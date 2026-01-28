//
//  LSPagingView.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  分页视图 - 简化分页滚动视图实现
//

#if canImport(UIKit)
import UIKit

// MARK: - LSPagingView

/// 分页视图
@MainActor
public class LSPagingView: UIView {

    // MARK: - 类型定义

    /// 页面索引回调
    public typealias PageIndexHandler = (Int) -> Void

    /// 页面数量回调
    public typealias PageCountHandler = () -> Int

    /// 页面视图回调
    public typealias PageViewHandler = (Int, UIView) -> Void

    // MARK: - 属性

    /// 滚动视图
    public let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.isPagingEnabled = true
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        sv.bounces = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    /// 页面控件
    public let pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.translatesAutoresizingMaskIntoConstraints = false
        return pc
    }()

    /// 当前页面索引
    public private(set) var currentPageIndex: Int = 0

    /// 页面数量
    public var numberOfPages: Int = 0 {
        didSet {
            pageControl.numberOfPages = numberOfPages
            updateContentSize()
        }
    }

    /// 是否水平滚动
    public var isHorizontal: Bool = true {
        didSet {
            updateScrollDirection()
        }
    }

    /// 是否显示页面指示器
    public var showsPageControl: Bool = true {
        didSet {
            pageControl.isHidden = !showsPageControl
        }
    }

    /// 页面指示器位置
    public var pageControlPosition: PageControlPosition = .bottom {
        didSet {
            updatePageControlConstraints()
        }
    }

    /// 页面视图缓存
    private var pageViewCache: [Int: UIView] = [:]

    /// 可见页面
    private var visiblePages: Set<Int> = []

    /// 重用队列
    private var reuseQueue: [UIView] = []

    /// 页面视图生成回调
    private var pageViewHandler: PageViewHandler?

    /// 页面索引变化回调
    public var onPageChanged: PageIndexHandler?

    // MARK: - 枚举

    /// 页面指示器位置
    public enum PageControlPosition {
        case top
        case bottom
        case topCenter
        case bottomCenter
    }

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - 设置

    private func setupUI() {
        addSubview(scrollView)
        addSubview(pageControl)

        scrollView.delegate = self

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        updatePageControlConstraints()

        // 页面控制事件
        pageControl.addTarget(
            self,
            action: #selector(pageControlValueChanged),
            for: .valueChanged
        )
    }

    private func updatePageControlConstraints() {
        // 移除旧的约束
        NSLayoutConstraint.deactivate(pageControl.constraints)

        switch pageControlPosition {
        case .top:
            NSLayoutConstraint.activate([
                pageControl.topAnchor.constraint(equalTo: topAnchor, constant: 8),
                pageControl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
                pageControl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
            ])
        case .bottom:
            NSLayoutConstraint.activate([
                pageControl.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
                pageControl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
                pageControl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
            ])
        case .topCenter:
            NSLayoutConstraint.activate([
                pageControl.topAnchor.constraint(equalTo: topAnchor, constant: 8),
                pageControl.centerXAnchor.constraint(equalTo: centerXAnchor)
            ])
        case .bottomCenter:
            NSLayoutConstraint.activate([
                pageControl.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
                pageControl.centerXAnchor.constraint(equalTo: centerXAnchor)
            ])
        }
    }

    // MARK: - 配置

    /// 配置数据源
    ///
    /// - Parameters:
    ///   - numberOfPages: 页面数量
    ///   - pageViewHandler: 页面视图生成回调
    public func configure(
        numberOfPages: Int,
        pageViewHandler: @escaping PageViewHandler
    ) {
        self.numberOfPages = numberOfPages
        self.pageViewHandler = pageViewHandler
        updateContentSize()
        loadCurrentPage()
    }

    /// 更新内容大小
    private func updateContentSize() {
        if isHorizontal {
            scrollView.contentSize = CGSize(
                width: bounds.width * CGFloat(numberOfPages),
                height: bounds.height
            )
        } else {
            scrollView.contentSize = CGSize(
                width: bounds.width,
                height: bounds.height * CGFloat(numberOfPages)
            )
        }
    }

    private func updateScrollDirection() {
        // 更新滚动方向
        if isHorizontal {
            scrollView.contentSize = CGSize(
                width: bounds.width * CGFloat(numberOfPages),
                height: bounds.height
            )
        } else {
            scrollView.contentSize = CGSize(
                width: bounds.width,
                height: bounds.height * CGFloat(numberOfPages)
            )
        }
    }

    // MARK: - 页面管理

    /// 加载当前页面
    public func loadCurrentPage() {
        loadPage(at: currentPageIndex)
    }

    /// 加载指定页面
    ///
    /// - Parameter index: 页面索引
    private func loadPage(at index: Int) {
        guard index >= 0 && index < numberOfPages else { return }

        // 检查是否已加载
        if visiblePages.contains(index) { return }

        // 从缓存获取或创建新视图
        let pageView: UIView
        if let cached = pageViewCache[index] {
            pageView = cached
        } else {
            pageView = createPageView(at: index)
            pageViewCache[index] = pageView
        }

        // 设置位置
        let frame: CGRect
        if isHorizontal {
            frame = CGRect(x: bounds.width * CGFloat(index), y: 0, width: bounds.width, height: bounds.height)
        } else {
            frame = CGRect(x: 0, y: bounds.height * CGFloat(index), width: bounds.width, height: bounds.height)
        }
        pageView.frame = frame

        scrollView.addSubview(pageView)
        visiblePages.insert(index)

        // 移除不可见的页面
        cleanupInvisiblePages()
    }

    /// 创建页面视图
    ///
    /// - Parameter index: 页面索引
    /// - Returns: 页面视图
    private func createPageView(at index: Int) -> UIView {
        let pageView
        if let tempValue = dequeueReuseView() {
            pageView = tempValue
        } else {
            pageView = UIView()
        }
        pageViewHandler?(index, pageView)
        return pageView
    }

    /// 移除不可见的页面
    private func cleanupInvisiblePages() {
        let visibleRange = calculateVisibleRange()

        for index in visiblePages {
            if !visibleRange.contains(index) {
                if let pageView = pageViewCache[index] {
                    pageView.removeFromSuperview()
                    enqueueReusable(view: pageView)
                }
                visiblePages.remove(index)
            }
        }
    }

    /// 计算可见范围
    private func calculateVisibleRange() -> Range<Int> {
        var visibleIndex: Int

        if isHorizontal {
            visibleIndex = Int(round(scrollView.contentOffset.x / bounds.width))
        } else {
            visibleIndex = Int(round(scrollView.contentOffset.y / bounds.height))
        }

        let startIndex = max(0, visibleIndex - 1)
        let endIndex = min(numberOfPages - 1, visibleIndex + 1)

        return startIndex..<endIndex + 1
    }

    // MARK: - 重用队列

    /// 出队重用视图
    private func dequeueReuseView() -> UIView? {
        return reuseQueue.popLast()
    }

    /// 入队重用视图
    ///
    /// - Parameter view: 视图
    private func enqueueReusable(view: UIView) {
        reuseQueue.append(view)
    }

    // MARK: - 滚动控制

    /// 滚动到指定页面
    ///
    /// - Parameters:
    ///   - index: 页面索引
    ///   - animated: 是否动画
    public func scrollToPage(at index: Int, animated: Bool = true) {
        guard index >= 0 && index < numberOfPages else { return }

        let offset: CGPoint
        if isHorizontal {
            offset = CGPoint(x: bounds.width * CGFloat(index), y: 0)
        } else {
            offset = CGPoint(x: 0, y: bounds.height * CGFloat(index))
        }

        scrollView.setContentOffset(offset, animated: animated)
    }

    /// 下一页
    ///
    /// - Parameter animated: 是否动画
    public func nextPage(animated: Bool = true) {
        scrollToPage(at: currentPageIndex + 1, animated: animated)
    }

    /// 上一页
    ///
    /// - Parameter animated: 是否动画
    public func previousPage(animated: Bool = true) {
        scrollToPage(at: currentPageIndex - 1, animated: animated)
    }

    // MARK: - 刷新

    /// 刷新所有页面
    public func reloadData() {
        // 移除所有页面视图
        for pageView in pageViewCache.values {
            pageView.removeFromSuperview()
        }

        pageViewCache.removeAll()
        visiblePages.removeAll()
        reuseQueue.removeAll()

        updateContentSize()
        loadCurrentPage()
    }

    /// 刷新指定页面
    ///
    /// - Parameter index: 页面索引
    public func reloadPage(at index: Int) {
        guard index >= 0 && index < numberOfPages else { return }

        // 移除旧视图
        if let pageView = pageViewCache[index] {
            pageView.removeFromSuperview()
            pageViewCache.removeValue(forKey: index)
            visiblePages.remove(index)
        }

        // 重新加载
        if index == currentPageIndex {
            loadPage(at: index)
        }
    }

    // MARK: - 事件处理

    @objc private func pageControlValueChanged() {
        scrollToPage(at: pageControl.currentPage, animated: true)
    }
}

// MARK: - UIScrollViewDelegate

extension LSPagingView: UIScrollViewDelegate {

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let index: Int

        if isHorizontal {
            index = Int(round(scrollView.contentOffset.x / bounds.width))
        } else {
            index = Int(round(scrollView.contentOffset.y / bounds.height))
        }

        let clampedIndex = max(0, min(index, numberOfPages - 1))

        if clampedIndex != currentPageIndex {
            currentPageIndex = clampedIndex
            pageControl.currentPage = currentPageIndex
            onPageChanged?(currentPageIndex)
        }

        // 预加载相邻页面
        loadPage(at: currentPageIndex)
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        cleanupInvisiblePages()
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        cleanupInvisiblePages()
    }
}

// MARK: - 便捷初始化

public extension LSPagingView {

    /// 创建图片轮播
    ///
    /// - Parameters:
    ///   - images: 图片数组
    ///   - duration: 自动滚动间隔（0 表示不自动）
    /// - Returns: 分页视图
    static func imageCarousel(
        images: [UIImage],
        autoScrollDuration: TimeInterval = 0
    ) -> LSPagingView {
        let pagingView = LSPagingView()

        pagingView.configure(numberOfPages: images.count) { index, contentView in
            // 清空之前的内容
            contentView.subviews.forEach { $0.removeFromSuperview() }

            // 添加图片视图
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            imageView.image = images[index]
            imageView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(imageView)

            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
        }

        // 自动滚动
        if autoScrollDuration > 0 {
            var timer: LSTimer?
            timer = LSTimer.every(autoScrollDuration) { [weak pagingView] in
                guard let pagingView = pagingView else {
                    timer?.invalidate()
                    return
                }

                var nextPage = pagingView.currentPageIndex + 1
                if nextPage >= pagingView.numberOfPages {
                    nextPage = 0
                }
                pagingView.scrollToPage(at: nextPage, animated: true)
            }
        }

        return pagingView
    }
}

#endif

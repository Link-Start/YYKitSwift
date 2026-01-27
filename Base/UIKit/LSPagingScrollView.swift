//
//  LSPagingScrollView.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  分页滚动视图 - 横向分页滚动容器
//

#if canImport(UIKit)
import UIKit

// MARK: - LSPagingScrollView

/// 分页滚动视图
public class LSPagingScrollView: UIView {

    // MARK: - 类型定义

    /// 页面索引回调
    public typealias PageChangeHandler = (Int) -> Void

    /// 页面配置
    public struct PageConfig {
        let view: UIView
        let title: String?

        public init(view: UIView, title: String? = nil) {
            self.view = view
            self.title = title
        }
    }

    // MARK: - 属性

    /// 滚动视图
    public let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.isPagingEnabled = true
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        sv.bounces = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.delegate = ProxyDelegate()
        return sv
    }()

    /// 内容容器
    public let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// 页面控制
    public let pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.currentPage = 0
        pc.translatesAutoresizingMaskIntoConstraints = false
        pc.hidesForSinglePage = true
        return pc
    }()

    /// 页面配置数组
    public var pages: [PageConfig] = [] {
        didSet {
            updatePages()
        }
    }

    /// 当前页面索引
    public private(set) var currentPage: Int = 0 {
        didSet {
            pageControl.currentPage = currentPage
            onPageChanged?(currentPage)
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
            updatePageControlPosition()
        }
    }

    /// 页面变化回调
    public var onPageChanged: PageChangeHandler?

    /// 是否自动滚动
    public var isAutoScrolling: Bool = false {
        didSet {
            if isAutoScrolling {
                startAutoScroll()
            } else {
                stopAutoScroll()
            }
        }
    }

    /// 自动滚动间隔
    public var autoScrollInterval: TimeInterval = 3.0

    /// 页面指示器位置
    public enum PageControlPosition {
        case top
        case bottom
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }

    // MARK: - 私有属性

    private var autoScrollTimer: Timer?

    // MARK: - 代理类

    private class ProxyDelegate: NSObject, UIScrollViewDelegate {
        var onScroll: ((UIScrollView) -> Void)?

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            onScroll?(scrollView)
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            onScroll?(scrollView)
        }
    }

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupPagingScrollView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPagingScrollView()
    }

    public init(pages: [PageConfig] = []) {
        self.pages = pages
        super.init(frame: .zero)
        setupPagingScrollView()
    }

    // MARK: - 设置

    private func setupPagingScrollView() {
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        addSubview(pageControl)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])

        updatePageControlPosition()

        // 设置滚动回调
        if let delegate = scrollView.delegate as? ProxyDelegate {
            delegate.onScroll = { [weak self] scrollView in
                self?.handleScroll(scrollView)
            }
        }
    }

    // MARK: - 更新

    private func updatePages() {
        // 移除旧的页面视图
        contentView.subviews.forEach { $0.removeFromSuperview() }

        for (index, page) in pages.enumerated() {
            let pageView = UIView()
            pageView.translatesAutoresizingMaskIntoConstraints = false

            pageView.addSubview(page.view)
            page.view.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                pageView.topAnchor.constraint(equalTo: contentView.topAnchor),
                pageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                pageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                pageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                pageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

                page.view.topAnchor.constraint(equalTo: pageView.topAnchor),
                pageView.leadingAnchor.constraint(equalTo: pageView.leadingAnchor),
                pageView.trailingAnchor.constraint(equalTo: pageView.trailingAnchor),
                pageView.bottomAnchor.constraint(equalTo: pageView.bottomAnchor)
            ])

            contentView.addSubview(pageView)
        }

        pageControl.numberOfPages = pages.count

        setNeedsLayout()
    }

    private func updatePageControlPosition() {
        pageControl.constraints.forEach { pageView.removeConstraint($0) }

        switch pageControlPosition {
        case .top:
            NSLayoutConstraint.activate([
                pageControl.topAnchor.constraint(equalTo: topAnchor, constant: 8),
                pageControl.centerXAnchor.constraint(equalTo: centerXAnchor)
            ])

        case .bottom:
            NSLayoutConstraint.activate([
                pageControl.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
                pageControl.centerXAnchor.constraint(equalTo: centerXAnchor)
            ])

        case .topLeft:
            NSLayoutConstraint.activate([
                pageControl.topAnchor.constraint(equalTo: topAnchor, constant: 8),
                pageControl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16)
            ])

        case .topRight:
            NSLayoutConstraint.activate([
                pageControl.topAnchor.constraint(equalTo: topAnchor, constant: 8),
                pageControl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
            ])

        case .bottomLeft:
            NSLayoutConstraint.activate([
                pageControl.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
                pageControl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16)
            ])

        case .bottomRight:
            NSLayoutConstraint.activate([
                pageControl.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
                pageControl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
            ])
        }
    }

    // MARK: - 滚动处理

    private func handleScroll(_ scrollView: UIScrollView) {
        let pageIndex = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        currentPage = max(0, min(pageIndex, pages.count - 1))
    }

    // MARK: - 自动滚动

    private func startAutoScroll() {
        stopAutoScroll()

        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: autoScrollInterval, repeats: true) { [weak self] _ in
            self?.scrollToNextPage()
        }
    }

    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }

    // MARK: - 公共方法

    /// 滚动到指定页面
    public func scrollToPage(_ index: Int, animated: Bool = true) {
        guard index >= 0 && index < pages.count else { return }

        let offset = CGPoint(x: scrollView.bounds.width * CGFloat(index), y: 0)
        scrollView.setContentOffset(offset, animated: animated)
    }

    /// 滚动到下一页
    public func scrollToNextPage(animated: Bool = true) {
        let nextIndex = min(currentPage + 1, pages.count - 1)
        scrollToPage(nextIndex, animated: animated)
    }

    /// 滚动到上一页
    public func scrollToPreviousPage(animated: Bool = true) {
        let prevIndex = max(currentPage - 1, 0)
        scrollToPage(prevIndex, animated: animated)
    }

    /// 添加页面
    public func addPage(_ page: PageConfig) {
        pages.append(page)
        updatePages()
    }

    /// 移除页面
    public func removePage(at index: Int) {
        guard index < pages.count else { return }
        pages.remove(at: index)
        updatePages()
    }

    deinit {
        stopAutoScroll()
    }
}

// MARK: - UIViewController Extension (Paging)

public extension UIViewController {

    /// 关联的分页滚动视图
    private static var pagingScrollViewKey: UInt8 = 0

    var ls_pagingScrollView: LSPagingScrollView? {
        get {
            return objc_getAssociatedObject(self, &UIViewController.pagingScrollViewKey) as? LSPagingScrollView
        }
        set {
            objc_setAssociatedObject(
                self,
                &UIViewController.pagingScrollViewKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// 设置分页滚动视图
    func ls_setPagingScrollView(
        pages: [LSPagingScrollView.PageConfig],
        showsPageControl: Bool = true,
        pageControlPosition: LSPagingScrollView.PageControlPosition = .bottom
    ) -> LSPagingScrollView {
        let pagingView = LSPagingScrollView(pages: pages)
        pagingView.showsPageControl = showsPageControl
        pagingView.pageControlPosition = pageControlPosition

        view.addSubview(pagingView)
        pagingView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            pagingView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pagingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pagingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pagingView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        ls_pagingScrollView = pagingView
        return pagingView
    }
}

// MARK: - Carousel View

/// 轮播视图
public class LSCarouselView: UIView {

    // MARK: - 类型定义

    /// 轮播项
    public struct CarouselItem {
        let view: UIView
        let title: String?

        public init(view: UIView, title: String? = nil) {
            self.view = view
            self.title = title
        }
    }

    /// 轮播位置回调
    public typealias CarouselScrollHandler = (Int) -> Void

    // MARK: - 属性

    /// 轮播项
    public var items: [CarouselItem] = [] {
        didSet {
            updateItems()
        }
    }

    /// 当前索引
    public private(set) var currentIndex: Int = 0 {
        didSet {
            onScroll?(currentIndex)
        }
    }

    /// 滚动间隔
    public var scrollInterval: TimeInterval = 3.0 {
        didSet {
            if isAutoScrolling {
                restartAutoScroll()
            }
        }
    }

    /// 是否自动滚动
    public var isAutoScrolling: Bool = true {
        didSet {
            if isAutoScrolling {
                startAutoScroll()
            } else {
                stopAutoScroll()
            }
        }
    }

    /// 是否无限循环
    public var isInfinite: Bool = false

    /// 轮播回调
    public var onScroll: CarouselScrollHandler?

    // MARK: - UI 组件

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.isPagingEnabled = true
        sv.showsHorizontalScrollIndicator = false
        sv.bounces = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.delegate = ProxyDelegate()
        return sv
    }()

    private let pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.currentPage = 0
        pc.translatesAutoresizingMaskIntoConstraints = false
        pc.hidesForSinglePage = true
        return pc
    }()

    private var pageViews: [UIView] = []

    private var autoScrollTimer: Timer?

    // MARK: - 代理类

    private class ProxyDelegate: NSObject, UIScrollViewDelegate {
        var onScroll: ((UIScrollView) -> Void)?
        var onEndDecelerating: (() -> Void)?

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            onScroll?(scrollView)
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            onEndDecelerating?()
        }
    }

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupCarousel()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCarousel()
    }

    // MARK: - 设置

    private func setupCarousel() {
        addSubview(scrollView)
        addSubview(pageControl)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            pageControl.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            pageControl.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])

        // 设置代理
        if let delegate = scrollView.delegate as? ProxyDelegate {
            delegate.onScroll = { [weak self] scrollView in
                self?.handleScroll(scrollView)
            }

            delegate.onEndDecelerating = { [weak self] in
                self?.restartAutoScroll()
            }
        }

        updateItems()
    }

    // MARK: - 更新

    private func updateItems() {
        // 移除旧的页面视图
        pageViews.forEach { $0.removeFromSuperview() }
        pageViews.removeAll()

        for item in items {
            pageViews.append(item.view)
            scrollView.addSubview(item.view)
        }

        updateContentSize()
        pageControl.numberOfPages = items.count

        setNeedsLayout()
    }

    private func updateContentSize() {
        let pageWidth = scrollView.bounds.width
        let pageHeight = scrollView.bounds.height

        for (index, pageView) in pageViews.enumerated() {
            pageView.frame = CGRect(x: pageWidth * CGFloat(index), y: 0, width: pageWidth, height: pageHeight)
        }

        scrollView.contentSize = CGSize(width: pageWidth * CGFloat(pageViews.count), height: pageHeight)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        updateContentSize()
    }

    // MARK: - 滚动处理

    private func handleScroll(_ scrollView: UIScrollView) {
        let pageWidth = scrollView.bounds.width
        let index = Int(round(scrollView.contentOffset.x / pageWidth))

        if isInfinite && pageViews.count > 1 {
            // 处理无限循环
            if index == 0 && scrollView.contentOffset.x < pageWidth / 2 {
                // 滚动到最后一页
                scrollView.contentOffset.x = pageWidth * CGFloat(pageViews.count - 1)
            } else if index == pageViews.count - 1 && scrollView.contentOffset.x > pageWidth * CGFloat(pageViews.count - 1) + pageWidth / 2 {
                // 滚动到第一页
                scrollView.contentOffset.x = pageWidth
            }
        }

        currentIndex = max(0, min(index, pageViews.count - 1))
        pageControl.currentPage = currentIndex
    }

    // MARK: - 自动滚动

    private func startAutoScroll() {
        stopAutoScroll()

        guard isAutoScrolling && pageViews.count > 1 else { return }

        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: scrollInterval, repeats: true) { [weak self] _ in
            self?.scrollToNextPage()
        }
    }

    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }

    private func restartAutoScroll() {
        if isAutoScrolling {
            startAutoScroll()
        }
    }

    // MARK: - 公共方法

    /// 滚动到指定页面
    public func scrollToPage(_ index: Int, animated: Bool = true) {
        guard index >= 0 && index < pageViews.count else { return }

        let offset = CGPoint(x: scrollView.bounds.width * CGFloat(index), y: 0)
        scrollView.setContentOffset(offset, animated: animated)
    }

    /// 滚动到下一页
    public func scrollToNextPage(animated: Bool = true) {
        let nextIndex = (currentIndex + 1) % pageViews.count
        scrollToPage(nextIndex, animated: animated)
    }

    /// 滚动到上一页
    public func scrollToPreviousPage(animated: Bool = true) {
        let prevIndex = (currentIndex - 1 + pageViews.count) % pageViews.count
        scrollToPage(prevIndex, animated: animated)
    }

    deinit {
        stopAutoScroll()
    }
}

// MARK: - 便捷创建

public extension LSCarouselView {

    /// 从图片创建轮播
    static func create(
        images: [UIImage],
        autoScrollInterval: TimeInterval = 3.0,
        isInfinite: Bool = true
    ) -> LSCarouselView {
        let items: [CarouselItem] = images.map { image in
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            return CarouselItem(view: imageView)
        }

        let carousel = LSCarouselView()
        carousel.items = items
        carousel.scrollInterval = autoScrollInterval
        carousel.isInfinite = isInfinite

        return carousel
    }

    /// 从视图数组创建轮播
    static func create(
        views: [UIView],
        autoScrollInterval: TimeInterval = 3.0
    ) -> LSCarouselView {
        let items = views.map { CarouselItem(view: $0) }

        let carousel = LSCarouselView()
        carousel.items = items
        carousel.scrollInterval = autoScrollInterval

        return carousel
    }
}

#endif

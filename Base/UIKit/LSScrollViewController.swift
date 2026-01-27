//
//  LSScrollViewController.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  滚动视图控制器 - 实现类似 ScrollView 的页面控制器
//

#if canImport(UIKit)
import UIKit

// MARK: - LSScrollViewController

/// 滚动视图控制器
public class LSScrollViewController: UIViewController {

    // MARK: - 类型定义

    /// 页面索引回调
    public typealias PageIndexHandler = (Int) -> Void

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

    /// 页面容器
    public let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.alignment = .fill
        sv.distribution = .fillEqually
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    /// 页面控制器
    public let pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.translatesAutoresizingMaskIntoConstraints = false
        return pc
    }()

    /// 视图控制器数组
    private var viewControllers: [UIViewController] = []

    /// 当前页面索引
    public private(set) var currentPageIndex: Int = 0

    /// 页面变化回调
    public var onPageChanged: PageIndexHandler?

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

    /// 页面间距
    public var pageSpacing: CGFloat = 0 {
        didSet {
            stackView.spacing = pageSpacing
        }
    }

    // MARK: - 枚举

    /// 页面指示器位置
    public enum PageControlPosition {
        case top
        case bottom
        case topCenter
        case bottomCenter
        hidden
    }

    // MARK: - 初始化

    public init(viewControllers: [UIViewController] = []) {
        self.viewControllers = viewControllers
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        self.viewControllers = []
        super.init(coder: coder)
    }

    // MARK: - 生命周期

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        addViewControllers()
    }

    // MARK: - 设置

    private func setupUI() {
        view.backgroundColor = .white

        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        view.addSubview(pageControl)

        scrollView.delegate = self

        // 页面控制事件
        pageControl.addTarget(
            self,
            action: #selector(pageControlValueChanged),
            for: .valueChanged
        )

        updateScrollDirection()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        ])

        updatePageControlConstraints()
    }

    private func updatePageControlConstraints() {
        NSLayoutConstraint.deactivate(pageControl.constraints)

        switch pageControlPosition {
        case .top:
            NSLayoutConstraint.activate([
                pageControl.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
                pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ])
        case .bottom:
            NSLayoutConstraint.activate([
                pageControl.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
                pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ])
        case .topCenter:
            NSLayoutConstraint.activate([
                pageControl.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
                pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ])
        case .bottomCenter:
            NSLayoutConstraint.activate([
                pageControl.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
                pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ])
        case .hidden:
            break
        }
    }

    private func updateScrollDirection() {
        let axis: NSLayoutConstraint.Axis = isHorizontal ? .horizontal : .vertical
        stackView.axis = axis
    }

    // MARK: - 视图控制器管理

    /// 设置视图控制器
    ///
    /// - Parameter viewControllers: 视图控制器数组
    public func setViewControllers(_ viewControllers: [UIViewController]) {
        // 移除旧的
        for vc in self.viewControllers {
            vc.willMove(toParent: self)
            vc.view.removeFromSuperview()
            vc.removeFromParent()
        }

        self.viewControllers = viewControllers
        pageControl.numberOfPages = viewControllers.count

        // 添加新的
        for (index, vc) in viewControllers.enumerated() {
            addChild(vc)
            stackView.addArrangedSubview(vc.view)
            vc.view.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                vc.view.topAnchor.constraint(equalTo: stackView.topAnchor),
                vc.view.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
                vc.view.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
                vc.view.bottomAnchor.constraint(equalTo: stackView.bottomAnchor)
            ])

            vc.didMove(toParent: self)
        }

        updateContentSize()
    }

    /// 添加视图控制器
    ///
    /// - Parameter viewController: 视图控制器
    public func addViewController(_ viewController: UIViewController) {
        viewControllers.append(viewController)
        pageControl.numberOfPages = viewControllers.count

        addChild(viewController)
        stackView.addArrangedSubview(viewController.view)
        viewController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            viewController.view.topAnchor.constraint(equalTo: stackView.topAnchor),
            viewController.view.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            viewController.view.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            viewController.view.bottomAnchor.constraint(equalTo: stackView.bottomAnchor)
        ])

        viewController.didMove(toParent: self)

        updateContentSize()
    }

    /// 移除视图控制器
    ///
    /// - Parameter viewController: 视图控制器
    public func removeViewController(_ viewController: UIViewController) {
        guard let index = viewControllers.firstIndex(of: viewController) else { return }

        viewController.willMove(toParent: self)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()

        viewControllers.remove(at: index)
        pageControl.numberOfPages = viewControllers.count

        if currentPageIndex >= viewControllers.count {
            currentPageIndex = viewControllers.count - 1
        }

        updateContentSize()
        scrollToPage(at: currentPageIndex, animated: false)
    }

    /// 添加视图控制器
    ///
    /// - Parameter viewControllers: 视图控制器数组
    public func addViewControllers(_ viewControllers: [UIViewController]) {
        for vc in viewControllers {
            addViewController(vc)
        }
    }

    private func addViewControllers() {
        setViewControllers(viewControllers)
    }

    // MARK: - 滚动控制

    /// 更新内容大小
    private func updateContentSize() {
        guard !viewControllers.isEmpty else { return }

        if isHorizontal {
            scrollView.contentSize = CGSize(
                width: scrollView.bounds.width * CGFloat(viewControllers.count),
                height: scrollView.bounds.height
            )
        } else {
            scrollView.contentSize = CGSize(
                width: scrollView.bounds.width,
                height: scrollView.bounds.height * CGFloat(viewControllers.count)
            )
        }
    }

    /// 滚动到指定页面
    ///
    /// - Parameters:
    ///   - index: 页面索引
    ///   - animated: 是否动画
    public func scrollToPage(at index: Int, animated: Bool = true) {
        guard index >= 0 && index < viewControllers.count else { return }

        let offset: CGPoint
        if isHorizontal {
            offset = CGPoint(x: scrollView.bounds.width * CGFloat(index), y: 0)
        } else {
            offset = CGPoint(x: 0, y: scrollView.bounds.height * CGFloat(index))
        }

        scrollView.setContentOffset(offset, animated: animated)
    }

    /// 下一页
    ///
    /// - Parameter animated: 是否动画
    public func nextPage(animated: Bool = true) {
        let nextIndex = min(currentPageIndex + 1, viewControllers.count - 1)
        scrollToPage(at: nextIndex, animated: animated)
    }

    /// 上一页
    ///
    /// - Parameter animated: 是否动画
    public func previousPage(animated: Bool = true) {
        let prevIndex = max(currentPageIndex - 1, 0)
        scrollToPage(at: prevIndex, animated: animated)
    }

    // MARK: - 事件处理

    @objc private func pageControlValueChanged() {
        scrollToPage(at: pageControl.currentPage, animated: true)
    }

    // MARK: - 获取视图控制器

    /// 获取当前视图控制器
    public var currentViewController: UIViewController? {
        guard currentPageIndex < viewControllers.count else { return nil }
        return viewControllers[currentPageIndex]
    }
}

// MARK: - UIScrollViewDelegate

extension LSScrollViewController: UIScrollViewDelegate {

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let index: Int

        if isHorizontal {
            index = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        } else {
            index = Int(round(scrollView.contentOffset.y / scrollView.bounds.height))
        }

        let clampedIndex = max(0, min(index, viewControllers.count - 1))

        if clampedIndex != currentPageIndex {
            currentPageIndex = clampedIndex
            pageControl.currentPage = currentPageIndex
            onPageChanged?(currentPageIndex)
        }
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let index: Int

        if isHorizontal {
            index = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        } else {
            index = Int(round(scrollView.contentOffset.y / scrollView.bounds.height))
        }

        currentPageIndex = max(0, min(index, viewControllers.count - 1))
        pageControl.currentPage = currentPageIndex
    }
}

// MARK: - 便捷方法

public extension LSScrollViewController {

    /// 创建图片轮播控制器
    ///
    /// - Parameters:
    ///   - images: 图片数组
    ///   - autoScrollInterval: 自动滚动间隔（0 表示不自动）
    /// - Returns: 滚动视图控制器
    static func imageCarousel(
        images: [UIImage],
        autoScrollInterval: TimeInterval = 0
    ) -> LSScrollViewController {
        let viewControllers: [UIViewController] = images.map { image in
            let vc = UIViewController()
            vc.view.backgroundColor = .clear
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            vc.view.addSubview(imageView)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: vc.view.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor),
                imageView.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor)
            ])
            return vc
        }

        let scrollVC = LSScrollViewController(viewControllers: viewControllers)
        scrollVC.pageControl.isHidden = true

        // 自动滚动
        if autoScrollInterval > 0 {
            let timer = LSTimer.every(autoScrollInterval) { [weak scrollVC] in
                guard let scrollVC = scrollVC else { return }
                let nextIndex = (scrollVC.currentPageIndex + 1) % scrollVC.viewControllers.count
                scrollVC.scrollToPage(at: nextIndex, animated: true)
            }
        }

        return scrollVC
    }
}

#endif

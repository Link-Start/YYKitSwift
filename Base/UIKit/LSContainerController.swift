//
//  LSContainerController.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  容器视图控制器 - 管理多个子视图控制器
//

#if canImport(UIKit)
import UIKit

// MARK: - LSContainerController

/// 容器视图控制器
@MainActor
public class LSContainerController: UIViewController {

    // MARK: - 类型定义

    /// 容器模式
    public enum ContainerMode {
        case stack           // 堆叠（一次只显示一个）
        case tabs            // 标签页
        case carousel        // 轮播
        case custom          // 自定义布局
    }

    /// 控制器变化回调
    public typealias ControllerChangeHandler = (UIViewController?, UIViewController?) -> Void

    // MARK: - 属性

    /// 子视图控制器数组
    public var viewControllers: [UIViewController] = [] {
        didSet {
            updateViewControllers()
        }
    }

    /// 当前选中的索引
    public private(set) var selectedIndex: Int = 0 {
        didSet {
            if selectedIndex != oldValue {
                updateSelectedViewController()
                onControllerChanged?(viewControllers[safe: oldValue], viewControllers[safe: selectedIndex])
            }
        }
    }

    /// 容器模式
    public var containerMode: ContainerMode = .stack {
        didSet {
            updateContainerMode()
        }
    }

    /// 是否允许滑动切换
    public var allowsSwipeToChange: Bool = true {
        didSet {
            updateGestureRecognizers()
        }
    }

    /// 是否动画切换
    public var animatedTransition: Bool = true

    /// 转场时长
    public var transitionDuration: TimeInterval = 0.3

    /// 控制器变化回调
    public var onControllerChanged: ControllerChangeHandler?

    /// 选择变化回调
    public var onSelectionChanged: ((Int) -> Void)?

    // MARK: - 私有属性

    private var currentViewController: UIViewController?

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.isPagingEnabled = true
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.bounces = false
        return sv
    }()

    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var panGesture: UIPanGestureRecognizer?

    // MARK: - 初始化

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setupContainer()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupContainer()
    }

    public convenience init(viewControllers: [UIViewController] = []) {
        self.init()
        self.viewControllers = viewControllers
    }

    // MARK: - 设置

    private func setupContainer() {
        view.addSubview(contentView)
        updateContainerMode()
    }

    // MARK: - 视图生命周期

    public override func viewDidLoad() {
        super.viewDidLoad()
        updateViewControllers()
        updateGestureRecognizers()
    }

    // MARK: - 更新方法

    private func updateViewControllers() {
        guard isViewLoaded else { return }

        // 移除所有子视图控制器
        viewControllers.forEach { $0.removeFromParent() }

        // 更新选中索引
        if selectedIndex >= viewControllers.count {
            selectedIndex = max(0, viewControllers.count - 1)
        }

        updateSelectedViewController()
    }

    private func updateContainerMode() {
        switch containerMode {
        case .stack:
            scrollView.removeFromSuperview()
            view.addSubview(contentView)
            updateSelectedViewController()

        case .tabs:
            scrollView.removeFromSuperview()
            view.addSubview(contentView)
            updateSelectedViewController()

        case .carousel:
            contentView.removeFromSuperview()
            view.addSubview(scrollView)
            setupScrollView()

        case .custom:
            scrollView.removeFromSuperview()
            view.addSubview(contentView)
        }
    }

    private func updateSelectedViewController() {
        guard selectedIndex < viewControllers.count else { return }

        let newViewController = viewControllers[selectedIndex]

        switch containerMode {
        case .stack, .tabs:
            if let current = currentViewController, current != newViewController {
                transition(from: current, to: newViewController)
            } else if currentViewController == nil {
                add(newViewController, to: contentView)
                currentViewController = newViewController
            }

        case .carousel:
            if currentViewController != newViewController {
                currentViewController = newViewController
                addAllViewControllersToScrollView()
                scrollToSelectedViewController()
            }

        case .custom:
            currentViewController = newViewController
        }
    }

    private func transition(
        from oldViewController: UIViewController,
        to newViewController: UIViewController
    ) {
        oldViewController.willMove(toParent: nil)

        if animatedTransition {
            addChild(newViewController)
            newViewController.view.frame = contentView.bounds
            newViewController.view.alpha = 0

            transition(
                from: oldViewController,
                to: newViewController,
                duration: transitionDuration,
                options: .transitionCrossDissolve,
                animations: {
                    newViewController.view.alpha = 1
                },
                completion: { _ in
                    oldViewController.removeFromParent()
                    oldViewController.didMove(toParent: nil)
                    newViewController.didMove(toParent: self)
                    self.currentViewController = newViewController
                }
            )
        } else {
            oldViewController.view.removeFromSuperview()
            oldViewController.removeFromParent()

            add(newViewController, to: contentView)
            currentViewController = newViewController
        }
    }

    private func setupScrollView() {
        scrollView.delegate = self
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func addAllViewControllersToScrollView() {
        // 清空现有内容
        scrollView.subviews.forEach { $0.removeFromSuperview() }

        let width = scrollView.bounds.width
        let height = scrollView.bounds.height

        for (index, viewController) in viewControllers.enumerated() {
            add(viewController, to: scrollView)
            viewController.view.frame = CGRect(x: CGFloat(index) * width, y: 0, width: width, height: height)
        }

        scrollView.contentSize = CGSize(width: CGFloat(viewControllers.count) * width, height: height)
    }

    private func scrollToSelectedViewController() {
        let width = scrollView.bounds.width
        let offset = CGPoint(x: CGFloat(selectedIndex) * width, y: 0)
        scrollView.setContentOffset(offset, animated: animatedTransition)
    }

    private func updateGestureRecognizers() {
        if allowsSwipeToChange && panGesture == nil {
            panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
            view.addGestureRecognizer(panGesture!)
        } else if !allowsSwipeToChange {
            if let gesture = panGesture {
                view.removeGestureRecognizer(gesture)
                panGesture = nil
            }
        }
    }

    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard allowsSwipeToChange else { return }

        switch gesture.state {
        case .ended:
            let velocity = gesture.velocity(in: view)
            if abs(velocity.x) > 500 {
                if velocity.x > 0 {
                    showPreviousViewController()
                } else {
                    showNextViewController()
                }
            }

        default:
            break
        }
    }

    // MARK: - 公共方法

    /// 显示指定索引的控制器
    public func showViewController(at index: Int) {
        guard index >= 0 && index < viewControllers.count else { return }
        selectedIndex = index
        onSelectionChanged?(selectedIndex)
    }

    /// 显示下一个控制器
    public func showNextViewController() {
        let nextIndex = min(selectedIndex + 1, viewControllers.count - 1)
        showViewController(at: nextIndex)
    }

    /// 显示上一个控制器
    public func showPreviousViewController() {
        let previousIndex = max(selectedIndex - 1, 0)
        showViewController(at: previousIndex)
    }

    /// 添加视图控制器
    public func addViewController(_ viewController: UIViewController) {
        viewControllers.append(viewController)
    }

    /// 移除视图控制器
    public func removeViewController(at index: Int) {
        guard index < viewControllers.count else { return }

        let viewController = viewControllers.remove(at: index)

        if viewController == currentViewController {
            selectedIndex = max(0, selectedIndex - 1)
        }

        viewController.removeFromParent()
    }

    /// 插入视图控制器
    public func insertViewController(_ viewController: UIViewController, at index: Int) {
        viewControllers.insert(viewController, at: index)
    }
}

// MARK: - LSContainerController UIScrollViewDelegate

extension LSContainerController: UIScrollViewDelegate {

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let index = Int(scrollView.contentOffset.x / scrollView.bounds.width)
        selectedIndex = index
        onSelectionChanged?(selectedIndex)
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // 可用于实现自定义效果
    }
}

// MARK: - LSTabContainerController

/// 标签容器控制器
public class LSTabContainerController: LSContainerController {

    // MARK: - 类型定义

    /// 标签配置
    public struct TabItem {
        let title: String?
        let image: UIImage?
        let selectedImage: UIImage?
        let viewController: UIViewController

        public init(
            title: String? = nil,
            image: UIImage? = nil,
            selectedImage: UIImage? = nil,
            viewController: UIViewController
        ) {
            self.title = title
            self.image = image
            self.selectedImage = selectedImage
            self.viewController = viewController
        }
    }

    // MARK: - 属性

    /// 标签项
    public var tabItems: [TabItem] = [] {
        didSet {
            updateTabItems()
        }
    }

    /// 标签栏位置
    public var tabPosition: TabPosition = .top {
        didSet {
            updateTabBarPosition()
        }
    }

    /// 标签栏高度
    public var tabHeight: CGFloat = 44 {
        didSet {
            updateTabBarConstraints()
        }
    }

    /// 标签栏颜色
    public var tabBackgroundColor: UIColor = .systemBackground {
        didSet {
            tabBar.backgroundColor = tabBackgroundColor
        }
    }

    /// 选中标签颜色
    public var selectedTabColor: UIColor = .systemBlue {
        didSet {
            segmentedControl.selectedSegmentIndex = selectedIndex
        }
    }

    /// 未选中标签颜色
    public var normalTabColor: UIColor = .secondaryLabel {
        didSet {
            updateTabBarStyle()
        }
    }

    /// 是否显示指示器
    public var showsIndicator: Bool = true

    // MARK: - UI 组件

    private let tabBar: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl()
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()

    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - 标签位置

    public enum TabPosition {
        case top
        case bottom
        case left
        case right
    }

    // MARK: - 初始化

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setupTabContainer()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTabContainer()
    }

    public convenience init(tabItems: [TabItem] = []) {
        self.init()
        self.tabItems = tabItems
    }

    // MARK: - 设置

    private func setupTabContainer() {
        containerMode = .tabs

        view.addSubview(tabBar)
        tabBar.addSubview(segmentedControl)
        view.addSubview(containerView)

        updateTabBarPosition()
        updateTabBarConstraints()
        updateTabBarStyle()

        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
    }

    private func updateTabBarPosition() {
        // 更新约束会在 updateTabBarConstraints 中处理
        setNeedsUpdateConstraints()
    }

    private func updateTabBarConstraints() {
        NSLayoutConstraint.deactivate(tabBar.constraints)
        NSLayoutConstraint.deactivate(containerView.constraints)

        switch tabPosition {
        case .top:
            NSLayoutConstraint.activate([
                tabBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                tabBar.heightAnchor.constraint(equalToConstant: tabHeight),

                containerView.topAnchor.constraint(equalTo: tabBar.bottomAnchor),
                containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])

        case .bottom:
            NSLayoutConstraint.activate([
                tabBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                tabBar.heightAnchor.constraint(equalToConstant: tabHeight),

                containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                containerView.bottomAnchor.constraint(equalTo: tabBar.topAnchor)
            ])

        case .left:
            NSLayoutConstraint.activate([
                tabBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                tabBar.topAnchor.constraint(equalTo: view.topAnchor),
                tabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                tabBar.widthAnchor.constraint(equalToConstant: tabHeight),

                containerView.leadingAnchor.constraint(equalTo: tabBar.trailingAnchor),
                containerView.topAnchor.constraint(equalTo: view.topAnchor),
                containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])

        case .right:
            NSLayoutConstraint.activate([
                tabBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                tabBar.topAnchor.constraint(equalTo: view.topAnchor),
                tabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                tabBar.widthAnchor.constraint(equalToConstant: tabHeight),

                containerView.trailingAnchor.constraint(equalTo: tabBar.leadingAnchor),
                containerView.topAnchor.constraint(equalTo: view.topAnchor),
                containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
    }

    private func updateTabBarStyle() {
        segmentedControl.removeAllSegments()

        for (index, item) in tabItems.enumerated() {
            segmentedControl.insertSegment(
                withTitle: item.title,
                at: index,
                animated: false
            )
        }

        segmentedControl.selectedSegmentIndex = selectedIndex
    }

    private func updateTabItems() {
        viewControllers = tabItems.map { $0.viewController }
        updateTabBarStyle()
    }

    @objc private func segmentChanged() {
        selectedIndex = segmentedControl.selectedSegmentIndex
        onSelectionChanged?(selectedIndex)
    }
}

// MARK: - LSCarouselController

/// 轮播容器控制器
public class LSCarouselController: LSContainerController {

    // MARK: - 属性

    /// 是否自动滚动
    public var isAutoScrolling: Bool = false {
        didSet {
            updateAutoScroll()
        }
    }

    /// 自动滚动间隔
    public var autoScrollInterval: TimeInterval = 3.0

    /// 是否无限循环
    public var isInfinite: Bool = false

    /// 是否显示页面指示器
    public var showsPageIndicator: Bool = true {
        didSet {
            pageControl.isHidden = !showsPageIndicator
        }
    }

    /// 当前页面指示器颜色
    public var currentPageIndicatorColor: UIColor = .systemBlue {
        didSet {
            pageControl.currentPageIndicatorTintColor = currentPageIndicatorColor
        }
    }

    /// 页面指示器颜色
    public var pageIndicatorColor: UIColor = .systemGray {
        didSet {
            pageControl.pageIndicatorTintColor = pageIndicatorColor
        }
    }

    // MARK: - UI 组件

    private let pageControl: UIPageControl = {
        let control = UIPageControl()
        control.translatesAutoresizingMaskIntoConstraints = false
        control.hidesForSinglePage = true
        return control
    }()

    private var autoScrollTimer: Timer?

    // MARK: - 初始化

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setupCarousel()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCarousel()
    }

    public convenience init(viewControllers: [UIViewController] = [], isInfinite: Bool = false) {
        self.init()
        self.viewControllers = viewControllers
        self.isInfinite = isInfinite
    }

    // MARK: - 设置

    private func setupCarousel() {
        containerMode = .carousel
        allowsSwipeToChange = true

        view.addSubview(pageControl)

        NSLayoutConstraint.activate([
            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        updatePageControl()
    }

    // MARK: - 更新方法

    private func updatePageControl() {
        pageControl.numberOfPages = viewControllers.count
        pageControl.currentPage = selectedIndex
    }

    private func updateAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil

        if isAutoScrolling && viewControllers.count > 1 {
            autoScrollTimer = Timer.scheduledTimer(
                withTimeInterval: autoScrollInterval,
                repeats: true
            ) { [weak self] _ in
                self?.showNextViewController()
            }
        }
    }

    // MARK: - 重写方法

    public override func showViewController(at index: Int) {
        super.showViewController(at: index)
        updatePageControl()
    }

    public override func showNextViewController() {
        let nextIndex = (selectedIndex + 1) % viewControllers.count
        showViewController(at: nextIndex)
    }

    public override func showPreviousViewController() {
        let previousIndex = (selectedIndex - 1 + viewControllers.count) % viewControllers.count
        showViewController(at: previousIndex)
    }
}

// MARK: - LSSplitViewController

/// 分栏视图控制器
public class LSSplitViewController: UIViewController {

    // MARK: - 类型定义

    /// 分栏方向
    public enum SplitDirection {
        case horizontal
        case vertical
    }

    // MARK: - 属性

    /// 主视图控制器
    public var masterViewController: UIViewController? {
        didSet {
            updateMasterViewController()
        }
    }

    /// 详情视图控制器
    public var detailViewController: UIViewController? {
        didSet {
            updateDetailViewController()
        }
    }

    /// 分栏方向
    public var splitDirection: SplitDirection = .horizontal {
        didSet {
            updateSplitDirection()
        }
    }

    /// 主视图控制器占比（0.0 - 1.0）
    public var masterRatio: CGFloat = 0.3 {
        didSet {
            masterRatio = max(0, min(1, masterRatio))
            updateSplitRatio()
        }
    }

    /// 分隔线宽度
    public var dividerWidth: CGFloat = 1

    /// 分隔线颜色
    public var dividerColor: UIColor = .separator {
        didSet {
            dividerView.backgroundColor = dividerColor
        }
    }

    /// 是否允许调整分隔
    public var allowsResizingDivider: Bool = true {
        didSet {
            updateDividerGestures()
        }
    }

    // MARK: - UI 组件

    private let masterContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let detailContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let dividerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .separator
        return view
    }()

    private var dividerGesture: UIPanGestureRecognizer?

    // MARK: - 初始化

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setupSplitView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSplitView()
    }

    public convenience init(
        master: UIViewController? = nil,
        detail: UIViewController? = nil,
        direction: SplitDirection = .horizontal
    ) {
        self.init()
        self.masterViewController = master
        self.detailViewController = detail
        self.splitDirection = direction
    }

    // MARK: - 设置

    private func setupSplitView() {
        view.addSubview(masterContainerView)
        view.addSubview(dividerView)
        view.addSubview(detailContainerView)

        updateSplitDirection()
        updateSplitRatio()
        updateDividerGestures()

        updateMasterViewController()
        updateDetailViewController()
    }

    // MARK: - 更新方法

    private func updateSplitDirection() {
        setNeedsUpdateConstraints()
    }

    private func updateSplitRatio() {
        setNeedsUpdateConstraints()
    }

    private func updateMasterViewController() {
        guard let master = masterViewController else {
            masterContainerView.subviews.forEach { $0.removeFromSuperview() }
            return
        }

        add(master, to: masterContainerView)
    }

    private func updateDetailViewController() {
        guard let detail = detailViewController else {
            detailContainerView.subviews.forEach { $0.removeFromSuperview() }
            return
        }

        add(detail, to: detailContainerView)
    }

    private func updateDividerGestures() {
        if allowsResizingDivider && dividerGesture == nil {
            dividerGesture = UIPanGestureRecognizer(target: self, action: #selector(handleDividerPan(_:)))
            dividerView.addGestureRecognizer(dividerGesture!)
        } else if !allowsResizingDivider {
            if let gesture = dividerGesture {
                dividerView.removeGestureRecognizer(gesture)
                dividerGesture = nil
            }
        }
    }

    public override func updateViewConstraints() {
        super.updateViewConstraints()

        NSLayoutConstraint.deactivate(constraints)

        switch splitDirection {
        case .horizontal:
            NSLayoutConstraint.activate([
                masterContainerView.topAnchor.constraint(equalTo: view.topAnchor),
                masterContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                masterContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                masterContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: masterRatio),

                dividerView.topAnchor.constraint(equalTo: view.topAnchor),
                dividerView.leadingAnchor.constraint(equalTo: masterContainerView.trailingAnchor),
                dividerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                dividerView.widthAnchor.constraint(equalToConstant: dividerWidth),

                detailContainerView.topAnchor.constraint(equalTo: view.topAnchor),
                detailContainerView.leadingAnchor.constraint(equalTo: dividerView.trailingAnchor),
                detailContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                detailContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])

        case .vertical:
            NSLayoutConstraint.activate([
                masterContainerView.topAnchor.constraint(equalTo: view.topAnchor),
                masterContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                masterContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                masterContainerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: masterRatio),

                dividerView.topAnchor.constraint(equalTo: masterContainerView.bottomAnchor),
                dividerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                dividerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                dividerView.heightAnchor.constraint(equalToConstant: dividerWidth),

                detailContainerView.topAnchor.constraint(equalTo: dividerView.bottomAnchor),
                detailContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                detailContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                detailContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
    }

    @objc private func handleDividerPan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)

        switch splitDirection {
        case .horizontal:
            let newRatio = (masterContainerView.frame.width + translation.x) / view.bounds.width
            masterRatio = newRatio

        case .vertical:
            let newRatio = (masterContainerView.frame.height + translation.y) / view.bounds.height
            masterRatio = newRatio
        }

        gesture.setTranslation(.zero, in: view)
    }
}

// MARK: - UIViewController Extension (Container)

public extension UIViewController {

    /// 关联的容器控制器
    private static var containerControllerKey: UInt8 = 0

    var ls_containerController: LSContainerController? {
        get {
            return objc_getAssociatedObject(self, &UIViewController.containerControllerKey) as? LSContainerController
        }
        set {
            objc_setAssociatedObject(
                self,
                &UIViewController.containerControllerKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// 添加容器控制器
    @discardableResult
    func ls_addContainer(
        viewControllers: [UIViewController] = [],
        mode: LSContainerController.ContainerMode = .stack
    ) -> LSContainerController {
        let container = LSContainerController(viewControllers: viewControllers)
        container.containerMode = mode

        addChild(container)
        view.addSubview(container.view)
        container.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            container.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            container.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        container.didMove(toParent: self)

        ls_containerController = container
        return container
    }

    /// 添加标签容器控制器
    @discardableResult
    func ls_addTabContainer(
        tabItems: [LSTabContainerController.TabItem] = [],
        position: LSTabContainerController.TabPosition = .top
    ) -> LSTabContainerController {
        let container = LSTabContainerController(tabItems: tabItems)
        container.tabPosition = position

        addChild(container)
        view.addSubview(container.view)
        container.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            container.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            container.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        container.didMove(toParent: self)

        return container
    }
}

// MARK: - Helper Extension

private extension Collection {

    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#endif

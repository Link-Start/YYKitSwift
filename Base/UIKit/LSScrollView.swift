//
//  LSScrollView.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  增强的滚动视图 - 提供更多滚动功能
//

#if canImport( UIKit)
import UIKit

// MARK: - LSScrollView

/// 增强的滚动视图
public class LSScrollView: UIView {

    // MARK: - 类型定义

    /// 滚动回调
    public typealias ScrollHandler = (CGPoint) -> Void

    /// 滚动状态回调
    public typealias ScrollStateHandler = (LSScrollView.ScrollState) -> Void

    /// 滚动状态
    public enum ScrollState {
        case idle
        case dragging
        case decelerating
    }

    // MARK: - 属性

    /// 滚动视图
    public let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsHorizontalScrollIndicator = true
        sv.showsVerticalScrollIndicator = true
        sv.bounces = true
        return sv
    }()

    /// 内容视图
    public let contentView: UIView = {
        let cv = UIView()
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    /// 滚动回调
    public var onScroll: ScrollHandler?

    /// 滚动状态变化回调
    public var onScrollStateChanged: ScrollStateHandler?

    /// 当前滚动状态
    public private(set) var scrollState: ScrollState = .idle {
        didSet {
            onScrollStateChanged?(scrollState)
        }
    }

    /// 是否启用分页
    public var isPagingEnabled: Bool = false {
        didSet {
            scrollView.isPagingEnabled = isPagingEnabled
        }
    }

    /// 是否显示水平指示器
    public var showsHorizontalScrollIndicator: Bool = true {
        didSet {
            scrollView.showsHorizontalScrollIndicator = showsHorizontalScrollIndicator
        }
    }

    /// 是否显示垂直指示器
    public var showsVerticalScrollIndicator: Bool = true {
        didSet {
            scrollView.showsVerticalScrollIndicator = showsVerticalScrollIndicator
        }
    }

    /// 指示器样式
    public var indicatorStyle: UIScrollView.IndicatorStyle = .default {
        didSet {
            scrollView.indicatorStyle = indicatorStyle
        }
    }

    /// 是否弹跳
    public var bounces: Bool = true {
        didSet {
            scrollView.bounces = bounces
        }
    }

    // MARK: - 委托

    private var delegateProxy: ScrollViewDelegateProxy?

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
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            contentView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])

        delegateProxy = ScrollViewDelegateProxy(scrollView: scrollView)
        delegateProxy?.onScroll = { [weak self] offset in
            self?.onScroll?(offset)
        }
        delegateProxy?.onScrollStateChanged = { [weak self] state in
            self?.scrollState = state
        }

        scrollView.delegate = delegateProxy
    }

    // MARK: - 滚动控制

    /// 滚动到顶部
    ///
    /// - Parameter animated: 是否动画
    public func scrollToTop(animated: Bool = true) {
        scrollView.setContentOffset(.zero, animated: animated)
    }

    /// 滚动到底部
    ///
    /// - Parameter animated: 是否动画
    public func scrollToBottom(animated: Bool = true) {
        let bottomOffset = max(0, scrollView.contentSize.height - scrollView.bounds.height)
        scrollView.setContentOffset(CGPoint(x: 0, y: bottomOffset), animated: animated)
    }

    /// 滚动到指定位置
    ///
    /// - Parameters:
    ///   - point: 位置
    ///   - animated: 是否动画
    public func scrollTo(_ point: CGPoint, animated: Bool = true) {
        scrollView.setContentOffset(point, animated: animated)
    }

    /// 滚动到指定百分比
    ///
    /// - Parameters:
    ///   - percentage: 百分比 (0-1)
    ///   - animated: 是否动画
    public func scrollToPercentage(_ percentage: CGFloat, animated: Bool = true) {
        let maxOffset = max(
            scrollView.contentSize.width - scrollView.bounds.width,
            scrollView.contentSize.height - scrollView.bounds.height
        )
        let offset = CGPoint(
            x: maxOffset.x * percentage,
            y: maxOffset.y * percentage
        )
        scrollView.setContentOffset(offset, animated: animated)
    }

    /// 滚动到左侧
    ///
    /// - Parameter animated: 是否动画
    public func scrollToLeft(animated: Bool = true) {
        scrollView.setContentOffset(CGPoint(x: 0, y: scrollView.contentOffset.y), animated: animated)
    }

    /// 滚动到右侧
    ///
    /// - Parameter animated: 是否动画
    public func scrollToRight(animated: Bool = true) {
        let maxOffsetX = max(0, scrollView.contentSize.width - scrollView.bounds.width)
        scrollView.setContentOffset(CGPoint(x: maxOffsetX, y: scrollView.contentOffset.y), animated: animated)
    }

    // MARK: - 状态查询

    /// 是否已滚动到顶部
    public var isAtTop: Bool {
        return scrollView.contentOffset.y <= 0
    }

    /// 是否已滚动到底部
    public var isAtBottom: Bool {
        let bottomOffset = scrollView.contentSize.height - scrollView.bounds.height
        return scrollView.contentOffset.y >= bottomOffset - 0.5
    }

    /// 是否正在滚动
    public var isScrolling: Bool {
        return scrollState != .idle
    }

    /// 是否正在拖动
    public var isDragging: Bool {
        return scrollState == .dragging
    }

    /// 滚动进度（垂直）
    public var verticalScrollProgress: CGFloat {
        let maxOffset = max(0, scrollView.contentSize.height - scrollView.bounds.height)
        guard maxOffset > 0 else { return 0 }
        return scrollView.contentOffset.y / maxOffset
    }

    /// 滚动进度（水平）
    public var horizontalScrollProgress: CGFloat {
        let maxOffset = max(0, scrollView.contentSize.width - scrollView.bounds.width)
        guard maxOffset > 0 else { return 0 }
        return scrollView.contentOffset.x / maxOffset
    }

    // MARK: - 内容尺寸

    /// 设置内容尺寸
    ///
    /// - Parameter size: 内容尺寸
    public func setContentSize(_ size: CGSize) {
        scrollView.contentSize = size
    }

    /// 更新内容尺寸（基于子视图）
    public func updateContentSize() {
        // 计算所有子视图的并集
        var contentRect = CGRect.zero

        for subview in contentView.subviews {
            contentRect = contentRect.union(subview.frame)
        }

        scrollView.contentSize = contentRect.size
    }
}

// MARK: - ScrollViewDelegateProxy

/// 滚动视图代理
private class ScrollViewDelegateProxy: NSObject, UIScrollViewDelegate {

    /// 滚动回调
    var onScroll: ((CGPoint) -> Void)?

    /// 状态变化回调
    var onScrollStateChanged: ((LSScrollView.ScrollState) -> Void)?

    /// 滚动视图
    private weak var scrollView: UIScrollView?

    /// 初始化
    init(scrollView: UIScrollView) {
        self.scrollView = scrollView
    }

    // MARK: - UIScrollViewDelegate

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        onScroll?(scrollView.contentOffset)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        onScrollStateChanged?(.dragging)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate {
            onScrollStateChanged?(.decelerating)
        } else {
            onScrollStateChanged?(.idle)
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        onScrollStateChanged?(.idle)
    }
}

// MARK: - 便捷方法

public extension LSScrollView {

    /// 创建水平滚动视图
    ///
    /// - Returns: 滚动视图
    static func horizontal() -> LSScrollView {
        let scrollView = LSScrollView()
        scrollView.scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }

    /// 创建垂直滚动视图
    ///
    /// - Returns: 滚动视图
    static func vertical() -> LSScrollView {
        let scrollView = LSScrollView()
        scrollView.scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }

    /// 创建分页滚动视图
    ///
    /// - Returns: 滚动视图
    static func paging() -> LSScrollView {
        let scrollView = LSScrollView()
        scrollView.isPagingEnabled = true
        scrollView.bounces = false
        return scrollView
    }

    /// 创建无指示器滚动视图
    ///
    /// - Returns: 滚动视图
    static func withoutIndicators() -> LSScrollView {
        let scrollView = LSScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }
}

// MARK: - UIScrollView Extension (增强)

public extension UIScrollView {

    /// 当前滚动进度（垂直）
    var ls_verticalProgress: CGFloat {
        let maxOffsetY = max(0, contentSize.height - bounds.height)
        guard maxOffsetY > 0 else { return 0 }
        return contentOffset.y / maxOffsetY
    }

    /// 当前滚动进度（水平）
    var ls_horizontalProgress: CGFloat {
        let maxOffsetX = max(0, contentSize.width - bounds.width)
        guard maxOffsetX > 0 else { return 0 }
        return contentOffset.x / maxOffsetX
    }

    /// 是否已滚动到顶部
    var ls_isAtTop: Bool {
        return contentOffset.y <= 0
    }

    /// 是否已滚动到底部
    var ls_isAtBottom: Bool {
        let bottomOffset = contentSize.height - bounds.height
        return contentOffset.y >= bottomOffset - 0.5
    }

    /// 滚动到顶部
    func ls_scrollToTop(animated: Bool = true) {
        setContentOffset(.zero, animated: animated)
    }

    /// 滚动到底部
    func ls_scrollToBottom(animated: Bool = true) {
        let bottomOffset = max(0, contentSize.height - bounds.height)
        setContentOffset(CGPoint(x: 0, y: bottomOffset), animated: animated)
    }

    /// 滚动到指定百分比
    ///
    /// - Parameter percentage: 百分比 (0-1)
    func ls_scrollToPercentage(_ percentage: CGFloat, animated: Bool = true) {
        let maxOffsetY = max(0, contentSize.height - bounds.height)
        let offsetY = maxOffsetY * percentage
        setContentOffset(CGPoint(x: contentOffset.x, y: offsetY), animated: animated)
    }

    /// 添加滚动到顶部检测
    ///
    /// - Parameter threshold: 阈值（像素）
    /// - onTrigger: 触发回调
    /// - Returns: 观察者令牌
    @discardableResult
    func ls_onNearTop(
        threshold: CGFloat = 20,
        onTrigger: @escaping () -> Void
    ) -> ScrollViewObserver {
        let observer = ScrollViewObserver(
            scrollView: self,
            threshold: threshold,
            onTrigger: onTrigger
        )
        observer.start()
        return observer
    }

    /// 添加滚动到底部检测
    ///
    /// - Parameter threshold: 阈值（像素）
    /// - onTrigger: 触发回调
    /// - Returns: 观察者令牌
    @discardableResult
    func ls_onNearBottom(
        threshold: CGFloat = 20,
        onTrigger: @escaping () -> Void
    ) -> ScrollViewObserver {
        let observer = ScrollViewObserver(
            scrollView: self,
            threshold: threshold,
            onTrigger: onTrigger
        )
        observer.isBottomObserver = true
        observer.start()
        return observer
    }
}

// MARK: - ScrollViewObserver

/// 滚动观察者
public class ScrollViewObserver: NSObject {

    /// 滚动视图
    private weak var scrollView: UIScrollView?

    /// 阈值
    private let threshold: CGFloat

    /// 是否为底部观察者
    private var isBottomObserver: Bool = false

    /// 触发回调
    private var onTrigger: () -> Void?

    /// 滚动观察者
    private var observer: NSObjectProtocol?

    /// 是否已触发
    private var hasTriggered: Bool = false

    /// 初始化
    init(
        scrollView: UIScrollView,
        threshold: CGFloat,
        onTrigger: @escaping () -> Void
    ) {
        self.scrollView = scrollView
        self.threshold = threshold
        self.onTrigger = onTrigger
    }

    /// 开始观察
    func start() {
        guard let scrollView = scrollView else { return }

        observer = NotificationCenter.default.addObserver(
            forName: UIScrollView.didScrollNotificationName,
            object: scrollView,
            queue: .main
        ) { [weak self] _ in
            self?.checkThreshold()
        }
    }

    /// 停止观察
    func stop() {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
            self.observer = nil
        }
    }

    /// 检查阈值
    private func checkThreshold() {
        guard let scrollView = scrollView else { return }

        let progress: CGFloat
        if isBottomObserver {
            progress = 1 - scrollView.ls_verticalProgress
        } else {
            progress = scrollView.ls_verticalProgress
        }

        let shouldTrigger = progress <= (threshold / scrollView.bounds.height)

        if shouldTrigger && !hasTriggered {
            hasTriggered = true
            onTrigger?()
        } else if !shouldTrigger {
            hasTriggered = false
        }
    }

    deinit {
        stop()
    }
}

#endif

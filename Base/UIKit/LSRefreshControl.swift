//
//  LSRefreshControl.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  下拉刷新控件
//

#if canImport(UIKit)
import UIKit

// MARK: - LSRefreshControl

/// 下拉刷新控件
@MainActor
public class LSRefreshControl: UIView {

    // MARK: - 类型定义

    /// 刷新状态回调
    public typealias RefreshHandler = () -> Void

    /// 刷新状态
    public enum State {
        case idle           // 空闲
        case pulling       // 拖动中
        case refreshing    // 刷新中
    }

    // MARK: - 属性

    /// 刷新回调
    public var onRefresh: RefreshHandler?

    /// 当前状态
    public private(set) var state: State = .idle {
        didSet {
            updateState()
        }
    }

    /// 触发刷新的阈值
    public var triggerThreshold: CGFloat = 60 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    /// 关联的滚动视图
    public weak var scrollView: UIScrollView? {
        didSet {
            setupScrollViewObservers()
        }
    }

    /// 指示器视图
    private let indicatorView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    /// 状态标签
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 箭头视图
    private let arrowView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "arrow.down")
        imageView.tintColor = .systemGray
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    /// 原始contentInset
    private var originalContentInset: UIEdgeInsets = .zero

    /// 是否正在显示
    private var isDisplaying: Bool = false

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
        backgroundColor = .clear

        addSubview(arrowView)
        addSubview(statusLabel)
        addSubview(indicatorView)

        NSLayoutConstraint.activate([
            arrowView.centerXAnchor.constraint(equalTo: centerXAnchor),
            arrowView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -10),
            arrowView.widthAnchor.constraint(equalToConstant: 20),
            arrowView.heightAnchor.constraint(equalToConstant: 20),

            statusLabel.topAnchor.constraint(equalTo: arrowView.bottomAnchor, constant: 8),
            statusLabel.centerXAnchor.constraint(equalTo: centerXAnchor),

            indicatorView.centerXAnchor.constraint(equalTo: centerXAnchor),
            indicatorView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -10)
        ])

        updateState()
    }

    private func setupScrollViewObservers() {
        guard let scrollView = scrollView else { return }

        // 使用 KVO 监听 contentOffset
        scrollView.addObserver(
            self,
            forKeyPath: "contentOffset",
            options: [.new, .initial],
            context: nil
        )
    }

    public override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard keyPath == "contentOffset",
              let scrollView = object as? UIScrollView,
              let newOffset = change?[.newKey] as? CGPoint else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

        handleScrollViewDidScroll(scrollView, contentOffset: newOffset)
    }

    // MARK: - 滚动处理

    private func handleScrollViewDidScroll(_ scrollView: UIScrollView, contentOffset: CGPoint) {
        guard state != .refreshing else { return }

        let pullDistance = max(0, -contentOffset.y - originalContentInset.top)

        if pullDistance > 0 {
            if pullDistance < triggerThreshold {
                state = .pulling
            } else {
                // 触发刷新
                beginRefreshing()
            }
        } else {
            state = .idle
        }

        // 更新箭头旋转
        let progress = min(pullDistance / triggerThreshold, 1.0)
        arrowView.transform = CGAffineTransform(rotationAngle: .pi * progress)
    }

    private func updateState() {
        switch state {
        case .idle:
            statusLabel.text = "下拉刷新"
            arrowView.isHidden = false
            indicatorView.stopAnimating()

        case .pulling:
            statusLabel.text = "释放立即刷新"
            arrowView.isHidden = false
            indicatorView.stopAnimating()

        case .refreshing:
            statusLabel.text = "正在刷新"
            arrowView.isHidden = true
            indicatorView.startAnimating()
        }
    }

    // MARK: - 公共方法

    /// 开始刷新
    public func beginRefreshing() {
        guard state != .refreshing else { return }

        state = .refreshing

        guard let scrollView = scrollView else { return }

        // 保存原始 inset
        originalContentInset = scrollView.contentInset

        // 动画显示刷新控件
        UIView.animate(withDuration: 0.25) {
            scrollView.contentInset = UIEdgeInsets(
                top: self.originalContentInset.top + self.triggerThreshold,
                left: self.originalContentInset.left,
                bottom: self.originalContentInset.bottom,
                right: self.originalContentInset.right
            )
        } completion: { _ in
            self.onRefresh?()
        }
    }

    /// 结束刷新
    public func endRefreshing() {
        guard state == .refreshing else { return }

        state = .idle

        guard let scrollView = scrollView else { return }

        // 动画隐藏刷新控件
        UIView.animate(withDuration: 0.25) {
            scrollView.contentInset = self.originalContentInset
        }
    }

    /// 是否正在刷新
    public var isRefreshing: Bool {
        return state == .refreshing
    }

    // MARK: - 清理

    deinit {
        scrollView?.removeObserver(self, forKeyPath: "contentOffset")
    }
}

// MARK: - UIScrollView Extension

public extension UIScrollView {

    private enum AssociatedKeys {
        static var refreshControlKey: UInt8 = 0
    }var ls_refreshControl: LSRefreshControl? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.refreshControlKey) as? LSRefreshControl
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.refreshControlKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// 添加下拉刷新
    ///
    /// - Parameters:
    ///   - handler: 刷新回调
    /// - Returns: 刷新控件
    @discardableResult
    func ls_addRefreshControl(handler: @escaping () -> Void) -> LSRefreshControl {
        let refreshControl = LSRefreshControl()
        refreshControl.scrollView = self
        refreshControl.onRefresh = handler

        addSubview(refreshControl)
        refreshControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            refreshControl.centerXAnchor.constraint(equalTo: centerXAnchor),
            refreshControl.widthAnchor.constraint(equalToConstant: bounds.width),
            refreshControl.heightAnchor.constraint(equalToConstant: 60),
            refreshControl.bottomAnchor.constraint(equalTo: topAnchor, constant: -60)
        ])

        ls_refreshControl = refreshControl
        return refreshControl
    }

    /// 结束刷新
    func ls_endRefreshing() {
        ls_refreshControl?.endRefreshing()
    }

    /// 开始刷新
    func ls_beginRefreshing() {
        ls_refreshControl?.beginRefreshing()
    }
}

// MARK: - 无限滚动控件

/// 无限滚动控件
public class LSInfiniteScrollControl: UIView {

    // MARK: - 类型定义

    /// 加载更多回调
    public typealias LoadMoreHandler = () -> Void

    // MARK: - 属性

    /// 加载更多回调
    public var onLoadMore: LoadMoreHandler?

    /// 是否正在加载
    public private(set) var isLoading: Bool = false

    /// 触发阈值（距离底部多少像素触发）
    public var triggerThreshold: CGFloat = 60

    /// 指示器
    private let indicatorView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    /// 状态标签
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.text = "加载更多"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 关联的滚动视图
    public weak var scrollView: UIScrollView? {
        didSet {
            setupScrollViewObservers()
        }
    }

    /// 是否已触发过
    private var hasTriggered: Bool = false

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
        backgroundColor = .clear

        addSubview(indicatorView)
        addSubview(statusLabel)

        NSLayoutConstraint.activate([
            indicatorView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            indicatorView.centerYAnchor.constraint(equalTo: centerYAnchor),

            statusLabel.leadingAnchor.constraint(equalTo: indicatorView.trailingAnchor, constant: 12),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20),
            statusLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    private func setupScrollViewObservers() {
        guard let scrollView = scrollView else { return }

        scrollView.addObserver(
            self,
            forKeyPath: "contentOffset",
            options: [.new],
            context: nil
        )
    }

    public override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard keyPath == "contentOffset",
              let scrollView = object as? UIScrollView,
              let newOffset = change?[.newKey] as? CGPoint else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

        handleScrollViewDidScroll(scrollView, contentOffset: newOffset)
    }

    // MARK: - 滚动处理

    private func handleScrollViewDidScroll(_ scrollView: UIScrollView, contentOffset: CGPoint) {
        guard !isLoading else { return }

        let contentHeight = scrollView.contentSize.height
        let visibleHeight = scrollView.bounds.height
        let offset = scrollView.contentOffset.y
        let insetBottom = scrollView.contentInset.bottom

        // 计算距离底部距离
        let distanceToBottom = contentHeight - visibleHeight - offset + insetBottom

        if distanceToBottom < triggerThreshold {
            if !hasTriggered {
                hasTriggered = true
                beginLoading()
            }
        } else {
            hasTriggered = false
        }
    }

    // MARK: - 公共方法

    /// 开始加载
    public func beginLoading() {
        guard !isLoading else { return }
        isLoading = true

        statusLabel.text = "正在加载..."
        indicatorView.startAnimating()
        isHidden = false

        onLoadMore?()
    }

    /// 结束加载
    public func endLoading() {
        isLoading = false

        statusLabel.text = "加载更多"
        indicatorView.stopAnimating()

        // 延迟隐藏
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self, !self.isLoading else { return }
            self.isHidden = true
        }
    }

    /// 显示无更多数据
    public func showNoMoreData() {
        isLoading = false
        indicatorView.stopAnimating()
        statusLabel.text = "没有更多数据了"
        isHidden = false
    }

    /// 重置状态
    public func reset() {
        isLoading = false
        hasTriggered = false
        statusLabel.text = "加载更多"
        indicatorView.stopAnimating()
        isHidden = true
    }

    // MARK: - 清理

    deinit {
        scrollView?.removeObserver(self, forKeyPath: "contentOffset")
    }
}

// MARK: - UIScrollView Extension (Infinite Scroll)

public extension UIScrollView {

    private enum AssociatedKeys {
        static var infiniteScrollControlKey: UInt8 = 0
    }var ls_infiniteScrollControl: LSInfiniteScrollControl? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.infiniteScrollControlKey) as? LSInfiniteScrollControl
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.infiniteScrollControlKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// 添加无限滚动
    ///
    /// - Parameters:
    ///   - handler: 加载更多回调
    ///   - threshold: 触发阈值
    /// - Returns: 无限滚动控件
    @discardableResult
    func ls_addInfiniteScroll(
        threshold: CGFloat = 60,
        handler: @escaping () -> Void
    ) -> LSInfiniteScrollControl {
        let infiniteScroll = LSInfiniteScrollControl()
        infiniteScroll.scrollView = self
        infiniteScroll.onLoadMore = handler
        infiniteScroll.triggerThreshold = threshold
        infiniteScroll.isHidden = true

        addSubview(infiniteScroll)
        infiniteScroll.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            infiniteScroll.leadingAnchor.constraint(equalTo: leadingAnchor),
            infiniteScroll.trailingAnchor.constraint(equalTo: trailingAnchor),
            infiniteScroll.heightAnchor.constraint(equalToConstant: 40),
            infiniteScroll.topAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor, constant: -40)
        ])

        ls_infiniteScrollControl = infiniteScroll
        return infiniteScroll
    }

    /// 结束加载更多
    func ls_endLoadingMore() {
        ls_infiniteScrollControl?.endLoading()
    }

    /// 显示无更多数据
    func ls_showNoMoreData() {
        ls_infiniteScrollControl?.showNoMoreData()
    }

    /// 重置无限滚动
    func ls_resetInfiniteScroll() {
        ls_infiniteScrollControl?.reset()
    }
}

#endif

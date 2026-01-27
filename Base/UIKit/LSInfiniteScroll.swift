//
//  LSInfiniteScroll.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  上拉加载更多控件
//

#if canImport(UIKit)
import UIKit

// MARK: - LSInfiniteScrollView

/// 上拉加载更多视图
public class LSInfiniteScrollView: UIView {

    // MARK: - 类型定义

    /// 加载更多回调
    public typealias LoadMoreHandler = () -> Void

    /// 加载状态
    public enum State {
        case idle           // 闲置
        case loading        // 加载中
        case finished       // 已完成（没有更多数据）
        case error          // 错误
    }

    // MARK: - 属性

    /// 状态
    public private(set) var state: State = .idle {
        didSet {
            updateForState()
        }
    }

    /// 加载回调
    public var onLoadMore: LoadMoreHandler?

    /// 触发阈值（距离底部多少像素触发）
    public var triggerThreshold: CGFloat = 60

    /// 指示器样式
    public var indicatorStyle: UIActivityIndicatorView.Style = .medium {
        didSet {
            activityIndicator.style = indicatorStyle
        }
    }

    /// 文本颜色
    public var textColor: UIColor = .secondaryLabel {
        didSet {
            statusLabel.textColor = textColor
        }
    }

    /// 关联的 ScrollView
    private weak var scrollView: UIScrollView?

    /// 原始内容 inset
    private var originalContentInset: UIEdgeInsets = .zero

    /// 是否已触发
    private var hasTriggered: Bool = false

    /// 活动指示器
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    /// 状态标签
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()

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
        addSubview(activityIndicator)
        addSubview(statusLabel)

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            activityIndicator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),

            statusLabel.leadingAnchor.constraint(equalTo: activityIndicator.trailingAnchor, constant: 8),
            statusLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            statusLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        updateForState()
    }

    // MARK: - 配置

    /// 绑定到 ScrollView
    ///
    /// - Parameter scrollView: 目标滚动视图
    func attach(to scrollView: UIScrollView) {
        self.scrollView = scrollView
        self.originalContentInset = scrollView.contentInset

        // 添加 KVO
        scrollView.addObserver(
            self,
            forKeyPath: "contentOffset",
            options: [.new],
            context: nil
        )
    }

    /// 从 ScrollView 分离
    func detach() {
        guard let scrollView = scrollView else { return }

        scrollView.removeObserver(self, forKeyPath: "contentOffset")
        self.scrollView = nil
    }

    // MARK: - KVO

    public override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard keyPath == "contentOffset",
              let scrollView = scrollView,
              let newOffset = change?[.newKey] as? CGPoint else {
            return
        }

        handleContentOffset(newOffset, in: scrollView)
    }

    // MARK: - 内容偏移处理

    private func handleContentOffset(_ contentOffset: CGPoint, in scrollView: UIScrollView) {
        guard state != .loading && state != .finished else { return }

        let contentHeight = scrollView.contentSize.height
        let visibleHeight = scrollView.bounds.height - scrollView.contentInset.top - scrollView.contentInset.bottom
        let distanceToBottom = contentHeight - (contentOffset.y + scrollView.contentInset.top) - visibleHeight

        if distanceToBottom <= triggerThreshold && !hasTriggered {
            hasTriggered = true
            beginLoading()
        } else if distanceToBottom > triggerThreshold * 2 {
            hasTriggered = false
        }
    }

    // MARK: - 加载控制

    /// 开始加载
    public func beginLoading() {
        guard state != .loading && state != .finished else { return }

        state = .loading

        UIView.animate(withDuration: 0.3) {
            guard let scrollView = self.scrollView else { return }
            var inset = scrollView.contentInset
            inset.bottom = self.originalContentInset.bottom + self.bounds.height
            scrollView.contentInset = inset
        }

        onLoadMore?()
    }

    /// 结束加载
    ///
    /// - Parameter finished: 是否已加载完成所有数据
    public func endLoading(finished: Bool = false) {
        guard state == .loading else { return }

        if finished {
            state = .finished
        } else {
            state = .idle
            hasTriggered = false
        }

        UIView.animate(withDuration: 0.3) {
            guard let scrollView = self.scrollView else { return }
            scrollView.contentInset = self.originalContentInset
        }
    }

    /// 重置状态
    public func reset() {
        state = .idle
        hasTriggered = false

        UIView.animate(withDuration: 0.3) {
            guard let scrollView = self.scrollView else { return }
            scrollView.contentInset = self.originalContentInset
        }
    }

    // MARK: - 状态更新

    private func updateForState() {
        switch state {
        case .idle:
            statusLabel.text = ""
            activityIndicator.stopAnimating()
            isHidden = true

        case .loading:
            statusLabel.text = "正在加载..."
            activityIndicator.startAnimating()
            isHidden = false

        case .finished:
            statusLabel.text = "没有更多数据"
            activityIndicator.stopAnimating()
            isHidden = false

        case .error:
            statusLabel.text = "加载失败"
            activityIndicator.stopAnimating()
            isHidden = false
        }
    }
}

// MARK: - UIScrollView Extension

public extension UIScrollView {

    /// 关联的上拉加载视图
    private static var infiniteScrollViewKey: UInt8 = 0

    /// 上拉加载视图
    var ls_infiniteScrollView: LSInfiniteScrollView? {
        get {
            return objc_getAssociatedObject(self, &UIScrollView.infiniteScrollViewKey) as? LSInfiniteScrollView
        }
        set {
            objc_setAssociatedObject(self, &UIScrollView.infiniteScrollViewKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// 添加上拉加载
    ///
    /// - Parameters:
    ///   - handler: 加载回调
    ///   - threshold: 触发阈值
    /// - Returns: 加载视图
    @discardableResult
    func ls_addInfiniteScroll(
        handler: @escaping () -> Void,
        threshold: CGFloat = 60
    ) -> LSInfiniteScrollView {
        // 移除旧的
        ls_removeInfiniteScroll()

        // 创建新的
        let loadMoreView = LSInfiniteScrollView(frame: CGRect(
            x: 0,
            y: 0,
            width: bounds.width,
            height: 60
        ))
        loadMoreView.onLoadMore = handler
        loadMoreView.triggerThreshold = threshold
        loadMoreView.isHidden = true
        ls_infiniteScrollView = loadMoreView

        // 作为 footer view（对于 UITableView）
        if let tableView = self as? UITableView {
            tableView.tableFooterView = loadMoreView
        } else {
            addSubview(loadMoreView)
        }

        loadMoreView.attach(to: self)

        return loadMoreView
    }

    /// 移除上拉加载
    func ls_removeInfiniteScroll() {
        ls_infiniteScrollView?.detach()
        ls_infiniteScrollView?.removeFromSuperview()
        ls_infiniteScrollView = nil

        if let tableView = self as? UITableView {
            tableView.tableFooterView = UIView()
        }
    }

    /// 开始加载
    func ls_beginLoadingMore() {
        ls_infiniteScrollView?.beginLoading()
    }

    /// 结束加载
    ///
    /// - Parameter finished: 是否已加载完成所有数据
    func ls_endLoadingMore(finished: Bool = false) {
        ls_infiniteScrollView?.endLoading(finished: finished)
    }

    /// 重置加载状态
    func ls_resetInfiniteScroll() {
        ls_infiniteScrollView?.reset()
    }

    /// 是否正在加载
    var ls_isLoadingMore: Bool {
        return ls_infiniteScrollView?.state == .loading
    }

    /// 是否已完成加载
    var ls_isLoadMoreFinished: Bool {
        return ls_infiniteScrollView?.state == .finished
    }
}

// MARK: - UITableView Extension

public extension UITableView {

    /// 添加上拉加载
    ///
    /// - Parameters:
    ///   - handler: 加载回调
    ///   - threshold: 触发阈值
    /// - Returns: 加载视图
    @discardableResult
    func ls_addInfiniteScroll(
        handler: @escaping () -> Void,
        threshold: CGFloat = 60
    ) -> LSInfiniteScrollView {
        return (self as UIScrollView).ls_addInfiniteScroll(handler: handler, threshold: threshold)
    }
}

// MARK: - UICollectionView Extension

public extension UICollectionView {

    /// 添加上拉加载
    ///
    /// - Parameters:
    ///   - handler: 加载回调
    ///   - threshold: 触发阈值
    /// - Returns: 加载视图
    @discardableResult
    func ls_addInfiniteScroll(
        handler: @escaping () -> Void,
        threshold: CGFloat = 60
    ) -> LSInfiniteScrollView {
        return (self as UIScrollView).ls_addInfiniteScroll(handler: handler, threshold: threshold)
    }
}

// MARK: - 组合使用

public extension UIScrollView {

    /// 添加下拉刷新和上拉加载
    ///
    /// - Parameters:
    ///   - refreshHandler: 刷新回调
    ///   - loadMoreHandler: 加载回调
    /// - Returns: 元组 (刷新视图, 加载视图)
    @discardableResult
    func ls_addRefreshAndLoadMore(
        refreshHandler: @escaping () -> Void,
        loadMoreHandler: @escaping () -> Void
    ) -> (LSPullToRefreshView, LSInfiniteScrollView) {
        let refreshView = ls_addPullToRefresh(handler: refreshHandler)
        let loadMoreView = ls_addInfiniteScroll(handler: loadMoreHandler)
        return (refreshView, loadMoreView)
    }
}

#endif

//
//  LSPullToRefresh.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  下拉刷新控件
//

#if canImport(UIKit)
import UIKit

// MARK: - LSPullToRefreshView

/// 下拉刷新视图
@MainActor
public class LSPullToRefreshView: UIView {

    // MARK: - 类型定义

    /// 刷新回调
    public typealias RefreshHandler = () -> Void

    /// 刷新状态
    public enum State {
        case idle           // 闲置
        case pulling        // 拖动中
        case ready          // 准备刷新
        case refreshing     // 刷新中
        case finished       // 完成
    }

    // MARK: - 属性

    /// 状态
    public private(set) var state: State = .idle {
        didSet {
            updateForState()
        }
    }

    /// 刷新回调
    public var onRefresh: RefreshHandler?

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

    /// 背景颜色
    public var backgroundColor: UIColor = .clear {
        didSet {
            self.backgroundColor = backgroundColor
        }
    }

    /// 触发刷新的拖动比例
    public var triggerThreshold: CGFloat = 1.0

    /// 关联的 ScrollView
    private weak var scrollView: UIScrollView?

    /// 原始内容 inset
    private var originalContentInset: UIEdgeInsets = .zero

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

    /// 箭头视图
    private let arrowView: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let image = UIImage(systemName: "arrow.down", withConfiguration: config)
        let iv = UIImageView(image: image)
        iv.tintColor = .secondaryLabel
        return iv
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
        addSubview(arrowView)
        addSubview(statusLabel)

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        arrowView.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            activityIndicator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),

            arrowView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            arrowView.centerYAnchor.constraint(equalTo: centerYAnchor),
            arrowView.widthAnchor.constraint(equalToConstant: 20),
            arrowView.heightAnchor.constraint(equalToConstant: 20),

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
            options: [.new, .old],
            context: nil
        )

        // 添加手势
        scrollView.panGestureRecognizer.addTarget(self, action: #selector(handlePanGesture))
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
        guard state != .refreshing else { return }

        let pullDistance = calculatePullDistance(contentOffset, in: scrollView)

        if pullDistance <= 0 {
            state = .idle
        } else if pullDistance < bounds.height * triggerThreshold {
            state = .pulling
        } else {
            state = .ready
        }
    }

    private func calculatePullDistance(_ contentOffset: CGPoint, in scrollView: UIScrollView) -> CGFloat {
        // 计算下拉距离
        let minY = -originalContentInset.top
        return max(0, minY - contentOffset.y)
    }

    // MARK: - 手势处理

    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard let scrollView = scrollView else { return }

        switch gesture.state {
        case .ended:
            if state == .ready {
                beginRefreshing()
            }
        default:
            break
        }
    }

    // MARK: - 刷新控制

    /// 开始刷新
    public func beginRefreshing() {
        guard state != .refreshing else { return }

        state = .refreshing

        UIView.animate(withDuration: 0.3) {
            guard let scrollView = self.scrollView else { return }
            var inset = scrollView.contentInset
            inset.top = self.originalContentInset.top + self.bounds.height
            scrollView.contentInset = inset
        }

        onRefresh?()
    }

    /// 结束刷新
    public func endRefreshing() {
        guard state == .refreshing else { return }

        state = .finished

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }

            UIView.animate(withDuration: 0.3) {
                guard let scrollView = self.scrollView else { return }
                scrollView.contentInset = self.originalContentInset
            } completion: { _ in
                self.state = .idle
            }
        }
    }

    // MARK: - 状态更新

    private func updateForState() {
        switch state {
        case .idle:
            statusLabel.text = "下拉刷新"
            arrowView.isHidden = false
            activityIndicator.stopAnimating()
            arrowView.transform = .identity

        case .pulling:
            statusLabel.text = "继续下拉"
            arrowView.isHidden = false
            activityIndicator.stopAnimating()
            arrowView.transform = .identity

        case .ready:
            statusLabel.text = "释放刷新"
            arrowView.isHidden = false
            activityIndicator.stopAnimating()
            UIView.animate(withDuration: 0.2) {
                self.arrowView.transform = CGAffineTransform(rotationAngle: .pi)
            }

        case .refreshing:
            statusLabel.text = "正在刷新"
            arrowView.isHidden = true
            activityIndicator.startAnimating()

        case .finished:
            statusLabel.text = "刷新完成"
            arrowView.isHidden = true
            activityIndicator.stopAnimating()
        }
    }
}

// MARK: - UIScrollView Extension

public extension UIScrollView {

    /// 关联的下拉刷新视图
    private static var pullToRefreshViewKey: UInt8 = 0

    /// 下拉刷新视图
    var ls_pullToRefreshView: LSPullToRefreshView? {
        get {
            return objc_getAssociatedObject(self, &UIScrollView.pullToRefreshViewKey) as? LSPullToRefreshView
        }
        set {
            objc_setAssociatedObject(self, &UIScrollView.pullToRefreshViewKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// 添加下拉刷新
    ///
    /// - Parameters:
    ///   - handler: 刷新回调
    /// - Returns: 刷新视图
    @discardableResult
    func ls_addPullToRefresh(handler: @escaping () -> Void) -> LSPullToRefreshView {
        // 移除旧的
        ls_removePullToRefresh()

        // 创建新的
        let refreshView = LSPullToRefreshView(frame: CGRect(x: 0, y: -60, width: bounds.width, height: 60))
        refreshView.onRefresh = handler
        addSubview(refreshView)
        refreshView.attach(to: self)
        ls_pullToRefreshView = refreshView

        return refreshView
    }

    /// 移除下拉刷新
    func ls_removePullToRefresh() {
        ls_pullToRefreshView?.detach()
        ls_pullToRefreshView?.removeFromSuperview()
        ls_pullToRefreshView = nil
    }

    /// 开始刷新
    func ls_beginRefreshing() {
        ls_pullToRefreshView?.beginRefreshing()
    }

    /// 结束刷新
    func ls_endRefreshing() {
        ls_pullToRefreshView?.endRefreshing()
    }

    /// 是否正在刷新
    var ls_isRefreshing: Bool {
        return ls_pullToRefreshView?.state == .refreshing
    }
}

// MARK: - UITableView Extension

public extension UITableView {

    /// 添加下拉刷新
    ///
    /// - Parameter handler: 刷新回调
    /// - Returns: 刷新视图
    @discardableResult
    func ls_addPullToRefresh(handler: @escaping () -> Void) -> LSPullToRefreshView {
        return (self as UIScrollView).ls_addPullToRefresh(handler: handler)
    }
}

// MARK: - UICollectionView Extension

public extension UICollectionView {

    /// 添加下拉刷新
    ///
    /// - Parameter handler: 刷新回调
    /// - Returns: 刷新视图
    @discardableResult
    func ls_addPullToRefresh(handler: @escaping () -> Void) -> LSPullToRefreshView {
        return (self as UIScrollView).ls_addPullToRefresh(handler: handler)
    }
}

#endif

//
//  LSPlaceholderView.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  占位视图 - 空状态视图
//

#if canImport(UIKit)
import UIKit

// MARK: - LSPlaceholderView

/// 占位视图
@MainActor
public class LSPlaceholderView: UIView {

    // MARK: - 类型定义

    /// 占位视图类型
    public enum PlaceholderType {
        case empty           // 空数据
        case error           // 错误
        case noNetwork       // 无网络
        case searching       // 搜索中
        case custom          // 自定义
    }

    /// 按钮点击回调
    public typealias ButtonTapHandler = () -> Void

    // MARK: - 属性

    /// 类型
    public var type: PlaceholderType = .empty {
        didSet {
            updateType()
        }
    }

    /// 图片
    public var image: UIImage? {
        didSet {
            imageView.image = image
            imageView.isHidden = (image == nil)
        }
    }

    /// 标题
    public var title: String? {
        didSet {
            titleLabel.text = title
            titleLabel.isHidden = (title == nil)
        }
    }

    /// 消息
    public var message: String? {
        didSet {
            messageLabel.text = message
            messageLabel.isHidden = (message == nil)
        }
    }

    /// 按钮标题
    public var buttonTitle: String? {
        didSet {
            actionButton.setTitle(buttonTitle, for: .normal)
            actionButton.isHidden = (buttonTitle == nil)
        }
    }

    /// 按钮回调
    public var onButtonTap: ButtonTapHandler? {
        didSet {
            updateButtonAction()
        }
    }

    /// 视图间距
    public var spacing: CGFloat = 16 {
        didSet {
            stackView.spacing = spacing
        }
    }

    /// 内容边距
    public var contentInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 40) {
        didSet {
            updateInsets()
        }
    }

    // MARK: - UI 组件

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .systemGray3
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 18)
        label.textColor = .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupPlaceholder()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPlaceholder()
    }

    // MARK: - 设置

    private func setupPlaceholder() {
        addSubview(stackView)

        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(messageLabel)
        stackView.addArrangedSubview(actionButton)

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 80),

            actionButton.widthAnchor.constraint(equalToConstant: 120),
            actionButton.heightAnchor.constraint(equalToConstant: 40)
        ])

        updateType()
        updateButtonAction()
    }

    public override func updateConstraints() {
        super.updateConstraints()

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: contentInsets.left),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -contentInsets.right)
        ])
    }

    // MARK: - 更新

    private func updateType() {
        switch type {
        case .empty:
            image = UIImage(systemName: "tray")
            title = "暂无数据"
            message = "这里还没有任何内容"

        case .error:
            image = UIImage(systemName: "exclamationmark.triangle")
            title = "出错了"
            message = "加载失败，请稍后再试"

        case .noNetwork:
            image = UIImage(systemName: "wifi.slash")
            title = "无网络连接"
            message = "请检查网络设置后重试"

        case .searching:
            image = UIImage(systemName: "magnifyingglass")
            title = "搜索中"
            message = "正在搜索..."

        case .custom:
            break
        }
    }

    private func updateButtonAction() {
        actionButton.ls_removeAllActions()
        actionButton.ls_addAction(for: .touchUpInside) { [weak self] _ in
            self?.onButtonTap?()
        }
    }

    private func updateInsets() {
        setNeedsUpdateConstraints()
    }

    // MARK: - 公共方法

    /// 显示加载状态
    public func showLoading() {
        type = .searching
        actionButton.isHidden = true
    }

    /// 隐藏按钮
    public func hideButton() {
        actionButton.isHidden = true
    }
}

// MARK: - 便捷创建

public extension LSPlaceholderView {

    /// 创建空数据占位视图
    static func empty(
        title: String? = nil,
        message: String? = nil,
        buttonTitle: String? = nil,
        action: ButtonTapHandler? = nil
    ) -> LSPlaceholderView {
        let placeholder = LSPlaceholderView()
        placeholder.type = .custom
        if let tempValue = title {
            title = tempValue
        } else {
            title = "暂无数据"
        }
        if let tempValue = message {
            message = tempValue
        } else {
            message = "这里还没有任何内容"
        }
        placeholder.buttonTitle = buttonTitle
        placeholder.onButtonTap = action
        return placeholder
    }

    /// 创建错误占位视图
    static func error(
        message: String? = nil,
        buttonTitle: String = "重试",
        action: @escaping () -> Void
    ) -> LSPlaceholderView {
        let placeholder = LSPlaceholderView()
        placeholder.type = .error
        placeholder.message = message
        placeholder.buttonTitle = buttonTitle
        placeholder.onButtonTap = action
        return placeholder
    }

    /// 创建无网络占位视图
    static func noNetwork(
        buttonTitle: String = "刷新",
        action: @escaping () -> Void
    ) -> LSPlaceholderView {
        let placeholder = LSPlaceholderView()
        placeholder.type = .noNetwork
        placeholder.buttonTitle = buttonTitle
        placeholder.onButtonTap = action
        return placeholder
    }
}

// MARK: - UIView Extension (Placeholder)

public extension UIView {

    private enum AssociatedKeys {
        static var placeholderViewKey: UInt8 = 0
    }var ls_placeholderView: LSPlaceholderView? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.placeholderViewKey) as? LSPlaceholderView
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.placeholderViewKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// 显示占位视图
    @discardableResult
    func ls_showPlaceholder(
        type: LSPlaceholderView.PlaceholderType = .empty,
        title: String? = nil,
        message: String? = nil,
        buttonTitle: String? = nil,
        action: (() -> Void)? = nil
    ) -> LSPlaceholderView {
        // 移除旧的
        ls_hidePlaceholder()

        let placeholder = LSPlaceholderView()
        placeholder.type = type

        if let title = title {
            placeholder.title = title
        }

        if let message = message {
            placeholder.message = message
        }

        if let buttonTitle = buttonTitle {
            placeholder.buttonTitle = buttonTitle
            placeholder.onButtonTap = action
        }

        addSubview(placeholder)
        placeholder.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            placeholder.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            placeholder.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            placeholder.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            placeholder.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -20)
        ])

        ls_placeholderView = placeholder
        return placeholder
    }

    /// 显示空数据占位
    @discardableResult
    func ls_showEmptyPlaceholder(
        title: String? = nil,
        message: String? = nil,
        buttonTitle: String? = nil,
        action: (() -> Void)? = nil
    ) -> LSPlaceholderView {
        return ls_showPlaceholder(
            type: .empty,
            title: title,
            message: message,
            buttonTitle: buttonTitle,
            action: action
        )
    }

    /// 显示错误占位
    @discardableResult
    func ls_showErrorPlaceholder(
        message: String? = nil,
        buttonTitle: String = "重试",
        action: (() -> Void)? = nil
    ) -> LSPlaceholderView {
        return ls_showPlaceholder(
            type: .error,
            message: message,
            buttonTitle: buttonTitle,
            action: action
        )
    }

    /// 显示无网络占位
    @discardableResult
    func ls_showNoNetworkPlaceholder(
        buttonTitle: String = "刷新",
        action: @escaping () -> Void
    ) -> LSPlaceholderView {
        return ls_showPlaceholder(
            type: .noNetwork,
            buttonTitle: buttonTitle,
            action: action
        )
    }

    /// 隐藏占位视图
    func ls_hidePlaceholder() {
        ls_placeholderView?.removeFromSuperview()
        ls_placeholderView = nil
    }

    /// 是否显示占位视图
    var ls_isShowingPlaceholder: Bool {
        return ls_placeholderView != nil
    }
}

// MARK: - Empty State View

/// 空状态视图
public class LSEmptyStateView: UIView {

    /// 空状态类型
    public enum EmptyType {
        case noData
        case noSearchResults
        case noNotifications
        case noMessages
        case noFavorites
        case noDownloads
        case custom
    }

    /// 类型
    public var emptyType: EmptyType = .noData {
        didSet {
            updateContent()
        }
    }

    /// 自定义图片
    public var customImage: UIImage? {
        didSet {
            if emptyType == .custom {
                imageView.image = customImage
            }
        }
    }

    /// 自定义标题
    public var customTitle: String? {
        didSet {
            if emptyType == .custom {
                titleLabel.text = customTitle
            }
        }
    }

    /// 自定义消息
    public var customMessage: String? {
        didSet {
            if emptyType == .custom {
                messageLabel.text = customMessage
            }
        }
    }

    /// 操作按钮
    public var actionButtonTitle: String? {
        didSet {
            actionButton.setTitle(actionButtonTitle, for: .normal)
            actionButton.isHidden = (actionButtonTitle == nil)
        }
    }

    /// 操作回调
    public var onAction: (() -> Void)?

    // MARK: - UI 组件

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .systemGray3
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 18)
        label.textColor = .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupEmptyState()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupEmptyState()
    }

    // MARK: - 设置

    private func setupEmptyState() {
        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(messageLabel)
        addSubview(actionButton)

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 40),
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 80),

            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40),

            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40),

            actionButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 24),
            actionButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            actionButton.widthAnchor.constraint(equalToConstant: 120),
            actionButton.heightAnchor.constraint(equalToConstant: 40)
        ])

        actionButton.ls_addAction(for: .touchUpInside) { [weak self] in
            self?.onAction?()
        }

        updateContent()
    }

    // MARK: - 更新

    private func updateContent() {
        switch emptyType {
        case .noData:
            imageView.image = UIImage(systemName: "tray")
            titleLabel.text = "暂无数据"
            messageLabel.text = "这里还没有任何内容"

        case .noSearchResults:
            imageView.image = UIImage(systemName: "magnifyingglass")
            titleLabel.text = "无搜索结果"
            messageLabel.text = "没有找到相关内容"

        case .noNotifications:
            imageView.image = UIImage(systemName: "bell.slash")
            titleLabel.text = "暂无通知"
            messageLabel.text = "您还没有收到任何通知"

        case .noMessages:
            imageView.image = UIImage(systemName: "envelope")
            titleLabel.text = "暂无消息"
            messageLabel.text = "您还没有收到任何消息"

        case .noFavorites:
            imageView.image = UIImage(systemName: "heart")
            titleLabel.text = "暂无收藏"
            messageLabel.text = "您还没有收藏任何内容"

        case .noDownloads:
            imageView.image = UIImage(systemName: "icloud.and.arrow.down")
            titleLabel.text = "暂无下载"
            messageLabel.text = "您还没有下载任何内容"

        case .custom:
            imageView.image = customImage
            titleLabel.text = customTitle
            messageLabel.text = customMessage
        }
    }
}

// MARK: - 便捷创建

public extension LSEmptyStateView {

    /// 创建无数据空状态
    static func noData(
        title: String = "暂无数据",
        message: String = "这里还没有任何内容"
    ) -> LSEmptyStateView {
        let emptyView = LSEmptyStateView()
        emptyView.emptyType = .custom
        emptyView.customTitle = title
        emptyView.customMessage = message
        return emptyView
    }
}

// MARK: - Loading State View

/// 加载状态视图
public class LSLoadingStateView: UIView {

    /// 状态类型
    public enum LoadingState {
        case loading
        case success
        case error
        case empty
    }

    /// 状态
    public var state: LoadingState = .loading {
        didSet {
            updateState()
        }
    }

    /// 加载视图
    private let loadingView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .large)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// 图标视图
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    /// 消息标签
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupLoadingState()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLoadingState()
    }

    // MARK: - 设置

    private func setupLoadingState() {
        addSubview(loadingView)
        addSubview(iconImageView)
        addSubview(messageLabel)

        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingView.topAnchor.constraint(equalTo: topAnchor, constant: 40),
            loadingView.widthAnchor.constraint(equalToConstant: 40),
            loadingView.heightAnchor.constraint(equalToConstant: 40),

            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.topAnchor.constraint(equalTo: topAnchor, constant: 40),
            iconImageView.widthAnchor.constraint(equalToConstant: 60),
            iconImageView.heightAnchor.constraint(equalToConstant: 60),

            messageLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 24),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40)
        ])

        updateState()
    }

    // MARK: - 更新

    private func updateState() {
        switch state {
        case .loading:
            loadingView.startAnimating()
            loadingView.isHidden = false
            iconImageView.isHidden = true
            messageLabel.text = "加载中..."

        case .success:
            loadingView.stopAnimating()
            loadingView.isHidden = true
            iconImageView.isHidden = false
            iconImageView.image = UIImage(systemName: "checkmark.circle.fill")
            iconImageView.tintColor = .systemGreen
            messageLabel.text = "加载成功"

        case .error:
            loadingView.stopAnimating()
            loadingView.isHidden = true
            iconImageView.isHidden = false
            iconImageView.image = UIImage(systemName: "xmark.circle.fill")
            iconImageView.tintColor = .systemRed
            messageLabel.text = "加载失败"

        case .empty:
            loadingView.stopAnimating()
            loadingView.isHidden = true
            iconImageView.isHidden = false
            iconImageView.image = UIImage(systemName: "tray")
            iconImageView.tintColor = .systemGray3
            messageLabel.text = "暂无数据"
        }
    }
}

#endif

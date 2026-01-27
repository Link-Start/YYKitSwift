//
//  LSActionController.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  动作控制器 - 自定义样式的动作表单和警报视图
//

#if canImport(UIKit)
import UIKit

// MARK: - LSActionController

/// 动作控制器基类
public class LSActionController: UIViewController {

    // MARK: - 类型定义

    /// 动作项
    public struct Action {
        let title: String?
        let subtitle: String?
        let image: UIImage?
        let style: Style
        let isEnabled: Bool
        let action: (() -> Void)?

        public enum Style {
            case `default`
            case cancel
            case destructive
            case custom(UIColor)
        }

        public init(
            title: String? = nil,
            subtitle: String? = nil,
            image: UIImage? = nil,
            style: Style = .default,
            isEnabled: Bool = true,
            action: (() -> Void)? = nil
        ) {
            self.title = title
            self.subtitle = subtitle
            self.image = image
            self.style = style
            self.isEnabled = isEnabled
            self.action = action
        }

        /// 创建默认动作
        public static func `default`(_ title: String, action: (() -> Void)? = nil) -> Action {
            return Action(title: title, style: .default, action: action)
        }

        /// 创建取消动作
        public static func cancel(_ title: String = "取消", action: (() -> Void)? = nil) -> Action {
            return Action(title: title, style: .cancel, action: action)
        }

        /// 创建危险动作
        public static func destructive(_ title: String, action: (() -> Void)? = nil) -> Action {
            return Action(title: title, style: .destructive, action: action)
        }
    }

    /// 动作处理回调
    public typealias ActionHandler = (Action) -> Void

    // MARK: - 属性

    /// 标题
    public var controllerTitle: String? {
        didSet {
            updateTitle()
        }
    }

    /// 消息
    public var message: String? {
        didSet {
            updateMessage()
        }
    }

    /// 动作数组
    public var actions: [Action] = [] {
        didSet {
            updateActions()
        }
    }

    /// 是否显示
    public private(set) var isVisible: Bool = false

    /// 显示完成后回调
    public var onPresent: (() -> Void)?

    /// 消失完成后回调
    public var onDismiss: (() -> Void)?

    /// 点击背景是否关闭
    public var dismissesOnBackgroundTap: Bool = true

    // MARK: - UI 组件

    internal let backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.alpha = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    internal let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    internal let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    internal let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - 初始化

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setupActionController()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupActionController()
    }

    public convenience init(
        title: String? = nil,
        message: String? = nil,
        actions: [Action] = []
    ) {
        self.init()
        self.controllerTitle = title
        self.message = message
        self.actions = actions
    }

    // MARK: - 设置

    private func setupActionController() {
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(backgroundView)
        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(messageLabel)

        // 背景点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
        backgroundView.addGestureRecognizer(tapGesture)

        setupConstraints()
        updateTitle()
        updateMessage()
        updateActions()
    }

    internal func setupConstraints() {
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(lessThanOrEqualToConstant: 320)
        ])
    }

    // MARK: - 更新方法

    internal func updateTitle() {
        titleLabel.text = controllerTitle
        titleLabel.isHidden = (controllerTitle == nil)
    }

    internal func updateMessage() {
        messageLabel.text = message
        messageLabel.isHidden = (message == nil)
    }

    internal func updateActions() {
        // 子类重写
    }

    // MARK: - 显示/隐藏

    /// 显示控制器
    public func show(in viewController: UIViewController, animated: Bool = true) {
        viewController.present(self, animated: animated) {
            self.isVisible = true
            self.onPresent?()
        }
    }

    /// 显示在当前窗口
    public func show(animated: Bool = true) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }

        show(in: rootViewController, animated: animated)
    }

    /// 隐藏控制器
    public func hide(animated: Bool = true) {
        dismiss(animated: animated) {
            self.isVisible = false
            self.onDismiss?()
        }
    }

    // MARK: - 手势处理

    @objc private func handleBackgroundTap() {
        if dismissesOnBackgroundTap {
            hide()
        }
    }
}

// MARK: - LSAlertController

/// 警报控制器
public class LSAlertController: LSActionController {

    // MARK: - 属性

    /// 警报样式
    public var alertStyle: AlertStyle = .alert {
        didSet {
            updateStyle()
        }
    }

    /// 自定义视图
    public var customView: UIView? {
        didSet {
            updateCustomView()
        }
    }

    // MARK: - 警报样式

    public enum AlertStyle {
        case alert
        case actionSheet
    }

    // MARK: - UI 组件

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let buttonsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - 初始化

    public override func viewDidLoad() {
        super.viewDidLoad()

        containerView.addSubview(stackView)
        containerView.addSubview(buttonsStackView)

        setupAlertConstraints()
    }

    private func setupAlertConstraints() {
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: buttonsStackView.topAnchor, constant: -8),

            buttonsStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            buttonsStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            buttonsStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }

    // MARK: - 更新方法

    private func updateStyle() {
        // 可以根据样式调整布局
    }

    private func updateCustomView() {
        // 移除旧的
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // 添加标题和消息
        if !titleLabel.isHidden {
            stackView.addArrangedSubview(titleLabel)
        }

        if !messageLabel.isHidden {
            stackView.addArrangedSubview(messageLabel)
        }

        // 添加自定义视图
        if let customView = customView {
            stackView.addArrangedSubview(customView)
        }
    }

    internal override func updateActions() {
        // 移除旧按钮
        buttonsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (index, action) in actions.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(action.title, for: .normal)
            button.isEnabled = action.isEnabled

            // 设置样式
            switch action.style {
            case .default:
                button.setTitleColor(.systemBlue, for: .normal)
            case .cancel:
                button.setTitleColor(.systemBlue, for: .normal)
                button.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
            case .destructive:
                button.setTitleColor(.systemRed, for: .normal)
            case .custom(let color):
                button.setTitleColor(color, for: .normal)
            }

            // 添加分隔线
            if index > 0 {
                let separator = UIView()
                separator.backgroundColor = .separator
                separator.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    separator.heightAnchor.constraint(equalToConstant: 0.5)
                ])
                buttonsStackView.addArrangedSubview(separator)
            }

            button.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                button.heightAnchor.constraint(equalToConstant: 44)
            ])

            button.ls_addAction(for: .touchUpInside) { [weak self] in
                action.action?()
                self?.hide()
            }

            buttonsStackView.addArrangedSubview(button)
        }
    }

    // MARK: - 便捷创建方法

    /// 创建简单警报
    public static func alert(
        title: String? = nil,
        message: String? = nil,
        confirmButtonTitle: String = "确定",
        cancelButtonTitle: String? = nil,
        onConfirm: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) -> LSAlertController {
        var actions: [Action] = []

        if let cancel = cancelButtonTitle {
            actions.append(.cancel(cancel, action: onCancel))
        }

        actions.append(.default(confirmButtonTitle, action: onConfirm))

        return LSAlertController(title: title, message: message, actions: actions)
    }

    /// 创建确认对话框
    public static func confirm(
        title: String? = nil,
        message: String? = nil,
        confirmButtonTitle: String = "确定",
        cancelButtonTitle: String = "取消",
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) -> LSAlertController {
        let actions = [
            Action.cancel(cancelButtonTitle, action: onCancel),
            Action.default(confirmButtonTitle, action: onConfirm)
        ]

        return LSAlertController(title: title, message: message, actions: actions)
    }
}

// MARK: - LSActionSheetController

/// 动作表单控制器
public class LSActionSheetController: LSActionController {

    // MARK: - 属性

    /// 是否在底部显示
    public var showsAtBottom: Bool = true

    // MARK: - UI 组件

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.showsHorizontalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - 初始化

    public override func viewDidLoad() {
        super.viewDidLoad()

        containerView.addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        setupActionSheetConstraints()
    }

    private func setupActionSheetConstraints() {
        if showsAtBottom {
            NSLayoutConstraint.activate([
                containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                containerView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.7)
            ])
        } else {
            NSLayoutConstraint.activate([
                containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                containerView.widthAnchor.constraint(equalToConstant: 270)
            ])
        }

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -8),

            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    // MARK: - 更新方法

    internal override func updateActions() {
        // 清空现有内容
        contentStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // 添加标题和消息
        if let title = controllerTitle, let message = message {
            let headerView = createHeaderView(title: title, message: message)
            contentStackView.addArrangedSubview(headerView)
        }

        // 添加取消按钮
        if let cancelAction = actions.first(where: { $0.style == .cancel }) {
            let cancelButton = createButton(for: cancelAction)
            contentStackView.addArrangedSubview(createSeparator())
            contentStackView.addArrangedSubview(cancelButton)
        }

        // 添加其他动作
        for action in actions where action.style != .cancel {
            let button = createButton(for: action)
            if contentStackView.arrangedSubviews.count > 0 {
                contentStackView.addArrangedSubview(createSeparator())
            }
            contentStackView.addArrangedSubview(button)
        }
    }

    private func createHeaderView(title: String, message: String) -> UIView {
        let view = UIView()
        view.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        view.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        titleLabel.textColor = .secondaryLabel
        titleLabel.textAlignment = .center

        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.font = .systemFont(ofSize: 13, weight: .medium)
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        view.addSubview(titleLabel)
        view.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            messageLabel.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor)
        ])

        return view
    }

    private func createButton(for action: Action) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(action.title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18)
        button.contentEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        button.isEnabled = action.isEnabled

        switch action.style {
        case .default:
            button.setTitleColor(.systemBlue, for: .normal)
        case .cancel:
            button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
            button.setTitleColor(.systemBlue, for: .normal)
        case .destructive:
            button.setTitleColor(.systemRed, for: .normal)
        case .custom(let color):
            button.setTitleColor(color, for: .normal)
        }

        button.ls_addAction(for: .touchUpInside) { [weak self] in
            action.action?()
            self?.hide()
        }

        return button
    }

    private func createSeparator() -> UIView {
        let view = UIView()
        view.backgroundColor = .separator
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: 0.5)
        ])
        return view
    }

    // MARK: - 便捷创建方法

    /// 创建简单动作表单
    public static func actionSheet(
        title: String? = nil,
        message: String? = nil,
        actions: [Action] = []
    ) -> LSActionSheetController {
        return LSActionSheetController(title: title, message: message, actions: actions)
    }

    /// 创建分享动作表单
    public static func shareSheet(
        items: [Any],
        excludedActivityTypes: [UIActivity.ActivityType]? = nil
    ) -> UIActivityViewController {
        let activityVC = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        activityVC.excludedActivityTypes = excludedActivityTypes
        return activityVC
    }
}

// MARK: - UIViewController Extension (Action)

public extension UIViewController {

    /// 显示警报
    func ls_showAlert(
        title: String? = nil,
        message: String? = nil,
        confirmButtonTitle: String = "确定",
        cancelButtonTitle: String? = nil,
        onConfirm: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        let alert = LSAlertController.alert(
            title: title,
            message: message,
            confirmButtonTitle: confirmButtonTitle,
            cancelButtonTitle: cancelButtonTitle,
            onConfirm: onConfirm,
            onCancel: onCancel
        )
        alert.show(in: self)
    }

    /// 显示确认对话框
    func ls_showConfirm(
        title: String? = nil,
        message: String? = nil,
        confirmButtonTitle: String = "确定",
        cancelButtonTitle: String = "取消",
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        let alert = LSAlertController.confirm(
            title: title,
            message: message,
            confirmButtonTitle: confirmButtonTitle,
            cancelButtonTitle: cancelButtonTitle,
            onConfirm: onConfirm,
            onCancel: onCancel
        )
        alert.show(in: self)
    }

    /// 显示动作表单
    func ls_showActionSheet(
        title: String? = nil,
        message: String? = nil,
        actions: [LSActionController.Action]
    ) {
        let actionSheet = LSActionSheetController.actionSheet(
            title: title,
            message: message,
            actions: actions
        )
        actionSheet.show(in: self)
    }

    /// 显示加载提示
    func ls_showLoading(message: String? = nil) -> LSProgressView {
        let progressView = LSProgressView(frame: view.bounds)
        progressView.label.text = message
        view.addSubview(progressView)
        progressView.show()
        return progressView
    }

    /// 显示成功提示
    func ls_showSuccess(_ message: String, duration: TimeInterval = 2.0) {
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.mode = .text
        hud.label.text = message
        hud.hide(animated: true, afterDelay: duration)
    }

    /// 显示错误提示
    func ls_showError(_ message: String, duration: TimeInterval = 2.0) {
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.mode = .text
        hud.label.text = message
        hud.detailsLabel.text = "错误"
        hud.hide(animated: true, afterDelay: duration)
    }

    /// 显示文本提示
    func ls_showText(_ message: String, duration: TimeInterval = 2.0) {
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.mode = .text
        hud.label.text = message
        hud.hide(animated: true, afterDelay: duration)
    }
}

// MARK: - MBProgressHUD Helper

/// 进度提示视图（简化版）
public class LSProgressView: UIView {

    public let label: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 14)
        lbl.textColor = .white
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .white
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupProgress()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupProgress()
    }

    private func setupProgress() {
        addSubview(containerView)
        containerView.addSubview(activityIndicator)
        containerView.addSubview(label)

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 100),
            containerView.heightAnchor.constraint(equalToConstant: 100),

            activityIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: -10),

            label.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 8),
            label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8)
        ])
    }

    public func show() {
        isHidden = false
        alpha = 0
        activityIndicator.startAnimating()

        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
        }
    }

    public func hide() {
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
        }) { _ in
            self.isHidden = true
            self.activityIndicator.stopAnimating()
        }
    }
}

#endif

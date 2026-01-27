//
//  LSSheetView.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  底部表单视图 - 类似 UIAlertController 的 ActionSheet 样式
//

#if canImport(UIKit)
import UIKit

// MARK: - LSSheetView

/// 底部表单视图
public class LSSheetView: UIView {

    // MARK: - 类型定义

    /// 选项项
    public struct Item {
        let title: String
        let subtitle: String?
        let image: UIImage?
        let textColor: UIColor?
        let isEnabled: Bool
        let action: (() -> Void)?

        public init(
            title: String,
            subtitle: String? = nil,
            image: UIImage? = nil,
            textColor: UIColor? = nil,
            isEnabled: Bool = true,
            action: (() -> Void)? = nil
        ) {
            self.title = title
            self.subtitle = subtitle
            self.image = image
            self.textColor = textColor
            self.isEnabled = isEnabled
            self.action = action
        }
    }

    /// 取消回调
    public typealias CancelHandler = () -> Void

    // MARK: - 属性

    /// 标题
    public var sheetTitle: String? {
        didSet {
            titleLabel.text = sheetTitle
            titleLabel.isHidden = (sheetTitle == nil)
        }
    }

    /// 消息
    public var message: String? {
        didSet {
            messageLabel.text = message
            messageLabel.isHidden = (message == nil)
        }
    }

    /// 选项数组
    public var items: [Item] = [] {
        didSet {
            updateItems()
        }
    }

    /// 取消按钮标题
    public var cancelButtonTitle: String = "取消" {
        didSet {
            cancelButton.setTitle(cancelButtonTitle, for: .normal)
        }
    }

    /// 取消回调
    public var onCancel: CancelHandler?

    /// 背景遮罩颜色
    public var maskColor: UIColor = UIColor.black.withAlphaComponent(0.5)

    /// 表单圆角
    public var sheetCornerRadius: CGFloat = 12 {
        didSet {
            containerView.layer.cornerRadius = sheetCornerRadius
        }
    }

    // MARK: - UI 组件

    private let maskView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        return view
    }()

    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private var itemButtons: [UIButton] = []

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSheet()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSheet()
    }

    // MARK: - 设置

    private func setupSheet() {
        addSubview(maskView)
        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(messageLabel)
        containerView.addSubview(stackView)
        containerView.addSubview(cancelButton)

        NSLayoutConstraint.activate([
            maskView.topAnchor.constraint(equalTo: topAnchor),
            maskView.leadingAnchor.constraint(equalTo: leadingAnchor),
            maskView.trailingAnchor.constraint(equalTo: trailingAnchor),
            maskView.bottomAnchor.constraint(equalTo: bottomAnchor),

            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            stackView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            cancelButton.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 8),
            cancelButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            cancelButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            cancelButton.heightAnchor.constraint(equalToConstant: 56)
        ])

        // 添加遮罩点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMaskTap))
        maskView.addGestureRecognizer(tapGesture)

        // 取消按钮事件
        cancelButton.ls_addAction(for: .touchUpInside) { [weak self] _ in
            self?.dismiss()
        }

        // 设置初始位置
        containerView.transform = CGAffineTransform(translationX: 0, y: containerView.bounds.height)
    }

    // MARK: - 更新

    private func updateItems() {
        // 移除旧的按钮
        itemButtons.forEach { $0.removeFromSuperview() }
        itemButtons.removeAll()

        for item in items {
            let button = UIButton(type: .system)
            button.titleLabel?.font = .systemFont(ofSize: 20)
            button.setTitle(item.title, for: .normal)

            if let textColor = item.textColor {
                button.setTitleColor(textColor, for: .normal)
            }

            if let image = item.image {
                button.setImage(image, for: .normal)
            }

            button.isEnabled = item.isEnabled
            button.alpha = item.isEnabled ? 1.0 : 0.5

            button.translatesAutoresizingMaskIntoConstraints = false
            button.heightAnchor.constraint(equalToConstant: 56).isActive = true

            // 添加分隔线
            let divider = UIView()
            divider.backgroundColor = .separator
            divider.translatesAutoresizingMaskIntoConstraints = false
            divider.heightAnchor.constraint(equalToConstant: 0.5).isActive = true

            stackView.addArrangedSubview(divider)
            stackView.addArrangedSubview(button)

            // 按钮事件
            button.ls_addAction(for: .touchUpInside) { [weak self, weak button] _ in
                guard let self = self else { return }
                item.action?()
                self.dismiss()
            }

            itemButtons.append(button)
        }
    }

    // MARK: - 手势处理

    @objc private func handleMaskTap() {
        dismiss()
    }

    // MARK: - 公共方法

    /// 显示
    func show(in view: UIView) {
        frame = view.bounds
        view.addSubview(self)

        // 动画显示
        maskView.alpha = 0
        containerView.transform = CGAffineTransform(translationX: 0, y: containerView.bounds.height)

        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            options: .curveEaseOut
        ) {
            self.maskView.alpha = 1
            self.containerView.transform = .identity
        }
    }

    /// 显示在窗口
    func showInWindow() {
        guard let window = LSKeyWindow.keyWindow else { return }
        show(in: window)
    }

    /// 隐藏
    func dismiss() {
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            options: .curveEaseIn
        ) {
            self.maskView.alpha = 0
            self.containerView.transform = CGAffineTransform(translationX: 0, y: self.containerView.bounds.height)
        } completion: { _ in
            self.removeFromSuperview()
            self.onCancel?()
        }
    }

    /// 添加标题
    func setTitle(_ title: String) {
        sheetTitle = title
    }

    /// 添加消息
    func setMessage(_ message: String) {
        self.message = message
    }

    /// 添加选项
    func addItem(
        title: String,
        subtitle: String? = nil,
        image: UIImage? = nil,
        textColor: UIColor? = nil,
        action: (() -> Void)? = nil
    ) {
        let item = Item(
            title: title,
            subtitle: subtitle,
            image: image,
            textColor: textColor,
            action: action
        )
        items.append(item)
        updateItems()
    }

    /// 添加取消项
    func addCancelItem(title: String) {
        cancelButtonTitle = title
    }
}

// MARK: - UIViewController Extension (Sheet)

public extension UIViewController {

    /// 显示底部表单
    @discardableResult
    func ls_showSheet(
        title: String? = nil,
        message: String? = nil,
        items: [LSSheetView.Item],
        cancelButtonTitle: String = "取消",
        onCancel: (() -> Void)? = nil
    ) -> LSSheetView {
        let sheet = LSSheetView()
        sheet.sheetTitle = title
        sheet.message = message
        sheet.items = items
        sheet.cancelButtonTitle = cancelButtonTitle
        sheet.onCancel = onCancel

        sheet.showInWindow()

        return sheet
    }

    /// 显示简单的选项表单
    @discardableResult
    func ls_showActionSheet(
        title: String? = nil,
        message: String? = nil,
        actions: [String],
        cancelTitle: String = "取消",
        onCancel: (() -> Void)? = nil,
        completion: @escaping (Int?) -> Void
    ) -> LSSheetView {
        let items: [LSSheetView.Item] = actions.enumerated().map { index, title in
            return LSSheetView.Item(title: title) {
                completion(index)
            }
        }

        return ls_showSheet(
            title: title,
            message: message,
            items: items,
            cancelButtonTitle: cancelTitle,
            onCancel: {
                completion(nil)
                onCancel?()
            }
        )
    }

    /// 显示确认表单
    @discardableResult
    func ls_showConfirmSheet(
        title: String? = nil,
        message: String? = nil,
        confirmTitle: String = "确定",
        destructiveTitle: String? = nil,
        cancelTitle: String = "取消",
        onConfirm: @escaping () -> Void,
        onDestructive: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) -> LSSheetView {
        var items: [LSSheetView.Item] = []

        if let destructive = destructiveTitle {
            items.append(LSSheetView.Item(
                title: destructive,
                textColor: .systemRed,
                action: onDestructive
            ))
        }

        items.append(LSSheetView.Item(title: confirmTitle, action: onConfirm))

        return ls_showSheet(
            title: title,
            message: message,
            items: items,
            cancelButtonTitle: cancelTitle,
            onCancel: onCancel
        )
    }
}

// MARK: - Share Sheet

/// 分享表单
public class LSShareSheet: LSSheetView {

    public init(
        title: String? = nil,
        items: [LSShareItem],
        onCancel: (() -> Void)? = nil
    ) {
        super.init(frame: .zero)

        sheetTitle = title
        self.items = items.map { item in
            LSSheetView.Item(
                title: item.title,
                image: item.image,
                action: item.action
            )
        }
        self.onCancel = onCancel
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

/// 分享项
public struct LSShareItem {
    let title: String
    let image: UIImage?
    let action: () -> Void

    public init(title: String, image: UIImage?, action: @escaping () -> Void) {
        self.title = title
        self.image = image
        self.action = action
    }
}

public extension UIViewController {

    /// 显示分享表单
    @discardableResult
    func ls_showShareSheet(
        title: String? = nil,
        items: [LSShareItem],
        onCancel: (() -> Void)? = nil
    ) -> LSShareSheet {
        let sheet = LSShareSheet(title: title, items: items, onCancel: onCancel)
        sheet.showInWindow()
        return sheet
    }

    /// 显示系统分享
    func ls_showSystemShare(
        items: [Any],
        sourceView: UIView? = nil
    ) {
        let activityVC = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )

        if let popover = activityVC.popoverPresentationController,
           let sourceView = sourceView {
            popover.sourceView = sourceView
            popover.sourceRect = sourceView.bounds
        }

        present(activityVC, animated: true)
    }
}

// MARK: - Action Sheet (AlertController Style)

/// UIAlertController 样式的操作表
public extension UIViewController {

    /// 显示操作表
    func ls_showActionSheet(
        title: String? = nil,
        message: String? = nil,
        actions: [LSActionSheetAction],
        cancelTitle: String = "取消",
        sourceView: UIView? = nil
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)

        // 添加操作
        for action in actions {
            let alertAction = UIAlertAction(
                title: action.title,
                style: action.style,
                handler: { _ in
                    action.handler?()
                }
            )
            alert.addAction(alertAction)
        }

        // 添加取消
        alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel, handler: nil))

        // 设置弹出位置
        if let popover = alert.popoverPresentationController,
           let sourceView = sourceView ?? view {
            popover.sourceView = sourceView
            popover.sourceRect = sourceView.bounds
        }

        present(alert, animated: true)
    }
}

/// 操作表动作
public struct LSActionSheetAction {
    let title: String
    let style: UIAlertAction.Style
    let handler: (() -> Void)?

    public init(
        title: String,
        style: UIAlertAction.Style = .default,
        handler: (() -> Void)? = nil
    ) {
        self.title = title
        self.style = style
        self.handler = handler
    }

    /// 默认操作
    public static func `default`(_ title: String, handler: (() -> Void)? = nil) -> LSActionSheetAction {
        return LSActionSheetAction(title: title, style: .default, handler: handler)
    }

    /// 危险操作
    public static func destructive(_ title: String, handler: (() -> Void)? = nil) -> LSActionSheetAction {
        return LSActionSheetAction(title: title, style: .destructive, handler: handler)
    }
}

#endif

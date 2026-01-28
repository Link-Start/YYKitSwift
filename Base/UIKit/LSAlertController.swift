//
//  LSAlertController.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  Alert 工具 - 便捷的对话框显示
//

#if canImport(UIKit)
import UIKit

// MARK: - LSAlertController

/// Alert 工具类
public enum LSAlertController {

    // MARK: - 基础 Alert

    /// 显示基础 Alert
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - message: 消息
    ///   - buttons: 按钮标题数组
    ///   - preferredButtonIndex: 默认按钮索引
    ///   - completion: 完成回调（返回点击的按钮索引）
    /// - Returns: UIAlertController 实例
    @discardableResult
    public static func alert(
        title: String?,
        message: String?,
        buttons: [String] = ["确定"],
        preferredButtonIndex: Int? = nil,
        completion: ((Int) -> Void)? = nil
    ) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        for (index, title) in buttons.enumerated() {
            let action = UIAlertAction(title: title, style: .default) { _ in
                completion?(index)
            }

            if let preferredIndex = preferredButtonIndex, index == preferredIndex {
                alert.preferredAction = action
            }

            alert.addAction(action)
        }

        present(alert)

        return alert
    }

    /// 显示确认对话框
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - message: 消息
    ///   - confirmTitle: 确认按钮标题
    ///   - cancelTitle: 取消按钮标题
    ///   - confirm: 确认回调
    /// - Returns: UIAlertController 实例
    @discardableResult
    public static func confirm(
        title: String? = nil,
        message: String?,
        confirmTitle: String = "确定",
        cancelTitle: String = "取消",
        confirm: @escaping () -> Void
    ) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel))
        alert.addAction(UIAlertAction(title: confirmTitle, style: .default) { _ in
            confirm()
        })

        present(alert)

        return alert
    }

    /// 显示错误对话框
    ///
    /// - Parameters:
    ///   - error: 错误
    ///   - completion: 完成回调
    /// - Returns: UIAlertController 实例
    @discardableResult
    public static func error(
        _ error: Error,
        completion: (() -> Void)? = nil
    ) -> UIAlertController {
        return alert(
            title: "错误",
            message: error.localizedDescription,
            buttons: ["确定"],
            completion: { _ in
                completion?()
            }
        )
    }

    /// 显示提示对话框
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - message: 消息
    ///   - completion: 完成回调
    /// - Returns: UIAlertController 实例
    @discardableResult
    public static func notice(
        title: String? = nil,
        message: String,
        completion: (() -> Void)? = nil
    ) -> UIAlertController {
        return alert(
            title: title,
            message: message,
            buttons: ["知道了"],
            completion: { _ in
                completion?()
            }
        )
    }

    // MARK: - Action Sheet

    /// 显示 Action Sheet
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - message: 消息
    ///   - actions: 操作数组
    ///   - completion: 完成回调（返回点击的操作索引，取消返回 -1）
    /// - Returns: UIAlertController 实例
    @discardableResult
    public static func actionSheet(
        title: String? = nil,
        message: String? = nil,
        actions: [Action],
        completion: ((Int) -> Void)? = nil
    ) -> UIAlertController {
        let sheet = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)

        for (index, action) in actions.enumerated() {
            let alertAction = UIAlertAction(title: action.title, style: action.style) { _ in
                completion?(index)
            }
            sheet.addAction(alertAction)
        }

        sheet.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in
            completion?(-1)
        })

        present(sheet, sourceView: nil)

        return sheet
    }

    // MARK: - 输入对话框

    /// 显示单行输入对话框
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - message: 消息
    ///   - placeholder: 占位符
    ///   - text: 默认文本
    ///   - confirmTitle: 确认按钮标题
    ///   - cancelTitle: 取消按钮标题
    ///   - confirm: 确认回调（返回输入的文本）
    /// - Returns: UIAlertController 实例
    @discardableResult
    public static func input(
        title: String? = nil,
        message: String? = nil,
        placeholder: String = "",
        text: String? = nil,
        confirmTitle: String = "确定",
        cancelTitle: String = "取消",
        confirm: @escaping (String?) -> Void
    ) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = placeholder
            textField.text = text
        }

        alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel) { _ in
            confirm(nil)
        })

        alert.addAction(UIAlertAction(title: confirmTitle, style: .default) { _ in
            confirm(alert.textFields?.first?.text)
        })

        present(alert)

        return alert
    }

    /// 显示多行输入对话框
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - message: 消息
    ///   - placeholder: 占位符
    ///   - text: 默认文本
    ///   - confirmTitle: 确认按钮标题
    ///   - cancelTitle: 取消按钮标题
    ///   - confirm: 确认回调（返回输入的文本）
    /// - Returns: UIAlertController 实例
    @discardableResult
    public static func textView(
        title: String? = nil,
        message: String? = nil,
        placeholder: String = "",
        text: String? = nil,
        confirmTitle: String = "确定",
        cancelTitle: String = "取消",
        confirm: @escaping (String?) -> Void
    ) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = placeholder
            textField.text = text
        }

        alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel) { _ in
            confirm(nil)
        })

        alert.addAction(UIAlertAction(title: confirmTitle, style: .default) { _ in
            confirm(alert.textFields?.first?.text)
        })

        present(alert)

        // 注意：UIAlertController 的 textField 默认不支持多行
        // 如需多行输入，需使用自定义视图控制器

        return alert
    }

    /// 显示密码输入对话框
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - message: 消息
    ///   - placeholder: 占位符
    ///   - confirmTitle: 确认按钮标题
    ///   - cancelTitle: 取消按钮标题
    ///   - confirm: 确认回调（返回输入的密码）
    /// - Returns: UIAlertController 实例
    @discardableResult
    public static func password(
        title: String? = nil,
        message: String? = nil,
        placeholder: String = "请输入密码",
        confirmTitle: String = "确定",
        cancelTitle: String = "取消",
        confirm: @escaping (String?) -> Void
    ) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = placeholder
            textField.isSecureTextEntry = true
        }

        alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel) { _ in
            confirm(nil)
        })

        alert.addAction(UIAlertAction(title: confirmTitle, style: .default) { _ in
            confirm(alert.textFields?.first?.text)
        })

        present(alert)

        return alert
    }

    /// 显示双输入对话框（如登录时的用户名/密码）
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - message: 消息
    ///   - placeholders: 占位符数组
    ///   - confirmTitle: 确认按钮标题
    ///   - cancelTitle: 取消按钮标题
    ///   - confirm: 确认回调（返回输入的文本数组）
    /// - Returns: UIAlertController 实例
    @discardableResult
    public static func doubleInput(
        title: String? = nil,
        message: String? = nil,
        placeholders: [String] = ["", ""],
        confirmTitle: String = "确定",
        cancelTitle: String = "取消",
        confirm: @escaping ([String?]) -> Void
    ) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        for placeholder in placeholders {
            alert.addTextField { textField in
                textField.placeholder = placeholder
            }
        }

        alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel) { _ in
            confirm([nil, nil])
        })

        alert.addAction(UIAlertAction(title: confirmTitle, style: .default) { _ in
            if let tempValue = alert.textFields?.map { $0.text } {
                texts = tempValue
            } else {
                texts = []
            }
            confirm(texts)
        })

        present(alert)

        return alert
    }

    // MARK: - 等待对话框

    /// 显示等待对话框
    ///
    /// - Parameters:
    ///   - message: 消息
    ///   - inView: 父视图
    /// - Returns: LSProgressHUD 实例（用于手动关闭）
    @discardableResult
    public static func waiting(message: String? = nil, inView: UIView? = nil) -> LSProgressHUD {
        let hud = LSProgressHUD.showAdded(to: inView, animated: true)
        hud.label.text = message
        return hud
    }

    /// 显示成功提示
    ///
    /// - Parameters:
    ///   - message: 消息
    ///   - inView: 父视图
    /// - Returns: LSProgressHUD 实例
    @discardableResult
    public static func success(message: String, inView: UIView? = nil) -> LSProgressHUD {
        let hud = LSProgressHUD.showAdded(to: inView, animated: true)
        hud.mode = .customView
        hud.customView = UIImageView(image: LSProgressHUD.successImage)
        hud.label.text = message
        hud.hide(animated: true, afterDelay: 2)
        return hud
    }

    /// 显示错误提示
    ///
    /// - Parameters:
    ///   - message: 消息
    ///   - inView: 父视图
    /// - Returns: LSProgressHUD 实例
    @discardableResult
    public static func failure(message: String, inView: UIView? = nil) -> LSProgressHUD {
        let hud = LSProgressHUD.showAdded(to: inView, animated: true)
        hud.mode = .customView
        hud.customView = UIImageView(image: LSProgressHUD.errorImage)
        hud.label.text = message
        hud.hide(animated: true, afterDelay: 2)
        return hud
    }

    /// 显示信息提示
    ///
    /// - Parameters:
    ///   - message: 消息
    ///   - inView: 父视图
    /// - Returns: LSProgressHUD 实例
    @discardableResult
    public static func info(message: String, inView: UIView? = nil) -> LSProgressHUD {
        let hud = LSProgressHUD.showAdded(to: inView, animated: true)
        hud.mode = .text
        hud.label.text = message
        hud.hide(animated: true, afterDelay: 2)
        return hud
    }

    // MARK: - 底部弹出

    /// 显示底部弹出菜单（iOS 14+ 风格）
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - actions: 操作数组
    ///   - completion: 完成回调（返回点击的操作索引，取消返回 nil）
    @available(iOS 14.0, *)
    public static func menu(
        title: String? = nil,
        actions: [Action],
        completion: ((Int?) -> Void)?
    ) {
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
              let rootVC = window.rootViewController else {
            return
        }

        var menuActions: [UIAction] = []

        for (index, action) in actions.enumerated() {
            let uiAction = UIAction(title: action.title, image: action.image) { _ in
                completion?(index)
            }
            uiAction.attributes = action.style == .destructive ? .destructive : []
            menuActions.append(uiAction)
        }

        let cancelAction = UIAction(title: "取消") { _ in
            completion?(nil)
        }

        let menu
        if let tempMenu = title {
            menu = tempMenu
        } else {
            menu = "", children: menuActions + [cancelAction])
        }

        if let button = rootVC.view {
            button.showMenu(menu)
        }
    }

    // MARK: - 私有方法

    /// 显示 AlertController
    private static func present(_ alert: UIAlertController, sourceView: UIView? = nil) {
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
              let rootVC = window.rootViewController else {
            return
        }

        var topVC = rootVC
        while let presentedVC = topVC.presentedViewController {
            topVC = presentedVC
        }

        // 对于 iPad 的 Action Sheet，需要设置 source
        if alert.preferredStyle == .actionSheet, UIDevice.current.userInterfaceIdiom == .pad {
            if let tempValue = sourceView {
                sourceView = tempValue
            } else {
                sourceView = topVC.view
            }
            alert.popoverPresentationController?.sourceRect = CGRect(
                x: topVC.view.bounds.midX,
                y: topVC.view.bounds.midY,
                width: 0,
                height: 0
            )
            alert.popoverPresentationController?.permittedArrowDirections = []
        }

        topVC.present(alert, animated: true)
    }
}

// MARK: - Action

public extension LSAlertController {

    /// Action 定义
    struct Action {
        /// 标题
        public let title: String
        /// 样式
        public let style: UIAlertAction.Style
        /// 图标
        public let image: UIImage?

        public init(title: String, style: UIAlertAction.Style = .default, image: UIImage? = nil) {
            self.title = title
            self.style = style
            self.image = image
        }
    }
}

// MARK: - UIView Extension (菜单显示)

@available(iOS 14.0, *)
private extension UIView {
    func showMenu(_ menu: UIMenu) {
        let interaction = UIInteractionManager(configuration: [])

        let button = UIButton(type: .system)
        button.showsMenuAsPrimaryAction = true
        button.menu = menu
        button.sendActions(for: .touchUpInside)
    }
}

// MARK: - LSProgressHUD (简化版)

/// 简化的 Progress HUD
@MainActor
public class LSProgressHUD: UIView {

    // MARK: - 静态图片

    public static var successImage: UIImage {
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .medium)
        if let tempValue = UIImage(systemName: "checkmark.circle.fill", withConfiguration: config) {
            return tempValue
        }
        return UIImage()
    }

    public static var errorImage: UIImage {
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .medium)
        if let tempValue = UIImage(systemName: "xmark.circle.fill", withConfiguration: config) {
            return tempValue
        }
        return UIImage()
    }

    // MARK: - 属性

    public var mode: Mode = .indeterminate {
        didSet {
            updateViews()
        }
    }

    public var customView: UIView? {
        didSet {
            updateViews()
        }
    }

    public let label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.7)
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        return view
    }()

    private let indicatorView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .whiteLarge)
        return indicator
    }()

    // MARK: - Mode

    public enum Mode {
        case indeterminate
        case customView
        case text
    }

    // MARK: - 初始化

    public init() {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = UIColor(white: 0, alpha: 0.3)

        addSubview(containerView)
        containerView.addSubview(indicatorView)
        containerView.addSubview(label)

        containerView.translatesAutoresizingMaskIntoConstraints = false
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80),

            indicatorView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            indicatorView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 15),

            label.topAnchor.constraint(equalTo: indicatorView.bottomAnchor, constant: 10),
            label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 15),
            label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -15),
            label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -15)
        ])
    }

    private func updateViews() {
        indicatorView.isHidden = mode != .indeterminate
        customView?.isHidden = mode != .customView

        if mode == .customView, let customView = customView {
            containerView.addSubview(customView)
            customView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                customView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                customView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 15)
            ])
        }
    }

    // MARK: - 显示方法

    public static func showAdded(to view: UIView?, animated: Bool) -> LSProgressHUD {
        let hud = LSProgressHUD()

        if let view = view {
            view.addSubview(hud)
            hud.frame = view.bounds
            hud.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        } else if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            window.addSubview(hud)
            hud.frame = window.bounds
            hud.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }

        if animated {
            hud.alpha = 0
            UIView.animate(withDuration: 0.3) {
                hud.alpha = 1
            }
        }

        hud.indicatorView.startAnimating()

        return hud
    }

    public func hide(animated: Bool) {
        hide(animated: animated, afterDelay: 0)
    }

    public func hide(animated: Bool, afterDelay: TimeInterval) {
        let hideBlock: () -> Void = { [weak self] in
            guard let self = self else { return }
            self.indicatorView.stopAnimating()

            if animated {
                UIView.animate(withDuration: 0.3, animations: {
                    self.alpha = 0
                }, completion: { _ in
                    self.removeFromSuperview()
                })
            } else {
                self.removeFromSuperview()
            }
        }

        if afterDelay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + afterDelay, execute: hideBlock)
        } else {
            hideBlock()
        }
    }
}

#endif

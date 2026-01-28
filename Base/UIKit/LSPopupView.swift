//
//  LSPopupView.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  弹出视图 - 通用弹窗组件
//

#if canImport(UIKit)
import UIKit

// MARK: - LSPopupView

/// 弹出视图
@MainActor
public class LSPopupView: UIView {

    // MARK: - 类型定义

    /// 弹出位置
    public enum PopupPosition {
        case center
        case top
        case bottom
        case custom(CGPoint)
    }

    /// 弹出动画
    public enum PopupAnimation {
        case none
        case fade
        case scale
        case slideFromTop
        case slideFromBottom
        case slideFromLeft
        case slideFromRight
        case custom((UIView, Bool) -> Void)
    }

    /// 背景点击回调
    public typealias BackgroundTapHandler = () -> Void

    // MARK: - 属性

    /// 内容视图
    public let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        return view
    }()

    /// 弹出位置
    public var position: PopupPosition = .center

    /// 弹出动画
    public var animation: PopupAnimation = .scale

    /// 背景颜色
    public var maskColor: UIColor = UIColor.black.withAlphaComponent(0.5) {
        didSet {
            maskView.backgroundColor = maskColor
        }
    }

    /// 是否允许背景点击
    public var allowsBackgroundTap: Bool = true {
        didSet {
            maskTapGesture.isEnabled = allowsBackgroundTap
        }
    }

    /// 背景点击回调
    public var onBackgroundTap: BackgroundTapHandler?

    /// 弹出状态
    public private(set) var isPopupVisible: Bool = false

    // MARK: - UI 组件

    private let maskView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        return view
    }()

    private let maskTapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer()
        return gesture
    }()

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupPopup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPopup()
    }

    public init(contentView: UIView) {
        super.init(frame: .zero)
        self.contentView.subviews.forEach { $0.removeFromSuperview() }
        contentView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
        ])
        setupPopup()
    }

    // MARK: - 设置

    private func setupPopup() {
        addSubview(maskView)
        addSubview(contentView)

        NSLayoutConstraint.activate([
            maskView.topAnchor.constraint(equalTo: topAnchor),
            maskView.leadingAnchor.constraint(equalTo: leadingAnchor),
            maskView.trailingAnchor.constraint(equalTo: trailingAnchor),
            maskView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentView.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        maskTapGesture.addTarget(self, action: #selector(handleMaskTap))
        maskView.addGestureRecognizer(maskTapGesture)
    }

    // MARK: - 手势处理

    @objc private func handleMaskTap() {
        guard allowsBackgroundTap else { return }
        onBackgroundTap?()
        dismiss()
    }

    // MARK: - 公共方法

    /// 显示
    func show(in view: UIView, animated: Bool = true) {
        frame = view.bounds
        view.addSubview(self)

        isPopupVisible = true

        guard animated else {
            return
        }

        // 执行进入动画
        performAnimation(isShowing: true)
    }

    /// 显示在窗口
    func showInWindow(animated: Bool = true) {
        guard let window = LSKeyWindow.keyWindow else { return }
        show(in: window, animated: animated)
    }

    /// 隐藏
    func dismiss(animated: Bool = true) {
        isPopupVisible = false

        guard animated else {
            removeFromSuperview()
            return
        }

        // 执行退出动画
        performAnimation(isShowing: false) { [weak self] in
            self?.removeFromSuperview()
        }
    }

    // MARK: - 动画

    private func performAnimation(isShowing: Bool, completion: (() -> Void)? = nil) {
        switch animation {
        case .none:
            completion?()

        case .fade:
            UIView.animate(withDuration: 0.3, animations: {
                self.maskView.alpha = isShowing ? 1 : 0
                self.contentView.alpha = isShowing ? 1 : 0
            }, completion: { _ in
                completion?()
            })

        case .scale:
            if isShowing {
                maskView.alpha = 0
                contentView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                contentView.alpha = 0

                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
                    self.maskView.alpha = 1
                    contentView.alpha = 1
                    contentView.transform = .identity
                }
            } else {
                UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn) {
                    self.maskView.alpha = 0
                    contentView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                    contentView.alpha = 0
                }, completion: { _ in
                    completion?()
                })
            }

        case .slideFromTop:
            if isShowing {
                contentView.transform = CGAffineTransform(translationX: 0, y: -bounds.height)
                contentView.alpha = 0

                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
                    self.maskView.alpha = 1
                    contentView.alpha = 1
                    contentView.transform = .identity
                }
            } else {
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
                    self.maskView.alpha = 0
                    contentView.transform = CGAffineTransform(translationX: 0, y: -bounds.height)
                    contentView.alpha = 0
                }, completion: { _ in
                    completion?()
                })
            }

        case .slideFromBottom:
            if isShowing {
                contentView.transform = CGAffineTransform(translationX: 0, y: bounds.height)
                contentView.alpha = 0

                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
                    self.maskView.alpha = 1
                    contentView.alpha = 1
                    contentView.transform = .identity
                }
            } else {
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
                    self.maskView.alpha = 0
                    contentView.transform = CGAffineTransform(translationX: 0, y: bounds.height)
                    contentView.alpha = 0
                }, completion: { _ in
                    completion?()
                })
            }

        case .slideFromLeft:
            if isShowing {
                contentView.transform = CGAffineTransform(translationX: -bounds.width, y: 0)
                contentView.alpha = 0

                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
                    self.maskView.alpha = 1
                    contentView.alpha = 1
                    contentView.transform = .identity
                }
            } else {
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
                    self.maskView.alpha = 0
                    contentView.transform = CGAffineTransform(translationX: -bounds.width, y: 0)
                    contentView.alpha = 0
                }, completion: { _ in
                    completion?()
                })
            }

        case .slideFromRight:
            if isShowing {
                contentView.transform = CGAffineTransform(translationX: bounds.width, y: 0)
                contentView.alpha = 0

                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
                    self.maskView.alpha = 1
                    contentView.alpha = 1
                    contentView.transform = .identity
                }
            } else {
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
                    self.maskView.alpha = 0
                    contentView.transform = CGAffineTransform(translationX: bounds.width, y: 0)
                    contentView.alpha = 0
                }, completion: { _ in
                    completion?()
                })
            }

        case .custom(let customAnimation):
            customAnimation(self, isShowing)
            completion?()
        }
    }
}

// MARK: - 便捷创建

public extension LSPopupView {

    /// 创建简单弹出视图
    static func create(
        content: UIView,
        position: PopupPosition = .center,
        animation: PopupAnimation = .scale,
        allowsBackgroundTap: Bool = true
    ) -> LSPopupView {
        let popup = LSPopupView(contentView: content)
        popup.position = position
        popup.animation = animation
        popup.allowsBackgroundTap = allowsBackgroundTap
        return popup
    }

    /// 创建文字弹出视图
    static func message(
        _ message: String,
        title: String? = nil,
        position: PopupPosition = .center,
        animation: PopupAnimation = .scale
    ) -> LSPopupView {
        let contentView = UIView()
        contentView.backgroundColor = .systemBackground
        contentView.layer.cornerRadius = 12

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.font = .systemFont(ofSize: 16)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(titleLabel)
        contentView.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            messageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])

        let popup = LSPopupView(contentView: contentView)
        popup.position = position
        popup.animation = animation

        return popup
    }
}

// MARK: - UIViewController Extension (Popup)

public extension UIViewController {

    /// 关联的弹出视图
    private static var popupViewKey: UInt8 = 0

    var ls_popupView: LSPopupView? {
        get {
            return objc_getAssociatedObject(self, &UIViewController.popupViewKey) as? LSPopupView
        }
        set {
            objc_setAssociatedObject(
                self,
                &UIViewController.popupViewKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// 显示弹出视图
    @discardableResult
    func ls_showPopup(
        content: UIView,
        position: LSPopupView.PopupPosition = .center,
        animation: LSPopupView.PopupAnimation = .scale,
        allowsBackgroundTap: Bool = true,
        onBackgroundTap: (() -> Void)? = nil
    ) -> LSPopupView {
        // 移除旧的
        ls_dismissPopup()

        let popup = LSPopupView.create(
            content: content,
            position: position,
            animation: animation,
            allowsBackgroundTap: allowsBackgroundTap
        )
        popup.onBackgroundTap = onBackgroundTap

        popup.showInWindow()
        ls_popupView = popup

        return popup
    }

    /// 显示文字弹出
    @discardableResult
    func ls_showPopupMessage(
        _ message: String,
        title: String? = nil,
        position: LSPopupView.PopupPosition = .center,
        animation: LSPopupView.PopupAnimation = .scale,
        duration: TimeInterval? = nil
    ) -> LSPopupView {
        let popup = LSPopupView.message(
            message,
            title: title,
            position: position,
            animation: animation
        )

        popup.showInWindow()

        // 自动隐藏
        if let duration = duration {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                popup.dismiss()
            }
        }

        ls_popupView = popup
        return popup
    }

    /// 隐藏弹出视图
    func ls_dismissPopup(animated: Bool = true) {
        ls_popupView?.dismiss(animated: animated)
        ls_popupView = nil
    }
}

// MARK: - Loading Popup

/// 加载弹出视图
public class LSLoadingPopup: LSPopupView {

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    public init(message: String? = nil) {
        super.init(frame: .zero)

        let contentView = UIView()
        contentView.backgroundColor = .systemBackground
        contentView.layer.cornerRadius = 12
        contentView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(activityIndicator)
        contentView.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),

            messageLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 16),
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            messageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),

            contentView.widthAnchor.constraint(equalToConstant: 120),
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120)
        ])

        self.contentView.subviews.forEach { $0.removeFromSuperview() }
        self.contentView.addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
        ])

        messageLabel.text = message
        messageLabel.isHidden = (message == nil)

        animation = .scale
        allowsBackgroundTap = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public override func show(in view: UIView, animated: Bool = true) {
        super.show(in: view, animated: animated)
        activityIndicator.startAnimating()
    }

    public override func dismiss(animated: Bool = true) {
        activityIndicator.stopAnimating()
        super.dismiss(animated: animated)
    }
}

public extension UIViewController {

    /// 显示加载弹窗
    @discardableResult
    func ls_showLoadingPopup(
        message: String? = nil,
        animated: Bool = true
    ) -> LSLoadingPopup {
        // 移除旧的
        ls_dismissPopup()

        let loading = LSLoadingPopup(message: message)
        loading.showInWindow(animated: animated)

        ls_popupView = loading
        return loading
    }

    /// 隐藏加载弹窗
    func ls_hideLoadingPopup(animated: Bool = true) {
        guard let loading = ls_popupView as? LSLoadingPopup else {
            ls_dismissPopup(animated: animated)
            return
        }

        loading.dismiss(animated: animated)
        ls_popupView = nil
    }
}

// MARK: - Toast Popup

/// Toast 弹出视图
public class LSToastPopup: LSPopupView {

    public init(
        message: String,
        duration: TimeInterval = 2,
        position: PopupPosition = .center
    ) {
        let label = UILabel()
        label.text = message
        label.font = .systemFont(ofSize: 16)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        let contentView = UIView()
        contentView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        contentView.layer.cornerRadius = 8
        contentView.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            contentView.widthAnchor.constraint(lessThanOrEqualToConstant: 280)
        ])

        super.init(contentView: contentView)

        self.position = position
        self.animation = .scale
        self.allowsBackgroundTap = true

        // 自动隐藏
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.dismiss()
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

public extension UIViewController {

    /// 显示 Toast
    @discardableResult
    func ls_showToast(
        _ message: String,
        duration: TimeInterval = 2,
        position: LSPopupView.PopupPosition = .center
    ) -> LSToastPopup {
        let toast = LSToastPopup(message: message, duration: duration, position: position)
        toast.showInWindow()
        return toast
    }
}

#endif

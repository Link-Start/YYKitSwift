//
//  LSTextKeyboardManager.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  键盘管理器 - 监听键盘显示/隐藏事件
//

#if canImport(UIKit)
import UIKit

// MARK: - LSTextKeyboardManagerDelegate

/// 键盘管理器代理协议
@MainActor
public protocol LSTextKeyboardManagerDelegate: AnyObject {
    /// 键盘即将显示
    ///
    /// - Parameters:
    ///   - manager: 键盘管理器
    ///   - keyboardRect: 键盘框架（屏幕坐标系）
    ///   - animationDuration: 动画时长
    ///   - animationCurve: 动画曲线
    @objc optional func keyboardManager(_ manager: LSTextKeyboardManager, keyboardWillShow keyboardRect: CGRect, animationDuration: TimeInterval, animationCurve: UIView.AnimationCurve)

    /// 键盘已显示
    ///
    /// - Parameters:
    ///   - manager: 键盘管理器
    ///   - keyboardRect: 键盘框架（屏幕坐标系）
    @objc optional func keyboardManager(_ manager: LSTextKeyboardManager, keyboardDidShow keyboardRect: CGRect)

    /// 键盘即将隐藏
    ///
    /// - Parameters:
    ///   - manager: 键盘管理器
    ///   - animationDuration: 动画时长
    ///   - animationCurve: 动画曲线
    @objc optional func keyboardManager(_ manager: LSTextKeyboardManager, keyboardWillHide animationDuration: TimeInterval, animationCurve: UIView.AnimationCurve)

    /// 键盘已隐藏
    ///
    /// - Parameter manager: 键盘管理器
    @objc optional func keyboardManagerDidHide(_ manager: LSTextKeyboardManager)

    /// 键盘框架变化
    ///
    /// - Parameters:
    ///   - manager: 键盘管理器
    ///   - keyboardRect: 新的键盘框架（屏幕坐标系）
    ///   - animationDuration: 动画时长
    ///   - animationCurve: 动画曲线
    @objc optional func keyboardManager(_ manager: LSTextKeyboardManager, keyboardDidChange keyboardRect: CGRect, animationDuration: TimeInterval, animationCurve: UIView.AnimationCurve)
}

// MARK: - LSTextKeyboardManager

/// 键盘管理器
///
/// 监听键盘显示/隐藏事件，并通知代理
@MainActor
public class LSTextKeyboardManager: NSObject {

    // MARK: - 属性

    /// 代理
    public weak var delegate: LSTextKeyboardManagerDelegate?

    /// 是否启用（默认 true）
    public var isEnabled: Bool = true {
        didSet {
            if isEnabled {
                _addObservers()
            } else {
                _removeObservers()
            }
        }
    }

    // MARK: - 只读属性

    /// 键盘是否可见
    public private(set) var isKeyboardVisible: Bool = false

    /// 键盘框架（屏幕坐标系）
    public private(set) var keyboardFrame: CGRect = .zero

    /// 当前动画时长
    public private(set) var animationDuration: TimeInterval = 0.25

    /// 当前动画曲线
    public private(set) var animationCurve: UIView.AnimationCurve = .easeInOut

    // MARK: - 私有属性

    private var _isObserving: Bool = false

    // MARK: - 单例

    /// 共享实例
    public static let shared = LSTextKeyboardManager()

    // MARK: - 初始化

    public override init() {
        super.init()
        _addObservers()
    }

    deinit {
        _removeObservers()
    }

    // MARK: - 通知观察

    private func _addObservers() {
        guard !_isObserving else { return }

        _isObserving = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(_keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(_keyboardDidShow(_:)),
            name: UIResponder.keyboardDidShowNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(_keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(_keyboardDidHide(_:)),
            name: UIResponder.keyboardDidHideNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(_keyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(_keyboardDidChangeFrame(_:)),
            name: UIResponder.keyboardDidChangeFrameNotification,
            object: nil
        )
    }

    private func _removeObservers() {
        guard _isObserving else { return }

        _isObserving = false

        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidChangeFrameNotification, object: nil)
    }

    // MARK: - 通知处理

    @objc private func _keyboardWillShow(_ notification: Notification) {
        guard isEnabled else { return }

        _extractKeyboardInfo(from: notification)

        delegate?.keyboardManager?(self, keyboardWillShow: keyboardFrame, animationDuration: animationDuration, animationCurve: animationCurve)
    }

    @objc private func _keyboardDidShow(_ notification: Notification) {
        guard isEnabled else { return }

        isKeyboardVisible = true
        _extractKeyboardInfo(from: notification)

        delegate?.keyboardManager?(self, keyboardDidShow: keyboardFrame)
    }

    @objc private func _keyboardWillHide(_ notification: Notification) {
        guard isEnabled else { return }

        _extractKeyboardInfo(from: notification)

        delegate?.keyboardManager?(self, keyboardWillHide: animationDuration, animationCurve: animationCurve)
    }

    @objc private func _keyboardDidHide(_ notification: Notification) {
        guard isEnabled else { return }

        isKeyboardVisible = false
        keyboardFrame = .zero

        delegate?.keyboardManagerDidHide?(self)
    }

    @objc private func _keyboardWillChangeFrame(_ notification: Notification) {
        guard isEnabled else { return }

        _extractKeyboardInfo(from: notification)

        delegate?.keyboardManager?(self, keyboardDidChange: keyboardFrame, animationDuration: animationDuration, animationCurve: animationCurve)
    }

    @objc private func _keyboardDidChangeFrame(_ notification: Notification) {
        guard isEnabled else { return }

        _extractKeyboardInfo(from: notification)
        isKeyboardVisible = keyboardFrame.height > 0
    }

    // MARK: - 私有方法

    private func _extractKeyboardInfo(from notification: Notification) {
        guard let userInfo = notification.userInfo else { return }

        // 获取键盘框架
        if let frameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            keyboardFrame = frameValue.cgRectValue
        }

        // 获取动画时长
        if let durationValue = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber {
            animationDuration = durationValue.doubleValue
        }

        // 获取动画曲线
        if let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber {
            animationCurve = UIView.AnimationCurve(rawValue: curveValue.intValue) ?? .easeInOut
        }
    }

    // MARK: - 公共方法

    /// 将键盘框架从屏幕坐标转换为视图坐标
    ///
    /// - Parameters:
    ///   - keyboardRect: 键盘框架（屏幕坐标）
    ///   - view: 目标视图
    /// - Returns: 转换后的框架
    public func convertKeyboardFrame(_ keyboardRect: CGRect, to view: UIView) -> CGRect {
        return view.convert(keyboardRect, from: view.window)
    }

    /// 获取键盘在视图中的框架
    ///
    /// - Parameter view: 目标视图
    /// - Returns: 键盘在视图中的框架
    public func keyboardFrame(in view: UIView) -> CGRect {
        return convertKeyboardFrame(keyboardFrame, to: view)
    }

    /// 获取键盘高度（在给定视图中）
    ///
    /// - Parameter view: 目标视图
    /// - Returns: 键盘高度
    public func keyboardHeight(in view: UIView) -> CGFloat {
        return keyboardFrame(in: view).height
    }

    /// 检查点是否在键盘区域内
    ///
    /// - Parameters:
    ///   - point: 点（视图坐标）
    ///   - view: 视图
    /// - Returns: 是否在键盘区域内
    public func isPointInKeyboard(_ point: CGPoint, in view: UIView) -> Bool {
        let keyboardRect = keyboardFrame(in: view)
        return keyboardRect.contains(point)
    }
}

// MARK: - LSTextKeyboardAnimation

/// 键盘动画辅助类
public class LSTextKeyboardAnimation {

    /// 执行键盘动画
    ///
    /// - Parameters:
    ///   - duration: 动画时长
    ///   - curve: 动画曲线
    ///   - animations: 动画块
    ///   - completion: 完成块
    @discardableResult
    public static func animate(
        withDuration duration: TimeInterval,
        curve: UIView.AnimationCurve,
        animations: @escaping () -> Void,
        completion: ((Bool) -> Void)? = nil
    ) -> UIViewPropertyAnimator? {
        let animator: UIViewPropertyAnimator

        if #available(iOS 17.0, *) {
            let options = UIView.AnimationOptions(curve: curve)
            animator = UIViewPropertyAnimator(duration: duration, curve: .init(options.rawValue)) {
                animations()
            }
        } else {
            let options = UIView.AnimationOptions(curve: curve)
            animator = UIViewPropertyAnimator(duration: duration, curve: .easeInOut) {
                UIView.animate(withDuration: duration, delay: 0, options: options, animations: animations)
            }
        }

        animator.addCompletion { position in
            completion?(position == .end)
        }

        animator.startAnimation()
        return animator
    }

    /// 执行与键盘同步的动画
    ///
    /// - Parameters:
    ///   - manager: 键盘管理器
    ///   - animations: 动画块
    ///   - completion: 完成块
    @discardableResult
    public static func animateWithKeyboard(
        manager: LSTextKeyboardManager,
        animations: @escaping () -> Void,
        completion: ((Bool) -> Void)? = nil
    ) -> UIViewPropertyAnimator? {
        return animate(
            withDuration: manager.animationDuration,
            curve: manager.animationCurve,
            animations: animations,
            completion: completion
        )
    }

    /// 执行弹簧动画
    ///
    /// - Parameters:
    ///   - duration: 动画时长
    ///   - damping: 阻尼比（0-1）
    ///   - velocity: 初始速度
    ///   - animations: 动画块
    ///   - completion: 完成块
    @discardableResult
    public static func animateWithSpring(
        duration: TimeInterval,
        damping: CGFloat = 0.8,
        velocity: CGFloat = 0,
        animations: @escaping () -> Void,
        completion: ((Bool) -> Void)? = nil
    ) -> UIViewPropertyAnimator? {
        let animator = UIViewPropertyAnimator(
            duration: duration,
            dampingRatio: damping
        ) {
            animations()
        }

        animator.addCompletion { position in
            completion?(position == .end)
        }

        animator.startAnimation()
        return animator
    }
}

// MARK: - UIView.AnimationCurve Extension

private extension UIView.AnimationCurve {
    init(options: UIView.AnimationOptions) {
        switch options {
        case .curveEaseIn:
            self = .easeIn
        case .curveEaseOut:
            self = .easeOut
        case .curveLinear:
            self = .linear
        default:
            self = .easeInOut
        }
    }
}

#endif

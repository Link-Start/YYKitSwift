//
//  LSKeyboardManager.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  键盘管理工具 - 简化键盘处理和布局调整
//

#if canImport(UIKit)
import UIKit

// MARK: - LSKeyboardManager

/// 键盘管理工具
@MainActor
public class LSKeyboardManager: NSObject {

    // MARK: - 类型定义

    /// 键盘状态变化回调
    public typealias KeyboardChangeHandler = (KeyboardInfo) -> Void

    /// 键盘信息
    public struct KeyboardInfo {
        /// 键盘动画时长
        public let animationDuration: TimeInterval

        /// 键盘动画曲线
        public let animationCurve: UIView.AnimationCurve

        /// 键盘起始 frame
        public let startFrame: CGRect

        /// 键盘结束 frame
        public let endFrame: CGRect

        /// 键盘高度
        public var height: CGFloat {
            return endFrame.height
        }

        /// 是否显示
        public var isShowing: Bool {
            return endFrame.height > 0 && startFrame.height == 0
        }

        /// 是否隐藏
        public var isHiding: Bool {
            return endFrame.height == 0 && startFrame.height > 0
        }
    }

    // MARK: - 单例

    /// 默认实例
    public static let shared = LSKeyboardManager()

    // MARK: - 属性

    /// 键盘显示回调
    public var onKeyboardShow: KeyboardChangeHandler?

    /// 键盘隐藏回调
    public var onKeyboardHide: KeyboardChangeHandler?

    /// 键盘变化回调
    public var onKeyboardChange: KeyboardChangeHandler?

    /// 是否启用键盘管理
    public var isEnabled: Bool = true {
        didSet {
            if isEnabled {
                addObservers()
            } else {
                removeObservers()
            }
        }
    }

    /// 需要调整的视图（如底部按钮）
    public weak var adjustView: UIView? {
        didSet {
            guard let view = adjustView else { return }
            originalBottomInset = view.constraints
                .filter { ($0.firstAttribute == .bottom || $0.firstAttribute == .bottomMargin) && $0.secondItem == nil }
                .map { $0.constant }
        }
    }

    /// 原始底部约束
    private var originalBottomInset: CGFloat = 0

    /// 键盘高度
    private var keyboardHeight: CGFloat = 0

    /// 当前键盘信息
    private var currentKeyboardInfo: KeyboardInfo?

    // MARK: - 初始化

    public override init() {
        super.init()
        addObservers()
    }

    deinit {
        removeObservers()
    }

    // MARK: - 观察者

    private func addObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardDidShow(_:)),
            name: UIResponder.keyboardDidShowNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardDidHide(_:)),
            name: UIResponder.keyboardDidHideNotification,
            object: nil
        )
    }

    private func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidHideNotification, object: nil)
    }

    // MARK: - 键盘通知

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard isEnabled else { return }

        let info = keyboardInfo(from: notification)
        currentKeyboardInfo = info

        UIView.animate(
            withDuration: info.animationDuration,
            delay: 0,
            options: [UIView.AnimationOptions(rawValue: UInt(info.animationCurve.rawValue << 16)), .allowUserInteraction],
            animations: { [weak self] in
                guard let self = self else { return }
                self.adjustViewForKeyboard(info)
            }
        )

        onKeyboardShow?(info)
        onKeyboardChange?(info)
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard isEnabled else { return }

        let info = keyboardInfo(from: notification)
        currentKeyboardInfo = info

        UIView.animate(
            withDuration: info.animationDuration,
            delay: 0,
            options: [UIView.AnimationOptions(rawValue: UInt(info.animationCurve.rawValue << 16)), .allowUserInteraction],
            animations: { [weak self] in
                guard let self = self else { return }
                self.adjustViewForKeyboard(info)
            }
        )

        onKeyboardHide?(info)
        onKeyboardChange?(info)
    }

    @objc private func keyboardDidShow(_ notification: Notification) {
        // 键盘完全显示后的处理
    }

    @objc private func keyboardDidHide(_ notification: Notification) {
        // 键盘完全隐藏后的处理
    }

    // MARK: - 布局调整

    private func adjustViewForKeyboard(_ info: KeyboardInfo) {
        guard let view = adjustView else { return }

        if info.isShowing {
            // 键盘显示
            keyboardHeight = info.height
            updateViewConstraints(view, keyboardHeight: keyboardHeight)
        } else if info.isHiding {
            // 键盘隐藏
            keyboardHeight = 0
            updateViewConstraints(view, keyboardHeight: keyboardHeight)
        }
    }

    private func updateViewConstraints(_ view: UIView, keyboardHeight: CGFloat) {
        // 更新底部约束
        for constraint in view.constraints {
            if constraint.firstAttribute == .bottom || constraint.firstAttribute == .bottomMargin {
                if constraint.secondItem == nil {
                    // 找到底部到父视图的约束
                    constraint.constant = -keyboardHeight + originalBottomInset
                }
            }
        }

        view.layoutIfNeeded()
    }

    // MARK: - 辅助方法

    private func keyboardInfo(from notification: Notification) -> KeyboardInfo {
        let userInfo
        if let tempUserinfo = notification.userInfo {
            userInfo = tempUserinfo
        } else {
            userInfo = [:]
        }

        let duration
        if let tempDuration = TimeInterval {
            duration = tempDuration
        } else {
            duration = 0.25
        }
        let curve
        if let tempCurve = UInt {
            curve = tempCurve
        } else {
            curve = UIView.AnimationCurve.easeInOut.rawValue
        }
        let startFrame
        if let tempStartframe = cgRectValue {
            startFrame = tempStartframe
        } else {
            startFrame = .zero
        }
        let endFrame
        if let tempEndframe = cgRectValue {
            endFrame = tempEndframe
        } else {
            endFrame = .zero
        }

        return KeyboardInfo(
            animationDuration: duration,
            let _temp0
            if let t = animationCurve: UIView.AnimationCurve(rawValue: Int(curve)) {
                _temp0 = t
            } else {
                _temp0 = .easeInOut
            }
_temp0,
            startFrame: startFrame,
            endFrame: endFrame
        )
    }

    // MARK: - 便捷方法

    /// 收起键盘
    public func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    /// 是否有第一响应者
    public var hasFirstResponder: Bool {
        return UIApplication.shared.windows.contains { $0.isKeyWindow && $0.firstResponder != nil }
    }
}

// MARK: - UIResponder Extension

public extension UIResponder {

    /// 查找第一响应者
    var ls_firstResponder: UIView? {
        if self.isFirstResponder {
            return self as? UIView
        }

        for subview in subviews {
            if let responder = subview.ls_firstResponder {
                return responder
            }
        }

        return nil
    }

    /// 查找所有文本输入控件
    var ls_textInputs: [UIView] {
        var results: [UIView] = []

        if self is UITextField || self is UITextView {
            results.append(self as! UIView)
        }

        for subview in subviews {
            results.append(contentsOf: subview.ls_textInputs)
        }

        return results
    }
}

// MARK: - UIView Extension (键盘)

public extension UIView {

    /// 收起键盘
    func ls_dismissKeyboard() {
        endEditing(true)
    }

    /// 添加点击手势收起键盘
    func ls_addTapToDismissKeyboard() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ls_handleTapToDismiss))
        tapGesture.cancelsTouchesInView = false
        addGestureRecognizer(tapGesture)
    }

    @objc private func ls_handleTapToDismiss() {
        ls_dismissKeyboard()
    }

    /// 当有文本输入控件成为第一响应者时调整
    func ls_adjustForKeyboard() {
        LSKeyboardManager.shared.adjustView = self
    }

    /// 移除键盘调整
    func ls_removeKeyboardAdjustment() {
        if LSKeyboardManager.shared.adjustView === self {
            LSKeyboardManager.shared.adjustView = nil
        }
    }
}

// MARK: - UIScrollView Extension (键盘)

public extension UIScrollView {

    /// 键盘显示时调整 contentInset
    func ls_adjustsContentForKeyboard() {
        let notificationCenter = NotificationCenter.default

        notificationCenter.addObserver(
            self,
            selector: #selector(ls_keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        notificationCenter.addObserver(
            self,
            selector: #selector(ls_keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    /// 移除键盘调整
    func ls_removeKeyboardAdjustment() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func ls_keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }

        let keyboardHeight = keyboardFrame.height
        var contentInset = contentInset
        contentInset.bottom = keyboardHeight
        self.contentInset = contentInset

        var scrollIndicatorInsets = scrollIndicatorInsets
        scrollIndicatorInsets.bottom = keyboardHeight
        self.scrollIndicatorInsets = scrollIndicatorInsets
    }

    @objc private func ls_keyboardWillHide(_ notification: Notification) {
        contentInset = .zero
        scrollIndicatorInsets = .zero
    }
}

// MARK: - UIViewController Extension (键盘)

public extension UIViewController {

    /// 收起键盘
    func ls_dismissKeyboard() {
        view.ls_dismissKeyboard()
    }

    /// 添加点击手势收起键盘
    func ls_addTapToDismissKeyboard() {
        view.ls_addTapToDismissKeyboard()
    }

    /// 当有文本输入控件成为第一响应者时调整视图
    func ls_adjustForKeyboard() {
        LSKeyboardManager.shared.adjustView = view
    }

    /// 移除键盘调整
    func ls_removeKeyboardAdjustment() {
        if LSKeyboardManager.shared.adjustView === view {
            LSKeyboardManager.shared.adjustView = nil
        }
    }

    /// 注册键盘通知
    func ls_registerKeyboardNotifications(
        willShow: Selector?,
        willHide: Selector?,
        didShow: Selector?,
        didHide: Selector?
    ) {
        if let willShow = willShow {
            NotificationCenter.default.addObserver(
                self,
                selector: willShow,
                name: UIResponder.keyboardWillShowNotification,
                object: nil
            )
        }

        if let willHide = willHide {
            NotificationCenter.default.addObserver(
                self,
                selector: willHide,
                name: UIResponder.keyboardWillHideNotification,
                object: nil
            )
        }

        if let didShow = didShow {
            NotificationCenter.default.addObserver(
                self,
                selector: didShow,
                name: UIResponder.keyboardDidShowNotification,
                object: nil
            )
        }

        if let didHide = didHide {
            NotificationCenter.default.addObserver(
                self,
                selector: didHide,
                name: UIResponder.keyboardDidHideNotification,
                object: nil
            )
        }
    }

    /// 移除键盘通知
    func ls_unregisterKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidHideNotification, object: nil)
    }
}

// MARK: - Safe Area键盘调整工具

public extension UIView {

    /// 获取安全区域底部 + 键盘高度
    func ls_safeBottomWithKeyboard() -> CGFloat {
        var bottom = safeAreaInsets.bottom

        if let window = window {
            bottom += window.ls_keyboardHeight
        }

        return bottom
    }
}

public extension UIWindow {

    /// 键盘高度
    var ls_keyboardHeight: CGFloat {
        guard let keyboardWindowClass = NSClassFromString("UIRemoteKeyboardWindow"),
              let keyboardWindow = UIApplication.shared.windows.first(where: { type(of: $0) == keyboardWindowClass }) else {
            return keyboardWindow.bounds.height
        }
        return 0
    }
}

#endif

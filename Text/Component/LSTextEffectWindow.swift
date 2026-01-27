//
//  LSTextEffectWindow.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  特效窗口 - 用于显示浮动效果（放大镜、高亮等）
//

#if canImport(UIKit)
import UIKit

// MARK: - LSTextEffectWindow

/// 特效窗口
///
/// 用于在所有视图之上显示浮动效果（如放大镜、高亮等）
public class LSTextEffectWindow: UIWindow {

    // MARK: - 单例

    /// 共享实例
    public static let shared = LSTextEffectWindow()

    // MARK: - 属性

    /// 特效视图
    public private(set) var effectView: UIView?

    /// 是否隐藏状态栏
    public override var prefersStatusBarHidden: Bool {
        return true
    }

    // MARK: - 初始化

    public override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
        _setup()
    }

    public init() {
        // iOS 13+ 使用 windowScene
        if #available(iOS 13.0, *) {
            // 使用默认场景
            super.init(frame: UIScreen.main.bounds)
        } else {
            super.init(frame: UIScreen.main.bounds)
        }
        _setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _setup()
    }

    private func _setup() {
        backgroundColor = .clear
        windowLevel = .statusBar
        isUserInteractionEnabled = false
        isHidden = false
        alpha = 1

        // 根视图
        let rootView = UIView(frame: bounds)
        rootView.backgroundColor = .clear
        rootView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        super.rootViewController = UIViewController(nibName: nil, bundle: nil)
        super.rootViewController?.view = rootView
    }

    // MARK: - 公共方法

    /// 显示特效视图
    ///
    /// - Parameters:
    ///   - view: 特效视图
    ///   - animated: 是否动画
    public func showEffect(_ view: UIView, animated: Bool = true) {
        // 移除旧视图
        if let oldView = effectView {
            oldView.removeFromSuperview()
        }

        effectView = view

        // 添加到根视图
        if let rootView = rootViewController?.view {
            rootView.addSubview(view)

            if animated {
                view.alpha = 0
                UIView.animate(withDuration: 0.2) {
                    view.alpha = 1
                }
            }
        }
    }

    /// 隐藏特效视图
    ///
    /// - Parameter animated: 是否动画
    public func hideEffect(animated: Bool = true) {
        guard let view = effectView else { return }

        if animated {
            UIView.animate(withDuration: 0.15, animations: {
                view.alpha = 0
            }) { _ in
                view.removeFromSuperview()
                self.effectView = nil
            }
        } else {
            view.removeFromSuperview()
            effectView = nil
        }
    }

    /// 显示放大镜
    ///
    /// - Parameters:
    ///   - magnifier: 放大镜视图
    ///   - animated: 是否动画
    public func showMagnifier(_ magnifier: LSTextMagnifier, animated: Bool = true) {
        showEffect(magnifier, animated: animated)
    }

    /// 显示高亮视图
    ///
    /// - Parameters:
    ///   - highlight: 高亮视图
    ///   - animated: 是否动画
    public func showHighlight(_ highlight: LSTextSelectionHighlight, animated: Bool = true) {
        showEffect(highlight, animated: animated)
    }

    /// 显示光标
    ///
    /// - Parameters:
    ///   - caret: 光标视图
    ///   - animated: 是否动画
    public func showCaret(_ caret: LSTextCaretView, animated: Bool = true) {
        showEffect(caret, animated: animated)
    }

    /// 更新特效视图
    ///
    /// - Parameter view: 新的特效视图
    public func updateEffect(_ view: UIView) {
        hideEffect(animated: false)
        showEffect(view, animated: false)
    }
}

// MARK: - LSTextEffectWindowManager

/// 特效窗口管理器
///
/// 管理特效窗口的生命周期
@MainActor
public class LSTextEffectWindowManager {

    // MARK: - 单例

    /// 共享实例
    public static let shared = LSTextEffectWindowManager()

    // MARK: - 属性

    /// 当前活动的特效类型
    public private(set) var activeEffectType: LSTextEffectType?

    /// 当前活动的视图
    public private(set) var activeView: UIView?

    /// 特效窗口
    public var effectWindow: LSTextEffectWindow {
        return LSTextEffectWindow.shared
    }

    // MARK: - 私有属性

    private var _effectViews: [LSTextEffectType: UIView] = [:]

    // MARK: - 初始化

    private init() {}

    // MARK: - 公共方法

    /// 显示特效
    ///
    /// - Parameters:
    ///   - type: 特效类型
    ///   - view: 特效视图
    ///   - animated: 是否动画
    public func showEffect(_ type: LSTextEffectType, view: UIView, animated: Bool = true) {
        // 隐藏当前特效
        hideActiveEffect(animated: animated)

        // 显示新特效
        effectWindow.showEffect(view, animated: animated)

        activeEffectType = type
        activeView = view
        _effectViews[type] = view
    }

    /// 隐藏当前特效
    ///
    /// - Parameter animated: 是否动画
    public func hideActiveEffect(animated: Bool = true) {
        guard let type = activeEffectType else { return }

        hideEffect(type, animated: animated)
    }

    /// 隐藏指定类型的特效
    ///
    /// - Parameters:
    ///   - type: 特效类型
    ///   - animated: 是否动画
    public func hideEffect(_ type: LSTextEffectType, animated: Bool = true) {
        guard let view = _effectViews[type] else { return }

        effectWindow.hideEffect(animated: animated)

        if activeEffectType == type {
            activeEffectType = nil
            activeView = nil
        }

        _effectViews.removeValue(forKey: type)
    }

    /// 隐藏所有特效
    ///
    /// - Parameter animated: 是否动画
    public func hideAllEffects(animated: Bool = true) {
        effectWindow.hideEffect(animated: animated)

        activeEffectType = nil
        activeView = nil
        _effectViews.removeAll()
    }

    /// 更新特效
    ///
    /// - Parameters:
    ///   - type: 特效类型
    ///   - view: 新的特效视图
    public func updateEffect(_ type: LSTextEffectType, view: UIView) {
        _effectViews[type] = view

        if activeEffectType == type {
            effectWindow.updateEffect(view)
            activeView = view
        }
    }

    /// 检查特效是否活动
    ///
    /// - Parameter type: 特效类型
    /// - Returns: 是否活动
    public func isEffectActive(_ type: LSTextEffectType) -> Bool {
        return activeEffectType == type
    }
}

// MARK: - LSTextEffectType

/// 特效类型
public enum LSTextEffectType: Int {
    case magnifier = 0      // 放大镜
    case highlight = 1      // 高亮
    case caret = 2          // 光标
    case selection = 3      // 选择
    case custom = 99        // 自定义
}

// MARK: - LSTextEffectView

/// 特效视图协议
///
/// 所有特效视图应遵循此协议
public protocol LSTextEffectView: UIView {

    /// 特效类型
    var effectType: LSTextEffectType { get }

    /// 显示特效
    ///
    /// - Parameters:
    ///   - point: 位置点
    ///   - view: 目标视图
    ///   - animated: 是否动画
    func show(at point: CGPoint, in view: UIView, animated: Bool)

    /// 隐藏特效
    ///
    /// - Parameter animated: 是否动画
    func hide(animated: Bool)
}

// MARK: - LSTextMagnifier Extension

extension LSTextMagnifier: LSTextEffectView {

    public var effectType: LSTextEffectType {
        return .magnifier
    }
}

// MARK: - LSTextSelectionHighlight Extension

extension LSTextSelectionHighlight: LSTextEffectView {

    public var effectType: LSTextEffectType {
        return .highlight
    }

    public func show(at point: CGPoint, in view: UIView, animated: Bool) {
        center = point
        LSTextEffectWindow.shared.showHighlight(self, animated: animated)
    }

    public func hide(animated: Bool) {
        removeFromSuperview()
    }
}

// MARK: - LSTextCaretView Extension

extension LSTextCaretView: LSTextEffectView {

    public var effectType: LSTextEffectType {
        return .caret
    }

    public func show(at point: CGPoint, in view: UIView, animated: Bool) {
        center = point
        LSTextEffectWindow.shared.showCaret(self, animated: animated)
    }

    public func hide(animated: Bool) {
        removeFromSuperview()
    }
}

// MARK: - 便捷方法

extension LSTextEffectWindowManager {

    /// 显示放大镜
    ///
    /// - Parameters:
    ///   - magnifier: 放大镜视图
    ///   - point: 位置点
    ///   - view: 目标视图
    ///   - animated: 是否动画
    public func showMagnifier(_ magnifier: LSTextMagnifier, at point: CGPoint, in view: UIView, animated: Bool = true) {
        magnifier.show(at: point, in: view, animated: false)
        showEffect(.magnifier, view: magnifier, animated: animated)
    }

    /// 显示高亮
    ///
    /// - Parameters:
    ///   - highlight: 高亮视图
    ///   - point: 位置点
    ///   - view: 目标视图
    ///   - animated: 是否动画
    public func showHighlight(_ highlight: LSTextSelectionHighlight, at point: CGPoint, in view: UIView, animated: Bool = true) {
        highlight.center = point
        showEffect(.highlight, view: highlight, animated: animated)
    }

    /// 显示光标
    ///
    /// - Parameters:
    ///   - caret: 光标视图
    ///   - point: 位置点
    ///   - view: 目标视图
    ///   - animated: 是否动画
    public func showCaret(_ caret: LSTextCaretView, at point: CGPoint, in view: UIView, animated: Bool = true) {
        caret.center = point
        showEffect(.caret, view: caret, animated: animated)
    }
}

#endif

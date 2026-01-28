//
//  LSConstraintLayout.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  约束布局工具 - 简化 Auto Layout 使用
//

#if canImport(UIKit)
import UIKit

// MARK: - LSLayout

/// 约束构建器
@MainActor
public class LSLayout {

    /// 视图
    private weak var view: UIView?

    /// 约束数组
    private var constraints: [NSLayoutConstraint] = []

    /// 初始化
    ///
    /// - Parameter view: 视图
    public init(_ view: UIView) {
        self.view = view
        view.translatesAutoresizingMaskIntoConstraints = false
    }

    /// 添加约束
    ///
    /// - Parameter closure: 约束闭包
    /// - Returns: self
    @discardableResult
    public func make(_ closure: (LSLayout) -> Void) -> Self {
        closure(self)
        return self
    }

    /// 激活约束
    ///
    /// - Returns: self
    @discardableResult
    public func activate() -> Self {
        guard let view = view else { return self }
        NSLayoutConstraint.activate(constraints)
        return self
    }

    /// 设置优先级
    ///
    /// - Parameters:
    ///   - priority: 优先级
    ///   - closure: 约束闭包
    /// - Returns: self
    @discardableResult
    public func priority(_ priority: UILayoutPriority, closure: (LSLayout) -> Void) -> Self {
        let oldConstraints = constraints
        constraints.removeAll()

        closure(self)

        for constraint in constraints {
            constraint.priority = priority
        }

        constraints.append(contentsOf: oldConstraints)
        return self
    }

    // MARK: - 边缘约束

    /// 顶部约束
    ///
    /// - Parameter view: 父视图
    /// - Returns: 约束
    @discardableResult
    public func top(to view: UIView, offset: CGFloat = 0) -> LSLayout {
        let constraint = self.view!.topAnchor.constraint(equalTo: view.topAnchor, constant: offset)
        constraints.append(constraint)
        return self
    }

    /// 底部约束
    ///
    /// - Parameters:
    ///   - view: 父视图
    ///   - offset: 偏移
    /// - Returns: self
    @discardableResult
    public func bottom(to view: UIView, offset: CGFloat = 0) -> LSLayout {
        let constraint = self.view!.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -offset)
        constraints.append(constraint)
        return self
    }

    /// 左侧约束
    ///
    /// - Parameters:
    ///   - view: 父视图
    ///   - offset: 偏移
    /// - Returns: self
    @discardableResult
    public func left(to view: UIView, offset: CGFloat = 0) -> LSLayout {
        let constraint = self.view!.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: offset)
        constraints.append(constraint)
        return self
    }

    /// 右侧约束
    ///
    /// - Parameters:
    ///   - view: 父视图
    ///   - offset: 偏移
    /// - Returns: self
    @discardableResult
    public func right(to view: UIView, offset: CGFloat = 0) -> LSLayout {
        let constraint = self.view!.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -offset)
        constraints.append(constraint)
        return self
    }

    // MARK: - 中心约束

    /// 水平居中
    ///
    /// - Parameter view: 父视图
    /// - Returns: self
    @discardableResult
    public func centerX(to view: UIView) -> LSLayout {
        let constraint = self.view!.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        constraints.append(constraint)
        return self
    }

    /// 垂直居中
    ///
    /// - Parameter view: 父视图
    /// - Returns: self
    @discardableResult
    public func centerY(to view: UIView) -> LSLayout {
        let constraint = self.view!.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        constraints.append(constraint)
        return self
    }

    /// 居中
    ///
    /// - Parameter view: 父视图
    /// - Returns: self
    @discardableResult
    public func center(to view: UIView) -> LSLayout {
        centerX(to: view)
        centerY(to: view)
        return self
    }

    // MARK: - 尺寸约束

    /// 宽度约束
    ///
    /// - Parameter width: 宽度
    /// - Returns: self
    @discardableResult
    public func width(_ width: CGFloat) -> LSLayout {
        let constraint = self.view!.widthAnchor.constraint(equalToConstant: width)
        constraints.append(constraint)
        return self
    }

    /// 宽度约束（相对于视图）
    ///
    /// - Parameters:
    ///   - view: 参考视图
    ///   - multiplier: 倍数
    ///   - constant: 常量
    /// - Returns: self
    @discardableResult
    public func width(to view: UIView, multiplier: CGFloat = 1, constant: CGFloat = 0) -> LSLayout {
        let constraint = self.view!.widthAnchor.constraint(
            equalTo: view.widthAnchor,
            multiplier: multiplier,
            constant: constant
        )
        constraints.append(constraint)
        return self
    }

    /// 高度约束
    ///
    /// - Parameter height: 高度
    /// - Returns: self
    @discardableResult
    public func height(_ height: CGFloat) -> LSLayout {
        let constraint = self.view!.heightAnchor.constraint(equalToConstant: height)
        constraints.append(constraint)
        return self
    }

    /// 高度约束（相对于视图）
    ///
    /// - Parameters:
    ///   - view: 参考视图
    ///   - multiplier: 倍数
    ///   - constant: 常量
    /// - Returns: self
    @discardableResult
    public func height(to view: UIView, multiplier: CGFloat = 1, constant: CGFloat = 0) -> LSLayout {
        let constraint = self.view!.heightAnchor.constraint(
            equalTo: view.heightAnchor,
            multiplier: multiplier,
            constant: constant
        )
        constraints.append(constraint)
        return self
    }

    /// 宽高比约束
    ///
    /// - Parameter ratio: 宽高比
    /// - Returns: self
    @discardableResult
    public func aspectRatio(_ ratio: CGFloat) -> LSLayout {
        let constraint = self.view!.widthAnchor.constraint(
            equalTo: self.view!.heightAnchor,
            multiplier: ratio
        )
        constraints.append(constraint)
        return self
    }

    // MARK: - 组合约束

    /// 填充父视图
    ///
    /// - Parameters:
    ///   - view: 父视图
    ///   - insets: 内边距
    /// - Returns: self
    @discardableResult
    public func fill(to view: UIView, insets: UIEdgeInsets = .zero) -> LSLayout {
        top(to: view, offset: insets.top)
        bottom(to: view, offset: insets.bottom)
        left(to: view, offset: insets.left)
        right(to: view, offset: insets.right)
        return self
    }

    /// 填充安全区域
    ///
    /// - Parameter view: 父视图
    /// - Returns: self
    @discardableResult
    @discardableResult
    public func fillSafeArea(to view: UIView) -> LSLayout {
        if #available(iOS 11.0, *) {
            top(to: view.safeAreaLayoutGuide, offset: 0)
            bottom(to: view.safeAreaLayoutGuide, offset: 0)
            left(to: view.safeAreaLayoutGuide, offset: 0)
            right(to: view.safeAreaLayoutGuide, offset: 0)
        } else {
            fill(to: view)
        }
        return self
    }

    /// 尺寸等于视图
    ///
    /// - Parameter view: 参考视图
    /// - Returns: self
    @discardableResult
    public func size(to view: UIView) -> LSLayout {
        width(to: view)
        height(to: view)
        return self
    }

    /// 尺寸等于视图（带偏移）
    ///
    /// - Parameters:
    ///   - view: 参考视图
    ///   - offset: 偏移
    /// - Returns: self
    @discardableResult
    public func size(to view: UIView, offset: UIEdgeInsets) -> LSLayout {
        width(to: view, constant: -offset.left - offset.right)
        height(to: view, constant: -offset.top - offset.bottom)
        return self
    }
}

// MARK: - UIView Extension (布局)

public extension UIView {

    /// 创建布局构建器
    ///
    /// - Returns: 布局构建器
    func ls_layout() -> LSLayout {
        return LSLayout(self)
    }

    /// 添加子视图并设置约束
    ///
    /// - Parameters:
    ///   - subview: 子视图
    ///   - closure: 约束闭包
    /// - Returns: 子视图
    @discardableResult
    func ls_addSubview(
        _ subview: UIView,
        layout closure: (LSLayout) -> Void
    ) -> UIView {
        addSubview(subview)
        subview.ls_layout().make(closure).activate()
        return subview
    }

    /// 填充父视图
    ///
    /// - Parameter insets: 内边距
    func ls_fillSuperview(insets: UIEdgeInsets = .zero) {
        guard let superview = superview else { return }
        ls_layout().fill(to: superview, insets: insets).activate()
    }

    /// 居中于父视图
    ///
    /// - Parameter size: 可选尺寸
    func ls_centerInSuperview(size: CGSize? = nil) {
        guard let superview = superview else { return }

        let layout = ls_layout()
        layout.center(to: superview)

        if let size = size {
            layout.width(size.width)
            layout.height(size.height)
        }

        layout.activate()
    }

    /// 固定尺寸
    ///
    /// - Parameter size: 尺寸
    func ls_fixedSize(_ size: CGSize) {
        ls_layout().width(size.width).height(size.height).activate()
    }

    /// 固定宽度
    ///
    /// - Parameter width: 宽度
    func ls_fixedWidth(_ width: CGFloat) {
        ls_layout().width(width).activate()
    }

    /// 固定高度
    ///
    /// - Parameter height: 高度
    func ls_fixedHeight(_ height: CGFloat) {
        ls_layout().height(height).activate()
    }

    /// 设置宽高比
    ///
    /// - Parameter ratio: 宽高比
    func ls_aspectRatio(_ ratio: CGFloat) {
        ls_layout().aspectRatio(ratio).activate()
    }

    /// 添加到父视图并设置约束
    ///
    /// - Parameter closure: 约束闭包
    func ls_addToSuperview(_ closure: (UIView, LSLayout) -> Void) {
        superview?.ls_addSubview(self, layout: { layout in
            closure(self, layout)
        })
    }
}

// MARK: - 便捷方法

public extension UIView {

    /// 快速设置四个边缘约束
    ///
    /// - Parameters:
    ///   - top: 顶部约束
    ///   - left: 左侧约束
    ///   - bottom: 底部约束
    ///   - right: 右侧约束
    func ls_edges(
        top: CGFloat? = nil,
        left: CGFloat? = nil,
        bottom: CGFloat? = nil,
        right: CGFloat? = nil
    ) {
        guard let superview = superview else { return }

        translatesAutoresizingMaskIntoConstraints = false

        var constraints: [NSLayoutConstraint] = []

        if let top = top {
            constraints.append(topAnchor.constraint(equalTo: superview.topAnchor, constant: top))
        }
        if let left = left {
            constraints.append(leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: left))
        }
        if let bottom = bottom {
            constraints.append(bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -bottom))
        }
        if let right = right {
            constraints.append(trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -right))
        }

        NSLayoutConstraint.activate(constraints)
    }

    /// 快速设置尺寸约束
    ///
    /// - Parameters:
    ///   - width: 宽度
    ///   - height: 高度
    func ls_size(width: CGFloat? = nil, height: CGFloat? = nil) {
        translatesAutoresizingMaskIntoConstraints = false

        var constraints: [NSLayoutConstraint] = []

        if let width = width {
            constraints.append(widthAnchor.constraint(equalToConstant: width))
        }
        if let height = height {
            constraints.append(heightAnchor.constraint(equalToConstant: height))
        }

        NSLayoutConstraint.activate(constraints)
    }

    /// 快速设置中心约束
    ///
    /// - Parameters:
    ///   - centerX: 水平中心
    ///   - centerY: 垂直中心
    func ls_center(centerX: Bool = false, centerY: Bool = false) {
        guard let superview = superview else { return }

        translatesAutoresizingMaskIntoConstraints = false

        var constraints: [NSLayoutConstraint] = []

        if centerX {
            constraints.append(centerXAnchor.constraint(equalTo: superview.centerXAnchor))
        }
        if centerY {
            constraints.append(centerYAnchor.constraint(equalTo: superview.centerYAnchor))
        }

        NSLayoutConstraint.activate(constraints)
    }

    /// 快速设置相对于视图的约束
    ///
    /// - Parameters:
    ///   - view: 参考视图
    ///   - width: 宽度倍数
    ///   - height: 高度倍数
    func ls_relative(to view: UIView, width: CGFloat = 1, height: CGFloat = 1) {
        translatesAutoresizingMaskIntoConstraints = false

        var constraints: [NSLayoutConstraint] = []

        if width != 0 {
            constraints.append(widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: width))
        }
        if height != 0 {
            constraints.append(heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: height))
        }

        NSLayoutConstraint.activate(constraints)
    }
}

// MARK: - NSLayoutConstraint Extension (批量激活)

public extension Array where Element == NSLayoutConstraint {

    /// 设置优先级
    ///
    /// - Parameter priority: 优先级
    /// - Returns: self
    @discardableResult
    func ls_priority(_ priority: UILayoutPriority) -> [NSLayoutConstraint] {
        forEach { $0.priority = priority }
        return self
    }
}

// MARK: - UIEdgeInsets Extension (布局)

public extension UIEdgeInsets {

    /// 垂直内边距
    var vertical: CGFloat {
        return top + bottom
    }

    /// 水平内边距
    var horizontal: CGFloat {
        return left + right
    }

    /// 创建对称内边距
    ///
    /// - Parameter inset: 内边距值
    /// - Returns: 内边距
    static func symmetric(_ inset: CGFloat) -> UIEdgeInsets {
        return UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
    }

    /// 创建顶部内边距
    ///
    /// - Parameter inset: 内边距值
    /// - Returns: 内边距
    static func top(_ inset: CGFloat) -> UIEdgeInsets {
        return UIEdgeInsets(top: inset, left: 0, bottom: 0, right: 0)
    }

    /// 创建底部内边距
    ///
    /// - Parameter inset: 内边距值
    /// - Returns: 内边距
    static func bottom(_ inset: CGFloat) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: inset, right: 0)
    }
}

#endif

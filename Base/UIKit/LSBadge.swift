//
//  LSBadge.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  角标工具 - 为 UIView 添加角标功能
//

#if canImport(UIKit)
import UIKit
import Foundation

// MARK: - LSBadgeView

/// 角标视图
@MainActor
public class LSBadgeView: UIView {

    // MARK: - 样式

    /// 角标样式
    public enum Style {
        case dot              // 红点
        case number           // 数字
        case text             // 文本
        case custom           // 自定义
    }

    /// 角标位置
    public enum Position {
        case topRight         // 右上角
        case topLeft          // 左上角
        case bottomRight      // 右下角
        case bottomLeft       // 左下角
        case center           // 中心
    }

    // MARK: - 属性

    /// 角标样式
    public var style: Style = .dot {
        didSet {
            updateAppearance()
        }
    }

    /// 角标值（数字或文本）
    public var value: Int = 0 {
        didSet {
            updateAppearance()
        }
    }

    /// 自定义文本
    public var text: String? {
        didSet {
            updateAppearance()
        }
    }

    /// 背景颜色
    public var badgeColor: UIColor = .red {
        didSet {
            backgroundColor = badgeColor
        }
    }

    /// 文本颜色
    public var textColor: UIColor = .white {
        didSet {
            label.textColor = textColor
        }
    }

    /// 字体
    public var font: UIFont = UIFont.systemFont(ofSize: 10) {
        didSet {
            label.font = font
            updateAppearance()
        }
    }

    /// 角标位置（相对于关联视图）
    public var position: Position = .topRight {
        didSet {
            updatePosition()
        }
    }

    /// 偏移量
    public var offset: CGPoint = .zero {
        didSet {
            updatePosition()
        }
    }

    /// 是否显示
    public var isDisplayed: Bool = false {
        didSet {
            isHidden = !isDisplayed
        }
    }

    /// 角标大小
    public var badgeSize: CGSize = CGSize(width: 18, height: 18) {
        didSet {
            updateAppearance()
        }
    }

    /// 最大显示数字（超过显示 99+）
    public var maxNumber: Int = 99

    /// 超过最大值的显示文本
    public var overflowText: String = "99+"

    // MARK: - UI 组件

    private lazy var label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = self.font
        label.textColor = self.textColor
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - 关联视图

    /// 关联的视图
    public weak var associatedView: UIView? {
        didSet {
            if let view = associatedView {
                view.addSubview(self)
                translatesAutoresizingMaskIntoConstraints = false
            }
        }
    }

    // MARK: - 初始化

    public init(style: Style = .dot) {
        self.style = style
        super.init(frame: .zero)
        setupUI()
        updateAppearance()
    }

    required init?(coder: NSCoder) {
        self.style = .dot
        super.init(coder: coder)
        setupUI()
        updateAppearance()
    }

    // MARK: - 设置

    private func setupUI() {
        backgroundColor = badgeColor
        layer.cornerRadius = bounds.height / 2
        clipsToBounds = true

        addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor),
            label.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor)
        ])
    }

    // MARK: - 更新

    private func updateAppearance() {
        switch style {
        case .dot:
            updateDotStyle()
        case .number:
            updateNumberStyle()
        case .text:
            updateTextStyle()
        case .custom:
            updateCustomStyle()
        }
    }

    private func updateDotStyle() {
        let size: CGFloat = 8
        frame.size = CGSize(width: size, height: size)
        layer.cornerRadius = size / 2
        label.isHidden = true
        isHidden = !isDisplayed
    }

    private func updateNumberStyle() {
        let displayText = value > maxNumber ? overflowText : "\(value)"
        label.text = displayText
        label.isHidden = false

        let textSize = label.intrinsicContentSize
        let padding: CGFloat = 4
        let size = CGSize(
            width: max(badgeSize.width, textSize.width + padding * 2),
            height: badgeSize.height
        )

        frame.size = size
        layer.cornerRadius = size.height / 2
        isHidden = !isDisplayed || value <= 0
    }

    private func updateTextStyle() {
        label.text = text
        label.isHidden = false

        if let text = text {
            let textSize = label.intrinsicContentSize
            let padding: CGFloat = 4
            let size = CGSize(
                width: max(badgeSize.width, textSize.width + padding * 2),
                height: badgeSize.height
            )

            frame.size = size
            layer.cornerRadius = size.height / 2
            isHidden = !isDisplayed || text.isEmpty
        } else {
            isHidden = true
        }
    }

    private func updateCustomStyle() {
        isHidden = !isDisplayed
    }

    private func updatePosition() {
        guard let view = associatedView else { return }

        switch position {
        case .topRight:
            let x = view.bounds.width - bounds.width / 2 + offset.x
            let y = -bounds.height / 2 + offset.y
            center = CGPoint(x: x, y: y)
        case .topLeft:
            let x = bounds.width / 2 + offset.x
            let y = -bounds.height / 2 + offset.y
            center = CGPoint(x: x, y: y)
        case .bottomRight:
            let x = view.bounds.width - bounds.width / 2 + offset.x
            let y = view.bounds.height + bounds.height / 2 + offset.y
            center = CGPoint(x: x, y: y)
        case .bottomLeft:
            let x = bounds.width / 2 + offset.x
            let y = view.bounds.height + bounds.height / 2 + offset.y
            center = CGPoint(x: x, y: y)
        case .center:
            center = CGPoint(
                x: view.bounds.width / 2 + offset.x,
                y: view.bounds.height / 2 + offset.y
            )
        }
    }

    // MARK: - 便捷方法

    /// 设置角标值并显示
    ///
    /// - Parameter value: 值
    public func setBadge(_ value: Int) {
        self.value = value
        style = .number
        isDisplayed = true
        updatePosition()
    }

    /// 显示红点
    public func showDot() {
        style = .dot
        isDisplayed = true
        updatePosition()
    }

    /// 隐藏角标
    public func hide() {
        isDisplayed = false
    }

    /// 清除角标
    public func clear() {
        value = 0
        text = nil
        hide()
    }

    /// 增加角标值
    ///
    /// - Parameter increment: 增量
    public func increment(by increment: Int = 1) {
        value += increment
        if value > 0 {
            style = .number
            isDisplayed = true
        }
        updatePosition()
    }

    /// 减少角标值
    ///
    /// - Parameter decrement: 减量
    public func decrement(by decrement: Int = 1) {
        value = max(0, value - decrement)
        if value == 0 {
            hide()
        }
        updatePosition()
    }
}

// MARK: - UIView Extension (角标)

public extension UIView {

    private enum AssociatedKeys {
        static var badgeKey: UInt8 = 0
    }
    /// 角标视图
    var ls_badge: LSBadgeView? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.badgeKey) as? LSBadgeView
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.badgeKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// 显示角标
    ///
    /// - Parameters:
    ///   - value: 角标值
    ///   - style: 样式
    ///   - position: 位置
    ///   - offset: 偏移
    /// - Returns: 角标视图
    @discardableResult
    func ls_showBadge(
        value: Int = 0,
        style: LSBadgeView.Style = .dot,
        position: LSBadgeView.Position = .topRight,
        offset: CGPoint = .zero
    ) -> LSBadgeView {
        let badge = LSBadgeView(style: style)
        badge.value = value
        badge.style = style
        badge.position = position
        badge.offset = offset
        badge.associatedView = self
        badge.isDisplayed = true

        self.ls_badge = badge

        return badge
    }

    /// 显示红点角标
    ///
    /// - Parameters:
    ///   - position: 位置
    ///   - offset: 偏移
    /// - Returns: 角标视图
    @discardableResult
    func ls_showBadgeDot(
        position: LSBadgeView.Position = .topRight,
        offset: CGPoint = .zero
    ) -> LSBadgeView {
        return ls_showBadge(style: .dot, position: position, offset: offset)
    }

    /// 显示数字角标
    ///
    /// - Parameters:
    ///   - value: 值
    ///   - position: 位置
    ///   - offset: 偏移
    /// - Returns: 角标视图
    @discardableResult
    func ls_showBadge(
        value: Int,
        position: LSBadgeView.Position = .topRight,
        offset: CGPoint = .zero
    ) -> LSBadgeView {
        return ls_showBadge(value: value, style: .number, position: position, offset: offset)
    }

    /// 显示文本角标
    ///
    /// - Parameters:
    ///   - text: 文本
    ///   - position: 位置
    ///   - offset: 偏移
    /// - Returns: 角标视图
    @discardableResult
    func ls_showBadge(
        text: String,
        position: LSBadgeView.Position = .topRight,
        offset: CGPoint = .zero
    ) -> LSBadgeView {
        let badge = ls_showBadge(style: .text, position: position, offset: offset)
        badge.text = text
        return badge
    }

    /// 设置角标值
    ///
    /// - Parameter value: 值
    func ls_setBadge(_ value: Int) {
        if let badge = ls_badge {
            badge.setBadge(value)
        } else {
            ls_showBadge(value: value, style: .number)
        }
    }

    /// 增加角标值
    ///
    /// - Parameter increment: 增量
    func ls_incrementBadge(by increment: Int = 1) {
        guard let badge = ls_badge else {
            ls_showBadge(value: increment, style: .number)
            return
        }
        badge.increment(by: increment)
    }

    /// 减少角标值
    ///
    /// - Parameter decrement: 减量
    func ls_decrementBadge(by decrement: Int = 1) {
        ls_badge?.decrement(by: decrement)
    }

    /// 清除角标
    func ls_clearBadge() {
        ls_badge?.clear()
        ls_badge = nil
    }

    /// 隐藏角标
    func ls_hideBadge() {
        ls_badge?.hide()
    }

    /// 显示角标
    func ls_displayBadge() {
        ls_badge?.isDisplayed = true
    }

    /// 角标值
    var ls_badgeValue: Int {
        get {
            if let badge = ls_badge {
                return badge.value
            } else {
                return 0
            }
        }
        set { ls_setBadge(newValue) }
    }
}

// MARK: - UIBarButtonItem Extension (角标)

public extension UIBarButtonItem {

    /// 自定义视图角标
    func ls_showBadge(_ value: Int) {
        if let customView = customView {
            customView.ls_showBadge(value: value)
        } else {
            // 对于非自定义视图，需要创建自定义视图
            let badgeView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
            let button = UIButton(type: .system)
            button.frame = badgeView.bounds
            badgeView.addSubview(button)
            customView = badgeView
            badgeView.ls_showBadge(value: value)
        }
    }

    /// 清除角标
    func ls_clearBadge() {
        customView?.ls_clearBadge()
    }
}

// MARK: - UITabBarItem Extension (角标)

public extension UITabBarItem {

    /// 显示角标（使用系统原生）
    ///
    /// - Parameter value: 值
    func ls_showBadge(_ value: Int) {
        if value > 0 {
            badgeValue = value > 99 ? "99+" : "\(value)"
        } else {
            badgeValue = nil
        }
    }

    /// 清除角标
    func ls_clearBadge() {
        badgeValue = nil
    }
}

#endif

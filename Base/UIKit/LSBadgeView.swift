//
//  LSBadgeView.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  角标视图 - 红点/数字角标
//

#if canImport(UIKit)
import UIKit

// MARK: - LSBadgeView

/// 角标视图
@MainActor
public class LSBadgeView: UIView {

    // MARK: - 样式枚举

    /// 角标样式
    public enum Style {
        case dot                // 红点
        case number             // 数字
        case text               // 文字
        case custom             // 自定义
    }

    // MARK: - 属性

    /// 角标样式
    public var style: Style = .dot {
        didSet {
            updateAppearance()
        }
    }

    /// 角标值（数字角标）
    public var value: Int = 0 {
        didSet {
            if style == .number {
                label.text = value > 99 ? "99+" : "\(value)"
                updateAppearance()
            }
        }
    }

    /// 角标文字（文字角标）
    public var text: String = "" {
        didSet {
            if style == .text {
                label.text = text
                updateAppearance()
            }
        }
    }

    /// 角标颜色
    public var badgeColor: UIColor = .red {
        didSet {
            backgroundColor = badgeColor
        }
    }

    /// 文字颜色
    public var textColor: UIColor = .white {
        didSet {
            label.textColor = textColor
        }
    }

    /// 字体
    public var font: UIFont = .systemFont(ofSize: 10) {
        didSet {
            label.font = font
            updateAppearance()
        }
    }

    /// 数字角标最小宽度
    public var minNumberWidth: CGFloat = 18 {
        didSet {
            updateAppearance()
        }
    }

    /// 红点大小
    public var dotSize: CGFloat = 8 {
        didSet {
            if style == .dot {
                updateAppearance()
            }
        }
    }

    /// 水平偏移
    public var horizontalOffset: CGFloat = 0

    /// 垂直偏移
    public var verticalOffset: CGFloat = 0

    /// 标签
    private let label: UILabel = {
        let lbl = UILabel()
        lbl.textAlignment = .center
        lbl.textColor = .white
        lbl.font = .systemFont(ofSize: 10)
        return lbl
    }()

    // MARK: - 初始化

    public init() {
        super.init(frame: .zero)
        setupUI()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - 设置

    private func setupUI() {
        backgroundColor = badgeColor
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        updateAppearance()
    }

    private func updateAppearance() {
        switch style {
        case .dot:
            label.isHidden = true
            snp.remakeConstraints { make in
                make.width.height.equalTo(dotSize)
            }
            layer.cornerRadius = dotSize / 2

        case .number:
            label.isHidden = false
            label.text = value > 99 ? "99+" : "\(value)"
            let width = max(minNumberWidth, label.intrinsicContentSize.width + 8)
            snp.remakeConstraints { make in
                make.width.greaterThanOrEqualTo(minNumberWidth)
                make.height.equalTo(minNumberWidth)
            }
            layer.cornerRadius = minNumberWidth / 2

        case .text:
            label.isHidden = false
            label.text = text
            let intrinsicWidth = label.intrinsicContentSize.width
            snp.remakeConstraints { make in
                make.width.equalTo(intrinsicWidth + 8)
                make.height.equalTo(minNumberWidth)
            }
            layer.cornerRadius = minNumberWidth / 2

        case .custom:
            label.isHidden = true
            layer.cornerRadius = 0
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    // MARK: - 便捷方法

    /// 显示红点
    public func showDot() {
        style = .dot
        isHidden = false
    }

    /// 显示数字
    ///
    /// - Parameter value: 数字值
    public func showNumber(_ value: Int) {
        style = .number
        self.value = value
        isHidden = value <= 0
    }

    /// 显示文字
    ///
    /// - Parameter text: 文字内容
    public func showText(_ text: String) {
        style = .text
        self.text = text
        isHidden = text.isEmpty
    }

    /// 隐藏角标
    public func hide() {
        isHidden = true
    }

    /// 增加数量
    public func increment() {
        value += 1
        if value > 0 {
            showNumber(value)
        }
    }

    /// 减少数量
    public func decrement() {
        value -= 1
        if value <= 0 {
            hide()
        } else {
            showNumber(value)
        }
    }

    /// 清空数量
    public func clear() {
        value = 0
        hide()
    }
}

// MARK: - UIView Extension (角标)

public extension UIView {

    /// 关联的角标视图
    private static var badgeViewKey: UInt8 = 0

    /// 角标视图
    var ls_badgeView: LSBadgeView? {
        get {
            return objc_getAssociatedObject(self, &UIView.badgeViewKey) as? LSBadgeView
        }
        set {
            objc_setAssociatedObject(self, &UIView.badgeViewKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// 添加红点角标
    ///
    /// - Parameters:
    ///   - position: 位置
    ///   - offset: 偏移
    /// - Returns: 角标视图
    @discardableResult
    func ls_addBadgeDot(
        at position: Position = .topRight,
        offset: CGPoint = .zero
    ) -> LSBadgeView {
        let badge: LSBadgeView
        if let tempBadge = ls_badgeView {
            badge = tempBadge
        } else {
            badge = LSBadgeView()
        }
        badge.showDot()
        return ls_addBadge(badge, at: position, offset: offset)
    }

    /// 添加数字角标
    ///
    /// - Parameters:
    ///   - value: 数字值
    ///   - position: 位置
    ///   - offset: 偏移
    /// - Returns: 角标视图
    @discardableResult
    func ls_addBadgeNumber(
        _ value: Int,
        at position: Position = .topRight,
        offset: CGPoint = .zero
    ) -> LSBadgeView {
        let badge: LSBadgeView
        if let tempBadge = ls_badgeView {
            badge = tempBadge
        } else {
            badge = LSBadgeView()
        }
        badge.showNumber(value)
        return ls_addBadge(badge, at: position, offset: offset)
    }

    /// 添加文字角标
    ///
    /// - Parameters:
    ///   - text: 文字内容
    ///   - position: 位置
    ///   - offset: 偏移
    /// - Returns: 角标视图
    @discardableResult
    func ls_addBadgeText(
        _ text: String,
        at position: Position = .topRight,
        offset: CGPoint = .zero
    ) -> LSBadgeView {
        let badge: LSBadgeView
        if let tempBadge = ls_badgeView {
            badge = tempBadge
        } else {
            badge = LSBadgeView()
        }
        badge.showText(text)
        return ls_addBadge(badge, at: position, offset: offset)
    }

    /// 添加角标视图
    ///
    /// - Parameters:
    ///   - badge: 角标视图
    ///   - position: 位置
    ///   - offset: 偏移
    /// - Returns: 角标视图
    @discardableResult
    private func ls_addBadge(
        _ badge: LSBadgeView,
        at position: Position,
        offset: CGPoint
    ) -> LSBadgeView {
        // 移除旧的
        ls_badgeView?.removeFromSuperview()

        // 设置新的
        ls_badgeView = badge
        addSubview(badge)
        badge.translatesAutoresizingMaskIntoConstraints = false

        // 约束
        switch position {
        case .topLeft:
            NSLayoutConstraint.activate([
                badge.leadingAnchor.constraint(equalTo: leadingAnchor, constant: offset.x),
                badge.topAnchor.constraint(equalTo: topAnchor, constant: offset.y)
            ])
        case .topRight:
            NSLayoutConstraint.activate([
                badge.trailingAnchor.constraint(equalTo: trailingAnchor, constant: offset.x),
                badge.topAnchor.constraint(equalTo: topAnchor, constant: offset.y)
            ])
        case .bottomLeft:
            NSLayoutConstraint.activate([
                badge.leadingAnchor.constraint(equalTo: leadingAnchor, constant: offset.x),
                badge.bottomAnchor.constraint(equalTo: bottomAnchor, constant: offset.y)
            ])
        case .bottomRight:
            NSLayoutConstraint.activate([
                badge.trailingAnchor.constraint(equalTo: trailingAnchor, constant: offset.x),
                badge.bottomAnchor.constraint(equalTo: bottomAnchor, constant: offset.y)
            ])
        case .center:
            NSLayoutConstraint.activate([
                badge.centerXAnchor.constraint(equalTo: centerXAnchor, constant: offset.x),
                badge.centerYAnchor.constraint(equalTo: centerYAnchor, constant: offset.y)
            ])
        }

        return badge
    }

    /// 移除角标
    func ls_removeBadge() {
        ls_badgeView?.removeFromSuperview()
        ls_badgeView = nil
    }

    /// 更新角标数字
    ///
    /// - Parameter value: 新数字
    func ls_updateBadgeNumber(_ value: Int) {
        ls_badgeView?.showNumber(value)
    }

    /// 增加角标数字
    func ls_incrementBadge() {
        ls_badgeView?.increment()
    }

    /// 减少角标数字
    func ls_decrementBadge() {
        ls_badgeView?.decrement()
    }

    /// 清空角标
    func ls_clearBadge() {
        ls_badgeView?.clear()
    }

    /// 角标位置
    enum Position {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
        case center
    }
}

// MARK: - Tab Bar Item Extension

public extension UITabBarItem {

    /// 设置角标值
    ///
    /// - Parameter value: 角标值（0 表示隐藏）
    func ls_setBadgeValue(_ value: Int) {
        if value > 0 {
            badgeValue = value > 99 ? "99+" : "\(value)"
        } else {
            badgeValue = nil
        }
    }

    /// 显示红点角标
    func ls_showBadgeDot() {
        badgeValue = ""
        // 需要自定义实现才能显示红点
        // 这里只是设置系统角标
    }

    /// 隐藏角标
    func ls_hideBadge() {
        badgeValue = nil
    }
}

#endif

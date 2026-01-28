//
//  LSDividerView.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  分割线视图 - 水平和垂直分割线
//

#if canImport(UIKit)
import UIKit

// MARK: - LSDividerView

/// 分割线视图
@MainActor
public class LSDividerView: UIView {

    // MARK: - 类型定义

    /// 分割线方向
    public enum DividerOrientation {
        case horizontal
        case vertical
    }

    /// 分割线样式
    public enum DividerStyle {
        case plain              // 普通
        case dashed             // 虚线
        case dotted             // 点线
    }

    // MARK: - 属性

    /// 方向
    public var orientation: DividerOrientation = .horizontal {
        didSet {
            updateOrientation()
        }
    }

    /// 样式
    public var style: DividerStyle = .plain {
        didSet {
            updateStyle()
        }
    }

    /// 颜色
    public var color: UIColor = .separator {
        didSet {
            updateColor()
        }
    }

    /// 厚度
    public var thickness: CGFloat = 1 {
        didSet {
            updateThickness()
        }
    }

    /// 虚线模式（用于虚线/点线）
    public var dashPattern: [NSNumber]? = nil {
        didSet {
            updateStyle()
        }
    }

    /// 内边距
    public var insets: UIEdgeInsets = .zero {
        didSet {
            updateInsets()
        }
    }

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupDivider()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupDivider()
    }

    public init(
        orientation: DividerOrientation = .horizontal,
        color: UIColor = .separator,
        thickness: CGFloat = 1
    ) {
        self.orientation = orientation
        self.color = color
        self.thickness = thickness
        super.init(frame: .zero)
        setupDivider()
    }

    // MARK: - 设置

    private func setupDivider() {
        backgroundColor = .clear
        updateOrientation()
        updateStyle()
        updateColor()
        updateThickness()
    }

    // MARK: - 更新

    private func updateOrientation() {
        switch orientation {
        case .horizontal:
            if constraints.isEmpty {
                heightAnchor.constraint(equalToConstant: thickness).isActive = true
            }

        case .vertical:
            if constraints.isEmpty {
                widthAnchor.constraint(equalToConstant: thickness).isActive = true
            }
        }
    }

    private func updateStyle() {
        switch style {
        case .plain:
            layer.borderStyle = .solid

        case .dashed:
            layer.borderStyle = .solid
            dashPattern = [6, 4] as [NSNumber]

        case .dotted:
            layer.borderStyle = .solid
            dashPattern = [2, 2] as [NSNumber]
        }

        if let pattern = dashPattern {
            if orientation == .horizontal {
                layer.borderStyle = .solid
            }
        }
    }

    private func updateColor() {
        layer.borderColor = color.cgColor
    }

    private func updateThickness() {
        switch orientation {
        case .horizontal:
            constraints.forEach { constraint in
                if constraint.firstAttribute == .height {
                    constraint.constant = thickness
                }
            }

        case .vertical:
            constraints.forEach { constraint in
                if constraint.firstAttribute == .width {
                    constraint.constant = thickness
                }
            }
        }
    }

    private func updateInsets() {
        switch orientation {
        case .horizontal:
            leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left).isActive = true
            trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right).isActive = true

        case .vertical:
            topAnchor.constraint(equalTo: topAnchor, constant: insets.top).isActive = true
            bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom).isActive = true
        }
    }

    public override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard style != .plain else { return }

        let path = UIBezierPath()

        switch orientation {
        case .horizontal:
            let y = bounds.height / 2
            path.move(to: CGPoint(x: 0, y: y))

            if let pattern = dashPattern {
                // 绘制虚线
                let patternArray = pattern.compactMap { $0 as? CGFloat }
                var x: CGFloat = 0
                let isDash = pattern.count > 1 ? true : false

                while x < bounds.width {
                    let dashLength = patternArray[0]
                    let gapLength = patternArray.count > 1 ? patternArray[1] : 0

                    path.addLine(to: CGPoint(x: x + dashLength, y: y))
                    x += dashLength

                    if x < bounds.width && isDash {
                        x += gapLength
                    }
                }
            }

        case .vertical:
            let x = bounds.width / 2
            path.move(to: CGPoint(x: x, y: 0))

            if let pattern = dashPattern {
                let patternArray = pattern.compactMap { $0 as? CGFloat }
                var y: CGFloat = 0
                let isDash = pattern.count > 1 ? true : false

                while y < bounds.height {
                    let dashLength = patternArray[0]
                    let gapLength = patternArray.count > 1 ? patternArray[1] : 0

                    path.addLine(to: CGPoint(x: x, y: y + dashLength))
                    y += dashLength

                    if y < bounds.height && isDash {
                        y += gapLength
                    }
                }
            }
        }

        color.setStroke()
        path.lineWidth = thickness
        path.stroke()
    }
}

// MARK: - 便捷创建

public extension LSDividerView {

    /// 创建水平分割线
    static func horizontal(
        color: UIColor = .separator,
        thickness: CGFloat = 1,
        insets: UIEdgeInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
    ) -> LSDividerView {
        let divider = LSDividerView(orientation: .horizontal, color: color, thickness: thickness)
        divider.insets = insets
        return divider
    }

    /// 创建垂直分割线
    static func vertical(
        color: UIColor = .separator,
        thickness: CGFloat = 1,
        insets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
    ) -> LSDividerView {
        let divider = LSDividerView(orientation: .vertical, color: color, thickness: thickness)
        divider.insets = insets
        return divider
    }

    /// 创建虚线分割线
    static func dashed(
        orientation: DividerOrientation = .horizontal,
        color: UIColor = .separator,
        dashPattern: [NSNumber] = [6, 4]
    ) -> LSDividerView {
        let divider = LSDividerView(orientation: orientation, color: color)
        divider.style = .dashed
        divider.dashPattern = dashPattern
        return divider
    }

    /// 创建点线分割线
    static func dotted(
        orientation: DividerOrientation = .horizontal,
        color: UIColor = .separator
    ) -> LSDividerView {
        let divider = LSDividerView(orientation: orientation, color: color)
        divider.style = .dotted
        return divider
    }
}

// MARK: - UIView Extension (Divider)

public extension UIView {

    /// 关联的分割线
    private static var dividerViewKey: UInt8 = 0

    var ls_dividerView: LSDividerView? {
        get {
            return objc_getAssociatedObject(self, &UIView.dividerViewKey) as? LSDividerView
        }
        set {
            objc_setAssociatedObject(
                self,
                &UIView.dividerViewKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// 添加顶部分割线
    @discardableResult
    func ls_addTopDivider(
        color: UIColor = .separator,
        thickness: CGFloat = 0.5,
        insets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)
    ) -> LSDividerView {
        let divider = LSDividerView.horizontal(color: color, thickness: thickness, insets: insets)
        addSubview(divider)

        divider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            divider.topAnchor.constraint(equalTo: topAnchor),
            divider.leadingAnchor.constraint(equalTo: leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        ls_dividerView = divider
        return divider
    }

    /// 添加底部分割线
    @discardableResult
    func ls_addBottomDivider(
        color: UIColor = .separator,
        thickness: CGFloat = 0.5,
        insets: UIEdgeInsets = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
    ) -> LSDividerView {
        let divider = LSDividerView.horizontal(color: color, thickness: thickness, insets: insets)
        addSubview(divider)

        divider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            divider.bottomAnchor.constraint(equalTo: bottomAnchor),
            divider.leadingAnchor.constraint(equalTo: leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        ls_dividerView = divider
        return divider
    }

    /// 添加左侧分割线
    @discardableResult
    func ls_addLeftDivider(
        color: UIColor = .separator,
        thickness: CGFloat = 0.5,
        insets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
    ) -> LSDividerView {
        let divider = LSDividerView.vertical(color: color, thickness: thickness, insets: insets)
        addSubview(divider)

        divider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            divider.topAnchor.constraint(equalTo: topAnchor),
            divider.leadingAnchor.constraint(equalTo: leadingAnchor),
            divider.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        ls_dividerView = divider
        return divider
    }

    /// 添加右侧分割线
    @discardableResult
    func ls_addRightDivider(
        color: UIColor = .separator,
        thickness: CGFloat = 0.5,
        insets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
    ) -> LSDividerView {
        let divider = LSDividerView.vertical(color: color, thickness: thickness, insets: insets)
        addSubview(divider)

        divider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            divider.topAnchor.constraint(equalTo: topAnchor),
            divider.trailingAnchor.constraint(equalTo: trailingAnchor),
            divider.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        ls_dividerView = divider
        return divider
    }

    /// 移除分割线
    func ls_removeDivider() {
        ls_dividerView?.removeFromSuperview()
        ls_dividerView = nil
    }
}

// MARK: - Separator View

/// 分隔视图（更简单的实现）
public class LSSeparatorView: UIView {

    /// 创建水平分隔线
    public static func horizontal(
        color: UIColor = .separator,
        height: CGFloat = 0.5,
        insets: UIEdgeInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
    ) -> LSSeparatorView {
        let view = LSSeparatorView()
        view.backgroundColor = color
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }

    /// 创建垂直分隔线
    public static func vertical(
        color: UIColor = .separator,
        width: CGFloat = 0.5,
        insets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
    ) -> LSSeparatorView {
        let view = LSSeparatorView()
        view.backgroundColor = color
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }

    /// 添加到视图
    public func addTo(
        view: UIView,
        edge: NSLayoutConstraint.Edge = .bottom,
        constant: CGFloat = 0,
        insets: UIEdgeInsets = .zero
    ) {
        view.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false

        switch edge {
        case .top:
            NSLayoutConstraint.activate([
                topAnchor.constraint(equalTo: view.topAnchor, constant: constant + insets.top),
                leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.left),
                trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -insets.right),
                heightAnchor.constraint(equalToConstant: bounds.height)
            ])

        case .bottom:
            NSLayoutConstraint.activate([
                bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -constant - insets.bottom),
                leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.left),
                trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -insets.right),
                heightAnchor.constraint(equalToConstant: bounds.height)
            ])

        case .leading:
            NSLayoutConstraint.activate([
                leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: constant + insets.left),
                topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top),
                bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -insets.bottom),
                widthAnchor.constraint(equalToConstant: bounds.width)
            ])

        case .trailing:
            NSLayoutConstraint.activate([
                trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -constant - insets.right),
                topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top),
                bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -insets.bottom),
                widthAnchor.constraint(equalToConstant: bounds.width)
            ])
        }
    }
}

// MARK: - Group Separator View

/// 组分隔线（带文字）
public class LSGroupSeparatorView: UIView {

    /// 标题
    public var title: String? {
        didSet {
            titleLabel.text = title
            titleLabel.isHidden = (title == nil)
        }
    }

    /// 颜色
    public var separatorColor: UIColor = .separator {
        didSet {
            separatorView.backgroundColor = separatorColor
        }
    }

    /// 标题颜色
    public var titleColor: UIColor = .secondaryLabel {
        didSet {
            titleLabel.textColor = titleColor
        }
    }

    /// 字体
    public var titleFont: UIFont = .systemFont(ofSize: 12) {
        didSet {
            titleLabel.font = titleFont
        }
    }

    // MARK: - UI 组件

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupGroupSeparator()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGroupSeparator()
    }

    public init(title: String?) {
        self.title = title
        super.init(frame: .zero)
        setupGroupSeparator()
    }

    // MARK: - 设置

    private func setupGroupSeparator() {
        addSubview(separatorView)
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            separatorView.topAnchor.constraint(equalTo: topAnchor),
            separatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 0.5),

            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])

        titleLabel.isHidden = (title == nil)
    }
}

// MARK: - UIView Extension (Separator)

public extension UIView {

    /// 添加组分隔线
    @discardableResult
    func ls_addGroupSeparator(
        title: String?,
        atTop: Bool = true
    ) -> LSGroupSeparatorView {
        let separator = LSGroupSeparatorView(title: title)

        addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false

        if atTop {
            NSLayoutConstraint.activate([
                separator.topAnchor.constraint(equalTo: topAnchor),
                separator.leadingAnchor.constraint(equalTo: leadingAnchor),
                separator.trailingAnchor.constraint(equalTo: trailingAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                separator.bottomAnchor.constraint(equalTo: bottomAnchor),
                separator.leadingAnchor.constraint(equalTo: leadingAnchor),
                separator.trailingAnchor.constraint(equalTo: trailingAnchor)
            ])
        }

        return separator
    }

    /// 添加简单的分隔线
    @discardableResult
    func ls_addSeparator(
        color: UIColor = .separator,
        thickness: CGFloat = 0.5,
        insets: UIEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16),
        position: SeparatorPosition = .top
    ) -> LSSeparatorView {
        let separator = LSSeparatorView.horizontal(color: color, height: thickness, insets: insets)

        addSubview(separator)

        switch position {
        case .top:
            separator.addTo(
                self,
                edge: .top,
                constant: 0,
                insets: insets
            )

        case .bottom:
            separator.addTo(
                self,
                edge: .bottom,
                constant: 0,
                insets: insets
            )
        }

        return separator
    }

    /// 分隔线位置
    enum SeparatorPosition {
        case top
        case bottom
    }
}

#endif

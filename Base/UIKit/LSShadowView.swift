//
//  LSShadowView.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  阴影视图 - 为任意视图添加阴影效果
//

#if canImport(UIKit)
import UIKit

// MARK: - LSShadowView

/// 阴影视图
@MainActor
public class LSShadowView: UIView {

    // MARK: - 属性

    /// 容器视图
    private let contentView: UIView

    /// 阴影层
    private let shadowLayer = CAGradientLayer()

    /// 阴影方向
    public enum ShadowDirection {
        case top
        case bottom
        case left
        case right
        case all
    }

    /// 阴影颜色
    public var shadowColor: UIColor = .black {
        didSet {
            updateShadowColor()
        }
    }

    /// 阴影透明度
    public var shadowOpacity: Float = 0.3 {
        didSet {
            shadowLayer.opacity = shadowOpacity
        }
    }

    /// 阴影高度
    public var shadowHeight: CGFloat = 10 {
        didSet {
            updateShadowSize()
        }
    }

    /// 阴影方向
    public var shadowDirection: ShadowDirection = .bottom {
        didSet {
            updateShadowDirection()
        }
    }

    /// 内容视图
    public var containedView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let view = containedView {
                contentView.addSubview(view)
                view.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    view.topAnchor.constraint(equalTo: contentView.topAnchor),
                    view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                    view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                    view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
                ])
            }
        }
    }

    // MARK: - 初始化

    public init(frame: CGRect = .zero) {
        contentView = UIView()
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        contentView = UIView()
        super.init(coder: coder)
        setupUI()
    }

    /// 便捷初始化
    ///
    /// - Parameter view: 要添加阴影的视图
    public convenience init(view: UIView) {
        self.init(frame: view.bounds)
        containedView = view
    }

    // MARK: - 设置

    private func setupUI() {
        backgroundColor = .clear

        addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        layer.insertSublayer(shadowLayer, at: 0)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        clipsToBounds = false
    }

    private func updateShadowColor() {
        shadowLayer.colors = [shadowColor.withAlphaComponent(0).cgColor, shadowColor.cgColor]
    }

    private func updateShadowSize() {
        setNeedsLayout()
        layoutIfNeeded()
    }

    private func updateShadowDirection() {
        setNeedsLayout()
        layoutIfNeeded()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        switch shadowDirection {
        case .top:
            shadowLayer.frame = CGRect(x: 0, y: -shadowHeight, width: bounds.width, height: shadowHeight)
        case .bottom:
            shadowLayer.frame = CGRect(x: 0, y: bounds.height, width: bounds.width, height: shadowHeight)
        case .left:
            shadowLayer.frame = CGRect(x: -shadowHeight, y: 0, width: shadowHeight, height: bounds.height)
        case .right:
            shadowLayer.frame = CGRect(x: bounds.width, y: 0, width: shadowHeight, height: bounds.height)
        case .all:
            shadowLayer.frame = bounds
        }
    }
}

// MARK: - UIView Extension (阴影)

public extension UIView {

    /// 关联的阴影视图
    private static var shadowViewKey: UInt8 = 0

    /// 阴影视图
    var ls_shadowView: LSShadowView? {
        get {
            return objc_getAssociatedObject(self, &UIView.shadowViewKey) as? LSShadowView
        }
        set {
            objc_setAssociatedObject(self, &UIView.shadowViewKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// 添加底部阴影
    ///
    /// - Parameters:
    ///   - height: 阴影高度
    ///   - color: 阴影颜色
    ///   - opacity: 透明度
    /// - Returns: 阴影视图
    @discardableResult
    func ls_addBottomShadow(
        height: CGFloat = 10,
        color: UIColor = .black,
        opacity: Float = 0.3
    ) -> LSShadowView {
        let shadowView = LSShadowView(view: self)
        shadowView.shadowDirection = .bottom
        shadowView.shadowHeight = height
        shadowView.shadowColor = color
        shadowView.shadowOpacity = opacity

        if let superview = superview {
            superview.addSubview(shadowView)
            shadowView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                shadowView.topAnchor.constraint(equalTo: topAnchor),
                shadowView.leadingAnchor.constraint(equalTo: leadingAnchor),
                shadowView.trailingAnchor.constraint(equalTo: trailingAnchor),
                shadowView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        }

        self.ls_shadowView = shadowView

        return shadowView
    }

    /// 添加阴影效果
    ///
    /// - Parameters:
    ///   - color: 阴影颜色
    ///   - offset: 偏移
    ///   - opacity: 不透明度
    ///   - radius: 模糊半径
    func ls_addShadow(
        color: UIColor = .black,
        offset: CGSize = CGSize(width: 0, height: -2),
        opacity: Float = 0.3,
        radius: CGFloat = 3
    ) {
        layer.shadowColor = color.cgColor
        layer.shadowOffset = offset
        layer.shadowOpacity = opacity
        layer.shadowRadius = radius
        layer.masksToBounds = false
    }

    /// 移除阴影效果
    func ls_removeShadow() {
        layer.shadowColor = nil
        layer.shadowOffset = .zero
        layer.shadowOpacity = 0
        layer.shadowRadius = 0
    }

    /// 移除阴影视图
    func ls_removeShadowView() {
        ls_shadowView?.removeFromSuperview()
        ls_shadowView = nil
    }

    /// 内阴影效果
    ///
    /// - Parameters:
    ///   - color: 阴影颜色
    ///   - opacity: 不透明度
    ///   - radius: 模糊半径
    func ls_addInnerShadow(
        color: UIColor = .black,
        opacity: Float = 0.3,
        radius: CGFloat = 3
    ) {
        let innerShadowLayer = CALayer()
        innerShadowLayer.frame = bounds
        innerShadowLayer.cornerRadius = layer.cornerRadius
        innerShadowLayer.shadowColor = color.cgColor
        innerShadowLayer.shadowOffset = .zero
        innerShadowLayer.shadowOpacity = opacity
        innerShadowLayer.shadowRadius = radius
        innerShadowLayer.masksToBounds = true

        // 创建带孔的路径
        let path = UIBezierPath(roundedRect: innerShadowLayer.bounds, cornerRadius: innerShadowLayer.cornerRadius)
        let cutoutPath = UIBezierPath(roundedRect: innerShadowLayer.bounds.insetBy(dx: -1, dy: -1), cornerRadius: 0)
        path.append(cutoutPath)
        path.usesEvenOddFillRule = true

        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillRule = .evenOdd
        innerShadowLayer.mask = maskLayer

        layer.insertSublayer(innerShadowLayer, at: 0)
    }

    /// 圆角阴影（为圆角视图添加外阴影）
    ///
    /// - Parameters:
    ///   - cornerRadius: 圆角半径
    ///   - color: 阴影颜色
    ///   - offset: 偏移
    ///   - opacity: 不透明度
    ///   - radius: 模糊半径
    func ls_addRoundedShadow(
        cornerRadius: CGFloat,
        color: UIColor = .black,
        offset: CGSize = CGSize(width: 0, height: -2),
        opacity: Float = 0.3,
        radius: CGFloat = 3
    ) {
        layer.cornerRadius = cornerRadius
        ls_addShadow(color: color, offset: offset, opacity: opacity, radius: radius)
    }

    /// 柔和阴影（多个方向的柔和阴影）
    ///
    /// - Parameters:
    ///   - color: 阴影颜色
    ///   - opacity: 不透明度
    func ls_addSoftShadow(
        color: UIColor = .black,
        opacity: Float = 0.1
    ) {
        // 创建三个方向的阴影层
        let shadow1 = CALayer()
        shadow1.frame = bounds.offsetBy(dx: 0, dy: 1)
        shadow1.shadowColor = color.cgColor
        shadow1.shadowOffset = .zero
        shadow1.shadowOpacity = opacity
        shadow1.shadowRadius = 2
        layer.insertSublayer(shadow1, at: 0)

        let shadow2 = CALayer()
        shadow2.frame = bounds.offsetBy(dx: 0, dy: 2)
        shadow2.shadowColor = color.cgColor
        shadow2.shadowOffset = .zero
        shadow2.shadowOpacity = opacity / 2
        shadow2.shadowRadius = 4
        layer.insertSublayer(shadow2, at: 0)

        let shadow3 = CALayer()
        shadow3.frame = bounds.offsetBy(dx: 0, dy: 3)
        shadow3.shadowColor = color.cgColor
        shadow3.shadowOffset = .zero
        shadow3.shadowOpacity = opacity / 4
        shadow3.shadowRadius = 6
        layer.insertSublayer(shadow3, at: 0)
    }
}

// MARK: - CALayer Extension (阴影)

public extension CALayer {

    /// 添加内阴影
    func ls_addInnerShadow(
        color: UIColor = .black,
        opacity: Float = 0.3,
        radius: CGFloat = 3,
        offset: CGSize = .zero
    ) {
        shadowColor = color.cgColor
        shadowOffset = offset
        shadowOpacity = opacity
        shadowRadius = radius
        masksToBounds = true
    }

    /// 添加描边阴影
    ///
    /// - Parameters:
    ///   - color: 阴影颜色
    ///   - opacity: 不透明度
    ///   - radius: 模糊半径
    ///   - width: 描边宽度
    func ls_addStrokeShadow(
        color: UIColor = .black,
        opacity: Float = 0.3,
        radius: CGFloat = 3,
        width: CGFloat = 1
    ) {
        shadowColor = color.cgColor
        shadowOpacity = opacity
        shadowRadius = radius
        borderWidth = width
        shadowOffset = .zero
    }
}

#endif

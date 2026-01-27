//
//  LSCornerRadius.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  圆角工具 - 简化视图圆角设置
//

#if canImport(UIKit)
import UIKit

// MARK: - UIView Extension (圆角)

public extension UIView {

    /// 关联的圆角遮罩视图
    private static var cornerMaskViewKey: UInt8 = 0

    /// 设置圆角（支持阴影）
    ///
    /// - Parameters:
    ///   - radius: 圆角半径
    ///   - corners: 圆角位置
    ///   - borderWidth: 边框宽度
    ///   - borderColor: 边框颜色
    func ls_cornerRadius(
        _ radius: CGFloat,
        corners: UIRectCorner = .allCorners,
        borderWidth: CGFloat = 0,
        borderColor: UIColor? = nil
    ) {
        // 使用 CAShapeLayer 实现圆角（支持阴影）
        let maskLayer = CAShapeLayer()
        maskLayer.path = UIBezierPath(
            roundedRect: bounds,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        ).cgPath
        layer.mask = maskLayer

        // 添加边框
        if borderWidth > 0 {
            let borderLayer = CAShapeLayer()
            borderLayer.path = maskLayer.path
            borderLayer.fillColor = UIColor.clear.cgColor
            borderLayer.strokeColor = borderColor?.cgColor ?? UIColor.clear.cgColor
            borderLayer.lineWidth = borderWidth
            borderLayer.frame = bounds
            layer.insertSublayer(borderLayer, at: 0)
        }
    }

    /// 设置圆角（简单方式）
    ///
    /// - Parameter radius: 圆角半径
    func ls_setCornerRadius(_ radius: CGFloat) {
        layer.cornerRadius = radius
        layer.masksToBounds = true
    }

    /// 设置指定角圆角
    ///
    /// - Parameters:
    ///   - radius: 圆角半径
    ///   - corners: 圆角位置
    func ls_setRoundedCorners(
        _ radius: CGFloat,
        corners: UIRectCorner
    ) {
        let path = UIBezierPath(
            roundedRect: bounds,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        ).cgPath

        let mask = CAShapeLayer()
        mask.path = path
        mask.frame = bounds
        layer.mask = mask
    }

    /// 设置顶部圆角
    ///
    /// - Parameter radius: 圆角半径
    func ls_roundTopCorners(radius: CGFloat) {
        ls_setRoundedCorners(radius, corners: [.topLeft, .topRight])
    }

    /// 设置底部圆角
    ///
    /// - Parameter radius: 圆角半径
    func ls_roundBottomCorners(radius: CGFloat) {
        ls_setRoundedCorners(radius, corners: [.bottomLeft, .bottomRight])
    }

    /// 设置左侧圆角
    ///
    /// - Parameter radius: 圆角半径
    func ls_roundLeftCorners(radius: CGFloat) {
        ls_setRoundedCorners(radius, corners: [.topLeft, .bottomLeft])
    }

    /// 设置右侧圆角
    ///
    /// - Parameter radius: 圆角半径
    func ls_roundRightCorners(radius: CGFloat) {
        ls_setRoundedCorners(radius, corners: [.topRight, .bottomRight])
    }

    /// 设置圆形
    func ls_setCircle() {
        layer.cornerRadius = min(bounds.width, bounds.height) / 2
        layer.masksToBounds = true
    }

    /// 设置椭圆
    func ls_setOval() {
        layer.cornerRadius = bounds.height / 2
        layer.masksToBounds = true
    }
}

// MARK: - UIImageView Extension (圆角图片)

public extension UIImageView {

    /// 设置圆角图片
    ///
    /// - Parameters:
    ///   - radius: 圆角半径
    ///   - corners: 圆角位置
    func ls_setRoundedImage(
        _ radius: CGFloat,
        corners: UIRectCorner = .allCorners
    ) {
        ls_setRoundedCorners(radius, corners: corners)
    }

    /// 设置圆形图片
    func ls_setCircular() {
        ls_setCircle()
        clipsToBounds = true
    }
}

// MARK: - UIButton Extension (圆角按钮)

public extension UIButton {

    /// 设置圆角按钮
    ///
    /// - Parameter radius: 圆角半径
    func ls_setRounded(_ radius: CGFloat) {
        layer.cornerRadius = radius
        layer.masksToBounds = true
    }

    /// 设置圆形按钮
    func ls_setCircular() {
        layer.cornerRadius = min(bounds.width, bounds.height) / 2
        layer.masksToBounds = true
    }

    /// 设置圆角（保持正方形比例）
    ///
    /// - Parameter radius: 圆角半径
    func ls_setRoundedSquare(_ radius: CGFloat) {
        layer.cornerRadius = radius
        layer.masksToBounds = true

        // 保持正方形
        let sizeConstraint = widthAnchor.constraint(equalTo: heightAnchor)
        sizeConstraint.priority = .required - 1
        sizeConstraint.isActive = true
    }
}

// MARK: - UILabel Extension (圆角标签)

public extension UILabel {

    /// 设置圆角标签
    ///
    /// - Parameter radius: 圆角半径
    func ls_setRounded(_ radius: CGFloat) {
        layer.cornerRadius = radius
        layer.masksToBounds = true
    }

    /// 设置药丸形状（半圆）
    func ls_setPillShape() {
        layer.cornerRadius = bounds.height / 2
        layer.masksToBounds = true
    }
}

// MARK: - CALayer Extension (圆角)

public extension CALayer {

    /// 设置圆角
    ///
    /// - Parameters:
    ///   - radius: 圆角半径
    ///   - corners: 圆角位置
    func ls_setCornerRadius(
        _ radius: CGFloat,
        corners: UIRectCorner = .allCorners
    ) {
        let path = UIBezierPath(
            roundedRect: bounds,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        ).cgPath

        let mask = CAShapeLayer()
        mask.path = path
        mask.frame = bounds
        self.mask = mask
    }

    /// 设置边框
    ///
    /// - Parameters:
    ///   - color: 边框颜色
    ///   - thickness: 边框粗细
    func ls_setBorder(color: UIColor, thickness: CGFloat) {
        borderColor = color.cgColor
        borderWidth = thickness
    }

    /// 设置虚线边框
    ///
    /// - Parameters:
    ///   - color: 边框颜色
    ///   - thickness: 边框粗细
    ///   - dashPattern: 虚线模式
    func ls_setDashedBorder(
        color: UIColor,
        thickness: CGFloat,
        dashPattern: [NSNumber]
    ) {
        borderColor = color.cgColor
        borderWidth = thickness
        lineDashPhase = 0
        lineDashPattern = dashPattern
    }

    /// 设置阴影
    ///
    /// - Parameters:
    ///   - color: 阴影颜色
    ///   - opacity: 不透明度
    ///   - radius: 模糊半径
    ///   - offset: 偏移
    func ls_setShadow(
        color: UIColor = .black,
        opacity: Float = 0.3,
        radius: CGFloat = 3,
        offset: CGSize = CGSize(width: 0, height: -2)
    ) {
        shadowColor = color.cgColor
        shadowOpacity = opacity
        shadowRadius = radius
        shadowOffset = offset
        masksToBounds = false
    }

    /// 移除阴影
    func ls_removeShadow() {
        shadowColor = nil
        shadowOffset = .zero
        shadowOpacity = 0
        shadowRadius = 0
    }
}

// MARK: - 便捷方法

public extension UIView {

    /// 创建带圆角的视图
    ///
    /// - Parameters:
    ///   - radius: 圆角半径
    ///   - borderColor: 边框颜色
    ///   - borderWidth: 边框宽度
    /// - Returns: 视图
    static func ls_create(
        radius: CGFloat,
        borderColor: UIColor? = nil,
        borderWidth: CGFloat = 0
    ) -> UIView {
        let view = UIView()
        view.layer.cornerRadius = radius
        view.layer.masksToBounds = true

        if let borderColor = borderColor {
            view.layer.borderColor = borderColor.cgColor
            view.layer.borderWidth = borderWidth
        }

        return view
    }

    /// 创建圆形视图
    ///
    /// - Parameters:
    ///   - size: 尺寸
    ///   - color: 背景颜色
    /// - Returns: 视图
    static func ls_circle(
        size: CGFloat,
        color: UIColor? = nil
    ) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
        view.layer.cornerRadius = size / 2
        view.layer.masksToBounds = true
        view.backgroundColor = color
        return view
    }

    /// 创建带边框的视图
    ///
    /// - Parameters:
    ///   - borderColor: 边框颜色
    ///   - borderWidth: 边框宽度
    ///   - cornerRadius: 圆角半径
    /// - Returns: 视图
    static func ls_border(
        borderColor: UIColor,
        borderWidth: CGFloat = 1,
        cornerRadius: CGFloat = 0
    ) -> UIView {
        let view = UIView()
        view.layer.borderColor = borderColor.cgColor
        view.layer.borderWidth = borderWidth
        view.layer.cornerRadius = cornerRadius
        view.layer.masksToBounds = true
        return view
    }

    /// 创建带阴影的视图
    ///
    /// - Parameters:
    ///   - shadowColor: 阴影颜色
    ///   - shadowOpacity: 阴影不透明度
    ///   - shadowRadius: 阴影半径
    /// - Returns: 视图
    static func ls_shadow(
        shadowColor: UIColor = .black,
        shadowOpacity: Float = 0.3,
        shadowRadius: CGFloat = 3
    ) -> UIView {
        let view = UIView()
        view.layer.ls_setShadow(
            color: shadowColor,
            opacity: shadowOpacity,
            radius: shadowRadius
        )
        return view
    }

    /// 创建药丸形状的视图
    ///
    /// - Parameters:
    ///   - width: 宽度
    ///   - height: 高度
    ///   - color: 背景颜色
    /// - Returns: 视图
    static func ls_pill(
        width: CGFloat,
        height: CGFloat,
        color: UIColor? = nil
    ) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        view.layer.cornerRadius = height / 2
        view.layer.masksToBounds = true
        view.backgroundColor = color
        return view
    }
}

// MARK: - 圆角常量

public extension CGFloat {

    /// 小圆角
    static var ls_smallCornerRadius: CGFloat {
        return 4
    }

    /// 中等圆角
    static var ls_mediumCornerRadius: CGFloat {
        return 8
    }

    /// 大圆角
    static var ls_largeCornerRadius: CGFloat {
        return 12
    }

    /// 超大圆角
    static var ls_xLargeCornerRadius: CGFloat {
        return 16
    }
}

// MARK: - 便捷圆角方法

public extension UIView {

    /// 应用小圆角
    func ls_applySmallCornerRadius() {
        ls_setCornerRadius(.ls_smallCornerRadius)
    }

    /// 应用中等圆角
    func ls_applyMediumCornerRadius() {
        ls_setCornerRadius(.ls_mediumCornerRadius)
    }

    /// 应用大圆角
    func ls_applyLargeCornerRadius() {
        ls_setCornerRadius(.ls_largeCornerRadius)
    }

    /// 应用超大圆角
    func ls_applyXLargeCornerRadius() {
        ls_setCornerRadius(.ls_xLargeCornerRadius)
    }

    /// 移除圆角
    func ls_removeCornerRadius() {
        layer.cornerRadius = 0
        layer.mask = nil
    }
}

// MARK: - 带圆角的容器视图

/// 圆角容器视图
public class LSRoundedView: UIView {

    /// 圆角半径
    public var cornerRadius: CGFloat = 8 {
        didSet {
            updateCornerRadius()
        }
    }

    /// 圆角位置
    public var roundedCorners: UIRectCorner = .allCorners {
        didSet {
            updateCornerRadius()
        }
    }

    /// 边框颜色
    public var borderColor: UIColor? {
        didSet {
            updateBorder()
        }
    }

    /// 边框宽度
    public var borderWidth: CGFloat = 0 {
        didSet {
            updateBorder()
        }
    }

    /// 阴影视图
    private let shadowContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    /// 内容视图
    private let contentView: UIView = {
        let view = UIView()
        return view
    }()

    // MARK: - 初始化

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
        addSubview(shadowContainerView)
        shadowContainerView.translatesAutoresizingMaskIntoConstraints = false
        shadowContainerView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)

        NSLayoutConstraint.activate([
            shadowContainerView.topAnchor.constraint(equalTo: topAnchor),
            shadowContainerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            shadowContainerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            shadowContainerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentView.topAnchor.constraint(equalTo: shadowContainerView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: shadowContainerView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: shadowContainerView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: shadowContainerView.bottomAnchor)
        ])

        clipsToBounds = false
    }

    private func updateCornerRadius() {
        if roundedCorners == .allCorners {
            contentView.layer.cornerRadius = cornerRadius
            contentView.layer.masksToBounds = true
            contentView.layer.mask = nil
        } else {
            contentView.layer.cornerRadius = 0
            contentView.layer.masksToBounds = false

            let path = UIBezierPath(
                roundedRect: contentView.bounds,
                byRoundingCorners: roundedCorners,
                cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
            ).cgPath

            let mask = CAShapeLayer()
            mask.path = path
            contentView.layer.mask = mask
        }
    }

    private func updateBorder() {
        if let borderColor = borderColor {
            contentView.layer.borderColor = borderColor.cgColor
            contentView.layer.borderWidth = borderWidth
        } else {
            contentView.layer.borderWidth = 0
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        updateCornerRadius()
    }
}

#endif

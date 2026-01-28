//
//  LSBlurEffect.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  模糊效果工具 - 提供多种模糊效果实现
//

#if canImport(UIKit)
import UIKit
import Foundation
import Accelerate

// MARK: - LSBlurEffect

/// 模糊效果类型
public enum LSBlurEffectStyle {
    case light               // 亮色模糊
    case regular             // 标准模糊
    case dark                // 暗色模糊
    case extraLight          // 超亮模糊
    case prominent           // 突出模糊
    case custom(radius: CGFloat, tint: UIColor?)  // 自定义
}

// MARK: - LSBlurView

/// 模糊视图
@MainActor
public class LSBlurView: UIView {

    // MARK: - 属性

    /// 模糊样式
    public var blurStyle: LSBlurEffectStyle = .regular {
        didSet {
            updateBlur()
        }
    }

    /// 模糊半径
    public var blurRadius: CGFloat = 20 {
        didSet {
            updateBlur()
        }
    }

    /// 色调颜色
    public var tintColor: UIColor? = nil {
        didSet {
            updateBlur()
        }
    }

    /// 是否使用实时模糊（iOS 13+）
    public var usesRealTimeBlur: Bool = true {
        didSet {
            updateBlur()
        }
    }

    /// 模糊效果视图
    private var blurEffectView: UIVisualEffectView?

    /// 模糊图层
    private var blurLayer: CALayer?

    // MARK: - 初始化

    public init(style: LSBlurEffectStyle = .regular) {
        self.blurStyle = style
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
        backgroundColor = .clear
        updateBlur()
    }

    // MARK: - 更新模糊

    private func updateBlur() {
        // 移除旧的模糊效果
        blurEffectView?.removeFromSuperview()
        blurEffectView = nil
        blurLayer?.removeFromSuperlayer()
        blurLayer = nil

        if usesRealTimeBlur {
            setupRealTimeBlur()
        } else {
            setupStaticBlur()
        }
    }

    /// 设置实时模糊
    private func setupRealTimeBlur() {
        guard #available(iOS 13.0, *) else {
            setupStaticBlur()
            return
        }

        let style: UIBlurEffect.Style
        var tint: UIColor?

        switch blurStyle {
        case .light:
            style = .light
            tint = nil
        case .regular:
            style = .regular
            tint = nil
        case .dark:
            style = .dark
            tint = nil
        case .extraLight:
            style = .extraLight
            tint = nil
        case .prominent:
            style = .prominent
            tint = nil
        case .custom(_, let customTint):
            style = .regular
            tint = customTint
        }

        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurView)

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // 应用色调
        let tint
        if let tempTint = tint {
            tint = tempTint
        } else {
            tint = tintColor {
        }
            blurView.backgroundColor = tint.withAlphaComponent(0.3)
        }

        blurEffectView = blurView
    }

    /// 设置静态模糊（使用 Core Image）
    private func setupStaticBlur() {
        let blurLayer = CALayer()
        layer.addSublayer(blurLayer)
        self.blurLayer = blurLayer

        // 需要捕获背景内容
        DispatchQueue.main.async {
            self.captureAndBlurBackground()
        }
    }

    /// 捕获并模糊背景
    private func captureAndBlurBackground() {
        // 截取父视图的图像
        guard let superview = superview,
              let image = captureSuperview(superview) else {
            return
        }

        // 应用模糊
        let blurredImage = image.ls_blurred(radius: blurRadius)

        // 创建图层
        blurLayer?.contents = blurredImage?.cgImage
        blurLayer?.frame = bounds

        // 应用色调
        if let tint = tintColor {
            blurLayer?.backgroundColor = tint.cgColor
        }
    }

    /// 捕获父视图
    private func captureSuperview(_ superview: UIView) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(superview.bounds.size, false, 0)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        // 转换坐标系
        let point = convert(CGPoint.zero, to: superview)
        context.translateBy(x: -point.x, y: -point.y)

        // 绘制父视图
        superview.layer.render(in: context)

        return UIGraphicsGetImageFromCurrentImageContext()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        if !usesRealTimeBlur {
            blurLayer?.frame = bounds
            captureAndBlurBackground()
        }
    }
}

// MARK: - UIImage Extension (模糊)

public extension UIImage {

    /// 模糊图片
    ///
    /// - Parameter radius: 模糊半径
    /// - Returns: 模糊后的图片
    func ls_blurred(radius: CGFloat) -> UIImage? {
        guard let cgImage = cgImage else { return nil }

        let inputImage = CIImage(cgImage: cgImage)
        guard let filter = CIFilter(name: "CIGaussianBlur") else { return nil }

        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(radius, forKey: kCIInputRadiusKey)

        guard let outputImage = filter.outputImage else { return nil }

        let context = CIContext(options: [.useSoftwareRenderer: false])
        guard let result = context.createCGImage(outputImage, from: inputImage.extent) else {
            return nil
        }

        return UIImage(cgImage: result)
    }

    /// 使用 vImage 模糊（更快）
    ///
    /// - Parameter radius: 模糊半径
    /// - Returns: 模糊后的图片
    func ls_blurredFast(radius: CGFloat) -> UIImage? {
        guard let cgImage = cgImage else { return nil }

        let context = CIContext(options: [.useSoftwareRenderer: false])
        let inputImage = CIImage(cgImage: cgImage)

        guard let filter = CIFilter(name: "CIGaussianBlur") else { return nil }
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(radius, forKey: kCIInputRadiusKey)

        guard let outputImage = filter.outputImage else { return nil }

        if let result = context.createCGImage(outputImage, from: inputImage.extent) {
            return UIImage(cgImage: result, scale: scale, orientation: imageOrientation)
        }

        return nil
    }

    /// 应用模糊效果到图片的指定区域
    ///
    /// - Parameters:
    ///   - rect: 模糊区域
    ///   - radius: 模糊半径
    /// - Returns: 处理后的图片
    func ls_blurred(in rect: CGRect, radius: CGFloat) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }

        // 创建裁剪的图像
        guard let croppedCGImage = cgImage.cropping(to: rect) else { return nil }
        let croppedImage = UIImage(cgImage: croppedCGImage)

        // 模糊裁剪的图像
        guard let blurredCropped = croppedImage?.ls_blurred(radius: radius) else { return nil }

        // 绘制到原始图像
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }

        draw(at: .zero)
        blurredCropped.draw(in: rect)

        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

// MARK: - UIView Extension (模糊)

public extension UIView {

    /// 添加模糊效果
    ///
    /// - Parameters:
    ///   - style: 模糊样式
    ///   - radius: 模糊半径
    /// - Returns: 模糊视图
    @discardableResult
    func ls_addBlur(
        style: LSBlurEffectStyle = .regular,
        radius: CGFloat = 20
    ) -> LSBlurView {
        let blurView = LSBlurView(style: style)
        blurView.blurRadius = radius
        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(blurView, at: 0)
        return blurView
    }

    /// 移除模糊效果
    func ls_removeBlur() {
        subviews.forEach {
            if let blurView = $0 as? LSBlurView {
                blurView.removeFromSuperview()
            }
        }
    }
}

// MARK: - UIVisualEffectView Extension (模糊)

public extension UIVisualEffectView {

    /// 创建模糊视图
    ///
    /// - Parameter style: 模糊样式
    /// - Returns: 模糊视图
    static func ls_blur(style: UIBlurEffect.Style = .regular) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: style)
        return UIVisualEffectView(effect: blurEffect)
    }

    /// 创建带颜色的模糊视图
    ///
    /// - Parameters:
    ///   - style: 模糊样式
    ///   - color: 颜色
    ///   - alpha: 透明度
    /// - Returns: 模糊视图
    static func ls_blur(
        style: UIBlurEffect.Style = .regular,
        color: UIColor,
        alpha: CGFloat = 0.3
    ) -> UIVisualEffectView {
        let blurView = ls_blur(style: style)
        blurView.backgroundColor = color.withAlphaComponent(alpha)
        return blurView
    }

    /// 更新模糊效果
    ///
    /// - Parameter style: 新样式
    func ls_update(style: UIBlurEffect.Style) {
        effect = UIBlurEffect(style: style)
    }
}

// MARK: - UILabel Extension (模糊背景)

public extension UILabel {

    /// 添加模糊背景
    ///
    /// - Parameters:
    ///   - style: 模糊样式
    ///   - padding: 内边距
    ///   - cornerRadius: 圆角
    /// - Returns: 模糊视图
    @discardableResult
    func ls_addBlurBackground(
        style: LSBlurEffectStyle = .regular,
        padding: UIEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12),
        cornerRadius: CGFloat = 8
    ) -> LSBlurView {
        let blurView = LSBlurView(style: style)
        blurView.layer.cornerRadius = cornerRadius
        blurView.clipsToBounds = true

        addSubview(blurView)
        sendSubviewToBack(blurView)

        blurView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor, constant: -padding.top),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -padding.left),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: padding.right),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: padding.bottom)
        ])

        return blurView
    }
}

// MARK: - UIButton Extension (模糊背景)

public extension UIButton {

    /// 添加模糊背景
    ///
    /// - Parameters:
    ///   - style: 模糊样式
    ///   - padding: 内边距
    ///   - cornerRadius: 圆角
    /// - Returns: 模糊视图
    @discardableResult
    func ls_addBlurBackground(
        style: LSBlurEffectStyle = .regular,
        padding: UIEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12),
        cornerRadius: CGFloat = 8
    ) -> LSBlurView {
        let blurView = LSBlurView(style: style)
        blurView.layer.cornerRadius = cornerRadius
        blurView.clipsToBounds = true
        blurView.isUserInteractionEnabled = false

        insertSubview(blurView, at: 0)

        blurView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor, constant: -padding.top),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -padding.left),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: padding.right),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: padding.bottom)
        ])

        return blurView
    }
}

// MARK: - 快速创建模糊效果

public extension LSBlurEffectStyle {

    /// 转换为系统模糊样式
    var systemStyle: UIBlurEffect.Style {
        switch self {
        case .light:
            return .light
        case .regular:
            return .regular
        case .dark:
            return .dark
        case .extraLight:
            return .extraLight
        case .prominent:
            if #available(iOS 13.0, *) {
                return .prominent
            } else {
                return .regular
            }
        case .custom:
            return .regular
        }
    }
}

// MARK: - 模糊效果预设

public extension LSBlurView {

    /// 创建导航栏模糊视图
    static func navigationBar() -> LSBlurView {
        let blurView = LSBlurView(style: .regular)
        blurView.tintColor = .white.withAlphaComponent(0.7)
        return blurView
    }

    /// 创建工具栏模糊视图
    static func toolBar() -> LSBlurView {
        let blurView = LSBlurView(style: .regular)
        blurView.tintColor = .white.withAlphaComponent(0.7)
        return blurView
    }

    /// 创建弹出层模糊视图
    static func popover() -> LSBlurView {
        let blurView = LSBlurView(style: .light)
        blurView.tintColor = .white.withAlphaComponent(0.9)
        return blurView
    }

    /// 创建深色主题模糊视图
    static func darkTheme() -> LSBlurView {
        let blurView = LSBlurView(style: .dark)
        blurView.tintColor = .black.withAlphaComponent(0.5)
        return blurView
    }
}

#endif

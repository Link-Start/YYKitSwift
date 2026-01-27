//
//  LSTextMagnifier.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  文本放大镜 - 用于文本选择时的放大效果
//

#if canImport(UIKit)
import UIKit

// MARK: - LSTextMagnifier

/// 文本放大镜，用于显示文本选择的放大效果
///
/// 类似系统 UITextView 的放大镜效果
@MainActor
public class LSTextMagnifier: UIView {

    // MARK: - 属性

    /// 放大倍数（默认 1.5）
    public var magnification: CGFloat = 1.5 {
        didSet {
            _updateMagnification()
        }
    }

    /// 放大镜大小
    public var magnifierSize: CGSize = CGSize(width: 120, height: 120) {
        didSet {
            _updateSize()
        }
    }

    /// 边框宽度
    public var borderWidth: CGFloat = 1 {
        didSet {
            _updateAppearance()
        }
    }

    /// 边框颜色
    public var borderColor: UIColor = UIColor(white: 0.7, alpha: 1) {
        didSet {
            _updateAppearance()
        }
    }

    /// 阴影半径
    public var shadowRadius: CGFloat = 5 {
        didSet {
            _updateAppearance()
        }
    }

    /// 阴影不透明度
    public var shadowOpacity: Float = 0.3 {
        didSet {
            _updateAppearance()
        }
    }

    /// 要放大的视图
    public weak var targetView: UIView? {
        didSet {
            _renderLayer.contents = nil
        }
    }

    /// 放大中心点（在 targetView 坐标系中）
    public var targetPoint: CGPoint = .zero {
        didSet {
            _updateContent()
        }
    }

    // MARK: - 私有属性

    private var _renderLayer: CALayer
    private var _borderLayer: CAShapeLayer
    private var _containerLayer: CALayer

    // MARK: - 初始化

    public override init(frame: CGRect) {
        _renderLayer = CALayer()
        _borderLayer = CAShapeLayer()
        _containerLayer = CALayer()

        super.init(frame: frame)

        _commonInit()
    }

    required init?(coder: NSCoder) {
        _renderLayer = CALayer()
        _borderLayer = CAShapeLayer()
        _containerLayer = CALayer()

        super.init(coder: coder)

        _commonInit()
    }

    private func _commonInit() {
        backgroundColor = .clear
        isUserInteractionEnabled = false

        // 设置容器层
        _containerLayer.masksToBounds = true
        layer.addSublayer(_containerLayer)

        // 设置渲染层
        _containerLayer.addSublayer(_renderLayer)

        // 设置边框层
        layer.addSublayer(_borderLayer)

        _updateSize()
        _updateAppearance()
    }

    // MARK: - 布局

    public override func layoutSubviews() {
        super.layoutSubviews()

        _containerLayer.frame = bounds
        _borderLayer.frame = bounds
        _renderLayer.frame = bounds

        _updateBorderPath()
    }

    // MARK: - 私有方法

    private func _updateSize() {
        bounds = CGRect(origin: .zero, size: magnifierSize)
        setNeedsLayout()
    }

    private func _updateMagnification() {
        _updateContent()
    }

    private func _updateAppearance() {
        // 更新阴影
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowRadius = shadowRadius
        layer.shadowOpacity = shadowOpacity
        layer.shadowOffset = CGSize(width: 0, height: 2)

        // 更新边框
        _borderLayer.fillColor = UIColor.clear.cgColor
        _borderLayer.strokeColor = borderColor.cgColor
        _borderLayer.lineWidth = borderWidth

        _updateBorderPath()
    }

    private func _updateBorderPath() {
        let path = UIBezierPath(ovalIn: bounds)
        _borderLayer.path = path.cgPath
    }

    private func _updateContent() {
        guard let targetView = targetView else { return }

        // 计算渲染区域
        let magnifierSize = bounds.size
        let renderSize = CGSize(
            width: magnifierSize.width / magnification,
            height: magnifierSize.height / magnification
        )

        let renderOrigin = CGPoint(
            x: targetPoint.x - renderSize.width / 2,
            y: targetPoint.y - renderSize.height / 2
        )

        let renderRect = CGRect(origin: renderOrigin, size: renderSize)

        // 捕获视图内容
        if let snapshot = _captureView(targetView, in: renderRect) {
            _renderLayer.contents = snapshot
            _renderLayer.contentsScale = UIScreen.main.scale * magnification
            _renderLayer.contentsGravity = .resizeAspect
        }
    }

    private func _captureView(_ view: UIView, in rect: CGRect) -> UIImage? {
        // 使用 UIGraphicsImageRenderer 捕获视图
        let renderer = UIGraphicsImageRenderer(size: rect.size)
        return renderer.image { context in
            // 转换坐标系
            context.cgContext.translateBy(x: -rect.origin.x, y: -rect.origin.y)

            // 渲染视图
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
    }

    // MARK: - 公共方法

    /// 显示放大镜
    ///
    /// - Parameters:
    ///   - point: 要放大的点（在目标视图坐标系中）
    ///   - view: 目标视图
    ///   - animated: 是否动画
    public func show(at point: CGPoint, in view: UIView, animated: Bool = true) {
        targetView = view
        targetPoint = point

        // 计算放大镜位置（在点上方）
        let magnifierOrigin = CGPoint(
            x: point.x - magnifierSize.width / 2,
            y: point.y - magnifierSize.height - 20
        )

        // 确保在父视图范围内
        var finalOrigin = magnifierOrigin
        if let superview = superview {
            finalOrigin.x = max(0, min(finalOrigin.x, superview.bounds.width - magnifierSize.width))
            finalOrigin.y = max(0, min(finalOrigin.y, superview.bounds.height - magnifierSize.height))
        }

        frame = CGRect(origin: finalOrigin, size: magnifierSize)

        if animated {
            alpha = 0
            transform = CGAffineTransform(scaleX: 0.5, y: 0.5)

            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
                self.alpha = 1
                self.transform = .identity
            }
        }

        _updateContent()
    }

    /// 更新放大镜位置
    ///
    /// - Parameter point: 新的位置（在目标视图坐标系中）
    public func updatePosition(_ point: CGPoint) {
        targetPoint = point

        // 计算放大镜位置
        let magnifierOrigin = CGPoint(
            x: point.x - magnifierSize.width / 2,
            y: point.y - magnifierSize.height - 20
        )

        // 确保在父视图范围内
        var finalOrigin = magnifierOrigin
        if let superview = superview {
            finalOrigin.x = max(0, min(finalOrigin.x, superview.bounds.width - magnifierSize.width))
            finalOrigin.y = max(0, min(finalOrigin.y, superview.bounds.height - magnifierSize.height))
        }

        frame = CGRect(origin: finalOrigin, size: magnifierSize)

        _updateContent()
    }

    /// 隐藏放大镜
    ///
    /// - Parameter animated: 是否动画
    public func hide(animated: Bool = true) {
        if animated {
            UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseIn) {
                self.alpha = 0
                self.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            } completion: { _ in
                self.removeFromSuperview()
            }
        } else {
            removeFromSuperview()
        }
    }
}

// MARK: - LSTextMagnifierLocation

/// 放大镜位置
public enum LSTextMagnifierLocation: Int {
    case automatic = 0  // 自动选择位置
    case above = 1      // 在光标上方
    case below = 2      // 在光标下方
    case left = 3       // 在光标左侧
    case right = 4      // 在光标右侧
}

// MARK: - LSTextLoupe

/// 文本放大镜（圆形放大镜）
///
/// iOS 风格的圆形放大镜
public class LSTextLoupe: LSTextMagnifier {

    // MARK: - 属性

    /// 放大镜位置偏好
    public var preferredLocation: LSTextMagnifierLocation = .automatic

    /// 距离光标的偏移
    public var offsetFromCaret: CGFloat = 50

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        _setupLoupe()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _setupLoupe()
    }

    private func _setupLoupe() {
        magnifierSize = CGSize(width: 120, height: 120)
        borderWidth = 2
        borderColor = UIColor(white: 0.8, alpha: 1)
        magnification = 1.5
    }

    // MARK: - 公共方法

    /// 显示放大镜在光标附近
    ///
    /// - Parameters:
    ///   - caretRect: 光标矩形
    ///   - view: 目标视图
    ///   - animated: 是否动画
    public func show(at caretRect: CGRect, in view: UIView, animated: Bool = true) {
        let targetPoint = CGPoint(x: caretRect.midX, y: caretRect.midY)

        // 根据位置偏好计算放大镜位置
        let magnifierOrigin = _calculateOrigin(for: caretRect, in: view)

        frame = CGRect(origin: magnifierOrigin, size: magnifierSize)

        targetView = view
        targetPoint = targetPoint

        if animated {
            alpha = 0
            transform = CGAffineTransform(scaleX: 0.5, y: 0.5)

            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
                self.alpha = 1
                self.transform = .identity
            }
        }

        _updateContent()
    }

    private func _calculateOrigin(for caretRect: CGRect, in view: UIView) -> CGPoint {
        let availableHeight = view.bounds.height - magnifierSize.height
        let availableWidth = view.bounds.width - magnifierSize.width

        switch preferredLocation {
        case .above:
            return CGPoint(
                x: max(0, min(caretRect.midX - magnifierSize.width / 2, availableWidth)),
                y: max(0, caretRect.minY - magnifierSize.height - offsetFromCaret)
            )

        case .below:
            return CGPoint(
                x: max(0, min(caretRect.midX - magnifierSize.width / 2, availableWidth)),
                y: min(availableHeight, caretRect.maxY + offsetFromCaret)
            )

        case .left:
            return CGPoint(
                x: max(0, caretRect.minX - magnifierSize.width - offsetFromCaret),
                y: max(0, min(caretRect.midY - magnifierSize.height / 2, availableHeight))
            )

        case .right:
            return CGPoint(
                x: min(availableWidth, caretRect.maxX + offsetFromCaret),
                y: max(0, min(caretRect.midY - magnifierSize.height / 2, availableHeight))
            )

        case .automatic:
            // 自动选择最佳位置（优先上方）
            let aboveY = caretRect.minY - magnifierSize.height - offsetFromCaret
            if aboveY >= 0 {
                return CGPoint(
                    x: max(0, min(caretRect.midX - magnifierSize.width / 2, availableWidth)),
                    y: aboveY
                )
            } else {
                return CGPoint(
                    x: max(0, min(caretRect.midX - magnifierSize.width / 2, availableWidth)),
                    y: min(availableHeight, caretRect.maxY + offsetFromCaret)
                )
            }
        }
    }
}

#endif

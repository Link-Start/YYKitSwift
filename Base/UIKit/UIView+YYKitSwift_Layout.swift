//
//  UIView+YYKitSwift_Layout.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  UIView 扩展 - 布局辅助方法
//

#if canImport(UIKit)
import UIKit

// MARK: - UIView Extension (Layout)

@MainActor
public extension UIView {

    // MARK: - Frame 属性

    /// 左边位置
    var ls_left: CGFloat {
        get { return frame.origin.x }
        set { frame.origin.x = newValue }
    }

    /// 顶部位置
    var ls_top: CGFloat {
        get { return frame.origin.y }
        set { frame.origin.y = newValue }
    }

    /// 右边位置
    var ls_right: CGFloat {
        get { return frame.origin.x + frame.size.width }
        set { frame.origin.x = newValue - frame.size.width }
    }

    /// 底部位置
    var ls_bottom: CGFloat {
        get { return frame.origin.y + frame.size.height }
        set { frame.origin.y = newValue - frame.size.height }
    }

    /// 宽度
    var ls_width: CGFloat {
        get { return frame.size.width }
        set { frame.size.width = newValue }
    }

    /// 高度
    var ls_height: CGFloat {
        get { return frame.size.height }
        set { frame.size.height = newValue }
    }

    /// 中心点 X
    var ls_centerX: CGFloat {
        get { return center.x }
        set { center.x = newValue }
    }

    /// 中心点 Y
    var ls_centerY: CGFloat {
        get { return center.y }
        set { center.y = newValue }
    }

    /// 原点
    var ls_origin: CGPoint {
        get { return frame.origin }
        set { frame.origin = newValue }
    }

    /// 尺寸
    var ls_size: CGSize {
        get { return frame.size }
        set { frame.size = newValue }
    }

    // MARK: - 边界

    /// 相对于父视图的边界
    var ls_boundsInSuperview: CGRect {
        guard let superview = superview else { return bounds }
        return convert(bounds, to: superview)
    }

    /// 相对于窗口的边界
    var ls_boundsInWindow: CGRect? {
        guard let window = window else { return nil }
        return convert(bounds, to: window)
    }

    // MARK: - 视图层级

    /// 视图所在的 UIViewController
    var ls_viewController: UIViewController? {
        var responder: UIResponder? = self
        while let next = responder?.next {
            if let viewController = next as? UIViewController {
                return viewController
            }
            responder = next
        }
        return nil
    }

    /// 所有父视图
    var ls_superviews: [UIView] {
        var views: [UIView] = []
        var currentView: UIView? = self
        while let superview = currentView?.superview {
            views.append(superview)
            currentView = superview
        }
        return views
    }

    /// 所有子视图
    var ls_allSubviews: [UIView] {
        var views: [UIView] = []
        views.append(contentsOf: subviews)
        for subview in subviews {
            views.append(contentsOf: subview.ls_allSubviews)
        }
        return views
    }

    // MARK: - 视图操作

    /// 移除所有子视图
    func ls_removeAllSubviews() {
        for subview in subviews {
            subview.removeFromSuperview()
        }
    }

    /// 添加多个子视图
    ///
    /// - Parameter views: 子视图数组
    func ls_addSubviews(_ views: [UIView]) {
        views.forEach { addSubview($0) }
    }

    /// 查找指定类型的父视图
    ///
    /// - Parameter type: 视图类型
    /// - Returns: 找到的视图
    func ls_superviewOfType<T: UIView>(_ type: T.Type) -> T? {
        var currentView: UIView? = superview
        while let view = currentView {
            if let foundView = view as? T {
                return foundView
            }
            currentView = view.superview
        }
        return nil
    }

    /// 查找指定类型的子视图
    ///
    /// - Parameter type: 视图类型
    /// - Returns: 找到的视图数组
    func ls_subviewsOfType<T: UIView>(_ type: T.Type) -> [T] {
        var result: [T] = []
        for subview in subviews {
            if let foundView = subview as? T {
                result.append(foundView)
            }
            result.append(contentsOf: subview.ls_subviewsOfType(type))
        }
        return result
    }

    /// 查找第一个指定类型的子视图
    ///
    /// - Parameter type: 视图类型
    /// - Returns: 找到的视图
    func ls_firstSubviewOfType<T: UIView>(_ type: T.Type) -> T? {
        for subview in subviews {
            if let foundView = subview as? T {
                return foundView
            }
            if let foundView = subview.ls_firstSubviewOfType(type) {
                return foundView
            }
        }
        return nil
    }

    // MARK: - 圆角

    /// 设置圆角
    ///
    /// - Parameters:
    ///   - cornerRadius: 圆角半径
    ///   - corners: 要圆角的位置（默认全部）
    func ls_setCornerRadius(_ cornerRadius: CGFloat, corners: UIRectCorner = .allCorners) {
        clipsToBounds = true
        layer.cornerRadius = cornerRadius

        if corners != .allCorners {
            let path = UIBezierPath(
                roundedRect: bounds,
                byRoundingCorners: corners,
                cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
            )
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            layer.mask = mask
        }
    }

    /// 添加边框
    ///
    /// - Parameters:
    ///   - width: 边框宽度
    ///   - color: 边框颜色
    func ls_addBorder(width: CGFloat, color: UIColor) {
        layer.borderWidth = width
        layer.borderColor = color.cgColor
    }

    /// 移除边框
    func ls_removeBorder() {
        layer.borderWidth = 0
        layer.borderColor = nil
    }

    // MARK: - 阴影

    /// 添加阴影
    ///
    /// - Parameters:
    ///   - color: 阴影颜色
    ///   - offset: 偏移量
    ///   - opacity: 不透明度
    ///   - radius: 模糊半径
    func ls_addShadow(color: UIColor, offset: CGSize, opacity: Float, radius: CGFloat) {
        layer.shadowColor = color.cgColor
        layer.shadowOffset = offset
        layer.shadowOpacity = opacity
        layer.shadowRadius = radius
        layer.masksToBounds = false
    }

    /// 移除阴影
    func ls_removeShadow() {
        layer.shadowColor = nil
        layer.shadowOffset = .zero
        layer.shadowOpacity = 0
        layer.shadowRadius = 0
    }

    // MARK: - 渐变

    /// 添加渐变背景
    ///
    /// - Parameters:
    ///   - colors: 渐变颜色数组
    ///   - startPoint: 起始点
    ///   - endPoint: 结束点
    /// - Returns: CAGradientLayer
    @discardableResult
    func ls_addGradient(colors: [UIColor], startPoint: CGPoint = CGPoint(x: 0, y: 0), endPoint: CGPoint = CGPoint(x: 1, y: 1)) -> CAGradientLayer {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        layer.insertSublayer(gradientLayer, at: 0)
        return gradientLayer
    }

    // MARK: - 动画

    /// 淡入动画
    ///
    /// - Parameters:
    ///   - duration: 动画时长
    ///   - completion: 完成回调
    func ls_fadeIn(duration: TimeInterval = 0.3, completion: (() -> Void)? = nil) {
        alpha = 0
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 1
        }, completion: { _ in
            completion?()
        })
    }

    /// 淡出动画
    ///
    /// - Parameters:
    ///   - duration: 动画时长
    ///   - completion: 完成回调
    func ls_fadeOut(duration: TimeInterval = 0.3, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 0
        }, completion: { _ in
            completion?()
        })
    }

    /// 缩放动画
    ///
    /// - Parameters:
    ///   - scale: 缩放比例
    ///   - duration: 动画时长
    ///   - completion: 完成回调
    func ls_scale(to scale: CGFloat, duration: TimeInterval = 0.3, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration, animations: {
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
        }, completion: { _ in
            completion?()
        })
    }

    /// 旋转动画
    ///
    /// - Parameters:
    ///   - angle: 旋转角度（弧度）
    ///   - duration: 动画时长
    ///   - completion: 完成回调
    func ls_rotate(by angle: CGFloat, duration: TimeInterval = 0.3, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration, animations: {
            self.transform = CGAffineTransform(rotationAngle: angle)
        }, completion: { _ in
            completion?()
        })
    }

    /// 弹簧动画
    ///
    /// - Parameters:
    ///   - duration: 动画时长
    ///   - damping: 阻尼系数
    ///   - velocity: 初始速度
    ///   - animations: 动画闭包
    ///   - completion: 完成回调
    func ls_springAnimate(duration: TimeInterval = 0.5, damping: CGFloat = 0.7, velocity: CGFloat = 0.5, animations: @escaping () -> Void, completion: (() -> Void)? = nil) {
        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: damping,
            initialSpringVelocity: velocity,
            options: .curveEaseInOut,
            animations: animations,
            completion: { _ in
                completion?()
            }
        )
    }

    // MARK: - 截图

    /// 转换为图片
    ///
    /// - Returns: UIImage
    func ls_toImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }

        if let context = UIGraphicsGetCurrentContext() {
            layer.render(in: context)
            return UIGraphicsGetImageFromCurrentImageContext()
        }
        return nil
    }

    /// 转换为图片（指定尺寸）
    ///
    /// - Parameter size: 尺寸
    /// - Returns: UIImage
    func ls_toImage(size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }

        if let context = UIGraphicsGetCurrentContext() {
            let scaledSize = CGSize(
                width: size.width / bounds.width * layer.bounds.width,
                height: size.height / bounds.height * layer.bounds.height
            )
            let origin = CGPoint(
                x: (size.width - scaledSize.width) / 2,
                y: (size.height - scaledSize.height) / 2
            )

            layer.render(in: context)
            return UIGraphicsGetImageFromCurrentImageContext()
        }
        return nil
    }

    // MARK: - 手势

    /// 添加点击手势
    ///
    /// - Parameter action: 点击回调
    /// - Returns: UITapGestureRecognizer
    @discardableResult
    func ls_addTapGesture(action: @escaping () -> Void) -> UITapGestureRecognizer {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        tapGesture.numberOfTapsRequired = 1
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true

        // 使用关联对象存储回调
        objc_setAssociatedObject(self, &AssociatedKeys.tapGestureAction, action, .OBJC_ASSOCIATION_COPY_NONATOMIC)

        return tapGesture
    }

    /// 添加长按手势
    ///
    /// - Parameters:
    ///   - minimumDuration: 最小长按时长
    ///   - action: 长按回调
    /// - Returns: UILongPressGestureRecognizer
    @discardableResult
    func ls_addLongPressGesture(minimumDuration: TimeInterval = 0.5, action: @escaping () -> Void) -> UILongPressGestureRecognizer {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture(_:)))
        longPressGesture.minimumPressDuration = minimumDuration
        addGestureRecognizer(longPressGesture)
        isUserInteractionEnabled = true

        objc_setAssociatedObject(self, &AssociatedKeys.longPressGestureAction, action, .OBJC_ASSOCIATION_COPY_NONATOMIC)

        return longPressGesture
    }

    @objc private func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        if let action = objc_getAssociatedObject(self, &AssociatedKeys.tapGestureAction) as? () -> Void {
            action()
        }
    }

    @objc private func handleLongPressGesture(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began,
           let action = objc_getAssociatedObject(self, &AssociatedKeys.longPressGestureAction) as? () -> Void {
            action()
        }
    }

    // MARK: - 响应者

    /// 查找第一响应者
    ///
    /// - Returns: 第一响应者
    func ls_findFirstResponder() -> UIView? {
        if isFirstResponder {
            return self
        }
        for subview in subviews {
            if let found = subview.ls_findFirstResponder() {
                return found
            }
        }
        return nil
    }

    /// 收起键盘
    func ls_resignFirstResponder() -> Bool {
        if let tempValue = ls_findFirstResponder()?.resignFirstResponder() {
            return tempValue
        }
        return true
    }
}

// MARK: - Associated Keys

private enum AssociatedKeys {
    static var tapGestureAction = "tapGestureAction"
    static var longPressGestureAction = "longPressGestureAction"
}

// MARK: - CGPoint Extension

public extension CGPoint {

    /// 距离另一个点的距离
    func ls_distance(to point: CGPoint) -> CGFloat {
        let dx = x - point.x
        let dy = y - point.y
        return sqrt(dx * dx + dy * dy)
    }
}

// MARK: - CGSize Extension

public extension CGSize {

    /// 调整尺寸以适应指定尺寸（保持宽高比）
    func ls_fitted(in size: CGSize) -> CGSize {
        let aspectRatio = width / height
        let targetAspectRatio = size.width / size.height

        if aspectRatio > targetAspectRatio {
            let newWidth = size.width
            let newHeight = newWidth / aspectRatio
            return CGSize(width: newWidth, height: newHeight)
        } else {
            let newHeight = size.height
            let newWidth = newHeight * aspectRatio
            return CGSize(width: newWidth, height: newHeight)
        }
    }

    /// 调整尺寸以填充指定尺寸（保持宽高比）
    func ls_filling(_ size: CGSize) -> CGSize {
        let aspectRatio = width / height
        let targetAspectRatio = size.width / size.height

        if aspectRatio < targetAspectRatio {
            let newWidth = size.width
            let newHeight = newWidth / aspectRatio
            return CGSize(width: newWidth, height: newHeight)
        } else {
            let newHeight = size.height
            let newWidth = newHeight * aspectRatio
            return CGSize(width: newWidth, height: newHeight)
        }
    }
}

// MARK: - CGRect Extension

public extension CGRect {

    /// 中心点
    var ls_center: CGPoint {
        get { return CGPoint(x: midX, y: midY) }
        set {
            origin = CGPoint(
                x: newValue.x - width / 2,
                y: newValue.y - height / 2
            )
        }
    }

    /// 调整尺寸以适应指定矩形（保持宽高比）
    func ls_fitted(in rect: CGRect) -> CGRect {
        let size = self.size.ls_fitted(in: rect.size)
        let origin = CGPoint(
            x: rect.origin.x + (rect.size.width - size.width) / 2,
            y: rect.origin.y + (rect.size.height - size.height) / 2
        )
        return CGRect(origin: origin, size: size)
    }

    /// 调整尺寸以填充指定矩形（保持宽高比）
    func ls_filling(_ rect: CGRect) -> CGRect {
        let size = self.size.ls_filling(rect.size)
        let origin = CGPoint(
            x: rect.origin.x + (rect.size.width - size.width) / 2,
            y: rect.origin.y + (rect.size.height - size.height) / 2
        )
        return CGRect(origin: origin, size: size)
    }

    /// 检查是否包含另一个矩形
    func ls_contains(_ rect: CGRect) -> Bool {
        return contains(rect) || intersects(rect)
    }

    /// 缩放矩形
    ///
    /// - Parameter scale: 缩放比例
    /// - Returns: 缩放后的矩形
    func ls_scaled(by scale: CGFloat) -> CGRect {
        let newSize = CGSize(
            width: size.width * scale,
            height: size.height * scale
        )
        let newOrigin = CGPoint(
            x: origin.x - (newSize.width - size.width) / 2,
            y: origin.y - (newSize.height - size.height) / 2
        )
        return CGRect(origin: newOrigin, size: newSize)
    }

    /// 内缩矩形
    ///
    /// - Parameter insets: 内缩量
    /// - Returns: 内缩后的矩形
    func ls_inset(by insets: UIEdgeInsets) -> CGRect {
        return inset(by: insets)
    }
}

#endif

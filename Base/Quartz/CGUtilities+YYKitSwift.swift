//
//  CGUtilities+YYKitSwift.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  CG 工具函数，提供 CGContext 创建、坐标转换、像素对齐等功能
//

import UIKit
import QuartzCore

// MARK: - CGContext 创建

/// CG 工具命名空间
public struct CG {

    // MARK: - Bitmap Context 创建

    /// 创建 ARGB Bitmap 上下文
    /// - Parameters:
    ///   - size: 上下文尺寸
    ///   - opaque: 是否不透明
    ///   - scale: 缩放比例
    /// - Returns: CGContext，失败返回 nil
    static func createContextARGB(size: CGSize, opaque: Bool = false, scale: CGFloat = 0) -> CGContext? {
        let width = Int(size.width * scale)
        let height = Int(size.height * scale)

        if width <= 0 || height <= 0 { return nil }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else { return nil }

        context.scaleBy(x: scale, y: scale)
        return context
    }

    /// 创建灰度 Bitmap 上下文
    /// - Parameters:
    ///   - size: 上下文尺寸
    ///   - scale: 缩放比例
    /// - Returns: CGContext，失败返回 nil
    static func createContextGray(size: CGSize, scale: CGFloat = 0) -> CGContext? {
        let width = Int(size.width * scale)
        let height = Int(size.height * scale)

        if width <= 0 || height <= 0 { return nil }

        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGImageAlphaInfo.none.rawValue

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else { return nil }

        context.scaleBy(x: scale, y: scale)
        return context
    }
}

// MARK: - 屏幕信息

/// 屏幕缩放比例
public func LSScreenScale() -> CGFloat {
    return UIScreen.main.scale
}

/// 屏幕尺寸（宽度较小，高度较大）
public func LSScreenSize() -> CGSize {
    let size = UIScreen.main.bounds.size
    return CGSize(width: min(size.width, size.height), height: max(size.width, size.height))
}

/// 屏幕宽度
public func LSScreenWidth() -> CGFloat {
    return LSScreenSize().width
}

/// 屏幕高度
public func LSScreenHeight() -> CGFloat {
    return LSScreenSize().height
}

// MARK: - 角度转换

/// 角度转弧度
public func LSDegreesToRadians(_ degrees: CGFloat) -> CGFloat {
    return degrees * .pi / 180
}

/// 弧度转角度
public func LSRadiansToDegrees(_ radians: CGFloat) -> CGFloat {
    return radians * 180 / .pi
}

// MARK: - CGAffineTransform 扩展

public extension CGAffineTransform {

    /// 获取旋转角度（弧度）
    var ls_rotation: CGFloat {
        return atan2(b, a)
    }

    /// 获取 X 轴缩放
    var ls_scaleX: CGFloat {
        return sqrt(a * a + c * c)
    }

    /// 获取 Y 轴缩放
    var ls_scaleY: CGFloat {
        return sqrt(b * b + d * d)
    }

    /// 获取 X 轴平移
    var ls_translateX: CGFloat {
        return tx
    }

    /// 获取 Y 轴平移
    var ls_translateY: CGFloat {
        return ty
    }

    /// 创建倾斜变换
    static func ls_skew(x: CGFloat, y: CGFloat) -> CGAffineTransform {
        var transform = CGAffineTransform.identity
        transform.c = -x
        transform.b = y
        return transform
    }
}

// MARK: - UIEdgeInsets 扩展

public extension UIEdgeInsets {

    /// 反转 insets
    var ls_invert: UIEdgeInsets {
        return UIEdgeInsets(top: -top, left: -left, bottom: -bottom, right: -right)
    }
}

// MARK: - CALayer gravity 与 UIViewContentMode 转换

/// CALayer gravity 转 UIViewContentMode
public func LSCAGravityToContentMode(_ gravity: CALayerContentsGravity) -> UIView.ContentMode {
    switch gravity {
    case .center: return .center
    case .top: return .top
    case .bottom: return .bottom
    case .left: return .left
    case .right: return .right
    case .topLeft: return .topLeft
    case .topRight: return .topRight
    case .bottomLeft: return .bottomLeft
    case .bottomRight: return .bottomRight
    case .resize: return .scaleToFill
    case .resizeAspect: return .scaleAspectFit
    case .resizeAspectFill: return .scaleAspectFill
    @unknown default:
        return .scaleToFill
    }
}

/// UIViewContentMode 转 CALayer gravity
public func LSContentModeToCAGravity(_ contentMode: UIView.ContentMode) -> CALayerContentsGravity {
    switch contentMode {
    case .scaleToFill: return .resize
    case .scaleAspectFit: return .resizeAspect
    case .scaleAspectFill: return .resizeAspectFill
    case .redraw: return .resize
    case .center: return .center
    case .top: return .top
    case .bottom: return .bottom
    case .left: return .left
    case .right: return .right
    case .topLeft: return .topLeft
    case .topRight: return .topRight
    case .bottomLeft: return .bottomLeft
    case .bottomRight: return .bottomRight
    @unknown default:
        return .resize
    }
}

// MARK: - CGRect 计算工具

/// 根据 ContentMode 计算 fitting rect
public func LSRectFit(_ rect: CGRect, size: CGSize, mode: UIView.ContentMode) -> CGRect {
    var rect = rect
    let aspect = size.width / size.height
    let rectAspect = rect.width / rect.height

    switch mode {
    case .scaleToFill:
        return rect
    case .scaleAspectFit:
        if rectAspect > aspect {
            rect.size.width = rect.height * aspect
        } else {
            rect.size.height = rect.width / aspect
        }
    case .scaleAspectFill:
        if rectAspect > aspect {
            rect.size.height = rect.width / aspect
        } else {
            rect.size.width = rect.height * aspect
        }
    case .center, .top, .bottom, .left, .right, .topLeft, .topRight, .bottomLeft, .bottomRight:
        // 不改变大小，只调整位置
        break
    case .redraw:
        break
    @unknown default:
        break
    }

    return rect
}

/// 获取矩形中心点
public func LSRectGetCenter(_ rect: CGRect) -> CGPoint {
    return CGPoint(x: rect.midX, y: rect.midY)
}

/// 获取矩形面积
public func LSRectGetArea(_ rect: CGRect) -> CGFloat {
    let rect = rect.standardized
    if rect.isNull { return 0 }
    return rect.width * rect.height
}

/// 两点间距离
public func LSPointDistance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
    return hypot(p1.x - p2.x, p1.y - p2.y)
}

/// 点到矩形的最小距离
public func LSPointDistanceToRect(_ point: CGPoint, _ rect: CGRect) -> CGFloat {
    let rect = rect.standardized
    if rect.contains(point) { return 0 }

    var distV: CGFloat = 0
    if rect.minY <= point.y && point.y <= rect.maxY {
        distV = 0
    } else {
        distV = point.y < rect.minY ? rect.minY - point.y : point.y - rect.maxY
    }

    var distH: CGFloat = 0
    if rect.minX <= point.x && point.x <= rect.maxX {
        distH = 0
    } else {
        distH = point.x < rect.minX ? rect.minX - point.x : point.x - rect.maxX
    }

    return max(distV, distH)
}

// MARK: - 像素对齐（CGFloat）

/// 点转像素
public func LSCGFloatToPixel(_ value: CGFloat) -> CGFloat {
    return value * LSScreenScale()
}

/// 像素转点
public func LSCGFloatFromPixel(_ value: CGFloat) -> CGFloat {
    return value / LSScreenScale()
}

/// 像素向下取整
public func LSCGFloatPixelFloor(_ value: CGFloat) -> CGFloat {
    let scale = LSScreenScale()
    return floor(value * scale) / scale
}

/// 像素四舍五入
public func LSCGFloatPixelRound(_ value: CGFloat) -> CGFloat {
    let scale = LSScreenScale()
    return round(value * scale) / scale
}

/// 像素向上取整
public func LSCGFloatPixelCeil(_ value: CGFloat) -> CGFloat {
    let scale = LSScreenScale()
    return ceil(value * scale) / scale
}

/// 像素半点取整（用于奇数像素线宽）
public func LSCGFloatPixelHalf(_ value: CGFloat) -> CGFloat {
    let scale = LSScreenScale()
    return (floor(value * scale) + 0.5) / scale
}

// MARK: - 像素对齐（CGPoint）

public extension CGPoint {

    /// 像素向下取整
    var ls_pixelFloor: CGPoint {
        let scale = LSScreenScale()
        return CGPoint(x: floor(x * scale) / scale, y: floor(y * scale) / scale)
    }

    /// 像素四舍五入
    var ls_pixelRound: CGPoint {
        let scale = LSScreenScale()
        return CGPoint(x: round(x * scale) / scale, y: round(y * scale) / scale)
    }

    /// 像素向上取整
    var ls_pixelCeil: CGPoint {
        let scale = LSScreenScale()
        return CGPoint(x: ceil(x * scale) / scale, y: ceil(y * scale) / scale)
    }

    /// 像素半点取整
    var ls_pixelHalf: CGPoint {
        let scale = LSScreenScale()
        return CGPoint(x: (floor(x * scale) + 0.5) / scale, y: (floor(y * scale) + 0.5) / scale)
    }
}

// MARK: - 像素对齐（CGSize）

public extension CGSize {

    /// 像素向下取整
    var ls_pixelFloor: CGSize {
        let scale = LSScreenScale()
        return CGSize(width: floor(width * scale) / scale, height: floor(height * scale) / scale)
    }

    /// 像素四舍五入
    var ls_pixelRound: CGSize {
        let scale = LSScreenScale()
        return CGSize(width: round(width * scale) / scale, height: round(height * scale) / scale)
    }

    /// 像素向上取整
    var ls_pixelCeil: CGSize {
        let scale = LSScreenScale()
        return CGSize(width: ceil(width * scale) / scale, height: ceil(height * scale) / scale)
    }

    /// 像素半点取整
    var ls_pixelHalf: CGSize {
        let scale = LSScreenScale()
        return CGSize(width: (floor(width * scale) + 0.5) / scale, height: (floor(height * scale) + 0.5) / scale)
    }
}

// MARK: - 像素对齐（CGRect）

public extension CGRect {

    /// 像素向下取整
    var ls_pixelFloor: CGRect {
        let origin = self.origin.ls_pixelCeil
        let corner = CGPoint(x: maxX, y: maxY).ls_pixelFloor
        return CGRect(x: origin.x, y: origin.y, width: max(0, corner.x - origin.x), height: max(0, corner.y - origin.y))
    }

    /// 像素四舍五入
    var ls_pixelRound: CGRect {
        let origin = self.origin.ls_pixelRound
        let corner = CGPoint(x: maxX, y: maxY).ls_pixelRound
        return CGRect(x: origin.x, y: origin.y, width: corner.x - origin.x, height: corner.y - origin.y)
    }

    /// 像素向上取整
    var ls_pixelCeil: CGRect {
        let origin = self.origin.ls_pixelFloor
        let corner = CGPoint(x: maxX, y: maxY).ls_pixelCeil
        return CGRect(x: origin.x, y: origin.y, width: corner.x - origin.x, height: corner.y - origin.y)
    }

    /// 像素半点取整
    var ls_pixelHalf: CGRect {
        let origin = self.origin.ls_pixelHalf
        let corner = CGPoint(x: maxX, y: maxY).ls_pixelHalf
        return CGRect(x: origin.x, y: origin.y, width: corner.x - origin.x, height: corner.y - origin.y)
    }
}

// MARK: - 像素对齐（UIEdgeInsets）

public extension UIEdgeInsets {

    /// 像素向下取整
    var ls_pixelFloor: UIEdgeInsets {
        return UIEdgeInsets(
            top: LSCGFloatPixelFloor(top),
            left: LSCGFloatPixelFloor(left),
            bottom: LSCGFloatPixelFloor(bottom),
            right: LSCGFloatPixelFloor(right)
        )
    }

    /// 像素向上取整
    var ls_pixelCeil: UIEdgeInsets {
        return UIEdgeInsets(
            top: LSCGFloatPixelCeil(top),
            left: LSCGFloatPixelCeil(left),
            bottom: LSCGFloatPixelCeil(bottom),
            right: LSCGFloatPixelCeil(right)
        )
    }
}

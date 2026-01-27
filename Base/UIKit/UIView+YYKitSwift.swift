//
//  UIView+YYKitSwift.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  UIView 扩展，提供快捷属性和截图方法
//

import UIKit

// MARK: - UIView 扩展

public extension UIView {

    // MARK: - 截图

    /// 创建快照图片
    func ls_snapshotImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, isOpaque, 0)
        defer { UIGraphicsEndImageContext() }
        layer.render(in: UIGraphicsGetCurrentContext()!)
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    /// 创建快照图片（支持屏幕更新后）
    func ls_snapshotImage(afterUpdates: Bool) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, isOpaque, 0)
        defer { UIGraphicsEndImageContext() }
        drawHierarchy(in: bounds, afterScreenUpdates: afterUpdates)
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    /// 创建快照 PDF
    func ls_snapshotPDF() -> Data? {
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData as Data, bounds, nil)
        UIGraphicsBeginPDFPage()
        layer.render(in: UIGraphicsGetCurrentContext()!)
        UIGraphicsEndPDFContext()
        return pdfData as Data
    }

    // MARK: - 阴影

    /// 设置阴影
    func ls_setShadow(color: UIColor?, offset: CGSize, radius: CGFloat) {
        layer.shadowColor = color?.cgColor
        layer.shadowOffset = offset
        layer.shadowRadius = radius
        layer.shadowOpacity = 1
    }

    // MARK: - 子视图

    /// 移除所有子视图
    func ls_removeAllSubviews() {
        subviews.forEach { $0.removeFromSuperview() }
    }

    // MARK: - 视图控制器

    /// 获取所属的视图控制器
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

    // MARK: - 可见透明度

    /// 获取屏幕上的可见透明度（考虑父视图）
    var ls_visibleAlpha: CGFloat {
        var alpha: CGFloat = 1
        var view: UIView? = self
        while let currentView = view {
            alpha *= currentView.alpha
            if alpha < 0.01 {
                return 0
            }
            view = currentView.superview
        }
        return alpha
    }

    // MARK: - 坐标转换

    /// 转换点到指定视图（支持 nil）
    func ls_convertPoint(_ point: CGPoint, to view: UIView?) -> CGPoint {
        if let view = view {
            return convert(point, to: view)
        } else {
            return convert(point, to: window)
        }
    }

    /// 从指定视图转换点
    func ls_convertPoint(_ point: CGPoint, from view: UIView?) -> CGPoint {
        if let view = view {
            return convert(point, from: view)
        } else {
            return convert(point, from: window)
        }
    }

    /// 转换矩形到指定视图
    func ls_convertRect(_ rect: CGRect, to view: UIView?) -> CGRect {
        if let view = view {
            return convert(rect, to: view)
        } else {
            return convert(rect, to: window)
        }
    }

    /// 从指定视图转换矩形
    func ls_convertRect(_ rect: CGRect, from view: UIView?) -> CGRect {
        if let view = view {
            return convert(rect, from: view)
        } else {
            return convert(rect, from: window)
        }
    }

    // MARK: - 快捷属性

    /// 左边位置（frame.origin.x）
    var ls_left: CGFloat {
        get { frame.origin.x }
        set { frame.origin.x = newValue }
    }

    /// 顶部位置（frame.origin.y）
    var ls_top: CGFloat {
        get { frame.origin.y }
        set { frame.origin.y = newValue }
    }

    /// 右边位置（frame.origin.x + frame.size.width）
    var ls_right: CGFloat {
        get { frame.origin.x + frame.size.width }
        set { frame.origin.x = newValue - frame.size.width }
    }

    /// 底部位置（frame.origin.y + frame.size.height）
    var ls_bottom: CGFloat {
        get { frame.origin.y + frame.size.height }
        set { frame.origin.y = newValue - frame.size.height }
    }

    /// 宽度（frame.size.width）
    var ls_width: CGFloat {
        get { frame.size.width }
        set { frame.size.width = newValue }
    }

    /// 高度（frame.size.height）
    var ls_height: CGFloat {
        get { frame.size.height }
        set { frame.size.height = newValue }
    }

    /// 中心 X 坐标
    var ls_centerX: CGFloat {
        get { center.x }
        set { center.x = newValue }
    }

    /// 中心 Y 坐标
    var ls_centerY: CGFloat {
        get { center.y }
        set { center.y = newValue }
    }

    /// 原点（frame.origin）
    var ls_origin: CGPoint {
        get { frame.origin }
        set { frame.origin = newValue }
    }

    /// 尺寸（frame.size）
    var ls_size: CGSize {
        get { frame.size }
        set { frame.size = newValue }
    }
}

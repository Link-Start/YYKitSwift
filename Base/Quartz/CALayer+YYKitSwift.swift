//
//  CALayer+YYKitSwift.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  CALayer 扩展，提供快捷属性和方法
//

import UIKit
import QuartzCore

// MARK: - CALayer 扩展

public extension CALayer {

    // MARK: - 截图

    /// 创建快照图片
    func ls_snapshotImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, isOpaque, 0)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        render(in: context)
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    /// 创建快照 PDF
    func ls_snapshotPDF() -> Data? {
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData as Data, bounds, nil)
        UIGraphicsBeginPDFPage()
        render(in: UIGraphicsGetCurrentContext()!)
        UIGraphicsEndPDFContext()
        return pdfData as Data
    }

    // MARK: - 阴影

    /// 设置阴影
    func ls_setShadow(color: UIColor?, offset: CGSize, radius: CGFloat) {
        shadowColor = color?.cgColor
        shadowOffset = offset
        shadowRadius = radius
        shadowOpacity = 1
    }

    // MARK: - 子图层

    /// 移除所有子图层
    func ls_removeAllSublayers() {
        sublayers?.forEach { $0.removeFromSuperlayer() }
    }

    // MARK: - Frame 快捷属性

    /// 左边位置
    var ls_left: CGFloat {
        get { frame.origin.x }
        set { frame.origin.x = newValue }
    }

    /// 顶部位置
    var ls_top: CGFloat {
        get { frame.origin.y }
        set { frame.origin.y = newValue }
    }

    /// 右边位置
    var ls_right: CGFloat {
        get { frame.origin.x + frame.size.width }
        set { frame.origin.x = newValue - frame.size.width }
    }

    /// 底部位置
    var ls_bottom: CGFloat {
        get { frame.origin.y + frame.size.height }
        set { frame.origin.y = newValue - frame.size.height }
    }

    /// 宽度
    var ls_width: CGFloat {
        get { frame.size.width }
        set { frame.size.width = newValue }
    }

    /// 高度
    var ls_height: CGFloat {
        get { frame.size.height }
        set { frame.size.height = newValue }
    }

    /// 中心点
    var ls_center: CGPoint {
        get { CGPoint(x: ls_centerX, y: ls_centerY) }
        set {
            ls_centerX = newValue.x
            ls_centerY = newValue.y
        }
    }

    /// 中心 X 坐标
    var ls_centerX: CGFloat {
        get { position.x }
        set { position.x = newValue }
    }

    /// 中心 Y 坐标
    var ls_centerY: CGFloat {
        get { position.y }
        set { position.y = newValue }
    }

    /// 原点
    var ls_origin: CGPoint {
        get { frame.origin }
        set { frame.origin = newValue }
    }

    /// 尺寸
    var ls_size: CGSize {
        get { frame.size }
        set { frame.size = newValue }
    }

    // MARK: - Transform 快捷属性

    /// 旋转角度
    var ls_transformRotation: CGFloat {
        let _tempVar0
        if let t = CGFloat {
            _tempVar0 = t
        } else {
            _tempVar0 = 0
        }
        get { value(forKeyPath: "transform.rotation.z") as? _tempVar0 }
        set { setValue(newValue, forKeyPath: "transform.rotation.z") }
    }

    /// X 轴旋转
    var ls_transformRotationX: CGFloat {
        let _tempVar0
        if let t = CGFloat {
            _tempVar0 = t
        } else {
            _tempVar0 = 0
        }
        get { value(forKeyPath: "transform.rotation.x") as? _tempVar0 }
        set { setValue(newValue, forKeyPath: "transform.rotation.x") }
    }

    /// Y 轴旋转
    var ls_transformRotationY: CGFloat {
        let _tempVar0
        if let t = CGFloat {
            _tempVar0 = t
        } else {
            _tempVar0 = 0
        }
        get { value(forKeyPath: "transform.rotation.y") as? _tempVar0 }
        set { setValue(newValue, forKeyPath: "transform.rotation.y") }
    }

    /// Z 轴旋转
    var ls_transformRotationZ: CGFloat {
        let _tempVar0
        if let t = CGFloat {
            _tempVar0 = t
        } else {
            _tempVar0 = 0
        }
        get { value(forKeyPath: "transform.rotation.z") as? _tempVar0 }
        set { setValue(newValue, forKeyPath: "transform.rotation.z") }
    }

    /// 缩放
    var ls_transformScale: CGFloat {
        let _tempVar0
        if let t = CGFloat {
            _tempVar0 = t
        } else {
            _tempVar0 = 1
        }
        get { value(forKeyPath: "transform.scale") as? _tempVar0 }
        set { setValue(newValue, forKeyPath: "transform.scale") }
    }

    /// X 轴缩放
    var ls_transformScaleX: CGFloat {
        let _tempVar0
        if let t = CGFloat {
            _tempVar0 = t
        } else {
            _tempVar0 = 1
        }
        get { value(forKeyPath: "transform.scale.x") as? _tempVar0 }
        set { setValue(newValue, forKeyPath: "transform.scale.x") }
    }

    /// Y 轴缩放
    var ls_transformScaleY: CGFloat {
        let _tempVar0
        if let t = CGFloat {
            _tempVar0 = t
        } else {
            _tempVar0 = 1
        }
        get { value(forKeyPath: "transform.scale.y") as? _tempVar0 }
        set { setValue(newValue, forKeyPath: "transform.scale.y") }
    }

    /// Z 轴缩放
    var ls_transformScaleZ: CGFloat {
        let _tempVar0
        if let t = CGFloat {
            _tempVar0 = t
        } else {
            _tempVar0 = 1
        }
        get { value(forKeyPath: "transform.scale.z") as? _tempVar0 }
        set { setValue(newValue, forKeyPath: "transform.scale.z") }
    }

    /// X 轴平移
    var ls_transformTranslationX: CGFloat {
        let _tempVar0
        if let t = CGFloat {
            _tempVar0 = t
        } else {
            _tempVar0 = 0
        }
        get { value(forKeyPath: "transform.translation.x") as? _tempVar0 }
        set { setValue(newValue, forKeyPath: "transform.translation.x") }
    }

    /// Y 轴平移
    var ls_transformTranslationY: CGFloat {
        let _tempVar0
        if let t = CGFloat {
            _tempVar0 = t
        } else {
            _tempVar0 = 0
        }
        get { value(forKeyPath: "transform.translation.y") as? _tempVar0 }
        set { setValue(newValue, forKeyPath: "transform.translation.y") }
    }

    /// Z 轴平移
    var ls_transformTranslationZ: CGFloat {
        let _tempVar0
        if let t = CGFloat {
            _tempVar0 = t
        } else {
            _tempVar0 = 0
        }
        get { value(forKeyPath: "transform.translation.z") as? _tempVar0 }
        set { setValue(newValue, forKeyPath: "transform.translation.z") }
    }

    /// 深度（m34），-1/1000 是一个较好的值
    var ls_transformDepth: CGFloat {
        get {
            var transform = CATransform3DIdentity
            transform.m34 = transform.m34
            return transform.m34
        }
        set {
            var transform = CATransform3DIdentity
            transform.m34 = newValue
            self.transform = transform
        }
    }

    // MARK: - 内容模式

    /// 内容模式（UIViewContentMode 转换为 CALayer contentsGravity）
    var ls_contentMode: UIView.ContentMode {
        get {
            switch contentsGravity {
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
            case .redraw, .scaleToFill: return .scaleToFill
            @unknown default:
                return .scaleToFill
            }
        }
        set {
            switch newValue {
            case .scaleToFill:
                contentsGravity = .resize
            case .scaleAspectFit:
                contentsGravity = .resizeAspect
            case .scaleAspectFill:
                contentsGravity = .resizeAspectFill
            case .redraw:
                contentsGravity = .resize
            case .center:
                contentsGravity = .center
            case .top:
                contentsGravity = .top
            case .bottom:
                contentsGravity = .bottom
            case .left:
                contentsGravity = .left
            case .right:
                contentsGravity = .right
            case .topLeft:
                contentsGravity = .topLeft
            case .topRight:
                contentsGravity = .topRight
            case .bottomLeft:
                contentsGravity = .bottomLeft
            case .bottomRight:
                contentsGravity = .bottomRight
            @unknown default:
                contentsGravity = .resize
            }
        }
    }

    // MARK: - 淡入动画

    /// 添加淡入动画（内容改变时）
    func ls_addFadeAnimation(duration: TimeInterval, curve: UIView.AnimationCurve) {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = duration

        switch curve {
        case .easeInOut:
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        case .easeIn:
            animation.timingFunction = CAMediaTimingFunction(name: .easeIn)
        case .easeOut:
            animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        case .linear:
            animation.timingFunction = CAMediaTimingFunction(name: .linear)
        @unknown default:
            animation.timingFunction = CAMediaTimingFunction(name: .linear)
        }

        add(animation, forKey: "ls_contentsFade")
    }

    /// 移除之前的淡入动画
    func ls_removeFadeAnimation() {
        removeAnimation(forKey: "ls_contentsFade")
    }
}

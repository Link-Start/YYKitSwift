//
//  LSGestureRecognizer.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-26.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  手势识别器辅助类 - 提供便捷的 Block 回调支持
//

#if canImport(UIKit)
import UIKit
import ObjectiveC

// MARK: - 关联对象键

private var kGestureActionBlockKey: UInt8 = 0
private var kGestureRecognizersKey: UInt8 = 0

// MARK: - UIGestureRecognizer 扩展

public extension UIGestureRecognizer {

    /// 手势回调 Block 类型
    typealias LSActionBlock = (UIGestureRecognizer) -> Void

    /// 添加手势回调
    ///
    /// - Parameter block: 手势触发时的回调
    func ls_addAction(_ block: @escaping LSActionBlock) {
        let wrapper = LSActionWrapper(block: block)
        addAction(wrapper, action: #wrapper(LSActionWrapper).ls_handleGesture(_:))
        objc_setAssociatedObject(self, &kGestureActionBlockKey, wrapper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    /// 移除所有手势回调
    func ls_removeAllActions() {
        objc_setAssociatedObject(self, &kGestureActionBlockKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

// MARK: - 手势回调包装器

private class LSActionWrapper: NSObject {

    let block: UIGestureRecognizer.LSActionBlock

    init(block: @escaping UIGestureRecognizer.LSActionBlock) {
        self.block = block
        super.init()
    }

    @objc func ls_handleGesture(_ gesture: UIGestureRecognizer) {
        block(gesture)
    }
}

// MARK: - UIView 扩展

public extension UIView {

    /// 为视图添加点击手势
    ///
    /// - Parameters:
    ///   - tapCount: 点击次数，默认为 1
    ///   - touches: 触摸点数，默认为 1
    ///   - block: 点击回调
    /// - Returns: 创建的手势识别器
    @discardableResult
    func ls_addTapGesture(
        tapCount: Int = 1,
        touches: Int = 1,
        block: @escaping (UITapGestureRecognizer) -> Void
    ) -> UITapGestureRecognizer {
        let gesture = UITapGestureRecognizer()
        gesture.numberOfTapsRequired = tapCount
        gesture.numberOfTouchesRequired = touches
        gesture.ls_addAction { gesture in
            if let tapGesture = gesture as? UITapGestureRecognizer {
                block(tapGesture)
            }
        }
        addGestureRecognizer(gesture)
        return gesture
    }

    /// 为视图添加长按手势
    ///
    /// - Parameters:
    ///   - minimumDuration: 最小长按时长，默认为 0.5 秒
    ///   - tapsRequired: 点击次数，默认为 0
    ///   - block: 长按回调
    /// - Returns: 创建的手势识别器
    @discardableResult
    func ls_addLongPressGesture(
        minimumDuration: TimeInterval = 0.5,
        tapsRequired: Int = 0,
        block: @escaping (UILongPressGestureRecognizer) -> Void
    ) -> UILongPressGestureRecognizer {
        let gesture = UILongPressGestureRecognizer()
        gesture.minimumPressDuration = minimumDuration
        gesture.numberOfTapsRequired = tapsRequired
        gesture.ls_addAction { gesture in
            if let longPressGesture = gesture as? UILongPressGestureRecognizer {
                block(longPressGesture)
            }
        }
        addGestureRecognizer(gesture)
        return gesture
    }

    /// 为视图添加滑动手势
    ///
    /// - Parameters:
    ///   - direction: 滑动方向
    ///   - block: 滑动回调
    /// - Returns: 创建的手势识别器
    @discardableResult
    func ls_addSwipeGesture(
        direction: UISwipeGestureRecognizer.Direction,
        block: @escaping (UISwipeGestureRecognizer) -> Void
    ) -> UISwipeGestureRecognizer {
        let gesture = UISwipeGestureRecognizer()
        gesture.direction = direction
        gesture.ls_addAction { gesture in
            if let swipeGesture = gesture as? UISwipeGestureRecognizer {
                block(swipeGesture)
            }
        }
        addGestureRecognizer(gesture)
        return gesture
    }

    /// 为视图添加拖动手势
    ///
    /// - Parameters:
    ///   - minimumNumberOfTouches: 最少触摸点数，默认为 1
    ///   - maximumNumberOfTouches: 最多触摸点数，默认为 1
    ///   - block: 拖动回调
    /// - Returns: 创建的手势识别器
    @discardableResult
    func ls_addPanGesture(
        minimumNumberOfTouches: Int = 1,
        maximumNumberOfTouches: Int = 1,
        block: @escaping (UIPanGestureRecognizer) -> Void
    ) -> UIPanGestureRecognizer {
        let gesture = UIPanGestureRecognizer()
        gesture.minimumNumberOfTouches = minimumNumberOfTouches
        gesture.maximumNumberOfTouches = maximumNumberOfTouches
        gesture.ls_addAction { gesture in
            if let panGesture = gesture as? UIPanGestureRecognizer {
                block(panGesture)
            }
        }
        addGestureRecognizer(gesture)
        return gesture
    }

    /// 为视图添加捏合手势
    ///
    /// - Parameter block: 捏合回调
    /// - Returns: 创建的手势识别器
    @discardableResult
    func ls_addPinchGesture(
        block: @escaping (UIPinchGestureRecognizer) -> Void
    ) -> UIPinchGestureRecognizer {
        let gesture = UIPinchGestureRecognizer()
        gesture.ls_addAction { gesture in
            if let pinchGesture = gesture as? UIPinchGestureRecognizer {
                block(pinchGesture)
            }
        }
        addGestureRecognizer(gesture)
        return gesture
    }

    /// 为视图添加旋转手势
    ///
    /// - Parameter block: 旋转回调
    /// - Returns: 创建的手势识别器
    @discardableResult
    func ls_addRotationGesture(
        block: @escaping (UIRotationGestureRecognizer) -> Void
    ) -> UIRotationGestureRecognizer {
        let gesture = UIRotationGestureRecognizer()
        gesture.ls_addAction { gesture in
            if let rotationGesture = gesture as? UIRotationGestureRecognizer {
                block(rotationGesture)
            }
        }
        addGestureRecognizer(gesture)
        return gesture
    }

    /// 为视图添加屏幕边缘平移手势
    ///
    /// - Parameters:
    ///   - edges: 边缘
    ///   - block: 回调
    /// - Returns: 创建的手势识别器
    @discardableResult
    func ls_addScreenEdgePanGesture(
        edges: UIRectEdge,
        block: @escaping (UIScreenEdgePanGestureRecognizer) -> Void
    ) -> UIScreenEdgePanGestureRecognizer {
        let gesture = UIScreenEdgePanGestureRecognizer()
        gesture.edges = edges
        gesture.ls_addAction { gesture in
            if let edgeGesture = gesture as? UIScreenEdgePanGestureRecognizer {
                block(edgeGesture)
            }
        }
        addGestureRecognizer(gesture)
        return gesture
    }

    /// 移除所有添加的手势识别器
    func ls_removeAllGestureRecognizers() {
        gestureRecognizers?.forEach { removeGestureRecognizer($0) }
    }
}

// MARK: - 手势状态辅助

extension UIGestureRecognizer.State: CustomStringConvertible {

    public var description: String {
        switch self {
        case .possible:
            return "possible"
        case .began:
            return "began"
        case .changed:
            return "changed"
        case .ended:
            return "ended"
        case .cancelled:
            return "cancelled"
        case .failed:
            return "failed"
        @unknown default:
            return "unknown"
        }
    }
}

// MARK: - 便捷获取手势位置

public extension UIPanGestureRecognizer {

    /// 在指定视图中获取拖动位置
    ///
    /// - Parameter view: 参考视图
    /// - Returns: 拖动位置
    func translation(in view: UIView? = nil) -> CGPoint {
        return translation(in: view)
    }

    /// 在指定视图中获取速度
    ///
    /// - Parameter view: 参考视图
    /// - Returns: 速度
    func velocity(in view: UIView? = nil) -> CGPoint {
        return velocity(in: view)
    }

    /// 重置拖动位置
    ///
    /// - Parameter view: 参考视图
    func setTranslation(_ point: CGPoint, in view: UIView? = nil) {
        setTranslation(point, in: view)
    }
}

public extension UISwipeGestureRecognizer.Direction {

    /// 获取方向的字符串描述
    var ls_description: String {
        switch self {
        case .right:
            return "right"
        case .left:
            return "left"
        case .up:
            return "up"
        case .down:
            return "down"
        @unknown default:
            return "unknown"
        }
    }
}
#endif

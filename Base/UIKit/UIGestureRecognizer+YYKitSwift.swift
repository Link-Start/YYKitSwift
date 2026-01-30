//
//  UIGestureRecognizer+YYKitSwift.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  UIGestureRecognizer 扩展，提供 Block 支持方法
//

import UIKit

// MARK: - UIGestureRecognizer 扩展

@MainActor
public extension UIGestureRecognizer {

    private enum AssociatedKeys {
        static var actionBlockKey: UInt8 = 0
    }
    /// 设置回调 Block
    func ls_action(_ block: @escaping (UIGestureRecognizer) -> Void) {
        let wrapper = GestureActionWrapper(action: block)
        let key = UnsafeRawPointer(Unmanaged.passUnretained(wrapper).toOpaque())

        // 移除旧的 action
        removeTarget(self, action: nil, forControlEvents: .all)

        // 添加新的 action
        addTarget(wrapper, action: #selector(GestureActionWrapper.invoke(_:)))

        // 使用关联对象保持引用
        objc_setAssociatedObject(self, &AssociatedKeys.actionBlockKey, wrapper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

// MARK: - Gesture Action Wrapper

private class GestureActionWrapper: NSObject {
    var action: (UIGestureRecognizer) -> Void

    init(action: @escaping (UIGestureRecognizer) -> Void) {
        self.action = action
    }

    @objc func invoke(_ gesture: UIGestureRecognizer) {
        action(gesture)
    }
}

// MARK: - 便捷初始化方法

public extension UITapGestureRecognizer {
    /// 创建点击手势（使用 Block）
    static func ls_tap(tapCount: Int = 1, fingers: Int = 1, action: @escaping (UITapGestureRecognizer) -> Void) -> UITapGestureRecognizer {
        let gesture = UITapGestureRecognizer()
        gesture.numberOfTapsRequired = tapCount
        gesture.numberOfTouchesRequired = fingers
        gesture.ls_action(action)
        return gesture
    }
}

public extension UIPanGestureRecognizer {
    /// 创建拖拽手势（使用 Block）
    static func ls_pan(minimumTouches: Int = 1, maximumTouches: Int = 0, action: @escaping (UIPanGestureRecognizer) -> Void) -> UIPanGestureRecognizer {
        let gesture = UIPanGestureRecognizer()
        gesture.minimumNumberOfTouches = minimumTouches
        if maximumTouches > 0 {
            gesture.maximumNumberOfTouches = maximumTouches
        }
        gesture.ls_action(action)
        return gesture
    }
}

public extension UISwipeGestureRecognizer {
    /// 创建滑动手势（使用 Block）
    static func ls_swipe(direction: UISwipeGestureRecognizer.Direction = .right, fingers: Int = 1, action: @escaping (UISwipeGestureRecognizer) -> Void) -> UISwipeGestureRecognizer {
        let gesture = UISwipeGestureRecognizer()
        gesture.direction = direction
        gesture.numberOfTouchesRequired = fingers
        gesture.ls_action(action)
        return gesture
    }
}

public extension UIPinchGestureRecognizer {
    /// 创建缩放手势（使用 Block）
    static func ls_pinch(action: @escaping (UIPinchGestureRecognizer) -> Void) -> UIPinchGestureRecognizer {
        let gesture = UIPinchGestureRecognizer()
        gesture.ls_action(action)
        return gesture
    }
}

public extension UIRotationGestureRecognizer {
    /// 创建旋转手势（使用 Block）
    static func ls_rotation(action: @escaping (UIRotationGestureRecognizer) -> Void) -> UIRotationGestureRecognizer {
        let gesture = UIRotationGestureRecognizer()
        gesture.ls_action(action)
        return gesture
    }
}

public extension UILongPressGestureRecognizer {
    /// 创建长按手势（使用 Block）
    static func ls_longPress(minimumDuration: TimeInterval = 0.5, taps: Int = 0, fingers: Int = 1, action: @escaping (UILongPressGestureRecognizer) -> Void) -> UILongPressGestureRecognizer {
        let gesture = UILongPressGestureRecognizer()
        gesture.minimumPressDuration = minimumDuration
        gesture.numberOfTapsRequired = taps
        gesture.numberOfTouchesRequired = fingers
        gesture.ls_action(action)
        return gesture
    }
}

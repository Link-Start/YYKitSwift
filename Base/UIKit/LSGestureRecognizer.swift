//
//  LSGestureRecognizer.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  手势识别器扩展 - 提供便捷的手势添加方法
//

#if canImport(UIKit)
import UIKit

// MARK: - UIView Extension (手势)

public extension UIView {

    /// 添加点击手势
    ///
    /// - Parameters:
    ///   - tapCount: 点击次数
    ///   - action: 动作闭包
    /// - Returns: 手势识别器
    @discardableResult
    func ls_addTapGesture(
        tapCount: Int = 1,
        action: @escaping () -> Void
    ) -> UITapGestureRecognizer {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        gesture.numberOfTapsRequired = tapCount
        gesture.ls_action = action

        addGestureRecognizer(gesture)
        userInteractionEnabled = true

        return gesture
    }

    /// 添加长按手势
    ///
    /// - Parameters:
    ///   - minimumDuration: 最短持续时间
    ///   - action: 动作闭包
    /// - Returns: 手势识别器
    @discardableResult
    func ls_addLongPressGesture(
        minimumDuration: TimeInterval = 0.5,
        action: @escaping () -> Void
    ) -> UILongPressGestureRecognizer {
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        gesture.minimumPressDuration = minimumDuration
        gesture.ls_action = { gesture in
            if gesture.state == .began {
                action()
            }
        }

        addGestureRecognizer(gesture)
        userInteractionEnabled = true

        return gesture
    }

    /// �添加滑动手势
    ///
    /// - Parameters:
    ///   - direction: 滑动方向
    ///   - action: 动作闭包
    /// - Returns: 手势识别器
    @discardableResult
    func ls_addSwipeGesture(
        direction: UISwipeGestureRecognizer.Direction,
        action: @escaping () -> Void
    ) -> UISwipeGestureRecognizer {
        let gesture = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        gesture.direction = direction
        gesture.ls_action = { gesture in
            if gesture.state == .ended {
                action()
            }
        }

        addGestureRecognizer(gesture)
        userInteractionEnabled = true

        return gesture
    }

    /// �添加拖动手势
    ///
    /// - Parameters:
    ///   - action: 动作闭包
    /// - Returns: 手势识别器
    @discardableResult
    func ls_addPanGesture(action: @escaping (UIPanGestureRecognizer) -> Void) -> UIPanGestureRecognizer {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        gesture.ls_panAction = action

        addGestureRecognizer(gesture)
        userInteractionEnabled = true

        return gesture
    }

    /// �添加捏合手势
    ///
    /// - Parameters:
    ///   - action: 动作闭包
    /// - Returns: 手势识别器
    @discardableResult
    func ls_addPinchGesture(action: @escaping (UIPinchGestureRecognizer) -> Void) -> UIPinchGestureRecognizer {
        let gesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        gesture.ls_pinchAction = action

        addGestureRecognizer(gesture)
        userInteractionEnabled = true

        return gesture
    }

    /// �添加旋转手势
    ///
    /// - Parameters:
    ///   - action: 动作闭包
    /// - Returns: 手势识别器
    @discardableResult
    func ls_addRotationGesture(action: @escaping (UIRotationGestureRecognizer) -> Void) -> UIRotationGestureRecognizer {
        let gesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotationGesture(_:)))
        gesture.ls_rotationAction = action

        addGestureRecognizer(gesture)
        userInteractionEnabled = true

        return gesture
    }

    /// 添加屏幕边缘滑动手势
    ///
    /// - Parameters:
    ///   - edges: 边缘
    ///   - action: 动作闭包
    /// - Returns: 手势识别器
    @discardableResult
    func ls_addScreenEdgePanGesture(
        edges: UIRectEdge,
        action: @escaping () -> Void
    ) -> UIScreenEdgePanGestureRecognizer {
        let gesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        gesture.edges = edges
        gesture.ls_action = { gesture in
            if gesture.state == .ended {
                action()
            }
        }

        addGestureRecognizer(gesture)
        userInteractionEnabled = true

        return gesture
    }

    // MARK: - 手势处理

    @objc private func handleGesture(_ gesture: UIGestureRecognizer) {
        gesture.ls_action?()
    }

    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        gesture.ls_panAction?(gesture)
    }

    @objc private func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
        gesture.ls_pinchAction?(gesture)
    }

    @objc private func handleRotationGesture(_ gesture: UIRotationGestureRecognizer) {
        gesture.ls_rotationAction?(gesture)
    }

    /// 移除所有手势
    func ls_removeAllGestures() {
        gestureRecognizers?.forEach { removeGestureRecognizer($0) }
    }

    /// 移除指定类型的手势
    ///
    /// - Parameter type: 手势类型
    func ls_removeGestures<T: UIGestureRecognizer>(of type: T.Type) {
        gestureRecognizers?.forEach { gesture in
            if gesture is T {
                removeGestureRecognizer(gesture)
            }
        }
    }
}

// MARK: - UIGestureRecognizer Extension (关联动作)

private extension UIGestureRecognizer {

    struct AssociatedKeys {
        static var actionKey = "actionKey"
        static var panActionKey = "panActionKey"
        static var pinchActionKey = "pinchActionKey"
        static var rotationActionKey = "rotationActionKey"
    }

    var ls_action: (() -> Void)? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.actionKey) as? () -> Void
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.actionKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }

    var ls_panAction: ((UIPanGestureRecognizer) -> Void)? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.panActionKey) as? (UIPanGestureRecognizer) -> Void
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.panActionKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }

    var ls_pinchAction: ((UIPinchGestureRecognizer) -> Void)? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.pinchActionKey) as? (UIPinchGestureRecognizer) -> Void
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.pinchActionKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }

    var ls_rotationAction: ((UIRotationGestureRecognizer) -> Void)? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.rotationActionKey) as? (UIRotationGestureRecognizer) -> Void
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.rotationActionKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
}

// MARK: - 组合手势

/// 组合手势管理器
public class LSCompositeGestureManager: NSObject {

    // MARK: - 类型定义

    /// 方向枚举
    public enum Direction {
        case up
        case down
        case left
        case right
    }

    /// 方向回调
    public typealias DirectionHandler = (Direction) -> Void

    // MARK: - 属性

    /// 目标视图
    private weak var targetView: UIView?

    /// 上滑手势
    private var upSwipe: UISwipeGestureRecognizer?

    /// 下滑手势
    private var downSwipe: UISwipeGestureRecognizer?

    /// 左滑手势
    private var leftSwipe: UISwipeGestureRecognizer?

    /// 右滑手势
    private var rightSwipe: UISwipeGestureRecognizer?

    /// 方向回调
    public var onSwipe: DirectionHandler?

    /// 点击手势
    private var tapGesture: UITapGestureRecognizer?

    /// 点击回调
    public var onTap: (() -> Void)?

    /// 长按手势
    private var longPressGesture: UILongPressGestureRecognizer?

    /// 长按回调
    public var onLongPress: (() -> Void)?

    // MARK: - 初始化

    /// 创建组合手势管理器
    ///
    /// - Parameter view: 目标视图
    public init(view: UIView) {
        self.targetView = view
        super.init()
        setupGestures()
    }

    // MARK: - 设置

    private func setupGestures() {
        guard let view = targetView else { return }

        // 上滑
        upSwipe = view.ls_addSwipeGesture(direction: .up) { [weak self] in
            self?.onSwipe?(.up)
        }

        // 下滑
        downSwipe = view.ls_addSwipeGesture(direction: .down) { [weak self] in
            self?.onSwipe?(.down)
        }

        // 左滑
        leftSwipe = view.ls_addSwipeGesture(direction: .left) { [weak self] in
            self?.onSwipe?(.left)
        }

        // 右滑
        rightSwipe = view.ls_addSwipeGesture(direction: .right) { [weak self] in
            self?.onSwipe?(.right)
        }

        // 点击
        tapGesture = view.ls_addTapGesture { [weak self] in
            self?.onTap?()
        }

        // 长按
        longPressGesture = view.ls_addLongPressGesture { [weak self] in
            self?.onLongPress?()
        }
    }

    // MARK: - 启用/禁用

    /// 启用所有方向滑动手势
    public func enableAllSwipeGestures() {
        upSwipe?.isEnabled = true
        downSwipe?.isEnabled = true
        leftSwipe?.isEnabled = true
        rightSwipe?.isEnabled = true
    }

    /// 禁用所有方向滑动手势
    public func disableAllSwipeGestures() {
        upSwipe?.isEnabled = false
        downSwipe?.isEnabled = false
        leftSwipe?.isEnabled = false
        rightSwipe?.isEnabled = false
    }

    /// 启用指定方向滑动手势
    ///
    /// - Parameter directions: 方向数组
    public func enableSwipeGestures(for directions: [Direction]) {
        for direction in directions {
            switch direction {
            case .up:
                upSwipe?.isEnabled = true
            case .down:
                downSwipe?.isEnabled = true
            case .left:
                leftSwipe?.isEnabled = true
            case .right:
                rightSwipe?.isEnabled = true
            }
        }
    }

    /// 禁用指定方向滑动手势
    ///
    /// - Parameter directions: 方向数组
    public func disableSwipeGestures(for directions: [Direction]) {
        for direction in directions {
            switch direction {
            case .up:
                upSwipe?.isEnabled = false
            case .down:
                downSwipe?.isEnabled = false
            case .left:
                leftSwipe?.isEnabled = false
            case .right:
                rightSwipe?.isEnabled = false
            }
        }
    }

    /// 启用点击手势
    public func enableTapGesture() {
        tapGesture?.isEnabled = true
    }

    /// 禁用点击手势
    public func disableTapGesture() {
        tapGesture?.isEnabled = false
    }

    /// 启用长按手势
    public func enableLongPressGesture() {
        longPressGesture?.isEnabled = true
    }

    /// 禁用长按手势
    public func disableLongPressGesture() {
        longPressGesture?.isEnabled = false
    }

    /// 移除所有手势
    public func removeAllGestures() {
        targetView?.ls_removeAllGestures()
    }
}

// MARK: - 便捷方法

public extension UIView {

    /// 添加组合手势
    ///
    /// - Returns: 组合手势管理器
    @discardableResult
    func ls_addCompositeGestures() -> LSCompositeGestureManager {
        return LSCompositeGestureManager(view: self)
    }
}

// MARK: - 手势扩展

public extension UIGestureRecognizer {

    /// 是否正在识别
    var ls_isRecognizing: Bool {
        return state == .began || state == .changed
    }

    /// 是否已完成
    var ls_isEnded: Bool {
        return state == .ended
    }

    /// 是否已取消
    var ls_isCancelled: Bool {
        return state == .cancelled
    }

    /// 是否失败
    var ls_isFailed: Bool {
        return state == .failed
    }

    /// 是否可能
    var ls_isPossible: Bool {
        return state == .possible
    }
}

// MARK: - 滑动手势扩展

public extension UISwipeGestureRecognizer {

    /// 是否为水平滑动
    var ls_isHorizontal: Bool {
        return direction.contains(.left) || direction.contains(.right)
    }

    /// 是否为垂直滑动
    var ls_isVertical: Bool {
        return direction.contains(.up) || direction.contains(.down)
    }
}

// MARK: - 拖动手势扩展

public extension UIPanGestureRecognizer {

    /// 拖动位移
    func ls_translation(in view: UIView?) -> CGPoint {
        return translation(in: view)
    }

    /// 拖动速度
    func ls_velocity(in view: UIView?) -> CGPoint {
        return velocity(in: view)
    }

    /// 是否正在向右拖动
    func ls_isDraggingRight(in view: UIView? = nil) -> Bool {
        return ls_velocity(in: view).x > 0
    }

    /// 是否正在向左拖动
    func ls_isDraggingLeft(in view: UIView? = nil) -> Bool {
        return ls_velocity(in: view).x < 0
    }

    /// 是否正在向上拖动
    func ls_isDraggingUp(in view: UIView? = nil) -> Bool {
        return ls_velocity(in: view).y < 0
    }

    /// 是否正在向下拖动
    func ls_isDraggingDown(in view: UIView? = nil) -> Bool {
        return ls_velocity(in: view).y > 0
    }
}

// MARK: - 捏合手势扩展

public extension UIPinchGestureRecognizer {

    /// 捏合比例
    var ls_scale: CGFloat {
        return scale
    }

    /// 是否正在放大
    var ls_isZoomingIn: Bool {
        return scale > 1.0
    }

    /// 是否正在缩小
    var ls_isZoomingOut: Bool {
        return scale < 1.0
    }

    /// 重置缩放
    func ls_resetScale() {
        scale = 1.0
    }
}

// MARK: - 旋转手势扩展

public extension UIRotationGestureRecognizer {

    /// 旋转角度（弧度）
    var ls_rotation: CGFloat {
        return rotation
    }

    /// 旋转角度（度）
    var ls_rotationInDegrees: CGFloat {
        return rotation * 180 / .pi
    }

    /// 重置旋转
    func ls_resetRotation() {
        rotation = 0
    }
}

#endif

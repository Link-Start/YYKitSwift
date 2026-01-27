//
//  LSAnimationHelper.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  动画辅助工具 - 便捷的动画方法
//

#if canImport(UIKit)
import UIKit

// MARK: - LSAnimationHelper

/// 动画辅助工具
public class LSAnimationHelper {

    // MARK: - 类型定义

    /// 动画完成回调
    public typealias CompletionHandler = (Bool) -> Void

    // MARK: - 基础动画

    /// 淡入动画
    @discardableResult
    public static func fadeIn(
        _ view: UIView,
        duration: TimeInterval = 0.3,
        delay: TimeInterval = 0,
        completion: CompletionHandler? = nil
    ) -> UIView {
        view.alpha = 0
        UIView.animate(
            withDuration: duration,
            delay: delay,
            options: .curveEaseInOut,
            animations: {
                view.alpha = 1
            },
            completion: completion
        )
        return view
    }

    /// 淡出动画
    @discardableResult
    public static func fadeOut(
        _ view: UIView,
        duration: TimeInterval = 0.3,
        delay: TimeInterval = 0,
        completion: CompletionHandler? = nil
    ) -> UIView {
        UIView.animate(
            withDuration: duration,
            delay: delay,
            options: .curveEaseInOut,
            animations: {
                view.alpha = 0
            },
            completion: completion
        )
        return view
    }

    /// 缩放动画
    @discardableResult
    public static func scale(
        _ view: UIView,
        from: CGFloat,
        to: CGFloat,
        duration: TimeInterval = 0.3,
        delay: TimeInterval = 0,
        springDamping: CGFloat = 0.6,
        springVelocity: CGFloat = 0.5,
        completion: CompletionHandler? = nil
    ) -> UIView {
        view.transform = CGAffineTransform(scaleX: from, y: from)

        UIView.animate(
            withDuration: duration,
            delay: delay,
            usingSpringWithDamping: springDamping,
            initialSpringVelocity: springVelocity,
            options: .curveEaseInOut,
            animations: {
                view.transform = CGAffineTransform(scaleX: to, y: to)
            },
            completion: completion
        )
        return view
    }

    /// 旋转动画
    @discardableResult
    public static func rotate(
        _ view: UIView,
        by angle: CGFloat,
        duration: TimeInterval = 0.3,
        delay: TimeInterval = 0,
        completion: CompletionHandler? = nil
    ) -> UIView {
        UIView.animate(
            withDuration: duration,
            delay: delay,
            options: .curveEaseInOut,
            animations: {
                view.transform = CGAffineTransform(rotationAngle: angle)
            },
            completion: completion
        )
        return view
    }

    /// 移动动画
    @discardableResult
    public static func move(
        _ view: UIView,
        to point: CGPoint,
        duration: TimeInterval = 0.3,
        delay: TimeInterval = 0,
        springDamping: CGFloat = 1.0,
        springVelocity: CGFloat = 0,
        completion: CompletionHandler? = nil
    ) -> UIView {
        UIView.animate(
            withDuration: duration,
            delay: delay,
            usingSpringWithDamping: springDamping,
            initialSpringVelocity: springVelocity,
            options: .curveEaseInOut,
            animations: {
                view.center = point
            },
            completion: completion
        )
        return view
    }

    /// 弹簧动画
    @discardableResult
    public static func spring(
        _ view: UIView,
        toCenter center: CGPoint,
        damping: CGFloat = 0.6,
        velocity: CGFloat = 0.5,
        duration: TimeInterval = 0.6,
        completion: CompletionHandler? = nil
    ) -> UIView {
        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: damping,
            initialSpringVelocity: velocity,
            options: .curveEaseInOut,
            animations: {
                view.center = center
            },
            completion: completion
        )
        return view
    }

    // MARK: - 组合动画

    /// 淡入并缩放
    @discardableResult
    public static func fadeInAndScale(
        _ view: UIView,
        duration: TimeInterval = 0.3,
        delay: TimeInterval = 0,
        completion: CompletionHandler? = nil
    ) -> UIView {
        view.alpha = 0
        view.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)

        UIView.animate(
            withDuration: duration,
            delay: delay,
            usingSpringWithDamping: 0.6,
            initialSpringVelocity: 0.5,
            options: .curveEaseInOut,
            animations: {
                view.alpha = 1
                view.transform = .identity
            },
            completion: completion
        )
        return view
    }

    /// 滑入动画
    @discardableResult
    public static func slideIn(
        _ view: UIView,
        from direction: SlideDirection = .bottom,
        duration: TimeInterval = 0.3,
        delay: TimeInterval = 0,
        completion: CompletionHandler? = nil
    ) -> UIView {
        let offset: CGFloat

        switch direction {
        case .top:
            view.frame.origin.y = -view.frame.height
            offset = view.frame.origin.y
        case .bottom:
            view.frame.origin.y = UIScreen.main.bounds.height
            offset = view.frame.origin.y - (UIScreen.main.bounds.height - view.frame.height)
        case .left:
            view.frame.origin.x = -view.frame.width
            offset = view.frame.origin.x
        case .right:
            view.frame.origin.x = UIScreen.main.bounds.width
            offset = view.frame.origin.x - (UIScreen.main.bounds.width - view.frame.width)
        }

        UIView.animate(
            withDuration: duration,
            delay: delay,
            options: .curveEaseOut,
            animations: {
                view.frame.origin.y = offset
            },
            completion: completion
        )
        return view
    }

    /// 滑出动画
    @discardableResult
    public static func slideOut(
        _ view: UIView,
        to direction: SlideDirection,
        duration: TimeInterval = 0.3,
        delay: TimeInterval = 0,
        removeOnCompletion: Bool = false,
        completion: CompletionHandler? = nil
    ) -> UIView {
        var targetFrame = view.frame

        switch direction {
        case .top:
            targetFrame.origin.y = -view.frame.height
        case .bottom:
            targetFrame.origin.y = UIScreen.main.bounds.height
        case .left:
            targetFrame.origin.x = -view.frame.width
        case .right:
            targetFrame.origin.x = UIScreen.main.bounds.width
        }

        UIView.animate(
            withDuration: duration,
            delay: delay,
            options: .curveEaseIn,
            animations: {
                view.frame = targetFrame
            },
            completion: { finished in
                if removeOnCompletion {
                    view.removeFromSuperview()
                }
                completion?(finished)
            }
        )
        return view
    }

    /// 滑动方向
    public enum SlideDirection {
        case top
        case bottom
        case left
        case right
    }

    // MARK: - 特殊动画

    /// 抖动动画
    @discardableResult
    public static func shake(
        _ view: UIView,
        duration: TimeInterval = 0.5,
        delay: TimeInterval = 0,
        completion: CompletionHandler? = nil
    ) -> UIView {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = duration
        animation.values = [-10, 10, -8, 8, -5, 5, 0]

        view.layer.add(animation, forKey: "shake")

        DispatchQueue.main.asyncAfter(deadline: .now() + duration + delay) {
            completion?(true)
        }

        return view
    }

    /// 脉冲动画
    @discardableResult
    public static func pulse(
        _ view: UIView,
        duration: TimeInterval = 0.3,
        delay: TimeInterval = 0,
        completion: CompletionHandler? = nil
    ) -> UIView {
        UIView.animate(
            withDuration: duration,
            delay: delay,
            animations: {
                view.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            },
            completion: { _ in
                UIView.animate(withDuration: duration) {
                    view.transform = .identity
                }
            }
        )

        if let completion = completion {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration * 2 + delay) {
                completion(true)
            }
        }

        return view
    }

    /// 呼吸动画（重复）
    @discardableResult
    public static func breathe(
        _ view: UIView,
        duration: TimeInterval = 2.0,
        delay: TimeInterval = 0
    ) -> UIView {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1
        animation.toValue = 0.5
        animation.duration = duration
        animation.autoreverses = true
        animation.repeatCount = .infinity
        view.layer.add(animation, forKey: "breathe")

        return view
    }

    /// 旋转动画（重复）
    @discardableResult
    public static func rotate(
        _ view: UIView,
        duration: TimeInterval = 1.0,
        delay: TimeInterval = 0,
        clockwise: Bool = true
    ) -> UIView {
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = 0
        animation.toValue = clockwise ? 2 * .pi : -2 * .pi
        animation.duration = duration
        animation.repeatCount = .infinity
        view.layer.add(animation, forKey: "rotate")

        return view
    }

    /// 弹跳动画
    @discardableResult
    public static func bounce(
        _ view: UIView,
        duration: TimeInterval = 0.5,
        delay: TimeInterval = 0,
        completion: CompletionHandler? = nil
    ) -> UIView {
        let animation = CAKeyframeAnimation(keyPath: "transform.scale")
        animation.values = [1, 1.2, 0.9, 1.1, 0.95, 1.0]
        animation.keyTimes = [0, 0.2, 0.4, 0.6, 0.8, 1]
        animation.duration = duration
        view.layer.add(animation, forKey: "bounce")

        DispatchQueue.main.asyncAfter(deadline: .now() + duration + delay) {
            completion?(true)
        }

        return view
    }

    /// 翻转动画
    @discardableResult
    public static func flip(
        _ view: UIView,
        duration: TimeInterval = 0.5,
        delay: TimeInterval = 0,
        direction: FlipDirection = .horizontal,
        completion: CompletionHandler? = nil
    ) -> UIView {
        let option: UIView.AnimationOptions = direction == .horizontal ? .transitionFlipFromLeft : .transitionFlipFromTop

        UIView.transition(
            with: view,
            duration: duration,
            options: option,
            animations: nil,
            completion: completion
        )

        return view
    }

    /// 翻转方向
    public enum FlipDirection {
        case horizontal
        case vertical
    }

    /// 交叉溶解动画
    @discardableResult
    public static func crossDissolve(
        _ view: UIView,
        duration: TimeInterval = 0.3,
        delay: TimeInterval = 0,
        completion: CompletionHandler? = nil
    ) -> UIView {
        UIView.transition(
            with: view,
            duration: duration,
            options: .transitionCrossDissolve,
            animations: nil,
            completion: completion
        )

        return view
    }

    // MARK: - CAAnimation 便捷方法

    /// 添加淡入动画
    @discardableResult
    public static func addFadeInAnimation(
        to layer: CALayer,
        duration: TimeInterval = 0.3
    ) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = duration
        layer.add(animation, forKey: "fadeIn")
        return animation
    }

    /// 添加淡出动画
    @discardableResult
    public static func addFadeOutAnimation(
        to layer: CALayer,
        duration: TimeInterval = 0.3,
        removeOnCompletion: Bool = true
    ) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1
        animation.toValue = 0
        animation.duration = duration
        animation.isRemovedOnCompletion = removeOnCompletion
        layer.add(animation, forKey: "fadeOut")
        return animation
    }

    /// 添加移动动画
    @discardableResult
    public static func addMoveAnimation(
        to layer: CALayer,
        to point: CGPoint,
        duration: TimeInterval = 0.3
    ) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "position")
        animation.toValue = NSValue(cgPoint: point)
        animation.duration = duration
        layer.add(animation, forKey: "move")
        return animation
    }

    /// 添加缩放动画
    @discardableResult
    public static func addScaleAnimation(
        to layer: CALayer,
        to scale: CGFloat,
        duration: TimeInterval = 0.3
    ) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.toValue = scale
        animation.duration = duration
        layer.add(animation, forKey: "scale")
        return animation
    }

    /// 添加旋转动画
    @discardableResult
    public static func addRotationAnimation(
        to layer: CALayer,
        to angle: CGFloat,
        duration: TimeInterval = 0.3
    ) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.toValue = angle
        animation.duration = duration
        layer.add(animation, forKey: "rotate")
        return animation
    }

    /// 添加路径动画
    @discardableResult
    public static func addPathAnimation(
        to layer: CALayer,
        path: UIBezierPath,
        duration: TimeInterval = 0.3
    ) -> CAKeyframeAnimation {
        let animation = CAKeyframeAnimation(keyPath: "position")
        animation.path = path.cgPath
        animation.duration = duration
        layer.add(animation, forKey: "path")
        return animation
    }

    /// 添加关键帧动画
    @discardableResult
    public static func addKeyframeAnimation(
        to layer: CALayer,
        keyPath: String,
        values: [Any],
        keyTimes: [NSNumber]?,
        duration: TimeInterval = 0.3
    ) -> CAKeyframeAnimation {
        let animation = CAKeyframeAnimation(keyPath: keyPath)
        animation.values = values
        if let keyTimes = keyTimes {
            animation.keyTimes = keyTimes
        }
        animation.duration = duration
        layer.add(animation, forKey: keyPath)
        return animation
    }

    /// 添加弹簧动画
    @discardableResult
    public static func addSpringAnimation(
        to layer: CALayer,
        keyPath: String,
        toValue: Any,
        damping: CGFloat = 0.6,
        velocity: CGFloat = 0.5,
        duration: TimeInterval = 0.6
    ) -> CASpringAnimation {
        let animation = CASpringAnimation(keyPath: keyPath)
        animation.toValue = toValue
        animation.damping = damping
        animation.initialVelocity = velocity
        animation.duration = duration
        layer.add(animation, forKey: keyPath)
        return animation
    }

    /// 添加组动画
    @discardableResult
    public static func addGroupAnimation(
        to layer: CALayer,
        animations: [CAAnimation],
        duration: TimeInterval = 0.3
    ) -> CAAnimationGroup {
        let group = CAAnimationGroup()
        group.animations = animations
        group.duration = duration
        layer.add(group, forKey: "group")
        return group
    }

    // MARK: - 动画暂停/恢复/移除

    /// 暂停动画
    public static func pauseAnimation(_ view: UIView, forKey key: String) {
        view.layer.pauseAnimation(forKey: key)
    }

    /// 恢复动画
    public static func resumeAnimation(_ view: UIView, forKey key: String) {
        view.layer.resumeAnimation(forKey: key)
    }

    /// 移除动画
    public static func removeAnimation(_ view: UIView, forKey key: String) {
        view.layer.removeAnimation(forKey: key)
    }

    /// 移除所有动画
    public static func removeAllAnimations(_ view: UIView) {
        view.layer.removeAllAnimations()
    }

    // MARK: - 动画序列

    /// 执行动画序列
    public static func animateSequence(
        _ animations: [() -> Void],
        duration: TimeInterval = 0.3,
        completion: (() -> Void)? = nil
    ) {
        executeAnimation(at: 0, animations: animations, duration: duration, completion: completion)
    }

    private static func executeAnimation(
        at index: Int,
        animations: [() -> Void],
        duration: TimeInterval,
        completion: (() -> Void)?
    ) {
        guard index < animations.count else {
            completion?()
            return
        }

        UIView.animate(
            withDuration: duration,
            animations: animations[index],
            completion: { _ in
                executeAnimation(at: index + 1, animations: animations, duration: duration, completion: completion)
            }
        )
    }

    /// 延迟执行
    public static func delay(_ delay: TimeInterval, closure: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            closure()
        }
    }
}

// MARK: - UIView Extension (Animation)

public extension UIView {

    /// 淡入
    func ls_fadeIn(duration: TimeInterval = 0.3, completion: LSAnimationHelper.CompletionHandler? = nil) {
        LSAnimationHelper.fadeIn(self, duration: duration, completion: completion)
    }

    /// 淡出
    func ls_fadeOut(duration: TimeInterval = 0.3, completion: LSAnimationHelper.CompletionHandler? = nil) {
        LSAnimationHelper.fadeOut(self, duration: duration, completion: completion)
    }

    /// 缩放
    func ls_scale(from: CGFloat, to: CGFloat, duration: TimeInterval = 0.3, completion: LSAnimationHelper.CompletionHandler? = nil) {
        LSAnimationHelper.scale(self, from: from, to: to, duration: duration, completion: completion)
    }

    /// 旋转
    func ls_rotate(by angle: CGFloat, duration: TimeInterval = 0.3, completion: LSAnimationHelper.CompletionHandler? = nil) {
        LSAnimationHelper.rotate(self, by: angle, duration: duration, completion: completion)
    }

    /// 移动
    func ls_move(to point: CGPoint, duration: TimeInterval = 0.3, completion: LSAnimationHelper.CompletionHandler? = nil) {
        LSAnimationHelper.move(self, to: point, duration: duration, completion: completion)
    }

    /// 抖动
    func ls_shake(duration: TimeInterval = 0.5, completion: LSAnimationHelper.CompletionHandler? = nil) {
        LSAnimationHelper.shake(self, duration: duration, completion: completion)
    }

    /// 脉冲
    func ls_pulse(duration: TimeInterval = 0.3, completion: LSAnimationHelper.CompletionHandler? = nil) {
        LSAnimationHelper.pulse(self, duration: duration, completion: completion)
    }

    /// 弹跳
    func ls_bounce(duration: TimeInterval = 0.5, completion: LSAnimationHelper.CompletionHandler? = nil) {
        LSAnimationHelper.bounce(self, duration: duration, completion: completion)
    }

    /// 滑入
    func ls_slideIn(from direction: LSAnimationHelper.SlideDirection = .bottom, duration: TimeInterval = 0.3, completion: LSAnimationHelper.CompletionHandler? = nil) {
        LSAnimationHelper.slideIn(self, from: direction, duration: duration, completion: completion)
    }

    /// 滑出
    func ls_slideOut(to direction: LSAnimationHelper.SlideDirection, duration: TimeInterval = 0.3, removeOnCompletion: Bool = false, completion: LSAnimationHelper.CompletionHandler? = nil) {
        LSAnimationHelper.slideOut(self, to: direction, duration: duration, removeOnCompletion: removeOnCompletion, completion: completion)
    }

    /// 移除动画
    func ls_removeAllAnimations() {
        LSAnimationHelper.removeAllAnimations(self)
    }
}

// MARK: - CALayer Extension (Animation)

public extension CALayer {

    /// 添加淡入动画
    func ls_addFadeInAnimation(duration: TimeInterval = 0.3) -> CABasicAnimation {
        return LSAnimationHelper.addFadeInAnimation(to: self, duration: duration)
    }

    /// 添加淡出动画
    func ls_addFadeOutAnimation(duration: TimeInterval = 0.3, removeOnCompletion: Bool = true) -> CABasicAnimation {
        return LSAnimationHelper.addFadeOutAnimation(to: self, duration: duration, removeOnCompletion: removeOnCompletion)
    }

    /// 添加移动动画
    func ls_addMoveAnimation(to point: CGPoint, duration: TimeInterval = 0.3) -> CABasicAnimation {
        return LSAnimationHelper.addMoveAnimation(to: self, to: point, duration: duration)
    }

    /// 添加缩放动画
    func ls_addScaleAnimation(to scale: CGFloat, duration: TimeInterval = 0.3) -> CABasicAnimation {
        return LSAnimationHelper.addScaleAnimation(to: self, to: scale, duration: duration)
    }

    /// 添加旋转动画
    func ls_addRotationAnimation(to angle: CGFloat, duration: TimeInterval = 0.3) -> CABasicAnimation {
        return LSAnimationHelper.addRotationAnimation(to: self, to: angle, duration: duration)
    }

    /// 添加弹簧动画
    func ls_addSpringAnimation(
        keyPath: String,
        toValue: Any,
        damping: CGFloat = 0.6,
        velocity: CGFloat = 0.5,
        duration: TimeInterval = 0.6
    ) -> CASpringAnimation {
        return LSAnimationHelper.addSpringAnimation(
            to: self,
            keyPath: keyPath,
            toValue: toValue,
            damping: damping,
            velocity: velocity,
            duration: duration
        )
    }

    /// 暂停动画
    func ls_pauseAnimation(forKey key: String) {
        pauseAnimation(forKey: key)
    }

    /// 恢复动画
    func ls_resumeAnimation(forKey key: String) {
        resumeAnimation(forKey: key)
    }

    /// 移除动画
    func ls_removeAnimation(forKey key: String) {
        removeAnimation(forKey: key)
    }

    /// 移除所有动画
    func ls_removeAllAnimations() {
        removeAllAnimations()
    }
}

// MARK: - CABasicAnimation Extension

public extension CABasicAnimation {

    /// 创建淡入动画
    static func ls_fadeInAnimation(duration: TimeInterval = 0.3) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = duration
        return animation
    }

    /// 创建淡出动画
    static func ls_fadeOutAnimation(duration: TimeInterval = 0.3) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1
        animation.toValue = 0
        animation.duration = duration
        return animation
    }

    /// 创建移动动画
    static func ls_moveAnimation(to point: CGPoint, duration: TimeInterval = 0.3) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "position")
        animation.toValue = NSValue(cgPoint: point)
        animation.duration = duration
        return animation
    }

    /// 创建缩放动画
    static func ls_scaleAnimation(to scale: CGFloat, duration: TimeInterval = 0.3) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.toValue = scale
        animation.duration = duration
        return animation
    }

    /// 创建旋转动画
    static func ls_rotationAnimation(to angle: CGFloat, duration: TimeInterval = 0.3) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.toValue = angle
        animation.duration = duration
        return animation
    }
}

// MARK: - CASpringAnimation Extension

public extension CASpringAnimation {

    /// 创建弹簧动画
    static func ls_springAnimation(
        keyPath: String,
        toValue: Any,
        damping: CGFloat = 0.6,
        velocity: CGFloat = 0.5,
        duration: TimeInterval = 0.6
    ) -> CASpringAnimation {
        let animation = CASpringAnimation(keyPath: keyPath)
        animation.toValue = toValue
        animation.damping = damping
        animation.initialVelocity = velocity
        animation.duration = duration
        return animation
    }
}

#endif

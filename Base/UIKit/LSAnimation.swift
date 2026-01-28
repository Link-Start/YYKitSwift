//
//  LSAnimation.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  动画工具 - 简化 UIView 动画操作
//

#if canImport(UIKit)
import UIKit
import Foundation

// MARK: - LSAnimation

/// 动画工具类
public enum LSAnimation {

    // MARK: - 基础动画

    /// 执行动画
    ///
    /// - Parameters:
    ///   - duration: 动画时长
    ///   - delay: 延迟时间
    ///   - options: 动画选项
    ///   - animations: 动画闭包
    ///   - completion: 完成回调
    @discardableResult
    public static func animate(
        duration: TimeInterval,
        delay: TimeInterval = 0,
        options: UIView.AnimationOptions = .curveEaseInOut,
        animations: @escaping () -> Void,
        completion: ((Bool) -> Void)? = nil
    ) -> UIViewPropertyAnimator {
        let animator = UIViewPropertyAnimator(
            duration: duration,
            curve: .easeInOut
        ) {
            animations()
        }

        if delay > 0 {
            animator.startAnimation(afterDelay: delay)
        } else {
            animator.startAnimation()
        }

        animator.addCompletion { position in
            completion?(position == .end)
        }

        return animator
    }

    /// 弹簧动画
    ///
    /// - Parameters:
    ///   - duration: 动画时长
    ///   - damping: 阻尼系数（0-1）
    ///   - velocity: 初始速度
    ///   - delay: 延迟时间
    ///   - options: 动画选项
    ///   - animations: 动画闭包
    ///   - completion: 完成回调
    @discardableResult
    public static func spring(
        duration: TimeInterval = 0.5,
        damping: CGFloat = 0.7,
        velocity: CGFloat = 0.5,
        delay: TimeInterval = 0,
        options: UIView.AnimationOptions = .curveEaseInOut,
        animations: @escaping () -> Void,
        completion: ((Bool) -> Void)? = nil
    ) -> UIViewPropertyAnimator {
        let animator = UIViewPropertyAnimator(
            duration: duration,
            dampingRatio: damping,
            initialVelocity: velocity
        ) {
            animations()
        }

        if delay > 0 {
            animator.startAnimation(afterDelay: delay)
        } else {
            animator.startAnimation()
        }

        animator.addCompletion { position in
            completion?(position == .end)
        }

        return animator
    }

    // MARK: - 淡入淡出

    /// 淡入动画
    ///
    /// - Parameters:
    ///   - view: 目标视图
    ///   - duration: 动画时长
    ///   - delay: 延迟时间
    ///   - completion: 完成回调
    @discardableResult
    public static func fadeIn(
        view: UIView,
        duration: TimeInterval = 0.3,
        delay: TimeInterval = 0,
        completion: ((Bool) -> Void)? = nil
    ) -> UIViewPropertyAnimator {
        view.alpha = 0
        return animate(
            duration: duration,
            delay: delay,
            animations: {
                view.alpha = 1
            },
            completion: completion
        )
    }

    /// 淡出动画
    ///
    /// - Parameters:
    ///   - view: 目标视图
    ///   - duration: 动画时长
    ///   - delay: 延迟时间
    ///   - completion: 完成回调
    @discardableResult
    public static func fadeOut(
        view: UIView,
        duration: TimeInterval = 0.3,
        delay: TimeInterval = 0,
        completion: ((Bool) -> Void)? = nil
    ) -> UIViewPropertyAnimator {
        return animate(
            duration: duration,
            delay: delay,
            animations: {
                view.alpha = 0
            },
            completion: completion
        )
    }

    // MARK: - 缩放动画

    /// 缩放动画
    ///
    /// - Parameters:
    ///   - view: 目标视图
    ///   - scale: 目标缩放比例
    ///   - duration: 动画时长
    ///   - delay: 延迟时间
    ///   - completion: 完成回调
    @discardableResult
    public static func scale(
        view: UIView,
        to scale: CGFloat,
        duration: TimeInterval = 0.3,
        delay: TimeInterval = 0,
        completion: ((Bool) -> Void)? = nil
    ) -> UIViewPropertyAnimator {
        return animate(
            duration: duration,
            delay: delay,
            animations: {
                view.transform = CGAffineTransform(scaleX: scale, y: scale)
            },
            completion: completion
        )
    }

    /// 弹跳缩放动画
    ///
    /// - Parameters:
    ///   - view: 目标视图
    ///   - scale: 目标缩放比例
    ///   - duration: 动画时长
    ///   - delay: 延迟时间
    ///   - completion: 完成回调
    @discardableResult
    public static func bounceScale(
        view: UIView,
        to scale: CGFloat,
        duration: TimeInterval = 0.5,
        delay: TimeInterval = 0,
        completion: ((Bool) -> Void)? = nil
    ) -> UIViewPropertyAnimator {
        return spring(
            duration: duration,
            damping: 0.5,
            delay: delay,
            animations: {
                view.transform = CGAffineTransform(scaleX: scale, y: scale)
            },
            completion: completion
        )
    }

    /// 脉冲动画（放大后恢复）
    ///
    /// - Parameters:
    ///   - view: 目标视图
    ///   - scale: 最大缩放比例
    ///   - duration: 动画时长
    ///   - delay: 延迟时间
    ///   - completion: 完成回调
    @discardableResult
    public static func pulse(
        view: UIView,
        scale: CGFloat = 1.1,
        duration: TimeInterval = 0.3,
        delay: TimeInterval = 0,
        completion: ((Bool) -> Void)? = nil
    ) -> UIViewPropertyAnimator {
        let animator = UIViewPropertyAnimator(duration: duration, curve: .easeInOut)
        animator.addAnimations {
            view.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
        animator.addCompletion { position in
            UIView.animate(withDuration: duration * 0.5) {
                view.transform = .identity
            }
            completion?(position == .end)
        }
        animator.startAnimation(afterDelay: delay)
        return animator
    }

    /// 持续脉冲动画（重复）
    ///
    /// - Parameters:
    ///   - view: 目标视图
    ///   - scale: 最大缩放比例
    ///   - duration: 单次动画时长
    /// - Returns: 链接对象（用于取消动画）
    @discardableResult
    public static func repeatingPulse(
        view: UIView,
        scale: CGFloat = 1.1,
        duration: TimeInterval = 1
    -> UIViewAnimateLink {
        let link = UIViewAnimateLink()

        let animation = CAKeyframeAnimation(keyPath: "transform.scale")
        animation.values = [1, scale, 1]
        animation.keyTimes = [0, 0.5, 1]
        animation.duration = duration
        animation.repeatCount = .infinity

        view.layer.add(animation, forKey: "repeatingPulse")
        link.animation = animation
        link.layer = view.layer

        return link
    }

    // MARK: - 旋转动画

    /// 旋转动画
    ///
    /// - Parameters:
    ///   - view: 目标视图
    ///   - angle: 旋转角度（弧度）
    ///   - duration: 动画时长
    ///   - delay: 延迟时间
    ///   - completion: 完成回调
    @discardableResult
    public static func rotate(
        view: UIView,
        by angle: CGFloat,
        duration: TimeInterval = 0.3,
        delay: TimeInterval = 0,
        completion: ((Bool) -> Void)? = nil
    ) -> UIViewPropertyAnimator {
        return animate(
            duration: duration,
            delay: delay,
            animations: {
                view.transform = CGAffineTransform(rotationAngle: angle)
            },
            completion: completion
        )
    }

    /// 持续旋转动画
    ///
    /// - Parameters:
    ///   - view: 目标视图
    ///   - duration: 单圈时长
    /// - Returns: 链接对象（用于取消动画）
    @discardableResult
    public static func rotating(
        view: UIView,
        duration: TimeInterval = 1
    ) -> UIViewAnimateLink {
        let link = UIViewAnimateLink()

        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.toValue = CGFloat.pi * 2
        animation.duration = duration
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false

        view.layer.add(animation, forKey: "rotating")
        link.animation = animation
        link.layer = view.layer

        return link
    }

    // MARK: - 位移动画

    /// 位移动画
    ///
    /// - Parameters:
    ///   - view: 目标视图
    ///   - offset: 偏移量
    ///   - duration: 动画时长
    ///   - delay: 延迟时间
    ///   - completion: 完成回调
    @discardableResult
    public static func translate(
        view: UIView,
        by offset: CGPoint,
        duration: TimeInterval = 0.3,
        delay: TimeInterval = 0,
        completion: ((Bool) -> Void)? = nil
    ) -> UIViewPropertyAnimator {
        return animate(
            duration: duration,
            delay: delay,
            animations: {
                view.transform = CGAffineTransform(translationX: offset.x, y: offset.y)
            },
            completion: completion
        )
    }

    /// 滑入动画
    ///
    /// - Parameters:
    ///   - view: 目标视图
    ///   - direction: 滑入方向
    ///   - distance: 滑动距离
    ///   - duration: 动画时长
    ///   - delay: 延迟时间
    ///   - completion: 完成回调
    @discardableResult
    public static func slideIn(
        view: UIView,
        direction: Direction = .fromBottom,
        distance: CGFloat = 50,
        duration: TimeInterval = 0.3,
        delay: TimeInterval = 0,
        completion: ((Bool) -> Void)? = nil
    ) -> UIViewPropertyAnimator {
        let offset: CGPoint
        switch direction {
        case .fromTop:
            offset = CGPoint(x: 0, y: -distance)
        case .fromBottom:
            offset = CGPoint(x: 0, y: distance)
        case .fromLeft:
            offset = CGPoint(x: -distance, y: 0)
        case .fromRight:
            offset = CGPoint(x: distance, y: 0)
        }

        view.transform = CGAffineTransform(translationX: offset.x, y: offset.y)
        view.alpha = 0

        return animate(
            duration: duration,
            delay: delay,
            options: .curveEaseOut,
            animations: {
                view.transform = .identity
                view.alpha = 1
            },
            completion: completion
        )
    }

    /// 滑出动画
    ///
    /// - Parameters:
    ///   - view: 目标视图
    ///   - direction: 滑出方向
    ///   - distance: 滑动距离
    ///   - duration: 动画时长
    ///   - delay: 延迟时间
    ///   - completion: 完成回调
    @discardableResult
    public static func slideOut(
        view: UIView,
        direction: Direction = .toBottom,
        distance: CGFloat = 50,
        duration: TimeInterval = 0.3,
        delay: TimeInterval = 0,
        completion: ((Bool) -> Void)? = nil
    ) -> UIViewPropertyAnimator {
        let offset: CGPoint
        switch direction {
        case .toTop:
            offset = CGPoint(x: 0, y: -distance)
        case .toBottom:
            offset = CGPoint(x: 0, y: distance)
        case .toLeft:
            offset = CGPoint(x: -distance, y: 0)
        case .toRight:
            offset = CGPoint(x: distance, y: 0)
        }

        return animate(
            duration: duration,
            delay: delay,
            options: .curveEaseIn,
            animations: {
                view.transform = CGAffineTransform(translationX: offset.x, y: offset.y)
                view.alpha = 0
            },
            completion: completion
        )
    }

    // MARK: - 组合动画

    /// 同时执行多个动画
    ///
    /// - Parameters:
    ///   - duration: 动画时长
    ///   - delay: 延迟时间
    ///   - animations: 动画闭包数组
    ///   - completion: 完成回调
    @discardableResult
    public static func parallel(
        duration: TimeInterval,
        delay: TimeInterval = 0,
        animations: [@escaping () -> Void],
        completion: ((Bool) -> Void)? = nil
    ) -> UIViewPropertyAnimator {
        return animate(
            duration: duration,
            delay: delay,
            animations: {
                for animation in animations {
                    animation()
                }
            },
            completion: completion
        )
    }

    /// 顺序执行多个动画
    ///
    /// - Parameters:
    ///   - duration: 单个动画时长
    ///   - animations: 动画闭包数组
    ///   - completion: 完成回调
    public static func sequence(
        duration: TimeInterval = 0.3,
        animations: [@escaping () -> Void],
        completion: ((Bool) -> Void)? = nil
    ) {
        guard !animations.isEmpty else {
            completion?(true)
            return
        }

        func execute(at index: Int) {
            guard index < animations.count else {
                completion?(true)
                return
            }

            UIView.animate(
                withDuration: duration,
                animations: animations[index],
                completion: { _ in
                    execute(at: index + 1)
                }
            )
        }

        execute(at: 0)
    }

    // MARK: - 弹性动画

    /// 弹性收缩动画
    ///
    /// - Parameters:
    ///   - view: 目标视图
    ///   - duration: 动画时长
    ///   - delay: 延迟时间
    ///   - completion: 完成回调
    @discardableResult
    public static func shrink(
        view: UIView,
        duration: TimeInterval = 0.2,
        delay: TimeInterval = 0,
        completion: ((Bool) -> Void)? = nil
    ) -> UIViewPropertyAnimator {
        return spring(
            duration: duration,
            damping: 0.6,
            velocity: 1,
            delay: delay,
            animations: {
                view.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            },
            completion: completion
        )
    }

    /// 弹性恢复动画
    ///
    /// - Parameters:
    ///   - view: 目标视图
    ///   - duration: 动画时长
    ///   - delay: 延迟时间
    ///   - completion: 完成回调
    @discardableResult
    public static func restore(
        view: UIView,
        duration: TimeInterval = 0.3,
        delay: TimeInterval = 0,
        completion: ((Bool) -> Void)? = nil
    ) -> UIViewPropertyAnimator {
        return spring(
            duration: duration,
            damping: 0.6,
            velocity: 1,
            delay: delay,
            animations: {
                view.transform = .identity
            },
            completion: completion
        )
    }

    /// 收缩后恢复动画
    ///
    /// - Parameters:
    ///   - view: 目标视图
    ///   - shrinkDuration: 收缩时长
    ///   - restoreDuration: 恢复时长
    ///   - delay: 延迟时间
    ///   - completion: 完成回调
    @discardableResult
    public static func shrinkAndRestore(
        view: UIView,
        shrinkDuration: TimeInterval = 0.2,
        restoreDuration: TimeInterval = 0.3,
        delay: TimeInterval = 0,
        completion: ((Bool) -> Void)? = nil
    ) -> UIViewPropertyAnimator {
        let animator = UIViewPropertyAnimator(duration: shrinkDuration + restoreDuration, curve: .linear)

        // 收缩
        UIView.animate(
            withDuration: shrinkDuration,
            delay: delay,
            options: .curveEaseIn,
            animations: {
                view.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            },
            completion: { _ in
                // 恢复
                UIView.animate(
                    withDuration: restoreDuration,
                    delay: 0,
                    options: .curveEaseOut,
                    animations: {
                        view.transform = .identity
                    },
                    completion: completion
                )
            }
        )

        return animator
    }

    // MARK: - 方向枚举

    /// 动画方向
    public enum Direction {
        case fromTop, fromBottom, fromLeft, fromRight
        case toTop, toBottom, toLeft, toRight
    }
}

// MARK: - UIViewAnimateLink

/// 动画链接对象（用于取消持续动画）
@MainActor
public class UIViewAnimateLink {

    /// 动画
    fileprivate var animation: CAAnimation?

    /// 图层
    fileprivate weak var layer: CALayer?

    /// 取消动画
    public func cancel() {
        layer?.removeAllAnimations()
    }

    /// 暂停动画
    public func pause() {
        guard let layer = layer else { return }
        let pausedTime = layer.convertTime(CACurrentMediaTime(), from: nil)
        layer.speed = 0
        layer.timeOffset = pausedTime
    }

    /// 恢复动画
    public func resume() {
        guard let layer = layer else { return }
        let pausedTime = layer.timeOffset
        layer.speed = 1
        layer.timeOffset = 0
        layer.beginTime = 0
        let timeSincePause = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        layer.beginTime = timeSincePause
    }
}

// MARK: - UIView Extension (动画)

public extension UIView {

    /// 淡入
    func ls_fadeIn(duration: TimeInterval = 0.3, delay: TimeInterval = 0, completion: ((Bool) -> Void)? = nil) -> UIViewPropertyAnimator {
        return LSAnimation.fadeIn(view: self, duration: duration, delay: delay, completion: completion)
    }

    /// 淡出
    func ls_fadeOut(duration: TimeInterval = 0.3, delay: TimeInterval = 0, completion: ((Bool) -> Void)? = nil) -> UIViewPropertyAnimator {
        return LSAnimation.fadeOut(view: self, duration: duration, delay: delay, completion: completion)
    }

    /// 缩放
    func ls_scale(to scale: CGFloat, duration: TimeInterval = 0.3, delay: TimeInterval = 0, completion: ((Bool) -> Void)? = nil) -> UIViewPropertyAnimator {
        return LSAnimation.scale(view: self, to: scale, duration: duration, delay: delay, completion: completion)
    }

    /// 旋转
    func ls_rotate(by angle: CGFloat, duration: TimeInterval = 0.3, delay: TimeInterval = 0, completion: ((Bool) -> Void)? = nil) -> UIViewPropertyAnimator {
        return LSAnimation.rotate(view: self, by: angle, duration: duration, delay: delay, completion: completion)
    }

    /// 位移
    func ls_translate(by offset: CGPoint, duration: TimeInterval = 0.3, delay: TimeInterval = 0, completion: ((Bool) -> Void)? = nil) -> UIViewPropertyAnimator {
        return LSAnimation.translate(view: self, by: offset, duration: duration, delay: delay, completion: completion)
    }

    /// 滑入
    func ls_slideIn(from direction: LSAnimation.Direction, distance: CGFloat = 50, duration: TimeInterval = 0.3, delay: TimeInterval = 0, completion: ((Bool) -> Void)? = nil) -> UIViewPropertyAnimator {
        return LSAnimation.slideIn(view: self, direction: direction, distance: distance, duration: duration, delay: delay, completion: completion)
    }

    /// 滑出
    func ls_slideOut(to direction: LSAnimation.Direction, distance: CGFloat = 50, duration: TimeInterval = 0.3, delay: TimeInterval = 0, completion: ((Bool) -> Void)? = nil) -> UIViewPropertyAnimator {
        return LSAnimation.slideOut(view: self, direction: direction, distance: distance, duration: duration, delay: delay, completion: completion)
    }

    /// 脉冲
    func ls_pulse(scale: CGFloat = 1.1, duration: TimeInterval = 0.3, delay: TimeInterval = 0, completion: ((Bool) -> Void)? = nil) -> UIViewPropertyAnimator {
        return LSAnimation.pulse(view: self, scale: scale, duration: duration, delay: delay, completion: completion)
    }

    /// 持续旋转
    func ls_rotateContinuously(duration: TimeInterval = 1) -> UIViewAnimateLink {
        return LSAnimation.rotating(view: self, duration: duration)
    }

    /// 持续脉冲
    func ls_pulseContinuously(scale: CGFloat = 1.1, duration: TimeInterval = 1) -> UIViewAnimateLink {
        return LSAnimation.repeatingPulse(view: self, scale: scale, duration: duration)
    }
}

// MARK: - CALayer Extension (动画)

public extension CALayer {

    /// 淡入
    func ls_fadeIn(duration: TimeInterval = 0.3) {
        opacity = 0
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = duration
        add(animation, forKey: "fadeIn")
        opacity = 1
    }

    /// 淡出
    func ls_fadeOut(duration: TimeInterval = 0.3) {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = opacity
        animation.toValue = 0
        animation.duration = duration
        add(animation, forKey: "fadeOut")
        opacity = 0
    }

    /// 缩放
    func ls_scale(to scale: CGFloat, duration: TimeInterval = 0.3) {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = 1
        animation.toValue = scale
        animation.duration = duration
        add(animation, forKey: "scale")
        transform = CATransform3DMakeScale(scale, scale, 1)
    }

    /// 移动
    func ls_move(to position: CGPoint, duration: TimeInterval = 0.3) {
        let animation = CABasicAnimation(keyPath: "position")
        animation.fromValue = NSValue(cgPoint: self.position)
        animation.toValue = NSValue(cgPoint: position)
        animation.duration = duration
        add(animation, forKey: "move")
        self.position = position
    }
}

#endif

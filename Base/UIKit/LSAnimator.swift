//
//  LSAnimator.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  动画工具 - 简化 UIView 动画实现
//

#if canImport(UIKit)
import UIKit
import Foundation

// MARK: - LSAnimator

/// 动画管理器
@MainActor
public class LSAnimator {

    // MARK: - 类型定义

    /// 动画完成回调
    public typealias CompletionHandler = () -> Void

    // MARK: - 基础动画

    /// 执行动画
    ///
    /// - Parameters:
    ///   - duration: 持续时间
    ///   - delay: 延迟时间
    ///   - options: 选项
    ///   - animations: 动画闭包
    ///   - completion: 完成闭包
    @discardableResult
    public static func animate(
        duration: TimeInterval,
        delay: TimeInterval = 0,
        options: UIView.AnimationOptions = .curveEaseInOut,
        animations: @escaping () -> Void,
        completion: CompletionHandler? = nil
    ) -> UIViewPropertyAnimator {
        let animator = UIViewPropertyAnimator(
            duration: duration,
            delay: delay,
            options: options
        ) {
            animations()
        }

        if let completion = completion {
            animator.addCompletion { _ in
                completion()
            }
        }

        animator.startAnimation()
        return animator
    }

    /// 弹簧动画
    ///
    /// - Parameters:
    ///   - damping: 阻尼比 (0-1)
    ///   - velocity: 初始速度
    ///   - delay: 延迟时间
    ///   - options: 选项
    ///   - animations: 动画闭包
    ///   - completion: 完成闭包
    @discardableResult
    public static func spring(
        damping: CGFloat = 0.7,
        velocity: CGFloat = 0,
        delay: TimeInterval = 0,
        options: UIView.AnimationOptions = .curveEaseInOut,
        animations: @escaping () -> Void,
        completion: CompletionHandler? = nil
    ) -> UIViewPropertyAnimator {
        let animator = UIViewPropertyAnimator(
            duration: 0.6,
            dampingRatio: damping,
            initialVelocity: velocity
        ) {
            animations()
        }

        animator.startAnimation(afterDelay: delay)

        if let completion = completion {
            animator.addCompletion { _ in
                completion()
            }
        }

        return animator
    }
}

// MARK: - UIView Extension (动画)

public extension UIView {

    // MARK: - 基础属性动画

    /// 淡入动画
    ///
    /// - Parameters:
    ///   - duration: 持续时间
    ///   - delay: 延迟时间
    ///   - completion: 完成回调
    @discardableResult
    func ls_fadeIn(
        duration: TimeInterval = 0.3,
        delay: TimeInterval = 0,
        completion: (() -> Void)? = nil
    ) -> UIViewPropertyAnimator {
        alpha = 0
        return LSAnimator.animate(
            duration: duration,
            delay: delay,
            animations: { [weak self] in
                self?.alpha = 1
            },
            completion: completion
        )
    }

    /// 淡出动画
    ///
    /// - Parameters:
    ///   - duration: 持续时间
    ///   - delay: 延迟时间
    ///   - completion: 完成回调
    @discardableResult
    func ls_fadeOut(
        duration: TimeInterval = 0.3,
        delay: TimeInterval = 0,
        completion: (() -> Void)? = nil
    ) -> UIViewPropertyAnimator {
        return LSAnimator.animate(
            duration: duration,
            delay: delay,
            animations: { [weak self] in
                self?.alpha = 0
            },
            completion: completion
        )
    }

    /// 移动动画
    ///
    /// - Parameters:
    ///   - offset: 偏移量
    ///   - duration: 持续时间
    ///   - delay: 延迟时间
    ///   - completion: 完成回调
    @discardableResult
    func ls_move(
        by offset: CGPoint,
        duration: TimeInterval = 0.3,
        delay: TimeInterval = 0,
        completion: (() -> Void)? = nil
    ) -> UIViewPropertyAnimator {
        return LSAnimator.animate(
            duration: duration,
            delay: delay,
            animations: { [weak self] in
                self?.center.x += offset.x
                self?.center.y += offset.y
            },
            completion: completion
        )
    }

    /// 缩放动画
    ///
    /// - Parameters:
    ///   - scale: 缩放比例
    ///   - duration: 持续时间
    ///   - delay: 延迟时间
    ///   - completion: 完成回调
    @discardableResult
    func ls_scale(
        to scale: CGFloat,
        duration: TimeInterval = 0.3,
        delay: TimeInterval = 0,
        completion: (() -> Void)? = nil
    ) -> UIViewPropertyAnimator {
        return LSAnimator.animate(
            duration: duration,
            delay: delay,
            animations: { [weak self] in
                self?.transform = CGAffineTransform(scaleX: scale, y: scale)
            },
            completion: completion
        )
    }

    /// 旋转动画
    ///
    /// - Parameters:
    ///   - angle: 旋转角度（弧度）
    ///   - duration: 持续时间
    ///   - delay: 延迟时间
    ///   - completion: 完成回调
    @discardableResult
    func ls_rotate(
        by angle: CGFloat,
        duration: TimeInterval = 0.3,
        delay: TimeInterval = 0,
        completion: (() -> Void)? = nil
    ) -> UIViewPropertyAnimator {
        return LSAnimator.animate(
            duration: duration,
            delay: delay,
            animations: { [weak self] in
                if let tempValue = .transform {
                    transform = tempValue
                } else {
                    transform = .identity
                }
            },
            completion: completion
        )
    }

    // MARK: - 弹簧动画

    /// 弹性缩放
    ///
    /// - Parameters:
    ///   - scale: 目标缩放
    ///   - damping: 阻尼
    ///   - velocity: 初速度
    ///   - completion: 完成回调
    @discardableResult
    func ls_springScale(
        to scale: CGFloat,
        damping: CGFloat = 0.6,
        velocity: CGFloat = 0,
        completion: (() -> Void)? = nil
    ) -> UIViewPropertyAnimator {
        return LSAnimator.spring(
            damping: damping,
            velocity: velocity,
            animations: { [weak self] in
                self?.transform = CGAffineTransform(scaleX: scale, y: scale)
            },
            completion: completion
        )
    }

    /// 弹性移动
    ///
    /// - Parameters:
    ///   - point: 目标位置
    ///   - damping: 阻尼
    ///   - velocity: 初速度
    ///   - completion: 完成回调
    @discardableResult
    func ls_springMove(
        to point: CGPoint,
        damping: CGFloat = 0.6,
        velocity: CGFloat = 0,
        completion: (() -> Void)? = nil
    ) -> UIViewPropertyAnimator {
        return LSAnimator.spring(
            damping: damping,
            velocity: velocity,
            animations: { [weak self] in
                self?.center = point
            },
            completion: completion
        )
    }

    // MARK: - 组合动画

    /// 弹跳动画
    ///
    /// - Parameters:
    ///   - duration: 持续时间
    ///   - completion: 完成回调
    @discardableResult
    func ls_bounce(
        duration: TimeInterval = 0.5,
        completion: (() -> Void)? = nil
    ) -> UIViewPropertyAnimator {
        let initialTransform = transform

        // 第一步：缩小
        let animator1 = LSAnimator.animate(
            duration: duration * 0.3,
            animations: { [weak self] in
                self?.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }
        )

        // 第二步：放大
        let animator2 = LSAnimator.animate(
            duration: duration * 0.3,
            delay: duration * 0.3,
            animations: { [weak self] in
                self?.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            }
        )

        // 第三步：恢复
        let animator3 = LSAnimator.animate(
            duration: duration * 0.4,
            delay: duration * 0.6,
            animations: { [weak self] in
                self?.transform = initialTransform
            },
            completion: completion
        )

        return animator3
    }

    /// 摇晃动画
    ///
    /// - Parameters:
    ///   - duration: 持续时间
    ///   - angle: 摇晃角度
    ///   - completion: 完成回调
    @discardableResult
    func ls_shake(
        duration: TimeInterval = 0.5,
        angle: CGFloat = .pi / 8,
        completion: (() -> Void)? = nil
    ) -> UIViewPropertyAnimator {
        let numberOfShakes = 3
        let shakeDuration = duration / Double(numberOfShakes * 2)

        for i in 0..<numberOfShakes {
            let delay = Double(i * 2) * shakeDuration

            // 向左摇
            LSAnimator.animate(
                duration: shakeDuration,
                delay: delay,
                animations: { [weak self] in
                    self?.transform = CGAffineTransform(rotationAngle: -angle)
                }
            )

            // 向右摇
            LSAnimator.animate(
                duration: shakeDuration,
                delay: delay + shakeDuration,
                animations: { [weak self] in
                    self?.transform = .identity
                },
                completion: i == numberOfShakes - 1 ? completion : nil
            )
        }

        return UIViewPropertyAnimator(duration: duration, curve: .linear)
    }

    /// 脉冲动画
    ///
    /// - Parameters:
    ///   - scale: 脉冲缩放
    ///   - duration: 持续时间
    ///   - completion: 完成回调
    @discardableResult
    func ls_pulse(
        scale: CGFloat = 1.2,
        duration: TimeInterval = 0.3,
        completion: (() -> Void)? = nil
    ) -> UIViewPropertyAnimator {
        let animator1 = LSAnimator.animate(
            duration: duration,
            animations: { [weak self] in
                self?.transform = CGAffineTransform(scaleX: scale, y: scale)
                self?.alpha = 0.5
            }
        )

        let animator2 = LSAnimator.animate(
            duration: duration,
            delay: duration,
            animations: { [weak self] in
                self?.transform = .identity
                self?.alpha = 1
            },
            completion: completion
        )

        return animator2
    }

    // MARK: - 转场动画

    /// 从位置进入
    ///
    /// - Parameters:
    ///   - position: 起始位置
    ///   - duration: 持续时间
    ///   - completion: 完成回调
    @discardableResult
    func ls_slideIn(
        from position: SlidePosition,
        duration: TimeInterval = 0.3,
        completion: (() -> Void)? = nil
    ) -> UIViewPropertyAnimator {
        let offset: CGFloat
        switch position {
        case .left:
            offset = -bounds.width
        case .right:
            offset = bounds.width
        case .top:
            offset = -bounds.height
        case .bottom:
            offset = bounds.height
        }

        let startPoint: CGPoint
        let animationOffset: CGPoint

        switch position {
        case .left, .right:
            startPoint = CGPoint(x: center.x + offset, y: center.y)
            animationOffset = CGPoint(x: -offset, y: 0)
        case .top, .bottom:
            startPoint = CGPoint(x: center.x, y: center.y + offset)
            animationOffset = CGPoint(x: 0, y: -offset)
        }

        center = startPoint

        return LSAnimator.animate(
            duration: duration,
            animations: { [weak self] in
                self?.center.x -= animationOffset.x
                self?.center.y -= animationOffset.y
            },
            completion: completion
        )
    }

    /// 滑出到位置
    ///
    /// - Parameters:
    ///   - position: 目标位置
    ///   - duration: 持续时间
    ///   - completion: 完成回调
    @discardableResult
    func ls_slideOut(
        to position: SlidePosition,
        duration: TimeInterval = 0.3,
        completion: (() -> Void)? = nil
    ) -> UIViewPropertyAnimator {
        let offset: CGFloat
        switch position {
        case .left:
            offset = -bounds.width
        case .right:
            offset = bounds.width
        case .top:
            offset = -bounds.height
        case .bottom:
            offset = bounds.height
        }

        let animationOffset: CGPoint
        switch position {
        case .left, .right:
            animationOffset = CGPoint(x: offset, y: 0)
        case .top, .bottom:
            animationOffset = CGPoint(x: 0, y: offset)
        }

        return LSAnimator.animate(
            duration: duration,
            animations: { [weak self] in
                self?.center.x += animationOffset.x
                self?.center.y += animationOffset.y
            },
            completion: completion
        )
    }

    // MARK: - 枚举

    /// 滑动位置
    enum SlidePosition {
        case left
        case right
        case top
        case bottom
    }
}

// MARK: - CALayer Extension (动画)

public extension CALayer {

    /// 淡入动画
    ///
    /// - Parameters:
    ///   - duration: 持续时间
    ///   - completion: 完成回调
    @discardableResult
    func ls_fadeIn(
        duration: TimeInterval = 0.3,
        completion: (() -> Void)? = nil
    ) -> CABasicAnimation {
        opacity = 0

        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = duration
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false

        add(animation, forKey: "fadeIn")

        // 设置最终值
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.opacity = 1
            completion?()
        }

        return animation
    }

    /// 淡出动画
    ///
    /// - Parameters:
    ///   - duration: 持续时间
    ///   - completion: 完成回调
    @discardableResult
    func ls_fadeOut(
        duration: TimeInterval = 0.3,
        completion: (() -> Void)? = nil
    ) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1
        animation.toValue = 0
        animation.duration = duration
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false

        add(animation, forKey: "fadeOut")

        // 设置最终值
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.opacity = 0
            completion?()
        }

        return animation
    }

    /// 移动动画
    ///
    /// - Parameters:
    ///   - to: 目标位置
    ///   - duration: 持续时间
    ///   - completion: 完成回调
    @discardableResult
    func ls_move(
        to point: CGPoint,
        duration: TimeInterval = 0.3,
        completion: (() -> Void)? = nil
    ) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "position")
        animation.fromValue = NSValue(cgPoint: position)
        animation.toValue = NSValue(cgPoint: point)
        animation.duration = duration
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false

        add(animation, forKey: "move")

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.position = point
            completion?()
        }

        return animation
    }

    /// 缩放动画
    ///
    /// - Parameters:
    ///   - scale: 目标缩放
    ///   - duration: 持续时间
    ///   - completion: 完成回调
    @discardableResult
    func ls_scale(
        to scale: CGFloat,
        duration: TimeInterval = 0.3,
        completion: (() -> Void)? = nil
    ) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.toValue = scale
        animation.duration = duration
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false

        add(animation, forKey: "scale")

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.transform = CATransform3DMakeScale(scale, scale, 1)
            completion?()
        }

        return animation
    }

    /// 旋转动画
    ///
    /// - Parameters:
    ///   - angle: 旋转角度（弧度）
    ///   - duration: 持续时间
    ///   - completion: 完成回调
    @discardableResult
    func ls_rotate(
        by angle: CGFloat,
        duration: TimeInterval = 0.3,
        completion: (() -> Void)? = nil
    ) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.toValue = angle
        animation.duration = duration
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false

        add(animation, forKey: "rotate")

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.transform = CATransform3DMakeRotation(angle, 0, 0, 1)
            completion?()
        }

        return animation
    }
}

// MARK: - UIView 动画序列

/// 动画序列构建器
public class LSAnimationSequence {

    private var animations: [AnimationStep] = []

    /// 动画步骤
    private struct AnimationStep {
        let duration: TimeInterval
        let delay: TimeInterval
        let animations: () -> Void
        let completion: (() -> Void)?
    }

    /// 添加动画
    ///
    /// - Parameters:
    ///   - duration: 持续时间
    ///   - animations: 动画闭包
    ///   - completion: 完成闭包
    /// - Returns: self
    @discardableResult
    public func then(
        duration: TimeInterval,
        animations: @escaping () -> Void,
        completion: (() -> Void)? = nil
    ) -> Self {
        animations.append(AnimationStep(
            duration: duration,
            delay: 0,
            animations: animations,
            completion: completion
        ))
        return self
    }

    /// 添加延迟
    ///
    /// - Parameter delay: 延迟时间
    /// - Returns: self
    @discardableResult
    public func wait(_ delay: TimeInterval) -> Self {
        animations.append(AnimationStep(
            duration: 0,
            delay: delay,
            animations: {},
            completion: nil
        ))
        return self
    }

    /// 执行序列
    ///
    /// - Parameter completion: 最终完成回调
    public func run(completion: (() -> Void)? = nil) {
        var totalDelay: TimeInterval = 0

        for step in animations {
            let delay = totalDelay + step.delay

            if step.duration > 0 {
                LSAnimator.animate(
                    duration: step.duration,
                    delay: delay,
                    animations: step.animations,
                    completion: step.animations.isEmpty ? step.completion : nil
                )
            }

            totalDelay += step.duration
        }

        // 最终完成回调
        if let completion = completion {
            DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
                completion()
            }
        }
    }
}

// MARK: - 便捷方法

public extension UIView {

    /// 创建动画序列
    ///
    /// - Parameter configure: 配置闭包
    static func ls_animationSequence(
        configure: (inout LSAnimationSequence) -> Void
    ) -> LSAnimationSequence {
        var sequence = LSAnimationSequence()
        configure(&sequence)
        return sequence
    }
}

#endif

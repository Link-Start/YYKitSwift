//
//  LSTransition.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  转场动画工具 - 自定义 ViewController 转场动画
//

#if canImport(UIKit)
import UIKit

// MARK: - LSTransitionAnimator

/// 转场动画类型
public enum LSTransitionType {
    case slideFromRight      // 从右侧滑入
    case slideFromLeft       // 从左侧滑入
    case slideFromTop        // 从上方滑入
    case slideFromBottom     // 从下方滑入
    case fade                // 淡入淡出
    case scale               // 缩放
    case flip                // 翻转
    case curl                // 翻页
    case crossDissolve       // 交叉溶解
    case none                // 无动画
}

// MARK: - LSTransitionAnimator

/// 转场动画器
@MainActor
public class LSTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    // MARK: - 属性

    /// 转场类型
    public let transitionType: LSTransitionType

    /// 持续时间
    public let duration: TimeInterval

    /// 是否为呈现
    private let isPresenting: Bool

    // MARK: - 初始化

    /// 创建转场动画器
    ///
    /// - Parameters:
    ///   - type: 转场类型
    ///   - duration: 持续时间
    ///   - isPresenting: 是否为呈现
    public init(
        type: LSTransitionType,
        duration: TimeInterval = 0.3,
        isPresenting: Bool = true
    ) {
        self.transitionType = type
        self.duration = duration
        self.isPresenting = isPresenting
        super.init()
    }

    // MARK: - UIViewControllerAnimatedTransitioning

    public func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning
    ) -> TimeInterval {
        return duration
    }

    public func animateTransition(
        using transitionContext: UIViewControllerContextTransitioning
    ) {
        guard let fromVC = transitionContext.viewController(forKey: .from),
              let toVC = transitionContext.viewController(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }

        let containerView = transitionContext.containerView
        let fromView = fromVC.view
        let toView = toVC.view

        // 获取最终 frame
        let finalFrame = transitionContext.finalFrame(for: toVC)

        switch transitionType {
        case .slideFromRight:
            animateSlide(
                from: fromView,
                to: toView,
                container: containerView,
                finalFrame: finalFrame,
                direction: isPresenting ? .fromRight : .fromLeft,
                context: transitionContext
            )

        case .slideFromLeft:
            animateSlide(
                from: fromView,
                to: toView,
                container: containerView,
                finalFrame: finalFrame,
                direction: isPresenting ? .fromLeft : .fromRight,
                context: transitionContext
            )

        case .slideFromTop:
            animateSlide(
                from: fromView,
                to: toView,
                container: containerView,
                finalFrame: finalFrame,
                direction: isPresenting ? .fromTop : .fromBottom,
                context: transitionContext
            )

        case .slideFromBottom:
            animateSlide(
                from: fromView,
                to: toView,
                container: containerView,
                finalFrame: finalFrame,
                direction: isPresenting ? .fromBottom : .fromTop,
                context: transitionContext
            )

        case .fade:
            animateFade(
                from: fromView,
                to: toView,
                container: containerView,
                finalFrame: finalFrame,
                context: transitionContext
            )

        case .scale:
            animateScale(
                from: fromView,
                to: toView,
                container: containerView,
                finalFrame: finalFrame,
                context: transitionContext
            )

        case .flip:
            animateFlip(
                from: fromView,
                to: toView,
                container: containerView,
                finalFrame: finalFrame,
                context: transitionContext
            )

        case .curl:
            animateCurl(
                from: fromView,
                to: toView,
                container: containerView,
                finalFrame: finalFrame,
                context: transitionContext
            )

        case .crossDissolve:
            animateCrossDissolve(
                from: fromView,
                to: toView,
                container: containerView,
                finalFrame: finalFrame,
                context: transitionContext
            )

        case .none:
            toView.frame = finalFrame
            transitionContext.completeTransition(true)
        }
    }

    // MARK: - 动画实现

    private func animateSlide(
        from fromView: UIView?,
        to toView: UIView,
        container: UIView,
        finalFrame: CGRect,
        direction: SlideDirection,
        context: UIViewControllerContextTransitioning
    ) {
        toView.frame = finalFrame

        let offset: CGFloat
        switch direction {
        case .fromRight:
            offset = container.bounds.width
            toView.transform = CGAffineTransform(translationX: offset, y: 0)
        case .fromLeft:
            offset = -container.bounds.width
            toView.transform = CGAffineTransform(translationX: offset, y: 0)
        case .fromTop:
            offset = -container.bounds.height
            toView.transform = CGAffineTransform(translationX: 0, y: offset)
        case .fromBottom:
            offset = container.bounds.height
            toView.transform = CGAffineTransform(translationX: 0, y: offset)
        }

        container.addSubview(toView)

        UIView.animate(
            withDuration: duration,
            animations: {
                toView.transform = .identity
                fromView?.transform = CGAffineTransform(
                    translationX: -offset * (direction == .fromLeft || direction == .fromRight ? (direction == .fromLeft ? 1 : -1) : 0),
                    y: -offset * (direction == .fromTop || direction == .fromBottom ? (direction == .fromTop ? 1 : -1) : 0)
                )
            },
            completion: { finished in
                fromView?.transform = .identity
                context.completeTransition(finished)
            }
        )
    }

    private func animateFade(
        from fromView: UIView?,
        to toView: UIView,
        container: UIView,
        finalFrame: CGRect,
        context: UIViewControllerContextTransitioning
    ) {
        toView.frame = finalFrame
        toView.alpha = 0
        container.addSubview(toView)

        UIView.animate(
            withDuration: duration,
            animations: {
                toView.alpha = 1
                fromView?.alpha = 0
            },
            completion: { finished in
                fromView?.alpha = 1
                context.completeTransition(finished)
            }
        )
    }

    private func animateScale(
        from fromView: UIView?,
        to toView: UIView,
        container: UIView,
        finalFrame: CGRect,
        context: UIViewControllerContextTransitioning
    ) {
        toView.frame = finalFrame
        toView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        toView.alpha = 0
        container.addSubview(toView)

        UIView.animate(
            withDuration: duration,
            animations: {
                toView.transform = .identity
                toView.alpha = 1
                fromView?.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                fromView?.alpha = 0
            },
            completion: { finished in
                fromView?.transform = .identity
                fromView?.alpha = 1
                context.completeTransition(finished)
            }
        )
    }

    private func animateFlip(
        from fromView: UIView?,
        to toView: UIView,
        container: UIView,
        finalFrame: CGRect,
        context: UIViewControllerContextTransitioning
    ) {
        toView.frame = finalFrame
        container.addSubview(toView)

        UIView.transition(
            with: container,
            duration: duration,
            options: [.transitionFlipFromRight],
            animations: {
                fromView?.removeFromSuperview()
            },
            completion: { finished in
                context.completeTransition(finished)
            }
        )
    }

    private func animateCurl(
        from fromView: UIView?,
        to toView: UIView,
        container: UIView,
        finalFrame: CGRect,
        context: UIViewControllerContextTransitioning
    ) {
        toView.frame = finalFrame
        container.addSubview(toView)

        UIView.transition(
            with: container,
            duration: duration,
            options: [.transitionCurlUp],
            animations: {
                fromView?.removeFromSuperview()
            },
            completion: { finished in
                context.completeTransition(finished)
            }
        )
    }

    private func animateCrossDissolve(
        from fromView: UIView?,
        to toView: UIView,
        container: UIView,
        finalFrame: CGRect,
        context: UIViewControllerContextTransitioning
    ) {
        toView.frame = finalFrame
        container.addSubview(toView)

        UIView.transition(
            with: container,
            duration: duration,
            options: [.transitionCrossDissolve],
            animations: {
                fromView?.removeFromSuperview()
            },
            completion: { finished in
                context.completeTransition(finished)
            }
        )
    }

    // MARK: - 类型定义

    private enum SlideDirection {
        case fromRight
        case fromLeft
        case fromTop
        case fromBottom
    }
}

// MARK: - LSTransitionDelegate

/// 转场代理
public class LSTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {

    // MARK: - 属性

    /// 转场类型
    public var transitionType: LSTransitionType = .slideFromRight

    /// 持续时间
    public var transitionDuration: TimeInterval = 0.3

    // MARK: - UIViewControllerTransitioningDelegate

    public func animationControllerForPresented(
        presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        return LSTransitionAnimator(
            type: transitionType,
            duration: transitionDuration,
            isPresenting: true
        )
    }

    public func animationControllerForDismissed(
        dismissed: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        return LSTransitionAnimator(
            type: transitionType,
            duration: transitionDuration,
            isPresenting: false
        )
    }
}

// MARK: - UIViewController Extension (转场)

public extension UIViewController {

    /// 设置转场代理
    ///
    /// - Parameter type: 转场类型
    func ls_setTransitionDelegate(_ type: LSTransitionType = .slideFromRight) {
        let transitionDelegate = LSTransitionDelegate()
        transitionDelegate.transitionType = type
        transitioningDelegate = transitionDelegate
        modalPresentationStyle = .custom

        // 使用关联对象保持引用
        objc_setAssociatedObject(
            self,
            &AssociatedKeys.transitionDelegate,
            transitionDelegate,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }

    /// 呈现 ViewController（带转场动画）
    ///
    /// - Parameters:
    ///   - viewController: 要呈现的控制器
    ///   - type: 转场类型
    ///   - animated: 是否动画
    ///   - completion: 完成回调
    func ls_present(
        _ viewController: UIViewController,
        type: LSTransitionType = .slideFromRight,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        viewController.ls_setTransitionDelegate(type)
        present(viewController, animated: animated, completion: completion)
    }
}

// MARK: - Associated Keys

private enum AssociatedKeys {
    static var transitionDelegate = "transitionDelegate"
}

// MARK: - UINavigationController Extension (转场)

public extension UINavigationController {

    /// 推送 ViewController（带动画）
    ///
    /// - Parameters:
    ///   - viewController: 要推送的控制器
    ///   - type: 转场类型
    func ls_push(
        _ viewController: UIViewController,
        type: LSTransitionType = .slideFromRight
    ) {
        let transitionDelegate = LSTransitionDelegate()
        transitionDelegate.transitionType = type

        viewController.transitioningDelegate = transitionDelegate

        objc_setAssociatedObject(
            viewController,
            &AssociatedKeys.transitionDelegate,
            transitionDelegate,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )

        pushViewController(viewController, animated: true)
    }
}

// MARK: - UITabBarController Extension (转场)

public extension UITabBarController {

    /// 设置转场动画
    ///
    /// - Parameter type: 转场类型
    func ls_setTransitionAnimation(_ type: LSTransitionType = .fade) {
        let transitionDelegate = LSTransitionDelegate()
        transitionDelegate.transitionType = type
        delegate = transitionDelegate

        objc_setAssociatedObject(
            self,
            &AssociatedKeys.transitionDelegate,
            transitionDelegate,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }
}

// MARK: - 便捷转场动画

public extension UIViewController {

    /// 从右侧滑入
    func ls_presentSlideFromRight(_ viewController: UIViewController) {
        ls_present(viewController, type: .slideFromRight)
    }

    /// 从左侧滑入
    func ls_presentSlideFromLeft(_ viewController: UIViewController) {
        ls_present(viewController, type: .slideFromLeft)
    }

    /// 从下方滑入
    func ls_presentSlideFromBottom(_ viewController: UIViewController) {
        ls_present(viewController, type: .slideFromBottom)
    }

    /// 淡入
    func ls_presentFade(_ viewController: UIViewController) {
        ls_present(viewController, type: .fade)
    }

    /// 缩放
    func ls_presentScale(_ viewController: UIViewController) {
        ls_present(viewController, type: .scale)
    }

    /// 翻转
    func ls_presentFlip(_ viewController: UIViewController) {
        ls_present(viewController, type: .flip)
    }
}

#endif

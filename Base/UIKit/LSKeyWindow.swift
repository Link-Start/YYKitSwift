//
//  LSKeyWindow.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  KeyWindow 工具 - 获取主窗口的便捷方法
//

#if canImport(UIKit)
import UIKit

// MARK: - LSKeyWindow

/// KeyWindow 工具
public enum LSKeyWindow {

    /// 获取 Key Window
    ///
    /// 在 iOS 13+ 使用连接场景的第一个窗口
    /// 在 iOS 13 之前使用 UIApplication.shared.keyWindow
    public static var keyWindow: UIWindow? {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?.windows
                .first { $0.isKeyWindow }
        } else {
            return UIApplication.shared.keyWindow
        }
    }

    /// 获取根视图控制器
    public static var rootViewController: UIViewController? {
        return keyWindow?.rootViewController
    }

    /// 获取顶层视图控制器
    public static var topViewController: UIViewController? {
        return rootViewController?.ls_topViewController
    }

    /// 获取最上层的视图控制器
    public static var visibleViewController: UIViewController? {
        return topViewController?.ls_visibleViewController
    }

    /// 获取窗口尺寸
    public static var bounds: CGRect {
        if let tempValue = keyWindow?.bounds {
            return tempValue
        }
        return .zero
    }

    /// 获取窗口宽度
    public static var width: CGFloat {
        return bounds.width
    }

    /// 获取窗口高度
    public static var height: CGFloat {
        return bounds.height
    }

    /// 安全区域顶部
    public static var safeAreaTop: CGFloat {
        if #available(iOS 11.0, *) {
            if let tempValue = keyWindow?.safeAreaInsets.top {
                return tempValue
            }
            return 0
        }
        return 0
    }

    /// 安全区域底部
    public static var safeAreaBottom: CGFloat {
        if #available(iOS 11.0, *) {
            if let tempValue = keyWindow?.safeAreaInsets.bottom {
                return tempValue
            }
            return 0
        }
        return 0
    }

    /// 安全区域
    public static var safeAreaInsets: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            if let tempValue = keyWindow?.safeAreaInsets {
                return tempValue
            }
            return .zero
        }
        return .zero
    }
}

// MARK: - UIViewController Extension (层级遍历)

public extension UIViewController {

    /// 获取顶层视图控制器
    var ls_topViewController: UIViewController? {
        if let presentedViewController = presentedViewController {
            return presentedViewController.ls_topViewController
        }

        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController?.ls_topViewController
        }

        if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController?.ls_topViewController
        }

        return self
    }

    /// 获取可见的视图控制器
    var ls_visibleViewController: UIViewController? {
        if let presentedViewController = presentedViewController {
            return presentedViewController.ls_visibleViewController
        }

        if let navigationController = self as? UINavigationController {
            if let visibleVC = navigationController.visibleViewController {
                return visibleVC.ls_visibleViewController
            }
        }

        if let tabBarController = self as? UITabBarController {
            if let selectedVC = tabBarController.selectedViewController {
                return selectedVC.ls_visibleViewController
            }
        }

        return self
    }

    /// 遍历所有子视图控制器
    var ls_allChildViewControllers: [UIViewController] {
        var result: [UIViewController] = []

        if let navigationController = self as? UINavigationController {
            result.append(contentsOf: navigationController.viewControllers)
        }

        if let tabBarController = self as? UITabBarController {
            if let viewControllers = tabBarController.viewControllers {
                result.append(contentsOf: viewControllers)
            }
        }

        for child in children {
            result.append(child)
            result.append(contentsOf: child.ls_allChildViewControllers)
        }

        return result
    }

    /// 查找指定类型的视图控制器
    ///
    /// - Parameter type: 视图控制器类型
    /// - Returns: 找到的视图控制器
    func ls_findViewController<T: UIViewController>(of type: T.Type) -> T? {
        if let self = self as? T {
            return self
        }

        for child in children {
            if let found = child.ls_findViewController(of: type) {
                return found
            }
        }

        return nil
    }

    /// 查找指定类型的父视图控制器
    ///
    /// - Parameter type: 视图控制器类型
    /// - Returns: 找到的视图控制器
    func ls_findParentViewController<T: UIViewController>(of type: T.Type) -> T? {
        var current: UIViewController? = parent

        while let viewController = current {
            if let found = viewController as? T {
                return found
            }
            current = viewController.parent
        }

        return nil
    }
}

// MARK: - 便捷方法

public extension LSKeyWindow {

    /// 呈现视图控制器
    ///
    /// - Parameters:
    ///   - viewController: 要呈现的控制器
    ///   - animated: 是否动画
    ///   - completion: 完成回调
    static func present(
        _ viewController: UIViewController,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        guard let topVC = topViewController else { return }
        topVC.present(viewController, animated: animated, completion: completion)
    }

    /// 关闭顶层视图控制器
    ///
    /// - Parameters:
    ///   - animated: 是否动画
    ///   - completion: 完成回调
    static func dismiss(
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        guard let topVC = visibleViewController else { return }
        topVC.dismiss(animated: animated, completion: completion)
    }

    /// 添加子视图控制器
    ///
    /// - Parameter viewController: 要添加的控制器
    static func addChild(_ viewController: UIViewController) {
        guard let rootVC = rootViewController else { return }

        rootVC.addChild(viewController)
        rootVC.view.addSubview(viewController.view)
        viewController.view.frame = rootVC.view.bounds
        viewController.didMove(toParent: rootVC)
    }

    /// 移除子视图控制器
    ///
    /// - Parameter viewController: 要移除的控制器
    static func removeChild(_ viewController: UIViewController) {
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }

    /// 显示提示
    ///
    /// - Parameter message: 提示消息
    static func showHUD(message: String) {
        guard let topVC = visibleViewController else { return }
        MBProgressHUD.show(message, to: topVC.view)
    }

    /// 隐藏提示
    static func hideHUD() {
        guard let topVC = visibleViewController else { return }
        MBProgressHUD.hide(for: topVC.view, animated: true)
    }
}

#endif

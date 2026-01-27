//
//  LSMacros.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//

import Foundation
import UIKit

// MARK: - 宏定义和常量

/// 通用宏定义
public struct LSMacros {

    // MARK: - 屏幕相关

    /// 屏幕宽度
    @inlinable
    public static var screenWidth: CGFloat {
        UIScreen.main.bounds.size.width
    }

    /// 屏幕高度
    @inlinable
    public static var screenHeight: CGFloat {
        UIScreen.main.bounds.size.height
    }

    /// 屏幕比例
    @inlinable
    public static var screenScale: CGFloat {
        UIScreen.main.scale
    }

    // MARK: - 系统版本

    /// iOS 版本
    @inlinable
    public static var systemVersion: String {
        UIDevice.current.systemVersion
    }

    /// 系统版本浮点值
    @inlinable
    public static var systemVersionFloat: Float {
        Float(systemVersion) ?? 0
    }

    // MARK: - 判断 iOS 版本

    /// 是否为 iOS 13.0 及以上
    @inlinable
    public static var isiOS13Later: Bool {
        if #available(iOS 13.0, *) {
            return true
        }
        return false
    }

    /// 是否为 iOS 14.0 及以上
    @inlinable
    public static var isiOS14Later: Bool {
        if #available(iOS 14.0, *) {
            return true
        }
        return false
    }

    /// 是否为 iOS 15.0 及以上
    @inlinable
    public static var isiOS15Later: Bool {
        if #available(iOS 15.0, *) {
            return true
        }
        return false
    }

    /// 是否为 iOS 16.0 及以上
    @inlinable
    public static var isiOS16Later: Bool {
        if #available(iOS 16.0, *) {
            return true
        }
        return false
    }

    /// 是否为 iOS 17.0 及以上
    @inlinable
    public static var isiOS17Later: Bool {
        if #available(iOS 17.0, *) {
            return true
        }
        return false
    }

    // MARK: - 安全区域

    /// 状态栏高度
    @inlinable
    public static var statusBarHeight: CGFloat {
        let window = UIApplication.shared.windows.first ?? UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first ?? UIWindow()
        return window.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
    }

    /// 导航栏高度
    @inlinable
    public static var navigationBarHeight: CGFloat {
        44.0
    }

    /// TabBar 高度
    @inlinable
    public static var tabBarHeight: CGFloat {
        49.0
    }

    /// 底部安全区域高度
    @inlinable
    public static var safeAreaBottom: CGFloat {
        let window = UIApplication.shared.windows.first ?? UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first ?? UIWindow()
        return window.safeAreaInsets.bottom
    }

    // MARK: - 主窗口

    /// 主窗口（iOS 13+ 兼容）
    @inlinable
    public static var keyWindow: UIWindow? {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
        } else {
            return UIApplication.shared.keyWindow
        }
    }

    // MARK: - 代码块执行

    /// 在主线程同步执行代码块
    @inlinable
    public static func dispatchMainThreadSync(_ block: () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.sync(execute: block)
        }
    }

    /// 在主线程异步执行代码块
    @inlinable
    public static func dispatchMainThreadAsync(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }

    /// 延迟执行代码块
    @inlinable
    public static func dispatchAfter(_ delay: TimeInterval, execute block: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: block)
    }
}

// MARK: - 编译条件

/// 模拟器环境判断
@inlinable
public func LSIsSimulator() -> Bool {
    #if targetEnvironment(simulator)
    return true
    #else
    return false
    #endif
}

/// Debug 环境判断
@inlinable
public func LSIsDebug() -> Bool {
    #if DEBUG
    return true
    #else
    return false
    #endif
}

// MARK: - 弱引用包装

/// 弱引用包装类，用于解决循环引用
public final class LSWeakBox<T: AnyObject>: NSObject {

    /// 弱引用的对象
    public weak var value: T?

    public init(_ value: T?) {
        self.value = value
    }
}

// MARK: - 关联对象 Key

/// 关联对象 Key 空间
private var associatedObjectKey: UInt8 = 0

/// 获取关联对象 Key
@inlinable
public func LSAssociatedObjectKey() -> UnsafeRawPointer {
    UnsafeRawPointer(&associatedObjectKey)
}

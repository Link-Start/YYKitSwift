//
//  YYKitSwiftUtility.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-26.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  YYKitSwift 工具模块 - 通用工具类
//

import Foundation
import UIKit

// MARK: - YYKitSwift 工具模块

/// YYKitSwift 工具模块
///
/// 此模块提供各种通用工具类，包括：
/// - 网络状态检测
/// - Keychain 存储
/// - 定时器
/// - GCD 队列和定时器
/// - 文件哈希
/// - 手势识别器
/// - 异步图层
/// - 弱引用代理
///
/// ## 主要组件
///
/// - `LSReachability`: 网络状态检测
/// - `LSKeychain`: Keychain 存储
/// - `LSTimer`: 定时器
/// - `LSGCDQueue`: GCD 队列
/// - `LSGCDTimer`: GCD 定时器
/// - `LSFileHash`: 文件哈希
/// - `LSGestureRecognizer`: 手势识别器
/// - `LSAsyncLayer`: 异步图层
/// - `LSWeakProxy`: 弱引用代理
///
/// ## 使用示例
///
/// ```swift
/// // 网络状态检测
/// let reachability = LSReachability()
/// reachability.startListening()
///
/// // Keychain 存储
/// LSKeychain.setPassword("token", forKey: "auth")
/// let token = LSKeychain.password(forKey: "auth")
///
/// // 定时器
/// let timer = LSTimer(timerInterval: 1.0, repeats: true) {
///     print("Timer fired")
/// }
/// ```
///
/// ## 依赖关系
///
/// - ✅ **完全独立**: 不依赖任何其他 YYKitSwift 模块
/// - ⚠️ **依赖 Core**: 需要引入 YYKitSwiftCore
///
// MARK: - 模块导出

// 网络和存储
@_exported import class YYKitSwift.LSReachability
@_exported import class YYKitSwift.LSKeychain

// 定时器和队列
@_exported import class YYKitSwift.LSTimer
@_exported import class YYKitSwift.LSGCDQueue
@_exported import class YYKitSwift.LSGCDTimer
@_exported import class YYKitSwift.LSDispatchQueuePool

// 文件和哈希
@_exported import class YYKitSwift.LSFileHash
@_exported import class YYKitSwift.LSImageTransformer

// 手势和交互
@_exported import class YYKitSwift.LSGestureRecognizer
@_exported import class YYKitSwift.LSSentinel

// 并发和线程安全
@_exported import class YYKitSwift.LSAsyncLayer
@_exported import class YYKitSwift.LSThreadSafeArray
@_exported import class YYKitSwift.LSThreadSafeDictionary

// 其他工具
@_exported import class YYKitSwift.LSWeakProxy
@_exported import class YYKitSwift.LSTransaction
@_exported import class YYKitSwift.LSLinkHTML

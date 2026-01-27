//
//  YYKitSwiftCore.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-26.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  YYKitSwift 核心模块 - 必须引入的基础模块
//

import Foundation

// MARK: - YYKitSwift 核心模块

/// YYKitSwift 核心模块
///
/// 这是 YYKitSwift 的基础模块，提供了命名空间、宏定义、扩展注册和初始化功能。
/// 所有其他模块都依赖于此模块。
///
/// ## 主要组件
///
/// - `YYKitSwiftNamespace`: 提供 `.ls` 泛型包装器
/// - `LSMacros`: 提供屏幕、版本、安全区域等通用宏定义
/// - `LSExtensions`: 扩展注册器
/// - `YYKitSwift`: 主入口类
///
/// ## 使用示例
///
/// ```swift
/// // 初始化 YYKitSwift
/// YYKitSwift.initialize()
///
/// // 使用命名空间
/// view.ls.width = 100
///
/// // 使用宏定义
/// let width = LSMacros.screenWidth
/// ```
///
/// ## 依赖关系
///
/// - ✅ **完全独立**: 不依赖任何其他 YYKitSwift 模块
/// - ⚠️ **被依赖**: 所有其他模块都依赖此模块
///
// MARK: - 模块导出

// 核心命名空间和协议
@_exported import struct YYKitSwift.YYKitSwiftNamespace
@_exported import protocol YYKitSwift.YYKitSwiftCompatible

// 宏定义和工具
@_exported import struct YYKitSwift.LSMacros
@_exported import func YYKitSwift.LSIsSimulator
@_exported import func YYKitSwift.LSIsDebug
@_exported import class YYKitSwift.LSWeakBox
@_exported import func YYKitSwift.LSAssociatedObjectKey

// 扩展注册
@_exported import class YYKitSwift.LSExtensions
@_exported import protocol YYKitSwift.LSExtensionProtocol
@_exported import enum YYKitSwift.LSExtensionInfo

// 主入口
@_exported import class YYKitSwift.YYKitSwift

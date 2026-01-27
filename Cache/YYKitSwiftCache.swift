//
//  YYKitSwiftCache.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-26.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  YYKitSwift 缓存模块 - 内存缓存和磁盘缓存
//

import Foundation

// MARK: - YYKitSwift 缓存模块

/// YYKitSwift 缓存模块
///
/// 此模块提供高效的内存缓存和磁盘缓存功能，支持：
/// - LRU (最近最少使用) 淘汰策略
/// - 线程安全的读写操作
/// - 自动清理和回收
/// - SQLite + 文件系统混合存储
///
/// ## 主要组件
///
/// - `LSCache`: 统一缓存接口
/// - `LSMemoryCache`: 内存缓存（基于 LRU）
/// - `LSDiskCache`: 磁盘缓存（基于 SQLite）
/// - `LSKVStorage`: SQLite 存储层
///
/// ## 使用示例
///
/// ```swift
/// // 内存缓存
/// let memoryCache = LSMemoryCache()
/// memoryCache.setObject("value", forKey: "key")
/// let value = memoryCache.object(forKey: "key")
///
/// // 磁盘缓存
/// let diskCache = LSDiskCache(path: path)
/// diskCache.writeObject(data, forKey: "key")
/// let data = diskCache.readObject(forKey: "key")
/// ```
///
/// ## 依赖关系
///
/// - ⚠️ **依赖 Core**: 需要引入 YYKitSwiftCore
/// - ⚠️ **被依赖**: Image 模块依赖此模块
///
// MARK: - 模块导出

// 统一缓存接口
@_exported import protocol YYKitSwift.LSCache

// 内存缓存
@_exported import class YYKitSwift.LSMemoryCache

// 磁盘缓存
@_exported import class YYKitSwift.LSDiskCache

// SQLite 存储层
@_exported import class YYKitSwift.LSKVStorage

//
//  YYKitSwiftModel.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-26.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  YYKitSwift 模型转换模块 - JSON 转换和运行时反射
//

import Foundation

// MARK: - YYKitSwift 模型转换模块

/// YYKitSwift 模型转换模块
///
/// 此模块提供 JSON 转换和运行时反射功能，支持：
/// - JSON 字典转模型
/// - 模型转 JSON 字典
/// - 运行时类信息获取
/// - 枚举扩展
///
/// ## 主要组件
///
/// - `LSModel`: JSON 转换协议和实现
/// - `LSClassInfo`: 运行时类信息
/// - `LSEnum`: 枚举扩展
///
/// ## 使用示例
///
/// ```swift
/// // 定义模型
/// struct User: LSModel {
///     var name: String
///     var age: Int
/// }
///
/// // JSON 转模型
/// let user = User.ls_model(with: jsonDict)
///
/// // 模型转 JSON
/// let json = user.ls_modelJSONObject()
/// ```
///
/// ## 依赖关系
///
/// - ✅ **完全独立**: 不依赖任何其他 YYKitSwift 模块
/// - ⚠️ **依赖 Core**: 需要引入 YYKitSwiftCore
///
// MARK: - 模块导出

// 运行时类信息
@_exported import class YYKitSwift.LSClassInfo

// 枚举扩展
@_exported import enum YYKitSwift.LSEnum

// 模型转换
@_exported import protocol YYKitSwift.LSModel

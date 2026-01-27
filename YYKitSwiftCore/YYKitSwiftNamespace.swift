//
//  YYKitSwiftNamespace.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-26.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  YYKitSwift 命名空间 - 提供 .ls 泛型包装器
//

import Foundation

// MARK: - YYKitSwift 泛型包装器

/// YYKitSwift 泛型包装器
/// 提供类型安全的命名空间扩展，避免方法名冲突
public struct YYKitSwift<Base> {

    /// 被包装的基础对象
    public let base: Base

    /// 初始化包装器
    /// - Parameter base: 被包装的基础对象
    @inlinable
    public init(_ base: Base) {
        self.base = base
    }
}

// MARK: - YYKitSwiftCompatible 协议

/// YYKitSwift 兼容协议
/// 遵循此协议的类型会自动获得 `.ls` 命名空间
public protocol YYKitSwiftCompatible {

    /// 关联类型
    associatedtype CompatibleType

    /// YYKitSwift 命名空间（使用 .ls 而非 .yy，符合项目规范）
    var ls: YYKitSwift<CompatibleType> { get }
}

// MARK: - 默认实现

/// 为 YYKitSwiftCompatible 协议提供默认的 `.ls` 属性实现
public extension YYKitSwiftCompatible {

    /// YYKitSwift 命名空间
    var ls: YYKitSwift<Self> {
        get { YYKitSwift(self) }
    }
}

// MARK: - 为常用类型添加兼容性

/// 让所有 NSObject 子类自动获得 `.ls` 属性
extension NSObject: YYKitSwiftCompatible {}

/// 让 String 类型获得 `.ls` 属性
extension String: YYKitSwiftCompatible {}

/// 让 Array 类型获得 `.ls` 属性
extension Array: YYKitSwiftCompatible {}

/// 让 Dictionary 类型获得 `.ls` 属性
extension Dictionary: YYKitSwiftCompatible {}

/// 让 Set 类型获得 `.ls` 属性
extension Set: YYKitSwiftCompatible {}

// MARK: - 使用示例

/*
 使用 .ls 命名空间可以避免方法名冲突，并提供更好的代码组织：

 ```swift
 // 传统方式（ls_ 前缀）
 button.ls_setContentLayoutStyle(.centerImageTop, spacing: 8)

 // 命名空间方式（.ls）
 button.ls.setContentLayoutStyle(.centerImageTop, spacing: 8)

 // 两种方式可以共存，项目根据需要选择使用
 ```
 */

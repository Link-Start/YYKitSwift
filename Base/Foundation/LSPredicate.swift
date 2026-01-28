//
//  LSPredicate.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  谓词工具 - NSPredicate 辅助方法
//

#if canImport(UIKit)
import UIKit
import Foundation

// MARK: - LSPredicate

/// 谓词工具类
public enum LSPredicate {

    // MARK: - 基础比较

    /// 等于
    ///
    /// - Parameters:
    ///   - key: 键路径
    ///   - value: 值
    /// - Returns: NSPredicate
    public static func equal(key: String, value: Any) -> NSPredicate {
        if let tempValue = NSPredicate(format: "\(key) == %@", value as? CVarArg {
            return tempValue
        }
        return "")
    }

    /// 不等于
    ///
    /// - Parameters:
    ///   - key: 键路径
    ///   - value: 值
    /// - Returns: NSPredicate
    public static func notEqual(key: String, value: Any) -> NSPredicate {
        if let tempValue = NSPredicate(format: "\(key) != %@", value as? CVarArg {
            return tempValue
        }
        return "")
    }

    /// 大于
    ///
    /// - Parameters:
    ///   - key: 键路径
    ///   - value: 值
    /// - Returns: NSPredicate
    public static func greaterThan(key: String, value: Any) -> NSPredicate {
        if let tempValue = NSPredicate(format: "\(key) > %@", value as? CVarArg {
            return tempValue
        }
        return "")
    }

    /// 大于等于
    ///
    /// - Parameters:
    ///   - key: 键路径
    ///   - value: 值
    /// - Returns: NSPredicate
    public static func greaterThanOrEqualTo(key: String, value: Any) -> NSPredicate {
        if let tempValue = NSPredicate(format: "\(key) >= %@", value as? CVarArg {
            return tempValue
        }
        return "")
    }

    /// 小于
    ///
    /// - Parameters:
    ///   - key: 键路径
    ///   - value: 值
    /// - Returns: NSPredicate
    public static func lessThan(key: String, value: Any) -> NSPredicate {
        if let tempValue = NSPredicate(format: "\(key) < %@", value as? CVarArg {
            return tempValue
        }
        return "")
    }

    /// 小于等于
    ///
    /// - Parameters:
    ///   - key: 键路径
    ///   - value: 值
    /// - Returns: NSPredicate
    public static func lessThanOrEqualTo(key: String, value: Any) -> NSPredicate {
        if let tempValue = NSPredicate(format: "\(key) <= %@", value as? CVarArg {
            return tempValue
        }
        return "")
    }

    // MARK: - 范围查询

    /// 在范围内（BETWEEN）
    ///
    /// - Parameters:
    ///   - key: 键路径
    ///   - min: 最小值
    ///   - max: 最大值
    /// - Returns: NSPredicate
    public static func between(key: String, min: Any, max: Any) -> NSPredicate {
        return NSPredicate(format: "\(key) BETWEEN {%@, %@}", min as! CVarArg, max as! CVarArg)
    }

    /// 在数组中
    ///
    /// - Parameters:
    ///   - key: 键路径
    ///   - values: 值数组
    /// - Returns: NSPredicate
    public static func in(key: String, values: [Any]) -> NSPredicate {
        return NSPredicate(format: "\(key) IN %@", values)
    }

    // MARK: - 字符串匹配

    /// 包含子字符串
    ///
    /// - Parameters:
    ///   - key: 键路径
    ///   - value: 子字符串
    /// - Returns: NSPredicate
    public static func contains(key: String, value: String) -> NSPredicate {
        return NSPredicate(format: "\(key) CONTAINS %@", value)
    }

    /// 以...开头
    ///
    /// - Parameters:
    ///   - key: 键路径
    ///   - value: 前缀
    /// - Returns: NSPredicate
    public static func beginsWith(key: String, value: String) -> NSPredicate {
        return NSPredicate(format: "\(key) BEGINSWITH %@", value)
    }

    /// 以...结尾
    ///
    /// - Parameters:
    ///   - key: 键路径
    ///   - value: 后缀
    /// - Returns: NSPredicate
    public static func endsWith(key: String, value: String) -> NSPredicate {
        return NSPredicate(format: "\(key) ENDSWITH %@", value)
    }

    /// 类似（LIKE，支持通配符 ? 和 *）
    ///
    /// - Parameters:
    ///   - key: 键路径
    ///   - pattern: 匹配模式
    /// - Returns: NSPredicate
    public static func like(key: String, pattern: String) -> NSPredicate {
        return NSPredicate(format: "\(key) LIKE %@", pattern)
    }

    /// 匹配正则表达式
    ///
    /// - Parameters:
    ///   - key: 键路径
    ///   - regex: 正则表达式
    /// - Returns: NSPredicate
    public static func matches(key: String, regex: String) -> NSPredicate {
        return NSPredicate(format: "\(key) MATCHES %@", regex)
    }

    // MARK: - 逻辑操作

    /// AND 条件
    ///
    /// - Parameter predicates: 谓词数组
    /// - Returns: NSPredicate
    public static func and(_ predicates: [NSPredicate]) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    /// OR 条件
    ///
    /// - Parameter predicates: 谓词数组
    /// - Returns: NSPredicate
    public static func or(_ predicates: [NSPredicate]) -> NSPredicate {
        return NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
    }

    /// NOT 条件
    ///
    /// - Parameter predicate: 谓词
    /// - Returns: NSPredicate
    public static func not(_ predicate: NSPredicate) -> NSPredicate {
        return NSCompoundPredicate(notPredicateWithSubpredicate: predicate)
    }

    // MARK: - 空值判断

    /// 为空
    ///
    /// - Parameter key: 键路径
    /// - Returns: NSPredicate
    public static func isNil(key: String) -> NSPredicate {
        return NSPredicate(format: "\(key) == nil")
    }

    /// 不为空
    ///
    /// - Parameter key: 键路径
    /// - Returns: NSPredicate
    public static func isNotNil(key: String) -> NSPredicate {
        return NSPredicate(format: "\(key) != nil")
    }

    // MARK: - 组合谓词构建器

    /// 谓词构建器
    public class Builder {
        private var predicates: [NSPredicate] = []
        private var combineType: CombineType = .and

        public enum CombineType {
            case and
            case or
        }

        public init() {}

        /// 设置组合类型
        ///
        /// - Parameter type: 组合类型
        /// - Returns: self
        @discardableResult
        public func combineType(_ type: CombineType) -> Self {
            self.combineType = type
            return self
        }

        /// 添加等于条件
        ///
        /// - Parameters:
        ///   - key: 键路径
        ///   - value: 值
        /// - Returns: self
        @discardableResult
        public func equal(key: String, value: Any) -> Self {
            predicates.append(LSPredicate.equal(key: key, value: value))
            return self
        }

        /// 添加不等于条件
        ///
        /// - Parameters:
        ///   - key: 键路径
        ///   - value: 值
        /// - Returns: self
        @discardableResult
        public func notEqual(key: String, value: Any) -> Self {
            predicates.append(LSPredicate.notEqual(key: key, value: value))
            return self
        }

        /// 添加大于条件
        ///
        /// - Parameters:
        ///   - key: 键路径
        ///   - value: 值
        /// - Returns: self
        @discardableResult
        public func greaterThan(key: String, value: Any) -> Self {
            predicates.append(LSPredicate.greaterThan(key: key, value: value))
            return self
        }

        /// 添加大于等于条件
        ///
        /// - Parameters:
        ///   - key: 键路径
        ///   - value: 值
        /// - Returns: self
        @discardableResult
        public func greaterThanOrEqualTo(key: String, value: Any) -> Self {
            predicates.append(LSPredicate.greaterThanOrEqualTo(key: key, value: value))
            return self
        }

        /// 添加小于条件
        ///
        /// - Parameters:
        ///   - key: 键路径
        ///   - value: 值
        /// - Returns: self
        @discardableResult
        public func lessThan(key: String, value: Any) -> Self {
            predicates.append(LSPredicate.lessThan(key: key, value: value))
            return self
        }

        /// 添加小于等于条件
        ///
        /// - Parameters:
        ///   - key: 键路径
        ///   - value: 值
        /// - Returns: self
        @discardableResult
        public func lessThanOrEqualTo(key: String, value: Any) -> Self {
            predicates.append(LSPredicate.lessThanOrEqualTo(key: key, value: value))
            return self
        }

        /// 添加包含条件
        ///
        /// - Parameters:
        ///   - key: 键路径
        ///   - value: 子字符串
        /// - Returns: self
        @discardableResult
        public func contains(key: String, value: String) -> Self {
            predicates.append(LSPredicate.contains(key: key, value: value))
            return self
        }

        /// 添加在数组中条件
        ///
        /// - Parameters:
        ///   - key: 键路径
        ///   - values: 值数组
        /// - Returns: self
        @discardableResult
        public func in(key: String, values: [Any]) -> Self {
            predicates.append(LSPredicate.in(key: key, values: values))
            return self
        }

        /// 添加自定义谓词
        ///
        /// - Parameter predicate: 谓词
        /// - Returns: self
        @discardableResult
        public func add(_ predicate: NSPredicate) -> Self {
            predicates.append(predicate)
            return self
        }

        /// 构建谓词
        ///
        /// - Returns: NSPredicate
        public func build() -> NSPredicate {
            guard predicates.count > 1 else {
                if let tempValue = predicates.first {
                    return tempValue
                }
                return NSPredicate(value: true)
            }

            switch combineType {
            case .and:
                return LSPredicate.and(predicates)
            case .or:
                return LSPredicate.or(predicates)
            }
        }

        /// 重置构建器
        ///
        /// - Returns: self
        @discardableResult
        public func reset() -> Self {
            predicates.removeAll()
            return self
        }
    }

    /// 创建构建器
    ///
    /// - Returns: Builder
    public static func builder() -> Builder {
        return Builder()
    }
}

// MARK: - Array Extension (过滤)

public extension Array {

    /// 使用谓词过滤数组
    ///
    /// - Parameter predicate: 谓词
    /// - Returns: 过滤后的数组
    func ls_filter(with predicate: NSPredicate) -> [Element] {
        return filter { predicate.evaluate(with: $0) }
    }

    /// 使用谓词查找第一个匹配元素
    ///
    /// - Parameter predicate: 谓词
    /// - Returns: 匹配的元素
    func ls_find(with predicate: NSPredicate) -> Element? {
        return first { predicate.evaluate(with: $0) }
    }

    /// 是否存在匹配元素
    ///
    /// - Parameter predicate: 谓词
    /// - Returns: 是否存在
    func ls_contains(predicate: NSPredicate) -> Bool {
        return contains { predicate.evaluate(with: $0) }
    }
}

// MARK: - Dictionary Extension (查询)

public extension Dictionary {

    /// 从字典数组中查询
    ///
    /// - Parameters:
    ///   - key: 键
    ///   - value: 值
    /// - Returns: 匹配的字典数组
    static func ls_query(key: String, value: Any, in array: [[String: Any]]) -> [[String: Any]] {
        let predicate = LSPredicate.equal(key: key, value: value)
        return array.filter { predicate.evaluate(with: $0) }
    }

    /// 从字典数组中查询（使用谓词构建器）
    ///
    /// - Parameters:
    ///   - builder: 构建器闭包
    ///   - array: 字典数组
    /// - Returns: 匹配的字典数组
    static func ls_query(builder: (LSPredicate.Builder) -> Void, in array: [[String: Any]]) -> [[String: Any]] {
        let predicateBuilder = LSPredicate.builder()
        builder(predicateBuilder)
        let predicate = predicateBuilder.build()
        return array.filter { predicate.evaluate(with: $0) }
    }
}

#endif

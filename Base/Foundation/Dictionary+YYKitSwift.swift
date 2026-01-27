//
//  Dictionary+YYKitSwift.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  Dictionary 扩展，提供常用方法
//

import Foundation

// MARK: - Dictionary 扩展

public extension Dictionary {

    // MARK: - Plist 序列化

    /// 从 Plist 数据创建 Dictionary
    static func ls_plist(_ plist: Data) -> [Key: Value]? {
        return (try? PropertyListSerialization.propertyList(from: plist, options: [], format: nil)) as? [Key: Value]
    }

    /// 从 Plist 字符串创建 Dictionary
    static func ls_plistString(_ plistString: String) -> [Key: Value]? {
        guard let data = plistString.data(using: .utf8) else { return nil }
        return ls_plist(data)
    }

    /// 序列化为 Plist 数据
    func ls_plistData() -> Data? {
        return try? PropertyListSerialization.data(fromPropertyList: self, format: .binary, options: 0)
    }

    /// 序列化为 Plist 字符串
    func ls_plistString() -> String? {
        guard let data = ls_plistData() else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - 排序

    /// 返回排序后的所有键（假设 Key 是 String）
    var ls_allKeysSorted: [Key] {
        guard let stringKeys = self as? [String: Any] else { return Array(keys) }
        return stringKeys.keys.sorted() as! [Key]
    }

    /// 返回按键排序后的所有值
    var ls_allValuesSortedByKeys: [Value] {
        guard let stringKeys = self as? [String: Any] else { return Array(values) }
        let sortedKeys = stringKeys.keys.sorted()
        return sortedKeys.compactMap { stringKeys[$0] as? Value }
    }

    // MARK: - 查询

    /// 是否包含指定键
    func ls_contains(key: Key) -> Bool {
        return index(forKey: key) != nil
    }

    /// 返回指定键对应的条目
    func ls_entries(forKeys keys: [Key]) -> [Key: Value] {
        var result: [Key: Value] = [:]
        for key in keys {
            if let value = self[key] {
                result[key] = value
            }
        }
        return result
    }

    // MARK: - JSON 序列化

    /// 转换为 JSON 字符串
    func ls_jsonString() -> String? {
        guard let validSelf = self as? [String: Any] else { return nil }
        guard JSONSerialization.isValidJSONObject(validSelf) else { return nil }
        guard let data = try? JSONSerialization.data(withJSONObject: validSelf, options: []) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// 转换为格式化的 JSON 字符串
    func ls_jsonPrettyString() -> String? {
        guard let validSelf = self as? [String: Any] else { return nil }
        guard JSONSerialization.isValidJSONObject(validSelf) else { return nil }
        guard let data = try? JSONSerialization.data(withJSONObject: validSelf, options: [.prettyPrinted]) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - XML 解析

    /// 从 XML 数据解析为 Dictionary
    /// 注意：这是一个简化的实现，完整 XML 解析需要更多工作
    static func ls_xml(_ xml: Any) -> [Key: Value]? {
        // XML 解析较为复杂，这里返回 nil
        // 如需完整实现，需要使用 XMLParser 进行解析
        return nil
    }
}

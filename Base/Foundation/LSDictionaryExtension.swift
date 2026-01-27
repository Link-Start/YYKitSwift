//
//  LSDictionaryExtension.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  字典扩展 - 提供常用的字典操作方法
//

#if canImport(UIKit)
import UIKit
import Foundation

// MARK: - Dictionary Extension

public extension Dictionary {

    // MARK: - 安全访问

    /// 安全获取键值
    ///
    /// - Parameter key: 键
    /// - Returns: 值（如果键存在）
    subscript(safe key: Key) -> Value? {
        return self[key]
    }

    // MARK: - 类型安全获取

    /// 获取字符串值
    func ls_string(forKey key: Key) -> String? {
        return self[key] as? String
    }

    /// 获取整数值
    func ls_int(forKey key: Key) -> Int? {
        if let intValue = self[key] as? Int {
            return intValue
        } else if let stringValue = self[key] as? String,
                  let intValue = Int(stringValue) {
            return intValue
        } else if let numberValue = self[key] as? NSNumber {
            return numberValue.intValue
        }
        return nil
    }

    /// 获取浮点数值
    func ls_double(forKey key: Key) -> Double? {
        if let doubleValue = self[key] as? Double {
            return doubleValue
        } else if let stringValue = self[key] as? String,
                  let doubleValue = Double(stringValue) {
            return doubleValue
        } else if let numberValue = self[key] as? NSNumber {
            return numberValue.doubleValue
        }
        return nil
    }

    /// 获取布尔值
    func ls_bool(forKey key: Key) -> Bool? {
        if let boolValue = self[key] as? Bool {
            return boolValue
        } else if let numberValue = self[key] as? NSNumber {
            return numberValue.boolValue
        } else if let stringValue = self[key] as? String {
            if let intValue = Int(stringValue) {
                return intValue != 0
            }
            return stringValue.lowercased() == "true"
        }
        return nil
    }

    /// 获取数组值
    func ls_array(forKey key: Key) -> [Any]? {
        return self[key] as? [Any]
    }

    /// 获取字典值
    func ls_dictionary(forKey key: Key) -> [String: Any]? {
        return self[key] as? [String: Any]
    }

    /// 获取 URL 值
    func ls_url(forKey key: Key) -> URL? {
        if let urlValue = self[key] as? URL {
            return urlValue
        } else if let stringValue = self[key] as? String {
            return URL(string: stringValue)
        }
        return nil
    }

    // MARK: - 默认值

    /// 获取字符串值（带默认值）
    func ls_string(forKey key: Key, default defaultValue: String) -> String {
        return ls_string(forKey: key) ?? defaultValue
    }

    /// 获取整数值（带默认值）
    func ls_int(forKey key: Key, default defaultValue: Int) -> Int {
        return ls_int(forKey: key) ?? defaultValue
    }

    /// 获取浮点数值（带默认值）
    func ls_double(forKey key: Key, default defaultValue: Double) -> Double {
        return ls_double(forKey: key) ?? defaultValue
    }

    /// 获取布尔值（带默认值）
    func ls_bool(forKey key: Key, default defaultValue: Bool) -> Bool {
        return ls_bool(forKey: key) ?? defaultValue
    }

    // MARK: - 键操作

    /// 获取所有键
    var ls_keys: [Key] {
        return Array(keys)
    }

    /// 获取所有值
    var ls_values: [Value] {
        return Array(values)
    }

    /// 是否包含键
    func ls_contains(key: Key) -> Bool {
        return self[key] != nil
    }

    // MARK: - 合并

    /// 合并字典
    ///
    /// - Parameter other: 另一个字典
    /// - Returns: 合并后的新字典
    func ls_merged(_ other: [Key: Value]) -> [Key: Value] {
        var result = self
        for (key, value) in other {
            result[key] = value
        }
        return result
    }

    /// 合并字典（in-place）
    mutating func ls_merge(_ other: [Key: Value]) {
        for (key, value) in other {
            self[key] = value
        }
    }

    // MARK: - 映射

    /// 映射键
    ///
    /// - Parameter transform: 转换闭包
    /// - Returns: 新字典
    func ls_mapKeys<T: Hashable>(_ transform: (Key) -> T) -> [T: Value] {
        var result: [T: Value] = [:]
        for (key, value) in self {
            result[transform(key)] = value
        }
        return result
    }

    /// 映射值
    ///
    /// - Parameter transform: 转换闭包
    /// - Returns: 新字典
    func ls_mapValues<T>(_ transform: (Value) -> T) -> [Key: T] {
        var result: [Key: T] = [:]
        for (key, value) in self {
            result[key] = transform(value)
        }
        return result
    }

    /// 映射键值对
    ///
    /// - Parameter transform: 转换闭包
    /// - Returns: 新字典
    func ls_map<K: Hashable, V>(_ transform: (Key, Value) -> (K, V)) -> [K: V] {
        var result: [K: V] = [:]
        for (key, value) in self {
            let (newKey, newValue) = transform(key, value)
            result[newKey] = newValue
        }
        return result
    }

    // MARK: - 过滤

    /// 过滤键值对
    ///
    /// - Parameter isIncluded: 包含条件
    /// - Returns: 过滤后的字典
    func ls_filter(_ isIncluded: (Key, Value) -> Bool) -> [Key: Value] {
        var result: [Key: Value] = [:]
        for (key, value) in self {
            if isIncluded(key, value) {
                result[key] = value
            }
        }
        return result
    }

    // MARK: - 分组

    /// 按值分组
    ///
    /// - Parameter keyPath: 值的 KeyPath
    /// - Returns: 分组后的字典
    func ls_grouped<T: Hashable>(by keyPath: KeyPath<Value, T>) -> [T: [(Key, Value)]] {
        var result: [T: [(Key, Value)]] = [:]
        for (key, value) in self {
            let group = value[keyPath: keyPath]
            result[group, default: []].append((key, value))
        }
        return result
    }
}

// MARK: - Dictionary Extension (JSON)

public extension Dictionary {

    /// 转换为 JSON 字符串
    ///
    /// - Parameter prettyPrinted: 是否格式化
    /// - Returns: JSON 字符串
    func ls_jsonString(prettyPrinted: Bool = false) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: self, options: .fragmentsAllowed) else {
            return nil
        }

        if prettyPrinted {
            return String(data: data, encoding: .utf8)
        }

        return String(data: data, encoding: .utf8)?
            .replacingOccurrences(of: "\\", with: "")
            .replacingOccurrences(of: "\n", with: "")
    }

    /// 从 JSON 字符串初始化
    init?(ls_jsonString: String) {
        guard let data = ls_jsonString.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [Key: Value] else {
            return nil
        }
        self = dict
    }
}

// MARK: - Dictionary Extension (查询字符串)

public extension Dictionary where Key == String, Value == String {

    /// 转换为查询字符串
    ///
    /// - Returns: 查询字符串（如: key1=value1&key2=value2）
    var ls_queryString: String {
        let components = map { "\($0.key)=\($0.value.ls_urlEncoded ?? "")" }
        return components.joined(separator: "&")
    }

    /// 从查询字符串初始化
    ///
    /// - Parameter queryString: 查询字符串
    init?(ls_queryString: String) {
        var result: [String: String] = [:]

        let pairs = queryString.components(separatedBy: "&")
        for pair in pairs {
            let components = pair.components(separatedBy: "=")
            guard components.count == 2 else { continue }

            let key = components[0].ls_urlDecoded ?? components[0]
            let value = components[1].ls_urlDecoded ?? components[1]

            result[key] = value
        }

        self = result
    }
}

// MARK: - Dictionary Extension (Codable)

public extension Dictionary where Key: Codable, Value: Codable {

    /// 转换为 JSON Data
    func ls_jsonData() -> Data? {
        return try? JSONEncoder().encode(self)
    }

    /// 从 JSON Data 初始化
    init?(ls_jsonData: Data) {
        guard let dict = try? JSONDecoder().decode([Key: Value].self, from: ls_jsonData) else {
            return nil
        }
        self = dict
    }
}

// MARK: - Dictionary Extension (URL 参数)

public extension Dictionary where Key == String {

    /// 转换为 URL 参数字符串
    ///
    /// - Returns: URL 参数字符串
    var ls_urlParameters: String {
        let components = compactMap { (key, value) -> String? in
            guard let key = key.ls_urlEncoded else { return nil }

            var stringValue: String
            if let strValue = value as? String {
                stringValue = strValue
            } else if let numValue = value as? NSNumber {
                stringValue = numValue.stringValue
            } else {
                return nil
            }

            guard let encodedValue = stringValue.ls_urlEncoded else { return nil }
            return "\(key)=\(encodedValue)"
        }

        return components.joined(separator: "&")
    }
}

#endif

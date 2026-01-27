//
//  LSUserDefaults.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  UserDefaults 工具 - 类型安全的偏好设置存储
//

#if canImport(UIKit)
import UIKit
import Foundation

// MARK: - LSUserDefaults

/// UserDefaults 工具类 - 提供类型安全的存取方法
public enum LSUserDefaults {

    // MARK: - 默认实例

    /// 标准 UserDefaults
    public static let standard = LSUserDefaultsStore(suiteName: nil)

    /// 获取自定义 UserDefaults
    ///
    /// - Parameter suiteName: Suite 名称
    /// - Returns: UserDefaults 实例
    public static func custom(suiteName: String) -> LSUserDefaultsStore {
        return LSUserDefaultsStore(suiteName: suiteName)
    }
}

// MARK: - LSUserDefaultsStore

/// UserDefaults 存储类
public class LSUserDefaultsStore {

    // MARK: - 属性

    /// 底层 UserDefaults 实例
    public let userDefaults: UserDefaults

    // MARK: - 初始化

    /// 创建存储实例
    ///
    /// - Parameter suiteName: Suite 名称（nil 为标准 UserDefaults）
    public init(suiteName: String?) {
        if let suiteName = suiteName {
            self.userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
        } else {
            self.userDefaults = .standard
        }
    }

    // MARK: - 通用方法

    /// 设置值
    ///
    /// - Parameters:
    ///   - value: 值
    ///   - key: 键
    public func set(_ value: Any?, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    /// 获取值
    ///
    /// - Parameter key: 键
    /// - Returns: 值
    public func value(forKey key: String) -> Any? {
        return userDefaults.value(forKey: key)
    }

    /// 移除值
    ///
    /// - Parameter key: 键
    public func removeObject(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }

    /// 是否包含键
    ///
    /// - Parameter key: 键
    /// - Returns: 是否包含
    public func contains(key: String) -> Bool {
        return userDefaults.object(forKey: key) != nil
    }

    /// 清空所有数据
    public func clearAll() {
        let dictionary = userDefaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            userDefaults.removeObject(forKey: key)
        }
    }

    /// 同步
    public func synchronize() -> Bool {
        return userDefaults.synchronize()
    }

    // MARK: - Bool

    /// 保存 Bool 值
    ///
    /// - Parameters:
    ///   - value: 值
    ///   - key: 键
    public func setBool(_ value: Bool, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    /// 获取 Bool 值
    ///
    /// - Parameters:
    ///   - key: 键
    ///   - defaultValue: 默认值
    /// - Returns: Bool 值
    public func bool(forKey key: String, defaultValue: Bool = false) -> Bool {
        if contains(key: key) {
            return userDefaults.bool(forKey: key)
        }
        return defaultValue
    }

    // MARK: - Int

    /// 保存 Int 值
    ///
    /// - Parameters:
    ///   - value: 值
    ///   - key: 键
    public func setInt(_ value: Int, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    /// 获取 Int 值
    ///
    /// - Parameters:
    ///   - key: 键
    ///   - defaultValue: 默认值
    /// - Returns: Int 值
    public func int(forKey key: String, defaultValue: Int = 0) -> Int {
        if contains(key: key) {
            return userDefaults.integer(forKey: key)
        }
        return defaultValue
    }

    // MARK: - Float

    /// 保存 Float 值
    ///
    /// - Parameters:
    ///   - value: 值
    ///   - key: 键
    public func setFloat(_ value: Float, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    /// 获取 Float 值
    ///
    /// - Parameters:
    ///   - key: 键
    ///   - defaultValue: 默认值
    /// - Returns: Float 值
    public func float(forKey key: String, defaultValue: Float = 0) -> Float {
        if contains(key: key) {
            return userDefaults.float(forKey: key)
        }
        return defaultValue
    }

    // MARK: - Double

    /// 保存 Double 值
    ///
    /// - Parameters:
    ///   - value: 值
    ///   - key: 键
    public func setDouble(_ value: Double, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    /// 获取 Double 值
    ///
    /// - Parameters:
    ///   - key: 键
    ///   - defaultValue: 默认值
    /// - Returns: Double 值
    public func double(forKey key: String, defaultValue: Double = 0) -> Double {
        if contains(key: key) {
            return userDefaults.double(forKey: key)
        }
        return defaultValue
    }

    // MARK: - String

    /// 保存 String 值
    ///
    /// - Parameters:
    ///   - value: 值
    ///   - key: 键
    public func setString(_ value: String, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    /// 获取 String 值
    ///
    /// - Parameters:
    ///   - key: 键
    ///   - defaultValue: 默认值
    /// - Returns: String 值
    public func string(forKey key: String, defaultValue: String = "") -> String {
        if contains(key: key) {
            return userDefaults.string(forKey: key) ?? defaultValue
        }
        return defaultValue
    }

    // MARK: - Date

    /// 保存 Date 值
    ///
    /// - Parameters:
    ///   - value: 值
    ///   - key: 键
    public func setDate(_ value: Date, forKey key: String) {
        userDefaults.set(value.timeIntervalSince1970, forKey: key)
    }

    /// 获取 Date 值
    ///
    /// - Parameters:
    ///   - key: 键
    ///   - defaultValue: 默认值
    /// - Returns: Date 值
    public func date(forKey key: String, defaultValue: Date = Date()) -> Date {
        if contains(key: key) {
            let timestamp = userDefaults.double(forKey: key)
            return Date(timeIntervalSince1970: timestamp)
        }
        return defaultValue
    }

    // MARK: - Data

    /// 保存 Data 值
    ///
    /// - Parameters:
    ///   - value: 值
    ///   - key: 键
    public func setData(_ value: Data, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    /// 获取 Data 值
    ///
    /// - Parameter key: 键
    /// - Returns: Data 值
    public func data(forKey key: String) -> Data? {
        return userDefaults.data(forKey: key)
    }

    // MARK: - Array

    /// 保存 Array 值
    ///
    /// - Parameters:
    ///   - value: 值
    ///   - key: 键
    public func setArray(_ value: [Any], forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    /// 获取 Array 值
    ///
    /// - Parameter key: 键
    /// - Returns: Array 值
    public func array(forKey key: String) -> [Any]? {
        return userDefaults.array(forKey: key)
    }

    // MARK: - Dictionary

    /// 保存 Dictionary 值
    ///
    /// - Parameters:
    ///   - value: 值
    ///   - key: 键
    public func setDictionary(_ value: [String: Any], forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    /// 获取 Dictionary 值
    ///
    /// - Parameter key: 键
    /// - Returns: Dictionary 值
    public func dictionary(forKey key: String) -> [String: Any]? {
        return userDefaults.dictionary(forKey: key)
    }

    // MARK: - URL

    /// 保存 URL 值
    ///
    /// - Parameters:
    ///   - value: 值
    ///   - key: 键
    public func setURL(_ value: URL, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    /// 获取 URL 值
    ///
    /// - Parameter key: 键
    /// - Returns: URL 值
    public func url(forKey key: String) -> URL? {
        return userDefaults.url(forKey: key)
    }

    // MARK: - Codable

    /// 保存 Codable 对象
    ///
    /// - Parameters:
    ///   - value: 值
    ///   - key: 键
    /// - Throws: 编码错误
    public func setCodable<T: Codable>(_ value: T, forKey key: String) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        userDefaults.set(data, forKey: key)
    }

    /// 获取 Codable 对象
    ///
    /// - Parameters:
    ///   - key: 键
    ///   - type: 对象类型
    /// - Returns: Codable 对象
    /// - Throws: 解码错误
    public func codable<T: Codable>(forKey key: String, type: T.Type) throws -> T? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }

    // MARK: - 批量操作

    /// 批量设置值
    ///
    /// - Parameter values: 键值对字典
    public func setValues(_ values: [String: Any]) {
        for (key, value) in values {
            set(value, forKey: key)
        }
    }

    /// 批量获取值
    ///
    /// - Parameter keys: 键数组
    /// - Returns: 键值对字典
    public func values(forKeys keys: [String]) -> [String: Any] {
        var result: [String: Any] = [:]
        for key in keys {
            if let value = value(forKey: key) {
                result[key] = value
            }
        }
        return result
    }

    /// 批量移除值
    ///
    /// - Parameter keys: 键数组
    public func removeObjects(forKeys keys: [String]) {
        for key in keys {
            removeObject(forKey: key)
        }
    }

    // MARK: - 下标访问

    /// 下标访问 Bool
    public subscript(boolKey key: String) -> Bool? {
        get {
            guard contains(key: key) else { return nil }
            return bool(forKey: key)
        }
        set {
            if let value = newValue {
                setBool(value, forKey: key)
            } else {
                removeObject(forKey: key)
            }
        }
    }

    /// 下标访问 Int
    public subscript(intKey key: String) -> Int? {
        get {
            guard contains(key: key) else { return nil }
            return int(forKey: key)
        }
        set {
            if let value = newValue {
                setInt(value, forKey: key)
            } else {
                removeObject(forKey: key)
            }
        }
    }

    /// 下标访问 Double
    public subscript(doubleKey key: String) -> Double? {
        get {
            guard contains(key: key) else { return nil }
            return double(forKey: key)
        }
        set {
            if let value = newValue {
                setDouble(value, forKey: key)
            } else {
                removeObject(forKey: key)
            }
        }
    }

    /// 下标访问 String
    public subscript(stringKey key: String) -> String? {
        get {
            return string(forKey: key)
        }
        set {
            if let value = newValue {
                setString(value, forKey: key)
            } else {
                removeObject(forKey: key)
            }
        }
    }

    /// 下标访问 Any
    public subscript(key: String) -> Any? {
        get {
            return value(forKey: key)
        }
        set {
            set(newValue, forKey: key)
        }
    }
}

// MARK: - UserDefaults Extension (便捷访问)

public extension UserDefaults {

    /// 快速访问 Bool
    func ls_bool(forKey key: String, defaultValue: Bool = false) -> Bool {
        return LSUserDefaultsStore(userDefaults: self).bool(forKey: key, defaultValue: defaultValue)
    }

    /// 快速访问 Int
    func ls_int(forKey key: String, defaultValue: Int = 0) -> Int {
        return LSUserDefaultsStore(userDefaults: self).int(forKey: key, defaultValue: defaultValue)
    }

    /// 快速访问 Double
    func ls_double(forKey key: String, defaultValue: Double = 0) -> Double {
        return LSUserDefaultsStore(userDefaults: self).double(forKey: key, defaultValue: defaultValue)
    }

    /// 快速访问 String
    func ls_string(forKey key: String, defaultValue: String = "") -> String {
        return LSUserDefaultsStore(userDefaults: self).string(forKey: key, defaultValue: defaultValue)
    }

    /// 快速访问 Date
    func ls_date(forKey key: String, defaultValue: Date = Date()) -> Date {
        return LSUserDefaultsStore(userDefaults: self).date(forKey: key, defaultValue: defaultValue)
    }

    /// 快速保存 Codable
    func ls_setCodable<T: Codable>(_ value: T, forKey key: String) throws {
        try LSUserDefaultsStore(userDefaults: self).setCodable(value, forKey: key)
    }

    /// 快速获取 Codable
    func ls_codable<T: Codable>(forKey key: String, type: T.Type) throws -> T? {
        return try LSUserDefaultsStore(userDefaults: self).codable(forKey: key, type: type)
    }

    /// 清空所有数据
    func ls_clearAll() {
        let dictionary = dictionaryRepresentation()
        dictionary.keys.forEach { key in
            removeObject(forKey: key)
        }
    }
}

#endif

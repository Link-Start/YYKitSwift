//
//  LSKeyEncoder.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  Snake/Camel Case 转换编码器 - 解决 JSON 命名风格不匹配问题
//

#if canImport(UIKit)
import UIKit
import Foundation

// MARK: - SnakeCaseEncoder

/// Snake Case 编码键策略
public struct SnakeCaseEncodingKey: CodingKey {

    public var stringValue: String
    public var intValue: Int?

    public init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    public init(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }

    /// 从 CodingKey 创建 SnakeCase key
    init(_ key: CodingKey) {
        if let intValue = key.intValue {
            self.stringValue = "\(intValue)"
            self.intValue = intValue
        } else {
            self.stringValue = Self.convertToSnakeCase(key.stringValue)
            self.intValue = nil
        }
    }

    /// 转换为 snake_case
    private static func convertToSnakeCase(_ string: String) -> String {
        var result = ""
        var previousCharacterWasLowercase = false

        for character in string {
            if character.isUppercase {
                if previousCharacterWasLowercase {
                    result.append("_")
                }
                result.append(character.lowercased())
                previousCharacterWasLowercase = false
            } else {
                result.append(character)
                previousCharacterWasLowercase = character.isLowercase
            }
        }

        return result
    }
}

// MARK: - SnakeCaseDecoder

/// Snake Case 解码键策略
public struct SnakeCaseDecodingKey: CodingKey {

    public var stringValue: String
    public var intValue: Int?

    public init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    public init(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }

    /// 从 CodingKey 创建 SnakeCase key
    init(_ key: CodingKey) {
        if let intValue = key.intValue {
            self.stringValue = "\(intValue)"
            self.intValue = intValue
        } else {
            self.stringValue = Self.convertToSnakeCase(key.stringValue)
            self.intValue = nil
        }
    }

    /// 转换为 snake_case
    private static func convertToSnakeCase(_ string: String) -> String {
        var result = ""
        var previousCharacterWasLowercase = false

        for character in string {
            if character.isUppercase {
                if previousCharacterWasLowercase {
                    result.append("_")
                }
                result.append(character.lowercased())
                previousCharacterWasLowercase = false
            } else {
                result.append(character)
                previousCharacterWasLowercase = character.isLowercase
            }
        }

        return result
    }
}

// MARK: - CamelCaseEncoder

/// Camel Case 编码键策略（kebab-case 转 camelCase）
public struct CamelCaseEncodingKey: CodingKey {

    public var stringValue: String
    public var intValue: Int?

    public init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    public init(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }

    /// 从 CodingKey 创建 CamelCase key
    init(_ key: CodingKey) {
        if let intValue = key.intValue {
            self.stringValue = "\(intValue)"
            self.intValue = intValue
        } else {
            self.stringValue = Self.convertToCamelCase(key.stringValue)
            self.intValue = nil
        }
    }

    /// 转换为 camelCase
    private static func convertToCamelCase(_ string: String) -> String {
        return string
    }

    /// 从 snake_case 转换
    static func fromSnakeCase(_ string: String) -> String {
        var result = ""
        var capitalizeNext = false

        for character in string {
            if character == "_" {
                capitalizeNext = true
            } else {
                if capitalizeNext {
                    result.append(character.uppercased())
                    capitalizeNext = false
                } else {
                    result.append(character)
                }
            }
        }

        return result
    }

    /// 从 kebab-case 转换
    static func fromKebabCase(_ string: String) -> String {
        return fromSnakeCase(string.replacingOccurrences(of: "-", with: "_"))
    }
}

// MARK: - KebabCaseEncoder

/// Kebab Case 编码键策略
public struct KebabCaseEncodingKey: CodingKey {

    public var stringValue: String
    public var intValue: Int?

    public init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    public init(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }

    /// 从 CodingKey 创建 KebabCase key
    init(_ key: CodingKey) {
        if let intValue = key.intValue {
            self.stringValue = "\(intValue)"
            self.intValue = intValue
        } else {
            self.stringValue = Self.convertToKebabCase(key.stringValue)
            self.intValue = nil
        }
    }

    /// 转换为 kebab-case
    private static func convertToKebabCase(_ string: String) -> String {
        var result = ""
        var previousCharacterWasLowercase = false

        for character in string {
            if character.isUppercase {
                if previousCharacterWasLowercase {
                    result.append("-")
                }
                result.append(character.lowercased())
                previousCharacterWasLowercase = false
            } else {
                result.append(character)
                previousCharacterWasLowercase = character.isLowercase
            }
        }

        return result
    }
}

// MARK: - KeyEncodingStrategy Extension

public extension JSONEncoder {

    /// Snake Case 编码策略
    static var snakeCase: JSONEncoder.KeyEncodingStrategy {
        return .custom { keys in
            let node = keys.last!
            let newKey = SnakeCaseEncodingKey(node)
            return newKey.stringValue
        }
    }

    /// Kebab Case 编码策略
    static var kebabCase: JSONEncoder.KeyEncodingStrategy {
        return .custom { keys in
            let node = keys.last!
            let newKey = KebabCaseEncodingKey(node)
            return newKey.stringValue
        }
    }

    /// 自定义前缀编码策略
    ///
    /// - Parameter prefix: 前缀
    /// - Returns: 编码策略
    static func withPrefix(_ prefix: String) -> JSONEncoder.KeyEncodingStrategy {
        return .custom { keys in
            let node = keys.last!
            return prefix + node.stringValue
        }
    }

    /// 自定义后缀编码策略
    ///
    /// - Parameter suffix: 后缀
    /// - Returns: 编码策略
    static func withSuffix(_ suffix: String) -> JSONEncoder.KeyEncodingStrategy {
        return .custom { keys in
            let node = keys.last!
            return node.stringValue + suffix
        }
    }

    /// 大写首字母编码策略
    static var upperCamelCase: JSONEncoder.KeyEncodingStrategy {
        return .custom { keys in
            let node = keys.last!
            let string = node.stringValue
            guard let firstCharacter = string.first else { return string }
            return firstCharacter.uppercased() + string.dropFirst()
        }
    }

    /// 小写编码策略
    static var lowerCase: JSONEncoder.KeyEncodingStrategy {
        return .custom { keys in
            keys.last!.stringValue.lowercased()
        }
    }

    /// 大写编码策略
    static var upperCase: JSONEncoder.KeyEncodingStrategy {
        return .custom { keys in
            keys.last!.stringValue.uppercased()
        }
    }
}

// MARK: - KeyDecodingStrategy Extension

public extension JSONDecoder {

    /// Snake Case 解码策略
    static var snakeCase: JSONDecoder.KeyDecodingStrategy {
        return .custom { keys in
            let node = keys.last!
            let newKey = SnakeCaseDecodingKey(node)
            return newKey.stringValue
        }
    }

    /// Kebab Case 解码策略
    static var kebabCase: JSONDecoder.KeyDecodingStrategy {
        return .custom { keys in
            let node = keys.last!
            // 将 kebab-case 转换为 camelCase
            let camelKey = node.stringValue.replacingOccurrences(of: "-", with: "_")
                .split(separator: "_")
                .enumerated()
                .map { $0.offset > 0 ? $0.element.capitalized : $0.element.lowercased() }
                .joined()
            return camelKey
        }
    }

    /// 自定义前缀解码策略
    ///
    /// - Parameter prefix: 前缀
    /// - Returns: 解码策略
    static func removingPrefix(_ prefix: String) -> JSONDecoder.KeyDecodingStrategy {
        return .custom { keys in
            let key = keys.last!.stringValue
            return key.hasPrefix(prefix) ? String(key.dropFirst(prefix.count)) : key
        }
    }

    /// 自定义后缀解码策略
    ///
    /// - Parameter suffix: 后缀
    /// - Returns: 解码策略
    static func removingSuffix(_ suffix: String) -> JSONDecoder.KeyDecodingStrategy {
        return .custom { keys in
            let key = keys.last!.stringValue
            return key.hasSuffix(suffix) ? String(key.dropLast(suffix.count)) : key
        }
    }

    /// 大写首字母解码策略
    static var upperCamelCase: JSONDecoder.KeyDecodingStrategy {
        return .custom { keys in
            let node = keys.last!
            let string = node.stringValue
            guard let firstCharacter = string.first else { return string }
            return firstCharacter.lowercased() + string.dropFirst()
        }
    }
}

// MARK: - 编码器工厂

public extension LSEncoder {

    /// 创建 Snake Case 编码器
    static var snakeCase: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .snakeCase
        return encoder
    }

    /// 创建 Kebab Case 编码器
    static var kebabCase: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .kebabCase
        return encoder
    }

    /// 创建 Upper Camel Case 编码器
    static var upperCamelCase: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .upperCamelCase
        return encoder
    }

    /// 创建带前缀的编码器
    ///
    /// - Parameter prefix: 前缀
    /// - Returns: 编码器
    static func withPrefix(_ prefix: String) -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .withPrefix(prefix)
        return encoder
    }
}

// MARK: - 解码器工厂

public extension LSDecoder {

    /// 创建 Snake Case 解码器
    static var snakeCase: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .snakeCase
        return decoder
    }

    /// 创建 Kebab Case 解码器
    static var kebabCase: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .kebabCase
        return decoder
    }

    /// 创建 Upper Camel Case 解码器
    static var upperCamelCase: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .upperCamelCase
        return decoder
    }

    /// 创建去除前缀的解码器
    ///
    /// - Parameter prefix: 前缀
    /// - Returns: 解码器
    static func removingPrefix(_ prefix: String) -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .removingPrefix(prefix)
        return decoder
    }
}

// MARK: - String 转换工具

public extension String {

    /// 转换为 snake_case
    var ls_toSnakeCase: String {
        var result = ""
        var previousCharacterWasLowercase = false

        for character in self {
            if character.isUppercase {
                if previousCharacterWasLowercase {
                    result.append("_")
                }
                result.append(character.lowercased())
                previousCharacterWasLowercase = false
            } else {
                result.append(character)
                previousCharacterWasLowercase = character.isLowercase
            }
        }

        return result
    }

    /// 转换为 kebab-case
    var ls_toKebabCase: String {
        return ls_toSnakeCase.replacingOccurrences(of: "_", with: "-")
    }

    /// 转换为 camelCase
    var ls_toCamelCase: String {
        return self
    }

    /// 从 snake_case 转换为 camelCase
    var ls_fromSnakeCase: String {
        var result = ""
        var capitalizeNext = false

        for character in self {
            if character == "_" {
                capitalizeNext = true
            } else {
                if capitalizeNext {
                    result.append(character.uppercased())
                    capitalizeNext = false
                } else {
                    result.append(character)
                }
            }
        }

        return result
    }

    /// 从 kebab-case 转换为 camelCase
    var ls_fromKebabCase: String {
        return ls_fromSnakeCase.replacingOccurrences(of: "-", with: "_").ls_fromSnakeCase
    }

    /// 转换为 UpperCamelCase
    var ls_toUpperCamelCase: String {
        guard let firstCharacter = self.first else { return self }
        return firstCharacter.uppercased() + self.dropFirst()
    }

    /// 转换为 lower_case
    var ls_toLowerCase: String {
        return lowercased()
    }

    /// 转换为 UPPER_CASE
    var ls_toUpperCase: String {
        return uppercased()
    }

    /// 转换为 SCREAMING_SNAKE_CASE
    var ls_toScreamingSnakeCase: String {
        return ls_toSnakeCase.uppercased()
    }
}

// MARK: - 字典键转换

public extension Dictionary where Key == String {

    /// 转换所有键为 snake_case
    var ls_keysToSnakeCase: [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in self {
            let newKey = key.ls_toSnakeCase
            if let nestedDict = value as? [String: Any] {
                result[newKey] = nestedDict.ls_keysToSnakeCase
            } else if let nestedArray = value as? [[String: Any]] {
                result[newKey] = nestedArray.map { $0.ls_keysToSnakeCase }
            } else {
                result[newKey] = value
            }
        }
        return result
    }

    /// 转换所有键为 camelCase
    var ls_keysFromSnakeCase: [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in self {
            let newKey = key.ls_fromSnakeCase
            if let nestedDict = value as? [String: Any] {
                result[newKey] = nestedDict.ls_keysFromSnakeCase
            } else if let nestedArray = value as? [[String: Any]] {
                result[newKey] = nestedArray.map { $0.ls_keysFromSnakeCase }
            } else {
                result[newKey] = value
            }
        }
        return result
    }
}

#endif

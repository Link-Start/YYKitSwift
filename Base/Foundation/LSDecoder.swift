//
//  LSDecoder.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  JSON 解码工具 - 简化 JSON 解码操作
//

#if canImport(UIKit)
import UIKit
import Foundation

// MARK: - LSDecoder

/// JSON 解码工具类
public enum LSDecoder {

    /// 默认 JSON 解码器
    public static let `default` = JSONDecoder()

    /// ISO8601 日期解码器
    public static let iso8601: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    /// 自定义日期格式解码器
    ///
    /// - Parameter format: 日期格式
    /// - Returns: JSONDecoder
    public static func dateFormatted(_ format: String) -> JSONDecoder {
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        return decoder
    }

    // MARK: - 解码方法

    /// 从 Data 解码
    ///
    /// - Parameters:
    ///   - data: JSON 数据
    ///   - type: 目标类型
    /// - Returns: 解码结果
    public static func decode<T: Decodable>(_ data: Data, as type: T.Type) -> Result<T, Error> {
        do {
            let result = try default.decode(T.self, from: data)
            return .success(result)
        } catch {
            return .failure(error)
        }
    }

    /// 从 Data 解码（使用自定义解码器）
    ///
    /// - Parameters:
    ///   - data: JSON 数据
    ///   - type: 目标类型
    ///   - decoder: 解码器
    /// - Returns: 解码结果
    public static func decode<T: Decodable>(
        _ data: Data,
        as type: T.Type,
        decoder: JSONDecoder
    ) -> Result<T, Error> {
        do {
            let result = try decoder.decode(T.self, from: data)
            return .success(result)
        } catch {
            return .failure(error)
        }
    }

    /// 从字符串解码
    ///
    /// - Parameters:
    ///   - string: JSON 字符串
    ///   - type: 目标类型
    /// - Returns: 解码结果
    public static func decode<T: Decodable>(_ string: String, as type: T.Type) -> Result<T, Error> {
        guard let data = string.data(using: .utf8) else {
            return .failure(DecodeError.invalidString)
        }
        return decode(data, as: type)
    }

    /// 从字典解码
    ///
    /// - Parameters:
    ///   - dictionary: 字典
    ///   - type: 目标类型
    /// - Returns: 解码结果
    public static func decode<T: Decodable>(
        _ dictionary: [String: Any],
        as type: T.Type
    ) -> Result<T, Error> {
        do {
            let data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
            return decode(data, as: type)
        } catch {
            return .failure(error)
        }
    }

    /// 从数组解码
    ///
    /// - Parameters:
    ///   - array: 数组
    ///   - type: 目标元素类型
    /// - Returns: 解码结果
    public static func decode<T: Decodable>(
        _ array: [Any],
        as type: T.Type
    ) -> Result<[T], Error> {
        do {
            let data = try JSONSerialization.data(withJSONObject: array, options: [])
            return decode(data, as: [T].self)
        } catch {
            return .failure(error)
        }
    }

    // MARK: - 便捷解码方法

    /// 解码或返回默认值
    ///
    /// - Parameters:
    ///   - data: JSON 数据
    ///   - type: 目标类型
    ///   - defaultValue: 默认值
    /// - Returns: 解码结果或默认值
    public static func decodeOr<T: Decodable>(
        _ data: Data,
        as type: T.Type,
        defaultValue: T
    ) -> T {
        if case .success(let result) = decode(data, as: type) {
            return result
        }
        return defaultValue
    }

    /// 解码或抛出错误
    ///
    /// - Parameters:
    ///   - data: JSON 数据
    ///   - type: 目标类型
    /// - Returns: 解码结果
    /// - Throws: 解码错误
    public static func decodeOrFail<T: Decodable>(
        _ data: Data,
        as type: T.Type
    ) throws -> T {
        switch decode(data, as: type) {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        }
    }

    /// 解码 JSON 字符串为字典
    ///
    /// - Parameter string: JSON 字符串
    /// - Returns: 字典或错误
    public static func decodeToDictionary(_ string: String) -> Result<[String: Any], Error> {
        guard let data = string.data(using: .utf8) else {
            return .failure(DecodeError.invalidString)
        }

        do {
            if let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                return .success(dictionary)
            }
            return .failure(DecodeError.notADictionary)
        } catch {
            return .failure(error)
        }
    }

    /// 解码 JSON 字符串为数组
    ///
    /// - Parameter string: JSON 字符串
    /// - Returns: 数组或错误
    public static func decodeToArray(_ string: String) -> Result<[Any], Error> {
        guard let data = string.data(using: .utf8) else {
            return .failure(DecodeError.invalidString)
        }

        do {
            if let array = try JSONSerialization.jsonObject(with: data, options: []) as? [Any] {
                return .success(array)
            }
            return .failure(DecodeError.notAnArray)
        } catch {
            return .failure(error)
        }
    }

    // MARK: - 键映射解码

    /// 使用自定义键策略解码
    ///
    /// - Parameters:
    ///   - data: JSON 数据
    ///   - type: 目标类型
    ///   - keyMapping: 键映射字典
    /// - Returns: 解码结果
    public static func decodeWithKeyMapping<T: Decodable>(
        _ data: Data,
        as type: T.Type,
        keyMapping: [String: String]
    ) -> Result<T, Error> {
        let decoder = JSONDecoder()
        // 注意：实际的键映射需要通过 CodingKeys 实现
        // 这里只是提供一个接口
        return decode(data, as: type, decoder: decoder)
    }
}

// MARK: - LSEncoder

/// JSON 编码工具类
public enum LSEncoder {

    /// 默认 JSON 编码器
    public static let `default` = JSONEncoder()

    /// ISO8601 日期编码器
    public static let iso8601: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    /// 自定义日期格式编码器
    ///
    /// - Parameter format: 日期格式
    /// - Returns: JSONEncoder
    public static func dateFormatted(_ format: String) -> JSONEncoder {
        let encoder = JSONEncoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
        return encoder
    }

    /// 美化输出编码器
    public static var prettyPrinted: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    // MARK: - 编码方法

    /// 编码为 Data
    ///
    /// - Parameter value: 要编码的值
    /// - Returns: 编码结果
    public static func encode<T: Encodable>(_ value: T) -> Result<Data, Error> {
        do {
            let data = try default.encode(value)
            return .success(data)
        } catch {
            return .failure(error)
        }
    }

    /// 编码为 Data（使用自定义编码器）
    ///
    /// - Parameters:
    ///   - value: 要编码的值
    ///   - encoder: 编码器
    /// - Returns: 编码结果
    public static func encode<T: Encodable>(
        _ value: T,
        encoder: JSONEncoder
    ) -> Result<Data, Error> {
        do {
            let data = try encoder.encode(value)
            return .success(data)
        } catch {
            return .failure(error)
        }
    }

    /// 编码为字符串
    ///
    /// - Parameter value: 要编码的值
    /// - Returns: 编码结果
    public static func encodeToString<T: Encodable>(_ value: T) -> Result<String, Error> {
        switch encode(value) {
        case .success(let data):
            if let string = String(data: data, encoding: .utf8) {
                return .success(string)
            } else {
                return .failure(EncodeError.stringConversionFailed)
            }
        case .failure(let error):
            return .failure(error)
        }
    }

    /// 编码为字符串（美化格式）
    ///
    /// - Parameter value: 要编码的值
    /// - Returns: 编码结果
    public static func encodeToPrettyString<T: Encodable>(_ value: T) -> Result<String, Error> {
        switch encode(value, encoder: prettyPrinted) {
        case .success(let data):
            if let string = String(data: data, encoding: .utf8) {
                return .success(string)
            } else {
                return .failure(EncodeError.stringConversionFailed)
            }
        case .failure(let error):
            return .failure(error)
        }
    }

    /// 编码为字典
    ///
    /// - Parameter value: 要编码的值
    /// - Returns: 编码结果
    public static func encodeToDictionary<T: Encodable>(_ value: T) -> Result<[String: Any], Error> {
        switch encode(value) {
        case .success(let data):
            do {
                if let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    return .success(dictionary)
                }
                return .failure(EncodeError.notADictionary)
            } catch {
                return .failure(error)
            }
        case .failure(let error):
            return .failure(error)
        }
    }
}

// MARK: - DecodeError

/// 解码错误
public enum DecodeError: Error {
    case invalidString
    case notADictionary
    case notAnArray
    case missingKey(String)
    case typeMismatch(expected: String, actual: String)
    case custom(Error)

    public var localizedDescription: String {
        switch self {
        case .invalidString:
            return "无效的字符串"
        case .notADictionary:
            return "不是字典类型"
        case .notAnArray:
            return "不是数组类型"
        case .missingKey(let key):
            return "缺少键: \(key)"
        case .typeMismatch(let expected, let actual):
            return "类型不匹配，期望: \(expected)，实际: \(actual)"
        case .custom(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - EncodeError

/// 编码错误
public enum EncodeError: Error {
    case stringConversionFailed
    case notADictionary
    case notAnArray
    case custom(Error)

    public var localizedDescription: String {
        switch self {
        case .stringConversionFailed:
            return "字符串转换失败"
        case .notADictionary:
            return "不是字典类型"
        case .notAnArray:
            return "不是数组类型"
        case .custom(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - Data Extension

public extension Data {

    /// 解码为指定类型
    ///
    /// - Parameter type: 目标类型
    /// - Returns: 解码结果
    func ls_decode<T: Decodable>(as type: T.Type) -> Result<T, Error> {
        return LSDecoder.decode(self, as: type)
    }

    /// 解码为指定类型（返回默认值）
    ///
    /// - Parameters:
    ///   - type: 目标类型
    ///   - defaultValue: 默认值
    /// - Returns: 解码结果或默认值
    func ls_decodeOr<T: Decodable>(as type: T.Type, defaultValue: T) -> T {
        return LSDecoder.decodeOr(self, as: type, defaultValue: defaultValue)
    }
}

// MARK: - String Extension

public extension String {

    /// 解码为指定类型
    ///
    /// - Parameter type: 目标类型
    /// - Returns: 解码结果
    func ls_decode<T: Decodable>(as type: T.Type) -> Result<T, Error> {
        return LSDecoder.decode(self, as: type)
    }

    /// 解码为指定类型（返回默认值）
    ///
    /// - Parameters:
    ///   - type: 目标类型
    ///   - defaultValue: 默认值
    /// - Returns: 解码结果或默认值
    func ls_decodeOr<T: Decodable>(as type: T.Type, defaultValue: T) -> T {
        return LSDecoder.decodeOr(self.data(using: .utf8) ?? Data(), as: type, defaultValue: defaultValue)
    }

    /// 解码为字典
    func ls_decodeToDictionary() -> Result<[String: Any], Error> {
        return LSDecoder.decodeToDictionary(self)
    }

    /// 解码为数组
    func ls_decodeToArray() -> Result<[Any], Error> {
        return LSDecoder.decodeToArray(self)
    }

    /// 是否为有效 JSON
    var ls_isValidJSON: Bool {
        guard let data = data(using: .utf8) else { return false }
        return (try? JSONSerialization.jsonObject(with: data, options: [])) != nil
    }
}

// MARK: - Dictionary Extension

public extension Dictionary where Key == String, Value == Any {

    /// 转换为 JSON 字符串
    ///
    /// - Returns: JSON 字符串或错误
    func ls_jsonString() -> Result<String, Error> {
        do {
            let data = try JSONSerialization.data(withJSONObject: self, options: [])
            if let string = String(data: data, encoding: .utf8) {
                return .success(string)
            }
            return .failure(EncodeError.stringConversionFailed)
        } catch {
            return .failure(error)
        }
    }

    /// 转换为 JSON 字符串（美化格式）
    ///
    /// - Returns: 格式化的 JSON 字符串或错误
    func ls_prettyJSONString() -> Result<String, Error> {
        do {
            let data = try JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted, .sortedKeys])
            if let string = String(data: data, encoding: .utf8) {
                return .success(string)
            }
            return .failure(EncodeError.stringConversionFailed)
        } catch {
            return .failure(error)
        }
    }

    /// 转换为 Data
    ///
    /// - Returns: JSON Data 或错误
    func ls_jsonData() -> Result<Data, Error> {
        do {
            let data = try JSONSerialization.data(withJSONObject: self, options: [])
            return .success(data)
        } catch {
            return .failure(error)
        }
    }
}

// MARK: - Array Extension

public extension Array {

    /// 转换为 JSON 字符串
    ///
    /// - Returns: JSON 字符串或错误
    func ls_jsonString() -> Result<String, Error> {
        do {
            let data = try JSONSerialization.data(withJSONObject: self, options: [])
            if let string = String(data: data, encoding: .utf8) {
                return .success(string)
            }
            return .failure(EncodeError.stringConversionFailed)
        } catch {
            return .failure(error)
        }
    }

    /// 转换为 JSON 字符串（美化格式）
    ///
    /// - Returns: 格式化的 JSON 字符串或错误
    func ls_prettyJSONString() -> Result<String, Error> {
        do {
            let data = try JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted, .sortedKeys])
            if let string = String(data: data, encoding: .utf8) {
                return .success(string)
            }
            return .failure(EncodeError.stringConversionFailed)
        } catch {
            return .failure(error)
        }
    }

    /// 转换为 Data
    ///
    /// - Returns: JSON Data 或错误
    func ls_jsonData() -> Result<Data, Error> {
        do {
            let data = try JSONSerialization.data(withJSONObject: self, options: [])
            return .success(data)
        } catch {
            return .failure(error)
        }
    }
}

// MARK: - Codable 辅助协议

/// 可忽略解码错误的协议
public protocol IgnoringDecodingErrors: Decodable {
    static var ignoredKeys: [String] { get }
}

#endif

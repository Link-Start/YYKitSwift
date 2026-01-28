//
//  LSModel.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  LSModel 协议，提供 JSON 模型转换功能
//

import Foundation

// MARK: - LSModel 协议

/// JSON 模型转换协议
@objc
public protocol LSModel: NSObjectProtocol {

    /// 自定义属性映射（JSON Key -> 属性名）
    /// 例如：["user_name": "userName", "user_id": "userId"]
    @objc optional static func ls_modelCustomPropertyMapper() -> [String: String]

    /// 容器属性泛型类型映射
    /// 例如：["friends": User.self, "items": "Item": Item.self]
    @objc optional static func ls_modelContainerPropertyGenericClass() -> [String: AnyClass]

    /// 数组属性元素类型映射
    @objc optional static func ls_modelPropertyClass() -> [String: AnyClass]

    /// 忽略的属性列表
    @objc optional static func ls_modelPropertyIgnoredList() -> [String]

    /// 白名单属性列表
    @objc optional static func ls_modelPropertyWhitelist() -> [String]

    /// 动态类选择 - 根据字典数据选择创建的类
    /// - Parameter dictionary: JSON/kv 字典
    /// - Returns: 要创建的类，nil 表示使用当前类
    @objc optional static func ls_modelCustomClass(for dictionary: [String: Any]) -> AnyClass?

    /// 转换前处理 - 在模型转换前调用
    /// - Parameter dictionary: JSON/kv 字典
    /// - Returns: 修改后的字典，nil 表示忽略此模型
    @objc optional func ls_modelCustomWillTransform(from dictionary: [String: Any]) -> [String: Any]?

    /// 转换后验证/修改 - 在属性设置完成后调用
    /// - Parameter dictionary: JSON/kv 字典
    /// - Returns: 是否有效，false 表示转换失败
    @objc optional func ls_modelCustomTransform(from dictionary: [String: Any]) -> Bool

    /// 导出前处理 - 在 JSON 序列化时调用
    /// - Parameter dictionary: JSON 字典（可变）
    /// - Returns: 是否有效，false 表示导出失败
    @objc optional func ls_modelCustomTransform(to dictionary: NSMutableDictionary) -> Bool

    // MARK: - NSCoding 支持

    /// 编码模型属性到 coder
    /// - Parameter coder: 归档器
    @objc optional func ls_encode(with coder: NSCoder)

    /// 从 coder 解码模型属性
    /// - Parameter coder: 解档器
    /// - Returns: self
    @objc optional static func ls_modelInit(with coder: NSCoder) -> Self?

    // MARK: - Hash/Equal/Description 支持

    /// 获取模型哈希值（用于哈希表键）
    @objc optional var ls_hash: UInt { get }

    /// 比较模型是否相等
    /// - Parameter model: 要比较的模型
    /// - Returns: 是否相等
    @objc optional func ls_isEqual(to model: Any?) -> Bool

    /// 获取模型描述信息（用于调试）
    @objc optional var ls_description: String { get }
}

// MARK: - LSModel 默认实现

public extension LSModel {

    /// 从 JSON 创建模型
    /// - Parameter json: JSON 数据（Dictionary、String、Data）
    /// - Returns: 模型实例，失败返回 nil
    static func ls_model(with json: Any?) -> Self? {
        guard let json = json else { return nil }

        var dictionary: [String: Any]?

        // 处理不同类型的输入
        switch json {
        case let dict as [String: Any]:
            dictionary = dict
        case let string as String:
            // 尝试将 JSON 字符串转换为 Dictionary
            if let data = string.data(using: .utf8),
               let obj = try? JSONSerialization.jsonObject(with: data, options: []),
               let dict = obj as? [String: Any] {
                dictionary = dict
            }
        case let data as Data:
            // 尝试将 JSON Data 转换为 Dictionary
            if let obj = try? JSONSerialization.jsonObject(with: data, options: []),
               let dict = obj as? [String: Any] {
                dictionary = dict
            }
        default:
            break
        }

        guard var dict = dictionary else { return nil }

        // 动态类选择
        let resultClass: AnyClass
        if let customClass = (Self.self as? LSModel.Type)?.ls_modelCustomClass?(for: dict) {
            guard let customNSObjectClass = customClass as? NSObject.Type else {
                return nil
            }
            resultClass = customClass
        } else {
            resultClass = Self.self
        }

        // 创建模型实例
        guard let model = (resultClass as NSObject.Type).init() as? Self else {
            return nil
        }

        // 调用转换前处理
        if let willTransformDict = (model as? LSModel)?.ls_modelCustomWillTransform?(from: dict) {
            dict = willTransformDict
        } else if (model as? LSModel)?.ls_modelCustomWillTransform?(from: dict) == nil {
            // 如果返回 nil，忽略此模型
            return nil
        }

        LSModelHelper.setProperties(to: model, with: dict)

        // 调用转换后验证
        if let isValid = (model as? LSModel)?.ls_modelCustomTransform?(from: dict), !isValid {
            return nil
        }

        return model
    }

    /// 从字典创建模型
    /// - Parameter dictionary: 字典数据
    /// - Returns: 模型实例
    static func ls_model(with dictionary: [String: Any]) -> Self {
        let model = self.init()
        LSModelHelper.setProperties(to: model, with: dictionary)

        // 调用转换后验证
        if let isValid = (model as? LSModel)?.ls_modelCustomTransform?(from: dictionary), !isValid {
            // 验证失败，返回空模型（保持与原 YYKit 一致的行为）
        }

        return model
    }

    /// 从 JSON 设置属性
    /// - Parameter json: JSON 数据
    /// - Returns: 是否成功
    func ls_setModel(with json: Any?) -> Bool {
        guard let json = json else { return false }

        var dictionary: [String: Any]?

        if let dict = json as? [String: Any] {
            dictionary = dict
        } else if let string = json as? String,
                  let data = string.data(using: .utf8),
                  let obj = try? JSONSerialization.jsonObject(with: data, options: []),
                  let dict = obj as? [String: Any] {
            dictionary = dict
        } else if let data = json as? Data,
                  let obj = try? JSONSerialization.jsonObject(with: data, options: []),
                  let dict = obj as? [String: Any] {
            dictionary = dict
        }

        guard var dict = dictionary else { return false }

        // 调用转换前处理
        if let willTransformDict = (self as? LSModel)?.ls_modelCustomWillTransform?(from: dict) {
            dict = willTransformDict
        } else if (self as? LSModel)?.ls_modelCustomWillTransform?(from: dict) == nil {
            return false
        }

        LSModelHelper.setProperties(to: self, with: dict)

        // 调用转换后验证
        if let isValid = (self as? LSModel)?.ls_modelCustomTransform?(from: dict), !isValid {
            return false
        }

        return true
    }

    /// 转换为 JSON 对象
    var ls_jsonObject: Any? {
        return LSModelHelper.toJSON(from: self)
    }

    /// 转换为 JSON 数据
    var ls_jsonData: Data? {
        guard let obj = ls_jsonObject else { return nil }
        return try? JSONSerialization.data(withJSONObject: obj, options: [])
    }

    /// 转换为 JSON 字符串
    var ls_jsonString: String? {
        guard let data = ls_jsonData else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// 复制模型
    var ls_copy: Self? {
        guard let dict = ls_jsonObject as? [String: Any] else { return nil }
        return Self.ls_model(with: dict)
    }

    // MARK: - NSCoding

    /// 编码模型属性到 coder（用于 NSCoding 归档）
    ///
    /// 此方法会自动序列化所有属性到 coder
    /// - Parameter coder: 归档器
    func ls_encode(with coder: NSCoder) {
        // 调用自定义编码（如果有）
        if let customEncode = (self as? LSModel)?.ls_encode {
            customEncode(coder)
            return
        }

        // 默认编码：将所有属性编码
        if let dict = ls_jsonObject as? [String: Any] {
            coder.encode(dict, forKey: "ls_modelProperties")
        }
    }

    /// 从 coder 解码并创建模型实例（用于 NSCoding 解档）
    ///
    /// - Parameter coder: 解档器
    /// - Returns: 模型实例
    static func ls_modelInit(with coder: NSCoder) -> Self? {
        // 调用自定义解码（如果有）
        if let customInit = (Self.self as? LSModel.Type)?.ls_modelInit {
            return customInit(coder)
        }

        // 默认解码：从属性字典解码
        guard let dict = coder.decodeObject(forKey: "ls_modelProperties") as? [String: Any] else {
            return nil
        }
        return Self.ls_model(with: dict)
    }

    // MARK: - Hash/Equal/Description

    /// 获取模型哈希值（用于哈希表键）
    ///
    /// 此方法基于模型属性的 JSON 表示计算哈希值
    var ls_hash: UInt {
        // 调用自定义哈希（如果有）
        if let customHash = (self as? LSModel)?.ls_hash {
            return customHash
        }

        // 默认哈希：基于 JSON 字符串
        guard let jsonString = ls_jsonString else {
            return ObjectIdentifier(self).hashValue
        }
        return UInt(jsonString.hashValue)
    }

    /// 比较模型是否相等
    ///
    /// 此方法比较两个模型的属性是否相等
    /// - Parameter model: 要比较的模型
    /// - Returns: 是否相等
    func ls_isEqual(to model: Any?) -> Bool {
        // 调用自定义相等比较（如果有）
        if let customEqual = (self as? LSModel)?.ls_isEqual {
            return customEqual(model)
        }

        // 默认相等比较：基于 JSON 字典
        guard let other = model as? NSObject else { return false }
        guard let selfDict = ls_jsonObject as? [String: Any],
              let otherDict = (other as? LSModel)?.ls_jsonObject as? [String: Any] else {
            return false
        }
        return selfDict == otherDict
    }

    /// 获取模型描述信息（用于调试）
    ///
    /// 此方法返回包含所有属性的描述字符串
    var ls_description: String {
        // 调用自定义描述（如果有）
        if let customDesc = (self as? LSModel)?.ls_description {
            return customDesc
        }

        // 默认描述：基于 JSON 字符串
        let className = String(describing: type(of: self))
        guard let jsonDict = ls_jsonObject as? [String: Any] else {
            return "\(className): {}"
        }

        let props = jsonDict.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        return "\(className): { \(props) }"
    }
}

// MARK: - 数组模型转换

public extension LSModel {

    /// 从 JSON 数组创建模型数组
    /// - Parameter jsonArray: JSON 数组
    /// - Returns: 模型数组
    static func ls_modelArray(with jsonArray: Any?) -> [Self]? {
        guard let jsonArray = jsonArray else { return nil }

        var array: [Any]?

        if let arr = jsonArray as? [Any] {
            array = arr
        } else if let string = jsonArray as? String,
                   let data = string.data(using: .utf8),
                   let obj = try? JSONSerialization.jsonObject(with: data, options: []),
                   let arr = obj as? [Any] {
            array = arr
        } else if let data = jsonArray as? Data,
                   let obj = try? JSONSerialization.jsonObject(with: data, options: []),
                   let arr = obj as? [Any] {
            array = arr
        }

        guard let items = array else { return nil }

        return items.compactMap { item in
            if let dict = item as? [String: Any] {
                return Self.ls_model(with: dict)
            }
            return nil
        }
    }
}

// MARK: - NSObject + LSModel 扩展

extension NSObject {

    /// 获取所有属性名称和类型
    static func ls_modelProperties() -> [(name: String, type: Any.Type)] {
        var properties: [(name: String, type: Any.Type)] = []

        var count: UInt32 = 0
        guard let ivars = class_copyIvarList(self.classForCoder(), &count) else {
            return properties
        }

        for i in 0..<count {
            let ivar = ivars[Int(i)]
            let name = String(cString: ivar_getName(ivar))

            // 移除下划线前缀
            let propertyName = name.hasPrefix("_") ? String(name.dropFirst()) : name

            // 获取类型
            let type = ls_propertyType(for: propertyName)

            properties.append((name: propertyName, type: type))
        }

        free(ivars)
        return properties
    }

    /// 获取属性类型
    private static func ls_propertyType(for name: String) -> Any.Type {
        // 尝试通过 getter 方法获取类型
        let selector = NSSelectorFromString(name)
        if let method = class_getInstanceMethod(self, selector) {
            let encoding = method_getTypeEncoding(method)
            if let type = ls_type(from: encoding) {
                return type
            }
        }

        return Any.self
    }

    /// 从类型编码获取类型
    private static func ls_type(from encoding: UnsafePointer<CChar>) -> Any.Type? {
        let string = String(cString: encoding)

        // 解析类型编码
        if string.hasPrefix("T@") {
            // 对象类型
            let range = string.index(string.startIndex, offsetBy: 2)..<string.index(string.endIndex, offsetBy: -1)
            let typeName = String(string[range])

            if typeName == "NSString" || typeName == "NSMutableString" {
                return String.self
            } else if typeName == "NSNumber" {
                return NSNumber.self
            } else if typeName == "NSArray" || typeName == "NSMutableArray" {
                return [Any].self
            } else if typeName == "NSDictionary" || typeName == "NSMutableDictionary" {
                return [String: Any].self
            } else if typeName == "NSDate" {
                return Date.self
            } else if typeName == "NSData" {
                return Data.self
            } else if typeName == "NSURL" {
                return URL.self
            } else if typeName == "UIView" {
                return UIView.self
            } else if typeName.hasPrefix("NS") {
                // 系统类
                return NSObject.self
            }
        } else if string.hasPrefix("Ti") || string.hasPrefix("TI") {
            return Int.self
        } else if string.hasPrefix("Tq") || string.hasPrefix("TQ") {
            return UInt.self
        } else if string.hasPrefix("Tf") || string.hasPrefix("TF") {
            return Float.self
        } else if string.hasPrefix("Td") || string.hasPrefix("TD") {
            return Double.self
        } else if string.hasPrefix("TB") || string.hasPrefix("Tc") {
            return Bool.self
        } else if string.hasPrefix("T{") {
            // 结构体类型
            return NSValue.self
        }

        return nil
    }
}

// MARK: - 模型辅助工具

public enum LSModelHelper {

    /// 设置属性值
    static func setProperties(to model: NSObject, with dictionary: [String: Any]) {
        guard let modelType = type(of: model) as? LSModel.Type else { return }

        // 获取自定义映射
        let customMapperValue: [String: String]
        if let mapper = modelType.ls_modelCustomPropertyMapper?() {
            customMapperValue = mapper
        } else {
            customMapperValue = [:]
        }
        let customMapper = customMapperValue

        // 获取容器泛型映射
        let containerGenericValue: [String: AnyClass]
        if let generic = modelType.ls_modelContainerPropertyGenericClass?() {
            containerGenericValue = generic
        } else {
            containerGenericValue = [:]
        }
        let containerGeneric = containerGenericValue

        // 获取忽略列表
        let ignoredListValue: [String]
        if let ignored = modelType.ls_modelPropertyIgnoredList?() {
            ignoredListValue = ignored
        } else {
            ignoredListValue = []
        }
        let ignoredList = ignoredListValue

        // 获取白名单
        let whitelist = (modelType.ls_modelPropertyWhitelist?())

        // 遍历字典设置属性
        for (key, value) in dictionary {
            // 获取映射后的属性名
            let propertyName: String
            if let mappedName = customMapper[key] {
                propertyName = mappedName
            } else {
                propertyName = key
            }

            // 检查是否在忽略列表中
            if ignoredList.contains(propertyName) {
                continue
            }

            // 检查白名单
            if let whitelist = whitelist, !whitelist.contains(propertyName) {
                continue
            }

            // 设置属性值
            setValue(to: model, key: propertyName, value: value, containerGeneric: containerGeneric)
        }
    }

    /// 设置单个属性值
    private static func setValue(to model: NSObject, key: String, value: Any, containerGeneric: [String: AnyClass]) {
        guard let modelType = type(of: model) as? LSModel.Type else { return }

        // 转换 JSON Key 到属性名
        let propertyName = ls_propertyName(from: key)

        // 尝试获取属性
        let properties = NSObject.ls_modelProperties()
        guard let property = properties.first(where: { $0.name == propertyName }) else {
            return
        }

        // 检查是否有容器泛型类型
        if let genericClass = containerGeneric[propertyName] {
            setContainerValue(to: model, key: propertyName, value: value, genericClass: genericClass)
            return
        }

        // 设置值
        if let convertedValue = convertValue(value, to: property.type) {
            model.setValue(convertedValue, forKey: propertyName)
        }
    }

    /// 设置容器属性值
    private static func setContainerValue(to model: NSObject, key: String, value: Any, genericClass: AnyClass) {
        if let array = value as? [Any] {
            let objects = array.compactMap { item -> NSObject? in
                if let dict = item as? [String: Any] {
                    let obj = genericClass.init() as? NSObject
                    if let obj = obj {
                        setProperties(to: obj, with: dict)
                        return obj
                    }
                }
                return nil
            }
            model.setValue(objects, forKey: key)
        } else if let dict = value as? [String: Any] {
            let obj = genericClass.init() as? NSObject
            if let obj = obj {
                setProperties(to: obj, with: dict)
                model.setValue(obj, forKey: key)
            }
        }
    }

    /// 转换值类型
    private static func convertValue(_ value: Any, to type: Any.Type) -> Any? {
        // 如果类型匹配，直接返回
        if type(of: value) == type || type == Any.self {
            return value
        }

        // 如果是可选类型，解包
        let mirror = Mirror(reflecting: value)
        if mirror.displayStyle == .optional {
            if let unwrapped = mirror.children.first?.value {
                return convertValue(unwrapped, to: type)
            }
        }

        // String 转换
        if let stringValue = value as? String {
            if type == Int.self || type == NSNumber.self {
                return Int(stringValue)
            } else if type == Double.self {
                return Double(stringValue)
            } else if type == Float.self {
                return Float(stringValue)
            } else if type == Bool.self {
                return Bool(stringValue)
            } else if type == URL.self {
                return URL(string: stringValue)
            } else if type == Date.self {
                return ls_date(from: stringValue)
            }
        }

        // NSNumber 转换
        if let numberValue = value as? NSNumber {
            if type == String.self {
                return numberValue.stringValue
            } else if type == Int.self {
                return numberValue.intValue
            } else if type == Double.self {
                return numberValue.doubleValue
            } else if type == Float.self {
                return numberValue.floatValue
            } else if type == Bool.self {
                return numberValue.boolValue
            }
        }

        // 集合类型转换
        if type == [String: Any].self, let dict = value as? [String: Any] {
            return dict
        } else if type == [Any].self, let array = value as? [Any] {
            return array
        }

        return value
    }

    /// 从字符串解析日期
    private static func ls_date(from string: String) -> Date? {
        let formatters = [
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd"
        ]

        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            if let date = formatter.date(from: string) {
                return date
            }
        }

        // 尝试 ISO8601
        if let date = ISO8601DateFormatter().date(from: string) {
            return date
        }

        return nil
    }

    /// 转换为 JSON 对象
    static func toJSON(from model: NSObject) -> Any? {
        let mirror = Mirror(reflecting: model)
        var dict: [String: Any] = [:]

        for (name, value) in mirror.children {
            guard let key = name else { continue }

            // 跳过可选值为 nil
            if let optionalValue = value as? Optional<Any>, optionalValue == nil {
                continue
            }

            // 处理嵌套模型
            if let nestedModel = value as? LSModel {
                if let nestedJSON = toJSON(from: nestedModel as! NSObject) {
                    dict[key] = nestedJSON
                }
            } else if let array = value as? [Any] {
                let jsonArray = array.compactMap { item -> Any? in
                    if let model = item as? LSModel {
                        return toJSON(from: model as! NSObject)
                    }
                    return item
                }
                dict[key] = jsonArray
            } else {
                let dictValue: Any
                if let v = value {
                    dictValue = v
                } else {
                    dictValue = NSNull()
                }
                dict[key] = dictValue
            }
        }

        // 创建可变字典用于导出前转换
        let mutableDict = NSMutableDictionary(dictionary: dict)

        // 调用导出前转换回调
        if let lsModel = model as? LSModel,
           let isValid = lsModel.ls_modelCustomTransform?(to: mutableDict),
           !isValid {
            return nil
        }

        return mutableDict as? [String: Any]
    }

    /// JSON Key 转属性名（蛇形转驼峰）
    private static func ls_propertyName(from key: String) -> String {
        // 如果已经是驼峰，直接返回
        if key.contains("_") {
            let components = key.split(separator: "_")
            let result: String
            if let first = components.first {
                result = first
            } else {
                result = ""
            }
            for component in components.dropFirst() {
                result += component.capitalized
            }
            return result
        }
        return key
    }
}

// MARK: - Optional 扩展

extension Optional {
    var isNil: Bool {
        return self == nil
    }
}

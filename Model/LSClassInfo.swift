//
//  LSClassInfo.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  LSClassInfo 运行时类信息获取
//

import Foundation

// MARK: - LSClassInfo

/// 类信息，用于获取运行时属性、方法等信息
public final class LSClassInfo: NSObject {

    /// 类信息缓存
    private static var cache: [String: LSClassInfo] = [:]
    private let lock = NSLock()

    /// 缓存键
    private static func cacheKey(for clazz: AnyClass) -> String {
        return NSStringFromClass(clazz)
    }

    /// 获取类信息（带缓存）
    @objc public static func info(for clazz: AnyClass) -> LSClassInfo {
        let key = cacheKey(for: clazz)

        if let cached = cache[key] {
            return cached
        }

        let info = LSClassInfo(clazz: clazz)
        info.lock.lock()
        cache[key] = info
        info.lock.unlock()

        return info
    }

    // MARK: - 属性信息

    /// 所有属性信息
    @objc public private(set) var properties: [LSPropertyInfo] = []

    /// 属性名到属性信息的映射
    @objc public private(set) var propertyMap: [String: LSPropertyInfo] = [:]

    // MARK: - 初始化

    private init(clazz: AnyClass) {
        super.init()
        updateProperties(for: clazz)
    }

    /// 更新属性信息
    private func updateProperties(for clazz: AnyClass) {
        var properties: [LSPropertyInfo] = [:]
        var map: [String: LSPropertyInfo] = [:]

        var count: UInt32 = 0
        guard let ivars = class_copyIvarList(clazz, &count) else {
            self.properties = properties
            self.propertyMap = map
            return
        }

        for i in 0..<count {
            let ivar = ivars[Int(i)]
            let name = String(cString: ivar_getName(ivar))

            // 移除下划线前缀
            let propertyName: String
            if name.hasPrefix("_") {
                propertyName = String(name.dropFirst())
            } else {
                propertyName = name
            }

            // 获取类型编码
            let encoding = ivar_getTypeEncoding(ivar)
            let typeString: String
            if let enc = encoding {
                typeString = String(cString: enc)
            } else {
                typeString = ""
            }

            let propertyInfo = LSPropertyInfo(name: propertyName, typeEncoding: typeString)

            properties.append(propertyInfo)
            map[propertyName] = propertyInfo
        }

        free(ivars)

        self.properties = properties
        self.propertyMap = map
    }
}

// MARK: - 属性信息

/// 属性信息
public final class LSPropertyInfo: NSObject {

    /// 属性名
    @objc public private(set) var name: String

    /// 类型编码
    @objc public private(set) var typeEncoding: String

    /// 属性类型
    @objc public var type: PropertyType {
        return PropertyType(typeEncoding: typeEncoding)
    }

    init(name: String, typeEncoding: String) {
        self.name = name
        self.typeEncoding = typeEncoding
        super.init()
    }
}

// MARK: - 属性类型

/// 属性类型枚举
@objc public enum PropertyType: Int {
    case unknown
    case int
    case uint
    case float
    case double
    case bool
    case string
    case array
    case dictionary
    case number
    case date
    case data
    case url
    case object
    case structType
    case optional

    init(typeEncoding: String) {
        if typeEncoding.isEmpty {
            self = .unknown
            return
        }

        switch typeEncoding {
        case let encoding where encoding.hasPrefix("Ti") || encoding.hasPrefix("TI") || encoding.hasPrefix("l") || encoding.hasPrefix("L"):
            self = .int
        case let encoding where encoding.hasPrefix("Tq") || encoding.hasPrefix("TQ"):
            self = .uint
        case let encoding where encoding.hasPrefix("Tf") || encoding.hasPrefix("TF"):
            self = .float
        case let encoding where encoding.hasPrefix("Td") || encoding.hasPrefix("TD"):
            self = .double
        case let encoding where encoding.hasPrefix("TB") || encoding.hasPrefix("Tc"):
            self = .bool
        case let encoding where encoding.contains("NSString"):
            self = .string
        case let encoding where encoding.contains("NSArray"):
            self = .array
        case let encoding where encoding.contains("NSDictionary"):
            self = .dictionary
        case let encoding where encoding.contains("NSNumber"):
            self = .number
        case let encoding where encoding.contains("NSDate"):
            self = .date
        case let encoding where encoding.contains("NSData"):
            self = .data
        case let encoding where encoding.contains("NSURL"):
            self = .url
        case let encoding where encoding.hasPrefix("T@") && !encoding.contains("<"):
            self = .object
        case let encoding where encoding.hasPrefix("T{"):
            self = .structType
        default:
            self = .unknown
        }
    }

    /// 是否为数字类型
    var isNumber: Bool {
        switch self {
        case .int, .uint, .float, .double, .bool:
            return true
        default:
            return false
        }
    }
}

// MARK: - 方法信息

/// 方法信息
public final class LSMethodInfo: NSObject {

    /// 方法选择器
    @objc public private(set) var selector: Selector

    /// 方法名
    @objc public var name: String {
        return NSStringFromSelector(selector)
    }

    /// 返回类型
    @objc public private(set) var returnType: String = ""

    /// 参数类型列表
    @objc public private(set) var argumentTypes: [String] = []

    init(selector: Selector) {
        self.selector = selector
        super.init()
    }

    /// 更新方法签名
    func update(with encoding: String) {
        // 解析方法类型编码
        // 格式: returnType(argumentTypes)...
        guard !encoding.isEmpty else { return }

        let parts = encoding.split(separator: ":", maxSplits: Int(encoding.count))

        if let returnTypeIndex = parts.firstIndex(of: Int(0)) {
            returnType = String(parts[returnTypeIndex])
        }

        // 参数类型（跳过返回类型和 self）
        if parts.count > 2 {
            argumentTypes = parts[1..<parts.count - 1].map { String($0) }
        }
    }
}

// MARK: - 类信息扩展

public extension LSClassInfo {

    /// 获取属性信息
    func propertyInfo(for name: String) -> LSPropertyInfo? {
        return propertyMap[name]
    }

    /// 检查是否有指定属性
    func hasProperty(_ name: String) -> Bool {
        return propertyMap[name] != nil
    }

    /// 所有属性名
    var propertyNames: [String] {
        return properties.map { $0.name }
    }
}

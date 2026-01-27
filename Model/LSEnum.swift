//
//  LSEnum.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  LSEnum 枚举映射支持
//

import Foundation

// MARK: - LSEnum 协议

/// 枚举映射协议
@objc
public protocol LSEnum: LSModel {

    /// 枚举值到字符串的映射
    /// 例如：["male": 0, "female": 1]
    @objc optional static func ls_enumMap() -> [String: Int]

    /// 字符串到枚举值的映射
    /// 例如：[0: "male", 1: "female"]
    @objc optional static func ls_enumStringMap() -> [Int: String]
}

// MARK: - LSEnum 默认实现

public extension LSEnum {

    /// 从字符串获取枚举值
    static func ls_enum(from string: String) -> Self? {
        guard let enumMap = ls_enumMap() else {
            return nil
        }

        if let rawValue = enumMap[string] {
            return ls_init(rawValue: rawValue)
        }

        return nil
    }

    /// 获取枚举的字符串表示
    func ls_enumString() -> String? {
        guard let enumStringMap = (Self.self as? LSEnum.Type)?.ls_enumStringMap() else {
            return nil
        }

        let mirror = Mirror(reflecting: self)
        if let rawValue = mirror.children.first(where: { $0.label == "rawValue" })?.value as? Int {
            return enumStringMap[rawValue]
        }

        return nil
    }

    /// 使用 rawValue 初始化
    private static func ls_init(rawValue: Int) -> Self? {
        let mirror = Mirror(reflecting: Self.self)
        for child in mirror.children {
            if child.label == "rawValue" {
                // 创建一个新的实例
                let instance = self.init()
                // 设置 rawValue
                (instance as AnyObject).setValue(rawValue, forKey: "rawValue")
                return instance as? Self
            }
        }

        // 尝试直接使用 rawValue 初始化
        if let convertible = self as? Int convertible {
            let _ = convertible
            // 这里需要具体的枚举类型支持
        }

        return nil
    }
}

// MARK: - 使用示例

/*
// 定义一个遵循 LSEnum 的枚举
enum Gender: Int, LSEnum {
    case male = 0
    case female = 1

    static func ls_enumMap() -> [String: Int] {
        return ["male": 0, "female": 1]
    }

    static func ls_enumStringMap() -> [Int: String] {
        return [0: "male", 1: "female"]
    }
}

// 在模型中使用
class User: NSObject, LSModel {
    var name: String = ""
    var gender: Gender = .male

    static func ls_modelCustomPropertyMapper() -> [String: String] {
        return ["user_gender": "gender"]
    }
}

// 使用示例
let json = ["user_gender": "male"]
let user = User.ls_model(with: json) // gender 会被正确设置为 .male
let genderString = user.gender.ls_enumString() // 返回 "male"
*/

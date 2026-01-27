//
//  Array+YYKitSwift.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  Array 扩展，提供常用方法
//

import Foundation

// MARK: - Array 扩展

public extension Array {

    // MARK: - Plist 序列化

    /// 从 Plist 数据创建 Array
    static func ls_plist(_ plist: Data) -> [Element]? {
        return (try? PropertyListSerialization.propertyList(from: plist, options: [], format: nil)) as? [Element]
    }

    /// 从 Plist 字符串创建 Array
    static func ls_plistString(_ plistString: String) -> [Element]? {
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

    // MARK: - 安全访问

    /// 随机返回一个元素
    var ls_random: Element? {
        guard !isEmpty else { return nil }
        let offset = Int.random(in: 0..<count)
        return self[offset]
    }

    /// 安全访问指定索引的元素（越界返回 nil）
    subscript(ls_safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }

    // MARK: - JSON 序列化

    /// 转换为 JSON 字符串
    func ls_jsonString() -> String? {
        guard isValidJSONObject else { return nil }
        guard let data = try? JSONSerialization.data(withJSONObject: self, options: [.fragmentsAllowed]) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// 转换为格式化的 JSON 字符串
    func ls_jsonPrettyString() -> String? {
        guard isValidJSONObject else { return nil }
        guard let data = try? JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted]) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

//
//  NSNumber+YYKitSwift.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  NSNumber 扩展，提供数字解析方法
//

import Foundation

// MARK: - NSNumber 扩展

public extension NSNumber {

    /// 从字符串创建 NSNumber
    /// 支持格式：@"12", @"12.345", @" -0xFF", @" .23e99 " 等
    /// - Parameter string: 数字字符串
    /// - Returns: NSNumber 对象，解析失败返回 nil
    static func ls_string(_ string: String) -> NSNumber? {
        // 去除首尾空白
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // 尝试解析整数
        if let intValue = Int(trimmed) {
            return NSNumber(value: intValue)
        }

        // 尝试解析浮点数
        if let doubleValue = Double(trimmed) {
            return NSNumber(value: doubleValue)
        }

        // 尝试解析十六进制（以 0x 或 0X 开头）
        if trimmed.hasPrefix("0x") || trimmed.hasPrefix("0X") {
            let hex = trimmed.dropFirst(2)
            if let hexValue = Int(hex, radix: 16) {
                return NSNumber(value: hexValue)
            }
        }

        return nil
    }
}

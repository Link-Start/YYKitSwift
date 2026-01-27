//
//  LSTextArchiver.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  文本归档器 - 用于序列化和反序列化富文本
//

#if canImport(UIKit)
import UIKit
import Foundation

// MARK: - LSTextArchiver

/// LSTextArchiver 用于将富文本序列化为数据
///
/// 支持序列化：
/// - 系统属性（字体、颜色、段落样式等）
/// - YYText 自定义属性（阴影、边框、附件、高亮等）
public class LSTextArchiver: NSObject {

    // MARK: - 归档方法

    /// 将富文本归档为数据
    ///
    /// - Parameter text: 富文本
    /// - Returns: 归档数据，失败返回 nil
    public static func archivedData(withRootObject text: NSAttributedString) -> Data? {
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: text, requiringSecureCoding: true) else {
            return nil
        }
        return data
    }

    /// 将富文本归档为数据（不使用安全编码）
    ///
    /// - Parameter text: 富文本
    /// - Returns: 归档数据，失败返回 nil
    public static func archivedData(withRootObjectUnsecurely text: NSAttributedString) -> Data? {
        return NSKeyedArchiver.archivedData(withRootObject: text)
    }
}

// MARK: - LSTextUnarchiver

/// LSTextUnarchiver 用于从数据反序列化富文本
public class LSTextUnarchiver: NSObject {

    // MARK: - 解档方法

    /// 从数据解档富文本
    ///
    /// - Parameter data: 归档数据
    /// - Returns: 富文本，失败返回 nil
    public static func unarchiveObject(with data: Data) -> NSAttributedString? {
        guard let result = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: data) else {
            return nil
        }
        return result
    }

    /// 从数据解档富文本（不使用安全编码）
    ///
    /// - Parameter data: 归档数据
    /// - Returns: 富文本，失败返回 nil
    public static func unarchiveObjectUnsecurely(with data: Data) -> NSAttributedString? {
        return NSKeyedUnarchiver.unarchiveObject(with: data) as? NSAttributedString
    }
}

// MARK: - NSAttributedString Extension (归档支持)

extension NSAttributedString {

    /// 归档为数据
    ///
    /// - Returns: 归档数据
    public func ls_archivedData() -> Data? {
        return LSTextArchiver.archivedData(withRootObject: self)
    }

    /// 归档为数据（不使用安全编码）
    ///
    /// - Returns: 归档数据
    public func ls_archivedDataUnsecurely() -> Data? {
        return LSTextArchiver.archivedData(withRootObjectUnsecurely: self)
    }
}

// MARK: - NSAttributedString Extension (创建方法)

extension NSAttributedString {

    /// 从归档数据创建富文本
    ///
    /// - Parameter data: 归档数据
    /// - Returns: 富文本，失败返回 nil
    public static func ls_attributedString(with data: Data) -> NSAttributedString? {
        return LSTextUnarchiver.unarchiveObject(with: data)
    }

    /// 从归档数据创建富文本（不使用安全编码）
    ///
    /// - Parameter data: 归档数据
    /// - Returns: 富文本，失败返回 nil
    public static func ls_attributedStringUnsecurely(with data: Data) -> NSAttributedString? {
        return LSTextUnarchiver.unarchiveObjectUnsecurely(with: data)
    }

    /// 从文件加载富文本
    ///
    /// - Parameter path: 文件路径
    /// - Returns: 富文本，失败返回 nil
    public static func ls_attributedString(withContentsOfFile path: String) -> NSAttributedString? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return nil
        }
        return ls_attributedString(with: data)
    }
}

// MARK: - NSMutableAttributedString Extension (归档支持)

extension NSMutableAttributedString {

    /// 从归档数据创建可变富文本
    ///
    /// - Parameter data: 归档数据
    /// - Returns: 可变富文本，失败返回 nil
    public static func ls_mutableAttributedString(with data: Data) -> NSMutableAttributedString? {
        guard let attributedString = NSAttributedString.ls_attributedString(with: data) else {
            return nil
        }
        return NSMutableAttributedString(attributedString: attributedString)
    }
}

#endif

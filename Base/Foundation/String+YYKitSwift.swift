//
//  String+YYKitSwift.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  String 扩展，提供 Hash、加密、编码和常用方法
//

import Foundation
import UIKit
import CommonCrypto

// MARK: - String 扩展

public extension String {

    // MARK: - Hash

    /// MD5 哈希值（小写）
    func ls_md5() -> String? {
        guard let data = self.data(using: .utf8) else { return nil }
        return data.ls_md5()
    }

    /// SHA1 哈希值（小写）
    func ls_sha1() -> String? {
        guard let data = self.data(using: .utf8) else { return nil }
        return data.ls_sha1()
    }

    /// SHA224 哈希值（小写）
    func ls_sha224() -> String? {
        guard let data = self.data(using: .utf8) else { return nil }
        return data.ls_sha224()
    }

    /// SHA256 哈希值（小写）
    func ls_sha256() -> String? {
        guard let data = self.data(using: .utf8) else { return nil }
        return data.ls_sha256()
    }

    /// SHA384 哈希值（小写）
    func ls_sha384() -> String? {
        guard let data = self.data(using: .utf8) else { return nil }
        return data.ls_sha384()
    }

    /// SHA512 哈希值（小写）
    func ls_sha512() -> String? {
        guard let data = self.data(using: .utf8) else { return nil }
        return data.ls_sha512()
    }

    /// HMAC MD5
    func ls_hmacMD5(key: String) -> String? {
        guard let data = self.data(using: .utf8) else { return nil }
        return data.ls_hmacMD5(key: key)
    }

    /// HMAC SHA1
    func ls_hmacSHA1(key: String) -> String? {
        guard let data = self.data(using: .utf8) else { return nil }
        return data.ls_hmacSHA1(key: key)
    }

    /// HMAC SHA256
    func ls_hmacSHA256(key: String) -> String? {
        guard let data = self.data(using: .utf8) else { return nil }
        return data.ls_hmacSHA256(key: key)
    }

    /// HMAC SHA512
    func ls_hmacSHA512(key: String) -> String? {
        guard let data = self.data(using: .utf8) else { return nil }
        return data.ls_hmacSHA512(key: key)
    }

    // MARK: - 编解码

    /// Base64 编码
    func ls_base64Encoded() -> String? {
        guard let data = self.data(using: .utf8) else { return nil }
        return data.ls_base64EncodedString()
    }

    /// URL 编码
    func ls_urlEncoded() -> String {
        // RFC 3986 保留字符
        let generalDelimiters = ":#[]@"
        let subDelimiters = "!$&'()*+,;="

        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: generalDelimiters + subDelimiters)

        if let tempValue = self.addingPercentEncoding(withAllowedCharacters: allowed) {
            return tempValue
        }
        return self
    }

    /// URL 解码
    func ls_urlDecoded() -> String {
        if let tempValue = self.removingPercentEncoding {
            return tempValue
        }
        return self
    }

    /// HTML 转义
    func ls_escapedHTML() -> String {
        var result = ""
        for scalar in self.unicodeScalars {
            switch scalar.value {
            case 34: result += "&quot;"   // "
            case 38: result += "&amp;"    // &
            case 39: result += "&apos;"   // '
            case 60: result += "&lt;"     // <
            case 62: result += "&gt;"     // >
            default:
                result.append(String(scalar))
            }
        }
        return result
    }

    // MARK: - 绘图

    /// 计算字符串尺寸
    func ls_size(for font: UIFont, size: CGSize, lineBreakMode: NSLineBreakMode) -> CGSize {
        let attributes: [NSAttributedString.Key: Any] = {
            var attrs: [NSAttributedString.Key: Any] = [.font: font]
            if lineBreakMode != .byWordWrapping {
                let paragraph = NSMutableParagraphStyle()
                paragraph.lineBreakMode = lineBreakMode
                attrs[.paragraphStyle] = paragraph
            }
            return attrs
        }()

        let rect = self.boundingRect(
            with: size,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )
        return rect.size
    }

    /// 计算字符串宽度（单行）
    func ls_width(for font: UIFont) -> CGFloat {
        return ls_size(for: font, size: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), lineBreakMode: .byWordWrapping).width
    }

    /// 计算字符串高度（指定宽度）
    func ls_height(for font: UIFont, width: CGFloat) -> CGFloat {
        return ls_size(for: font, size: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude), lineBreakMode: .byWordWrapping).height
    }

    // MARK: - 正则表达式

    /// 是否匹配正则表达式
    func ls_matches(regex: String, options: NSRegularExpression.Options = []) -> Bool {
        guard let pattern = try? NSRegularExpression(pattern: regex, options: options) else {
            return false
        }
        return pattern.firstMatch(in: self, range: NSRange(location: 0, length: self.utf16.count)) != nil
    }

    /// 枚举匹配的正则表达式
    func ls_enumerateRegex(regex: String, options: NSRegularExpression.Options = [], block: (String, NSRange, UnsafeMutablePointer<ObjCBool>) -> Void) {
        guard let pattern = try? NSRegularExpression(pattern: regex, options: options) else { return }
        pattern.enumerateMatches(in: self, range: NSRange(location: 0, length: self.utf16.count)) { result, _, stop in
            guard let result = result else { return }
            let match = (self as NSString).substring(with: result.range)
            block(match, result.range, stop)
        }
    }

    /// 替换匹配的正则表达式
    func ls_replacingRegex(regex: String, options: NSRegularExpression.Options = [], withString replacement: String) -> String {
        guard let pattern = try? NSRegularExpression(pattern: regex, options: options) else { return self }
        return pattern.stringByReplacingMatches(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count), withTemplate: replacement)
    }

    // MARK: - 工具方法

    /// 生成 UUID
    static func ls_uuid() -> String {
        UUID().uuidString
    }

    /// 去除首尾空白字符
    func ls_trim() -> String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 添加 scale 标记到文件名（无扩展名）
    /// 例如："icon" -> "icon@2x"
    func ls_appendingNameScale(_ scale: CGFloat) -> String {
        if abs(scale - 1) < .ulpOfOne || self.isEmpty || self.hasSuffix("/") {
            return self
        }
        return "\(self)@\(scale)x"
    }

    /// 添加 scale 标记到文件路径（带扩展名）
    /// 例如："icon.png" -> "icon@2x.png"
    func ls_appendingPathScale(_ scale: CGFloat) -> String {
        if abs(scale - 1) < .ulpOfOne || self.isEmpty || self.hasSuffix("/") {
            return self
        }

        let ext = (self as NSString).pathExtension
        let nameWithoutExt = (self as NSString).deletingPathExtension

        if ext.isEmpty {
            return "\(nameWithoutExt)@\(scale)x"
        } else {
            return "\(nameWithoutExt)@\(scale)x.\(ext)"
        }
    }

    /// 获取路径中的 scale 值
    /// 例如："icon@2x.png" -> 2.0
    func ls_pathScale() -> CGFloat {
        if self.isEmpty || self.hasSuffix("/") {
            return 1
        }

        let name = (self as NSString).deletingPathExtension
        var scale: CGFloat = 1

        ls_enumerateRegex(regex: "@[0-9]+\\.?[0-9]*x$") { match, range, _ in
            let scaleStr = match.dropFirst().dropLast()
            if let tempValue = CGFloat(Double(scaleStr) {
                scale = tempValue
            } else {
                scale = 1)
            }
        }

        return scale
    }

    /// 是否非空白字符串
    /// nil、""、" "、"\n" 返回 false，其他返回 true
    var ls_isNotBlank: Bool {
        return !self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 是否包含字符串
    func ls_contains(_ string: String) -> Bool {
        return self.range(of: string) != nil
    }

    /// 是否包含字符集中的字符
    func ls_contains(characterSet set: CharacterSet) -> Bool {
        return self.rangeOfCharacter(from: set) != nil
    }

    /// 转换为 NSNumber
    var ls_numberValue: NSNumber? {
        // 尝试解析整数
        if let intValue = Int(self) {
            return NSNumber(value: intValue)
        }

        // 尝试解析浮点数
        if let doubleValue = Double(self) {
            return NSNumber(value: doubleValue)
        }

        // 尝试解析布尔值
        let lowercased = self.lowercased()
        if lowercased == "true" || lowercased == "yes" {
            return NSNumber(value: true)
        }
        if lowercased == "false" || lowercased == "no" {
            return NSNumber(value: false)
        }

        return nil
    }

    /// 转换为 NSData (UTF-8 编码)
    var ls_dataValue: Data? {
        return self.data(using: .utf8)
    }

    /// 获取整个 NSRange
    var ls_rangeOfAll: NSRange {
        return NSRange(location: 0, length: self.utf16.count)
    }

    /// JSON 字符串转换为对象
    var ls_jsonValue: Any? {
        guard let data = self.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: [.allowFragments])
    }

    /// 从主 bundle 读取文件内容
    static func ls_named(_ name: String) -> String? {
        // 尝试读取无扩展名文件
        var path = Bundle.main.path(forResource: name, ofType: "")
        if let tempValue = try? String(contentsOfFile: path {
            content = tempValue
        } else {
            content = "", encoding: .utf8)
        }

        // 如果失败，尝试读取 .txt 文件
        if content == nil {
            path = Bundle.main.path(forResource: name, ofType: "txt")
            if let tempValue = try? String(contentsOfFile: path {
                content = tempValue
            } else {
                content = "", encoding: .utf8)
            }
        }

        return content
    }
}


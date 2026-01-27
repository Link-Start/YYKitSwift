//
//  LSRegex.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  正则表达式工具 - 简化正则匹配和替换
//

#if canImport(UIKit)
import UIKit
import Foundation

// MARK: - LSRegex

/// 正则表达式工具类
public class LSRegex: NSObject {

    // MARK: - 属性

    /// NSRegularExpression 实例
    public let regex: NSRegularExpression

    /// 正则表达式模式
    public let pattern: String

    /// 选项
    public let options: NSRegularExpression.Options

    // MARK: - 初始化

    /// 创建正则表达式
    ///
    /// - Parameters:
    ///   - pattern: 正则表达式模式
    ///   - options: 选项
    /// - Throws: 正则表达式错误
    public init(pattern: String, options: NSRegularExpression.Options = []) throws {
        self.pattern = pattern
        self.options = options
        self.regex = try NSRegularExpression(pattern: pattern, options: options)
        super.init()
    }

    /// 便捷初始化（失败返回 nil）
    ///
    /// - Parameters:
    ///   - pattern: 正则表达式模式
    ///   - options: 选项
    /// - Returns: LSRegex 实例
    public static func make(pattern: String, options: NSRegularExpression.Options = []) -> LSRegex? {
        return try? LSRegex(pattern: pattern, options: options)
    }

    // MARK: - 匹配

    /// 是否匹配
    ///
    /// - Parameter string: 要检查的字符串
    /// - Returns: 是否匹配
    public func matches(_ string: String) -> Bool {
        let range = NSRange(location: 0, length: string.utf16.count)
        return regex.firstMatch(in: string, options: [], range: range) != nil
    }

    /// 第一个匹配
    ///
    /// - Parameter string: 要搜索的字符串
    /// - Returns: 匹配结果
    public func firstMatch(in string: String) -> Match? {
        let range = NSRange(location: 0, length: string.utf16.count)
        guard let result = regex.firstMatch(in: string, options: [], range: range) else {
            return nil
        }
        return Match(result: result, string: string)
    }

    /// 所有匹配
    ///
    /// - Parameter string: 要搜索的字符串
    /// - Returns: 匹配结果数组
    public func matches(in string: String) -> [Match] {
        let range = NSRange(location: 0, length: string.utf16.count)
        guard let results = regex.matches(in: string, options: [], range: range) as? [NSTextCheckingResult] else {
            return []
        }
        return results.map { Match(result: $0, string: string) }
    }

    // MARK: - 替换

    /// 替换匹配
    ///
    /// - Parameters:
    ///   - string: 原字符串
    ///   - template: 替换模板
    ///   - options: 匹配选项
    /// - Returns: 替换后的字符串
    public func replaceMatches(in string: String, with template: String, options: NSRegularExpression.MatchingOptions = []) -> String {
        let range = NSRange(location: 0, length: string.utf16.count)
        return regex.stringByReplacingMatches(in: string, options: options, range: range, withTemplate: template)
    }

    /// 替换匹配（使用闭包）
    ///
    /// - Parameters:
    ///   - string: 原字符串
    ///   - options: 匹配选项
    ///   - block: 替换闭包
    /// - Returns: 替换后的字符串
    public func replaceMatches(in string: String, options: NSRegularExpression.MatchingOptions = [], block: (Match) -> String) -> String {
        let matches = self.matches(in: string)
        var result = string

        for match in matches.reversed() {
            guard let range = Range(match.range, in: string) else { continue }
            let replacement = block(match)
            result.replaceSubrange(range, with: replacement)
        }

        return result
    }

    // MARK: - 枚举

    /// 枚举匹配
    ///
    /// - Parameters:
    ///   - string: 要搜索的字符串
    ///   - options: 匹配选项
    ///   - block: 枚举闭包
    public func enumerateMatches(in string: String, options: NSRegularExpression.MatchingOptions = [], block: (Match) -> Void) {
        let range = NSRange(location: 0, length: string.utf16.count)
        regex.enumerateMatches(in: string, options: options, range: range) { result, _, _ in
            guard let result = result else { return }
            block(Match(result: result, string: string))
        }
    }

    // MARK: - 分割

    /// 按匹配分割字符串
    ///
    /// - Parameters:
    ///   - string: 原字符串
    ///   - options: 匹配选项
    /// - Returns: 分割后的数组
    public func split(_ string: String, options: NSRegularExpression.MatchingOptions = []) -> [String] {
        let matches = self.matches(in: string)
        var result: [String] = []
        var lastIndex = string.startIndex

        for match in matches {
            guard let range = Range(match.range, in: string) else { continue }
            result.append(String(string[lastIndex..<range.lowerBound]))
            lastIndex = range.upperBound
        }

        result.append(String(string[lastIndex...]))
        return result
    }

    // MARK: - 常用正则表达式

    /// 邮箱验证
    public static let email = LSRegex(pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}")!

    /// URL 验证
    public static let url = LSRegex(pattern: "https?://[^s]+")!

    /// 手机号验证（中国大陆）
    public static let phoneNumber = LSRegex(pattern: "^1[3-9]\\d{9}$")!

    /// 身份证号验证（中国大陆）
    public static let idCard = LSRegex(pattern: "^[1-9]\\d{5}(18|19|20)\\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\\d|3[01])\\d{3}[0-9Xx]$")!

    /// IP 地址验证
    public static let ipAddress = LSRegex(pattern: "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$")!

    /// 十六进制颜色验证
    public static let hexColor = LSRegex(pattern: "^#?([a-fA-F0-9]{6}|[a-fA-F0-9]{3})$")!

    /// 用户名验证（字母、数字、下划线，4-16 位）
    public static let username = LSRegex(pattern: "^[a-zA-Z0-9_]{4,16}$")!

    /// 密码验证（至少 8 位，包含字母和数字）
    public static let password = LSRegex(pattern: "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d@$!%*#?&]{8,}$")!

    /// 仅中文字符
    public static let chinese = LSRegex(pattern: "^[\\u4e00-\\u9fa5]+$")!

    /// 仅数字
    public static let numeric = LSRegex(pattern: "^\\d+$")!

    /// 仅字母
    public static let alphabetic = LSRegex(pattern: "^[a-zA-Z]+$")!

    /// 字母数字
    public static let alphanumeric = LSRegex(pattern: "^[a-zA-Z0-9]+$")!

    /// 日期验证 (YYYY-MM-DD)
    public static let date = LSRegex(pattern: "^\\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\\d|3[01])$")!

    /// 时间验证 (HH:MM:SS)
    public static let time = LSRegex(pattern: "^([01]\\d|2[0-3]):[0-5]\\d:[0-5]\\d$")!

    /// 日期时间验证 (YYYY-MM-DD HH:MM:SS)
    public static let dateTime = LSRegex(pattern: "^\\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\\d|3[01]) ([01]\\d|2[0-3]):[0-5]\\d:[0-5]\\d$")!
}

// MARK: - Match

/// 正则匹配结果
public class LSRegex.Match {

    /// NSTextCheckingResult
    public let result: NSTextCheckingResult

    /// 原字符串
    public let string: String

    /// 匹配范围
    public var range: NSRange {
        return result.range
    }

    /// 匹配的字符串
    public var matchedString: String {
        guard let range = Range(result.range, in: string) else { return "" }
        return String(string[range])
    }

    /// 捕获组数量
    public var numberOfRanges: Int {
        return result.numberOfRanges
    }

    /// 初始化
    internal init(result: NSTextCheckingResult, string: String) {
        self.result = result
        self.string = string
    }

    /// 获取捕获组
    ///
    /// - Parameter index: 组索引
    /// - Returns: 捕获的字符串
    public func group(at index: Int) -> String? {
        guard index < result.numberOfRanges else { return nil }
        let range = result.range(at: index)
        guard range.location != NSNotFound,
              let swiftRange = Range(range, in: string) else {
            return nil
        }
        return String(string[swiftRange])
    }

    /// 所有捕获组
    public var groups: [String?] {
        var groups: [String?] = []
        for i in 1..<result.numberOfRanges {
            groups.append(group(at: i))
        }
        return groups
    }
}

// MARK: - String Extension (正则)

public extension String {

    /// 是否匹配正则表达式
    ///
    /// - Parameter pattern: 正则表达式
    /// - Returns: 是否匹配
    func ls_matches(regex pattern: String) -> Bool {
        guard let regex = LSRegex.make(pattern: pattern) else { return false }
        return regex.matches(self)
    }

    /// 正则替换
    ///
    /// - Parameters:
    ///   - pattern: 正则表达式
    ///   - template: 替换模板
    /// - Returns: 替换后的字符串
    func ls_replacingMatches(regex pattern: String, with template: String) -> String {
        guard let regex = LSRegex.make(pattern: pattern) else { return self }
        return regex.replaceMatches(in: self, with: template)
    }

    /// 获取第一个匹配
    ///
    /// - Parameter pattern: 正则表达式
    /// - Returns: 匹配的字符串
    func ls_firstMatch(regex pattern: String) -> String? {
        guard let regex = LSRegex.make(pattern: pattern) else { return nil }
        return regex.firstMatch(in: self)?.matchedString
    }

    /// 获取所有匹配
    ///
    /// - Parameter pattern: 正则表达式
    /// - Returns: 匹配的字符串数组
    func ls_allMatches(regex pattern: String) -> [String] {
        guard let regex = LSRegex.make(pattern: pattern) else { return [] }
        return regex.matches(in: self).map { $0.matchedString }
    }

    /// 按正则分割
    ///
    /// - Parameter pattern: 正则表达式
    /// - Returns: 分割后的数组
    func ls_split(regex pattern: String) -> [String] {
        guard let regex = LSRegex.make(pattern: pattern) else { return [self] }
        return regex.split(self)
    }

    /// 枚举匹配
    ///
    /// - Parameters:
    ///   - pattern: 正则表达式
    ///   - block: 枚举闭包
    func ls_enumerateMatches(regex pattern: String, block: (LSRegex.Match) -> Void) {
        guard let regex = LSRegex.make(pattern: pattern) else { return }
        regex.enumerateMatches(in: self, block: block)
    }

    /// 是否为有效邮箱
    var ls_isValidEmail: Bool {
        return ls_matches(regex: LSRegex.email.pattern)
    }

    /// 是否为有效 URL
    var ls_isValidURL: Bool {
        return ls_matches(regex: LSRegex.url.pattern)
    }

    /// 是否为有效手机号（中国大陆）
    var ls_isValidPhoneNumber: Bool {
        return ls_matches(regex: LSRegex.phoneNumber.pattern)
    }

    /// 是否为有效身份证号（中国大陆）
    var ls_isValidIDCard: Bool {
        return ls_matches(regex: LSRegex.idCard.pattern)
    }

    /// 是否为有效 IP 地址
    var ls_isValidIPAddress: Bool {
        return ls_matches(regex: LSRegex.ipAddress.pattern)
    }

    /// 是否为有效日期
    var ls_isValidDate: Bool {
        return ls_matches(regex: LSRegex.date.pattern)
    }

    /// 是否为纯中文
    var ls_isChinese: Bool {
        return ls_matches(regex: LSRegex.chinese.pattern)
    }

    /// 是否为纯数字
    var ls_isNumeric: Bool {
        return ls_matches(regex: LSRegex.numeric.pattern)
    }

    /// 是否为纯字母
    var ls_isAlphabetic: Bool {
        return ls_matches(regex: LSRegex.alphabetic.pattern)
    }

    /// 是否为字母数字组合
    var ls_isAlphanumeric: Bool {
        return ls_matches(regex: LSRegex.alphanumeric.pattern)
    }
}

// MARK: - 常用验证

public extension String {

    /// 是否为空或仅空白字符
    var ls_isBlank: Bool {
        return trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 是否包含数字
    var ls_containsNumber: Bool {
        return ls_matches(regex: ".*\\d.*")
    }

    /// 是否包含字母
    var ls_containsLetter: Bool {
        return ls_matches(regex: ".*[a-zA-Z].*")
    }

    /// 是否包含大写字母
    var ls_containsUpperCase: Bool {
        return ls_matches(regex: ".*[A-Z].*")
    }

    /// 是否包含小写字母
    var ls_containsLowerCase: Bool {
        return ls_matches(regex: ".*[a-z].*")
    }

    /// 是否包含特殊字符
    var ls_containsSpecialCharacter: Bool {
        return ls_matches(regex: ".*[^a-zA-Z0-9].*")
    }

    /// 密码强度评估
    var ls_passwordStrength: PasswordStrength {
        var score = 0

        if count >= 8 { score += 1 }
        if count >= 12 { score += 1 }
        if ls_containsNumber { score += 1 }
        if ls_containsUpperCase { score += 1 }
        if ls_containsLowerCase { score += 1 }
        if ls_containsSpecialCharacter { score += 1 }

        switch score {
        case 0...2: return .weak
        case 3...4: return .medium
        case 5...6: return .strong
        default: return .weak
        }
    }

    /// 密码强度
    enum PasswordStrength {
        case weak
        case medium
        case strong

        var description: String {
            switch self {
            case .weak: return "弱"
            case .medium: return "中"
            case .strong: return "强"
            }
        }
    }
}

#endif

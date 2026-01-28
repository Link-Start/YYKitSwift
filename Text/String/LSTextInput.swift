//
//  LSTextInput.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  文本输入协议和类 - 用于 UITextView/UITextField 的扩展
//

#if canImport(UIKit)
import UIKit

// MARK: - LSTextPosition

/// 文本位置（UITextProtocol 的 Swift 实现）
public class LSTextPosition: UITextPosition {

    public let offset: Int

    public init(offset: Int) {
        self.offset = offset
        super.init()
    }
}

// MARK: - LSTextRange

/// 文本范围（UITextRange 的 Swift 实现）
public class LSTextRange: UITextRange {

    public let start: LSTextPosition
    public let end: LSTextPosition

    public init(start: LSTextPosition, end: LSTextPosition) {
        self.start = start
        self.end = end
        super.init()
    }

    public convenience init(location: Int, length: Int) {
        let start = LSTextPosition(offset: location)
        let end = LSTextPosition(offset: location + length)
        self.init(start: start, end: end)
    }

    public override var isEmpty: Bool {
        return start.offset >= end.offset
    }

    public var nsRange: NSRange {
        let length = max(0, end.offset - start.offset)
        return NSRange(location: start.offset, length: length)
    }
}

// MARK: - LSTextSelectionRect

/// 文本选择矩形（UITextSelectionRect 的 Swift 实现）
public class LSTextSelectionRect: UITextSelectionRect {

    public let rect: CGRect
    public let writingDirection: UITextWritingDirection
    public let containsStart: Bool
    public let containsEnd: Bool
    public let isVertical: Bool

    public init(rect: CGRect, writingDirection: UITextWritingDirection = .leftToRight, containsStart: Bool = false, containsEnd: Bool = false, isVertical: Bool = false) {
        self.rect = rect
        self.writingDirection = writingDirection
        self.containsStart = containsStart
        self.containsEnd = containsEnd
        self.isVertical = isVertical
        super.init()
    }

    public override var rect: CGRect {
        return self.rect
    }
}

// MARK: - LSTextInputDelegate

/// 文本输入代理协议
public protocol LSTextInputDelegate: AnyObject {

    /// 文本即将更改
    ///
    /// - Parameters:
    ///   - textInput: 文本输入对象
    ///   - range: 受影响的范围
    ///   - replacementText: 替换文本
    /// - Returns: 是否允许更改
    func textInput(_ textInput: AnyObject, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool

    /// 文本已更改
    ///
    /// - Parameters:
    ///   - textInput: 文本输入对象
    func textDidChange(_ textInput: AnyObject)

    /// 选择已更改
    ///
    /// - Parameters:
    ///   - textInput: 文本输入对象
    func selectionDidChange(_ textInput: AnyObject)

    /// 开始编辑
    ///
    /// - Parameters:
    ///   - textInput: 文本输入对象
    func textInputDidBeginEditing(_ textInput: AnyObject)

    /// 结束编辑
    ///
    /// - Parameters:
    ///   - textInput: 文本输入对象
    func textInputDidEndEditing(_ textInput: AnyObject)

    /// 按下返回键
    ///
    /// - Parameters:
    ///   - textInput: 文本输入对象
    /// - Returns: 是否处理
    func textInputShouldReturn(_ textInput: AnyObject) -> Bool
}

// MARK: - LSTextInput Utilities

/// 文本输入工具类
public class LSTextInputUtilities: NSObject {

    // MARK: - 文本验证

    /// 验证邮箱格式
    ///
    /// - Parameter email: 邮箱地址
    /// - Returns: 是否有效
    public static func isValid(email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    /// 验证手机号格式（中国大陆）
    ///
    /// - Parameter phoneNumber: 手机号
    /// - Returns: 是否有效
    public static func isValid(phoneNumber: String) -> Bool {
        let phoneRegex = "^1[3-9]\\d{9}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phoneNumber)
    }

    /// 验证密码格式
    ///
    /// - Parameters:
    ///   - password: 密码
    ///   - minLength: 最小长度
    /// - Returns: 是否有效
    public static func isValid(password: String, minLength: Int = 6) -> Bool {
        return password.count >= minLength
    }

    /// 验证 URL 格式
    ///
    /// - Parameter urlString: URL 字符串
    /// - Returns: 是否有效
    public static func isValid(url urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    // MARK: - 文本格式化

    /// 格式化手机号（中间 4 位隐藏）
    ///
    /// - Parameter phoneNumber: 手机号
    /// - Returns: 格式化后的手机号
    public static func format(phoneNumber: String) -> String {
        guard phoneNumber.count == 11 else { return phoneNumber }

        let prefix = String(phoneNumber.prefix(3))
        let suffix = String(phoneNumber.suffix(4))

        return "\(prefix)****\(suffix)"
    }

    /// 格式化银行卡号（每 4 位一组）
    ///
    /// - Parameter cardNumber: 银行卡号
    /// - Returns: 格式化后的卡号
    public static func format(cardNumber: String) -> String {
        var formatted = ""
        for (index, char) in cardNumber.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += " "
            }
            formatted.append(char)
        }
        return formatted
    }

    /// 格式化金额（添加千分位分隔符）
    ///
    /// - Parameters:
    ///   - amount: 金额
    ///   - decimals: 小数位数
    /// - Returns: 格式化后的金额
    public static func format(amount: Double, decimals: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = decimals
        formatter.maximumFractionDigits = decimals
        if let tempValue = formatter.string(from: NSNumber(value: amount)) {
            return tempValue
        }
        return ""
    }

    // MARK: - 文本清理

    /// 移除字符串两端的空白
    ///
    /// - Parameter string: 原始字符串
    /// - Returns: 清理后的字符串
    public static func trim(_ string: String) -> String {
        return string.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 移除所有空白
    ///
    /// - Parameter string: 原始字符串
    /// - Returns: 清理后的字符串
    public static func removeAllWhitespaces(_ string: String) -> String {
        return string.replacingOccurrences(of: "\\s", with: "", options: .regularExpression)
    }

    /// 移除换行符
    ///
    /// - Parameter string: 原始字符串
    /// - Returns: 清理后的字符串
    public static func removeNewlines(_ string: String) -> String {
        return string.replacingOccurrences(of: "\\r|\\n", with: "", options: .regularExpression)
    }

    // MARK: - 文本转换

    /// 转换为首字母大写
    ///
    /// - Parameter string: 原始字符串
    /// - Returns: 转换后的字符串
    public static func capitalize(_ string: String) -> String {
        return string.capitalized
    }

    /// 转换为小写
    ///
    /// - Parameter string: 原始字符串
    /// - Returns: 转换后的字符串
    public static func lowercase(_ string: String) -> String {
        return string.lowercased()
    }

    /// 转换为大写
    ///
    /// - Parameter string: 原始字符串
    /// - Returns: 转换后的字符串
    public static func uppercase(_ string: String) -> String {
        return string.uppercased()
    }

    // MARK: - 文本截断

    /// 截断文本到指定长度
    ///
    /// - Parameters:
    ///   - string: 原始字符串
    ///   - length: 最大长度
    ///   - trailing: 截断后缀（默认 "…"）
    /// - Returns: 截断后的字符串
    public static func truncate(_ string: String, length: Int, trailing: String = "…") -> String {
        guard string.count > length else { return string }

        let index = string.index(string.startIndex, offsetBy: length)
        var truncated = String(string[..<index])

        if !trailing.isEmpty {
            truncated += trailing
        }

        return truncated
    }
}

#endif

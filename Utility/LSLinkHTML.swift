//
//  LSLinkHTML.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  HTML 链接检测器 - 自动检测和转换 URL 为可点击链接
//

#if canImport(UIKit)
import UIKit
import Foundation

// MARK: - LSLinkHTML

/// LSLinkHTML 用于检测和转换文本中的链接
///
/// 支持检测以下类型的链接：
/// - HTTP/HTTPS URL
/// - 邮箱地址
/// - 电话号码
/// - Mentions (@username)
/// - Hashtags (#topic)
public class LSLinkHTML: NSObject {

    // MARK: - 属性

    /// 链接颜色
    public var linkColor: UIColor = .blue

    /// 链接下划线
    public var linkUnderline: Bool = true

    /// 高亮颜色
    public var highlightColor: UIColor?

    /// 链接字体
    public var linkFont: UIFont?

    // MARK: - 链接检测

    /// 检测文本中的所有链接
    ///
    /// - Parameter text: 原始文本
    /// - Returns: 链接数组
    public static func detectLinks(in text: String) -> [LSLink] {
        var links: [LSLink] = []

        // 检测 URL
        links.append(contentsOf: detectURLs(in: text))

        // 检测邮箱
        links.append(contentsOf: detectEmails(in: text))

        // 检测电话号码
        links.append(contentsOf: detectPhoneNumbers(in: text))

        // 检测 Mentions
        links.append(contentsOf: detectMentions(in: text))

        // 检测 Hashtags
        links.append(contentsOf: detectHashtags(in: text))

        // 按位置排序并去重
        links = links.sorted { $0.range.location < $1.range.location }
        var uniqueLinks: [LSLink] = []
        for link in links {
            if !uniqueLinks.contains(where: { $0.range.overlaps(link.range) }) {
                uniqueLinks.append(link)
            }
        }

        return uniqueLinks
    }

    /// 检测文本中的 URL
    ///
    /// - Parameter text: 原始文本
    /// - Returns: 链接数组
    public static func detectURLs(in text: String) -> [LSLink] {
        let urlPattern = "(?i)\\b((?:https?://|www\\d{0,3}[.]|[a-z0-9.\\-]+[.][a-z]{2,4}/)(?:[^\\s()<>]+|\\(([^\\s()<>]+|(?:\\([^\\s()<>]+\\)))*\\))+(?:\\(([^\\s()<>]+|(?:\\([^\\s()<>]+\\)))*\\)|[^\\s`!()\\[\\]{};:'\".,<>?]))"
        return detectPattern(in: text, pattern: urlPattern, type: LSLink.LSLinkType.url)
    }

    /// 检测文本中的邮箱地址
    ///
    /// - Parameter text: 原始文本
    /// - Returns: 链接数组
    public static func detectEmails(in text: String) -> [LSLink] {
        let emailPattern = "(?i)\\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,64}\\b"
        return detectPattern(in: text, pattern: emailPattern, type: LSLink.LSLinkType.email)
    }

    /// 检测文本中的电话号码
    ///
    /// - Parameter text: 原始文本
    /// - Returns: 链接数组
    public static func detectPhoneNumbers(in text: String) -> [LSLink] {
        let phonePattern = "\\b\\d{3}[-.]?\\d{3}[-.]?\\d{4}\\b|\\b\\d{11}\\b"
        return detectPattern(in: text, pattern: phonePattern, type: LSLink.LSLinkType.phoneNumber)
    }

    /// 检测文本中的 Mentions
    ///
    /// - Parameter text: 原始文本
    /// - Returns: 链接数组
    public static func detectMentions(in text: String) -> [LSLink] {
        let mentionPattern = "(?<!\\w)@[A-Za-z0-9_]{1,20}"
        return detectPattern(in: text, pattern: mentionPattern, type: LSLink.LSLinkType.mention)
    }

    /// 检测文本中的 Hashtags
    ///
    /// - Parameter text: 原始文本
    /// - Returns: 链接数组
    public static func detectHashtags(in text: String) -> [LSLink] {
        let hashtagPattern = "(?<!\\w)#[A-Za-z0-9_]{1,50}"
        return detectPattern(in: text, pattern: hashtagPattern, type: LSLink.LSLinkType.hashtag)
    }

    // MARK: - 文本转换

    /// 将文本中的链接转换为可点击的属性字符串
    ///
    /// - Parameters:
    ///   - text: 原始文本
    ///   - linkColor: 链接颜色
    ///   - linkUnderline: 是否添加下划线
    /// - Returns: 属性字符串
    public static func linkified(
        text: String,
        linkColor: UIColor = .blue,
        linkUnderline: Bool = true
    ) -> NSAttributedString {
        let links = detectLinks(in: text)
        let attributed = NSMutableAttributedString(string: text)

        for link in links {
            var attrs: [NSAttributedString.Key: Any] = [:]
            attrs[.foregroundColor] = linkColor
            attrs[.underlineColor] = linkColor
            attrs[.underlineStyle] = linkUnderline ? NSUnderlineStyle.single.rawValue : 0
            attrs[LSLinkAttributeName] = link

            attributed.addAttributes(attrs, range: link.range)
        }

        return attributed
    }

    // MARK: - 私有方法

    private static func detectPattern(in text: String, pattern: String, type: LSLinkType) -> [LSLink] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }

        let range = NSRange(location: 0, length: text.utf16.count)
        let matches = regex.matches(in: text, options: [], range: range)

        return matches.map { match in
            let linkText = (text as NSString).substring(with: match.range)
            let url: URL?

            switch type {
            case .url:
                var urlString = linkText
                if !urlString.lowercased().hasPrefix("http") {
                    urlString = "http://" + urlString
                }
                url = URL(string: urlString)
            case .email:
                url = URL(string: "mailto:\(linkText)")
            case .phoneNumber:
                url = URL(string: "tel:\(linkText)")
            case .mention:
                url = URL(string: "mention:\(linkText)")
            case .hashtag:
                url = URL(string: "hashtag:\(linkText)")
            }

            return LSLink(type: type, text: linkText, url: url, range: match.range)
        }
    }
}

// MARK: - LSLink

/// LSLink 表示一个文本链接
public class LSLink: NSObject {

    // MARK: - 类型定义

    /// 链接类型
    public enum LSLinkType {
        case url
        case email
        case phoneNumber
        case mention
        case hashtag
    }

    // MARK: - 属性

    /// 链接类型
    public let type: LSLinkType

    /// 链接文本
    public let text: String

    /// 链接 URL
    public let url: URL?

    /// 文本范围
    public let range: NSRange

    // MARK: - 初始化

    public init(type: LSLinkType, text: String, url: URL?, range: NSRange) {
        self.type = type
        self.text = text
        self.url = url
        self.range = range
        super.init()
    }
}

// MARK: - LSLink Attribute Name

/// LSLink 属性名称
public let LSLinkAttributeName = NSAttributedString.Key("LSLinkAttributeName")

// MARK: - NSRange Extension

private extension NSRange {
    func overlaps(_ other: NSRange) -> Bool {
        return location < other.location + other.length && other.location < location + length
    }
}

#endif

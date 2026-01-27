//
//  UIPasteboard+YYKitSwift.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  UIPasteboard 扩展 - 剪贴板便捷方法
//

#if canImport(UIKit)
import UIKit

// MARK: - UIPasteboard Extension

extension UIPasteboard {

    // MARK: - 便捷属性

    /// 是否有文本内容
    public var ls_hasText: Bool {
        return hasStrings
    }

    /// 是否有图片内容
    public var ls_hasImage: Bool {
        return hasImages
    }

    /// 是否有 URL 内容
    public var ls_hasURL: Bool {
        return hasURLs
    }

    /// 是否有颜色内容
    public var ls_hasColor: Bool {
        return hasColors
    }

    // MARK: - 文本操作

    /// 复制文本到剪贴板
    ///
    /// - Parameter text: 要复制的文本
    public static func ls_copy(_ text: String) {
        general.string = text
    }

    /// 复制富文本到剪贴板
    ///
    /// - Parameter text: 要复制的富文本
    public static func ls_copy(_ text: NSAttributedString) {
        general.string = text.string
        // 尝试保存富文本数据
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: text, requiringSecureCoding: false) {
            general.setData(data, forPasteboardType: "com.apple.rtfd")
        }
    }

    /// 获取剪贴板文本
    ///
    /// - Returns: 剪贴板文本（nil 表示无文本）
    public static func ls_text() -> String? {
        return general.string
    }

    /// 获取剪贴板富文本
    ///
    /// - Returns: 剪贴板富文本（nil 表示无富文本）
    public static func ls_attributedText() -> NSAttributedString? {
        // 尝试从 RTFD 数据读取
        if let data = general.data(forPasteboardType: "com.apple.rtfd"),
           let attributedString = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: data) {
            return attributedString
        }

        // 尝试从 RTF 数据读取
        if let data = general.data(forPasteboardType: "public.rtf"),
           let attributedString = NSAttributedString(rtf: data, documentAttributes: nil) {
            return attributedString
        }

        // 回退到纯文本
        if let string = general.string {
            return NSAttributedString(string: string)
        }

        return nil
    }

    // MARK: - 图片操作

    /// 复制图片到剪贴板
    ///
    /// - Parameter image: 要复制的图片
    public static func ls_copy(_ image: UIImage) {
        general.image = image
    }

    /// 获取剪贴板图片
    ///
    /// - Returns: 剪贴板图片（nil 表示无图片）
    public static func ls_image() -> UIImage? {
        return general.image
    }

    // MARK: - URL 操作

    /// 复制 URL 到剪贴板
    ///
    /// - Parameter url: 要复制的 URL
    public static func ls_copy(_ url: URL) {
        general.url = url
        // 同时复制 URL 字符串
        general.string = url.absoluteString
    }

    /// 获取剪贴板 URL
    ///
    /// - Returns: 剪贴板 URL（nil 表示无 URL）
    public static func ls_url() -> URL? {
        return general.url
    }

    // MARK: - 颜色操作

    /// 复制颜色到剪贴板
    ///
    /// - Parameter color: 要复制的颜色
    public static func ls_copy(_ color: UIColor) {
        general.colors = [color]
    }

    /// 获取剪贴板颜色
    ///
    /// - Returns: 剪贴板颜色数组（nil 表示无颜色）
    public static func ls_colors() -> [UIColor]? {
        return general.color?.colors
    }

    // MARK: - 数据操作

    /// 复制自定义数据到剪贴板
    ///
    /// - Parameters:
    ///   - data: 要复制的数据
    ///   - type: 数据类型标识
    public static func ls_copy(_ data: Data, forType type: String) {
        general.setData(data, forPasteboardType: type)
    }

    /// 获取剪贴板自定义数据
    ///
    /// - Parameter type: 数据类型标识
    /// - Returns: 数据（nil 表示无该类型数据）
    public static func ls_data(forType type: String) -> Data? {
        return general.data(forPasteboardType: type)
    }

    // MARK: - 清空操作

    /// 清空剪贴板
    public static func ls_clear() {
        general.items = []
    }

    // MARK: - 检测操作

    /// 检查剪贴板是否包含指定类型
    ///
    /// - Parameter type: 数据类型标识
    /// - Returns: 是否包含
    public static func ls_contains(_ type: String) -> Bool {
        return general.contains(pasteboardTypes: [type] as? [String] ?? []) ?? false
    }

    /// 获取剪贴板所有可用类型
    ///
    /// - Returns: 类型数组
    public static func ls_availableTypes() -> [String] {
        return general.items.first?.keys.compactMap { $0 as? String } ?? []
    }
}

// MARK: - UIPasteboard 扩展方法

extension UIPasteboard {

    /// 复制多种类型的数据到剪贴板
    ///
    /// - Parameter items: 要复制的数据项字典数组
    public func ls_copyItems(_ items: [[String: Any]]) {
        self.items = items
    }

    /// 复制文本和图片到剪贴板
    ///
    /// - Parameters:
    ///   - text: 文本
    ///   - image: 图片
    public func ls_copy(text: String, image: UIImage?) {
        var item: [String: Any] = ["public.utf8-plain-text": text]

        if let image = image {
            item["public.png"] = image.pngData()
            item["public.jpeg"] = image.jpegData(compressionQuality: 0.9)
        }

        items = [item]
    }

    /// 复制 HTML 到剪贴板
    ///
    /// - Parameter html: HTML 字符串
    public func ls_copyHTML(_ html: String) {
        let item: [String: Any] = [
            "public.html": html.data(using: .utf8) ?? Data(),
            "public.utf8-plain-text": html.strippedHTML
        ]
        items = [item]
    }

    /// 获取 HTML 内容
    ///
    /// - Returns: HTML 字符串（nil 表示无 HTML）
    public func ls_html() -> String? {
        if let data = data(forPasteboardType: "public.html") {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}

// MARK: - String Extension (HTML Stripping)

private extension String {
    var strippedHTML: String {
        // 简单的 HTML 标签移除
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
    }
}

// MARK: - LSTextPasteboard

/// 文本剪贴板辅助类
public class LSTextPasteboard {

    /// 共享剪贴板（general）
    public static var general: UIPasteboard {
        return UIPasteboard.general
    }

    // MARK: - 富文本支持

    /// 复制富文本到剪贴板（保留格式）
    ///
    /// - Parameter text: 富文本
    public static func copyAttributedText(_ text: NSAttributedString) {
        UIPasteboard.ls_copy(text)
    }

    /// 获取剪贴板富文本
    ///
    /// - Returns: 富文本（nil 表示无）
    public static func attributedText() -> NSAttributedString? {
        return UIPasteboard.ls_attributedText()
    }

    // MARK: - 附加信息支持

    /// 复制带附加信息的文本
    ///
    /// - Parameters:
    ///   - text: 文本
    ///   - source: 来源（可选）
    ///   - timestamp: 时间戳（可选）
    public static func copy(_ text: String, source: String? = nil, timestamp: Date? = nil) {
        var item: [String: Any] = ["public.utf8-plain-text": text]

        // 添加元数据
        if let source = source {
            item["com.xiaoyueyun.pasteboard.source"] = source.data(using: .utf8)
        }

        if let timestamp = timestamp {
            item["com.xiaoyueyun.pasteboard.timestamp"] = timestamp.timeIntervalSince1970
        }

        UIPasteboard.general.items = [item]
    }

    /// 获取元数据
    ///
    /// - Parameter key: 元数据键
    /// - Returns: 元数据值
    public static func metadata(forKey key: String) -> Any? {
        return UIPasteboard.general.value(forPasteboardKey: key)
    }

    // MARK: - 历史记录支持

    /// 最大历史记录数
    public static var maxHistoryCount: Int = 10

    /// 粘贴板历史记录（使用 UserDefaults 存储）
    private static let historyKey = "com.xiaoyueyun.pasteboard.history"

    /// 添加到历史记录
    ///
    /// - Parameter text: 文本
    public static func addToHistory(_ text: String) {
        guard !text.isEmpty else { return }

        var history = loadHistory()

        // 移除重复项
        history.removeAll { $0 == text }

        // 添加到开头
        history.insert(text, at: 0)

        // 限制数量
        if history.count > maxHistoryCount {
            history = Array(history.prefix(maxHistoryCount))
        }

        saveHistory(history)
    }

    /// 加载历史记录
    ///
    /// - Returns: 历史记录数组
    public static func loadHistory() -> [String] {
        return UserDefaults.standard.stringArray(forKey: historyKey) ?? []
    }

    /// 保存历史记录
    ///
    /// - Parameter history: 历史记录数组
    private static func saveHistory(_ history: [String]) {
        UserDefaults.standard.set(history, forKey: historyKey)
    }

    /// 清空历史记录
    public static func clearHistory() {
        UserDefaults.standard.removeObject(forKey: historyKey)
    }

    /// 检查文本是否在历史记录中
    ///
    /// - Parameter text: 文本
    /// - Returns: 是否存在
    public static func isInHistory(_ text: String) -> Bool {
        return loadHistory().contains(text)
    }
}

#endif

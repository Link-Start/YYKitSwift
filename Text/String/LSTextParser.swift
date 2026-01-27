//
//  LSTextParser.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  文本解析器 - 用于解析和转换文本内容
//

#if canImport(UIKit)
import UIKit

// MARK: - LSTextParser Protocol

/// LSTextParser 协议
///
/// 文本解析器用于在文本布局前修改或增强文本内容
public protocol LSTextParser: NSObjectProtocol {

    /// 解析并修改文本
    ///
    /// - Parameters:
    ///   - text: 可变的富文本
    ///   - selectedRange: 当前选择的范围（可以为 nil）
    /// - Returns: 是否成功解析
    func parse(_ text: NSMutableAttributedString, selectedRange: NSRangePointer?) -> Bool
}

// MARK: - LSTextSimpleMarkdownParser

/// 简单的 Markdown 解析器
///
/// 支持基本的 Markdown 语法：
/// - `**粗体**` → 粗体
/// - `*斜体*` → 斜体
/// - `` `代码` `` → 等宽字体
/// - `~~删除线~~` → 删除线
public class LSTextSimpleMarkdownParser: NSObject, LSTextParser {

    // MARK: - 属性

    /// 粗体字体大小倍数（默认 1.0）
    public var boldFontSizeMultiplier: CGFloat = 1.0

    /// 粗体颜色
    public var boldColor: UIColor?

    /// 斜体颜色
    public var italicColor: UIColor?

    /// 代码字体
    public var codeFont: UIFont?

    /// 代码背景颜色
    public var codeBackgroundColor: UIColor?

    /// 删除线颜色
    public var strikethroughColor: UIColor?

    /// 最大解析深度（防止循环引用）
    public var maxParseDepth: Int = 10

    // MARK: - 初始化

    public override init() {
        super.init()
    }

    // MARK: - LSTextParser

    public func parse(_ text: NSMutableAttributedString, selectedRange: NSRangePointer?) -> Bool {
        return parse(text, selectedRange: selectedRange, depth: 0)
    }

    private func parse(_ text: NSMutableAttributedString, selectedRange: NSRangePointer?, depth: Int) -> Bool {
        guard depth < maxParseDepth else { return false }

        let fullRange = NSRange(location: 0, length: text.length)
        var modified = false

        // 解析粗体 **text**
        modified = parseBold(text, range: fullRange) || modified

        // 解析斜体 *text*
        modified = parseItalic(text, range: fullRange) || modified

        // 解析删除线 ~~text~~
        modified = parseStrikethrough(text, range: fullRange) || modified

        // 解析代码 `text`
        modified = parseCode(text, range: fullRange) || modified

        // 调整选择范围
        if let selectedRange = selectedRange, modified {
            adjustRangeForEmoji(text, selectedRange: selectedRange)
        }

        return modified
    }

    // MARK: - Emoji 范围调整

    /// 调整选择范围以包含完整的 emoji 序列
    ///
    /// Emoji 可能由多个 Unicode 码点组成：
    /// - Skin tone 修饰符 (Fitzpatrick type 1-6)
    /// - Zero-width joiner (ZWJ)
    /// - Variation selector
    /// - 组合标记
    ///
    /// - Parameters:
    ///   - text: 属性字符串
    ///   - selectedRange: 选择范围指针
    private func adjustRangeForEmoji(_ text: NSAttributedString, selectedRange: NSRangePointer) {
        let string = text.string
        let length = string.count

        guard selectedRange.pointee.location < length else { return }

        // 向前扩展起始位置
        var start = selectedRange.pointee.location
        while start > 0 {
            let clusterRange = (string as NSString).rangeOfComposedCharacterSequences(for: start, range: NSRange(location: 0, length: length))
            if clusterRange.location == start {
                // 当前位置已经是簇的起始
                break
            }
            start = clusterRange.location
        }

        // 向后扩展结束位置
        var end = selectedRange.pointee.location + selectedRange.pointee.length - 1
        if end < length {
            // 获取结束位置的字符簇
            let clusterRange = (string as NSString).rangeOfComposedCharacterSequences(for: end, range: NSRange(location: 0, length: length))
            if clusterRange.location + clusterRange.length - 1 == end {
                // 当前位置在簇的末尾，需要包含整个簇
                end = clusterRange.location + clusterRange.length - 1
            }
        }

        // 处理特定 emoji 序列
        // 检查 skin tone 修饰符
        if start + 1 < length {
            let nextChar = (string as NSString).character(at: start + 1)
            if _isSkinToneModifier(nextChar) {
                // 包含后续的 skin tone 修饰符
                var adjustedEnd = start + 1
                while adjustedEnd < length {
                    let char = (string as NSString).character(at: adjustedEnd)
                    if !_isSkinToneModifier(char) {
                        break
                    }
                    adjustedEnd += 1
                }
                end = max(end, adjustedEnd)
            }
        }

        // 检查 ZWJ 序列
        if end + 1 < length {
            let nextChar = (string as NSString).character(at: end + 1)
            if nextChar == 0x200D { // ZWJ
                // 包含 ZWJ 序列，扩展到完整 emoji
                var adjustedEnd = end + 1
                while adjustedEnd + 1 < length {
                    let char = (string as NSString).character(at: adjustedEnd + 1)
                    if char == 0x200D || _isEmojiBase(char) {
                        adjustedEnd += 1
                    } else {
                        break
                    }
                }
                end = max(end, adjustedEnd)
            }
        }

        // 检查 variation selector
        if end + 1 < length {
            let nextChar = (string as NSString).character(at: end + 1)
            if nextChar == 0xFE0E || nextChar == 0xFE0F { // VS15/VS16
                end += 1
            }
        }

        // 更新选择范围
        selectedRange.pointee = NSRange(location: start, length: max(0, end - start + 1))
    }

    /// 检查是否为 skin tone 修饰符
    private func _isSkinToneModifier(_ char: UniChar) -> Bool {
        return char >= 0x1F3FB && char <= 0x1F3FF
    }

    /// 检查是否为 emoji 基础字符
    private func _isEmojiBase(_ char: UniChar) -> Bool {
        // 简化检查：包含常见 emoji 范围
        // 完整实现应包含所有 emoji 块
        let emojiRanges: [(ClosedRange<UInt32>, UInt32)] = [
            (0x1F600...0x1F64F, 1),  // Emoticons
            (0x1F300...0x1F5FF, 1),  // Misc Symbols and Pictographs
            (0x1F680...0x1F6FF, 1),  // Transport and Map
            (0x1F900...0x1F9FF, 1),  // Supplemental Symbols and Pictographs
            (0x2600...0x27BF, 1),     // Misc symbols
            (0x1F000...0x1F0FF, 1),    // Variation Selectors
            (0x1F300...0x1F9FF, 1),    // Extended emoji
        ]

        for (range, _) in emojiRanges {
            if char >= UInt32(range.lowerBound) && char <= UInt32(range.upperBound) {
                return true
            }
        }

        return false
    }

    // MARK: - 私有解析方法

    private func parseBold(_ text: NSMutableAttributedString, range: NSRange) -> Bool {
        let pattern = "\\*\\*([^*]+?)\\*\\*"
        return parsePattern(text, pattern: pattern, range: range) { matchRange in
            var attrs: [NSAttributedString.Key: Any] = [:]

            // 字体
            if let font = text.attribute(.font, at: matchRange.location, effectiveRange: nil) as? UIFont {
                let newFont: UIFont
                if boldFontSizeMultiplier != 1.0 {
                    let size = font.pointSize * boldFontSizeMultiplier
                    newFont = UIFont(descriptor: font.fontDescriptor.withSymbolicTraits(.traitBold), size: size)
                } else {
                    newFont = UIFont(descriptor: font.fontDescriptor.withSymbolicTraits(.traitBold), size: font.pointSize)
                }
                attrs[.font] = newFont
            }

            // 颜色
            if let color = boldColor {
                attrs[.foregroundColor] = color
            }

            return attrs
        }
    }

    private func parseItalic(_ text: NSMutableAttributedString, range: NSRange) -> Bool {
        let pattern = "(?<!\\*)\\*([^*]+?)\\*(?!\\*)"
        return parsePattern(text, pattern: pattern, range: range) { matchRange in
            var attrs: [NSAttributedString.Key: Any] = [:]

            // 字体
            if let font = text.attribute(.font, at: matchRange.location, effectiveRange: nil) as? UIFont {
                let newFont = UIFont(descriptor: font.fontDescriptor.withSymbolicTraits(.traitItalic), size: font.pointSize)
                attrs[.font] = newFont
            }

            // 颜色
            if let color = italicColor {
                attrs[.foregroundColor] = color
            }

            return attrs
        }
    }

    private func parseStrikethrough(_ text: NSMutableAttributedString, range: NSRange) -> Bool {
        let pattern = "~~([^~]+?)~~"
        return parsePattern(text, pattern: pattern, range: range) { matchRange in
            let decoration = LSTextDecoration(style: .single)
            var attrs: [NSAttributedString.Key: Any] = [
                LSTextStrikethroughAttributeName: decoration
            ]

            // 颜色
            if let color = strikethroughColor {
                attrs[.foregroundColor] = color
            }

            return attrs
        }
    }

    private func parseCode(_ text: NSMutableAttributedString, range: NSRange) -> Bool {
        let pattern = "`([^`]+?)`"
        return parsePattern(text, pattern: pattern, range: range) { matchRange in
            var attrs: [NSAttributedString.Key: Any] = [:]

            // 字体
            if let font = codeFont {
                attrs[.font] = font
            } else {
                attrs[.font] = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
            }

            // 背景边框
            let fillColor: UIColor
            if let color = codeBackgroundColor {
                fillColor = color
            } else {
                fillColor = UIColor(white: 0.9, alpha: 1)
            }
            let border = LSTextBorder(fillColor: fillColor, cornerRadius: 4)
            border.insets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 2)
            attrs[LSTextBackgroundBorderAttributeName] = border

            return attrs
        }
    }

    private func parsePattern(_ text: NSMutableAttributedString, pattern: String, range: NSRange, attributes: (NSRange) -> [NSAttributedString.Key: Any]) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return false }

        let matches = regex.matches(in: text.string, options: [], range: range)
        var modified = false

        // 从后往前处理，避免索引问题
        for match in matches.reversed() {
            let contentRange = match.range(at: 1)
            guard contentRange.location != NSNotFound else { continue }

            let attrs = attributes(contentRange)

            // 移除 Markdown 标记
            text.deleteCharacters(in: match.range)

            // 应用属性到内容
            let adjustedRange = NSRange(location: contentRange.location, length: contentRange.length)
            text.addAttributes(attrs, range: adjustedRange)

            modified = true
        }

        return modified
    }
}

// MARK: - LSTextSimpleEmoticonParser

/// 简单的 Emoji 解析器
///
/// 将文本中的 emoji 代码（如 `:smile:`）转换为实际的 emoji 字符或图片
public class LSTextSimpleEmoticonParser: NSObject, LSTextParser {

    // MARK: - 属性

    /// emoji 映射字典
    ///
    /// 键为 emoji 代码（如 `:smile:`），值为替换内容（字符串或图片）
    public var emoticonMapper: [String: Any] = [:]

    /// 默认字体大小（用于图片 emoji）
    public var defaultEmoticonSize: CGFloat = 16

    // MARK: - 初始化

    public override init() {
        super.init()

        // 默认 emoji 映射
        setupDefaultEmoticons()
    }

    public convenience init(emoticonMapper: [String: Any]) {
        self.init()
        self.emoticonMapper = emoticonMapper
    }

    // MARK: - LSTextParser

    public func parse(_ text: NSMutableAttributedString, selectedRange: NSRangePointer?) -> Bool {
        guard !emoticonMapper.isEmpty else { return false }

        let fullRange = NSRange(location: 0, length: text.length)
        var modified = false

        // 查找所有 emoji 代码
        for (code, replacement) in emoticonMapper.sorted(by: { $0.key.count > $1.key.count }) {
            let pattern = NSRegularExpression.escapedPattern(for: code)

            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { continue }

            let matches = regex.matches(in: text.string, options: [], range: fullRange)

            for match in matches.reversed() {
                if let replacement = replacement as? String {
                    // 文本替换
                    text.replaceCharacters(in: match.range, with: replacement)
                } else if let image = replacement as? UIImage {
                    // 图片替换
                    let attachment = LSTextAttachment(content: image)
                    attachment.contentSize = CGSize(width: defaultEmoticonSize, height: defaultEmoticonSize)

                    let attachmentString = NSMutableAttributedString(attachment: attachment)
                    text.replaceCharacters(in: match.range, with: attachmentString)
                }

                modified = true
            }
        }

        return modified
    }

    // MARK: - 私有方法

    private func setupDefaultEmoticons() {
        // 常用 emoji 映射
        let commonEmojis: [String: String] = [
            ":smile:": "😊",
            ":laughing:": "😆",
            ":wink:": "😉",
            ":heart:": "❤️",
            ":thumbsup:": "👍",
            ":thumbsdown:": "👎",
            ":fire:": "🔥",
            ":star:": "⭐",
            ":check:": "✅",
            ":cross:": "❌",
            ":thinking:": "🤔",
            ":ok:": "👌",
            ":clap:": "👏",
            ":pray:": "🙏",
            ":point_up:": "☝️",
            ":point_down:": "👇",
            ":point_left:": "👈",
            ":point_right:": "👉",
            ":raised_hands:": "🙌",
            ":wave:": "👋"
        ]

        for (code, emoji) in commonEmojis {
            emoticonMapper[code] = emoji
        }
    }
}

// MARK: - NSAttributedString Extension

private extension NSAttributedString {
    init(attachment: LSTextAttachment) {
        var attrs: [NSAttributedString.Key: Any] = [:]
        attrs[LSTextAttachmentAttributeName] = attachment

        // 创建 Run Delegate
        let delegateCallback: CTRunDelegateCallbacks = {
            var callbacks = CTRunDelegateCallbacks(
                version: kCTRunDelegateCurrentVersion,
                dealloc: { _ in },
                getAscent: { pointer in
                    let attachment = Unmanaged<LSTextAttachment>.fromOpaque(pointer!).takeUnretainedValue()
                    return attachment.contentSize.height as CGFloat
                },
                getDescent: { _ in return 0.0 },
                getWidth: { pointer in
                    let attachment = Unmanaged<LSTextAttachment>.fromOpaque(pointer!).takeUnretainedValue()
                    return attachment.contentSize.width as CGFloat
                }
            )

            let pointer = Unmanaged.passRetained(attachment).toOpaque()
            return CTRunDelegateCreate(&callbacks, pointer)!
        }

        attrs[kCTRunDelegateAttributeName as NSAttributedString.Key] = delegateCallback

        self.init(string: LSTextAttachmentToken, attributes: attrs)
    }
}

#endif

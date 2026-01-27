//
//  LSTextUtilities.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  文本工具类 - 文本处理辅助函数
//

#if canImport(UIKit)
import UIKit
import CoreText

// MARK: - 垂直排版字符集

/// LSTextVerticalFormRotateCharacterSet - 需要旋转的字符集
///
/// 用于判断哪些字符在垂直排版时需要旋转
public func LSTextVerticalFormRotateCharacterSet() -> CharacterSet {
    var set = CharacterSet()

    // 日文假名和标点
    let rotateChars: [UniChar] = [
        // Hiragana
        0x3041, 0x3042, 0x3043, 0x3044, 0x3045, 0x3046, 0x3047, 0x3048,
        0x3049, 0x304A, 0x304B, 0x304C, 0x304D, 0x304E, 0x304F, 0x3050,
        0x3051, 0x3052, 0x3053, 0x3054, 0x3055, 0x3056, 0x3057, 0x3058,
        0x3059, 0x305A, 0x305B, 0x305C, 0x305D, 0x305E, 0x305F, 0x3060,
        0x3061, 0x3062, 0x3063, 0x3064, 0x3065, 0x3066, 0x3067, 0x3068,
        0x3069, 0x306A, 0x306B, 0x306C, 0x306D, 0x306E, 0x306F, 0x3070,
        0x3071, 0x3072, 0x3073, 0x3074, 0x3075, 0x3076, 0x3077, 0x3078,
        0x3079, 0x307A, 0x307B, 0x307C, 0x307D, 0x307E, 0x307F, 0x3080,
        0x3081, 0x3082, 0x3083, 0x3084, 0x3085, 0x3086, 0x3087, 0x3088,
        0x3089, 0x308A, 0x308B, 0x308C, 0x308D, 0x308E, 0x308F, 0x3090,
        0x3091, 0x3092, 0x3093,
        // Katakana
        0x30A1, 0x30A2, 0x30A3, 0x30A4, 0x30A5, 0x30A6, 0x30A7, 0x30A8,
        0x30A9, 0x30AA, 0x30AB, 0x30AC, 0x30AD, 0x30AE, 0x30AF, 0x30B0,
        0x30B1, 0x30B2, 0x30B3, 0x30B4, 0x30B5, 0x30B6, 0x30B7, 0x30B8,
        0x30B9, 0x30BA, 0x30BB, 0x30BC, 0x30BD, 0x30BE, 0x30BF, 0x30C0,
        0x30C1, 0x30C2, 0x30C3, 0x30C4, 0x30C5, 0x30C6, 0x30C7, 0x30C8,
        0x30C9, 0x30CA, 0x30CB, 0x30CC, 0x30CD, 0x30CE, 0x30CF, 0x30D0,
        0x30D1, 0x30D2, 0x30D3, 0x30D4, 0x30D5, 0x30D6, 0x30D7, 0x30D8,
        0x30D9, 0x30DA, 0x30DB, 0x30DC, 0x30DD, 0x30DE, 0x30DF, 0x30E0,
        0x30E1, 0x30E2, 0x30E3, 0x30E4, 0x30E5, 0x30E6, 0x30E7, 0x30E8,
        0x30E9, 0x30EA, 0x30EB, 0x30EC, 0x30ED, 0x30EE, 0x30EF, 0x30F0,
        0x30F1, 0x30F2, 0x30F3, 0x30F4, 0x30F5, 0x30F6,
        // CJK Symbols and Punctuation
        0x3000, 0x3001, 0x3002, 0x3003, 0x3004, 0x3005, 0x3006, 0x3007,
        0x3008, 0x3009, 0x300A, 0x300B, 0x300C, 0x300D, 0x300E, 0x300F,
        0x3010, 0x3011, 0x3012, 0x3013, 0x3014, 0x3015, 0x3016, 0x3017,
        0x3018, 0x3019, 0x301A, 0x301B, 0x301C, 0x301D, 0x301E, 0x301F,
        0x3030, 0x3031, 0x3032, 0x3033, 0x3034, 0x3035, 0x3036, 0x3037,
        0x3038, 0x3039, 0x303A, 0x303B, 0x303C, 0x303D, 0x303E, 0x303F,
        // Halfwidth and Fullwidth Forms
        0xFF01, 0xFF02, 0xFF03, 0xFF04, 0xFF05, 0xFF06, 0xFF07, 0xFF08,
        0xFF09, 0xFF0A, 0xFF0B, 0xFF0C, 0xFF0D, 0xFF0E, 0xFF0F, 0xFF10,
        0xFF11, 0xFF12, 0xFF13, 0xFF14, 0xFF15, 0xFF16, 0xFF17, 0xFF18,
        0xFF19, 0xFF1A, 0xFF1B, 0xFF1C, 0xFF1D, 0xFF1E, 0xFF1F, 0xFF20,
        0xFF3B, 0xFF3C, 0xFF3D, 0xFF3E, 0xFF3F, 0xFF40, 0xFF5B, 0xFF5C,
        0xFF5D, 0xFF5E, 0xFF5F, 0xFF60
    ]

    for char in rotateChars {
        set.insert(UnicodeScalar(char)!)
    }

    // 添加 CJK 统一表意文字范围
    let cjkRanges: [(ClosedRange<UInt32>, UInt32)] = [
        (0x4E00...0x9FFF, 1),      // CJK Unified Ideographs
        (0x3400...0x4DBF, 1),      // CJK Unified Ideographs Extension A
        (0x20000...0x2A6DF, 1),    // CJK Unified Ideographs Extension B
        (0x2A700...0x2B73F, 1),    // CJK Unified Ideographs Extension C
        (0x2B740...0x2B81F, 1),    // CJK Unified Ideographs Extension D
        (0x2F800...0x2FA1F, 1),    // CJK Compatibility Ideographs
        (0x31C0...0x31EF, 1),      // CJK Strokes
        (0x2E80...0x2EFF, 1),      // CJK Radicals Supplement
        (0x2F00...0x2FDF, 1),      // Kangxi Radicals
        (0x3100...0x312F, 1),      // Bopomofo
        (0x31A0...0x31BF, 1),      // Bopomofo Extended
        (0xAC00...0xD7AF, 1),      // Hangul Syllables
        (0x1100...0x11FF, 1),      // Hangul Jamo
        (0x3130...0x318F, 1)       // Hangul Compatibility Jamo
    ]

    for (range, _) in cjkRanges {
        for codePoint in range {
            set.insert(UnicodeScalar(codePoint)!)
        }
    }

    return set
}

/// LSTextVerticalFormRotateAndMoveCharacterSet - 需要旋转并移动的字符集
///
/// 用于判断哪些字符在垂直排版时需要旋转并移动到更好的位置
public func LSTextVerticalFormRotateAndMoveCharacterSet() -> CharacterSet {
    var set = CharacterSet()

    // 全角标点
    let rotateMoveChars: [UniChar] = [
        0x3001,  // 、
        0x3002,  // 。
        0x3008, 0x3009,  // 〈 〉
        0x300A, 0x300B,  // 《 》
        0x300C, 0x300D,  // 「 」
        0x300E, 0x300F,  // 『 』
        0x3010, 0x3011,  // 【 】
        0x3014, 0x3015,  // 〔 〕
        0x3016, 0x3017,  // 〖 〗
        0x3018, 0x3019,  // 〘 〙
        0x301A, 0x301B,  // 〚 〛
        0x301C, 0x301D,  // 〜 〝
        0x301E, 0x301F,  // 〟 〟
        0xFF08, 0xFF09,  // （ ）
        0xFF3B, 0xFF3D,  // ［ ］
        0xFF5B, 0xFF5D,  // ｛ ｝
        0xFF01, 0xFF1F,  // ！ ？
        0xFF1B,  // ；
        0xFF1A,  // ：
        0xFF1C, 0xFF1E,  // ＜ ＞
        0xFF06,  // ＆
        0xFF40,  // ＠
        0xFF3C,  // ＼
        0xFF3E,  // ＾
        0xFF5F, 0xFF60,  // ｀ ￠
        0xFF02   // ＂
    ]

    for char in rotateMoveChars {
        set.insert(UnicodeScalar(char)!)
    }

    return set
}

// MARK: - 字符串标记

/// 文本附件标记 - 对象替换字符（U+FFFC）
public let LSTextAttachmentToken = "\u{FFFC}"

/// 文本截断标记 - 省略号（U+2026）
public let LSTextTruncationToken = "\u{2026}"

// MARK: - CoreText 辅助函数

extension LSTextLayout {

    /// 获取指定点的文本范围
    ///
    /// - Parameter point: 容器中的点
    /// - Returns: 文本范围，如果没有则返回 nil
    public func textRangeAtPoint(_ point: CGPoint) -> LSTextRange? {
        guard let _ = frame else { return nil }

        // 获取行索引
        guard let lineIndex = lineIndexForPoint(point) else { return nil }
        guard lineIndex < lines.count else { return nil }

        let line = lines[lineIndex]

        // 计算偏移
        var offset = point.x - line.position.x
        if container.isVerticalForm {
            offset = point.y - line.position.y
        }

        // 获取文本位置
        let textPosition = offsetForTextPosition(at: offset, lineIndex: lineIndex)
        guard textPosition != NSNotFound else { return nil }

        // 扩展到完整范围（处理 emoji、绑定文本等）
        return textRangeByExtendingPosition(LSTextPosition(offset: textPosition))
    }

    /// 获取最近位置的文本范围
    ///
    /// - Parameter point: 容器中的点
    /// - Returns: 文本范围，如果没有则返回 nil
    public func closestTextRangeAtPoint(_ point: CGPoint) -> LSTextRange? {
        // 首先尝试精确匹配
        if let exactRange = textRangeAtPoint(point) {
            return exactRange
        }

        // 如果没有精确匹配，查找最近的行
        guard let _ = frame else { return nil }

        var closestLineIndex: UInt?
        var closestDistance: CGFloat = .infinity

        for (index, line) in lines.enumerated() {
            // 计算点到行的距离
            let distance: CGFloat
            if container.isVerticalForm {
                distance = abs(point.x - line.position.x)
            } else {
                distance = abs(point.y - line.position.y)
            }

            if distance < closestDistance {
                closestDistance = distance
                closestLineIndex = UInt(index)
            }
        }

        guard let lineIndex = closestLineIndex else { return nil }
        guard lineIndex < lines.count else { return nil }

        let line = lines[lineIndex]

        // 返回该行的范围
        return LSTextRange(start: UInt(line.range.location), end: UInt(line.range.location + line.range.length - 1))
    }

    /// 通过扩展位置获取文本范围
    ///
    /// - Parameter position: 文本位置
    /// - Returns: 扩展后的文本范围
    public func textRangeByExtendingPosition(_ position: LSTextPosition) -> LSTextRange? {
        guard let text = text else { return nil }

        var start = position.offset
        var end = position.offset

        // 检查是否在 emoji 范围内
        if start < text.length {
            let char = (text.string as NSString).character(at: start)
            if char >= 0xD800 && char <= 0xDBFF {
                // 高代理，检查是否有低代理
                if start + 1 < text.length {
                    let next = (text.string as NSString).character(at: start + 1)
                    if next >= 0xDC00 && next <= 0xDFFF {
                        end = start + 1
                    }
                }
            } else if char >= 0xDC00 && char <= 0xDFFF {
                // 低代理，检查是否有高代理
                if start > 0 {
                    let prev = (text.string as NSString).character(at: start - 1)
                    if prev >= 0xD800 && prev <= 0xDBFF {
                        start = start - 1
                    }
                }
            }
        }

        // 检查是否有绑定属性
        if start < text.length {
            if let binding = text.attribute(LSTextBindingAttributeName, at: start, effectiveRange: nil) as? LSTextBinding {
                // 查找绑定范围的起始
                var bindingRange = NSRange(location: 0, length: 0)
                _ = text.attribute(LSTextBindingAttributeName, at: start, longestEffectiveRange: &bindingRange, in: NSRange(location: 0, length: text.length))
                start = bindingRange.location
                end = bindingRange.location + bindingRange.length - 1
            }
        }

        return LSTextRange(start: start, end: end)
    }

    /// 获取行在指定点的索引
    ///
    /// - Parameter point: 容器中的点
    /// - Returns: 行索引，没有则返回 nil
    public func lineIndexForPoint(_ point: CGPoint) -> UInt? {
        guard let _ = frame else { return nil }

        var bestIndex: UInt?
        var bestDistance: CGFloat = .infinity

        for (index, line) in lines.enumerated() {
            // 计算点到行的距离
            let distance: CGFloat
            if container.isVerticalForm {
                // 垂直排版：比较 X 坐标
                distance = abs(point.x - line.position.x)
            } else {
                // 水平排版：比较 Y 坐标
                distance = abs(point.y - line.position.y)
            }

            // 检查点是否在行的水平范围内
            let inHorizontalRange: Bool
            if container.isVerticalForm {
                inHorizontalRange = point.y >= line.bounds.minY && point.y <= line.bounds.maxY
            } else {
                inHorizontalRange = point.x >= line.bounds.minX && point.x <= line.bounds.maxX
            }

            // 如果点在行范围内，优先选择
            if inHorizontalRange && distance < bestDistance {
                bestDistance = distance
                bestIndex = UInt(index)
            } else if distance < bestDistance / 2 {
                // 如果距离小于一半的最优距离，也考虑
                bestDistance = distance
                bestIndex = UInt(index)
            }
        }

        return bestIndex
    }

    /// 获取文本位置在指定行中的偏移
    ///
    /// - Parameters:
    ///   - offset: 容器中的偏移
    ///   - lineIndex: 行索引
    /// - Returns: 文本位置，没找到则返回 NSNotFound
    public func offsetForTextPosition(at offset: CGFloat, lineIndex: UInt) -> UInt {
        guard lineIndex < lines.count else { return UInt(NSNotFound) }
        let line = lines[lineIndex]

        guard let ctLine = line.ctLine else { return UInt(NSNotFound) }

        // 转换坐标系
        var adjustedOffset = offset
        if container.isVerticalForm {
            // 垂直排版：Y 坐标
            adjustedOffset = offset - line.position.y
        } else {
            // 水平排版：X 坐标
            adjustedOffset = offset - line.position.x
        }

        // 使用 CTLineGetStringIndexForPosition 获取精确位置
        let index = CTLineGetStringIndexForPosition(ctLine, adjustedOffset, nil)

        return UInt(index)
    }

    /// 获取指定位置的基线位置
    ///
    /// - Parameter position: 文本位置
    /// - Returns: 基线位置
    public func linePositionForPosition(_ position: LSTextPosition) -> CGPoint {
        guard let _ = frame else { return .zero }
        guard let text = text else { return .zero }

        let offset = position.offset
        guard offset < UInt(text.length) else { return .zero }

        // 查找包含该位置的行
        for line in lines {
            if offset >= UInt(line.range.location) && offset < UInt(line.range.location + line.range.length) {
                // 计算该位置在行中的偏移
                let lineOffset = Int(offset) - line.range.location

                guard let ctLine = line.ctLine else { return line.position }

                // 获取字符串索引位置
                var stringIndex = CTLineGetStringIndexForPosition(ctLine, 0, nil)
                if lineOffset > 0 {
                    let count = CFIndex(lineOffset)
                    if let string = text.string.cString(using: .utf8) {
                        let charIndex = string.index(string.startIndex, offsetBy: lineOffset, limitedBy: string.endIndex)
                        if charIndex != string.endIndex {
                            // 获取字形位置
                            stringIndex = CTLineGetStringIndexForPosition(ctLine, CGFloat(lineOffset) * 10, nil)
                        }
                    }
                }

                // 获取该位置的字形位置
                var secondaryOffset: CGFloat = 0
                let primaryOffset = CTLineGetOffsetForStringIndex(ctLine, stringIndex, &secondaryOffset)

                // 计算最终位置
                if container.isVerticalForm {
                    return CGPoint(
                        x: line.position.x + secondaryOffset,
                        y: line.position.y + primaryOffset
                    )
                } else {
                    return CGPoint(
                        x: line.position.x + primaryOffset,
                        y: line.position.y
                    )
                }
            }
        }

        return .zero
    }
}

// MARK: - LSTextRange

/// 文本范围
public class LSTextRange: NSObject, NSCopying {

    public let start: UInt
    public let end: UInt

    public init(start: UInt, end: UInt) {
        self.start = start
        self.end = end
        super.init()
    }

    public var range: NSRange {
        return NSRange(location: Int(start), length: max(0, Int(end) - Int(start) + 1))
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        return LSTextRange(start: start, end: end)
    }
}

// MARK: - LSTextPosition

/// 文本位置
public class LSTextPosition: NSObject, NSCopying {

    public let offset: UInt

    public init(offset: UInt) {
        self.offset = offset
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        return LSTextPosition(offset: offset)
    }
}

#endif

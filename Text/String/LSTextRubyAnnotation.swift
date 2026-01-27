//
//  LSTextRubyAnnotation.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  文本 Ruby 注释 - 用于日文拼音标注
//

#if canImport(UIKit)
import UIKit
import CoreText

// MARK: - LSTextRubyAnnotation

/// LSTextRubyAnnotation 用于创建 Ruby 注释（拼音标注）
///
/// Ruby 注释主要用于东亚文字的拼音标注
public class LSTextRubyAnnotation: NSObject, NSCopying {

    // MARK: - 属性

    /// Ruby 文本（拼音）
    public var text: String {
        get { return _text }
        set { _text = newValue }
    }

    /// 基文本位置
    public var textPosition: LSTextPosition {
        get { return _textPosition }
        set { _textPosition = newValue }
    }

    /// Ruby 对齐方式
    public var alignment: CTRubyAlignment = .auto {
        didSet { _updateCTRubyAnnotation() }
    }

    /// Ruby 过度悬挂
    public var overhang: Bool = true {
        didSet { _updateCTRubyAnnotation() }
    }

    // MARK: - 私有属性

    private var _text: String
    private var _textPosition: LSTextPosition
    private var _ctRuby: CTRubyAnnotation?

    // MARK: - 初始化

    /// 创建 Ruby 注释
    ///
    /// - Parameters:
    ///   - text: Ruby 文本（拼音）
    ///   - position: 基文本位置
    public init(text: String, position: LSTextPosition) {
        self._text = text
        self._textPosition = position
        super.init()
        _updateCTRubyAnnotation()
    }

    public override init() {
        self._text = ""
        self._textPosition = LSTextPosition(offset: 0)
        super.init()
    }

    // MARK: - 公共方法

    /// 获取 CTRubyAnnotation
    public var ctRubyAnnotation: CTRubyAnnotation? {
        return _ctRuby
    }

    // MARK: - 私有方法

    private func _updateCTRubyAnnotation() {
        let string = _text as CFString
        let position = _textPosition.offset

        var rubyAlignment: CTRubyAlignment = .auto
        switch alignment {
        case .auto:
            rubyAlignment = .auto
        case .start:
            rubyAlignment = .start
        case .center:
            rubyAlignment = .center
        case .end:
            rubyAlignment = .end
        case .distributeSpace:
            rubyAlignment = .distributeSpace
        case .distributeSpaceForce:
            rubyAlignment = .distributeSpaceForce
        case .lineEdge:
            rubyAlignment = .lineEdge
        @unknown default:
            rubyAlignment = .auto
        }

        _ctRuby = CTRubyAnnotationCreateWithAttributes(
            string,
            rubyAlignment,
            position,
            overhang ? 1 : 0,
            nil
        )
    }

    // MARK: - NSCopying

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = LSTextRubyAnnotation(text: _text, position: _textPosition)
        copy.alignment = alignment
        copy.overhang = overhang
        return copy
    }
}

// MARK: - NSAttributedString Extension (Ruby 注释支持)

extension NSAttributedString {

    /// 为指定范围添加 Ruby 注释
    ///
    /// - Parameters:
    ///   - rubyText: Ruby 文本
    ///   - range: 文本范围
    /// - Returns: 新的属性字符串
    public func ls_addingRubyAnnotation(_ rubyText: String, for range: NSRange) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: self)
        mutable.ls_addRubyAnnotation(rubyText, for: range)
        return mutable
    }
}

extension NSMutableAttributedString {

    /// 为指定范围添加 Ruby 注释
    ///
    /// - Parameters:
    ///   - rubyText: Ruby 文本
    ///   - range: 文本范围
    public func ls_addRubyAnnotation(_ rubyText: String, for range: NSRange) {
        let position = LSTextPosition(offset: UInt(range.location))
        let ruby = LSTextRubyAnnotation(text: rubyText, position: position)

        if let ctRuby = ruby.ctRubyAnnotation {
            addAttribute(kCTRubyAnnotationAttributeName as NSAttributedString.Key, value: ctRuby, range: range)
        }
    }

    /// 批量添加 Ruby 注释
    ///
    /// - Parameters:
    ///   - annotations: Ruby 注释数组
    public func ls_addRubyAnnotations(_ annotations: [(text: String, range: NSRange)]) {
        for annotation in annotations {
            ls_addRubyAnnotation(annotation.text, for: annotation.range)
        }
    }
}

// MARK: - Ruby 注释辅助类

/// LSTextRubyAnnotationBuilder 用于批量创建 Ruby 注释
public class LSTextRubyAnnotationBuilder: NSObject {

    // MARK: - 属性

    /// 对齐方式
    public var alignment: CTRubyAlignment = .auto

    /// 过度悬挂
    public var overhang: Bool = true

    // MARK: - 公共方法

    /// 为文本添加拼音标注
    ///
    /// - Parameters:
    ///   - text: 原始文本
    ///   - pinyin: 拼音数组（每个字符对应一个拼音）
    /// - Returns: 带拼音标注的属性字符串
    public static func attributedString(withPinyin text: String, pinyin: [String]) -> NSAttributedString {
        let mutable = NSMutableAttributedString(string: text)
        let baseAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17)
        ]
        mutable.addAttributes(baseAttrs, range: NSRange(location: 0, length: mutable.length))

        // 为每个字符添加拼音
        for (index, pinyinText) in pinyin.enumerated() {
            guard index < text.count else { break }
            let range = NSRange(location: index, length: 1)
            mutable.ls_addRubyAnnotation(pinyinText, for: range)
        }

        return mutable
    }

    /// 为日文文本添加假名标注
    ///
    /// - Parameters:
    ///   - text: 原始文本
    ///   - furigana: 假名数组（每个字符对应一个假名）
    /// - Returns: 带假名标注的属性字符串
    public static func attributedString(withFurigana text: String, furigana: [String]) -> NSAttributedString {
        return attributedString(withPinyin: text, pinyin: furigana)
    }
}

#endif

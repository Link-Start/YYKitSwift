//
//  NSParagraphStyle+YYKitSwift.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  NSParagraphStyle 扩展 - 段落样式便捷方法
//

#if canImport(UIKit)
import UIKit
import CoreText

// MARK: - NSParagraphStyle Extension

extension NSParagraphStyle {

    // MARK: - 默认样式

    /// 默认段落样式
    public static var ls_default: NSParagraphStyle {
        return NSParagraphStyle.default
    }

    // MARK: - 便捷创建方法

    /// 创建具有指定对齐方式的段落样式
    ///
    /// - Parameter alignment: 对齐方式
    /// - Returns: 段落样式
    public static func ls_paragraphStyle(with alignment: NSTextAlignment) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        return style as NSParagraphStyle
    }

    /// 创建具有指定行距的段落样式
    ///
    /// - Parameters:
    ///   - lineSpacing: 行距
    ///   - alignment: 对齐方式
    /// - Returns: 段落样式
    public static func ls_paragraphStyle(lineSpacing: CGFloat, alignment: NSTextAlignment = .natural) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = lineSpacing
        style.alignment = alignment
        return style as NSParagraphStyle
    }

    /// 创建具有指定段落间距的段落样式
    ///
    /// - Parameters:
    ///   - paragraphSpacing: 段落间距
    ///   - alignment: 对齐方式
    /// - Returns: 段落样式
    public static func ls_paragraphStyle(paragraphSpacing: CGFloat, alignment: NSTextAlignment = .natural) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.paragraphSpacing = paragraphSpacing
        style.alignment = alignment
        return style as NSParagraphStyle
    }

    /// 创建具有指定行距和段落间距的段落样式
    ///
    /// - Parameters:
    ///   - lineSpacing: 行距
    ///   - paragraphSpacing: 段落间距
    ///   - alignment: 对齐方式
    /// - Returns: 段落样式
    public static func ls_paragraphStyle(lineSpacing: CGFloat, paragraphSpacing: CGFloat, alignment: NSTextAlignment = .natural) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = lineSpacing
        style.paragraphSpacing = paragraphSpacing
        style.alignment = alignment
        return style as NSParagraphStyle
    }

    /// 创建具有指定首行缩进的段落样式
    ///
    /// - Parameters:
    ///   - firstLineHeadIndent: 首行缩进
    ///   - alignment: 对齐方式
    /// - Returns: 段落样式
    public static func ls_paragraphStyle(firstLineHeadIndent: CGFloat, alignment: NSTextAlignment = .natural) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.firstLineHeadIndent = firstLineHeadIndent
        style.alignment = alignment
        return style as NSParagraphStyle
    }

    /// 创建具有指定头缩进的段落样式
    ///
    /// - Parameters:
    ///   - headIndent: 头缩进
    ///   - alignment: 对齐方式
    /// - Returns: 段落样式
    public static func ls_paragraphStyle(headIndent: CGFloat, alignment: NSTextAlignment = .natural) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.headIndent = headIndent
        style.alignment = alignment
        return style as NSParagraphStyle
    }

    /// 创建具有指定尾缩进的段落样式
    ///
    /// - Parameters:
    ///   - tailIndent: 尾缩进
    ///   - alignment: 对齐方式
    /// - Returns: 段落样式
    public static func ls_paragraphStyle(tailIndent: CGFloat, alignment: NSTextAlignment = .natural) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.tailIndent = tailIndent
        style.alignment = alignment
        return style as NSParagraphStyle
    }
}

// MARK: - NSMutableParagraphStyle Extension

extension NSMutableParagraphStyle {

    // MARK: - 链式调用方法

    /// 设置对齐方式
    ///
    /// - Parameter alignment: 对齐方式
    /// - Returns: self，支持链式调用
    @discardableResult
    public func ls_alignment(_ alignment: NSTextAlignment) -> Self {
        self.alignment = alignment
        return self
    }

    /// 设置行距
    ///
    /// - Parameter spacing: 行距
    /// - Returns: self，支持链式调用
    @discardableResult
    public func ls_lineSpacing(_ spacing: CGFloat) -> Self {
        lineSpacing = spacing
        return self
    }

    /// 设置段落间距
    ///
    /// - Parameter spacing: 段落间距
    /// - Returns: self，支持链式调用
    @discardableResult
    public func ls_paragraphSpacing(_ spacing: CGFloat) -> Self {
        paragraphSpacing = spacing
        return self
    }

    /// 设置首行缩进
    ///
    /// - Parameter indent: 首行缩进
    /// - Returns: self，支持链式调用
    @discardableResult
    public func ls_firstLineHeadIndent(_ indent: CGFloat) -> Self {
        firstLineHeadIndent = indent
        return self
    }

    /// 设置头缩进
    ///
    /// - Parameter indent: 头缩进
    /// - Returns: self，支持链式调用
    @discardableResult
    public func ls_headIndent(_ indent: CGFloat) -> Self {
        headIndent = indent
        return self
    }

    /// 设置尾缩进
    ///
    /// - Parameter indent: 尾缩进
    /// - Returns: self，支持链式调用
    @discardableResult
    public func ls_tailIndent(_ indent: CGFloat) -> Self {
        tailIndent = indent
        return self
    }

    /// 设置行高倍数
    ///
    /// - Parameter multiple: 行高倍数
    /// - Returns: self，支持链式调用
    @discardableResult
    public func ls_lineHeightMultiple(_ multiple: CGFloat) -> Self {
        lineHeightMultiple = multiple
        return self
    }

    /// 设置最大行高
    ///
    /// - Parameter height: 最大行高
    /// - Returns: self，支持链式调用
    @discardableResult
    public func ls_maximumLineHeight(_ height: CGFloat) -> Self {
        maximumLineHeight = height
        return self
    }

    /// 设置最小行高
    ///
    /// - Parameter height: 最小行高
    /// - Returns: self，支持链式调用
    @discardableResult
    public func ls_minimumLineHeight(_ height: CGFloat) -> Self {
        minimumLineHeight = height
        return self
    }

    /// 设置基线偏移
    ///
    /// - Parameter offset: 基线偏移
    /// - Returns: self，支持链式调用
    @discardableResult
    public func ls_baseWritingDirection(_ direction: NSWritingDirection) -> Self {
        baseWritingDirection = direction
        return self
    }

    /// 设置断行模式
    ///
    /// - Parameter mode: 断行模式
    /// - Returns: self，支持链式调用
    @discardableResult
    public func ls_lineBreakMode(_ mode: NSLineBreakMode) -> Self {
        lineBreakMode = mode
        return self
    }

    /// 设置连字模式
    ///
    /// - Parameter mode: 连字模式
    /// - Returns: self，支持链式调用
    @discardableResult
    public func ls_lineHeightMultiple(_ mode: NSLineBreakMode) -> Self {
        lineBreakMode = mode
        return self
    }

    /// 设置制表符停靠点
    ///
    /// - Parameter stops: 制表符停靠点
    /// - Returns: self，支持链式调用
    @discardableResult
    public func ls_tabStops(_ stops: [NSTextTab]) -> Self {
        tabStops = stops
        return self
    }

    /// 设置默认制表符间隔
    ///
    /// - Parameter interval: 制表符间隔
    /// - Returns: self，支持链式调用
    @discardableResult
    public func ls_defaultTabInterval(_ interval: CGFloat) -> Self {
        defaultTabInterval = interval
        return self
    }

    /// 设置文本缩进
    ///
    /// - Parameters:
    ///   - firstLine: 首行缩进
    ///   - rest: 其余行缩进
    /// - Returns: self，支持链式调用
    @discardableResult
    public func ls_textIndent(firstLine: CGFloat, rest: CGFloat) -> Self {
        firstLineHeadIndent = firstLine
        headIndent = rest
        return self
    }

    /// 设置所有边距
    ///
    /// - Parameters:
    ///   - firstLine: 首行缩进
    ///   - head: 头缩进
    ///   - tail: 尾缩进
    /// - Returns: self，支持链式调用
    @discardableResult
    public func ls_indents(firstLine: CGFloat, head: CGFloat, tail: CGFloat) -> Self {
        firstLineHeadIndent = firstLine
        headIndent = head
        tailIndent = tail
        return self
    }
}

// MARK: - CTParagraphStyle 扩展

extension NSParagraphStyle {

    /// 转换为 CTParagraphStyle
    ///
    /// - Returns: CTParagraphStyle 对象
    public var ls_CTParagraphStyle: CTParagraphStyle {
        return self as CTParagraphStyle
    }

    /// 从 CTParagraphStyle 创建 NSParagraphStyle
    ///
    /// - Parameter ctStyle: CTParagraphStyle 对象
    /// - Returns: NSParagraphStyle 对象
    public static func ls_from(ctStyle: CTParagraphStyle) -> NSParagraphStyle {
        return NSParagraphStyle(ctStyle)
    }
}

// MARK: - 段落样式预设

public struct LSTextParagraphPresets {

    /// 正文样式（默认）
    public static var body: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 4
        style.paragraphSpacing = 8
        style.alignment = .natural
        return style as NSParagraphStyle
    }

    /// 标题样式
    public static var title: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 0
        style.paragraphSpacing = 12
        style.alignment = .center
        return style as NSParagraphStyle
    }

    /// 副标题样式
    public static var subtitle: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 2
        style.paragraphSpacing = 10
        style.alignment = .left
        return style as NSParagraphStyle
    }

    /// 引用样式
    public static var quote: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 6
        style.paragraphSpacing = 8
        style.firstLineHeadIndent = 20
        style.headIndent = 20
        style.alignment = .natural
        return style as NSParagraphStyle
    }

    /// 代码块样式
    public static var code: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 0
        style.paragraphSpacing = 8
        style.alignment = .left
        return style as NSParagraphStyle
    }

    /// 列表样式
    public static var list: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 4
        style.paragraphSpacing = 4
        style.firstLineHeadIndent = 20
        style.headIndent = 20
        style.alignment = .natural
        return style as NSParagraphStyle
    }

    /// 居中样式
    public static var centered: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 4
        style.paragraphSpacing = 8
        style.alignment = .center
        return style as NSParagraphStyle
    }

    /// 右对齐样式
    public static var rightAligned: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 4
        style.paragraphSpacing = 8
        style.alignment = .right
        return style as NSParagraphStyle
    }

    /// 两端对齐样式
    public static var justified: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 4
        style.paragraphSpacing = 8
        style.alignment = .justified
        return style as NSParagraphStyle
    }
}

#endif

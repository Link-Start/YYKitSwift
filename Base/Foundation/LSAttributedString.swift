//
//  LSAttributedString.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  富文本工具 - 提供富文本字符串创建方法
//

#if canImport(UIKit)
import UIKit
import Foundation

// MARK: - LSAttributedString

/// 富文本构建器
public class LSAttributedString {

    // MARK: - 属性

    /// 字符串
    private var string: String

    /// 属性字典
    private var attributes: [NSAttributedString.Key: Any] = [:]

    /// 富文本对象
    private var attributedString: NSMutableAttributedString

    // MARK: - 初始化

    /// 创建富文本构建器
    ///
    /// - Parameter string: 初始字符串
    public init(_ string: String = "") {
        self.string = string
        self.attributedString = NSMutableAttributedString(string: string)
    }

    // MARK: - 全局属性设置

    /// 设置字体
    ///
    /// - Parameter font: 字体
    /// - Returns: self
    @discardableResult
    public func font(_ font: UIFont) -> Self {
        attributes[.font] = font
        return self
    }

    /// 设置字体大小
    ///
    /// - Parameter size: 字体大小
    /// - Returns: self
    @discardableResult
    public func fontSize(_ size: CGFloat) -> Self {
        attributes[.font] = UIFont.systemFont(ofSize: size)
        return self
    }

    /// 设置粗体
    ///
    /// - Parameter size: 字体大小
    /// - Returns: self
    @discardableResult
    public func boldFontSize(_ size: CGFloat) -> Self {
        attributes[.font] = UIFont.boldSystemFont(ofSize: size)
        return self
    }

    /// 设置文本颜色
    ///
    /// - Parameter color: 颜色
    /// - Returns: self
    @discardableResult
    public func textColor(_ color: UIColor) -> Self {
        attributes[.foregroundColor] = color
        return self
    }

    /// 设置背景颜色
    ///
    /// - Parameter color: 颜色
    /// - Returns: self
    @discardableResult
    public func backgroundColor(_ color: UIColor) -> Self {
        attributes[.backgroundColor] = color
        return self
    }

    /// 设置下划线
    ///
    /// - Parameter style: 下划线样式
    /// - Returns: self
    @discardableResult
    public func underline(_ style: NSUnderlineStyle = .single) -> Self {
        attributes[.underlineStyle] = style.rawValue
        return self
    }

    /// 设置删除线
    ///
    /// - Parameter style: 删除线样式
    /// - Returns: self
    @discardableResult
    public func strikethrough(_ style: NSUnderlineStyle = .single) -> Self {
        attributes[.strikethroughStyle] = style.rawValue
        return self
    }

    /// 设置段落样式
    ///
    /// - Parameter style: 段落样式
    /// - Returns: self
    @discardableResult
    public func paragraphStyle(_ style: NSParagraphStyle) -> Self {
        attributes[.paragraphStyle] = style
        return self
    }

    /// 设置对齐方式
    ///
    /// - Parameter alignment: 对齐方式
    /// - Returns: self
    @discardableResult
    public func alignment(_ alignment: NSTextAlignment) -> Self {
        let paragraphStyle = attributes[.paragraphStyle] as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        attributes[.paragraphStyle] = paragraphStyle
        return self
    }

    /// 设置行间距
    ///
    /// - Parameter spacing: 行间距
    /// - Returns: self
    @discardableResult
    public func lineSpacing(_ spacing: CGFloat) -> Self {
        let paragraphStyle = attributes[.paragraphStyle] as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = spacing
        attributes[.paragraphStyle] = paragraphStyle
        return self
    }

    /// 设置字间距
    ///
    /// - Parameter spacing: 字间距
    /// - Returns: self
    @discardableResult
    public func kern(_ spacing: CGFloat) -> Self {
        attributes[.kern] = spacing
        return self
    }

    /// 设置基线偏移
    ///
    /// - Parameter offset: 偏移量
    /// - Returns: self
    @discardableResult
    public func baselineOffset(_ offset: CGFloat) -> Self {
        attributes[.baselineOffset] = offset
        return self
    }

    /// 设置连字符
    ///
    /// - Parameter value: 是否启用
    /// - Returns: self
    @discardableResult
    public func ligature(_ value: Bool) -> Self {
        attributes[.ligature] = value ? 1 : 0
        return self
    }

    /// 设置阴影
    ///
    /// - Parameter shadow: 阴影
    /// - Returns: self
    @discardableResult
    public func shadow(_ shadow: NSShadow) -> Self {
        attributes[.shadow] = shadow
        return self
    }

    /// 设置文本效果
    ///
    /// - Parameter effect: 文本效果
    /// - Returns: self
    @discardableResult
    public func textEffect(_ effect: NSAttributedString.TextEffectStyle) -> Self {
        attributes[.textEffect] = effect
        return self
    }

    /// 设置附件
    ///
    /// - Parameter attachment: 附件
    /// - Returns: self
    @discardableResult
    public func attachment(_ attachment: NSTextAttachment) -> Self {
        attributes[.attachment] = attachment
        return self
    }

    /// 设置链接
    ///
    /// - Parameter url: 链接 URL
    /// - Returns: self
    @discardableResult
    public func link(_ url: URL) -> Self {
        attributes[.link] = url
        return self
    }

    /// 设置链接（字符串）
    ///
    /// - Parameter urlString: 链接字符串
    /// - Returns: self
    @discardableResult
    public func link(_ urlString: String) -> Self {
        if let url = URL(string: urlString) {
            attributes[.link] = url
        }
        return self
    }

    // MARK: - 添加文本

    /// 添加普通文本
    ///
    /// - Parameter text: 文本
    /// - Returns: self
    @discardableResult
    public func append(_ text: String) -> Self {
        let attributedText = NSMutableAttributedString(string: text, attributes: attributes)
        attributedString.append(attributedText)
        return self
    }

    /// 添加带样式的文本
    ///
    /// - Parameters:
    ///   - text: 文本
    ///   - configure: 配置闭包
    /// - Returns: self
    @discardableResult
    public func append(
        _ text: String,
        configure: (inout LSAttributedString) -> Void
    ) -> Self {
        let builder = LSAttributedString(text)
        configure(&builder)
        attributedString.append(builder.build())
        return self
    }

    /// 添加图片
    ///
    /// - Parameters:
    ///   - image: 图片
    ///   - bounds: 图片边界
    /// - Returns: self
    @discardableResult
    public func append(image: UIImage, bounds: CGRect = .zero) -> Self {
        let attachment = NSTextAttachment()
        attachment.image = image

        if bounds != .zero {
            attachment.bounds = bounds
        }

        let attributedText = NSAttributedString(attachment: attachment)
        attributedString.append(attributedText)
        return self
    }

    // MARK: - 构建

    /// 构建富文本
    ///
    /// - Returns: 富文本对象
    public func build() -> NSAttributedString {
        return attributedString
    }
}

// MARK: - NSAttributedString Extension

public extension NSAttributedString {

    /// 调整富文本大小
    ///
    /// - Parameter size: 缩放比例
    /// - Returns: 调整后的富文本
    func ls_scaled(by size: CGFloat) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: self)

        mutable.enumerateAttribute(.font, in: NSRange(location: 0, length: length)) { value, range, _ in
            if let font = value as? UIFont {
                let newFont = font.withSize(font.pointSize * size)
                mutable.addAttribute(.font, value: newFont, range: range)
            }
        }

        return mutable
    }

    /// 获取文本大小
    ///
    /// - Parameters:
    ///   - width: 最大宽度
    ///   - options: 绘制选项
    /// - Returns: 文本大小
    func ls_size(width: CGFloat, options: NSStringDrawingOptions = .usesLineFragmentOrigin) -> CGSize {
        return boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: options,
            context: nil
        ).size
    }

    /// 获取文本高度
    ///
    /// - Parameters:
    ///   - width: 最大宽度
    ///   - options: 绘制选项
    /// - Returns: 文本高度
    func ls_height(width: CGFloat, options: NSStringDrawingOptions = .usesLineFragmentOrigin) -> CGFloat {
        return ls_size(width: width, options: options).height
    }

    /// 转换为 HTML
    ///
    /// - Returns: HTML 字符串
    func ls_htmlString() -> String? {
        let documentAttributes: [NSAttributedString.DocumentAttributeKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        guard let data = try? data(
            from: NSRange(location: 0, length: length),
            documentAttributes: documentAttributes
        ) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }
}

// MARK: - NSMutableAttributedString Extension

public extension NSMutableAttributedString {

    /// 添加下划线
    ///
    /// - Parameters:
    ///   - text: 要添加下划线的文本
    ///   - color: 下划线颜色
    func ls_addUnderline(to text: String, color: UIColor = .blue) {
        let range = (string as NSString).range(of: text)
        addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        addAttribute(.underlineColor, value: color, range: range)
    }

    /// 添加颜色
    ///
    /// - Parameters:
    ///   - text: 要添加颜色的文本
    ///   - color: 颜色
    func ls_addColor(to text: String, color: UIColor) {
        let range = (string as NSString).range(of: text)
        addAttribute(.foregroundColor, value: color, range: range)
    }

    /// 添加字体
    ///
    /// - Parameters:
    ///   - text: 要添加字体的文本
    ///   - font: 字体
    func ls_addFont(to text: String, font: UIFont) {
        let range = (string as NSString).range(of: text)
        addAttribute(.font, value: font, range: range)
    }

    /// 添加背景色
    ///
    /// - Parameters:
    ///   - text: 要添加背景色的文本
    ///   - color: 背景色
    func ls_addBackgroundColor(to text: String, color: UIColor) {
        let range = (string as NSString).range(of: text)
        addAttribute(.backgroundColor, value: color, range: range)
    }

    /// 添加行间距
    ///
    /// - Parameter spacing: 行间距
    func ls_addLineSpacing(_ spacing: CGFloat) {
        let range = NSRange(location: 0, length: length)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = spacing
        addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
    }

    /// 添加字间距
    ///
    /// - Parameter kerning: 字间距
    func ls_addKern(_ kerning: CGFloat) {
        let range = NSRange(location: 0, length: length)
        addAttribute(.kern, value: kerning, range: range)
    }

    /// 设置段落样式
    ///
    /// - Parameter style: 段落样式
    func ls_setParagraphStyle(_ style: NSParagraphStyle) {
        let range = NSRange(location: 0, length: length)
        addAttribute(.paragraphStyle, value: style, range: range)
    }
}

// MARK: - String Extension (富文本)

public extension String {

    /// 转换为富文本
    ///
    /// - Parameter configure: 配置闭包
    /// - Returns: 富文本
    func ls_attributedString(configure: (inout LSAttributedString) -> Void = { _ in }) -> NSAttributedString {
        var builder = LSAttributedString(self)
        configure(&builder)
        return builder.build()
    }

    /// 转换为带颜色的富文本
    ///
    /// - Parameter color: 颜色
    /// - Returns: 富文本
    func ls_colored(_ color: UIColor) -> NSAttributedString {
        return ls_attributedString {
            $0.textColor(color)
        }
    }

    /// 转换为带字体的富文本
    ///
    /// - Parameter font: 字体
    /// - Returns: 富文本
    func ls_font(_ font: UIFont) -> NSAttributedString {
        return ls_attributedString {
            $0.font(font)
        }
    }

    /// 转换为带下划线的富文本
    ///
    /// - Returns: 富文本
    func ls_underlined() -> NSAttributedString {
        return ls_attributedString {
            $0.underline()
        }
    }

    /// 转换为带删除线的富文本
    ///
    /// - Returns: 富文本
    func ls_strikethrough() -> NSAttributedString {
        return ls_attributedString {
            $0.strikethrough()
        }
    }

    /// 从 HTML 创建富文本
    ///
    /// - Returns: 富文本
    func ls_htmlAttributedString() -> NSAttributedString? {
        guard let data = data(using: .utf8) else { return nil }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        return try? NSAttributedString(data: data, options: options, documentAttributes: nil)
    }
}

#endif

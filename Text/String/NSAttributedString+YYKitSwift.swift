//
//  NSAttributedString+YYKitSwift.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  NSAttributedString 和 NSMutableAttributedString 的富文本扩展
//

#if canImport(UIKit)
import UIKit
import CoreText

// MARK: - NSAttributedString 扩展

public extension NSAttributedString {

    // MARK: - 属性访问

    /// 返回第一个字符的属性
    var attributes: [NSAttributedString.Key: Any]? {
        guard length > 0 else { return nil }
        return self.attributes(at: 0, effectiveRange: nil)
    }

    /// 返回指定索引的属性
    func attributes(at index: Int) -> [NSAttributedString.Key: Any]? {
        guard length > 0 && index < length else { return nil }
        return self.attributes(at: index, effectiveRange: nil)
    }

    /// 返回指定索引的属性值
    func attribute(_ attributeName: String, at index: Int) -> Any? {
        guard length > 0 && index < length else { return nil }
        return self.attribute(attributeName, at: index, effectiveRange: nil)
    }

    // MARK: - 属性快速访问（字符级别）

    /// 文本字体（只读）
    var font: UIFont? {
        return self.font(at: 0)
    }

    func font(at index: Int) -> UIFont? {
        return attribute(kCTFontAttributeName as String, at: index) as? UIFont
    }

    /// 字距调整（只读）
    var kern: NSNumber? {
        return self.kern(at: 0)
    }

    func kern(at index: Int) -> NSNumber? {
        return attribute(kCTKernAttributeName as String, at: index) as? NSNumber
    }

    /// 前景色（只读）
    var color: UIColor? {
        return self.color(at: 0)
    }

    func color(at index: Int) -> UIColor? {
        return attribute(kCTForegroundColorAttributeName as String, at: index) as? UIColor
    }

    /// 背景色（只读）
    var backgroundColor: UIColor? {
        return self.backgroundColor(at: 0)
    }

    func backgroundColor(at index: Int) -> UIColor? {
        return attribute(kCTBackgroundColorAttributeName as String, at: index) as? UIColor
    }

    /// 描边宽度（只读）
    var strokeWidth: NSNumber? {
        return self.strokeWidth(at: 0)
    }

    func strokeWidth(at index: Int) -> NSNumber? {
        return attribute(kCTStrokeWidthAttributeName as String, at: index) as? NSNumber
    }

    /// 描边颜色（只读）
    var strokeColor: UIColor? {
        return self.strokeColor(at: 0)
    }

    func strokeColor(at index: Int) -> UIColor? {
        return attribute(kCTStrokeColorAttributeName as String, at: index) as? UIColor
    }

    /// 文本阴影（只读）
    var shadow: NSShadow? {
        return self.shadow(at: 0)
    }

    func shadow(at index: Int) -> NSShadow? {
        return attribute(NSShadowAttributeName, at: index) as? NSShadow
    }

    /// 删除线样式（只读）
    var strikethroughStyle: NSUnderlineStyle {
        return self.strikethroughStyle(at: 0)
    }

    func strikethroughStyle(at index: Int) -> NSUnderlineStyle {
        return attribute(NSStrikethroughStyleAttributeName, at: index) as? NSUnderlineStyle ?? .styleNone
    }

    /// 删除线颜色（只读）
    var strikethroughColor: UIColor? {
        return self.strikethroughColor(at: 0)
    }

    func strikethroughColor(at index: Int) -> UIColor? {
        return attribute(NSStrikethroughColorAttributeName, at: index) as? UIColor
    }

    /// 下划线样式（只读）
    var underlineStyle: NSUnderlineStyle {
        return self.underlineStyle(at: 0)
    }

    func underlineStyle(at index: Int) -> NSUnderlineStyle {
        return attribute(kCTUnderlineStyleAttributeName as String, at: index) as? NSUnderlineStyle ?? .styleNone
    }

    /// 下划线颜色（只读）
    var underlineColor: UIColor? {
        return self.underlineColor(at: 0)
    }

    func underlineColor(at index: Int) -> UIColor? {
        return attribute(kCTUnderlineColorAttributeName as String, at: index) as? UIColor
    }

    /// 连字控制（只读）
    var ligature: NSNumber? {
        return self.ligature(at: 0)
    }

    func ligature(at index: Int) -> NSNumber? {
        return attribute(kCTLigatureAttributeName as String, at: index) as? NSNumber
    }

    /// 字形倾斜度（只读）
    var obliqueness: NSNumber? {
        return self.obliqueness(at: 0)
    }

    func obliqueness(at index: Int) -> NSNumber? {
        return attribute(kCTObliquenessAttributeName as String, at: index) as? NSNumber
    }

    /// 字形扩展因子（只读）
    var expansion: NSNumber? {
        return self.expansion(at: 0)
    }

    func expansion(at index: Int) -> NSNumber? {
        return attribute(kCTExpansionAttributeName as String, at: index) as? NSNumber
    }

    /// 基线偏移（只读）
    var baselineOffset: NSNumber? {
        return self.baselineOffset(at: 0)
    }

    func baselineOffset(at index: Int) -> NSNumber? {
        return attribute(kCTBaselineOffsetAttributeName as String, at: index) as NSNumber?
    }

    /// 段落样式（只读）
    var paragraphStyle: NSParagraphStyle? {
        return self.paragraphStyle(at: 0)
    }

    func paragraphStyle(at index: Int) -> NSParagraphStyle? {
        return attribute(kCTParagraphStyleAttributeName as String, at: index) as? NSParagraphStyle
    }

    // MARK: - YYText 属性快速访问

    /// YYText 文本阴影（只读）
    var textShadow: LSTextShadow? {
        return self.textShadow(at: 0)
    }

    func textShadow(at index: Int) -> LSTextShadow? {
        return attribute(LSTextShadowAttributeName, at: index) as? LSTextShadow
    }

    /// YYText 文本内阴影（只读）
    var textInnerShadow: LSTextShadow? {
        return self.textInnerShadow(at: 0)
    }

    func textInnerShadow(at index: Int) -> LSTextShadow? {
        return attribute(LSTextInnerShadowAttributeName, at: index) as? LSTextShadow
    }

    /// YYText 文本下划线（只读）
    var textUnderline: LSTextDecoration? {
        return self.textUnderline(at: 0)
    }

    func textUnderline(at index: Int) -> LSTextDecoration? {
        return attribute(LSTextUnderlineAttributeName, at: index) as? LSTextDecoration
    }

    /// YYText 文本删除线（只读）
    var textStrikethrough: LSTextDecoration? {
        return self.textStrikethrough(at: 0)
    }

    func textStrikethrough(at index: Int) -> LSTextDecoration? {
        return attribute(LSTextStrikethroughAttributeName, at: index) as? LSTextDecoration
    }

    /// YYText 文本边框（只读）
    var textBorder: LSTextBorder? {
        return self.textBorder(at: 0)
    }

    func textBorder(at index: Int) -> LSTextBorder? {
        return attribute(LSTextBorderAttributeName, at: index) as? LSTextBorder
    }

    /// YYText 文本背景边框（只读）
    var textBackgroundBorder: LSTextBorder? {
        return self.textBackgroundBorder(at: 0)
    }

    func textBackgroundBorder(at index: Int) -> LSTextBorder? {
        return attribute(LSTextBackgroundBorderAttributeName, at: index) as? LSTextBorder
    }

    /// YYText 字形变换（只读）
    var textGlyphTransform: CGAffineTransform {
        return self.textGlyphTransform(at: 0)
    }

    func textGlyphTransform(at index: Int) -> CGAffineTransform {
        if let value = attribute(LSTextGlyphTransformAttributeName, at: index) {
            return value as! CGAffineTransform
        }
        return .identity
    }

    // MARK: - 工具方法

    /// 返回整个文本范围
    var rangeOfAll: NSRange {
        return NSRange(location: 0, length: length)
    }

    /// 是否在整个文本范围共享相同属性
    var isSharedAttributesInAllRange: Bool {
        guard length > 0 else { return false }
        let attrs = self.attributes(at: 0, effectiveRange: nil)
        var range = NSRange(location: 0, length: 0)
        enumerateAttributes(in: NSRange(location: 0, length: length), options: []) { attrs2, range2, _ in
            if let attrs2 = attrs2 as? [NSAttributedString.Key: Any], attrs != attrs2 {
                return false
            }
            range = range2
        }
        return range.length == length
    }

    /// 是否可以用 UIKit 绘制
    var canDrawWithUIKit: Bool {
        guard length > 0 else { return true }

        var result = true
        enumerateAttributes(in: rangeOfAll, options: []) { attrs, _, _ in
            for key in attrs.keys {
                if let keyStr = key as? String {
                    let type = attributeType(from: keyStr)
                    if type.contains(.coreText) {
                        result = false
                        break
                    }
                }
            }
        }

        return result
    }

    /// 从范围获取纯文本
    /// 如果有 LSTextBackedStringAttributeName 属性，则使用支持字符串替换属性字符串范围
    func plainText(for range: NSRange) -> String? {
        guard range.location + range.length <= length else { return nil }
        var result = string as NSString
        enumerateAttribute(LSTextBackedStringAttributeName, in: range, options: []) { value, range2, _ in
            if let backed = value as? LSTextBackedString, let backedString = backed.string {
                result = result.replacingCharacters(in: range2, with: backedString) as NSString
            }
        }
        return result as String
    }

    // MARK: - 归档/解档

    /// 将字符串归档为数据
    func archiveToData() -> Data? {
        return try? NSKeyedArchiver.archivedData(withRootObject: self)
    }

    /// 从数据解档字符串
    static func unarchive(from data: Data) -> NSAttributedString? {
        return try? NSKeyedUnarchiver.unarchiveTopLevelObject(with: data) as? NSAttributedString
    }

    // MARK: - 私有方法

    private func attributeType(from attributeName: String) -> LSTextAttributeType {
        switch attributeName {
        case kCTFontAttributeName,
             kCTForegroundColorAttributeName,
             kCTBackgroundColorAttributeName,
             kCTStrokeWidthAttributeName,
             kCTStrokeColorAttributeName,
             kCTUnderlineStyleAttributeName,
             kCTUnderlineColorAttributeName,
             kCTSuperscriptAttributeName,
             kCTLigatureAttributeName,
             kCTVerticalFormsAttributeName,
             kCTGlyphInfoAttributeName,
             kCTCharacterShapeAttributeName,
             kCTRunDelegateAttributeName,
             kCTBaselineClassAttributeName,
             kCTBaselineInfoAttributeName,
             kCTBaselineReferenceInfoAttributeName,
             kCTWritingDirectionAttributeName:
            return .coreText

        case LSTextBackedStringAttributeName,
             LSTextBindingAttributeName,
             LSTextShadowAttributeName,
             LSTextInnerShadowAttributeName,
             LSTextUnderlineAttributeName,
             LSTextStrikethroughAttributeName,
             LSTextBorderAttributeName,
             LSTextBackgroundBorderAttributeName,
             LSTextBlockBorderAttributeName,
             LSTextAttachmentAttributeName,
             LSTextHighlightAttributeName,
             LSTextGlyphTransformAttributeName:
            return .yyText

        default:
            // 检查是否是 UIKit 属性
            if attributeName == NSShadowAttributeName ||
               attributeName == NSParagraphStyleAttributeName ||
               attributeName == NSAttachmentAttributeName ||
               attributeName == NSLinkAttributeName {
                return .uiKit
            }
            return .none
        }
    }
}

// MARK: - NSMutableAttributedString 扩展

public extension NSMutableAttributedString {

    // MARK: - 设置属性

    /// 设置整个文本字符串的属性
    ///
    /// - Parameter attributes: 要设置的属性字典，nil 表示移除所有属性
    func setAttributes(_ attributes: [NSAttributedString.Key: Any]?) {
        guard let attrs = attributes else {
            self.setAttributes([:], range: rangeOfAll)
            return
        }
        self.setAttributes(attrs, range: rangeOfAll)
    }

    /// 为整个文本字符串设置指定名称的属性
    ///
    /// - Parameters:
    ///   - name: 属性名称
    ///   - value: 属性值，nil 或 NSNull 表示移除属性
    func setAttribute(_ name: String, value: Any?) {
        guard let key = NSAttributedString.Key(name) else { return }
        if let val = value {
            self.addAttribute(key, value: val, range: rangeOfAll)
        } else {
            self.removeAttribute(key, range: rangeOfAll)
        }
    }

    /// 为指定范围的字符设置指定名称和值的属性
    ///
    /// - Parameters:
    ///   - name: 属性名称
    ///   - value: 属性值
    ///   - range: 应用属性值的字符范围
    func setAttribute(_ name: String, value: Any?, range: NSRange) {
        guard let key = NSAttributedString.Key(name) else { return }
        if let val = value {
            self.addAttribute(key, value: val, range: range)
        } else {
            self.removeAttribute(key, range: range)
        }
    }

    /// 移除指定范围的所有属性
    ///
    /// - Parameter range: 字符范围
    func removeAttributes(in range: NSRange) {
        self.setAttributes([:], range: range)
    }

    // MARK: - 设置字符属性

    /// 文本字体
    var font: UIFont? {
        get { return self.font(at: 0) }
        set { setFont(newValue, range: rangeOfAll) }
    }

    func setFont(_ font: UIFont?, range: NSRange) {
        guard let key = NSAttributedString.Key(kCTFontAttributeName) else { return }
        if let font = font {
            addAttribute(key, value: font, range: range)
        } else {
            removeAttribute(key, range: range)
        }
    }

    /// 字距
    var kern: NSNumber? {
        get { return self.kern(at: 0) }
        set { setKern(newValue, range: rangeOfAll) }
    }

    func setKern(_ kern: NSNumber?, range: NSRange) {
        guard let key = NSAttributedString.Key(kCTKernAttributeName) else { return }
        if let kern = kern {
            addAttribute(key, value: kern, range: range)
        } else {
            removeAttribute(key, range: range)
        }
    }

    /// 前景色
    var color: UIColor? {
        get { return self.color(at: 0) }
        set { setColor(newValue, range: rangeOfAll) }
    }

    func setColor(_ color: UIColor?, range: NSRange) {
        guard let key = NSAttributedString.Key(kCTForegroundColorAttributeName) else { return }
        if let color = color {
            addAttribute(key, value: color, range: range)
        } else {
            removeAttribute(key, range: range)
        }
    }

    /// 背景色
    var backgroundColor: UIColor? {
        get { return self.backgroundColor(at: 0) }
        set { setBackgroundColor(newValue, range: rangeOfAll) }
    }

    func setBackgroundColor(_ backgroundColor: UIColor?, range: NSRange) {
        guard let key = NSAttributedString.Key(kCTBackgroundColorAttributeName) else { return }
        if let color = backgroundColor {
            addAttribute(key, value: color, range: range)
        } else {
            removeAttribute(key, range: range)
        }
    }

    /// 描边宽度
    var strokeWidth: NSNumber? {
        get { return self.strokeWidth(at: 0) }
        set { setStrokeWidth(newValue, range: rangeOfAll) }
    }

    func setStrokeWidth(_ strokeWidth: NSNumber?, range: NSRange) {
        guard let key = NSAttributedString.Key(kCTStrokeWidthAttributeName) else { return }
        if let width = strokeWidth {
            addAttribute(key, value: width, range: range)
        } else {
            removeAttribute(key, range: range)
        }
    }

    /// 描边颜色
    var strokeColor: UIColor? {
        get { return self.strokeColor(at: 0) }
        set { setStrokeColor(newValue, range: rangeOfAll) }
    }

    func setStrokeColor(_ strokeColor: UIColor?, range: NSRange) {
        guard let key = NSAttributedString.Key(kCTStrokeColorAttributeName) else { return }
        if let color = strokeColor {
            addAttribute(key, value: color, range: range)
        } else {
            removeAttribute(key, range: range)
        }
    }

    /// 文本阴影
    var shadow: NSShadow? {
        get { return self.shadow(at: 0) }
        set { setShadow(newValue, range: rangeOfAll) }
    }

    func setShadow(_ shadow: NSShadow?, range: NSRange) {
        guard let key = NSShadowAttributeName else { return }
        if let shadow = shadow {
            addAttribute(key, value: shadow, range: range)
        } else {
            removeAttribute(key, range: range)
        }
    }

    /// 删除线样式
    var strikethroughStyle: NSUnderlineStyle {
        get { return self.strikethroughStyle(at: 0) }
        set { setStrikethroughStyle(newValue, range: rangeOfAll) }
    }

    func setStrikethroughStyle(_ strikethroughStyle: NSUnderlineStyle, range: NSRange) {
        guard let key = NSStrikethroughStyleAttributeName else { return }
        addAttribute(key, value: strikethroughStyle.rawValue, range: range)
    }

    /// 删除线颜色
    var strikethroughColor: UIColor? {
        get { return self.strikethroughColor(at: 0) }
        set { setStrikethroughColor(newValue, range: rangeOfAll) }
    }

    func setStrikethroughColor(_ strikethroughColor: UIColor?, range: NSRange) {
        guard let key = NSStrikethroughColorAttributeName else { return }
        if let color = strikethroughColor {
            addAttribute(key, value: color, range: range)
        } else {
            removeAttribute(key, range: range)
        }
    }

    /// 下划线样式
    var underlineStyle: NSUnderlineStyle {
        get { return self.underlineStyle(at: 0) }
        set { setUnderlineStyle(newValue, range: rangeOfAll) }
    }

    func setUnderlineStyle(_ underlineStyle: NSUnderlineStyle, range: NSRange) {
        guard let key = NSAttributedString.Key(kCTUnderlineStyleAttributeName) else { return }
        addAttribute(key, value: underlineStyle.rawValue, range: range)
    }

    /// 下划线颜色
    var underlineColor: UIColor? {
        get { return self.underlineColor(at: 0) }
        set { setUnderlineColor(newValue, range: rangeOfAll) }
    }

    func setUnderlineColor(_ underlineColor: UIColor?, range: NSRange) {
        guard let key = NSAttributedString.Key(kCTUnderlineColorAttributeName) else { return }
        if let color = underlineColor {
            addAttribute(key, value: color, range: range)
        } else {
            removeAttribute(key, range: range)
        }
    }

    /// 连字控制
    var ligature: NSNumber? {
        get { return self.ligature(at: 0) }
        set { setLigature(newValue, range: rangeOfAll) }
    }

    func setLigature(_ ligature: NSNumber?, range: NSRange) {
        guard let key = NSAttributedString.Key(kCTLigatureAttributeName) else { return }
        if let lig = ligature {
            addAttribute(key, value: lig, range: range)
        } else {
            removeAttribute(key, range: range)
        }
    }

    /// 基线偏移
    var baselineOffset: NSNumber? {
        get { return self.baselineOffset(at: 0) }
        set { setBaselineOffset(newValue, range: rangeOfAll) }
    }

    func setBaselineOffset(_ baselineOffset: NSNumber?, range: NSRange) {
        guard let key = NSAttributedString.Key(kCTBaselineOffsetAttributeName) else { return }
        if let offset = baselineOffset {
            addAttribute(key, value: offset, range: range)
        } else {
            removeAttribute(key, range: range)
        }
    }

    /// 段落样式
    var paragraphStyle: NSParagraphStyle? {
        get { return self.paragraphStyle(at: 0) }
        set { setParagraphStyle(newValue, range: rangeOfAll) }
    }

    func setParagraphStyle(_ paragraphStyle: NSParagraphStyle?, range: NSRange) {
        guard let key = NSAttributedString.Key(kCTParagraphStyleAttributeName) else { return }
        if let style = paragraphStyle {
            addAttribute(key, value: style, range: range)
        } else {
            removeAttribute(key, range: range)
        }
    }

    // MARK: - YYText 属性设置

    /// YYText 文本阴影
    var textShadow: LSTextShadow? {
        get { return self.textShadow(at: 0) }
        set { setTextShadow(newValue, range: rangeOfAll) }
    }

    func setTextShadow(_ textShadow: LSTextShadow?, range: NSRange) {
        if let shadow = textShadow {
            addAttribute(LSTextShadowAttributeName, value: shadow, range: range)
        } else {
            removeAttribute(LSTextShadowAttributeName, range: range)
        }
    }

    /// YYText 文本内阴影
    var textInnerShadow: LSTextShadow? {
        get { return self.textInnerShadow(at: 0) }
        set { setTextInnerShadow(newValue, range: rangeOfAll) }
    }

    func setTextInnerShadow(_ textInnerShadow: LSTextShadow?, range: NSRange) {
        if let shadow = textInnerShadow {
            addAttribute(LSTextInnerShadowAttributeName, value: shadow, range: range)
        } else {
            removeAttribute(LSTextInnerShadowAttributeName, range: range)
        }
    }

    /// YYText 文本下划线
    var textUnderline: LSTextDecoration? {
        get { return self.textUnderline(at: 0) }
        set { setTextUnderline(newValue, range: rangeOfAll) }
    }

    func setTextUnderline(_ textUnderline: LSTextDecoration?, range: NSRange) {
        if let underline = textUnderline {
            addAttribute(LSTextUnderlineAttributeName, value: underline, range: range)
        } else {
            removeAttribute(LSTextUnderlineAttributeName, range: range)
        }
    }

    /// YYText 文本删除线
    var textStrikethrough: LSTextDecoration? {
        get { return self.textStrikethrough(at: 0) }
        set { setTextStrikethrough(newValue, range: rangeOfAll) }
    }

    func setTextStrikethrough(_ textStrikethrough: LSTextDecoration?, range: NSRange) {
        if let strikethrough = textStrikethrough {
            addAttribute(LSTextStrikethroughAttributeName, value: strikethrough, range: range)
        } else {
            removeAttribute(LSTextStrikethroughAttributeName, range: range)
        }
    }

    /// YYText 文本边框
    var textBorder: LSTextBorder? {
        get { return self.textBorder(at: 0) }
        set { setTextBorder(newValue, range: rangeOfAll) }
    }

    func setTextBorder(_ textBorder: LSTextBorder?, range: NSRange) {
        if let border = textBorder {
            addAttribute(LSTextBorderAttributeName, value: border, range: range)
        } else {
            removeAttribute(LSTextBorderAttributeName, range: range)
        }
    }

    /// YYText 文本背景边框
    var textBackgroundBorder: LSTextBorder? {
        get { return self.textBackgroundBorder(at: 0) }
        set { setTextBackgroundBorder(newValue, range: rangeOfAll) }
    }

    func setTextBackgroundBorder(_ textBackgroundBorder: LSTextBorder?, range: NSRange) {
        if let border = textBackgroundBorder {
            addAttribute(LSTextBackgroundBorderAttributeName, value: border, range: range)
        } else {
            removeAttribute(LSTextBackgroundBorderAttributeName, range: range)
        }
    }

    /// YYText 字形变换
    var textGlyphTransform: CGAffineTransform {
        get { return self.textGlyphTransform(at: 0) }
        set { setTextGlyphTransform(newValue, range: rangeOfAll) }
    }

    func setTextGlyphTransform(_ textGlyphTransform: CGAffineTransform, range: NSRange) {
        addAttribute(LSTextGlyphTransformAttributeName, value: NSValue(cgAffineTransform: textGlyphTransform), range: range)
    }

    // MARK: - 便捷方法

    /// 在指定位置插入字符串
    ///
    /// 新字符串继承位置处第一个被替换字符的属性
    ///
    /// - Parameters:
    ///   - string: 要插入的字符串
    ///   - location: 插入位置
    func insert(_ string: String, at location: Int) {
        let attrs = self.attributes(at: location, effectiveRange: nil) ?? [:]
        let attrString = NSAttributedString(string: string, attributes: attrs)
        insert(attrString, at: location)
    }

    /// 在末尾追加字符串
    ///
    /// 新字符串继承接收者的尾部属性
    ///
    /// - Parameter string: 要追加的字符串
    func append(_ string: String) {
        let attrs = self.attributes(at: max(0, length - 1), effectiveRange: nil) ?? [:]
        let attrString = NSAttributedString(string: string, attributes: attrs)
        append(attrString)
    }

    /// 设置文本高亮
    ///
    /// - Parameters:
    ///   - range: 文本范围
    ///   - color: 文本颜色
    ///   - backgroundColor: 高亮时的背景颜色
    ///   - userInfo: 用户信息
    ///   - tapAction: 点击操作
    ///   - longPressAction: 长按操作
    func setTextHighlight(
        range: NSRange,
        color: UIColor?,
        backgroundColor: UIColor?,
        userInfo: [AnyHashable: Any]?,
        tapAction: LSTextAction?,
        longPressAction: LSTextAction?
    ) {
        var highlightAttrs: [String: Any] = [:]

        if let color = color {
            highlightAttrs[kCTForegroundColorAttributeName as String] = color
        }

        if let bgColor = backgroundColor {
            highlightAttrs[LSTextBackgroundBorderAttributeName] = LSTextBorder.border(fillColor: bgColor, cornerRadius: 4)
        }

        let highlight = LSTextHighlight()
        highlight.attributes = highlightAttrs
        highlight.userInfo = userInfo
        highlight.tapAction = tapAction
        highlight.longPressAction = longPressAction

        addAttribute(LSTextHighlightAttributeName, value: highlight, range: range)
    }

    /// 设置文本高亮（简化版）
    ///
    /// - Parameters:
    ///   - range: 文本范围
    ///   - color: 文本颜色
    ///   - backgroundColor: 背景颜色
    func setTextHighlight(range: NSRange, color: UIColor?, backgroundColor: UIColor?) {
        setTextHighlight(range: range, color: color, backgroundColor: backgroundColor, userInfo: nil, tapAction: nil, longPressAction: nil)
    }
}
#endif

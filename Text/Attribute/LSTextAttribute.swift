//
//  LSTextAttribute.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  文本属性定义 - YYText 属性名和值类型
//

#if canImport(UIKit)
import UIKit
import CoreText

// MARK: - 属性类型枚举

/// 文本属性类型
public struct LSTextAttributeType: OptionSet {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    /// UIKit 属性 (UILabel/UITextField/drawInRect)
    public static let uiKit = LSTextAttributeType(rawValue: 1 << 0)

    /// CoreText 属性
    public static let coreText = LSTextAttributeType(rawValue: 1 << 1)

    /// YYText 属性
    public static let yyText = LSTextAttributeType(rawValue: 1 << 2)
}

// MARK: - 文本线条样式

/// 文本线条样式（类似 NSUnderlineStyle）
public struct LSTextLineStyle: OptionSet {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    // 基础样式 (bitmask: 0xFF)
    /// 不绘制线条
    public static let none = LSTextLineStyle(rawValue: 0x00)
    /// 单线 (──────)
    public static let single = LSTextLineStyle(rawValue: 0x01)
    /// 粗线 (━━━━━━━)
    public static let thick = LSTextLineStyle(rawValue: 0x02)
    /// 双线 (══════)
    public static let double = LSTextLineStyle(rawValue: 0x09)

    // 样式模式 (bitmask: 0xF00)
    /// 实线 (────────)
    public static let patternSolid = LSTextLineStyle(rawValue: 0x000)
    /// 点线 (‑ ‑ ‑ ‑ ‑ ‑)
    public static let patternDot = LSTextLineStyle(rawValue: 0x100)
    /// 虚线 (— — — —)
    public static let patternDash = LSTextLineStyle(rawValue: 0x200)
    /// 点划线 (— ‑ — ‑ — ‑)
    public static let patternDashDot = LSTextLineStyle(rawValue: 0x300)
    /// 点点划线 (— ‑ ‑ — ‑ ‑)
    public static let patternDashDotDot = LSTextLineStyle(rawValue: 0x400)
    /// 圆点线 (••••••••••••)
    public static let patternCircleDot = LSTextLineStyle(rawValue: 0x900)
}

// MARK: - 文本垂直对齐

/// 文本垂直对齐
public enum LSTextVerticalAlignment: Int {
    case top = 0
    case center = 1
    case bottom = 2
}

// MARK: - 文本方向

/// YYText 中的方向定义
public struct LSTextDirection: OptionSet {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let none = LSTextDirection(rawValue: 0)
    public static let top = LSTextDirection(rawValue: 1 << 0)
    public static let right = LSTextDirection(rawValue: 1 << 1)
    public static let bottom = LSTextDirection(rawValue: 1 << 2)
    public static let left = LSTextDirection(rawValue: 1 << 3)
}

// MARK: - 截断类型

/// 截断类型，告诉截断引擎请求哪种类型的截断
public enum LSTextTruncationType: UInt {
    case none = 0
    case start = 1
    case end = 2
    case middle = 3
}

// MARK: - 属性名定义（YYText 自定义）

/// YYTextBackedString 对象的值
/// 使用此属性存储原始纯文本（如果被其他内容替换，如附件）
public let LSTextBackedStringAttributeName = "YYTextBackedStringAttribute"

/// YYTextBinding 对象的值
/// 使用此属性将文本范围绑定在一起，就像单个字符一样
public let LSTextBindingAttributeName = "YYTextBindingAttribute"

/// YYTextShadow 对象的值
/// 使用此属性为文本范围添加阴影
/// 阴影绘制在文本字形下方，使用 subShadow 添加多层阴影
public let LSTextShadowAttributeName = "YYTextShadowAttribute"

/// YYTextShadow 对象的值
/// 使用此属性为文本范围添加内阴影
/// 内阴影绘制在文本字形上方，使用 subShadow 添加多层阴影
public let LSTextInnerShadowAttributeName = "YYTextInnerShadowAttribute"

/// YYTextDecoration 对象的值
/// 使用此属性为文本范围添加下划线
/// 下划线绘制在文本字形下方
public let LSTextUnderlineAttributeName = "YYTextUnderlineAttribute"

/// YYTextDecoration 对象的值
/// 使用此属性为文本范围添加删除线
/// 删除线绘制在文本字形上方
public let LSTextStrikethroughAttributeName = "YYTextStrikethroughAttribute"

/// YYTextBorder 对象的值
/// 使用此属性为文本范围添加覆盖边框或颜色
/// 边框绘制在文本字形上方
public let LSTextBorderAttributeName = "YYTextBorderAttribute"

/// YYTextBorder 对象的值
/// 使用此属性为文本范围添加背景边框或颜色
/// 边框绘制在文本字形下方
public let LSTextBackgroundBorderAttributeName = "YYTextBackgroundBorderAttribute"

/// YYTextBorder 对象的值
/// 使用此属性为一行或多行文本添加代码块边框
/// 边框绘制在文本字形下方
public let LSTextBlockBorderAttributeName = "YYTextBlockBorderAttribute"

/// YYTextAttachment 对象的值
/// 使用此属性为文本添加附件
/// 应与 CTRunDelegate 一起使用
public let LSTextAttachmentAttributeName = "YYTextAttachmentAttribute"

/// YYTextHighlight 对象的值
/// 使用此属性为文本范围添加可触摸的高亮状态
public let LSTextHighlightAttributeName = "YYTextHighlightAttribute"

/// NSValue 对象，存储 CGAffineTransform
/// 使用此属性为文本范围内的每个字形添加变换
public let LSTextGlyphTransformAttributeName = "YYTextGlyphTransformAttribute"

// MARK: - 字符串标记定义

/// 对象替换字符 (U+FFFC)，用于文本附件
public let LSTextAttachmentToken = "\u{FFFC}"

/// 水平省略号 (U+2026)，用于文本截断 "…"
public let LSTextTruncationToken = "\u{2026}"

// MARK: - 文本操作闭包

/// YYText 中定义的点击/长按操作回调
///
/// - Parameters:
///   - containerView: 文本容器视图 (如 YYLabel/YYTextView)
///   - text: 整个文本
///   - range: `text` 中的文本范围（如果没有范围，range.location 为 NSNotFound）
///   - rect: `containerView` 中的文本框架（如果没有数据，rect 为 CGRectNull）
public typealias LSTextAction = (UIView, NSAttributedString, NSRange, CGRect) -> Void

// MARK: - LSTextBackedString

/// LSTextBackedString 对象被 NSAttributedString 类簇用作文本支持字符串属性的值
///
/// 可能用于从属性字符串复制/粘贴纯文本
/// 示例：如果 :) 被自定义 emoji（如😊）替换，支持字符串可以设置为 ":)"
@MainActor
public class LSTextBackedString: NSObject, NSCoding, NSCopying {

    /// 支持字符串
    public var string: String?

    /// 使用指定字符串创建
    ///
    /// - Parameter string: 支持字符串
    /// - Returns: 新实例
    public static func string(with string: String?) -> LSTextBackedString {
        let backed = LSTextBackedString()
        backed.string = string
        return backed
    }

    // MARK: - NSCoding

    required public init?(coder: NSCoder) {
        super.init()
        string = coder.decodeObject(forKey: "string") as? String
    }

    public func encode(with coder: NSCoder) {
        coder.encode(string, forKey: "string")
    }

    // MARK: - NSCopying

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = LSTextBackedString()
        copy.string = string
        return copy
    }
}

// MARK: - LSTextBinding

/// LSTextBinding 对象被 NSAttributedString 类簇用作阴影属性的值
///
/// 将此属性添加到文本范围会使指定字符"绑定在一起"
/// YYTextView 在文本选择和编辑期间将文本范围视为单个字符
public class LSTextBinding: NSObject, NSCoding, NSCopying {

    /// 在 YYTextView 中删除时确认范围
    public var deleteConfirm: Bool = false

    /// 使用指定的删除确认创建绑定
    ///
    /// - Parameter deleteConfirm: 是否需要删除确认
    /// - Returns: 新实例
    public static func binding(deleteConfirm: Bool) -> LSTextBinding {
        let binding = LSTextBinding()
        binding.deleteConfirm = deleteConfirm
        return binding
    }

    // MARK: - NSCoding

    required public init?(coder: NSCoder) {
        super.init()
        deleteConfirm = coder.decodeBool(forKey: "deleteConfirm")
    }

    public func encode(with coder: NSCoder) {
        coder.encode(deleteConfirm, forKey: "deleteConfirm")
    }

    // MARK: - NSCopying

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = LSTextBinding()
        copy.deleteConfirm = deleteConfirm
        return copy
    }
}

// MARK: - LSTextShadow

/// LSTextShadow 对象被 NSAttributedString 类簇用作阴影属性的值
///
/// 类似于 NSShadow，但提供更多选项
public class LSTextShadow: NSObject, NSCoding, NSCopying {

    /// 阴影颜色
    public var color: UIColor?

    /// 阴影偏移
    public var offset: CGSize = .zero

    /// 阴影模糊半径
    public var radius: CGFloat = 0

    /// 阴影混合模式
    public var blendMode: CGBlendMode = .normal

    /// 子阴影（将添加在父阴影上方）
    public var subShadow: LSTextShadow?

    /// 使用指定参数创建阴影
    ///
    /// - Parameters:
    ///   - color: 阴影颜色
    ///   - offset: 阴影偏移
    ///   - radius: 阴影模糊半径
    /// - Returns: 新实例
    public static func shadow(color: UIColor?, offset: CGSize, radius: CGFloat) -> LSTextShadow {
        let shadow = LSTextShadow()
        shadow.color = color
        shadow.offset = offset
        shadow.radius = radius
        return shadow
    }

    /// 从 NSShadow 转换
    ///
    /// - Parameter nsShadow: NSShadow 对象
    /// - Returns: 新实例
    public static func shadow(nsShadow: NSShadow?) -> LSTextShadow {
        let shadow = LSTextShadow()
        shadow.color = nsShadow?.shadowColor
        let shadowOffset: CGSize
        if let offset = nsShadow?.shadowOffset {
            shadowOffset = offset
        } else {
            shadowOffset = .zero
        }
        shadow.offset = shadowOffset
        let shadowRadius: CGFloat
        if let radius = nsShadow?.shadowBlurRadius {
            shadowRadius = radius
        } else {
            shadowRadius = 0
        }
        shadow.radius = shadowRadius
        return shadow
    }

    /// 转换为 NSShadow
    public var nsShadow: NSShadow {
        let shadow = NSShadow()
        shadow.shadowColor = color
        shadow.shadowOffset = offset
        shadow.shadowBlurRadius = radius
        return shadow
    }

    // MARK: - NSCoding

    required public init?(coder: NSCoder) {
        super.init()
        color = coder.decodeObject(forKey: "color") as? UIColor
        offset = coder.decodeCGSize(forKey: "offset")
        radius = coder.decodeCGFloat(forKey: "radius")
        let blendModeRawValue = coder.decodeInteger(forKey: "blendMode")
        let decodedBlendMode: CGBlendMode
        if let mode = CGBlendMode(rawValue: blendModeRawValue) {
            decodedBlendMode = mode
        } else {
            decodedBlendMode = .normal
        }
        blendMode = decodedBlendMode
        subShadow = coder.decodeObject(forKey: "subShadow") as? LSTextShadow
    }

    public func encode(with coder: NSCoder) {
        coder.encode(color, forKey: "color")
        coder.encode(offset, forKey: "offset")
        coder.encode(radius, forKey: "radius")
        coder.encode(Int(blendMode.rawValue), forKey: "blendMode")
        coder.encode(subShadow, forKey: "subShadow")
    }

    // MARK: - NSCopying

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = LSTextShadow()
        copy.color = color
        copy.offset = offset
        copy.radius = radius
        copy.blendMode = blendMode
        copy.subShadow = subShadow?.copy() as? LSTextShadow
        return copy
    }
}

// MARK: - LSTextDecoration

/// LSTextDecoration 对象被用作装饰线属性的值
///
/// 用作下划线时，线条绘制在文本字形下方
/// 用作删除线时，线条绘制在文本字形上方
public class LSTextDecoration: NSObject, NSCoding, NSCopying {

    /// 线条样式
    public var style: LSTextLineStyle = .none

    /// 线条宽度（nil 表示自动宽度）
    public var width: NSNumber?

    /// 线条颜色（nil 表示自动颜色）
    public var color: UIColor?

    /// 线条阴影
    public var shadow: LSTextShadow?

    /// 使用指定样式创建装饰
    ///
    /// - Parameter style: 线条样式
    /// - Returns: 新实例
    public static func decoration(style: LSTextLineStyle) -> LSTextDecoration {
        let decoration = LSTextDecoration()
        decoration.style = style
        return decoration
    }

    /// 使用指定参数创建装饰
    ///
    /// - Parameters:
    ///   - style: 线条样式
    ///   - width: 线条宽度
    ///   - color: 线条颜色
    /// - Returns: 新实例
    public static func decoration(style: LSTextLineStyle, width: NSNumber?, color: UIColor?) -> LSTextDecoration {
        let decoration = LSTextDecoration()
        decoration.style = style
        decoration.width = width
        decoration.color = color
        return decoration
    }

    // MARK: - NSCoding

    required public init?(coder: NSCoder) {
        super.init()
        let styleRawValue = coder.decodeInteger(forKey: "style")
        let decodedStyle: LSTextLineStyle
        if let decoded = LSTextLineStyle(rawValue: styleRawValue) {
            decodedStyle = decoded
        } else {
            decodedStyle = .none
        }
        style = decodedStyle
        width = coder.decodeObject(forKey: "width") as? NSNumber
        color = coder.decodeObject(forKey: "color") as? UIColor
        shadow = coder.decodeObject(forKey: "shadow") as? LSTextShadow
    }

    public func encode(with coder: NSCoder) {
        coder.encode(style.rawValue, forKey: "style")
        coder.encode(width, forKey: "width")
        coder.encode(color, forKey: "color")
        coder.encode(shadow, forKey: "shadow")
    }

    // MARK: - NSCopying

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = LSTextDecoration()
        copy.style = style
        copy.width = width
        copy.color = color
        copy.shadow = shadow?.copy() as? LSTextShadow
        return copy
    }
}

// MARK: - LSTextBorder

/// LSTextBorder 对象被用作边框属性的值
///
/// 可用于在文本范围周围绘制边框，或为文本范围绘制背景
///
/// 示例:
///    ╭──────╮
///    │ Text │
///    ╰──────╯
public class LSTextBorder: NSObject, NSCoding, NSCopying {

    /// 边框线条样式
    public var lineStyle: LSTextLineStyle = .none

    /// 边框线条宽度
    public var strokeWidth: CGFloat = 0

    /// 边框线条颜色
    public var strokeColor: UIColor?

    /// 边框线条连接样式
    public var lineJoin: CGLineJoin = .miter

    /// 边框内边距（用于文本边界）
    public var insets: UIEdgeInsets = .zero

    /// 边框圆角半径
    public var cornerRadius: CGFloat = 0

    /// 边框阴影
    public var shadow: LSTextShadow?

    /// 内部填充颜色
    public var fillColor: UIColor?

    /// 使用线条样式创建边框
    ///
    /// - Parameters:
    ///   - lineStyle: 线条样式
    ///   - lineWidth: 线条宽度
    ///   - strokeColor: 线条颜色
    /// - Returns: 新实例
    public static func border(lineStyle: LSTextLineStyle, lineWidth: CGFloat, strokeColor: UIColor?) -> LSTextBorder {
        let border = LSTextBorder()
        border.lineStyle = lineStyle
        border.strokeWidth = lineWidth
        border.strokeColor = strokeColor
        return border
    }

    /// 使用填充颜色创建边框
    ///
    /// - Parameters:
    ///   - fillColor: 填充颜色
    ///   - cornerRadius: 圆角半径
    /// - Returns: 新实例
    public static func border(fillColor: UIColor?, cornerRadius: CGFloat) -> LSTextBorder {
        let border = LSTextBorder()
        border.fillColor = fillColor
        border.cornerRadius = cornerRadius
        return border
    }

    // MARK: - NSCoding

    required public init?(coder: NSCoder) {
        super.init()
        let lineStyleRawValue = coder.decodeInteger(forKey: "lineStyle")
        let decodedLineStyle: LSTextLineStyle
        if let decoded = LSTextLineStyle(rawValue: lineStyleRawValue) {
            decodedLineStyle = decoded
        } else {
            decodedLineStyle = .none
        }
        lineStyle = decodedLineStyle
        strokeWidth = coder.decodeCGFloat(forKey: "strokeWidth")
        strokeColor = coder.decodeObject(forKey: "strokeColor") as? UIColor
        let lineJoinRawValue = coder.decodeInteger(forKey: "lineJoin")
        let decodedLineJoin: CGLineJoin
        if let join = CGLineJoin(rawValue: lineJoinRawValue) {
            decodedLineJoin = join
        } else {
            decodedLineJoin = .miter
        }
        lineJoin = decodedLineJoin
        insets = coder.decodeUIEdgeInsets(forKey: "insets")
        cornerRadius = coder.decodeCGFloat(forKey: "cornerRadius")
        shadow = coder.decodeObject(forKey: "shadow") as? LSTextShadow
        fillColor = coder.decodeObject(forKey: "fillColor") as? UIColor
    }

    public func encode(with coder: NSCoder) {
        coder.encode(lineStyle.rawValue, forKey: "lineStyle")
        coder.encode(strokeWidth, forKey: "strokeWidth")
        coder.encode(strokeColor, forKey: "strokeColor")
        coder.encode(lineJoin.rawValue, forKey: "lineJoin")
        coder.encode(insets, forKey: "insets")
        coder.encode(cornerRadius, forKey: "cornerRadius")
        coder.encode(shadow, forKey: "shadow")
        coder.encode(fillColor, forKey: "fillColor")
    }

    // MARK: - NSCopying

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = LSTextBorder()
        copy.lineStyle = lineStyle
        copy.strokeWidth = strokeWidth
        copy.strokeColor = strokeColor
        copy.lineJoin = lineJoin
        copy.insets = insets
        copy.cornerRadius = cornerRadius
        copy.shadow = shadow?.copy() as? LSTextShadow
        copy.fillColor = fillColor
        return copy
    }
}

// MARK: - LSTextAttachment

/// LSTextAttachment 对象被用作附件属性的值
///
/// 显示包含 LSTextAttachment 的属性字符串时，内容将放置在文本度量中
/// 如果内容是 UIImage，则绘制到 CGContext
/// 如果内容是 UIView 或 CALayer，则添加到文本容器的视图或图层
public class LSTextAttachment: NSObject, NSCoding, NSCopying {

    /// 支持的内容类型：UIImage、UIView、CALayer
    public var content: AnyObject?

    /// 内容尺寸（用于附件排版）
    public var contentSize: CGSize = .zero

    /// 内容显示模式
    public var contentMode: UIView.ContentMode = .scaleToFill

    /// 绘制内容时的内边距
    public var contentInsets: UIEdgeInsets = .zero

    /// 用户信息字典
    public var userInfo: [AnyHashable: Any]?

    /// 使用指定内容创建附件
    ///
    /// - Parameter content: 内容（UIImage、UIView、CALayer）
    /// - Returns: 新实例
    public static func attachment(content: Any?) -> LSTextAttachment {
        let attachment = LSTextAttachment()
        attachment.content = content as AnyObject?
        return attachment
    }

    // MARK: - NSCoding

    required public init?(coder: NSCoder) {
        super.init()
        // 对于 content，这里需要更复杂的序列化逻辑
        content = coder.decodeObject(forKey: "content") as AnyObject
        contentSize = coder.decodeCGSize(forKey: "contentSize")
        let contentModeRawValue = coder.decodeInteger(forKey: "contentMode")
        let decodedContentMode: UIView.ContentMode
        if let mode = UIView.ContentMode(rawValue: contentModeRawValue) {
            decodedContentMode = mode
        } else {
            decodedContentMode = .scaleToFill
        }
        contentMode = decodedContentMode
        contentInsets = coder.decodeUIEdgeInsets(forKey: "contentInsets")
        userInfo = coder.decodeObject(forKey: "userInfo") as? [AnyHashable: Any]
    }

    public func encode(with coder: NSCoder) {
        coder.encode(content, forKey: "content")
        coder.encode(contentSize, forKey: "contentSize")
        coder.encode(contentMode.rawValue, forKey: "contentMode")
        coder.encode(contentInsets, forKey: "contentInsets")
        coder.encode(userInfo, forKey: "userInfo")
    }

    // MARK: - NSCopying

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = LSTextAttachment()
        copy.content = content
        copy.contentSize = contentSize
        copy.contentMode = contentMode
        copy.contentInsets = contentInsets
        copy.userInfo = userInfo
        return copy
    }
}

// MARK: - LSTextHighlight

/// LSTextHighlight 对象被用作可触摸高亮属性的值
///
/// 在 YYLabel 或 YYTextView 中显示属性字符串时，高亮文本范围可以被用户触摸
/// 当文本范围变为高亮状态时，`attributes` 中的 LSTextHighlight 将用于修改（设置或移除）
/// 范围内的原始属性以用于显示
public class LSTextHighlight: NSObject, NSCoding, NSCopying {

    /// 高亮时应用的属性
    /// - Key: 与 CoreText/YYText 属性名相同
    /// - Value: 高亮时修改属性值（NSNull 表示移除属性）
    public var attributes: [String: Any]?

    /// 用户信息字典
    public var userInfo: [AnyHashable: Any]?

    /// 点击时的高亮操作
    public var tapAction: LSTextAction?

    /// 长按时的高亮操作
    public var longPressAction: LSTextAction?

    /// 使用指定属性创建高亮
    ///
    /// - Parameter attributes: 高亮时替换原始属性的属性
    ///   如果值为 NSNull，则在高亮时移除
    /// - Returns: 新实例
    public static func highlight(attributes: [String: Any]?) -> LSTextHighlight {
        let highlight = LSTextHighlight()
        highlight.attributes = attributes
        return highlight
    }

    /// 使用指定背景颜色创建高亮
    ///
    /// - Parameter color: 背景边框颜色
    /// - Returns: 新实例
    public static func highlight(backgroundColor: UIColor?) -> LSTextHighlight {
        let highlight = LSTextHighlight()
        if let color = backgroundColor {
            highlight.attributes = [LSTextBackgroundBorderAttributeName: LSTextBorder.border(fillColor: color, cornerRadius: 4)]
        }
        return highlight
    }

    // MARK: - 便捷设置方法

    /// 设置字体
    public func setFont(_ font: UIFont?) {
        var attrs
        if let tempValue = attributes {
            attrs = tempValue
        } else {
            attrs = [:]
        }
        if let font = font {
            attrs[kCTFontAttributeName as String] = font
        } else {
            attrs.removeValue(forKey: kCTFontAttributeName as String)
        }
        attributes = attrs
    }

    /// 设置颜色
    public func setColor(_ color: UIColor?) {
        var attrs
        if let tempValue = attributes {
            attrs = tempValue
        } else {
            attrs = [:]
        }
        if let color = color {
            attrs[kCTForegroundColorAttributeName as String] = color
        } else {
            attrs.removeValue(forKey: kCTForegroundColorAttributeName as String)
        }
        attributes = attrs
    }

    /// 设置描边宽度
    public func setStrokeWidth(_ width: NSNumber?) {
        var attrs
        if let tempValue = attributes {
            attrs = tempValue
        } else {
            attrs = [:]
        }
        if let width = width {
            attrs[kCTStrokeWidthAttributeName as String] = width
        } else {
            attrs.removeValue(forKey: kCTStrokeWidthAttributeName as String)
        }
        attributes = attrs
    }

    /// 设置描边颜色
    public func setStrokeColor(_ color: UIColor?) {
        var attrs
        if let tempValue = attributes {
            attrs = tempValue
        } else {
            attrs = [:]
        }
        if let color = color {
            attrs[kCTStrokeColorAttributeName as String] = color
        } else {
            attrs.removeValue(forKey: kCTStrokeColorAttributeName as String)
        }
        attributes = attrs
    }

    /// 设置阴影
    public func setShadow(_ shadow: LSTextShadow?) {
        var attrs
        if let tempValue = attributes {
            attrs = tempValue
        } else {
            attrs = [:]
        }
        if let shadow = shadow {
            attrs[LSTextShadowAttributeName] = shadow
        } else {
            attrs.removeValue(forKey: LSTextShadowAttributeName)
        }
        attributes = attrs
    }

    /// 设置内阴影
    public func setInnerShadow(_ shadow: LSTextShadow?) {
        var attrs
        if let tempValue = attributes {
            attrs = tempValue
        } else {
            attrs = [:]
        }
        if let shadow = shadow {
            attrs[LSTextInnerShadowAttributeName] = shadow
        } else {
            attrs.removeValue(forKey: LSTextInnerShadowAttributeName)
        }
        attributes = attrs
    }

    /// 设置下划线
    public func setUnderline(_ underline: LSTextDecoration?) {
        var attrs
        if let tempValue = attributes {
            attrs = tempValue
        } else {
            attrs = [:]
        }
        if let underline = underline {
            attrs[LSTextUnderlineAttributeName] = underline
        } else {
            attrs.removeValue(forKey: LSTextUnderlineAttributeName)
        }
        attributes = attrs
    }

    /// 设置删除线
    public func setStrikethrough(_ strikethrough: LSTextDecoration?) {
        var attrs
        if let tempValue = attributes {
            attrs = tempValue
        } else {
            attrs = [:]
        }
        if let strikethrough = strikethrough {
            attrs[LSTextStrikethroughAttributeName] = strikethrough
        } else {
            attrs.removeValue(forKey: LSTextStrikethroughAttributeName)
        }
        attributes = attrs
    }

    /// 设置背景边框
    public func setBackgroundBorder(_ border: LSTextBorder?) {
        var attrs
        if let tempValue = attributes {
            attrs = tempValue
        } else {
            attrs = [:]
        }
        if let border = border {
            attrs[LSTextBackgroundBorderAttributeName] = border
        } else {
            attrs.removeValue(forKey: LSTextBackgroundBorderAttributeName)
        }
        attributes = attrs
    }

    /// 设置边框
    public func setBorder(_ border: LSTextBorder?) {
        var attrs
        if let tempValue = attributes {
            attrs = tempValue
        } else {
            attrs = [:]
        }
        if let border = border {
            attrs[LSTextBorderAttributeName] = border
        } else {
            attrs.removeValue(forKey: LSTextBorderAttributeName)
        }
        attributes = attrs
    }

    /// 设置附件
    public func setAttachment(_ attachment: LSTextAttachment?) {
        var attrs
        if let tempValue = attributes {
            attrs = tempValue
        } else {
            attrs = [:]
        }
        if let attachment = attachment {
            attrs[LSTextAttachmentAttributeName] = attachment
        } else {
            attrs.removeValue(forKey: LSTextAttachmentAttributeName)
        }
        attributes = attrs
    }

    // MARK: - NSCoding

    required public init?(coder: NSCoder) {
        super.init()
        attributes = coder.decodeObject(forKey: "attributes") as? [String: Any]
        userInfo = coder.decodeObject(forKey: "userInfo") as? [AnyHashable: Any]
        // tapAction 和 longPressAction 需要特殊处理
    }

    public func encode(with coder: NSCoder) {
        coder.encode(attributes, forKey: "attributes")
        coder.encode(userInfo, forKey: "userInfo")
        // tapAction 和 longPressAction 需要特殊处理
    }

    // MARK: - NSCopying

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = LSTextHighlight()
        copy.attributes = attributes
        copy.userInfo = userInfo
        copy.tapAction = tapAction
        copy.longPressAction = longPressAction
        return copy
    }
}
#endif

//
//  UIFont+YYKitSwift.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  UIFont 扩展，提供字体特性检查和加载方法
//

import UIKit
import CoreText

// MARK: - UIFont 扩展

public extension UIFont {

    // MARK: - 字体特性

    /// 是否粗体
    var ls_isBold: Bool {
        return fontDescriptor.symbolicTraits.contains(.traitBold)
    }

    /// 是否斜体
    var ls_isItalic: Bool {
        return fontDescriptor.symbolicTraits.contains(.traitItalic)
    }

    /// 是否等宽字体
    var ls_isMonoSpace: Bool {
        return fontDescriptor.symbolicTraits.contains(.traitMonoSpace)
    }

    /// 是否彩色字形（如 Emoji）
    var ls_isColorGlyphs: Bool {
        return CTFontGetSymbolicTraits(self as CTFont).contains(.traitColorGlyphs)
    }

    /// 字体粗细（-1.0 到 1.0，常规字体为 0.0）
    var ls_fontWeight: CGFloat {
        let traits = fontDescriptor.fontAttributes[.traits] as? [UIFontDescriptor.AttributeName: Any]
        return traits?[.weight] as? CGFloat ?? 0
    }

    // MARK: - 创建变体

    /// 创建粗体字体
    func ls_bold() -> UIFont? {
        var traits = fontDescriptor.symbolicTraits
        traits.insert(.traitBold)

        guard let newDescriptor = fontDescriptor.withSymbolicTraits(traits) else { return nil }
        return UIFont(descriptor: newDescriptor, size: pointSize)
    }

    /// 创建斜体字体
    func ls_italic() -> UIFont? {
        var traits = fontDescriptor.symbolicTraits
        traits.insert(.traitItalic)

        guard let newDescriptor = fontDescriptor.withSymbolicTraits(traits) else { return nil }
        return UIFont(descriptor: newDescriptor, size: pointSize)
    }

    /// 创建粗斜体字体
    func ls_boldItalic() -> UIFont? {
        var traits = fontDescriptor.symbolicTraits
        traits.insert(.traitBold)
        traits.insert(.traitItalic)

        guard let newDescriptor = fontDescriptor.withSymbolicTraits(traits) else { return nil }
        return UIFont(descriptor: newDescriptor, size: pointSize)
    }

    /// 创建常规字体
    func ls_normal() -> UIFont? {
        let baseDescriptor = fontDescriptor.withSymbolicTraits(.traitBold) ?? fontDescriptor
        guard let newDescriptor = baseDescriptor.withSymbolicTraits([]) else { return nil }
        return UIFont(descriptor: newDescriptor, size: pointSize)
    }

    // MARK: - 从 CoreGraphics/CoreText 创建

    /// 从 CTFont 创建 UIFont
    static func ls_ctFont(_ ctFont: CTFont) -> UIFont? {
        return UIFont(ctFont: ctFont)
    }

    /// 从 CGFont 创建 UIFont
    static func ls_cgFont(_ cgFont: CGFont, size: CGFloat) -> UIFont? {
        return UIFont(cgFont: cgFont, size: size)
    }

    // MARK: - 转换为 CoreGraphics/CoreText

    /// 转换为 CTFontRef
    var ls_ctFont: CTFont? {
        return CTFontCreateWithName(fontName as CFString, pointSize, nil)
    }

    /// 转换为 CGFontRef
    var ls_cgFont: CGFont? {
        return CTFontCopyGraphicsFont(ls_ctFont, nil)
    }

    // MARK: - 加载/卸载字体

    /// 从路径加载字体
    /// - Parameter path: 字体文件路径（支持 TTF、OTF）
    /// - Returns: 是否成功
    @discardableResult
    static func ls_loadFont(from path: String) -> Bool {
        guard let fontDataProvider = CGDataProvider(filename: path) else { return false }
        guard let font = CGFont(fontDataProvider) else { return false }

        CTFontManagerRegisterGraphicsFont(font, nil)
        return true
    }

    /// 从路径卸载字体
    static func ls_unloadFont(from path: String) {
        guard let fontDataProvider = CGDataProvider(filename: path) else { return }
        guard let font = CGFont(fontDataProvider) else { return }

        CTFontManagerUnregisterGraphicsFont(font, nil)
    }

    /// 从数据加载字体
    /// - Parameter data: 字体数据（支持 TTF、OTF）
    /// - Returns: UIFont 对象，失败返回 nil
    static func ls_loadFont(from data: Data) -> UIFont? {
        guard let fontDataProvider = CGDataProvider(data: data as CFData) else { return nil }
        guard let cgFont = CGFont(fontDataProvider) else { return nil }

        CTFontManagerRegisterGraphicsFont(cgFont, nil)
        return UIFont(cgFont: cgFont, size: UIFont.systemFontSize)
    }

    /// 卸载通过 loadFont(from:) 加载的字体
    /// - Parameter font: 要卸载的字体
    /// - Returns: 是否成功
    @discardableResult
    static func ls_unloadFont(_ font: UIFont) -> UIFont? {
        guard let cgFont = font.ls_cgFont else { return nil }
        CTFontManagerUnregisterGraphicsFont(cgFont, nil)
        return font
    }

    // MARK: - 序列化字体数据

    /// 将字体序列化为 TTF 数据
    static func ls_data(from font: UIFont) -> Data? {
        guard let cgFont = font.ls_cgFont else { return nil }
        return ls_data(from: cgFont)
    }

    /// 将 CGFont 序列化为 TTF 数据
    static func ls_data(from cgFont: CGFont) -> Data? {
        return cgFont.tableData(for: kCGFontTableCFF)
    }
}

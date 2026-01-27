//
//  LSTextDebugOption.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  文本调试选项 - 用于调试文本布局
//

#if canImport(UIKit)
import UIKit
import CoreText

// MARK: - LSTextDebugOption

/// LSTextDebugOption 用于文本布局调试
///
/// 可以控制各种布局元素的显示，如基线、边界、附件等
public class LSTextDebugOption: NSObject, NSCopying {

    // MARK: - 属性

    /// 是否显示基线
    public var showBaseline: Bool = false

    /// 是否显示字形边界
    public var showGlyphBounds: Bool = false

    /// 是否显示行边界
    public var showLineBounds: Bool = false

    /// 是否显示行片段边界
    public var showLineFragment: Bool = false

    /// 是否显示图像边界
    public var showImageBounds: Bool = false

    /// 是否显示附件边界
    public var showAttachmentBounds: Bool = false

    /// 基线颜色（默认红色）
    public var baselineColor: UIColor = .red

    /// 字形边界颜色（默认蓝色）
    public var glyphBoundsColor: UIColor = .blue

    /// 行边界颜色（默认绿色）
    public var lineBoundsColor: UIColor = .green

    /// 行片段边界颜色（默认黄色）
    public var lineFragmentColor: UIColor = .yellow

    /// 图像边界颜色（默认紫色）
    public var imageBoundsColor: UIColor = .purple

    /// 附件边界颜色（默认橙色）
    public var attachmentBoundsColor: UIColor = .orange

    /// 边框宽度
    public var borderWidth: CGFloat = 1.0

    // MARK: - 初始化

    public override init() {
        super.init()
    }

    // MARK: - NSCopying

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = LSTextDebugOption()
        copy.showBaseline = showBaseline
        copy.showGlyphBounds = showGlyphBounds
        copy.showLineBounds = showLineBounds
        copy.showLineFragment = showLineFragment
        copy.showImageBounds = showImageBounds
        copy.showAttachmentBounds = showAttachmentBounds
        copy.baselineColor = baselineColor
        copy.glyphBoundsColor = glyphBoundsColor
        copy.lineBoundsColor = lineBoundsColor
        copy.lineFragmentColor = lineFragmentColor
        copy.imageBoundsColor = imageBoundsColor
        copy.attachmentBoundsColor = attachmentBoundsColor
        copy.borderWidth = borderWidth
        return copy
    }
}

#endif

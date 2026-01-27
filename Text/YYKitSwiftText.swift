//
//  YYKitSwiftText.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-26.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  YYKitSwift 文本模块 - 富文本和文本属性
//

import UIKit

// MARK: - YYKitSwift 文本模块

/// YYKitSwift 文本模块
///
/// 此模块提供强大的富文本处理功能，包括：
/// - 文本属性设置（字体、颜色、段落等）
/// - 文本布局计算
/// - 文本容器管理
/// - 文本选择和编辑
/// - 文本效果视图
///
/// ## 主要组件
///
/// - `LSLabel`: 富文本标签
/// - `LSTextView`: 富文本文本视图
/// - `LSTextLayout`: 文本布局
/// - `LSTextContainer`: 文本容器
/// - `NSAttributedString+YYKitSwift`: 属性字符串扩展
///
/// ## 使用示例
///
/// ```swift
/// // 使用富文本标签
/// let label = LSLabel()
/// label.text = "Hello World"
/// ```
///
/// ## 依赖关系
///
/// - ✅ **完全独立**: 不依赖任何其他 YYKitSwift 模块
/// - ⚠️ **依赖 Core**: 需要引入 YYKitSwiftCore
///
// MARK: - 模块导出

// 文本核心
@_exported import class YYKitSwift.LSLabel
@_exported import class YYKitSwift.LSTextView

// 文本组件
@_exported import class YYKitSwift.LSTextLayout
@_exported import class YYKitSwift.LSTextContainer
@_exported import class YYKitSwift.LSTextKeyboardManager
@_exported import class YYKitSwift.LSTextEffectWindow
@_exported import class YYKitSwift.LSTextSelectionView
@_exported import class YYKitSwift.LSTextLine
@_exported import class YYKitSwift.LSTextDebugOption
@_exported import class YYKitSwift.LSTextMagnifier

// 文本属性
@_exported import class YYKitSwift.LSTextAttribute

// 字符串扩展
@_exported import class YYKitSwift.NSAttributedString_YYKitSwift
@_exported import class YYKitSwift.LSTextUtilities
@_exported import class YYKitSwift.LSTextArchiver
@_exported import class YYKitSwift.LSTextRunDelegate
@_exported import class YYKitSwift.LSTextRubyAnnotation
@_exported import class YYKitSwift.LSTextParser
@_exported import class YYKitSwift.LSTextInput
@_exported import class YYKitSwift.NSParagraphStyle_YYKitSwift
@_exported import class YYKitSwift.UIPasteboard_YYKitSwift

//
//  LSTextLine.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  文本行 - 包装 CTLineRef 的文本行对象
//

#if canImport(UIKit)
import UIKit
import CoreText

// MARK: - LSTextRunGlyphDrawMode Enum

/// Run 字形绘制模式
public enum LSTextRunGlyphDrawMode: UInt {
    /// 不旋转
    case horizontal = 0
    /// 垂直旋转单个字形
    case verticalRotate = 1
    /// 垂直旋转单个字形并移动到更好的位置（如全角标点）
    case verticalRotateMove = 2
}

// MARK: - LSTextRunGlyphRange

/// CTRun 中的范围，用于垂直排版
public class LSTextRunGlyphRange: NSObject, NSCopying {

    /// Run 中的字形范围
    public var glyphRangeInRun: NSRange = NSRange(location: 0, length: 0)

    /// 绘制模式
    public var drawMode: LSTextRunGlyphDrawMode = .horizontal

    // MARK: - 初始化

    public override init() {
        super.init()
    }

    /// 使用范围和绘制模式创建
    ///
    /// - Parameters:
    ///   - range: 字形范围
    ///   - mode: 绘制模式
    /// - Returns: 新的 LSTextRunGlyphRange 实例
    public static func range(with range: NSRange, drawMode mode: LSTextRunGlyphDrawMode) -> LSTextRunGlyphRange {
        let glyphRange = LSTextRunGlyphRange()
        glyphRange.glyphRangeInRun = range
        glyphRange.drawMode = mode
        return glyphRange
    }

    // MARK: - NSCopying

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = LSTextRunGlyphRange()
        copy.glyphRangeInRun = glyphRangeInRun
        copy.drawMode = drawMode
        return copy
    }
}

// MARK: - LSTextLine

/// 包装 `CTLineRef` 的文本行对象
///
/// 用于 LSTextLayout 中，提供对 CoreText 行的访问和操作。
public class LSTextLine: NSObject {

    // MARK: - 属性

    /// 行索引
    public var index: UInt = 0

    /// 行号
    public var row: UInt = 0

    /// 垂直旋转范围
    public var verticalRotateRange: [[LSTextRunGlyphRange]]?

    // MARK: - 只读属性

    /// CoreText 行
    public private(set) var ctLine: CTLine? {
        didSet {
            _lineInfo = nil
            _attachmentsInfo = nil
        }
    }

    /// 字符串范围
    public private(set) var range: NSRange = NSRange(location: 0, length: 0)

    /// 是否为垂直排版
    public private(set) var isVertical: Bool = false

    /// 边界矩形
    public var bounds: CGRect {
        if let cached = _lineInfo?.bounds {
            return cached
        }
        let calculated = _calculateBounds()
        _lineInfo?.bounds = calculated
        return calculated
    }

    /// 边界尺寸
    public var size: CGSize {
        return bounds.size
    }

    /// 宽度
    public var width: CGFloat {
        return bounds.width
    }

    /// 高度
    public var height: CGFloat {
        return bounds.height
    }

    /// 顶部位置
    public var top: CGFloat {
        return bounds.minY
    }

    /// 底部位置
    public var bottom: CGFloat {
        return bounds.maxY
    }

    /// 左侧位置
    public var left: CGFloat {
        return bounds.minX
    }

    /// 右侧位置
    public var right: CGFloat {
        return bounds.maxX
    }

    /// 基线位置
    public var position: CGPoint = .zero {
        didSet {
            _lineInfo = nil
        }
    }

    /// 行上升部
    public var ascent: CGFloat {
        if let cached = _lineInfo?.ascent {
            return cached
        }
        _calculateLineMetrics()
        return _lineInfo?.ascent ?? 0
    }

    /// 行下降部
    public var descent: CGFloat {
        if let cached = _lineInfo?.descent {
            return cached
        }
        _calculateLineMetrics()
        return _lineInfo?.descent ?? 0
    }

    /// 行间距
    public var leading: CGFloat {
        if let cached = _lineInfo?.leading {
            return cached
        }
        _calculateLineMetrics()
        return _lineInfo?.leading ?? 0
    }

    /// 行宽度
    public var lineWidth: CGFloat {
        if let cached = _lineInfo?.lineWidth {
            return cached
        }
        _calculateLineMetrics()
        return _lineInfo?.lineWidth ?? 0
    }

    /// 尾随空白宽度
    public var trailingWhitespaceWidth: CGFloat {
        if let cached = _lineInfo?.trailingWhitespaceWidth {
            return cached
        }
        _calculateLineMetrics()
        return _lineInfo?.trailingWhitespaceWidth ?? 0
    }

    /// 附件数组
    public var attachments: [LSTextAttachment]? {
        _ensureAttachmentsInfo()
        return _attachmentsInfo?.attachments
    }

    /// 附件范围数组（NSRange 包装为 NSValue）
    public var attachmentRanges: [NSValue]? {
        _ensureAttachmentsInfo()
        return _attachmentsInfo?.attachmentRanges
    }

    /// 附件矩形数组（CGRect 包装为 NSValue）
    public var attachmentRects: [NSValue]? {
        _ensureAttachmentsInfo()
        return _attachmentsInfo?.attachmentRects
    }

    // MARK: - 私有属性

    private var _lineInfo: LineInfo?
    private var _attachmentsInfo: AttachmentsInfo?

    // MARK: - 初始化

    /// 使用 CTLine 创建文本行
    ///
    /// - Parameters:
    ///   - ctLine: CoreText 行对象
    ///   - position: 基线位置
    ///   - isVertical: 是否为垂直排版
    /// - Returns: 新的 LSTextLine 实例
    public static func line(with ctLine: CTLine, position: CGPoint, vertical: Bool) -> LSTextLine? {
        guard ctLine != nil else { return nil }

        let line = LSTextLine()
        line.position = position
        line.isVertical = vertical
        line.ctLine = ctLine
        return line
    }

    public override init() {
        super.init()
    }

    deinit {
        ctLine = nil
    }

    // MARK: - 公共方法

    /// 设置 CTLine
    ///
    /// - Parameter ctLine: CoreText 行对象
    public func set(ctLine: CTLine?) {
        self.ctLine = ctLine
    }

    // MARK: - 私有方法

    private struct LineInfo {
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        var leading: CGFloat = 0
        var lineWidth: CGFloat = 0
        var trailingWhitespaceWidth: CGFloat = 0
        var firstGlyphPosition: CGFloat = 0
        var bounds: CGRect = .zero
    }

    private struct AttachmentsInfo {
        var attachments: [LSTextAttachment] = []
        var attachmentRanges: [NSValue] = []
        var attachmentRects: [NSValue] = []
    }

    private func _calculateLineMetrics() {
        guard _lineInfo == nil else { return }

        var info = LineInfo()

        guard let ctLine = ctLine else {
            _lineInfo = info
            return
        }

        info.lineWidth = CTLineGetTypographicBounds(ctLine, &info.ascent, &info.descent, &info.leading)

        let stringRange = CTLineGetStringRange(ctLine)
        info.ascent = max(0, info.ascent)
        info.descent = max(0, info.descent)
        info.leading = max(0, info.leading)
        range = NSRange(location: stringRange.location, length: stringRange.length)

        // 获取第一个字形位置
        let runs = CTLineGetGlyphRuns(ctLine) as NSArray
        if runs.count > 0, let run = runs.firstObject as! CTRun? {
            var positions = [CGPoint](repeating: .zero, count: 1)
            CTRunGetPositions(run, CFRange(location: 0, length: 1), &positions[0])
            info.firstGlyphPosition = positions[0].x
        } else {
            info.firstGlyphPosition = 0
        }

        info.trailingWhitespaceWidth = CTLineGetTrailingWhitespaceWidth(ctLine)

        _lineInfo = info
    }

    private func _calculateBounds() -> CGRect {
        _calculateLineMetrics()
        guard let info = _lineInfo else { return .zero }

        if isVertical {
            var bounds = CGRect(
                x: position.x - info.descent,
                y: position.y,
                width: info.ascent + info.descent,
                height: info.lineWidth
            )
            bounds.origin.y += info.firstGlyphPosition
            return bounds
        } else {
            var bounds = CGRect(
                x: position.x,
                y: position.y - info.ascent,
                width: info.lineWidth,
                height: info.ascent + info.descent
            )
            bounds.origin.x += info.firstGlyphPosition
            return bounds
        }
    }

    private func _ensureAttachmentsInfo() {
        if _attachmentsInfo != nil { return }

        var info = AttachmentsInfo()

        guard let ctLine = ctLine else {
            _attachmentsInfo = info
            return
        }

        let runs = CTLineGetGlyphRuns(ctLine) as NSArray
        guard runs.count > 0 else {
            _attachmentsInfo = info
            return
        }

        for run in runs {
            guard let ctRun = run as! CTRun? else { continue }
            let glyphCount = CTRunGetGlyphCount(ctRun)
            guard glyphCount > 0 else { continue }

            let attributes = CTRunGetAttributes(ctRun) as! [NSAttributedString.Key: Any]
            if let attachment = attributes[LSTextAttachmentAttributeName] as? LSTextAttachment {
                // 获取 run 位置
                var positions = [CGPoint](repeating: .zero, count: 1)
                CTRunGetPositions(ctRun, CFRange(location: 0, length: 1), &positions[0])
                var runPosition = positions[0]

                // 获取 run 排版信息
                var ascent: CGFloat = 0
                var descent: CGFloat = 0
                var leading: CGFloat = 0
                let runWidth = CTRunGetTypographicBounds(ctRun, CFRange(location: 0, length: 0), &ascent, &descent, &leading)

                var runTypoBounds: CGRect

                if isVertical {
                    // 垂直排版：交换 x 和 y
                    swap(&runPosition.x, &runPosition.y)
                    runPosition.y = position.y + runPosition.y
                    runTypoBounds = CGRect(
                        x: position.x + runPosition.x - descent,
                        y: runPosition.y,
                        width: ascent + descent,
                        height: runWidth
                    )
                } else {
                    runPosition.x += position.x
                    runPosition.y = position.y - runPosition.y
                    runTypoBounds = CGRect(
                        x: runPosition.x,
                        y: runPosition.y - ascent,
                        width: runWidth,
                        height: ascent + descent
                    )
                }

                let runRange = NSRange(location: CTRunGetStringRange(ctRun).location,
                                      length: CTRunGetStringRange(ctRun).length)

                info.attachments.append(attachment)
                info.attachmentRanges.append(NSValue(range: runRange))
                info.attachmentRects.append(NSValue(cgRect: runTypoBounds))
            }
        }

        _attachmentsInfo = info
    }

    // MARK: - NSObject

    public override var description: String {
        var desc = "<LSTextLine: \(Unmanaged.passUnretained(self).toOpaque())> row:\(row) range:\(range.location),\(range.length)"
        desc += " position:\(NSStringFromCGPoint(position))"
        desc += " bounds:\(NSStringFromCGRect(bounds))"
        return desc
    }
}

// MARK: - Utility Functions

private func swap(_ a: inout CGFloat, _ b: inout CGFloat) {
    let temp = a
    a = b
    b = temp
}

#endif

//
//  LSTextLayout.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  文本布局引擎 - 基于 CoreText 的文本布局系统
//

#if canImport(UIKit)
import UIKit
import CoreText

// MARK: - LSTextLayout

/// LSTextLayout 类是一个只读类，用于存储文本布局结果
///
/// 所有属性都是只读的，不应被修改。此类中的大多数方法是线程安全的。
///
/// 示例（使用圆形排除路径布局）：
/// ```
///     ┌──────────────────────────┐  <------ container
///     │ [--------Line0--------]  │  <- Row0
///     │ [--------Line1--------]  │  <- Row1
///     │ [-Line2-]     [-Line3-]  │  <- Row2
///     │ [-Line4]       [Line5-]  │  <- Row3
///     │ [-Line6-]     [-Line7-]  │  <- Row4
///     │ [--------Line8--------]  │  <- Row5
///     │ [--------Line9--------]  │  <- Row6
///     └──────────────────────────┘
/// ```
@MainActor
public class LSTextLayout: NSObject, NSCoding {

    // MARK: - 只读属性

    /// 文本容器
    public private(set) var container: LSTextContainer!

    /// 完整文本
    public private(set) var text: NSAttributedString!

    /// 完整文本中的范围
    public private(set) var range: NSRange = NSRange(location: 0, length: 0)

    /// CTFramesetter
    public private(set) var frameSetter: CTFramesetter!

    /// CTFrame
    public private(set) var frame: CTFrame!

    /// LSTextLine 数组（不包含截断行）
    public private(set) var lines: [LSTextLine] = []

    /// 带截断标记的 LSTextLine，如果没有截断则为 nil
    public private(set) var truncatedLine: LSTextLine?

    /// LSTextAttachment 数组
    public private(set) var attachments: [LSTextAttachment]?

    /// 文本中的范围（NSRange 包装为 NSValue）
    public private(set) var attachmentRanges: [NSValue]?

    /// 容器中的矩形（CGRect 包装为 NSValue）
    public private(set) var attachmentRects: [NSValue]?

    /// 附件内容集合（UIImage/UIView/CALayer）
    public private(set) var attachmentContentsSet: Set<AnyHashable>?

    /// 行数
    public private(set) var rowCount: UInt = 0

    /// 可见文本范围
    public private(set) var visibleRange: NSRange = NSRange(location: 0, length: 0)

    /// 边界矩形（字形）
    public private(set) var textBoundingRect: CGRect = .zero

    /// 边界尺寸（字形和内边距，向上取整到像素）
    public private(set) var textBoundingSize: CGSize = .zero

    /// 包含高亮属性
    public private(set) var containsHighlight: Bool = false

    /// 需要绘制块边框
    public private(set) var needDrawBlockBorder: Bool = false

    /// 需要绘制背景边框
    public private(set) var needDrawBackgroundBorder: Bool = false

    /// 需要绘制阴影
    public private(set) var needDrawShadow: Bool = false

    /// 需要绘制下划线
    public private(set) var needDrawUnderline: Bool = false

    /// 需要绘制文本
    public private(set) var needDrawText: Bool = false

    /// 需要绘制附件
    public private(set) var needDrawAttachment: Bool = false

    /// 需要绘制内阴影
    public private(set) var needDrawInnerShadow: Bool = false

    /// 需要绘制删除线
    public private(set) var needDrawStrikethrough: Bool = false

    /// 需要绘制边框
    public private(set) var needDrawBorder: Bool = false

    // MARK: - 私有属性

    private var lineRowsIndex: UnsafeMutablePointer<UInt>?
    private var lineRowsEdge: UnsafeMutablePointer<RowEdge>?

    private struct RowEdge {
        var head: CGFloat = 0  // 行头部位置
        var foot: CGFloat = 0  // 行尾部位置
    }

    // MARK: - 禁用初始化

    @available(*, unavailable)
    public override init() {
        super.init()
    }

    @available(*, unavailable)
    public static func new() -> Self {
        fatalError()
    }

    // MARK: - 生成文本布局

    /// 使用给定的容器尺寸和文本生成布局
    ///
    /// - Parameters:
    ///   - size: 文本容器尺寸
    ///   - text: 文本（nil 返回 nil）
    /// - Returns: 新的布局，错误时返回 nil
    public static func layout(withContainerSize size: CGSize, text: NSAttributedString?) -> LSTextLayout? {
        let container = LSTextContainer.container(withSize: size)
        return layout(with: container, text: text)
    }

    /// 使用给定的容器和文本生成布局
    ///
    /// - Parameters:
    ///   - container: 文本容器（nil 返回 nil）
    ///   - text: 文本（nil 返回 nil）
    /// - Returns: 新的布局，错误时返回 nil
    public static func layout(with container: LSTextContainer?, text: NSAttributedString?) -> LSTextLayout? {
        guard let text = text else { return nil }
        return layout(with: container, text: text, range: NSRange(location: 0, length: text.length))
    }

    /// 使用给定的容器和文本生成布局
    ///
    /// - Parameters:
    ///   - container: 文本容器（nil 返回 nil）
    ///   - text: 文本（nil 返回 nil）
    ///   - range: 文本范围（超出范围返回 nil）
    /// - Returns: 新的布局，错误时返回 nil
    public static func layout(with container: LSTextContainer?, text: NSAttributedString?, range: NSRange) -> LSTextLayout? {
        guard let text = text, let container = container else { return nil }
        guard range.location + range.length <= text.length else { return nil }

        // 复制容器和文本
        let containerCopy = container.copy() as! LSTextContainer
        let textCopy = text.mutableCopy() as! NSMutableAttributedString

        // 创建布局
        let layout = _createLayout(container: containerCopy, text: textCopy, range: range)
        return layout
    }

    /// 使用给定的容器数组和文本生成多个布局
    ///
    /// - Parameters:
    ///   - containers: LSTextContainer 对象数组
    ///   - text: 文本
    /// - Returns: LSTextLayout 对象数组
    public static func layout(withContainers containers: [LSTextContainer]?, text: NSAttributedString?) -> [LSTextLayout]? {
        guard let text = text else { return nil }
        return layout(withContainers: containers, text: text, range: NSRange(location: 0, length: text.length))
    }

    /// 使用给定的容器数组和文本生成多个布局
    ///
    /// - Parameters:
    ///   - containers: LSTextContainer 对象数组
    ///   - text: 文本
    ///   - range: 文本范围
    /// - Returns: LSTextLayout 对象数组
    public static func layout(withContainers containers: [LSTextContainer]?, text: NSAttributedString?, range: NSRange) -> [LSTextLayout]? {
        guard let containers = containers, let text = text else { return nil }
        guard range.location + range.length <= text.length else { return nil }

        var currentRange = range
        var layouts: [LSTextLayout] = []

        for container in containers {
            guard let layout = layout(with: container, text: text, range: currentRange) else { return nil }

            let length = Int(currentRange.length) - Int(layout.visibleRange.length)
            if length <= 0 {
                currentRange.length = 0
                currentRange.location = text.length
            } else {
                currentRange.length = UInt(length)
                currentRange.location += layout.visibleRange.length
            }

            layouts.append(layout)

            if currentRange.length == 0 {
                break
            }
        }

        return layouts.isEmpty ? nil : layouts
    }

    // MARK: - 私有布局创建方法

    private static func _createLayout(container: LSTextContainer, text: NSMutableAttributedString, range: NSRange) -> LSTextLayout? {
        let layout = LSTextLayout(unavailableInit: true)
        layout.text = text
        layout.container = container
        layout.range = range

        let isVerticalForm = container.isVerticalForm
        let maximumNumberOfRows = container.maximumNumberOfRows

        // 修复 iOS 8.3 的 joined emoji bug
        if #available(iOS 8.3, iOS 9.0) {
            // TODO: 实现 joined emoji 清色修复
        }

        // 设置路径
        var cgPath: CGPath?
        var cgPathBox = CGRect.zero
        var rowMaySeparated = false
        var constraintSizeIsExtended = false
        var constraintRectBeforeExtended = CGRect.zero

        // 检查是否需要扩展尺寸（iOS 10+ bug）
        if #available(iOS 10.0, *) {
            let exclusionPathsIsEmpty: Bool
            if let paths = container.exclusionPaths {
                exclusionPathsIsEmpty = paths.isEmpty
            } else {
                exclusionPathsIsEmpty = true
            }
            if container.path == nil && exclusionPathsIsEmpty {
                constraintSizeIsExtended = true
            }
        }

        let exclusionPathsIsEmpty2: Bool
        if let paths = container.exclusionPaths {
            exclusionPathsIsEmpty2 = paths.isEmpty
        } else {
            exclusionPathsIsEmpty2 = true
        }
        if container.path == nil && exclusionPathsIsEmpty2 {
            // 简单矩形路径
            guard container.size.width > 0 && container.size.height > 0 else { return nil }

            var rect = CGRect(origin: .zero, size: container.size)

            if constraintSizeIsExtended {
                constraintRectBeforeExtended = rect.inset(by: container.insets)
                constraintRectBeforeExtended = constraintRectBeforeExtended.standardized
                if isVerticalForm {
                    rect.size.width = LSTextContainerMaxSize.width
                } else {
                    rect.size.height = LSTextContainerMaxSize.height
                }
            }

            rect = rect.inset(by: container.insets).standardized
            cgPathBox = rect

            var transform = CGAffineTransform(scaleX: 1, y: -1)
            cgPath = CGPath(rect: rect, transform: &transform)

        } else if let containerPath = container.path,
                  CGPathIsRect(containerPath.cgPath, &cgPathBox) {
            let exclusionPathsIsEmpty: Bool
            if let paths = container.exclusionPaths {
                exclusionPathsIsEmpty = paths.isEmpty
            } else {
                exclusionPathsIsEmpty = true
            }
            if exclusionPathsIsEmpty {
            // 矩形路径，无排除路径
            var transform = CGAffineTransform(scaleX: 1, y: -1)
            cgPath = CGPath(rect: cgPathBox, transform: &transform)

        } else {
            // 自定义路径或有排除路径
            rowMaySeparated = true

            var path: CGMutablePath?
            if let containerPath = container.path {
                path = CGPath(__mutableCopy: containerPath.cgPath!)
            } else {
                let rect = CGRect(origin: .zero, size: container.size)
                    .inset(by: container.insets)
                if let rectPath = CGPath(rect: rect, transform: nil) {
                    path = CGPath(__mutableCopy: rectPath)
                }
            }

            if let path = path {
                // 添加排除路径
                if let exclusionPaths = container.exclusionPaths {
                    for exclusionPath in exclusionPaths {
                        path.addPath(exclusionPath.cgPath)
                    }
                }

                cgPathBox = path.boundingBox
                var transform = CGAffineTransform(scaleX: 1, y: -1)
                if let transPath = path.copy(using: &transform) {
                    cgPath = transPath
                }
            }
        }

        guard let finalPath = cgPath else { return nil }

        // 配置帧属性
        var frameAttrs: [CFString: Any] = [:]

        if !container.pathFillEvenOdd {
            frameAttrs[kCTFramePathFillRuleAttributeName] = kCTFramePathFillWindingNumber
        }

        if container.pathLineWidth > 0 {
            frameAttrs[kCTFramePathWidthAttributeName] = container.pathLineWidth
        }

        if isVerticalForm {
            frameAttrs[kCTFrameProgressionAttributeName] = kCTFrameProgressionRightToLeft
        }

        // 创建 CoreText 对象
        guard let ctSetter = CTFramesetterCreateWithAttributedString(text) else { return nil }
        guard let ctFrame = CTFramesetterCreateFrame(ctSetter, range.toCFRange(), finalPath, frameAttrs as CFDictionary) else {
            return nil
        }

        // 获取行
        guard let ctLines = CTFrameGetLines(ctFrame) as? [CTLine] else { return nil }
        let lineCount = ctLines.count

        var lineOrigins: [CGPoint] = Array(repeating: .zero, count: lineCount)
        CTFrameGetLineOrigins(ctFrame, CFRange(location: 0, length: lineCount), &lineOrigins)

        var lines: [LSTextLine] = []
        var textBoundingRect = CGRect.zero
        var rowIdx: Int = -1
        var rowCount: UInt = 0
        var lastRect = CGRect.zero
        var lastPosition = CGPoint.zero

        if isVerticalForm {
            lastRect = CGRect(x: .greatestFiniteMagnitude, y: 0, width: 0, height: 0)
            lastPosition = CGPoint(x: .greatestFiniteMagnitude, y: 0)
        } else {
            lastRect = CGRect(x: 0, y: -.greatestFiniteMagnitude, width: 0, height: 0)
            lastPosition = CGPoint(x: 0, y: -.greatestFiniteMagnitude)
        }

        // 计算行框架
        var lineCurrentIdx: UInt = 0

        for i in 0..<lineCount {
            let ctLine = ctLines[i]
            guard CTLineGetGlyphRuns(ctLine).count > 0 else { continue }

            // CoreText 坐标系
            let ctLineOrigin = lineOrigins[i]

            // UIKit 坐标系
            var position = CGPoint(
                x: cgPathBox.origin.x + ctLineOrigin.x,
                y: cgPathBox.size.height + cgPathBox.origin.y - ctLineOrigin.y
            )

            guard let line = LSTextLine.line(with: ctLine, position: position, vertical: isVerticalForm) else { continue }
            let rect = line.bounds

            // 检查约束尺寸
            if constraintSizeIsExtended {
                if isVerticalForm {
                    if rect.maxX > constraintRectBeforeExtended.maxX {
                        break
                    }
                } else {
                    if rect.maxY > constraintRectBeforeExtended.maxY {
                        break
                    }
                }
            }

            // 检测新行
            var newRow = true
            if rowMaySeparated && position.x != lastPosition.x {
                if isVerticalForm {
                    if rect.width > lastRect.width {
                        if position.x > lastPosition.x && lastPosition.x > position.x - rect.width {
                            newRow = false
                        }
                    } else {
                        if lastRect.minX > position.x && position.x > lastRect.minX - lastRect.width {
                            newRow = false
                        }
                    }
                } else {
                    if rect.height > lastRect.height {
                        if position.y < lastPosition.y && lastPosition.y < position.y + rect.height {
                            newRow = false
                        }
                    } else {
                        if lastRect.minY < position.y && position.y < lastRect.maxY {
                            newRow = false
                        }
                    }
                }
            }

            if newRow {
                rowIdx += 1
            }

            lastRect = rect
            lastPosition = position

            line.index = lineCurrentIdx
            line.row = UInt(rowIdx)
            lines.append(line)
            rowCount = UInt(rowIdx + 1)
            lineCurrentIdx += 1

            if lineCurrentIdx == 1 {
                textBoundingRect = rect
            } else if maximumNumberOfRows == 0 || UInt(rowIdx) < maximumNumberOfRows {
                textBoundingRect = textBoundingRect.union(rect)
            }
        }

        // 处理截断
        var needTruncation = false
        var truncatedLine: LSTextLine?

        if rowCount > 0 {
            if maximumNumberOfRows > 0 && rowCount > maximumNumberOfRows {
                needTruncation = true
                rowCount = maximumNumberOfRows
                while let lastLine = lines.last, lastLine.row >= rowCount {
                    lines.removeLast()
                }
            }

            if let lastLine = lines.last,
               lastLine.range.location + lastLine.range.length < text.length {
                needTruncation = true
            }

            // 应用行位置修饰器
            if let modifier = container.linePositionModifier {
                modifier.modifyLines(lines, fromText: text, inContainer: container)
                textBoundingRect = .zero
                for (index, line) in lines.enumerated() {
                    if index == 0 {
                        textBoundingRect = line.bounds
                    } else {
                        textBoundingRect = textBoundingRect.union(line.bounds)
                    }
                }
            }

            // 计算行边缘
            let lineRowsEdge = UnsafeMutablePointer<RowEdge>.allocate(capacity: Int(rowCount))
            let lineRowsIndex = UnsafeMutablePointer<UInt>.allocate(capacity: Int(rowCount))

            var lastRowIdx: Int = -1
            var lastHead: CGFloat = 0
            var lastFoot: CGFloat = 0

            for (index, line) in lines.enumerated() {
                let rect = line.bounds
                if Int(line.row) != lastRowIdx {
                    if lastRowIdx >= 0 {
                        lineRowsEdge[Int(lastRowIdx)] = RowEdge(head: lastHead, foot: lastFoot)
                    }
                    lastRowIdx = Int(line.row)
                    lineRowsIndex[Int(lastRowIdx)] = UInt(index)

                    if isVerticalForm {
                        lastHead = rect.maxX
                        lastFoot = lastHead - rect.width
                    } else {
                        lastHead = rect.minY
                        lastFoot = lastHead + rect.height
                    }
                } else {
                    if isVerticalForm {
                        lastHead = max(lastHead, rect.maxX)
                        lastFoot = min(lastFoot, rect.minX)
                    } else {
                        lastHead = min(lastHead, rect.minY)
                        lastFoot = max(lastFoot, rect.maxY)
                    }
                }
            }
            lineRowsEdge[Int(lastRowIdx)] = RowEdge(head: lastHead, foot: lastFoot)

            // 平滑行边缘
            for i in 1..<Int(rowCount) {
                let v0 = lineRowsEdge[i - 1]
                let v1 = lineRowsEdge[i]
                let mid = (v0.foot + v1.head) * 0.5
                lineRowsEdge[i - 1].foot = mid
                lineRowsEdge[i].head = mid
            }

            layout.lineRowsEdge = lineRowsEdge
            layout.lineRowsIndex = lineRowsIndex
        }

        // 计算边界尺寸
        var rect = textBoundingRect
        if container.path != nil {
            if container.pathLineWidth > 0 {
                let inset = container.pathLineWidth / 2
                rect = rect.insetBy(dx: -inset, dy: -inset)
            }
        } else {
            rect = rect.inset(by: UIEdgeInsets(top: -container.insets.top,
                                              left: -container.insets.left,
                                              bottom: -container.insets.bottom,
                                              right: -container.insets.right))
        }
        rect = rect.standardized

        var size = rect.size
        if container.isVerticalForm {
            size.width += container.size.width - rect.maxX
        } else {
            size.width += rect.minX
        }
        size.height += rect.minY

        size.width = max(0, ceil(size.width))
        size.height = max(0, ceil(size.height))

        layout.textBoundingSize = size

        // 获取可见范围
        let visibleRange = CTFrameGetVisibleStringRange(ctFrame).toNSRange()
        layout.visibleRange = visibleRange

        // 收集附件和检测属性
        layout._collectAttachmentsAndDetectAttributes(from: text, lines: lines)

        // 创建截断行（如果需要）
        if needTruncation {
            layout.truncatedLine = _createTruncatedLine(for: layout, in: container)
        }

        layout.frameSetter = ctSetter
        layout.frame = ctFrame
        layout.lines = lines
        layout.truncatedLine = truncatedLine
        layout.rowCount = rowCount

        return layout
    }

    // 私有初始化方法
    private init(unavailableInit: Bool) {
        super.init()
    }

    // MARK: - NSCoding

    required public init?(coder: NSCoder) {
        super.init()
        guard let textData = coder.decodeObject(forKey: "text") as? Data,
              let container = coder.decodeObject(forKey: "container") as? LSTextContainer,
              let text = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: textData) else {
            return nil
        }

        if let tempValue = .rangeValue {
            range = tempValue
        } else {
            range = NSRange(location: 0
        }

        // 重新创建布局
        if let layout = LSTextLayout._createLayout(container: container, text: text.mutableCopy() as! NSMutableAttributedString, range: range) {
            self.container = layout.container
            self.text = layout.text
            self.range = layout.range
            self.frameSetter = layout.frameSetter
            self.frame = layout.frame
            self.lines = layout.lines
            self.truncatedLine = layout.truncatedLine
            self.attachments = layout.attachments
            self.attachmentRanges = layout.attachmentRanges
            self.attachmentRects = layout.attachmentRects
            self.attachmentContentsSet = layout.attachmentContentsSet
            self.rowCount = layout.rowCount
            self.visibleRange = layout.visibleRange
            self.textBoundingRect = layout.textBoundingRect
            self.textBoundingSize = layout.textBoundingSize
            self.lineRowsIndex = layout.lineRowsIndex
            self.lineRowsEdge = layout.lineRowsEdge
            self.containsHighlight = layout.containsHighlight
            self.needDrawBlockBorder = layout.needDrawBlockBorder
            self.needDrawBackgroundBorder = layout.needDrawBackgroundBorder
            self.needDrawShadow = layout.needDrawShadow
            self.needDrawUnderline = layout.needDrawUnderline
            self.needDrawText = layout.needDrawText
            self.needDrawAttachment = layout.needDrawAttachment
            self.needDrawInnerShadow = layout.needDrawInnerShadow
            self.needDrawStrikethrough = layout.needDrawStrikethrough
            self.needDrawBorder = layout.needDrawBorder
        } else {
            return nil
        }
    }

    public func encode(with coder: NSCoder) {
        if let textData = try? NSKeyedArchiver.archivedData(withRootObject: text, requiringSecureCoding: false) {
            coder.encode(textData, forKey: "text")
        }
        coder.encode(container, forKey: "container")
        coder.encode(NSValue(range: range), forKey: "range")
    }

    // MARK: - 私有辅助方法

    private func _collectAttachmentsAndDetectAttributes(from text: NSAttributedString, lines: [LSTextLine]) {
        var collectedAttachments: [LSTextAttachment] = []
        var collectedAttachmentRanges: [NSValue] = []
        var collectedAttachmentRects: [NSValue] = []
        var collectedContents: Set<AnyHashable> = []

        // 检测绘制标志
        containsHighlight = false
        needDrawBlockBorder = false
        needDrawBackgroundBorder = false
        needDrawShadow = false
        needDrawUnderline = false
        needDrawText = true
        needDrawAttachment = false
        needDrawInnerShadow = false
        needDrawStrikethrough = false
        needDrawBorder = false

        let textLength = text.length

        // 遍历所有属性范围
        text.enumerateAttributes(in: NSRange(location: 0, length: textLength), options: []) { attrs, range, _ in
            // 检测高亮
            if attrs[LSTextHighlightAttributeName] != nil {
                containsHighlight = true
            }

            // 检测块边框
            if attrs[LSTextBlockBorderAttributeName] != nil {
                needDrawBlockBorder = true
            }

            // 检测背景边框
            if attrs[LSTextBackgroundBorderAttributeName] != nil {
                needDrawBackgroundBorder = true
            }

            // 检测阴影
            if attrs[LSTextShadowAttributeName] != nil {
                needDrawShadow = true
            }

            // 检测内阴影
            if attrs[LSTextInnerShadowAttributeName] != nil {
                needDrawInnerShadow = true
            }

            // 检测下划线
            if attrs[LSTextUnderlineAttributeName] != nil {
                needDrawUnderline = true
            }

            // 检测删除线
            if attrs[LSTextStrikethroughAttributeName] != nil {
                needDrawStrikethrough = true
            }

            // 检测边框
            if attrs[LSTextBorderAttributeName] != nil {
                needDrawBorder = true
            }

            // 检测附件
            if let attachment = attrs[LSTextAttachmentAttributeName] as? LSTextAttachment {
                needDrawAttachment = true
                collectedAttachments.append(attachment)
                collectedAttachmentRanges.append(NSValue(range: range))

                if let content = attachment.content {
                    collectedContents.insert(content)
                }
            }
        }

        // 计算附件矩形
        for (index, attachment) in collectedAttachments.enumerated() {
            guard index < collectedAttachmentRanges.count else { break }

            let range = collectedAttachmentRanges[index].rangeValue

            // 查找包含该范围的行
            for line in lines {
                if let intersection = line.range.intersection(range) {
                    // 计算附件矩形（简化：使用行边界）
                    var rect = line.bounds

                    // 应用附件内边距
                    rect = rect.inset(by: attachment.contentInsets)

                    collectedAttachmentRects.append(NSValue(cgRect: rect))
                    break
                }
            }
        }

        attachments = collectedAttachments.isEmpty ? nil : collectedAttachments
        attachmentRanges = collectedAttachmentRanges.isEmpty ? nil : collectedAttachmentRanges
        attachmentRects = collectedAttachmentRects.isEmpty ? nil : collectedAttachmentRects
        attachmentContentsSet = collectedContents.isEmpty ? nil : collectedContents
    }

    private static func _createTruncatedLine(for layout: LSTextLayout, in container: LSTextContainer) -> LSTextLine? {
        guard container.truncationType != .none else { return nil }
        guard let lastLine = layout.lines.last else { return nil }

        // 如果最后一行包含所有文本，无需截断
        if lastLine.range.location + lastLine.range.length >= layout.text.length {
            return nil
        }

        guard let ctLine = lastLine.ctLine else { return nil }

        // 获取截断标记
        let token: NSAttributedString
        if let customToken = container.truncationToken {
            token = customToken
        } else {
            // 默认使用省略号
            token = NSAttributedString(string: LSTextTruncationToken)
        }

        // 计算可用宽度
        let containerWidth = container.size.width - container.insets.left - container.insets.right

        // 根据截断类型创建截断行
        let truncatedCTLine: CTLine?
        switch container.truncationType {
        case .none:
            truncatedCTLine = nil
        case .start:
            truncatedCTLine = CTLineCreateTruncatedLine(ctLine, containerWidth, .start, token)
        case .end:
            truncatedCTLine = CTLineCreateTruncatedLine(ctLine, containerWidth, .end, token)
        case .middle:
            truncatedCTLine = CTLineCreateTruncatedLine(ctLine, containerWidth, .middle, token)
        }

        guard let newCTLine = truncatedCTLine else { return nil }

        // 创建新的 LSTextLine
        let truncatedLine = LSTextLine.line(
            with: newCTLine,
            position: lastLine.position,
            vertical: container.isVerticalForm
        )

        // 保留原始行的行号信息
        if let textLine = truncatedLine {
            textLine.row = lastLine.row
            textLine.index = lastLine.index
        }

        return textLine
    }

    // MARK: - 内存管理

    deinit {
        if let lineRowsIndex = lineRowsIndex {
            lineRowsIndex.deallocate()
        }
        if let lineRowsEdge = lineRowsEdge {
            lineRowsEdge.deallocate()
        }
    }
}

// MARK: - NSRange Extensions

private extension NSRange {
    func toCFRange() -> CFRange {
        return CFRange(location: self.location, length: self.length)
    }
}

private extension CFRange {
    func toNSRange() -> NSRange {
        return NSRange(location: self.location, length: self.length)
    }
}

#endif

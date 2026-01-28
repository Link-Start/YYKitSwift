//
//  LSLabel.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  富文本标签 - 支持异步渲染、高亮交互、文本附件
//

#if canImport(UIKit)
import UIKit
import CoreText
import QuartzCore

// MARK: - 常量

private let kLongPressMinimumDuration: TimeInterval = 0.5
private let kLongPressAllowableMovement: CGFloat = 9.0
private let kHighlightFadeDuration: TimeInterval = 0.15
private let kAsyncFadeDuration: TimeInterval = 0.08

// MARK: - 类型定义

/// 文本操作回调
///
/// - Parameters:
///   - containerView: 文本容器视图（LSLabel）
///   - text: 完整文本
///   - range: 文本范围
///   - rect: 文本在容器中的框架
public typealias LSTextAction = @Sendable (_ containerView: UIView, _ text: NSAttributedString, _ range: NSRange, _ rect: CGRect) -> Void

// MARK: - LSLabel

/// LSLabel 是一个功能强大的富文本标签，支持异步渲染、高亮交互、文本附件等
///
/// 主要特性：
/// - 支持 CoreText 布局
/// - 支持异步渲染，提高滚动性能
/// - 支持文本高亮和点击交互
/// - 支持图片/视图/图层附件
/// - 支持垂直排版（CJK）
/// - 支持自定义容器路径和排除路径
@MainActor
public class LSLabel: UIView {

    // MARK: - 文本属性

    /// 显示的纯文本
    public var text: String? {
        didSet {
            _updateAttributedTextFromPlainText()
            _setLayoutNeedUpdate()
        }
    }

    /// 富文本内容
    public var attributedText: NSAttributedString? {
        didSet {
            if let attributedText = attributedText {
                _innerText = NSMutableAttributedString(attributedString: attributedText)
            } else {
                _innerText = nil
            }
            _setLayoutNeedUpdate()
        }
    }

    /// 字体（默认 17pt 系统字体）
    public var font: UIFont = UIFont.systemFont(ofSize: 17) {
        didSet { _setLayoutNeedUpdate() }
    }

    /// 文本颜色
    public var textColor: UIColor = .black {
        didSet { _setLayoutNeedUpdate() }
    }

    /// 阴影颜色
    public var shadowColor: UIColor? {
        didSet { _setLayoutNeedUpdate() }
    }

    /// 阴影偏移
    public var shadowOffset: CGSize = .zero {
        didSet { _setLayoutNeedUpdate() }
    }

    /// 阴影模糊半径
    public var shadowBlurRadius: CGFloat = 0 {
        didSet { _setLayoutNeedUpdate() }
    }

    /// 对齐方式
    public var textAlignment: NSTextAlignment = .natural {
        didSet { _setLayoutNeedUpdate() }
    }

    /// 垂直对齐
    public var textVerticalAlignment: LSTextVerticalAlignment = .center {
        didSet { _setLayoutNeedUpdate() }
    }

    /// 换行截断模式
    public var lineBreakMode: NSLineBreakMode = .byTruncatingTail {
        didSet { _setLayoutNeedUpdate() }
    }

    /// 最大行数（0 表示无限制）
    public var numberOfLines: UInt = 0 {
        didSet { _setLayoutNeedUpdate() }
    }

    /// 截断标记
    public var truncationToken: NSAttributedString? {
        didSet { _setLayoutNeedUpdate() }
    }

    // MARK: - 容器配置

    /// 文本容器路径
    public var textContainerPath: UIBezierPath? {
        didSet { _setLayoutNeedUpdate() }
    }

    /// 排除路径数组
    public var exclusionPaths: [UIBezierPath]? {
        didSet { _setLayoutNeedUpdate() }
    }

    /// 容器内边距
    public var textContainerInset: UIEdgeInsets = .zero {
        didSet { _setLayoutNeedUpdate() }
    }

    /// 是否垂直排版
    public var verticalForm: Bool = false {
        didSet { _setLayoutNeedUpdate() }
    }

    /// 行位置修饰器
    public var linePositionModifier: LSTextLinePositionModifier? {
        didSet { _setLayoutNeedUpdate() }
    }

    // MARK: - 交互属性

    /// 点击文本时的回调
    public var textTapAction: LSTextAction?

    /// 长按文本时的回调
    public var textLongPressAction: LSTextAction?

    /// 点击高亮区域时的回调
    public var highlightTapAction: LSTextAction?

    /// 长按高亮区域时的回调
    public var highlightLongPressAction: LSTextAction?

    // MARK: - 显示模式

    /// 是否异步渲染（默认 NO）
    public var displaysAsynchronously: Bool = false {
        didSet { _setLayoutNeedUpdate() }
    }

    /// 异步渲染前是否清空内容（默认 YES）
    public var clearContentsBeforeAsynchronouslyDisplay: Bool = true

    /// 异步渲染是否淡入（默认 YES）
    public var fadeOnAsynchronouslyDisplay: Bool = true

    /// 高亮时是否淡入淡出（默认 YES）
    public var fadeOnHighlight: Bool = true

    /// 忽略公共属性，仅使用 textLayout（默认 NO）
    public var ignoreCommonProperties: Bool = false {
        didSet { _setLayoutNeedUpdate() }
    }

    // MARK: - 只读属性

    /// 内部布局对象（只读）
    public private(set) var innerLayout: LSTextLayout?

    /// 当前文本布局
    public var textLayout: LSTextLayout? {
        return _innerLayout
    }

    /// 当前文本范围
    public var textRange: NSRange {
        if let tempValue = NSRange(location: 0, length: _innerText?.length {
            return tempValue
        }
        return 0)
    }

    // MARK: - 私有属性

    private var _innerText: NSMutableAttributedString?
    private var _innerLayout: LSTextLayout?

    private var _highlightRange: NSRange = NSRange(location: NSNotFound, length: 0)
    private var _highlight: LSTextHighlight?
    private var _highlightLayout: LSTextLayout?

    private var _layoutNeedUpdate: Bool = true

    // 状态标志
    private struct State {
        var showingHighlight: Bool = false
        var trackingTouch: Bool = false
        var swallowTouch: Bool = false
        var touchMoved: Bool = false
        var hasTapAction: Bool = false
        var hasLongPressAction: Bool = false
        var contentsNeedFade: Bool = false
    }

    private var _state = State()

    // 触摸相关
    private var _longPressTimer: Timer?
    private var _touchPoint: CGPoint = .zero

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        _commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _commonInit()
    }

    private func _commonInit() {
        backgroundColor = .clear
        userInteractionEnabled = false
        layer.masksToBounds = false

        #if !os(tvOS)
        layer.displayIfNeeded()
        #endif
    }

    // MARK: - 布局更新

    private func _setLayoutNeedUpdate() {
        _layoutNeedUpdate = true
        _updateIfNeeded()
        setNeedsDisplay()
    }

    private func _updateIfNeeded() {
        if !_layoutNeedUpdate { return }
        _layoutNeedUpdate = false
        _updateLayout()
    }

    private func _updateLayout() {
        // 创建文本容器
        let container = _createTextContainer()

        // 创建或更新内部文本
        if !ignoreCommonProperties {
            _updateInnerText()
        }

        // 生成布局
        if let text = _innerText {
            _innerLayout = LSTextLayout.layout(with: container, text: text)
        } else {
            _innerLayout = nil
        }

        // 移除高亮
        _highlightLayout = nil
        _state.showingHighlight = false
    }

    private func _createTextContainer() -> LSTextContainer {
        let container: LSTextContainer

        if let path = textContainerPath {
            container = LSTextContainer.container(withPath: path)
        } else {
            container = LSTextContainer.container(withSize: bounds.size, insets: textContainerInset)
        }

        container.exclusionPaths = exclusionPaths
        container.isVerticalForm = verticalForm
        container.maximumNumberOfRows = numberOfLines
        container.truncationToken = truncationToken
        container.linePositionModifier = linePositionModifier

        return container
    }

    private func _updateInnerText() {
        guard let originalText = _innerText else { return }

        let text = NSMutableAttributedString(attributedString: originalText)
        let range = NSRange(location: 0, length: text.length)

        // 应用字体
        text.addAttribute(.font, value: font, range: range)

        // 应用颜色
        text.addAttribute(.foregroundColor, value: textColor, range: range)

        // 应用阴影
        if let shadowColor = shadowColor {
            let shadow = LSTextShadow(color: shadowColor, offset: shadowOffset, radius: shadowBlurRadius)
            text.addAttribute(LSTextShadowAttributeName, value: shadow, range: range)
        }

        // 应用段落样式
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = textAlignment
        paragraphStyle.lineBreakMode = lineBreakMode

        text.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)

        _innerText = text
    }

    private func _updateAttributedTextFromPlainText() {
        guard let plainText = text else {
            attributedText = nil
            return
        }

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]

        attributedText = NSAttributedString(string: plainText, attributes: attrs)
    }

    // MARK: - 触摸事件处理

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        _updateIfNeeded()

        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        _touchPoint = point

        // 获取高亮信息
        var highlightRange: NSRange?
        _highlight = _getHighlight(at: point, range: &highlightRange)
        if let tempValue = highlightRange {
            _highlightRange = tempValue
        } else {
            _highlightRange = NSRange(location: NSNotFound
        }

        // 设置交互状态
        _state.trackingTouch = true
        _state.touchMoved = false
        _state.swallowTouch = false
        _state.hasTapAction = (textTapAction != nil)
        _state.hasLongPressAction = (textLongPressAction != nil)

        // 启动长按定时器
        _longPressTimer = Timer.scheduledTimer(withTimeInterval: kLongPressMinimumDuration, repeats: false) { [weak self] _ in
            self?._trackDidLongPress()
        }

        // 显示高亮
        if _highlight != nil {
            _showHighlight(animated: true)
        }

        userInteractionEnabled = true
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)

        // 检查移动距离
        let dx = abs(point.x - _touchPoint.x)
        let dy = abs(point.y - _touchPoint.y)

        if dx > kLongPressAllowableMovement || dy > kLongPressAllowableMovement {
            _longPressTimer?.invalidate()
            _longPressTimer = nil
            _state.touchMoved = true
        }

        // 动态显示/隐藏高亮
        if _highlight != nil && _state.touchMoved {
            var highlightRange: NSRange?
            let highlight = _getHighlight(at: point, range: &highlightRange)

            if highlight != nil && highlight !== _highlight {
                _highlight = highlight
                if let tempValue = highlightRange {
                    _highlightRange = tempValue
                } else {
                    _highlightRange = NSRange(location: NSNotFound
                }
                _showHighlight(animated: true)
            } else if highlight == nil {
                _hideHighlight()
            }
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        _longPressTimer?.invalidate()
        _longPressTimer = nil

        defer {
            _state.trackingTouch = false
            userInteractionEnabled = false
        }

        // 处理点击事件
        if !_state.touchMoved {
            if _highlight == nil && _state.hasTapAction {
                _invokeTapAction(at: _touchPoint)
            } else if _highlight != nil {
                if _state.hasTapAction {
                    _invokeTapAction(at: _touchPoint)
                }
                if let tapAction = _highlight?.tapAction {
                    _invokeHighlightAction(tapAction, at: _touchPoint)
                }
            }
        }

        // 移除高亮
        _hideHighlight()
    }

    public override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
        _longPressTimer?.invalidate()
        _longPressTimer = nil
        _state.trackingTouch = false
        _hideHighlight()
        userInteractionEnabled = false
    }

    // MARK: - 高亮检测

    private func _getHighlight(at point: CGPoint, range: NSRangePointer?) -> LSTextHighlight? {
        guard let layout = _innerLayout else { return nil }

        let layoutPoint = _convertPoint(toLayout: point)
        guard let textRange = layout.textRangeAtPoint(layoutPoint) else { return nil }

        let startIndex = textRange.start

        // 查找最长有效范围的高亮属性
        var highlightRange = NSRange(location: NSNotFound, length: 0)
        let highlight = _innerText?.attribute(LSTextHighlightAttributeName, at: startIndex, longestEffectiveRange: &highlightRange, in: NSRange(location: 0, length: _innerText!.length)) as? LSTextHighlight

        range?.pointee = highlightRange
        return highlight
    }

    private func _convertPoint(toLayout point: CGPoint) -> CGPoint {
        guard let layout = _innerLayout else { return point }

        var result = point
        result.x -= layout.textBoundingRect.minX
        result.y -= layout.textBoundingRect.minY

        return result
    }

    // MARK: - 高亮显示/隐藏

    private func _showHighlight(animated: Bool) {
        guard let layout = _innerLayout, let highlight = _highlight else { return }

        // 创建高亮文本
        let text = NSMutableAttributedString(attributedString: _innerText!)
        let range = NSRange(location: _highlightRange.location, length: _highlightRange.length)

        // 应用高亮属性
        if let attributes = highlight.attributes {
            for (key, value) in attributes {
                if let nsNull = value as? NSNull {
                    text.removeAttribute(key, range: range)
                } else {
                    text.addAttribute(key, value: value, range: range)
                }
            }
        }

        // 创建高亮布局
        _highlightLayout = LSTextLayout.layout(with: layout.container.copy() as? LSTextContainer, text: text, range: range)

        _state.showingHighlight = true

        if animated && fadeOnHighlight {
            _state.contentsNeedFade = true
        }

        setNeedsDisplay()
    }

    private func _hideHighlight() {
        _highlightLayout = nil
        _state.showingHighlight = false

        if fadeOnHighlight {
            _state.contentsNeedFade = true
        }

        setNeedsDisplay()
    }

    // MARK: - 操作回调

    private func _trackDidLongPress() {
        if _highlight != nil {
            if let longPressAction = _highlight?.longPressAction {
                _invokeHighlightAction(longPressAction, at: _touchPoint)
            }
        } else if _state.hasLongPressAction {
            _invokeLongPressAction(at: _touchPoint)
        }

        _state.swallowTouch = true
    }

    private func _invokeTapAction(at point: CGPoint) {
        guard let layout = _innerLayout, let text = _innerText else { return }

        let rect = bounds
        textTapAction?(self, text, textRange, rect)
    }

    private func _invokeLongPressAction(at point: CGPoint) {
        guard let layout = _innerLayout, let text = _innerText else { return }

        let rect = bounds
        textLongPressAction?(self, text, textRange, rect)
    }

    private func _invokeHighlightAction(_ action: LSTextAction, at point: CGPoint) {
        guard let text = _innerText else { return }

        let rect = bounds
        action(self, text, _highlightRange, rect)
    }

    // MARK: - 绘制方法

    private func _drawLayout(_ layout: LSTextLayout, in context: CGContext, size: CGSize, isCancelled: @escaping () -> Bool) {
        // 保存图形状态
        context.saveGState()

        // 计算绘制原点
        var point = CGPoint.zero
        if let innerLayout = _innerLayout {
            switch textVerticalAlignment {
            case .top:
                point = CGPoint(x: innerLayout.textBoundingRect.minX, y: innerLayout.textBoundingRect.minY)
            case .center:
                point = CGPoint(x: innerLayout.textBoundingRect.minX, y: (bounds.height - innerLayout.textBoundingSize.height) / 2)
            case .bottom:
                point = CGPoint(x: innerLayout.textBoundingRect.minX, y: bounds.height - innerLayout.textBoundingSize.height - innerLayout.textBoundingRect.minY)
            }
        }

        // 裁剪到容器区域
        let clipRect = bounds.inset(by: textContainerInset)
        context.clip(to: [clipRect])

        // 翻转坐标系（CoreText 使用左下角为原点）
        context.textPosition = point
        context.translateBy(x: 0, y: bounds.height)
        context.scaleBy(x: 1.0, y: -1.0)

        // 1. 绘制背景边框（在最底层）
        if layout.needDrawBackgroundBorder || layout.needDrawBlockBorder {
            _drawBackgroundBorders(layout: layout, in: context, isCancelled: isCancelled)
        }

        // 2. 绘制阴影
        if layout.needDrawShadow {
            _drawShadows(layout: layout, in: context, isCancelled: isCancelled)
        }

        // 3. 绘制文本
        if layout.needDrawText {
            if let ctFrame = layout.frame {
                CTFrameDraw(ctFrame, context)
            }
        }

        // 4. 绘制装饰线（删除线）
        if layout.needDrawStrikethrough {
            _drawStrikethroughs(layout: layout, in: context, isCancelled: isCancelled)
        }

        // 5. 绘制下划线
        if layout.needDrawUnderline {
            _drawUnderlines(layout: layout, in: context, isCancelled: isCancelled)
        }

        // 6. 绘制边框（在最上层）
        if layout.needDrawBorder {
            _drawBorders(layout: layout, in: context, isCancelled: isCancelled)
        }

        // 7. 绘制内阴影
        if layout.needDrawInnerShadow {
            _drawInnerShadows(layout: layout, in: context, isCancelled: isCancelled)
        }

        // 恢复图形状态
        context.restoreGState()
    }

    private func _drawBackgroundBorders(layout: LSTextLayout, in context: CGContext, isCancelled: @escaping () -> Bool) {
        guard let text = _innerText else { return }

        let range = NSRange(location: 0, length: text.length)
        text.enumerateAttribute(LSTextBackgroundBorderAttributeName, in: range, options: []) { value, range, _ in
            if isCancelled() { return }
            guard let border = value as? LSTextBorder else { return }

            // 获取文本范围的所有行
            for line in layout.lines {
                // 检查行范围是否与属性范围重叠
                if let lineRange = line.range.intersection(range) {
                    // 计算实际绘制的矩形
                    let rect = _rectForRange(lineRange, in: line)
                    _drawBorder(border, in: rect, context: context)
                }
            }
        }

        // 绘制块边框
        text.enumerateAttribute(LSTextBlockBorderAttributeName, in: range, options: []) { value, range, _ in
            if isCancelled() { return }
            guard let border = value as? LSTextBorder else { return }

            // 获取文本范围的所有行
            for line in layout.lines {
                if let lineRange = line.range.intersection(range) {
                    let rect = _rectForRange(lineRange, in: line)
                    _drawBorder(border, in: rect, context: context)
                }
            }
        }
    }

    private func _drawShadows(layout: LSTextLayout, in context: CGContext, isCancelled: @escaping () -> Bool) {
        guard let text = _innerText else { return }

        let range = NSRange(location: 0, length: text.length)
        text.enumerateAttribute(LSTextShadowAttributeName, in: range, options: []) { value, range, _ in
            if isCancelled() { return }
            guard let shadow = value as? LSTextShadow else { return }

            // 绘制阴影文本
            _drawShadow(shadow, for: range, in: layout, context: context)

            // 处理子阴影
            var currentShadow = shadow.subShadow
            while let subShadow = currentShadow {
                _drawShadow(subShadow, for: range, in: layout, context: context)
                currentShadow = subShadow.subShadow
            }
        }
    }

    private func _drawShadow(_ shadow: LSTextShadow, for range: NSRange, in layout: LSTextLayout, context: CGContext) {
        guard let color = shadow.color else { return }

        context.saveGState()

        // 设置阴影
        context.setShadow(offset: shadow.offset, blur: shadow.radius, color: color.cgColor)
        context.setBlendMode(shadow.blendMode)

        // 绘制带阴影的文本
        if let ctFrame = layout.frame {
            CTFrameDraw(ctFrame, context)
        }

        context.restoreGState()
    }

    private func _drawUnderlines(layout: LSTextLayout, in context: CGContext, isCancelled: @escaping () -> Bool) {
        guard let text = _innerText else { return }

        let range = NSRange(location: 0, length: text.length)
        text.enumerateAttribute(LSTextUnderlineAttributeName, in: range, options: []) { value, range, _ in
            if isCancelled() { return }
            guard let decoration = value as? LSTextDecoration else { return }

            _drawDecoration(decoration, for: range, in: layout, context: context)
        }
    }

    private func _drawStrikethroughs(layout: LSTextLayout, in context: CGContext, isCancelled: @escaping () -> Bool) {
        guard let text = _innerText else { return }

        let range = NSRange(location: 0, length: text.length)
        text.enumerateAttribute(LSTextStrikethroughAttributeName, in: range, options: []) { value, range, _ in
            if isCancelled() { return }
            guard let decoration = value as? LSTextDecoration else { return }

            _drawDecoration(decoration, for: range, in: layout, context: context)
        }
    }

    private func _drawDecoration(_ decoration: LSTextDecoration, for range: NSRange, in layout: LSTextLayout, context: CGContext) {
        let lineWidth
        if let tempLinewidth = decoration.width?.CGFloatValue {
            lineWidth = tempLinewidth
        } else {
            lineWidth = 1.0
        }
        let color
        if let tempColor = decoration.color {
            color = tempColor
        } else {
            color = .black
        }

        context.saveGState()
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(lineWidth)

        // 获取线条样式
        var lineDashPhase: CGFloat = 0
        var lineDashPattern: [CGFloat]?

        switch decoration.style {
        case .solid:
            lineDashPattern = nil
        case .dot:
            lineDashPattern = [1.0, 1.0]
        case .dash:
            lineDashPattern = [4.0, 2.0]
        case .dashDot:
            lineDashPattern = [4.0, 2.0, 1.0, 2.0]
        case .dashDotDot:
            lineDashPattern = [4.0, 2.0, 1.0, 2.0, 1.0, 2.0]
        default:
            lineDashPattern = nil
        }

        if let pattern = lineDashPattern {
            context.setLineDash(phase: lineDashPhase, lengths: pattern)
        }

        // 绘制线条到每行
        for line in layout.lines {
            if let lineRange = line.range.intersection(range) {
                let rect = _rectForRange(lineRange, in: line)
                let y = rect.midY

                context.move(to: CGPoint(x: rect.minX, y: y))
                context.addLine(to: CGPoint(x: rect.maxX, y: y))
                context.strokePath()
            }
        }

        context.restoreGState()
    }

    private func _drawBorders(layout: LSTextLayout, in context: CGContext, isCancelled: @escaping () -> Bool) {
        guard let text = _innerText else { return }

        let range = NSRange(location: 0, length: text.length)
        text.enumerateAttribute(LSTextBorderAttributeName, in: range, options: []) { value, range, _ in
            if isCancelled() { return }
            guard let border = value as? LSTextBorder else { return }

            for line in layout.lines {
                if let lineRange = line.range.intersection(range) {
                    let rect = _rectForRange(lineRange, in: line)
                    _drawBorder(border, in: rect, context: context)
                }
            }
        }
    }

    private func _drawBorder(_ border: LSTextBorder, in rect: CGRect, context: CGContext) {
        context.saveGState()

        let drawRect = rect.inset(by: border.insets)

        // 绘制填充
        if let fillColor = border.fillColor {
            context.setFillColor(fillColor.cgColor)
            context.fill(drawRect)
        }

        // 绘制边框
        if border.strokeWidth > 0 {
            let _tempVar0
            if let t = .cgColor {
                _tempVar0 = t
            } else {
                _tempVar0 = UIColor.black.cgColor
            }
            context.setStrokeColor(border.strokeColor?_tempVar0)
            context.setLineWidth(border.strokeWidth)
            context.setLineJoin(border.lineJoin)

            let path = UIBezierPath(roundedRect: drawRect, cornerRadius: border.cornerRadius)
            context.addPath(path.cgPath)
            context.strokePath()
        }

        // 绘制阴影
        if let shadow = border.shadow {
            let _tempVar0
            if let t = .cgColor {
                _tempVar0 = t
            } else {
                _tempVar0 = UIColor.black.cgColor
            }
            context.setShadow(offset: shadow.offset, blur: shadow.radius, color: shadow.color?_tempVar0)
        }

        context.restoreGState()
    }

    private func _drawInnerShadows(layout: LSTextLayout, in context: CGContext, isCancelled: @escaping () -> Bool) {
        // 内阴影实现较复杂，暂时跳过
        // 可以使用 clipping 和阴影混合模式实现
    }

    private func _rectForRange(_ range: NSRange, in line: LSTextLine) -> CGRect {
        // 简化实现：返回行的边界
        // 实际应该计算精确的范围矩形
        return line.bounds
    }

    // MARK: - 附件视图管理

    private func _removeOldAttachmentViews() {
        // 移除所有附件视图
        subviews.forEach { view in
            if view is LSTextAttachmentView {
                view.removeFromSuperview()
            }
        }
    }

    private func _addAttachmentViews() {
        let layout
        if let tempLayout = _innerLayout {
            layout = tempLayout
        } else {
            layout = _highlightLayout else { return }
        }
        guard let attachments = layout.attachments, let attachmentRects = layout.attachmentRects else { return }

        for (index, attachment) in attachments.enumerated() {
            guard index < attachmentRects.count else { break }

            let rectValue = attachmentRects[index]
            let rect = rectValue.cgRectValue

            // 创建附件视图
            let attachmentView = _createAttachmentView(for: attachment, in: rect)
            addSubview(attachmentView)
        }
    }

    private func _createAttachmentView(for attachment: LSTextAttachment, in rect: CGRect) -> UIView {
        let view = LSTextAttachmentView(frame: rect)
        view.attachment = attachment

        if let image = attachment.content as? UIImage {
            let imageView = UIImageView(image: image)
            imageView.contentMode = attachment.contentMode
            view.addSubview(imageView)
        } else if let contentView = attachment.content as? UIView {
            view.addSubview(contentView)
        } else if let layer = attachment.content as? CALayer {
            view.layer.addSublayer(layer)
        }

        return view
    }

    // MARK: - CALayer

    public override class var layerClass: AnyClass {
        return LSAsyncLayer.self
    }
}

// MARK: - LSAsyncLayerDelegate

extension LSLabel: LSAsyncLayerDelegate {
    public func newAsyncDisplayTask() -> LSAsyncLayerDisplayTask {
        let task = LSAsyncLayerDisplayTask()

        // willDisplay - 主线程
        task.willDisplay = { [weak self] layer in
            guard let self = self else { return }
            // 移除旧的 contents 动画
            layer.removeAnimation(forKey: "contents")

            // 移除旧的附件视图
            self._removeOldAttachmentViews()
        }

        // display - 后台线程
        task.display = { [weak self] context, size, isCancelled in
            guard let self = self else { return }

            if isCancelled() { return }

            // 更新布局
            self._updateIfNeeded()

            let layout
            if let tempLayout = self._innerLayout {
                layout = tempLayout
            } else {
                layout = self._highlightLayout else { return }
            }

            // 绘制布局
            self._drawLayout(layout, in: context, size: size, isCancelled: isCancelled)
        }

        // didDisplay - 主线程
        task.didDisplay = { [weak self] layer, finished in
            guard let self = self else { return }

            if !finished { return }

            // 添加附件视图/图层
            self._addAttachmentViews()

            // 淡入动画
            if self.displaysAsynchronously && self.fadeOnAsynchronouslyDisplay && self._state.contentsNeedFade {
                let transition = CATransition()
                transition.duration = kAsyncFadeDuration
                transition.type = CATransitionType.fade
                transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                layer.add(transition, forKey: "contents")
                self._state.contentsNeedFade = false
            }
        }

        return task
    }
}

// MARK: - LSTextAttachmentView

/// 附件视图
///
/// 用于显示文本附件内容的视图
public class LSTextAttachmentView: UIView {

    /// 附件内容
    public var attachment: LSTextAttachment? {
        didSet {
            _updateContent()
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        _commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _commonInit()
    }

    private func _commonInit() {
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    private func _updateContent() {
        // 移除旧的子视图
        subviews.forEach { $0.removeFromSuperview() }

        guard let attachment = attachment else { return }

        if let image = attachment.content as? UIImage {
            let imageView = UIImageView(frame: bounds.inset(by: attachment.contentInsets))
            imageView.image = image
            imageView.contentMode = attachment.contentMode
            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(imageView)
        } else if let contentView = attachment.content as? UIView {
            contentView.frame = bounds.inset(by: attachment.contentInsets)
            contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(contentView)
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        _updateContent()
    }
}

#endif

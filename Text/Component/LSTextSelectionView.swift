//
//  LSTextSelectionView.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  文本选择视图 - 显示文本选择状态和高亮
//

#if canImport(UIKit)
import UIKit
import CoreText

// MARK: - LSTextSelectionView

/// 文本选择视图，用于显示文本选择状态
///
/// 在 LSLabel 或 LSTextView 中显示文本选择高亮
@MainActor
public class LSTextSelectionView: UIView {

    // MARK: - 属性

    /// 选择范围数组（NSRange 包装为 NSValue）
    public var selectionRanges: [NSValue]? {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 选择颜色
    public var selectionColor: UIColor = UIColor(white: 0.9, alpha: 1) {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 光标颜色
    public var caretColor: UIColor = UIColor(white: 0.2, alpha: 1) {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 光标位置（nil 表示无光标）
    public var caretPosition: CGPoint? {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 是否显示光标
    public var showsCaret: Bool = true {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 光标宽度
    public var caretWidth: CGFloat = 2 {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 光标圆角
    public var caretCornerRadius: CGFloat = 1 {
        didSet {
            setNeedsDisplay()
        }
    }

    // MARK: - 私有属性

    private var _caretBlinkTimer: Timer?
    private var _isCaretVisible: Bool = true

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
        isUserInteractionEnabled = false

        _startCaretBlink()
    }

    // MARK: - 绘制

    public override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        // 绘制选择高亮
        _drawSelectionHighlight(in: context, rect: rect)

        // 绘制光标
        if showsCaret {
            _drawCaret(in: context, rect: rect)
        }
    }

    private func _drawSelectionHighlight(in context: CGContext, rect: CGRect) {
        guard let selectionRanges = selectionRanges else { return }

        context.setFillColor(selectionColor.cgColor)

        for value in selectionRanges {
            let selectionRect = value.cgRectValue
            context.fill(selectionRect)
        }
    }

    private func _drawCaret(in context: CGContext, rect: CGRect) {
        guard _isCaretVisible, let position = caretPosition else { return }

        context.setFillColor(caretColor.cgColor)

        let caretRect = CGRect(
            x: position.x - caretWidth / 2,
            y: position.y,
            width: caretWidth,
            height: 20 // 默认光标高度
        )

        let path = UIBezierPath(roundedRect: caretRect, cornerRadius: caretCornerRadius)
        context.addPath(path.cgPath)
        context.fillPath()
    }

    // MARK: - 光标闪烁

    private func _startCaretBlink() {
        _stopCaretBlink()

        _caretBlinkTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?._toggleCaret()
        }
    }

    private func _stopCaretBlink() {
        _caretBlinkTimer?.invalidate()
        _caretBlinkTimer = nil
    }

    private func _toggleCaret() {
        _isCaretVisible.toggle()
        setNeedsDisplay()
    }

    // MARK: - 公共方法

    /// 设置选择范围
    ///
    /// - Parameters:
    ///   - ranges: 选择范围数组
    ///   - animated: 是否动画
    public func setSelectionRanges(_ ranges: [NSValue]?, animated: Bool = true) {
        selectionRanges = ranges
    }

    /// 设置光标位置
    ///
    /// - Parameters:
    ///   - position: 光标位置
    ///   - animated: 是否动画
    public func setCaretPosition(_ position: CGPoint?, animated: Bool = true) {
        caretPosition = position
        _isCaretVisible = true
        _resetCaretBlink()
    }

    /// 重置光标闪烁
    private func _resetCaretBlink() {
        _isCaretVisible = true
        _startCaretBlink()
    }

    /// 隐藏光标
    public func hideCaret() {
        _isCaretVisible = false
        setNeedsDisplay()
    }

    /// 显示光标
    public func showCaret() {
        _isCaretVisible = true
        _resetCaretBlink()
    }

    // MARK: - 析构

    deinit {
        _stopCaretBlink()
    }
}

// MARK: - LSTextSelectionHighlight

/// 文本选择高亮视图
///
/// 用于在 LSLabel 中显示高亮选择状态
@MainActor
public class LSTextSelectionHighlight: UIView {

    // MARK: - 属性

    /// 高亮颜色
    public var highlightColor: UIColor = UIColor(white: 0.9, alpha: 1) {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 边框颜色
    public var borderColor: UIColor = UIColor(white: 0.7, alpha: 1) {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 边框宽度
    public var borderWidth: CGFloat = 1 {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 圆角半径
    public var cornerRadius: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
    }

    // MARK: - 绘制

    public override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        // 填充高亮背景
        context.setFillColor(highlightColor.cgColor)
        context.fill(bounds)

        // 绘制边框
        if borderWidth > 0 {
            context.setStrokeColor(borderColor.cgColor)
            context.setLineWidth(borderWidth)

            let borderRect = bounds.insetBy(dx: borderWidth / 2, dy: borderWidth / 2)
            let path = UIBezierPath(roundedRect: borderRect, cornerRadius: cornerRadius)
            context.addPath(path.cgPath)
            context.strokePath()
        }
    }
}

// MARK: - LSTextCaretView

/// 光标视图
///
/// 独立的光标视图，可以添加到任何视图
@MainActor
public class LSTextCaretView: UIView {

    // MARK: - 属性

    /// 光标颜色
    public var caretColor: UIColor = UIColor(white: 0.2, alpha: 1) {
        didSet {
            backgroundColor = caretColor
        }
    }

    /// 光标宽度
    public var caretWidth: CGFloat {
        get { return bounds.width }
        set {
            frame.size.width = newValue
        }
    }

    /// 是否闪烁
    public var isBlinking: Bool = true {
        didSet {
            if isBlinking {
                _startBlink()
            } else {
                _stopBlink()
                alpha = 1
            }
        }
    }

    // MARK: - 私有属性

    private var _blinkTimer: Timer?

    // MARK: - 初始化

    public init(frame: CGRect, color: UIColor = UIColor(white: 0.2, alpha: 1)) {
        super.init(frame: frame)
        caretColor = color
        _commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _commonInit()
    }

    private func _commonInit() {
        backgroundColor = caretColor
        layer.cornerRadius = 1
        _startBlink()
    }

    // MARK: - 闪烁

    private func _startBlink() {
        _stopBlink()

        _blinkTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.alpha = self?.alpha == 0 ? 1 : 0
        }
    }

    private func _stopBlink() {
        _blinkTimer?.invalidate()
        _blinkTimer = nil
    }

    // MARK: - 公共方法

    /// 重置闪烁
    public func resetBlink() {
        alpha = 1
        _startBlink()
    }

    // MARK: - 析构

    deinit {
        _stopBlink()
    }
}

#endif

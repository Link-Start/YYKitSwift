//
//  LSLabel.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  增强的标签视图 - 支持多种文本样式、复制、富文本等
//

#if canImport(UIKit)
import UIKit

// MARK: - LSLabel

/// 增强的标签视图
public class LSLabel: UILabel {

    // MARK: - 类型定义

    /// 文本样式
    public enum TextStyle {
        case heading1        // 28pt Bold
        case heading2        // 24pt Bold
        case heading3        // 20pt Semibold
        case title           // 18pt Semibold
        case body            // 16pt Regular
        case callout         // 16pt Regular
        case subheadline     // 14pt Regular
        case footnote        // 12pt Regular
        case caption1        // 12pt Regular
        case caption2        // 11pt Regular
        case custom(UIFont)
    }

    /// 文本对齐
    public enum TextAlignment {
        case left
        case center
        case right
        case justified
    }

    // MARK: - 属性

    /// 是否支持文本复制
    public var isCopyEnabled: Bool = false {
        didSet {
            updateGestureRecognizers()
        }
    }

    /// 最大行数（0 表示无限制）
    public var maxLines: Int = 0 {
        didSet {
            numberOfLines = maxLines
        }
    }

    /// 文本样式
    public var textStyle: TextStyle = .body {
        didSet {
            updateTextStyle()
        }
    }

    /// 是否自动调整字体大小
    public var adjustsFontForContentSize: Bool = true {
        didSet {
            adjustsFontForContentSizeCategory = adjustsFontForContentSize
        }
    }

    /// 行高倍数
    public var lineHeightMultiple: CGFloat = 0 {
        didSet {
            updateTextAttributes()
        }
    }

    /// 字间距
    public var letterSpacing: CGFloat = 0 {
        didSet {
            updateTextAttributes()
        }
    }

    /// 文本颜色（支持渐变）
    public var textGradientColors: [UIColor]? = nil {
        didSet {
            updateGradient()
        }
    }

    /// 文本阴影
    public var ls_textShadow: NSShadow? = nil {
        didSet {
            updateTextAttributes()
        }
    }

    /// 链接检测
    public var isLinkDetectionEnabled: Bool = false {
        didSet {
            updateGestureRecognizers()
        }
    }

    /// 链接颜色
    public var linkColor: UIColor = .systemBlue {
        didSet {
            updateTextAttributes()
        }
    }

    /// 链接点击回调
    public var onLinkTap: ((URL) -> Void)?

    // MARK: - 私有属性

    private var gradientLayer: CAGradientLayer?

    private var textStorage: NSTextStorage?
    private var layoutManager: NSLayoutManager?
    private var textContainer: NSTextContainer?

    private var links: [NSRange: URL] = [:]

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupLabel()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLabel()
    }

    public convenience init(
        text: String?,
        style: TextStyle = .body,
        color: UIColor = .label
    ) {
        self.init(frame: .zero)
        self.text = text
        self.textStyle = style
        self.textColor = color
    }

    // MARK: - 设置

    private func setupLabel() {
        // 默认配置
        numberOfLines = 1
        lineBreakMode = .byTruncatingTail

        // 启用用户交互
       .isUserInteractionEnabled = true

        // 更新文本样式
        updateTextStyle()
    }

    private func updateTextStyle() {
        switch textStyle {
        case .heading1:
            font = .boldSystemFont(ofSize: 28)
        case .heading2:
            font = .boldSystemFont(ofSize: 24)
        case .heading3:
            font = .systemFont(ofSize: 20, weight: .semibold)
        case .title:
            font = .systemFont(ofSize: 18, weight: .semibold)
        case .body:
            font = .systemFont(ofSize: 16)
        case .callout:
            font = .systemFont(ofSize: 16)
        case .subheadline:
            font = .systemFont(ofSize: 14)
        case .footnote:
            font = .systemFont(ofSize: 12)
        case .caption1:
            font = .systemFont(ofSize: 12)
        case .caption2:
            font = .systemFont(ofSize: 11)
        case .custom(let customFont):
            font = customFont
        }
    }

    private func updateTextAttributes() {
        guard let text = text else { return }

        let attributedString = NSMutableAttributedString(string: text)

        // 行高
        if lineHeightMultiple > 0 {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineHeightMultiple = lineHeightMultiple
            attributedString.addAttributes([
                .paragraphStyle: paragraphStyle
            ], range: NSRange(location: 0, length: text.count))
        }

        // 字间距
        if letterSpacing != 0 {
            attributedString.addAttributes([
                .kern: letterSpacing
            ], range: NSRange(location: 0, length: text.count))
        }

        // 阴影
        if let shadow = ls_textShadow {
            attributedString.addAttributes([
                .shadow: shadow
            ], range: NSRange(location: 0, length: text.count))
        }

        self.attributedText = attributedString
    }

    private func updateGradient() {
        guard let colors = textGradientColors, !colors.isEmpty else {
            gradientLayer?.removeFromSuperlayer()
            gradientLayer = nil
            return
        }

        let gradient = CAGradientLayer()
        gradient.colors = colors.map { $0.cgColor }
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)

        layer.insertSublayer(gradient, at: 0)
        gradientLayer = gradient

        layer.masksToBounds = true
        setNeedsLayout()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        gradientLayer?.frame = bounds

        // 更新渐变遮罩
        if textGradientColors != nil {
            layer.mask = gradientLayer
        }
    }

    private func updateGestureRecognizers() {
        // 移除现有手势
        gestureRecognizers?.forEach { removeGestureRecognizer($0) }

        // 复制手势
        if isCopyEnabled {
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            addGestureRecognizer(longPress)
        }

        // 链接检测手势
        if isLinkDetectionEnabled {
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            addGestureRecognizer(tap)
        }
    }

    // MARK: - 手势处理

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, let text = text else { return }

        let menuController = UIMenuController.shared

        menuController.show(
            from: CGRect(x: bounds.midX, y: bounds.midY, width: 0, height: 0),
            in: self
        )

        becomeFirstResponder()
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard isLinkDetectionEnabled else { return }

        let location = gesture.location(in: self)

        if let url = linkAtPoint(location) {
            onLinkTap?(url)
        }
    }

    // MARK: - 链接检测

    private func detectLinks() {
        guard let text = text else { return }

        links.removeAll()

        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, range: NSRange(location: 0, length: text.utf16.count)) ?? []

        for match in matches {
            if let url = match.url, let range = Range(match.range, in: text) {
                let nsRange = NSRange(range, in: text)
                links[nsRange] = url
            }
        }

        // 高亮链接
        highlightLinks()
    }

    private func highlightLinks() {
        guard let text = text, !links.isEmpty else { return }

        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttributes([
            .foregroundColor: textColor,
            .font: font
        ], range: NSRange(location: 0, length: text.count))

        for (range, _) in links {
            attributedString.addAttributes([
                .foregroundColor: linkColor,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ], range: range)
        }

        self.attributedText = attributedString
    }

    private func linkAtPoint(_ point: CGPoint) -> URL? {
        guard let text = text else { return nil }

        for (range, url) in links {
            if let textRange = Range(range, in: text) {
                let nsRange = NSRange(textRange, in: text)

                layoutManager?.enumerateLineFragments(forGlyphRange: nsRange) { _, usedRect, textRect, _ in
                    if usedRect.contains(point) {
                        return
                    }
                }

                return url
            }
        }

        return nil
    }

    // MARK: - UIResponder

    public override func canBecomeFirstResponder() -> Bool {
        return isCopyEnabled
    }

    public override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(copy(_:)) {
            return isCopyEnabled
        }
        return super.canPerformAction(action, withSender: sender)
    }

    public override func copy(_ sender: Any?) {
        guard let text = text else { return }

        let pasteboard = UIPasteboard.general
        pasteboard.string = text

        UIMenuController.shared.hide()
    }

    // MARK: - 公共方法

    /// 设置文本和样式
    public func ls_setText(_ text: String?, style: TextStyle) {
        self.text = text
        self.textStyle = style
    }

    /// 设置 HTML 文本
    public func ls_setHTML(_ html: String) {
        guard let data = html.data(using: .utf8) else { return }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        if let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            self.attributedText = attributedString
        }
    }

    /// 设置 Markdown 文本
    @available(iOS 13.0, *)
    public func ls_setMarkdown(_ markdown: String) {
        let attributedString = try? NSAttributedString(markdown: markdown)
        self.attributedText = attributedString
    }

    /// 设置带间距的文本
    public func ls_setTextWithSpacing(_ text: String?, letterSpacing: CGFloat, lineSpacing: CGFloat) {
        self.text = text
        self.letterSpacing = letterSpacing
        self.lineHeightMultiple = lineSpacing / font.lineHeight
    }

    /// 计算文本大小
    public func ls_calculateSize(for width: CGFloat) -> CGSize {
        guard let text = text else { return .zero }

        let size = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let options: NSStringDrawingOptions = usesLineFragmentOrigin ? [.usesLineFragmentOrigin, .usesFontLeading] : []

        let boundingRect = (text as NSString).boundingRect(
            with: size,
            options: options,
            attributes: [.font: font],
            context: nil
        )

        return CGSize(
            width: ceil(boundingRect.width),
            height: ceil(boundingRect.height)
        )
    }

    /// 动画文本变化
    public func ls_animateTextChange(to newText: String?, duration: TimeInterval = 0.3) {
        UIView.transition(
            with: self,
            duration: duration,
            options: .transitionCrossDissolve
        ) {
            self.text = newText
        }
    }

    /// 获取当前文本高度
    public var ls_textHeight: CGFloat {
        return ls_calculateSize(for: bounds.width).height
    }
}

// MARK: - UILabel Extension

public extension UILabel {

    /// 创建预配置的标签
    static func ls_label(
        with text: String?,
        style: LSLabel.TextStyle = .body,
        color: UIColor = .label
    ) -> LSLabel {
        return LSLabel(text: text, style: style, color: color)
    }

    /// 设置占位符颜色（通过属性文本）
    func ls_setPlaceholderColor(_ color: UIColor) {
        guard let placeholder = text else { return }

        let attributedString = NSMutableAttributedString(string: placeholder)
        attributedString.addAttributes([
            .foregroundColor: color
        ], range: NSRange(location: 0, length: placeholder.count))

        self.attributedText = attributedString
    }

    /// 设置行间距
    func ls_setLineSpacing(_ spacing: CGFloat) {
        guard let text = text else { return }

        let attributedString = NSMutableAttributedString(string: text)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = spacing

        attributedString.addAttributes([
            .paragraphStyle: paragraphStyle,
            .font: font,
            .foregroundColor: textColor
        ], range: NSRange(location: 0, length: text.count))

        self.attributedText = attributedString
    }

    /// 设置字间距
    func ls_setLetterSpacing(_ spacing: CGFloat) {
        guard let text = text else { return }

        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttributes([
            .kern: spacing
        ], range: NSRange(location: 0, length: text.count))

        self.attributedText = attributedString
    }
}

// MARK: - Specialized Labels

/// 多样式标签
public class LSMultilineLabel: LSLabel {

    public convenience init(
        text: String?,
        lines: Int = 0,
        alignment: NSTextAlignment = .left
    ) {
        self.init(frame: .zero)
        self.text = text
        self.numberOfLines = lines
        self.textAlignment = alignment
    }
}

/// 标题标签
public class LSHeadingLabel: LSLabel {

    public enum Level {
        case h1, h2, h3
    }

    public convenience init(
        text: String?,
        level: Level = .h1,
        color: UIColor = .label
    ) {
        let style: LSLabel.TextStyle
        switch level {
        case .h1: style = .heading1
        case .h2: style = .heading2
        case .h3: style = .heading3
        }

        self.init(text: text, style: style, color: color)
    }
}

/// 副标题标签
public class LSSubheadlineLabel: LSLabel {

    public convenience init(
        text: String?,
        color: UIColor = .secondaryLabel
    ) {
        self.init(text: text, style: .subheadline, color: color)
    }
}

/// 说明文字标签
public class LSCaptionLabel: LSLabel {

    public enum Size {
        case caption1, caption2
    }

    public convenience init(
        text: String?,
        size: Size = .caption1,
        color: UIColor = .secondaryLabel
    ) {
        let style: LSLabel.TextStyle = size == .caption1 ? .caption1 : .caption2
        self.init(text: text, style: style, color: color)
    }
}

/// 价格标签
public class LSPriceLabel: LSLabel {

    /// 价格
    public var price: Double = 0 {
        didSet {
            updatePrice()
        }
    }

    /// 货币符号
    public var currencySymbol: String = "¥" {
        didSet {
            updatePrice()
        }
    }

    /// 是否显示小数
    public var showsDecimal: Bool = true {
        didSet {
            updatePrice()
        }
    }

    /// 小数部分颜色
    public var decimalColor: UIColor = .label {
        didSet {
            updatePrice()
        }
    }

    public convenience init(price: Double, currencySymbol: String = "¥") {
        self.init(frame: .zero)
        self.price = price
        self.currencySymbol = currencySymbol
        font = .systemFont(ofSize: 18, weight: .medium)
    }

    private func updatePrice() {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = currencySymbol

        if let text = formatter.string(from: NSNumber(value: price)) {
            let attributedString = NSMutableAttributedString(string: text)

            // 设置小数部分颜色
            if showsDecimal, let decimalRange = text.range(of: ".") {
                let nsRange = NSRange(decimalRange, in: text)
                if nsRange.location < text.count {
                    attributedString.addAttributes([
                        .foregroundColor: decimalColor
                    ], range: NSRange(location: nsRange.location, length: text.count - nsRange.location))
                }
            }

            self.attributedText = attributedString
        }
    }
}

/// 计数标签
public class LSCountLabel: LSLabel {

    /// 当前计数
    public var count: Int = 0 {
        didSet {
            updateCount()
        }
    }

    /// 格式化字符串
    public var formatString: String = "%d" {
        didSet {
            updateCount()
        }
    }

    /// 是否动画
    public var animated: Bool = true

    private var previousCount: Int = 0

    public convenience init(count: Int = 0, format: String = "%d") {
        self.init(frame: .zero)
        self.count = count
        self.formatString = format
    }

    private func updateCount() {
        let newCount = count
        let oldCount = previousCount

        if animated && oldCount != newCount {
            animateCount(from: oldCount, to: newCount)
        } else {
            text = String(format: formatString, newCount)
        }

        previousCount = newCount
    }

    private func animateCount(from start: Int, to end: Int) {
        let duration = 0.3
        let steps = 30
        let stepDuration = duration / Double(steps)
        let increment = Double(end - start) / Double(steps)

        var current = Double(start)
        var remaining = steps

        Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            current += increment
            remaining -= 1

            if remaining <= 0 {
                self.text = String(format: self.formatString, end)
                timer.invalidate()
            } else {
                self.text = String(format: self.formatString, Int(current))
            }
        }
    }
}

/// 时间标签
public class LSTimeLabel: LSLabel {

    /// 时间间隔
    public var timeInterval: TimeInterval = 0 {
        didSet {
            updateTime()
        }
    }

    /// 格式
    public enum TimeFormat {
        case short           // 1:30
        case medium          // 1:30:45
        case long            // 1h 30m 45s
        case abbreviated     // 1h30m
    }

    public var format: TimeFormat = .medium {
        didSet {
            updateTime()
        }
    }

    public convenience init(timeInterval: TimeInterval, format: TimeFormat = .medium) {
        self.init(frame: .zero)
        self.timeInterval = timeInterval
        self.format = format
        font = .monospacedDigitSystemFont(ofSize: 16, weight: .regular)
    }

    private func updateTime() {
        let interval = Int(abs(timeInterval))

        let hours = interval / 3600
        let minutes = (interval % 3600) / 60
        let seconds = interval % 60

        let text: String
        switch format {
        case .short:
            if hours > 0 {
                text = String(format: "%d:%02d:%02d", hours, minutes, seconds)
            } else {
                text = String(format: "%d:%02d", minutes, seconds)
            }
        case .medium:
            text = String(format: "%d:%02d:%02d", hours, minutes, seconds)
        case .long:
            if hours > 0 {
                text = String(format: "%dh %dm %ds", hours, minutes, seconds)
            } else if minutes > 0 {
                text = String(format: "%dm %ds", minutes, seconds)
            } else {
                text = String(format: "%ds", seconds)
            }
        case .abbreviated:
            if hours > 0 {
                text = String(format: "%dh%dm", hours, minutes)
            } else {
                text = String(format: "%dm%ds", minutes, seconds)
            }
        }

        self.text = text
    }
}

#endif

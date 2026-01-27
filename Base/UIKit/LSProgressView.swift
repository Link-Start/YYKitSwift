//
//  LSProgressView.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  进度视图 - 多种样式的进度指示器
//

#if canImport(UIKit)
import UIKit

// MARK: - LSProgressView

/// 进度视图
public class LSProgressView: UIView {

    // MARK: - 样式枚举

    /// 进度条样式
    public enum Style {
        case defaultBar          // 默认进度条
        case roundedBar          // 圆角进度条
        case segmentedBar        // 分段进度条
        circular                 // 圆形进度
        pie                     // 饼图进度
    }

    // MARK: - 属性

    /// 进度样式
    public var style: Style = .defaultBar {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 进度值 (0.0 - 1.0)
    public var progress: CGFloat = 0 {
        didSet {
            let clamped = max(0, min(1, progress))
            guard clamped != oldValue else { return }
            progress = clamped
            setNeedsDisplay()
        }
    }

    /// 进度颜色
    public var progressColor: UIColor = .systemBlue {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 进度渐变色（可选）
    public var progressGradientColors: [UIColor]? {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 背景颜色
    public var trackColor: UIColor = .systemGray5 {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 边框颜色
    public var borderColor: UIColor = .clear {
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }

    /// 边框宽度
    public var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }

    /// 分段数量（segmentedBar 样式）
    public var segmentCount: Int = 5 {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 圆角半径
    public var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            setNeedsDisplay()
        }
    }

    /// 是否显示百分比文本
    public var showsPercentageText: Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 百分比文本颜色
    public var percentageTextColor: UIColor = .label {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 百分比文本字体
    public var percentageTextFont: UIFont = .systemFont(ofSize: 14) {
        didSet {
            setNeedsDisplay()
        }
    }

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
    }

    // MARK: - 绘制

    public override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext() else { return }

        switch style {
        case .defaultBar:
            drawDefaultBar(in: rect, context: context)
        case .roundedBar:
            drawRoundedBar(in: rect, context: context)
        case .segmentedBar:
            drawSegmentedBar(in: rect, context: context)
        case .circular:
            drawCircular(in: rect, context: context)
        case .pie:
            drawPie(in: rect, context: context)
        }
    }

    // MARK: - 绘制方法

    /// 绘制默认进度条
    private func drawDefaultBar(in rect: CGRect, context: CGContext) {
        // 绘制背景
        trackColor.setFill()
        context.fill(rect)

        // 绘制进度
        let progressRect = CGRect(
            x: rect.origin.x,
            y: rect.origin.y,
            width: rect.width * progress,
            height: rect.height
        )

        if let gradientColors = progressGradientColors {
            drawGradient(in: progressRect, colors: gradientColors, context: context)
        } else {
            progressColor.setFill()
            context.fill(progressRect)
        }

        // 绘制百分比文本
        if showsPercentageText {
            drawPercentageText(in: rect)
        }
    }

    /// 绘制圆角进度条
    private func drawRoundedBar(in rect: CGRect, context: CGContext) {
        let cornerRadius = self.cornerRadius > 0 ? self.cornerRadius : rect.height / 2

        // 绘制背景
        let backgroundPath = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        trackColor.setFill()
        backgroundPath.fill()

        // 绘制进度
        let progressRect = CGRect(
            x: rect.origin.x,
            y: rect.origin.y,
            width: rect.width * progress,
            height: rect.height
        )

        let progressPath = UIBezierPath(roundedRect: progressRect, cornerRadius: cornerRadius)

        if let gradientColors = progressGradientColors {
            drawGradient(in: progressRect, colors: gradientColors, context: context)
            progressPath.addClip()
        } else {
            progressColor.setFill()
            progressPath.fill()
        }

        // 绘制百分比文本
        if showsPercentageText {
            drawPercentageText(in: rect)
        }
    }

    /// 绘制分段进度条
    private func drawSegmentedBar(in rect: CGRect, context: CGContext) {
        let segmentWidth = rect.width / CGFloat(segmentCount)
        let segmentSpacing: CGFloat = 2
        let activeSegmentCount = Int(CGFloat(segmentCount) * progress)

        for i in 0..<segmentCount {
            let segmentRect = CGRect(
                x: rect.origin.x + CGFloat(i) * segmentWidth + segmentSpacing / 2,
                y: rect.origin.y,
                width: segmentWidth - segmentSpacing,
                height: rect.height
            )

            if i < activeSegmentCount {
                progressColor.setFill()
            } else {
                trackColor.setFill()
            }

            let segmentPath = UIBezierPath(roundedRect: segmentRect, cornerRadius: segmentRect.height / 2)
            segmentPath.fill()
        }

        // 绘制百分比文本
        if showsPercentageText {
            drawPercentageText(in: rect)
        }
    }

    /// 绘制圆形进度
    private func drawCircular(in rect: CGRect, context: CGContext) {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - 2
        let lineWidth: CGFloat = 4

        // 绘制背景圆环
        let backgroundPath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: -.pi / 2 + 2 * .pi,
            clockwise: true
        )
        backgroundPath.lineWidth = lineWidth
        trackColor.setStroke()
        backgroundPath.stroke()

        // 绘制进度圆环
        let endAngle = -.pi / 2 + 2 * .pi * progress
        let progressPath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: endAngle,
            clockwise: true
        )
        progressPath.lineWidth = lineWidth
        progressColor.setStroke()
        progressPath.stroke()

        // 绘制百分比文本
        if showsPercentageText {
            drawPercentageText(in: rect)
        }
    }

    /// 绘制饼图进度
    private func drawPie(in rect: CGRect, context: CGContext) {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        // 绘制背景圆
        let backgroundPath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: 0,
            endAngle: 2 * .pi,
            clockwise: true
        )
        trackColor.setFill()
        backgroundPath.fill()

        // 绘制进度扇形
        let endAngle = -.pi / 2 + 2 * .pi * progress
        let progressPath = UIBezierPath()
        progressPath.move(to: center)
        progressPath.addArc(
            center: center,
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: endAngle,
            clockwise: true
        )
        progressPath.close()

        if let gradientColors = progressGradientColors {
            drawGradient(in: rect, colors: gradientColors, context: context)
            progressPath.addClip()
        } else {
            progressColor.setFill()
            progressPath.fill()
        }

        // 绘制百分比文本
        if showsPercentageText {
            drawPercentageText(in: rect)
        }
    }

    /// 绘制渐变
    private func drawGradient(in rect: CGRect, colors: [UIColor], context: CGContext) {
        guard colors.count >= 2 else { return }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let cgColors = colors.map { $0.cgColor }
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: cgColors as CFArray, locations: nil) else {
            return
        }

        let startPoint = CGPoint(x: rect.minX, y: rect.midY)
        let endPoint = CGPoint(x: rect.maxX, y: rect.midY)

        context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
    }

    /// 绘制百分比文本
    private func drawPercentageText(in rect: CGRect) {
        let percentageText = String(format: "%.0f%%", progress * 100)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: percentageTextFont,
            .foregroundColor: percentageTextColor
        ]

        let textSize = percentageText.size(withAttributes: attributes)
        let textRect = CGRect(
            x: rect.origin.x + (rect.width - textSize.width) / 2,
            y: rect.origin.y + (rect.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )

        percentageText.draw(in: textRect, withAttributes: attributes)
    }

    // MARK: - 动画

    /// 设置进度（带动画）
    ///
    /// - Parameters:
    ///   - newProgress: 新进度值
    ///   - animated: 是否动画
    ///   - duration: 动画时长
    public func setProgress(_ newProgress: CGFloat, animated: Bool, duration: TimeInterval = 0.3) {
        guard animated else {
            self.progress = newProgress
            return
        }

        UIView.animate(withDuration: duration) {
            self.progress = newProgress
        }
    }
}

// MARK: - LSAnimatedProgressView

/// 带动画效果的进度视图
public class LSAnimatedProgressView: LSProgressView {

    /// 动画类型
    public enum AnimationType {
        case none
        case pulse              // 脉冲效果
        case shimmer            // 微光效果
        case rotating           // 旋转效果（仅圆形/饼图）
    }

    /// 动画类型
    public var animationType: AnimationType = .none {
        didSet {
            updateAnimation()
        }
    }

    /// 动画持续时间
    public var animationDuration: TimeInterval = 1.5

    private var displayLink: CADisplayLink?
    private var animationStartTime: CFTimeInterval?

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupAnimation()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupAnimation()
    }

    deinit {
        displayLink?.invalidate()
    }

    // MARK: - 动画设置

    private func setupAnimation() {
        let displayLink = CADisplayLink(target: self, selector: #selector(animationTick))
        displayLink.add(to: .main, forMode: .common)
        self.displayLink = displayLink
        displayLink.isPaused = true
    }

    private func updateAnimation() {
        switch animationType {
        case .none:
            displayLink?.isPaused = true
        case .pulse, .shimmer, .rotating:
            displayLink?.isPaused = false
            animationStartTime = CACurrentMediaTime()
        }
    }

    @objc private func animationTick() {
        guard let startTime = animationStartTime else { return }
        let elapsed = CACurrentMediaTime() - startTime

        switch animationType {
        case .pulse:
            let scale = 1 + 0.05 * sin(elapsed * .pi * 2 / animationDuration)
            layer.setAffineTransform(CGAffineTransform(scaleX: scale, y: scale))
        case .shimmer:
            let offset = (elapsed.truncatingRemainder(dividingBy: animationDuration) / animationDuration)
            setNeedsDisplay()
        case .rotating:
            let angle = elapsed * .pi * 2 / animationDuration
            var transform = CGAffineTransform.identity
            transform = transform.rotated(by: angle)
            layer.setAffineTransform(transform)
        case .none:
            break
        }
    }
}

// MARK: - 便捷方法

public extension LSProgressView {

    /// 创建默认进度条
    static func defaultBar() -> LSProgressView {
        let progressView = LSProgressView()
        progressView.style = .defaultBar
        progressView.cornerRadius = 2
        return progressView
    }

    /// 创建圆形进度视图
    static func circular() -> LSProgressView {
        let progressView = LSProgressView()
        progressView.style = .circular
        progressView.showsPercentageText = true
        return progressView
    }

    /// 创建饼图进度视图
    static func pie() -> LSProgressView {
        let progressView = LSProgressView()
        progressView.style = .pie
        progressView.showsPercentageText = true
        return progressView
    }

    /// 创建分段进度条
    static func segmented(segmentCount: Int = 5) -> LSProgressView {
        let progressView = LSProgressView()
        progressView.style = .segmentedBar
        progressView.segmentCount = segmentCount
        return progressView
    }
}

#endif

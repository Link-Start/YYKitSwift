//
//  LSProgressBar.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  进度条组件 - 线性进度条、环形进度条、分段进度条等
//

#if canImport(UIKit)
import UIKit

// MARK: - LSProgressBar

/// 线性进度条
@MainActor
public class LSProgressBar: UIView {

    // MARK: - 类型定义

    /// 进度条样式
    public enum Style {
        case defaultStyle     // 默认
        case rounded          // 圆角
        case flat             // 扁平
        case segmented       // 分段
    }

    /// 进度条方向
    public enum Direction {
        case leftToRight
        case rightToLeft
        case bottomToTop
        case topToBottom
    }

    // MARK: - 属性

    /// 进度值 (0.0 - 1.0)
    public var progress: Float = 0 {
        didSet {
            progress = max(0, min(1, progress))
            updateProgress()
        }
    }

    /// 进度条颜色
    public var progressColor: UIColor = .systemBlue {
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

    /// 进度条样式
    public var style: Style = .defaultStyle {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 进度条方向
    public var direction: Direction = .leftToRight {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 是否显示百分比标签
    public var showsLabel: Bool = false {
        didSet {
            labelView.isHidden = !showsLabel
            updateLabel()
        }
    }

    /// 标签文字颜色
    public var labelColor: UIColor = .label {
        didSet {
            labelView.textColor = labelColor
        }
    }

    /// 是否动画
    public var animated: Bool = true

    /// 动画时长
    public var animationDuration: TimeInterval = 0.3

    /// 圆角半径
    public var cornerRadius: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 进度条边框
    public var borderWidth: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 边框颜色
    public var borderColor: UIColor = .clear {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 分段数量（仅 segmented 样式）
    public var segmentCount: Int = 5 {
        didSet {
            segmentCount = max(1, segmentCount)
            setNeedsDisplay()
        }
    }

    /// 进度变化回调
    public var onProgressChanged: ((Float) -> Void)?

    // MARK: - 私有属性

    private var displayProgress: Float = 0

    private let labelView: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupProgressBar()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupProgressBar()
    }

    public convenience init(progress: Float = 0) {
        self.init(frame: .zero)
        self.progress = progress
        self.displayProgress = progress
    }

    // MARK: - 设置

    private func setupProgressBar() {
        backgroundColor = .clear
        clipsToBounds = true

        addSubview(labelView)

        NSLayoutConstraint.activate([
            labelView.centerXAnchor.constraint(equalTo: centerXAnchor),
            labelView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    // MARK: - 绘制

    public override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext() else { return }

        // 绘制轨道
        drawTrack(in: rect, context: context)

        // 绘制进度
        drawProgress(in: rect, context: context)

        // 绘制边框
        if borderWidth > 0 {
            drawBorder(in: rect, context: context)
        }
    }

    private func drawTrack(in rect: CGRect, context: CGContext) {
        trackColor.setFill()

        var trackRect = rect

        switch style {
        case .rounded:
            let path = UIBezierPath(roundedRect: trackRect, cornerRadius: rect.height / 2)
            path.fill()
        case .flat:
            trackRect.fill()
        case .defaultStyle:
            trackRect.fill()
        case .segmented:
            drawSegments(in: rect, context: context, filled: false)
        }
    }

    private func drawProgress(in rect: CGRect, context: CGContext) {
        let progressRect = calculateProgressRect(in: rect)

        progressColor.setFill()

        switch style {
        case .rounded:
            let path = UIBezierPath(roundedRect: progressRect, cornerRadius: rect.height / 2)
            path.fill()
        case .flat:
            progressRect.fill()
        case .defaultStyle:
            progressRect.fill()
        case .segmented:
            drawSegments(in: rect, context: context, filled: true)
        }
    }

    private func drawSegments(in rect: CGRect, context: CGContext, filled: Bool) {
        let segmentWidth = rect.width / CGFloat(segmentCount)
        let spacing: CGFloat = 2

        for i in 0..<segmentCount {
            let x = CGFloat(i) * segmentWidth + spacing
            let y = spacing
            let width = segmentWidth - spacing * 2
            let height = rect.height - spacing * 2

            let segmentRect = CGRect(x: x, y: y, width: width, height: height)

            let shouldFill: Bool
            if filled {
                shouldFill = Float(i) / Float(segmentCount) <= displayProgress
            } else {
                shouldFill = false
            }

            if shouldFill {
                progressColor.setFill()
            } else {
                trackColor.setFill()
            }

            UIBezierPath(roundedRect: segmentRect, cornerRadius: height / 2).fill()
        }
    }

    private func drawBorder(in rect: CGRect, context: CGContext) {
        let borderPath = UIBezierPath(roundedRect: rect.insetBy(dx: borderWidth / 2, dy: borderWidth / 2), cornerRadius: cornerRadius)
        borderPath.lineWidth = borderWidth
        borderColor.setStroke()
        borderPath.stroke()
    }

    private func calculateProgressRect(in rect: CGRect) -> CGRect {
        var progressRect: CGRect

        switch direction {
        case .leftToRight:
            progressRect = CGRect(
                x: 0,
                y: 0,
                width: rect.width * CGFloat(displayProgress),
                height: rect.height
            )
        case .rightToLeft:
            progressRect = CGRect(
                x: rect.width * (1 - CGFloat(displayProgress)),
                y: 0,
                width: rect.width * CGFloat(displayProgress),
                height: rect.height
            )
        case .bottomToTop:
            progressRect = CGRect(
                x: 0,
                y: rect.height * (1 - CGFloat(displayProgress)),
                width: rect.width,
                height: rect.height * CGFloat(displayProgress)
            )
        case .topToBottom:
            progressRect = CGRect(
                x: 0,
                y: 0,
                width: rect.width,
                height: rect.height * CGFloat(displayProgress)
            )
        }

        return progressRect
    }

    // MARK: - 进度更新

    private func updateProgress() {
        onProgressChanged?(progress)

        if animated {
            UIView.animate(withDuration: animationDuration) {
                self.displayProgress = self.progress
                self.setNeedsDisplay()
                self.updateLabel()
            }
        } else {
            displayProgress = progress
            setNeedsDisplay()
            updateLabel()
        }
    }

    private func updateLabel() {
        guard showsLabel else { return }
        labelView.text = String(format: "%.0f%%", displayProgress * 100)
    }

    // MARK: - 公共方法

    /// 设置进度（带动画）
    public func setProgress(_ progress: Float, animated: Bool = true) {
        let wasAnimated = self.animated
        self.animated = animated
        self.progress = progress
        self.animated = wasAnimated
    }

    /// 增加进度
    public func increment(by amount: Float = 0.01) {
        progress += amount
    }

    /// 减少进度
    public func decrement(by amount: Float = 0.01) {
        progress -= amount
    }

    /// 重置进度
    public func reset() {
        progress = 0
    }

    /// 完成进度
    public func complete() {
        progress = 1
    }
}

// MARK: - LSCircularProgressView

/// 环形进度条
public class LSCircularProgressView: UIView {

    // MARK: - 属性

    /// 进度值 (0.0 - 1.0)
    public var progress: Float = 0 {
        didSet {
            progress = max(0, min(1, progress))
            updateProgress()
        }
    }

    /// 进度条颜色
    public var progressColor: UIColor = .systemBlue {
        didSet {
            progressLayer.strokeColor = progressColor.cgColor
        }
    }

    /// 背景轨道颜色
    public var trackColor: UIColor = .systemGray5 {
        didSet {
            trackLayer.strokeColor = trackColor.cgColor
        }
    }

    /// 线条宽度
    public var lineWidth: CGFloat = 8 {
        didSet {
            progressLayer.lineWidth = lineWidth
            trackLayer.lineWidth = lineWidth
        }
    }

    /// 是否显示标签
    public var showsLabel: Bool = true {
        didSet {
            labelView.isHidden = !showsLabel
        }
    }

    /// 标签字体
    public var labelFont: UIFont = .systemFont(ofSize: 16, weight: .medium) {
        didSet {
            labelView.font = labelFont
        }
    }

    /// 标签颜色
    public var labelColor: UIColor = .label {
        didSet {
            labelView.textColor = labelColor
        }
    }

    /// 是否动画
    public var animated: Bool = true

    /// 动画时长
    public var animationDuration: TimeInterval = 0.3

    /// 起始角度（默认从顶部开始，-90度）
    public var startAngle: CGFloat = -.pi / 2 {
        didSet {
            setNeedsLayout()
        }
    }

    /// 是否逆时针
    public var isClockwise: Bool = true

    // MARK: - 私有属性

    private let trackLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeEnd = 1
        return layer
    }()

    private let progressLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeEnd = 0
        return layer
    }()

    private let labelView: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private var displayProgress: Float = 0

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupProgressView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupProgressView()
    }

    public convenience init(progress: Float = 0) {
        self.init(frame: .zero)
        self.progress = progress
        self.displayProgress = progress
    }

    // MARK: - 设置

    private func setupProgressView() {
        backgroundColor = .clear

        layer.addSublayer(trackLayer)
        layer.addSublayer(progressLayer)

        addSubview(labelView)

        NSLayoutConstraint.activate([
            labelView.centerXAnchor.constraint(equalTo: centerXAnchor),
            labelView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        let radius = min(bounds.width, bounds.height) / 2 - lineWidth / 2

        let circularPath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: startAngle + 2 * .pi,
            clockwise: true
        )

        trackLayer.path = circularPath.cgPath
        progressLayer.path = circularPath.cgPath

        updateLabel()
    }

    // MARK: - 进度更新

    private func updateProgress() {
        let targetProgress = isClockwise ? progress : 1 - progress

        if animated {
            UIView.animate(withDuration: animationDuration) {
                self.displayProgress = self.progress
                self.progressLayer.strokeEnd = CGFloat(targetProgress)
                self.updateLabel()
            }
        } else {
            displayProgress = progress
            progressLayer.strokeEnd = CGFloat(targetProgress)
            updateLabel()
        }
    }

    private func updateLabel() {
        guard showsLabel else { return }
        labelView.text = String(format: "%.0f%%", displayProgress * 100)
    }

    // MARK: - 公共方法

    /// 设置进度
    public func setProgress(_ progress: Float, animated: Bool = true) {
        let wasAnimated = self.animated
        self.animated = animated
        self.progress = progress
        self.animated = wasAnimated
    }
}

// MARK: - LSSegmentedProgressBar

/// 分段进度条
public class LSSegmentedProgressBar: UIView {

    // MARK: - 属性

    /// 当前段索引
    public var currentSegment: Int = 0 {
        didSet {
            currentSegment = max(0, min(segmentCount - 1, currentSegment))
            updateSegments()
        }
    }

    /// 段数量
    public var segmentCount: Int = 5 {
        didSet {
            segmentCount = max(1, segmentCount)
            recreateSegments()
        }
    }

    /// 已完成段的颜色
    public var completedColor: UIColor = .systemGreen {
        didSet {
            updateSegmentColors()
        }
    }

    /// 当前段的颜色
    public var currentColor: UIColor = .systemBlue {
        didSet {
            updateSegmentColors()
        }
    }

    /// 未完成段的颜色
    public var incompleteColor: UIColor = .systemGray5 {
        didSet {
            updateSegmentColors()
        }
    }

    /// 段之间的间距
    public var segmentSpacing: CGFloat = 4 {
        didSet {
            setNeedsLayout()
        }
    }

    /// 是否显示标签
    public var showsLabels: Bool = false {
        didSet {
            updateLabelsVisibility()
        }
    }

    /// 段标题
    public var segmentTitles: [String] = [] {
        didSet {
            updateLabels()
        }
    }

    /// 段变化回调
    public var onSegmentChanged: ((Int) -> Void)?

    // MARK: - 私有属性

    private var segmentViews: [UIView] = []
    private var labelViews: [UILabel] = []

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSegments()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSegments()
    }

    public convenience init(segmentCount: Int = 5) {
        self.init(frame: .zero)
        self.segmentCount = segmentCount
    }

    // MARK: - 设置

    private func setupSegments() {
        recreateSegments()
    }

    private func recreateSegments() {
        // 移除旧的段
        segmentViews.forEach { $0.removeFromSuperview() }
        labelViews.forEach { $0.removeFromSuperview() }
        segmentViews.removeAll()
        labelViews.removeAll()

        // 创建新的段
        for i in 0..<segmentCount {
            let segment = UIView()
            segment.backgroundColor = incompleteColor
            segment.translatesAutoresizingMaskIntoConstraints = false
            addSubview(segment)
            segmentViews.append(segment)

            if showsLabels {
                let label = UILabel()
                label.font = .systemFont(ofSize: 10)
                label.textColor = .secondaryLabel
                label.textAlignment = .center
                label.translatesAutoresizingMaskIntoConstraints = false
                addSubview(label)
                labelViews.append(label)
            }
        }

        updateSegments()
        updateLabels()
        setNeedsLayout()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        let totalSpacing = segmentSpacing * CGFloat(segmentCount - 1)
        let segmentWidth = (bounds.width - totalSpacing) / CGFloat(segmentCount)
        let segmentHeight = bounds.height

        for (index, segment) in segmentViews.enumerated() {
            let x = CGFloat(index) * (segmentWidth + segmentSpacing)
            segment.frame = CGRect(x: x, y: 0, width: segmentWidth, height: segmentHeight)
        }

        if showsLabels {
            for (index, label) in labelViews.enumerated() {
                guard index < segmentViews.count else { break }
                let segment = segmentViews[index]
                label.frame = CGRect(
                    x: segment.frame.minX,
                    y: segment.frame.maxY + 4,
                    width: segment.frame.width,
                    height: 16
                )
            }
        }
    }

    // MARK: - 更新

    private func updateSegments() {
        onSegmentChanged?(currentSegment)

        for (index, segment) in segmentViews.enumerated() {
            if index < currentSegment {
                segment.backgroundColor = completedColor
            } else if index == currentSegment {
                segment.backgroundColor = currentColor
            } else {
                segment.backgroundColor = incompleteColor
            }
        }
    }

    private func updateSegmentColors() {
        updateSegments()
    }

    private func updateLabels() {
        guard showsLabels else { return }

        for (index, label) in labelViews.enumerated() {
            if index < segmentTitles.count {
                label.text = segmentTitles[index]
            }
        }
    }

    private func updateLabelsVisibility() {
        labelViews.forEach { $0.isHidden = !showsLabels }
        setNeedsLayout()
    }

    // MARK: - 公共方法

    /// 前进到下一段
    public func advance() {
        currentSegment += 1
    }

    /// 后退到上一段
    public func retreat() {
        currentSegment -= 1
    }

    /// 跳转到指定段
    public func goToSegment(_ index: Int) {
        currentSegment = index
    }

    /// 重置到第一段
    public func reset() {
        currentSegment = 0
    }
}

// MARK: - LSBufferProgressBar

/// 缓冲进度条（如视频播放）
public class LSBufferProgressBar: LSProgressBar {

    // MARK: - 属性

    /// 缓冲进度 (0.0 - 1.0)
    public var bufferProgress: Float = 0 {
        didSet {
            bufferProgress = max(0, min(1, bufferProgress))
            setNeedsDisplay()
        }
    }

    /// 缓冲颜色
    public var bufferColor: UIColor = .systemGray4 {
        didSet {
            setNeedsDisplay()
        }
    }

    // MARK: - 绘制

    public override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext() else { return }

        // 绘制缓冲进度
        let bufferRect = calculateProgressRect(in: rect)
        let bufferWidth = bufferRect.width * CGFloat(bufferProgress)

        let bufferProgressRect = CGRect(
            x: bufferRect.minX,
            y: bufferRect.minY,
            width: bufferWidth,
            height: bufferRect.height
        )

        bufferColor.setFill()
        bufferProgressRect.fill()
    }
}

// MARK: - UIView Extension (Progress)

public extension UIView {

    private enum AssociatedKeys {
        static var progressBarKey: UInt8 = 0
    }var ls_progressBar: LSProgressBar? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.progressBarKey) as? LSProgressBar
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.progressBarKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// 添加进度条
    @discardableResult
    func ls_addProgressBar(
        height: CGFloat = 4,
        color: UIColor = .systemBlue,
        style: LSProgressBar.Style = .rounded
    ) -> LSProgressBar {
        let progressBar = LSProgressBar()
        progressBar.progressColor = color
        progressBar.style = style
        progressBar.translatesAutoresizingMaskIntoConstraints = false

        addSubview(progressBar)

        NSLayoutConstraint.activate([
            progressBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            progressBar.topAnchor.constraint(equalTo: topAnchor),
            progressBar.heightAnchor.constraint(equalToConstant: height)
        ])

        ls_progressBar = progressBar
        return progressBar
    }

    /// 添加环形进度条
    @discardableResult
    func ls_addCircularProgress(
        size: CGFloat = 60,
        lineWidth: CGFloat = 8,
        color: UIColor = .systemBlue
    ) -> LSCircularProgressView {
        let progressView = LSCircularProgressView()
        progressView.lineWidth = lineWidth
        progressView.progressColor = color
        progressView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(progressView)

        NSLayoutConstraint.activate([
            progressView.centerXAnchor.constraint(equalTo: centerXAnchor),
            progressView.centerYAnchor.constraint(equalTo: centerYAnchor),
            progressView.widthAnchor.constraint(equalToConstant: size),
            progressView.heightAnchor.constraint(equalToConstant: size)
        ])

        return progressView
    }

    /// 添加分段进度条
    @discardableResult
    func ls_addSegmentedProgress(
        segmentCount: Int = 5,
        height: CGFloat = 8
    ) -> LSSegmentedProgressBar {
        let progressBar = LSSegmentedProgressBar(segmentCount: segmentCount)
        progressBar.translatesAutoresizingMaskIntoConstraints = false

        addSubview(progressBar)

        NSLayoutConstraint.activate([
            progressBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            progressBar.topAnchor.constraint(equalTo: topAnchor),
            progressBar.heightAnchor.constraint(equalToConstant: height)
        ])

        return progressBar
    }

    /// 显示进度指示器
    func ls_showProgress(
        message: String? = nil,
        in view: UIView? = nil
    ) -> LSProgressView {
        let targetView
        if let tempTargetview = view {
            targetView = tempTargetview
        } else {
            targetView = self
        }
        let progressView = LSProgressView(frame: targetView.bounds)
        progressView.label.text = message
        targetView.addSubview(progressView)
        return progressView
    }
}

#endif

//
//  LSChartView.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  图表视图 - 简单的图表组件（折线图、柱状图、饼图等）
//

#if canImport(UIKit)
import UIKit

// MARK: - LSChartView

/// 图表视图基类
@MainActor
public class LSChartView: UIView {

    // MARK: - 类型定义

    /// 图表数据点
    public struct DataPoint {
        let value: Double
        let label: String?
        let color: UIColor?

        public init(value: Double, label: String? = nil, color: UIColor? = nil) {
            self.value = value
            self.label = label
            self.color = color
        }
    }

    /// 图表数据系列
    public struct DataSeries {
        let name: String?
        let data: [DataPoint]
        let color: UIColor
        let fillColor: UIColor?

        public init(
            name: String? = nil,
            data: [DataPoint],
            color: UIColor,
            fillColor: UIColor? = nil
        ) {
            self.name = name
            self.data = data
            self.color = color
            self.fillColor = fillColor
        }
    }

    /// 数据点点击回调
    public typealias DataPointHandler = (Int, DataPoint) -> Void

    // MARK: - 属性

    /// 图表标题
    public var chartTitle: String? {
        didSet {
            titleLabel.text = chartTitle
            titleLabel.isHidden = (chartTitle == nil)
        }
    }

    /// 是否显示网格线
    public var showsGridLines: Bool = true {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 是否显示标签
    public var showsLabels: Bool = true {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 网格线颜色
    public var gridLineColor: UIColor = .systemGray4 {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 标签颜色
    public var labelColor: UIColor = .secondaryLabel {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 标签字体
    public var labelFont: UIFont = .systemFont(ofSize: 10) {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 内边距
    public var chartInsets: UIEdgeInsets = UIEdgeInsets(top: 20, left: 40, bottom: 40, right: 20) {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 动画时长
    public var animationDuration: TimeInterval = 0.5

    /// 数据点点击回调
    public var onDataPointTap: DataPointHandler?

    // MARK: - UI 组件

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupChart()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupChart()
    }

    // MARK: - 设置

    private func setupChart() {
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    // MARK: - 绘制

    public override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext() else { return }

        // 绘制网格线
        if showsGridLines {
            drawGridLines(in: rect, context: context)
        }
    }

    internal func drawGridLines(in rect: CGRect, context: CGContext) {
        let chartRect = CGRect(
            x: chartInsets.left,
            y: chartInsets.top + 40,
            width: rect.width - chartInsets.left - chartInsets.right,
            height: rect.height - chartInsets.top - chartInsets.bottom - 40
        )

        gridLineColor.setStroke()

        // 水平网格线
        let horizontalLines = 5
        for i in 0...horizontalLines {
            let y = chartRect.minY + CGFloat(i) * (chartRect.height / CGFloat(horizontalLines))

            context.move(to: CGPoint(x: chartRect.minX, y: y))
            context.addLine(to: CGPoint(x: chartRect.maxX, y: y))
            context.strokePath()
        }

        // 垂直网格线
        let verticalLines = 5
        for i in 0...verticalLines {
            let x = chartRect.minX + CGFloat(i) * (chartRect.width / CGFloat(verticalLines))

            context.move(to: CGPoint(x: x, y: chartRect.minY))
            context.addLine(to: CGPoint(x: x, y: chartRect.maxY))
            context.strokePath()
        }
    }

    internal func getChartRect() -> CGRect {
        return CGRect(
            x: chartInsets.left,
            y: chartInsets.top + 40,
            width: bounds.width - chartInsets.left - chartInsets.right,
            height: bounds.height - chartInsets.top - chartInsets.bottom - 40
        )
    }
}

// MARK: - LSLineChartView

/// 折线图
public class LSLineChartView: LSChartView {

    // MARK: - 属性

    /// 数据系列
    public var dataSeries: [DataSeries] = [] {
        didSet {
            updateChart()
        }
    }

    /// 是否填充区域
    public var fillsArea: Bool = false

    /// 是否显示数据点
    public var showsDataPoints: Bool = true

    /// 数据点半径
    public var dataPointRadius: CGFloat = 4

    /// 线条宽度
    public var lineWidth: CGFloat = 2

    /// 是否平滑曲线
    public var smoothCurves: Bool = true

    // MARK: - 私有属性

    private var dataPointLayers: [CAShapeLayer] = []

    // MARK: - 绘制

    public override func draw(_ rect: CGRect) {
        super.draw(rect)

        let chartRect = getChartRect()

        // 绘制每个数据系列
        for series in dataSeries {
            drawDataSeries(series, in: chartRect)
        }
    }

    private func drawDataSeries(_ series: DataSeries, in rect: CGRect) {
        guard !series.data.isEmpty else { return }

        let maxValue
        if let tempValue = series.data.map { $0.value }.max() {
            maxValue = tempValue
        } else {
            maxValue = 1
        }
        let minValue
        if let tempValue = series.data.map { $0.value }.min() {
            minValue = tempValue
        } else {
            minValue = 0
        }
        let valueRange = maxValue - minValue

        let path = UIBezierPath()
        var points: [CGPoint] = []

        for (index, dataPoint) in series.data.enumerated() {
            let x = rect.minX + CGFloat(index) * (rect.width / CGFloat(series.data.count - 1))
            let normalizedValue = (dataPoint.value - minValue) / (valueRange == 0 ? 1 : valueRange)
            let y = rect.maxY - CGFloat(normalizedValue) * rect.height

            points.append(CGPoint(x: x, y: y))

            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else if smoothCurves {
                let previousPoint = points[index - 1]
                let controlPoint1 = CGPoint(x: previousPoint.x + (x - previousPoint.x) / 2, y: previousPoint.y)
                let controlPoint2 = CGPoint(x: previousPoint.x + (x - previousPoint.x) / 2, y: y)
                path.addCurve(to: CGPoint(x: x, y: y), controlPoint1: controlPoint1, controlPoint2: controlPoint2)
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        // 绘制填充
        if fillsArea, let fillColor = series.fillColor {
            let fillPath = path.copy() as! UIBezierPath
            fillPath.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            fillPath.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            fillPath.close()

            fillColor.setFill()
            fillPath.fill()
        }

        // 绘制线条
        series.color.setStroke()
        path.lineWidth = lineWidth
        path.stroke()

        // 绘制数据点
        if showsDataPoints {
            for point in points {
                let circlePath = UIBezierPath(
                    arcCenter: point,
                    radius: dataPointRadius,
                    startAngle: 0,
                    endAngle: 2 * .pi,
                    clockwise: true
                )
                series.color.setFill()
                circlePath.fill()
            }
        }

        // 绘制标签
        if showsLabels {
            for (index, dataPoint) in series.data.enumerated() {
                guard let label = dataPoint.label else { continue }

                let point = points[index]
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: labelFont,
                    .foregroundColor: labelColor
                ]

                let text = label as NSString
                let textSize = text.size(withAttributes: attributes)
                let textRect = CGRect(
                    x: point.x - textSize.width / 2,
                    y: point.y - textSize.height - dataPointRadius - 4,
                    width: textSize.width,
                    height: textSize.height
                )

                text.draw(in: textRect, withAttributes: attributes)
            }
        }
    }

    private func updateChart() {
        setNeedsDisplay()
    }
}

// MARK: - LSBarChartView

/// 柱状图
public class LSBarChartView: LSChartView {

    // MARK: - 类型定义

    /// 柱状图样式
    public enum BarStyle {
        case vertical        // 垂直
        case horizontal      // 水平
    }

    // MARK: - 属性

    /// 数据系列
    public var dataSeries: [DataSeries] = [] {
        didSet {
            updateChart()
        }
    }

    /// 柱状图样式
    public var barStyle: BarStyle = .vertical

    /// 柱间距
    public var barSpacing: CGFloat = 8

    /// 柱圆角
    public var barCornerRadius: CGFloat = 4

    /// 是否显示数值标签
    public var showsValueLabels: Bool = true

    // MARK: - 绘制

    public override func draw(_ rect: CGRect) {
        super.draw(rect)

        let chartRect = getChartRect()

        if barStyle == .vertical {
            drawVerticalBars(in: chartRect)
        } else {
            drawHorizontalBars(in: chartRect)
        }
    }

    private func drawVerticalBars(in rect: CGRect) {
        guard !dataSeries.isEmpty else { return }

        let allData = dataSeries.flatMap { $0.data }
        let maxValue
        if let tempValue = allData.map { $0.value }.max() {
            maxValue = tempValue
        } else {
            maxValue = 1
        }

        let totalBars = allData.count
        let barWidth = (rect.width - CGFloat(totalBars - 1) * barSpacing) / CGFloat(totalBars)

        var barIndex = 0

        for series in dataSeries {
            for dataPoint in series.data {
                let x = rect.minX + CGFloat(barIndex) * (barWidth + barSpacing)
                let barHeight = CGFloat(dataPoint.value / maxValue) * rect.height
                let y = rect.maxY - barHeight

                let barRect = CGRect(x: x, y: y, width: barWidth, height: barHeight)

                // 绘制柱子
                let path = UIBezierPath(
                    roundedRect: barRect,
                    byRoundingCorners: [.topLeft, .topRight],
                    cornerRadii: CGSize(width: barCornerRadius, height: barCornerRadius)
                )

                let color
                if let tempColor = dataPoint.color {
                    color = tempColor
                } else {
                    color = series.color
                }
                color.setFill()
                path.fill()

                // 绘制数值标签
                if showsValueLabels {
                    let valueText = String(format: "%.1f", dataPoint.value)
                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: labelFont,
                        .foregroundColor: labelColor
                    ]

                    let text = valueText as NSString
                    let textSize = text.size(withAttributes: attributes)
                    let textRect = CGRect(
                        x: x + (barWidth - textSize.width) / 2,
                        y: y - textSize.height - 4,
                        width: textSize.width,
                        height: textSize.height
                    )

                    text.draw(in: textRect, withAttributes: attributes)
                }

                barIndex += 1
            }
        }
    }

    private func drawHorizontalBars(in rect: CGRect) {
        guard !dataSeries.isEmpty else { return }

        let allData = dataSeries.flatMap { $0.data }
        let maxValue
        if let tempValue = allData.map { $0.value }.max() {
            maxValue = tempValue
        } else {
            maxValue = 1
        }

        let totalBars = allData.count
        let barHeight = (rect.height - CGFloat(totalBars - 1) * barSpacing) / CGFloat(totalBars)

        var barIndex = 0

        for series in dataSeries {
            for dataPoint in series.data {
                let y = rect.minY + CGFloat(barIndex) * (barHeight + barSpacing)
                let barWidth = CGFloat(dataPoint.value / maxValue) * rect.width

                let barRect = CGRect(x: rect.minX, y: y, width: barWidth, height: barHeight)

                // 绘制柱子
                let path = UIBezierPath(
                    roundedRect: barRect,
                    byRoundingCorners: [.topLeft, .bottomLeft],
                    cornerRadii: CGSize(width: barCornerRadius, height: barCornerRadius)
                )

                let color
                if let tempColor = dataPoint.color {
                    color = tempColor
                } else {
                    color = series.color
                }
                color.setFill()
                path.fill()

                // 绘制数值标签
                if showsValueLabels {
                    let valueText = String(format: "%.1f", dataPoint.value)
                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: labelFont,
                        .foregroundColor: labelColor
                    ]

                    let text = valueText as NSString
                    let textSize = text.size(withAttributes: attributes)
                    let textRect = CGRect(
                        x: rect.minX + barWidth + 4,
                        y: y + (barHeight - textSize.height) / 2,
                        width: textSize.width,
                        height: textSize.height
                    )

                    text.draw(in: textRect, withAttributes: attributes)
                }

                barIndex += 1
            }
        }
    }

    private func updateChart() {
        setNeedsDisplay()
    }
}

// MARK: - LSPieChartView

/// 饼图
public class LSPieChartView: LSChartView {

    // MARK: - 属性

    /// 数据
    public var data: [DataPoint] = [] {
        didSet {
            updateChart()
        }
    }

    /// 是否空心（环形图）
    public var isHollow: Bool = false

    /// 空心半径比例
    public var hollowRatio: CGFloat = 0.5

    /// 是否显示百分比标签
    public var showsPercentageLabels: Bool = true

    /// 默认颜色
    public var defaultColors: [UIColor] = [
        .systemBlue, .systemGreen, .systemOrange, .systemRed,
        .systemPurple, .systemYellow, .systemPink, .systemTeal
    ]

    // MARK: - 绘制

    public override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard !data.isEmpty else { return }

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - chartInsets.left

        let totalValue = data.reduce(0) { $0 + $1.value }
        var startAngle: CGFloat = -.pi / 2

        for (index, dataPoint) in data.enumerated() {
            let sliceAngle = CGFloat(dataPoint.value / totalValue) * 2 * .pi
            let endAngle = startAngle + sliceAngle

            let color
            if let tempColor = dataPoint.color {
                color = tempColor
            } else {
                color = defaultColors[index % defaultColors.count]
            }

            // 绘制扇形
            let path = UIBezierPath()
            path.move(to: center)

            if isHollow {
                // 环形图
                let innerRadius = radius * hollowRatio
                let outerPath = UIBezierPath(
                    arcCenter: center,
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: true
                )
                let innerPath = UIBezierPath(
                    arcCenter: center,
                    radius: innerRadius,
                    startAngle: endAngle,
                    endAngle: startAngle,
                    clockwise: false
                )

                path.append(outerPath)
                path.append(innerPath)
            } else {
                // 饼图
                path.addArc(
                    withCenter: center,
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: true
                )
            }

            path.close()

            color.setFill()
            path.fill()

            // 绘制标签
            if showsPercentageLabels {
                let midAngle = startAngle + sliceAngle / 2
                let labelRadius = isHollow ? radius * (1 + hollowRatio) / 2 : radius * 0.7
                let labelX = center.x + labelRadius * cos(midAngle)
                let labelY = center.y + labelRadius * sin(midAngle)

                let percentage = dataPoint.value / totalValue * 100
                let percentageText = String(format: "%.1f%%", percentage)

                let attributes: [NSAttributedString.Key: Any] = [
                    .font: labelFont,
                    .foregroundColor: .white
                ]

                let text = percentageText as NSString
                let textSize = text.size(withAttributes: attributes)
                let textRect = CGRect(
                    x: labelX - textSize.width / 2,
                    y: labelY - textSize.height / 2,
                    width: textSize.width,
                    height: textSize.height
                )

                text.draw(in: textRect, withAttributes: attributes)
            }

            startAngle = endAngle
        }
    }

    private func updateChart() {
        setNeedsDisplay()
    }
}

// MARK: - LSRingProgressView

/// 环形进度图
public class LSRingProgressView: LSChartView {

    // MARK: - 属性

    /// 进度值 (0.0 - 1.0)
    public var progress: Float = 0 {
        didSet {
            progress = max(0, min(1, progress))
            setNeedsDisplay()
        }
    }

    /// 进度颜色
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

    /// 线条宽度
    public var lineWidth: CGFloat = 10 {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 是否显示百分比
    public var showsPercentage: Bool = true {
        didSet {
            percentageLabel.isHidden = !showsPercentage
        }
    }

    // MARK: - UI 组件

    private let percentageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupRing()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupRing()
    }

    // MARK: - 设置

    private func setupRing() {
        addSubview(percentageLabel)

        NSLayoutConstraint.activate([
            percentageLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            percentageLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    // MARK: - 绘制

    public override func draw(_ rect: CGRect) {
        super.draw(rect)

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - lineWidth / 2 - chartInsets.left

        // 绘制轨道
        let trackPath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: -.pi / 2 + 2 * .pi,
            clockwise: true
        )
        trackPath.lineWidth = lineWidth
        trackColor.setStroke()
        trackPath.stroke()

        // 绘制进度
        let progressAngle = CGFloat(progress) * 2 * .pi
        let progressPath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: -.pi / 2 + progressAngle,
            clockwise: true
        )
        progressPath.lineWidth = lineWidth
        progressColor.setStroke()
        progressPath.stroke()

        // 更新标签
        percentageLabel.text = String(format: "%.0f%%", progress * 100)
        percentageLabel.textColor = progressColor
    }
}

// MARK: - Convenience Factory

public extension LSChartView {

    /// 创建折线图
    static func lineChart(dataSeries: [DataSeries] = []) -> LSLineChartView {
        let chart = LSLineChartView()
        chart.dataSeries = dataSeries
        return chart
    }

    /// 创建柱状图
    static func barChart(dataSeries: [DataSeries] = [], style: LSBarChartView.BarStyle = .vertical) -> LSBarChartView {
        let chart = LSBarChartView()
        chart.dataSeries = dataSeries
        chart.barStyle = style
        return chart
    }

    /// 创建饼图
    static func pieChart(data: [DataPoint] = []) -> LSPieChartView {
        let chart = LSPieChartView()
        chart.data = data
        return chart
    }

    /// 创建环形进度图
    static func ringProgress(progress: Float = 0) -> LSRingProgressView {
        let chart = LSRingProgressView()
        chart.progress = progress
        return chart
    }
}

// MARK: - UIView Extension (Chart)

public extension UIView {

    /// 关联的图表视图
    private static var chartViewKey: UInt8 = 0

    var ls_chartView: LSChartView? {
        get {
            return objc_getAssociatedObject(self, &UIView.chartViewKey) as? LSChartView
        }
        set {
            objc_setAssociatedObject(
                self,
                &UIView.chartViewKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// 添加折线图
    @discardableResult
    func ls_addLineChart(
        dataSeries: [LSChartView.DataSeries],
        height: CGFloat = 200
    ) -> LSLineChartView {
        let chart = LSLineChartView.lineChart(dataSeries: dataSeries)
        chart.translatesAutoresizingMaskIntoConstraints = false

        addSubview(chart)

        NSLayoutConstraint.activate([
            chart.topAnchor.constraint(equalTo: topAnchor),
            chart.leadingAnchor.constraint(equalTo: leadingAnchor),
            chart.trailingAnchor.constraint(equalTo: trailingAnchor),
            chart.heightAnchor.constraint(equalToConstant: height)
        ])

        ls_chartView = chart
        return chart
    }

    /// 添加柱状图
    @discardableResult
    func ls_addBarChart(
        dataSeries: [LSChartView.DataSeries],
        height: CGFloat = 200,
        style: LSBarChartView.BarStyle = .vertical
    ) -> LSBarChartView {
        let chart = LSBarChartView.barChart(dataSeries: dataSeries, style: style)
        chart.translatesAutoresizingMaskIntoConstraints = false

        addSubview(chart)

        NSLayoutConstraint.activate([
            chart.topAnchor.constraint(equalTo: topAnchor),
            chart.leadingAnchor.constraint(equalTo: leadingAnchor),
            chart.trailingAnchor.constraint(equalTo: trailingAnchor),
            chart.heightAnchor.constraint(equalToConstant: height)
        ])

        ls_chartView = chart
        return chart
    }

    /// 添加饼图
    @discardableResult
    func ls_addPieChart(
        data: [LSChartView.DataPoint],
        size: CGFloat = 200
    ) -> LSPieChartView {
        let chart = LSPieChartView.pieChart(data: data)
        chart.translatesAutoresizingMaskIntoConstraints = false

        addSubview(chart)

        NSLayoutConstraint.activate([
            chart.centerXAnchor.constraint(equalTo: centerXAnchor),
            chart.centerYAnchor.constraint(equalTo: centerYAnchor),
            chart.widthAnchor.constraint(equalToConstant: size),
            chart.heightAnchor.constraint(equalToConstant: size)
        ])

        ls_chartView = chart
        return chart
    }

    /// 添加环形进度图
    @discardableResult
    func ls_addRingProgress(
        progress: Float = 0,
        size: CGFloat = 100
    ) -> LSRingProgressView {
        let chart = LSRingProgressView.ringProgress(progress: progress)
        chart.translatesAutoresizingMaskIntoConstraints = false

        addSubview(chart)

        NSLayoutConstraint.activate([
            chart.centerXAnchor.constraint(equalTo: centerXAnchor),
            chart.centerYAnchor.constraint(equalTo: centerYAnchor),
            chart.widthAnchor.constraint(equalToConstant: size),
            chart.heightAnchor.constraint(equalToConstant: size)
        ])

        return chart
    }
}

#endif

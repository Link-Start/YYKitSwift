//
//  LSSlider.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  增强的滑块 - 提供更多样式和功能
//

#if canImport(UIKit)
import UIKit

// MARK: - LSSlider

/// 增强的滑块
@MainActor
public class LSSlider: UIView {

    // MARK: - 类型定义

    /// 值变化回调
    public typealias ValueChangeHandler = (Float) -> Void

    /// 滑块样式
    public enum SliderStyle {
        case defaultStyle
        case rounded
        case circular
    }

    // MARK: - 属性

    /// 最小值
    public var minimumValue: Float = 0 {
        didSet {
            updateValue()
        }
    }

    /// 最大值
    public var maximumValue: Float = 100 {
        didSet {
            updateValue()
        }
    }

    /// 当前值
    public var value: Float = 50 {
        didSet {
            updateValue()
            onValueChanged?(value)
        }
    }

    /// 样式
    public var style: SliderStyle = .defaultStyle {
        didSet {
            updateStyle()
        }
    }

    /// 轨道颜色
    public var trackColor: UIColor = .systemGray4 {
        didSet {
            trackView.backgroundColor = trackColor
        }
    }

    /// 进度颜色
    public var progressColor: UIColor = .systemBlue {
        didSet {
            progressView.backgroundColor = progressColor
        }
    }

    /// 滑块颜色
    public var thumbColor: UIColor = .white {
        didSet {
            thumbView.backgroundColor = thumbColor
        }
    }

    /// 滑块大小
    public var thumbSize: CGSize = CGSize(width: 24, height: 24) {
        didSet {
            updateThumbSize()
        }
    }

    /// 轨道高度
    public var trackHeight: CGFloat = 4 {
        didSet {
            updateTrackHeight()
        }
    }

    /// 是否显示标签
    public var showsLabel: Bool = false {
        didSet {
            valueLabel.isHidden = !showsLabel
        }
    }

    /// 是否显示最小最大值
    public var showsMinMaxLabels: Bool = false {
        didSet {
            updateMinMaxLabels()
        }
    }

    /// 值变化回调
    public var onValueChanged: ValueChangeHandler?

    /// 是否正在拖动
    public private(set) var isDragging: Bool = false

    // MARK: - UI 组件

    private let trackView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let progressView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let thumbView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowOpacity = 0.2
        view.layer.shadowRadius = 2
        return view
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    private let minLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    private let maxLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSlider()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSlider()
    }

    public init(
        minimumValue: Float = 0,
        maximumValue: Float = 100,
        value: Float = 50
    ) {
        self.minimumValue = minimumValue
        self.maximumValue = maximumValue
        self.value = value
        super.init(frame: .zero)
        setupSlider()
    }

    // MARK: - 设置

    private func setupSlider() {
        addSubview(trackView)
        addSubview(progressView)
        addSubview(thumbView)
        addSubview(valueLabel)
        addSubview(minLabel)
        addSubview(maxLabel)

        NSLayoutConstraint.activate([
            trackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            trackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            trackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            trackView.heightAnchor.constraint(equalToConstant: trackHeight),

            progressView.centerYAnchor.constraint(equalTo: centerYAnchor),
            progressView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            progressView.heightAnchor.constraint(equalToConstant: trackHeight),

            thumbView.centerYAnchor.constraint(equalTo: centerYAnchor),
            thumbView.widthAnchor.constraint(equalToConstant: thumbSize.width),
            thumbView.heightAnchor.constraint(equalToConstant: thumbSize.height),

            valueLabel.bottomAnchor.constraint(equalTo: thumbView.topAnchor, constant: -8),
            valueLabel.centerXAnchor.constraint(equalTo: thumbView.centerXAnchor),

            minLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            minLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),

            maxLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            maxLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0)
        ])

        trackView.layer.cornerRadius = trackHeight / 2
        progressView.layer.cornerRadius = trackHeight / 2

        // 添加拖动手势
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        addGestureRecognizer(panGesture)

        updateStyle()
        updateValue()
    }

    // MARK: - 更新

    private func updateStyle() {
        switch style {
        case .defaultStyle:
            thumbView.layer.cornerRadius = thumbSize.width / 2
            trackView.layer.cornerRadius = trackHeight / 2
            progressView.layer.cornerRadius = trackHeight / 2

        case .rounded:
            thumbView.layer.cornerRadius = thumbSize.width / 2
            trackView.layer.cornerRadius = trackHeight / 2
            progressView.layer.cornerRadius = trackHeight / 2

        case .circular:
            thumbView.layer.cornerRadius = thumbSize.width / 2
            trackView.layer.cornerRadius = trackHeight / 2
            progressView.layer.cornerRadius = trackHeight / 2
        }
    }

    private func updateValue() {
        let clampedValue = max(minimumValue, min(maximumValue, value))
        let percentage = CGFloat((clampedValue - minimumValue) / (maximumValue - minimumValue))

        let trackWidth = trackView.bounds.width
        let progressWidth = trackWidth * percentage

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        progressView.bounds.size.width = progressWidth
        thumbView.center.x = trackView.frame.origin.x + progressWidth
        CATransaction.commit()

        if showsLabel {
            valueLabel.text = String(format: "%.0f", clampedValue)
        }
    }

    private func updateThumbSize() {
        thumbView.constraints.forEach { constraint in
            if constraint.firstAttribute == .width {
                constraint.constant = thumbSize.width
            } else if constraint.firstAttribute == .height {
                constraint.constant = thumbSize.height
            }
        }

        thumbView.layer.cornerRadius = thumbSize.width / 2
    }

    private func updateTrackHeight() {
        trackView.constraints.forEach { constraint in
            if constraint.firstAttribute == .height {
                constraint.constant = trackHeight
            }
        }

        progressView.constraints.forEach { constraint in
            if constraint.firstAttribute == .height {
                constraint.constant = trackHeight
            }
        }

        trackView.layer.cornerRadius = trackHeight / 2
        progressView.layer.cornerRadius = trackHeight / 2
    }

    private func updateMinMaxLabels() {
        minLabel.isHidden = !showsMinMaxLabels
        maxLabel.isHidden = !showsMinMaxLabels

        if showsMinMaxLabels {
            minLabel.text = String(format: "%.0f", minimumValue)
            maxLabel.text = String(format: "%.0f", maximumValue)
        }
    }

    // MARK: - 手势处理

    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)

        switch gesture.state {
        case .began:
            isDragging = true

        case .changed:
            let trackWidth = trackView.bounds.width
            let offset = location.x - trackView.frame.origin.x
            let percentage = max(0, min(1, offset / trackWidth))

            value = minimumValue + Float(percentage) * (maximumValue - minimumValue)

        case .ended, .cancelled:
            isDragging = true

        default:
            break
        }
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        let trackWidth = trackView.bounds.width
        let offset = location.x - trackView.frame.origin.x
        let percentage = max(0, min(1, offset / trackWidth))

        value = minimumValue + Float(percentage) * (maximumValue - minimumValue)
    }

    // MARK: - 公共方法

    /// 设置值
    public func setValue(_ value: Float, animated: Bool = false) {
        guard animated else {
            self.value = value
            return
        }

        UIView.animate(withDuration: 0.3) {
            self.value = value
        }
    }
}

// MARK: - UISlider Extension

public extension UISlider {

    /// 设置轨道颜色
    func ls_setTrackColor(_ color: UIColor) {
        if #available(iOS 13.0, *) {
            let appearance = standardAppearance.copy()
            appearance.normalTrackTintColor = color
            standardAppearance = appearance
        } else {
            minimumTrackTintColor = color
            maximumTrackTintColor = color
        }
    }

    /// 设置进度颜色
    func ls_setProgressColor(_ color: UIColor) {
        if #available(iOS 13.0, *) {
            let appearance = standardAppearance.copy()
            normalTrackTintColor = color
            standardAppearance = appearance
        } else {
            minimumTrackTintColor = color
        }
    }

    /// 设置滑块颜色
    func ls_setThumbColor(_ color: UIColor) {
        if #available(iOS 13.0, *) {
            let appearance = standardAppearance.copy()
            normalThumbTintColor = color
            standardAppearance = appearance
        } else {
            thumbTintColor = color
        }
    }

    /// 设置滑块图片
    func ls_setThumbImage(_ image: UIImage?, for state: UIControl.State = .normal) {
        setThumbImage(image, for: state)
    }

    /// 设置轨道图片
    func ls_setTrackImage(
        minimumTrackImage: UIImage?,
        maximumTrackImage: UIImage?,
        for state: UIControl.State = .normal
    ) {
        setMinimumTrackImage(minimumTrackImage, for: state)
        setMaximumTrackImage(maximumTrackImage, for: state)
    }

    /// 设置样式
    func ls_applyStyle(
        trackColor: UIColor = .systemGray4,
        progressColor: UIColor = .systemBlue,
        thumbColor: UIColor = .white
    ) {
        if #available(iOS 13.0, *) {
            let appearance = standardAppearance.copy()
            normalTrackTintColor = trackColor
            normalThumbTintColor = thumbColor
            standardAppearance = appearance

            minimumTrackTintColor = progressColor
        } else {
            minimumTrackTintColor = progressColor
            maximumTrackTintColor = trackColor
            thumbTintColor = thumbColor
        }
    }

    /// 添加左右图标
    func ls_setSideImages(
        leftImage: UIImage?,
        rightImage: UIImage?,
        leftPadding: CGFloat = 8,
        rightPadding: CGFloat = 8
    ) {
        // 可以通过添加 UIImageView 来实现
    }

    /// 添加标签显示值
    func ls_showValueLabel() -> UILabel {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .label
        label.textAlignment = .center

        // 关联到滑块
        let key = AssociatedKey.valueLabelKey
        objc_setAssociatedObject(self, key, label, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        addTarget(self, action: #selector(updateValueLabel), for: .valueChanged)

        return label
    }

    @objc private func updateValueLabel() {
        let key = AssociatedKey.valueLabelKey
        let label = objc_getAssociatedObject(self, key) as? UILabel
        label?.text = String(format: "%.0f", value)
    }

    /// 值文字（只读）
    var ls_valueText: String {
        return String(format: "%.0f", value)
    }

    /// 格式化值
    func ls_formattedValue(format: String = "%.1f") -> String {
        return String(format: format, value)
    }

    /// 值百分比
    var ls_valuePercentage: Float {
        guard maximumValue > minimumValue else { return 0 }
        return (value - minimumValue) / (maximumValue - minimumValue)
    }

    /// 设置值百分比
    func ls_setValuePercentage(_ percentage: Float, animated: Bool = false) {
        let newValue = minimumValue + percentage * (maximumValue - minimumValue)
        setValue(newValue, animated: animated)
    }
}

// MARK: - Range Slider

/// 范围滑块
public class LSRangeSlider: UIView {

    /// 范围变化回调
    public typealias RangeChangeHandler = (Float, Float) -> Void

    /// 最小值
    public var minimumValue: Float = 0 {
        didSet {
            updateRange()
        }
    }

    /// 最大值
    public var maximumValue: Float = 100 {
        didSet {
            updateRange()
        }
    }

    /// 当前最小值
    public var lowerValue: Float = 25 {
        didSet {
            updateRange()
            onRangeChanged?(lowerValue, upperValue)
        }
    }

    /// 当前最大值
    public var upperValue: Float = 75 {
        didSet {
            updateRange()
            onRangeChanged?(lowerValue, upperValue)
        }
    }

    /// 轨道颜色
    public var trackColor: UIColor = .systemGray4 {
        didSet {
            trackView.backgroundColor = trackColor
        }
    }

    /// 进度颜色
    public var progressColor: UIColor = .systemBlue {
        didSet {
            progressView.backgroundColor = progressColor
        }
    }

    /// 滑块颜色
    public var thumbColor: UIColor = .white {
        didSet {
            leftThumbView.backgroundColor = thumbColor
            rightThumbView.backgroundColor = thumbColor
        }
    }

    /// 最小间距
    public var minimumDistance: Float = 0

    /// 范围变化回调
    public var onRangeChanged: RangeChangeHandler?

    // MARK: - UI 组件

    private let trackView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let progressView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let leftThumbView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowOpacity = 0.2
        view.layer.shadowRadius = 2
        return view
    }()

    private let rightThumbView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowOpacity = 0.2
        view.layer.shadowRadius = 2
        return view
    }()

    private let thumbSize: CGFloat = 24
    private let trackHeight: CGFloat = 4

    private var draggingThumb: Thumb?

    private enum Thumb {
        case left
        case right
    }

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupRangeSlider()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupRangeSlider()
    }

    private func setupRangeSlider() {
        addSubview(trackView)
        addSubview(progressView)
        addSubview(leftThumbView)
        addSubview(rightThumbView)

        NSLayoutConstraint.activate([
            trackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            trackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            trackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            trackView.heightAnchor.constraint(equalToConstant: trackHeight),

            progressView.centerYAnchor.constraint(equalTo: centerYAnchor),
            progressView.heightAnchor.constraint(equalToConstant: trackHeight),

            leftThumbView.centerYAnchor.constraint(equalTo: centerYAnchor),
            leftThumbView.widthAnchor.constraint(equalToConstant: thumbSize),
            leftThumbView.heightAnchor.constraint(equalToConstant: thumbSize),

            rightThumbView.centerYAnchor.constraint(equalTo: centerYAnchor),
            rightThumbView.widthAnchor.constraint(equalToConstant: thumbSize),
            rightThumbView.heightAnchor.constraint(equalToConstant: thumbSize)
        ])

        trackView.layer.cornerRadius = trackHeight / 2
        progressView.layer.cornerRadius = trackHeight / 2
        leftThumbView.layer.cornerRadius = thumbSize / 2
        rightThumbView.layer.cornerRadius = thumbSize / 2

        // 添加手势
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        addGestureRecognizer(panGesture)

        updateRange()
    }

    // MARK: - 更新

    private func updateRange() {
        let range = maximumValue - minimumValue
        let lowerPercentage = CGFloat((lowerValue - minimumValue) / range)
        let upperPercentage = CGFloat((upperValue - minimumValue) / range)

        let trackWidth = trackView.bounds.width
        let lowerX = trackWidth * lowerPercentage
        let upperX = trackWidth * upperPercentage

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        progressView.frame.origin.x = trackView.frame.origin.x + lowerX
        progressView.bounds.size.width = max(0, upperX - lowerX)

        leftThumbView.center.x = trackView.frame.origin.x + lowerX
        rightThumbView.center.x = trackView.frame.origin.x + upperX

        CATransaction.commit()
    }

    // MARK: - 手势处理

    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)
        let trackWidth = trackView.bounds.width

        switch gesture.state {
        case .began:
            // 判断拖动哪个滑块
            let leftDistance = abs(location.x - leftThumbView.center.x)
            let rightDistance = abs(location.x - rightThumbView.center.x)

            if leftDistance < rightDistance {
                draggingThumb = .left
            } else {
                draggingThumb = .right
            }

        case .changed:
            guard let thumb = draggingThumb else { return }

            let offset = location.x - trackView.frame.origin.x
            let percentage = max(0, min(1, offset / trackWidth))
            let value = minimumValue + Float(percentage) * (maximumValue - minimumValue)

            switch thumb {
            case .left:
                let clampedValue = min(value, upperValue - minimumDistance)
                lowerValue = max(minimumValue, clampedValue)

            case .right:
                let clampedValue = max(value, lowerValue + minimumDistance)
                upperValue = min(maximumValue, clampedValue)
            }

        case .ended, .cancelled:
            draggingThumb = nil

        default:
            break
        }
    }

    // MARK: - 公共方法

    /// 设置范围
    public func setRange(lower: Float, upper: Float, animated: Bool = false) {
        guard animated else {
            lowerValue = lower
            upperValue = upper
            return
        }

        UIView.animate(withDuration: 0.3) {
            self.lowerValue = lower
            self.upperValue = upper
        }
    }
}

// MARK: - Associated Keys

private struct AssociatedKey {
    static var valueLabelKey: UInt8 = 0
}

#endif

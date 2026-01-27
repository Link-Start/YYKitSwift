//
//  LSStepper.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  增强的步进器 - 提供更多样式和功能
//

#if canImport(UIKit)
import UIKit

// MARK: - LSStepper

/// 增强的步进器
public class LSStepper: UIView {

    // MARK: - 类型定义

    /// 值变化回调
    public typealias ValueChangeHandler = (Double) -> Void

    /// 步进器样式
    public enum StepperStyle {
        case defaultStyle
        case rounded
        case flat
    }

    // MARK: - 属性

    /// 当前值
    public var value: Double = 0 {
        didSet {
            updateDisplay()
            onValueChanged?(value)
        }
    }

    /// 最小值
    public var minimumValue: Double = 0 {
        didSet {
            updateButtonStates()
        }
    }

    /// 最大值
    public var maximumValue: Double = 100 {
        didSet {
            updateButtonStates()
        }
    }

    /// 步长
    public var stepValue: Double = 1

    /// 是否自动重复
    public var autorepeat: Bool = true

    /// 是否连续
    public var isContinuous: Bool = true

    /// 自动重复间隔
    public var autorepeatInterval: TimeInterval = 0.5

    /// 样式
    public var style: StepperStyle = .defaultStyle {
        didSet {
            updateStyle()
        }
    }

    /// 按钮颜色
    public var buttonColor: UIColor = .systemBlue {
        didSet {
            updateColors()
        }
    }

    /// 背景颜色
    public var backgroundColor: UIColor = .systemGray5 {
        didSet {
            container.backgroundColor = backgroundColor
        }
    }

    /// 文字颜色
    public var textColor: UIColor = .label {
        didSet {
            valueLabel.textColor = textColor
        }
    }

    /// 字体
    public var font: UIFont = .systemFont(ofSize: 16) {
        didSet {
            valueLabel.font = font
        }
    }

    /// 是否显示标签
    public var showsLabel: Bool = true {
        didSet {
            valueLabel.isHidden = !showsLabel
        }
    }

    /// 标签格式
    public var labelFormat: String = "%.0f" {
        didSet {
            updateLabel()
        }
    }

    /// 值变化回调
    public var onValueChanged: ValueChangeHandler?

    // MARK: - UI 组件

    private let container: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.masksToBounds = true
        return view
    }()

    private let minusButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("−", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 24)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let plusButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("+", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 24)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let divider1: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let divider2: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - 定时器

    private var repeatTimer: Timer?

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupStepper()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupStepper()
    }

    public init(
        minimumValue: Double = 0,
        maximumValue: Double = 100,
        value: Double = 0,
        stepValue: Double = 1
    ) {
        self.minimumValue = minimumValue
        self.maximumValue = maximumValue
        self.value = value
        self.stepValue = stepValue
        super.init(frame: .zero)
        setupStepper()
    }

    // MARK: - 设置

    private func setupStepper() {
        addSubview(container)
        container.addSubview(minusButton)
        container.addSubview(plusButton)
        container.addSubview(valueLabel)
        container.addSubview(divider1)
        container.addSubview(divider2)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            container.heightAnchor.constraint(equalToConstant: 44),

            minusButton.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            minusButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            minusButton.widthAnchor.constraint(equalToConstant: 44),

            plusButton.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            plusButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            plusButton.widthAnchor.constraint(equalToConstant: 44),

            valueLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            valueLabel.leadingAnchor.constraint(equalTo: minusButton.trailingAnchor, constant: 8),
            valueLabel.trailingAnchor.constraint(equalTo: plusButton.trailingAnchor, constant: -8),

            divider1.leadingAnchor.constraint(equalTo: minusButton.trailingAnchor),
            divider1.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            divider1.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
            divider1.widthAnchor.constraint(equalToConstant: 0.5),

            divider2.leadingAnchor.constraint(equalTo: valueLabel.trailingAnchor),
            divider2.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            divider2.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
            divider2.widthAnchor.constraint(equalToConstant: 0.5)
        ])

        // 按钮事件
        minusButton.ls_addAction(for: .touchDown) { [weak self] _ in
            self?.handleMinusDown()
        }

        minusButton.ls_addAction(for: [.touchUpOutside, .touchUpInside]) { [weak self] _ in
            self?.handleButtonUp()
        }

        plusButton.ls_addAction(for: .touchDown) { [weak self] _ in
            self?.handlePlusDown()
        }

        plusButton.ls_addAction(for: [.touchUpOutside, .touchUpInside]) { [weak self] _ in
            self?.handleButtonUp()
        }

        updateStyle()
        updateDisplay()
        updateButtonStates()
    }

    // MARK: - 更新

    private func updateStyle() {
        switch style {
        case .defaultStyle:
            container.layer.cornerRadius = 8
            container.backgroundColor = backgroundColor

        case .rounded:
            container.layer.cornerRadius = 22
            container.backgroundColor = backgroundColor

        case .flat:
            container.layer.cornerRadius = 0
            container.backgroundColor = .clear
        }

        updateColors()
    }

    private func updateColors() {
        minusButton.tintColor = buttonColor
        plusButton.tintColor = buttonColor
        valueLabel.textColor = textColor
    }

    private func updateDisplay() {
        valueLabel.text = String(format: labelFormat, value)
        updateButtonStates()
    }

    private func updateLabel() {
        valueLabel.text = String(format: labelFormat, value)
    }

    private func updateButtonStates() {
        minusButton.isEnabled = value > minimumValue
        plusButton.isEnabled = value < maximumValue

        minusButton.alpha = minusButton.isEnabled ? 1.0 : 0.3
        plusButton.alpha = plusButton.isEnabled ? 1.0 : 0.3
    }

    // MARK: - 按钮处理

    private func handleMinusDown() {
        decrementValue()

        if autorepeat {
            startRepeatTimer(decrementValue)
        }
    }

    private func handlePlusDown() {
        incrementValue()

        if autorepeat {
            startRepeatTimer(incrementValue)
        }
    }

    private func handleButtonUp() {
        stopRepeatTimer()
    }

    private func incrementValue() {
        let newValue = min(value + stepValue, maximumValue)
        value = newValue
    }

    private func decrementValue() {
        let newValue = max(value - stepValue, minimumValue)
        value = newValue
    }

    // MARK: - 定时器

    private func startRepeatTimer(_ action: @escaping () -> Void) {
        repeatTimer?.invalidate()

        // 立即执行一次
        action()

        // 延迟后开始重复
        DispatchQueue.main.asyncAfter(deadline: .now() + autorepeatInterval) { [weak self] in
            self.repeatTimer = Timer.scheduledTimer(
                withTimeInterval: 0.1,
                repeats: true
            ) { [weak self] _ in
                if self?.isContinuous ?? true {
                    action()
                }
            }
        }
    }

    private func stopRepeatTimer() {
        repeatTimer?.invalidate()
        repeatTimer = nil
    }

    // MARK: - 公共方法

    /// 设置值
    public func setValue(_ value: Double, animated: Bool = false) {
        guard animated else {
            self.value = value
            return
        }

        UIView.animate(withDuration: 0.2) {
            self.value = value
        }
    }

    /// 增加值
    public func increment() {
        incrementValue()
    }

    /// 减少值
    public func decrement() {
        decrementValue()
    }

    deinit {
        stopRepeatTimer()
    }
}

// MARK: - UIStepper Extension

public extension UIStepper {

    /// 设置样式
    func ls_applyStyle(
        tintColor: UIColor = .systemBlue,
        backgroundColor: UIColor = .systemGray5
    ) {
        if #available(iOS 13.0, *) {
            let appearance = UIStepperAppearance()
            appearance.backgroundColor = backgroundColor
            standardAppearance = appearance
        }

        self.tintColor = tintColor
    }

    /// 设置圆角
    func ls_setRounded(cornerRadius: CGFloat = 8) {
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true
    }

    /// 值变化监听
    func ls_onValueChanged(_ handler: @escaping (Double) -> Void) {
        let key = AssociatedKey.valueChangeHandlerKey
        objc_setAssociatedObject(self, key, handler, .OBJC_ASSOCIATION_COPY_NONATOMIC)

        addTarget(self, action: #selector(handleValueChanged), for: .valueChanged)
    }

    @objc private func handleValueChanged() {
        let key = AssociatedKey.valueChangeHandlerKey
        let handler = objc_getAssociatedObject(self, key) as? ((Double) -> Void)
        handler?(value)
    }

    /// 格式化值文本
    var ls_formattedValue: String {
        return String(format: "%.0f", value)
    }

    /// 是否为最小值
    var ls_isAtMinimum: Bool {
        return value == minimumValue
    }

    /// 是否为最大值
    var ls_isAtMaximum: Bool {
        return value == maximumValue
    }

    /// 值百分比
    var ls_valuePercentage: Double {
        guard maximumValue > minimumValue else { return 0 }
        return (value - minimumValue) / (maximumValue - minimumValue)
    }

    /// 设置值百分比
    func ls_setValuePercentage(_ percentage: Double, animated: Bool = false) {
        let newValue = minimumValue + percentage * (maximumValue - minimumValue)
        setValue(newValue, animated: animated)
    }

    /// 重置为最小值
    func ls_reset() {
        value = minimumValue
    }
}

// MARK: - Counter View

/// 计数器视图
public class LSCounterView: UIView {

    /// 值变化回调
    public typealias ValueChangeHandler = (Int) -> Void

    /// 当前值
    public private(set) var value: Int = 0 {
        didSet {
            updateDisplay()
            onValueChanged?(value)
        }
    }

    /// 最小值
    public var minimumValue: Int = 0

    /// 最大值
    public var maximumValue: Int = 99

    /// 步长
    public var stepValue: Int = 1

    /// 按钮颜色
    public var buttonColor: UIColor = .systemBlue {
        didSet {
            updateColors()
        }
    }

    /// 背景颜色
    public var backgroundColor: UIColor = .systemGray6 {
        didSet {
            container.backgroundColor = backgroundColor
        }
    }

    /// 值变化回调
    public var onValueChanged: ValueChangeHandler?

    // MARK: - UI 组件

    private let container: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 8
        return view
    }()

    private let minusButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("−", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 20)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let plusButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("+", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 20)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupCounter()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCounter()
    }

    public init(value: Int = 0, minimum: Int = 0, maximum: Int = 99) {
        self.value = value
        self.minimumValue = minimum
        self.maximumValue = maximum
        super.init(frame: .zero)
        setupCounter()
    }

    // MARK: - 设置

    private func setupCounter() {
        addSubview(container)
        container.addSubview(minusButton)
        container.addSubview(plusButton)
        container.addSubview(valueLabel)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            container.heightAnchor.constraint(equalToConstant: 40),

            minusButton.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            minusButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            minusButton.widthAnchor.constraint(equalToConstant: 44),

            plusButton.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            plusButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            plusButton.widthAnchor.constraint(equalToConstant: 44),

            valueLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            valueLabel.leadingAnchor.constraint(equalTo: minusButton.trailingAnchor, constant: 8),
            valueLabel.trailingAnchor.constraint(equalTo: plusButton.trailingAnchor, constant: -8)
        ])

        minusButton.ls_addAction(for: .touchUpInside) { [weak self] _ in
            self?.decrement()
        }

        plusButton.ls_addAction(for: .touchUpInside) { [weak self] _ in
            self?.increment()
        }

        updateColors()
        updateDisplay()
    }

    // MARK: - 更新

    private func updateDisplay() {
        valueLabel.text = "\(value)"
        minusButton.isEnabled = value > minimumValue
        plusButton.isEnabled = value < maximumValue

        minusButton.alpha = minusButton.isEnabled ? 1.0 : 0.3
        plusButton.alpha = plusButton.isEnabled ? 1.0 : 0.3
    }

    private func updateColors() {
        container.backgroundColor = backgroundColor
        minusButton.tintColor = buttonColor
        plusButton.tintColor = buttonColor
    }

    // MARK: - 公共方法

    /// 设置值
    public func setValue(_ value: Int) {
        self.value = max(minimumValue, min(maximumValue, value))
    }

    /// 增加
    public func increment() {
        value = min(value + stepValue, maximumValue)
    }

    /// 减少
    public func decrement() {
        value = max(value - stepValue, minimumValue)
    }

    /// 重置
    public func reset() {
        value = minimumValue
    }
}

// MARK: - Associated Keys

private struct AssociatedKey {
    static var valueChangeHandlerKey: UInt8 = 0
}

#endif

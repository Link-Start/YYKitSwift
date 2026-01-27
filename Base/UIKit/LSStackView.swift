//
//  LSStackView.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  增强的栈视图 - 提供更多布局选项
//

#if canImport(UIKit)
import UIKit

// MARK: - LSStackView

/// 增强的栈视图
public class LSStackView: UIView {

    // MARK: - 属性

    /// 轴方向
    public var axis: NSLayoutConstraint.Axis = .vertical {
        didSet {
            stackView.axis = axis
        }
    }

    /// 对齐方式
    public var alignment: UIStackView.Alignment = .fill {
        didSet {
            stackView.alignment = alignment
        }
    }

    /// 分布方式
    public var distribution: UIStackView.Distribution = .fill {
        didSet {
            stackView.distribution = distribution
        }
    }

    /// 间距
    public var spacing: CGFloat = 8 {
        didSet {
            stackView.spacing = spacing
        }
    }

    /// 内边距
    public var edgeInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) {
        didSet {
            updateInsets()
        }
    }

    /// 是否启用自动内边距
    public var useLayoutMargins: Bool = true {
        didSet {
            updateInsets()
        }
    }

    /// 背景颜色
    public var stackBackgroundColor: UIColor? {
        didSet {
            stackView.backgroundColor = stackBackgroundColor
        }
    }

    /// 圆角
    public var cornerRadius: CGFloat = 0 {
        didSet {
            stackView.layer.cornerRadius = cornerRadius
            stackView.layer.masksToBounds = true
        }
    }

    /// 边框宽度
    public var borderWidth: CGFloat = 0 {
        didSet {
            stackView.layer.borderWidth = borderWidth
        }
    }

    /// 边框颜色
    public var borderColor: UIColor = .clear {
        didSet {
            stackView.layer.borderColor = borderColor.cgColor
        }
    }

    /// 阴影
    public var shadowColor: UIColor? = nil {
        didSet {
            updateShadow()
        }
    }

    /// 阴影偏移
    public var shadowOffset: CGSize = .zero {
        didSet {
            updateShadow()
        }
    }

    /// 阴影透明度
    public var shadowOpacity: Float = 0 {
        didSet {
            updateShadow()
        }
    }

    /// 阴影半径
    public var shadowRadius: CGFloat = 0 {
        didSet {
            updateShadow()
        }
    }

    /// 栈视图
    public let stackView: UIStackView = {
        let stack = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupStackView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupStackView()
    }

    public init(
        axis: NSLayoutConstraint.Axis = .vertical,
        alignment: UIStackView.Alignment = .fill,
        spacing: CGFloat = 8
    ) {
        self.axis = axis
        self.alignment = alignment
        self.spacing = spacing
        super.init(frame: .zero)
        setupStackView()
    }

    // MARK: - 设置

    private func setupStackView() {
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: edgeInsets.top),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: edgeInsets.left),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -edgeInsets.right),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -edgeInsets.bottom)
        ])
    }

    private func updateInsets() {
        let insets = useLayoutMargins ? layoutMargins : edgeInsets

        stackView.constraints.forEach { constraint in
            if constraint.firstAttribute == .top && constraint.firstItem == stackView {
                constraint.constant = insets.top
            } else if constraint.firstAttribute == .bottom && constraint.firstItem == stackView {
                constraint.constant = -insets.bottom
            } else if constraint.firstAttribute == .leading && constraint.firstItem == stackView {
                constraint.constant = insets.left
            } else if constraint.firstAttribute == .trailing && constraint.firstItem == stackView {
                constraint.constant = -insets.right
            }
        }
    }

    private func updateShadow() {
        if let color = shadowColor {
            layer.shadowColor = color.cgColor
            layer.shadowOffset = shadowOffset
            layer.shadowOpacity = shadowOpacity
            layer.shadowRadius = shadowRadius
        } else {
            layer.shadowColor = nil
            layer.shadowOffset = .zero
            layer.shadowOpacity = 0
            layer.shadowRadius = 0
        }
    }

    // MARK: - 公共方法

    /// 添加视图
    @discardableResult
    public func addArrangedSubview(_ view: UIView) -> UIView {
        stackView.addArrangedSubview(view)
        return view
    }

    /// 移除视图
    public func removeArrangedSubview(_ view: UIView) {
        stackView.removeArrangedSubview(view)
    }

    /// 移除所有视图
    public func removeArrangedSubviews() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }

    /// 获取视图数量
    public var arrangedSubviewsCount: Int {
        return stackView.arrangedSubviews.count
    }

    /// 获取所有视图
    public var arrangedSubviews: [UIView] {
        return stackView.arrangedSubviews
    }

    /// 设置间距
    public func setSpacing(_ spacing: CGFloat, after index: Int? = nil) {
        if let index = index {
            stackView.setCustomSpacing(spacing, after: index)
        } else {
            self.spacing = spacing
        }
    }
}

// MARK: - UIStackView Extension

public extension UIStackView {

    /// 设置内边距
    func ls_setEdgeInsets(_ insets: UIEdgeInsets) {
        translatesAutoresizingMaskIntoConstraints = false

        let top = topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: insets.top)
        let leading = leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: insets.left)
        let trailing = trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -insets.right)
        let bottom = bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -insets.bottom)

        NSLayoutConstraint.activate([top, leading, trailing, bottom])
    }

    /// 设置圆角
    func ls_setCornerRadius(_ radius: CGFloat) {
        layer.cornerRadius = radius
        layer.masksToBounds = true
    }

    /// 设置边框
    func ls_setBorder(
        width: CGFloat = 1,
        color: UIColor = .separator,
        cornerRadius: CGFloat = 0
    ) {
        layer.borderWidth = width
        layer.borderColor = color.cgColor
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true
    }

    /// 设置阴影
    func ls_setShadow(
        color: UIColor = .black,
        offset: CGSize = CGSize(width: 0, height: 2),
        opacity: Float = 0.3,
        radius: CGFloat = 4
    ) {
        layer.shadowColor = color.cgColor
        layer.shadowOffset = offset
        layer.shadowOpacity = opacity
        layer.shadowRadius = radius
    }

    /// 添加背景视图
    func ls_setBackground(
        color: UIColor = .white,
        cornerRadius: CGFloat = 8
    ) {
        let backgroundView = UIView()
        backgroundView.backgroundColor = color
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(backgroundView, at: 0)

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: topAnchor, constant: -4),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -4),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 4),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 4)
        ])

        backgroundView.layer.cornerRadius = cornerRadius
        backgroundView.layer.masksToBounds = true
    }
}

// MARK: - HStack 和 VStack 便捷创建

public extension UIView {

    /// 创建水平栈
    @discardableResult
    func ls_hStack(
        spacing: CGFloat = 8,
        alignment: UIStackView.Alignment = .fill,
        distribution: UIStackView.Distribution = .fill
    ) -> LSStackView {
        let stackView = LSStackView(axis: .horizontal, alignment: alignment, spacing: spacing)
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        return stackView
    }

    /// 创建垂直栈
    @discard0Result
    func ls_vStack(
        spacing: CGFloat = 8,
        alignment: UIStackView.Alignment = .fill,
        distribution: UIStackView.Distribution = .fill
    ) -> LSStackView {
        let stackView = LSStackView(axis: .vertical, alignment: alignment, spacing: spacing)
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        return stackView
    }
}

// MARK: - Form Stack View

/// 表单栈视图 - 带标签的表单行
public class LSFormStackView: LSStackView {

    // MARK: - 属性

    /// 标签宽度
    public var labelWidth: CGFloat = 80 {
        didSet {
            updateLabelConstraints()
        }
    }

    /// 标签颜色
    public var labelColor: UIColor = .label {
        didSet {
            updateLabelColors()
        }
    }

    /// 标签字体
    public var labelFont: UIFont = .systemFont(ofSize: 16) {
        didSet {
            updateLabelFonts()
        }
    }

    /// 是否必填
    public var required: Bool = false {
        didSet {
            updateRequiredIndicators()
        }
    }

    // MARK: - 便捷方法

    /// 添加文本行
    @discardableResult
    func addTextRow(
        label: String,
        text: String? = nil,
        placeholder: String? = nil
    ) -> (LSLabel, LSTextField) {
        let row = createRow(label: label)

        let labelView = row.0 as! LSLabel
        labelView.text = label
        labelView.font = labelFont
        labelView.textColor = labelColor

        let textField = LSTextField()
        if let text = text {
            textField.text = text
        }
        if let placeholder = placeholder {
            textField.placeholder = placeholder
        }

        row.1.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: row.1.topAnchor),
            textField.leadingAnchor.constraint(equalTo: row.1.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: row.1.trailingAnchor),
            textField.bottomAnchor.constraint(equalTo: row.1.bottomAnchor),
            textField.heightAnchor.constraint(equalToConstant: 44)
        ])

        return (labelView, textField)
    }

    /// 添加开关行
    @discardableResult
    func addSwitchRow(
        label: String,
        isOn: Bool = false
    ) -> (LSLabel, LSSwitch) {
        let row = createRow(label: label)

        let labelView = row.0 as! LSLabel
        labelView.text = label
        labelView.font = labelFont
        labelView.textColor = labelColor

        let switchControl = LSSwitch()
        switchControl.isOn = isOn

        row.1.addSubview(switchControl)
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            switchControl.centerYAnchor.constraint(equalTo: row.1.centerYAnchor),
            switchControl.trailingAnchor.constraint(equalTo: row.1.trailingAnchor)
        ])

        return (labelView, switchControl)
    }

    /// 添加选择行
    @discardableResult
    func addChoiceRow(
        label: String,
        options: [String],
        selectedIndex: Int = 0,
        onSelect: @escaping (Int) -> Void
    ) -> (LSLabel, LSSegmentedControl) {
        let row = createRow(label: label)

        let labelView = row.0 as! LSLabel
        labelView.text = label
        labelView.font = labelFont
        labelView.textColor = labelColor

        let segmentedControl = LSSegmentedControl()
        segmentedControl.titles = options
        segmentedControl.selectedIndex = selectedIndex

        segmentedControl.onSelectionChanged = { index in
            onSelect(index)
        }

        row.1.addSubview(segmentedControl)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            segmentedControl.centerYAnchor.constraint(equalTo: row.1.centerYAnchor),
            segmentedControl.trailingAnchor.constraint(equalTo: row.1.trailingAnchor)
        ])

        return (labelView, segmentedControl)
    }

    /// 添加自定义行
    @discardableResult
    func addCustomRow(
        label: String,
        view: UIView
    ) -> LSLabel {
        let row = createRow(label: label)

        let labelView = row.0 as! LSLabel
        labelView.text = label
        labelView.font = labelFont
        labelView.textColor = labelColor

        row.1.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.centerYAnchor.constraint(equalTo: row.1.centerYAnchor),
            view.leadingAnchor.constraint(equalTo: row.1.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: row.1.trailingAnchor),
            view.heightAnchor.constraint(equalToConstant: 44)
        ])

        return labelView
    }

    // MARK: - 私有方法

    private func createRow(label: String) -> (UIView, UIView) {
        let rowContainer = UIView()
        rowContainer.translatesAutoresizingMaskIntoConstraints = false

        let labelView = LSLabel()
        labelView.text = label
        labelView.font = labelFont
        labelView.textColor = labelColor
        labelView.translatesAutoresizingMaskIntoConstraints = false

        let valueView = UIView()
        valueView.translatesAutoresizingMaskIntoConstraints = false

        rowContainer.addSubview(labelView)
        rowContainer.addSubview(valueView)

        NSLayoutConstraint.activate([
            labelView.leadingAnchor.constraint(equalTo: rowContainer.leadingAnchor),
            labelView.widthAnchor.constraint(equalToConstant: labelWidth),
            labelView.centerYAnchor.constraint(equalTo: rowContainer.centerYAnchor),

            valueView.leadingAnchor.constraint(equalTo: labelView.trailingAnchor, constant: 8),
            valueView.trailingAnchor.constraint(equalTo: rowContainer.trailingAnchor),
            valueView.topAnchor.constraint(equalTo: rowContainer.topAnchor),
            valueView.bottomAnchor.constraint(equalTo: rowContainer.bottomAnchor),
            valueView.heightAnchor.constraint(equalToConstant: 44)
        ])

        addArrangedSubview(rowContainer)

        return (labelView, valueView)
    }

    private func updateLabelConstraints() {
        arrangedSubviews.compactMap { $0 as? LSLabel }.forEach { labelView in
            labelView.constraints.forEach { constraint in
                if constraint.firstAttribute == .width {
                    constraint.constant = labelWidth
                }
            }
        }
    }

    private func updateLabelColors() {
        arrangedSubviews.compactMap { $0 as? LSLabel }.forEach { labelView in
            labelView.textColor = labelColor
        }
    }

    private func updateLabelFonts() {
        arrangedSubviews.compactMap { $0 as? LSLabel }.forEach { labelView in
            labelView.font = labelFont
        }
    }

    private func updateRequiredIndicators() {
        // 可以在这里添加必填标记
    }
}

// MARK: - Card Stack View

/// 卡片栈视图
public class LSCardStackView: LSStackView {

    // MARK: - 属性

    /// 卡片样式
    public var cardStyle: LSCardView.CardStyle = .default {
        didSet {
            updateCardStyles()
        }
    }

    /// 卡片内边距
    public var cardInsets: UIEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12) {
        didSet {
            updateCardInsets()
        }
    }

    /// 卡片圆角
    public var cardCornerRadius: CGFloat = 12 {
        didSet {
            updateCardCornerRadius()
        }
    }

    /// 卡片阴影
    public var cardShadowColor: UIColor = .black {
        didSet {
            updateCardShadows()
        }
    }

    // MARK: - 卡片视图数组

    private var cardViews: [LSCardView] = []

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupCardStack()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCardStack()
    }

    // MARK: - 设置

    private func setupCardStack() {
        spacing = 8
        alignment = .fill
        axis = .vertical
    }

    // MARK: - 公共方法

    /// 添加卡片
    @discardableResult
    func addCard() -> LSCardView {
        let card = LSCardView()
        card.style = cardStyle
        card.cardInsets = cardInsets
        card.cornerRadius = cardCornerRadius
        card.shadowColor = cardShadowColor

        addArrangedSubview(card)
        cardViews.append(card)

        updateCardStyles()
        updateCardInsets()
        updateCardCornerRadius()
        updateCardShadows()

        return card
    }

    /// 添加带内容的卡片
    @discardableResult
    func addCard(content: (LSCardView) -> Void) -> LSCardView {
        let card = addCard()
        content(card)
        return card
    }

    /// 移除卡片
    func removeCard(_ card: LSCardView) {
        removeArrangedSubview(card)
        if let index = cardViews.firstIndex(of: card) {
            cardViews.remove(at: index)
        }
    }

    /// 清空卡片
    func clearCards() {
        removeArrangedSubviews()
        cardViews.removeAll()
    }

    // MARK: - 更新

    private func updateCardStyles() {
        for card in cardViews {
            card.style = cardStyle
        }
    }

    private func updateCardInsets() {
        for card in cardViews {
            card.cardInsets = cardInsets
        }
    }

    private func updateCardCornerRadius() {
        for card in cardViews {
            card.cornerRadius = cardCornerRadius
        }
    }

    private func updateCardShadows() {
        for card in cardViews {
            card.shadowColor = cardShadowColor
        }
    }
}

// MARK: - Equal Width Stack View

/// 等宽栈视图
public class LSEqualWidthStackView: LSStackView {

    /// 是否启用等宽
    public var isEqualWidthEnabled: Bool = true {
        didSet {
            updateEqualWidth()
        }
    }

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupEqualWidthStack()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupEqualWidthStack()
    }

    public init(
        axis: NSLayoutConstraint.Axis = .vertical,
        spacing: CGFloat = 8,
        alignment: UIStackView.Alignment = .fill
    ) {
        super.init(axis: axis, alignment: alignment, spacing: spacing)
        setupEqualWidthStack()
    }

    // MARK: - 设置

    private func setupEqualWidthStack() {
        distribution = .fillEqually
    }

    private func updateEqualWidth() {
        if isEqualWidthEnabled {
            distribution = .fillEqually
        } else {
            distribution = .fill
        }
}

#endif

//
//  LSButtonGroup.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  按钮组 - 管理一组相关的按钮
//

#if canImport(UIKit)
import UIKit

// MARK: - LSButtonGroup

/// 按钮组
@MainActor
public class LSButtonGroup: UIView {

    // MARK: - 类型定义

    /// 按钮配置
    public struct ButtonConfig {
        let title: String?
        let image: UIImage?
        let selectedImage: UIImage?
        let isEnabled: Bool
        let tag: Int?

        public init(
            title: String? = nil,
            image: UIImage? = nil,
            selectedImage: UIImage? = nil,
            isEnabled: Bool = true,
            tag: Int? = nil
        ) {
            self.title = title
            self.image = image
            self.selectedImage = selectedImage
            self.isEnabled = isEnabled
            self.tag = tag
        }
    }

    /// 按钮组样式
    public enum GroupStyle {
        case horizontal       // 水平排列
        case vertical         // 垂直排列
        case grid             // 网格排列
        case stack            // 堆叠
    }

    /// 按钮样式
    public enum ButtonStyle {
        case text            // 纯文本
        case image           // 纯图片
        case textAndImage    // 图片和文本
    }

    /// 选择模式
    public enum SelectionMode {
        case none            // 不选择
        case single          // 单选
        case multiple        // 多选
    }

    /// 按钮点击回调
    public typealias ButtonHandler = (Int, UIButton) -> Void

    // MARK: - 属性

    /// 按钮配置数组
    public var buttonConfigs: [ButtonConfig] = [] {
        didSet {
            updateButtons()
        }
    }

    /// 按钮组样式
    public var groupStyle: GroupStyle = .horizontal {
        didSet {
            updateGroupStyle()
        }
    }

    /// 按钮样式
    public var buttonStyle: ButtonStyle = .text {
        didSet {
            updateButtonStyle()
        }
    }

    /// 选择模式
    public var selectionMode: SelectionMode = .none {
        didSet {
            updateSelection()
        }
    }

    /// 间距
    public var spacing: CGFloat = 8 {
        didSet {
            updateSpacing()
        }
    }

    /// 按钮内边距
    public var buttonInsets: UIEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16) {
        didSet {
            updateButtonInsets()
        }
    }

    /// 按钮高度
    public var buttonHeight: CGFloat = 44 {
        didSet {
            updateButtonConstraints()
        }
    }

    /// 按钮宽度（0 表示自适应）
    public var buttonWidth: CGFloat = 0 {
        didSet {
            updateButtonConstraints()
        }
    }

    /// 选中索引
    public private(set) var selectedIndex: Int = -1 {
        didSet {
            updateSelectedState()
        }
    }

    /// 选中索引集合
    public private(set) var selectedIndices: Set<Int> = [] {
        didSet {
            updateSelectedState()
        }
    }

    /// 正常状态颜色
    public var normalColor: UIColor = .systemGray6 {
        didSet {
            updateButtonColors()
        }
    }

    /// 选中状态颜色
    public var selectedColor: UIColor = .systemBlue {
        didSet {
            updateButtonColors()
        }
    }

    /// 正常文本颜色
    public var normalTextColor: UIColor = .label {
        didSet {
            updateButtonColors()
        }
    }

    /// 选中文本颜色
    public var selectedTextColor: UIColor = .white {
        didSet {
            updateButtonColors()
        }
    }

    /// 按钮点击回调
    public var onButtonTap: ButtonHandler?

    /// 选择变化回调
    public var onSelectionChanged: ((Int) -> Void)?

    /// 圆角
    public var cornerRadius: CGFloat = 8 {
        didSet {
            updateCornerRadius()
        }
    }

    /// 是否等宽
    public var isEquallyWidth: Bool = false {
        didSet {
            updateButtonConstraints()
        }
    }

    // MARK: - UI 组件

    private var buttons: [UIButton] = []
    private var stackView: UIStackView?

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupButtonGroup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButtonGroup()
    }

    public convenience init(buttons: [ButtonConfig] = [], style: GroupStyle = .horizontal) {
        self.init(frame: .zero)
        self.buttonConfigs = buttons
        self.groupStyle = style
    }

    // MARK: - 设置

    private func setupButtonGroup() {
        updateGroupStyle()
    }

    // MARK: - 更新方法

    private func updateGroupStyle() {
        // 移除旧的 stack view
        stackView?.removeFromSuperview()
        stackView = nil
        buttons.forEach { $0.removeFromSuperview() }
        buttons.removeAll()

        let stack: UIStackView
        switch groupStyle {
        case .horizontal:
            stack = UIStackView()
            stack.axis = .horizontal
            stack.alignment = .fill
            stack.distribution = .fill

        case .vertical:
            stack = UIStackView()
            stack.axis = .vertical
            stack.alignment = .fill
            stack.distribution = .fill

        case .grid:
            stack = UIStackView()
            stack.axis = .vertical
            stack.spacing = spacing

        case .stack:
            stack = UIStackView()
            stack.axis = .vertical
            stack.spacing = 0
        }

        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.spacing = spacing
        addSubview(stack)
        stackView = stack

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        updateButtons()
    }

    private func updateButtons() {
        guard let stack = stackView else { return }

        // 移除旧按钮
        buttons.forEach { $0.removeFromSuperview() }
        buttons.removeAll()

        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // 创建新按钮
        for (index, config) in buttonConfigs.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(config.title, for: .normal)
            button.setImage(config.image, for: .normal)
            if let selectedImage = config.selectedImage {
                button.setImage(selectedImage, for: .selected)
            }
            button.isEnabled = config.isEnabled
            if let tempValue = config.tag {
                tag = tempValue
            } else {
                tag = index
            }
            button.translatesAutoresizingMaskIntoConstraints = false

            // 设置样式
            button.backgroundColor = normalColor
            button.setTitleColor(normalTextColor, for: .normal)
            button.layer.cornerRadius = cornerRadius
            button.clipsToBounds = true

            // 添加点击事件
            button.ls_addAction(for: .touchUpInside) { [weak self, weak button] in
                guard let self = self, let button = button else { return }
                self.handleButtonTap(button, at: index)
            }

            // 设置约束
            NSLayoutConstraint.activate([
                button.heightAnchor.constraint(equalToConstant: buttonHeight)
            ])

            if buttonWidth > 0 {
                NSLayoutConstraint.activate([
                    button.widthAnchor.constraint(equalToConstant: buttonWidth)
                ])
            }

            buttons.append(button)

            // 添加到 stack view
            if groupStyle == .grid {
                let rowStack = createRowStack(for: index)
                rowStack.addArrangedSubview(button)
                if rowStack.arrangedSubviews.count == 1 || index == buttonConfigs.count - 1 {
                    stack.addArrangedSubview(rowStack)
                }
            } else {
                stack.addArrangedSubview(button)
            }
        }

        updateButtonStyle()
        updateSelection()
    }

    private func createRowStack(for index: Int) -> UIStackView {
        let itemsPerRow = 3
        let rowIndex = index / itemsPerRow

        if rowIndex < stackView!.arrangedSubviews.count {
            return stackView!.arrangedSubviews[rowIndex] as! UIStackView
        } else {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = spacing
            rowStack.distribution = .fillEqually
            rowStack.translatesAutoresizingMaskIntoConstraints = false
            return rowStack
        }
    }

    private func updateButtonStyle() {
        for button in buttons {
            switch buttonStyle {
            case .text:
                button.imageEdgeInsets = .zero
                button.titleEdgeInsets = .zero

            case .image:
                button.titleEdgeInsets = .zero

            case .textAndImage:
                button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
                button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
            }
        }
    }

    private func updateButtonInsets() {
        for button in buttons {
            button.contentEdgeInsets = buttonInsets
        }
    }

    private func updateSpacing() {
        stackView?.spacing = spacing
    }

    private func updateButtonConstraints() {
        for button in buttons {
            let heightConstraint = button.constraints.first { $0.firstAttribute == .height }
            heightConstraint?.constant = buttonHeight
        }

        if isEquallyWidth, let stack = stackView {
            let count = CGFloat(buttons.count)
            for button in buttons {
                button.constraints.filter { $0.firstAttribute == .width }.forEach { button.removeConstraint($0) }

                if groupStyle == .horizontal {
                    let width = (stack.bounds.width - spacing * (count - 1)) / count
                    button.widthAnchor.constraint(equalToConstant: width).isActive = true
                }
            }
        }
    }

    private func updateSelection() {
        switch selectionMode {
        case .none:
            selectedIndex = -1
            selectedIndices.removeAll()

        case .single:
            if selectedIndex >= 0 {
                selectedIndices = [selectedIndex]
            } else {
                selectedIndices.removeAll()
            }

        case .multiple:
            break
        }

        updateSelectedState()
    }

    private func updateSelectedState() {
        for (index, button) in buttons.enumerated() {
            let isSelected = selectedIndices.contains(index) || index == selectedIndex

            button.isSelected = isSelected
            button.backgroundColor = isSelected ? selectedColor : normalColor
            button.setTitleColor(isSelected ? selectedTextColor : normalTextColor, for: .normal)
        }
    }

    private func updateButtonColors() {
        updateSelectedState()
    }

    private func updateCornerRadius() {
        for button in buttons {
            button.layer.cornerRadius = cornerRadius
        }
    }

    // MARK: - 按钮处理

    private func handleButtonTap(_ button: UIButton, at index: Int) {
        onButtonTap?(index, button)

        switch selectionMode {
        case .none:
            break

        case .single:
            if selectedIndex == index {
                // 取消选择
                selectedIndex = -1
            } else {
                selectedIndex = index
            }
            selectedIndices = selectedIndex >= 0 ? [selectedIndex] : []
            onSelectionChanged?(selectedIndex)

        case .multiple:
            if selectedIndices.contains(index) {
                selectedIndices.remove(index)
            } else {
                selectedIndices.insert(index)
            }
            onSelectionChanged?(index)
        }

        updateSelectedState()
    }

    // MARK: - 公共方法

    /// 选择指定索引的按钮
    public func selectButton(at index: Int) {
        guard index >= 0 && index < buttons.count else { return }

        switch selectionMode {
        case .none:
            break

        case .single:
            selectedIndex = index
            selectedIndices = [index]
            onSelectionChanged?(selectedIndex)

        case .multiple:
            selectedIndices.insert(index)
            onSelectionChanged?(index)
        }

        updateSelectedState()
    }

    /// 取消选择指定索引的按钮
    public func deselectButton(at index: Int) {
        guard index >= 0 && index < buttons.count else { return }

        switch selectionMode {
        case .none:
            break

        case .single:
            if selectedIndex == index {
                selectedIndex = -1
                selectedIndices.removeAll()
                onSelectionChanged?(selectedIndex)
            }

        case .multiple:
            selectedIndices.remove(index)
            onSelectionChanged?(index)
        }

        updateSelectedState()
    }

    /// 取消所有选择
    public func deselectAll() {
        selectedIndex = -1
        selectedIndices.removeAll()
        onSelectionChanged?(-1)
        updateSelectedState()
    }

    /// 获取选中的按钮
    public var selectedButtons: [UIButton] {
        return selectedIndices.compactMap { index in
            guard index < buttons.count else { return nil }
            return buttons[index]
        }
    }

    /// 获取按钮
    public func button(at index: Int) -> UIButton? {
        guard index >= 0 && index < buttons.count else { return nil }
        return buttons[index]
    }
}

// MARK: - LSTabButtonGroup

/// 标签按钮组
public class LSTabButtonGroup: LSButtonGroup {

    // MARK: - 属性

    /// 指示器高度
    public var indicatorHeight: CGFloat = 2 {
        didSet {
            updateIndicator()
        }
    }

    /// 指示器颜色
    public var indicatorColor: UIColor = .systemBlue {
        didSet {
            updateIndicator()
        }
    }

    /// 指示器宽度模式
    public var indicatorWidthMode: IndicatorWidthMode = .equalToButton {
        didSet {
            updateIndicator()
        }
    }

    // MARK: - 指示器宽度模式

    public enum IndicatorWidthMode {
        case equalToButton        // 等于按钮宽度
        case fixed(CGFloat)       // 固定宽度
        case proportional(CGFloat) // 按比例（0-1）
    }

    // MARK: - UI 组件

    private let indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBlue
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupTabButtonGroup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTabButtonGroup()
    }

    // MARK: - 设置

    private func setupTabButtonGroup() {
        selectionMode = .single
        groupStyle = .horizontal
        normalColor = .clear
        selectedColor = .clear

        addSubview(indicatorView)

        updateIndicator()
    }

    // MARK: - 更新

    private func updateIndicator() {
        guard selectedIndex >= 0 && selectedIndex < buttons.count else {
            indicatorView.isHidden = true
            return
        }

        indicatorView.isHidden = false
        indicatorView.backgroundColor = indicatorColor

        let selectedButton = buttons[selectedIndex]

        NSLayoutConstraint.deactivate(indicatorView.constraints)

        var widthConstraint: NSLayoutConstraint
        switch indicatorWidthMode {
        case .equalToButton:
            widthConstraint = indicatorView.widthAnchor.constraint(equalTo: selectedButton.widthAnchor)

        case .fixed(let width):
            widthConstraint = indicatorView.widthAnchor.constraint(equalToConstant: width)

        case .proportional(let proportion):
            widthConstraint = indicatorView.widthAnchor.constraint(
                equalTo: selectedButton.widthAnchor,
                multiplier: max(0, min(1, proportion))
            )
        }

        NSLayoutConstraint.activate([
            indicatorView.leadingAnchor.constraint(equalTo: selectedButton.leadingAnchor),
            indicatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            widthConstraint,
            indicatorView.heightAnchor.constraint(equalToConstant: indicatorHeight)
        ])

        // 动画
        if let stack = stackView, stack.arrangedSubviews.count > 0 {
            UIView.animate(withDuration: 0.3) {
                self.layoutIfNeeded()
            }
        }
    }

    public override func selectButton(at index: Int) {
        super.selectButton(at: index)
        updateIndicator()
    }

    public override func deselectButton(at index: Int) {
        super.deselectButton(at: index)
        updateIndicator()
    }

    public override func deselectAll() {
        super.deselectAll()
        updateIndicator()
    }
}

// MARK: - LSCheckboxGroup

/// 复选框组
public class LSCheckboxGroup: LSButtonGroup {

    // MARK: - 属性

    /// 复选框样式
    public var checkboxStyle: CheckboxStyle = .square {
        didSet {
            updateCheckboxStyle()
        }
    }

    /// 选中标记
    public var checkmarkColor: UIColor = .white {
        didSet {
            updateCheckboxStyle()
        }
    }

    // MARK: - 复选框样式

    public enum CheckboxStyle {
        case square
        case circle
        case custom(UIImage, UIImage)
    }

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        selectionMode = .multiple
        groupStyle = .vertical
        setupCheckboxGroup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCheckboxGroup()
    }

    // MARK: - 设置

    private func setupCheckboxGroup() {
        normalColor = .systemGray6
        selectedColor = .systemBlue
        normalTextColor = .label
        selectedTextColor = .label
    }

    private func updateCheckboxStyle() {
        // 更新按钮图片
        for (index, button) in buttons.enumerated() {
            let isSelected = selectedIndices.contains(index)

            switch checkboxStyle {
            case .square:
                let imageName = isSelected ? "checkmark.square.fill" : "square"
                button.setImage(UIImage(systemName: imageName), for: .normal)

            case .circle:
                let imageName = isSelected ? "checkmark.circle.fill" : "circle"
                button.setImage(UIImage(systemName: imageName), for: .normal)

            case .custom(let normalImage, let selectedImage):
                button.setImage(isSelected ? selectedImage : normalImage, for: .normal)
            }

            button.tintColor = isSelected ? selectedColor : normalColor
        }
    }

    public override func selectButton(at index: Int) {
        super.selectButton(at: index)
        updateCheckboxStyle()
    }

    public override func deselectButton(at index: Int) {
        super.deselectButton(at: index)
        updateCheckboxStyle()
    }
}

// MARK: - LSRadioGroup

/// 单选按钮组
public class LSRadioGroup: LSButtonGroup {

    // MARK: - 属性

    /// 单选按钮样式
    public var radioStyle: RadioStyle = .circle {
        didSet {
            updateRadioStyle()
        }
    }

    // MARK: - 单选样式

    public enum RadioStyle {
        case circle
        case diamond
        case custom(UIImage, UIImage)
    }

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        selectionMode = .single
        groupStyle = .vertical
        setupRadioGroup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupRadioGroup()
    }

    // MARK: - 设置

    private func setupRadioGroup() {
        normalColor = .clear
        selectedColor = .clear
        normalTextColor = .label
        selectedTextColor = .label
    }

    private func updateRadioStyle() {
        for (index, button) in buttons.enumerated() {
            let isSelected = (index == selectedIndex)

            switch radioStyle {
            case .circle:
                let imageName = isSelected ? "largecircle.fill.circle" : "circle"
                button.setImage(UIImage(systemName: imageName), for: .normal)

            case .diamond:
                let imageName = isSelected ? "diamond.fill" : "diamond"
                button.setImage(UIImage(systemName: imageName), for: .normal)

            case .custom(let normalImage, let selectedImage):
                button.setImage(isSelected ? selectedImage : normalImage, for: .normal)
            }

            button.tintColor = isSelected ? selectedColor : normalColor
        }
    }

    public override func selectButton(at index: Int) {
        super.selectButton(at: index)
        updateRadioStyle()
    }

    public override func deselectButton(at index: Int) {
        super.deselectButton(at: index)
        updateRadioStyle()
    }
}

// MARK: - UIView Extension (ButtonGroup)

public extension UIView {

    private enum AssociatedKeys {
        static var buttonGroupKey: UInt8 = 0
    }var ls_buttonGroup: LSButtonGroup? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.buttonGroupKey) as? LSButtonGroup
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.buttonGroupKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// 添加按钮组
    @discardableResult
    func ls_addButtonGroup(
        configs: [LSButtonGroup.ButtonConfig],
        style: LSButtonGroup.GroupStyle = .horizontal,
        height: CGFloat = 44
    ) -> LSButtonGroup {
        let buttonGroup = LSButtonGroup(buttons: configs, style: style)
        buttonGroup.translatesAutoresizingMaskIntoConstraints = false

        addSubview(buttonGroup)

        NSLayoutConstraint.activate([
            buttonGroup.topAnchor.constraint(equalTo: topAnchor),
            buttonGroup.leadingAnchor.constraint(equalTo: leadingAnchor),
            buttonGroup.trailingAnchor.constraint(equalTo: trailingAnchor),
            buttonGroup.heightAnchor.constraint(equalToConstant: height)
        ])

        ls_buttonGroup = buttonGroup
        return buttonGroup
    }

    /// 添加标签按钮组
    @discardableResult
    func ls_addTabButtonGroup(
        titles: [String],
        height: CGFloat = 44
    ) -> LSTabButtonGroup {
        let configs = titles.map { LSButtonGroup.ButtonConfig(title: $0) }
        let buttonGroup = LSTabButtonGroup(buttons: configs, style: .horizontal)
        buttonGroup.translatesAutoresizingMaskIntoConstraints = false

        addSubview(buttonGroup)

        NSLayoutConstraint.activate([
            buttonGroup.topAnchor.constraint(equalTo: topAnchor),
            buttonGroup.leadingAnchor.constraint(equalTo: leadingAnchor),
            buttonGroup.trailingAnchor.constraint(equalTo: trailingAnchor),
            buttonGroup.heightAnchor.constraint(equalToConstant: height)
        ])

        ls_buttonGroup = buttonGroup
        return buttonGroup
    }
}

#endif

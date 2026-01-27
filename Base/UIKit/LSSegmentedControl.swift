//
//  LSSegmentedControl.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  增强的分段控制器 - 提供更多样式和动画
//

#if canImport(UIKit)
import UIKit

// MARK: - LSSegmentedControl

/// 增强的分段控制器
public class LSSegmentedControl: UIView {

    // MARK: - 类型定义

    /// 选择变化回调
    public typealias SelectionHandler = (Int) -> Void

    /// 样式
    public enum Style {
        case plain              // 平面
        case stroked            // 描边
        case filled             // 填充
        case capsule            // 胶囊样式
    }

    // MARK: - 属性

    /// 标题数组
    public var titles: [String] = [] {
        didSet {
            updateSegments()
        }
    }

    /// 图标数组
    public var images: [UIImage?] = [] {
        didSet {
            updateSegments()
        }
    }

    /// 当前选中索引
    public private(set) var selectedIndex: Int = 0 {
        didSet {
            updateSelection()
            onSelectionChanged?(selectedIndex)
        }
    }

    /// 样式
    public var style: Style = .plain {
        didSet {
            updateStyle()
        }
    }

    /// 正常颜色
    public var normalColor: UIColor = .clear {
        didSet {
            updateColors()
        }
    }

    /// 选中颜色
    public var selectedColor: UIColor = .systemBlue {
        didSet {
            updateColors()
        }
    }

    /// 标题颜色（正常）
    public var titleColor: UIColor = .label {
        didSet {
            updateTitleColors()
        }
    }

    /// 标题颜色（选中）
    public var selectedTitleColor: UIColor = .white {
        didSet {
            updateTitleColors()
        }
    }

    /// 字体
    public var font: UIFont = .systemFont(ofSize: 16) {
        didSet {
            updateFont()
        }
    }

    /// 分段间距
    public var segmentSpacing: CGFloat = 0 {
        didSet {
            updateConstraints()
        }
    }

    /// 圆角
    public var cornerRadius: CGFloat = 8 {
        didSet {
            updateCorners()
        }
    }

    /// 边框宽度
    public var borderWidth: CGFloat = 0 {
        didSet {
            updateBorder()
        }
    }

    /// 边框颜色
    public var borderColor: UIColor = .systemGray4 {
        didSet {
            updateBorder()
        }
    }

    /// 指示器视图
    public var showsIndicator: Bool = true {
        didSet {
            indicatorView.isHidden = !showsIndicator
        }
    }

    /// 指示器颜色
    public var indicatorColor: UIColor = .systemBlue {
        didSet {
            indicatorView.backgroundColor = indicatorColor
        }
    }

    /// 指示器高度
    public var indicatorHeight: CGFloat = 2 {
        didSet {
            updateIndicatorConstraints()
        }
    }

    /// 选择变化回调
    public var onSelectionChanged: SelectionHandler?

    // MARK: - UI 组件

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 0
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let indicatorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var segmentButtons: [UIButton] = []

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSegmentedControl()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSegmentedControl()
    }

    public init(titles: [String], style: Style = .plain) {
        self.titles = titles
        self.style = style
        super.init(frame: .zero)
        setupSegmentedControl()
    }

    // MARK: - 设置

    private func setupSegmentedControl() {
        addSubview(stackView)
        addSubview(indicatorView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),

            indicatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            indicatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            indicatorView.heightAnchor.constraint(equalToConstant: indicatorHeight)
        ])

        updateSegments()
        updateStyle()
    }

    // MARK: - 更新

    private func updateSegments() {
        // 移除旧的按钮
        segmentButtons.forEach { $0.removeFromSuperview() }
        segmentButtons.removeAll()

        // 添加新的按钮
        for (index, title) in titles.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = font
            button.tag = index
            button.translatesAutoresizingMaskIntoConstraints = false

            button.ls_addAction(for: .touchUpInside) { [weak self] _ in
                self?.selectSegment(at: index)
            }

            stackView.addArrangedSubview(button)
            segmentButtons.append(button)
        }

        updateColors()
        updateTitleColors()
        updateSelection()
        updateIndicatorConstraints()
    }

    private func updateStyle() {
        switch style {
        case .plain:
            backgroundColor = .clear
            borderWidth = 0
            cornerRadius = 0

        case .stroked:
            backgroundColor = .clear
            borderWidth = 1
            cornerRadius = 8

        case .filled:
            backgroundColor = .systemGray5
            borderWidth = 0
            cornerRadius = 8

        case .胶囊:
            backgroundColor = .systemGray5
            borderWidth = 0
            cornerRadius = bounds.height / 2
        }

        updateColors()
    }

    private func updateColors() {
        switch style {
        case .plain, .stroked:
            // 不填充背景
            for button in segmentButtons {
                button.backgroundColor = .clear
            }

        case .filled, .胶囊:
            // 填充选中项
            for (index, button) in segmentButtons.enumerated() {
                if index == selectedIndex {
                    button.backgroundColor = selectedColor
                } else {
                    button.backgroundColor = normalColor
                }
            }
        }

        layer.borderColor = borderColor.cgColor
        layer.borderWidth = borderWidth
        layer.cornerRadius = cornerRadius
    }

    private func updateTitleColors() {
        for (index, button) in segmentButtons.enumerated() {
            if index == selectedIndex {
                button.setTitleColor(selectedTitleColor, for: .normal)
            } else {
                button.setTitleColor(titleColor, for: .normal)
            }
        }
    }

    private func updateFont() {
        for button in segmentButtons {
            button.titleLabel?.font = font
        }
    }

    private func updateCorners() {
        layer.cornerRadius = cornerRadius

        for button in segmentButtons {
            button.layer.cornerRadius = cornerRadius
            button.layer.masksToBounds = true
        }
    }

    private func updateBorder() {
        layer.borderWidth = borderWidth
        layer.borderColor = borderColor.cgColor
    }

    private func updateSelection() {
        updateColors()
        updateTitleColors()
        updateIndicatorPosition()
    }

    private func updateIndicatorPosition() {
        guard showsIndicator, !segmentButtons.isEmpty else { return }

        let selectedButton = segmentButtons[selectedIndex]

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.indicatorView.transform = CGAffineTransform(
                translationX: selectedButton.frame.origin.x,
                y: 0
            )
            self.indicatorView.bounds.size.width = selectedButton.bounds.width
        }
    }

    private func updateIndicatorConstraints() {
        indicatorView.constraints.forEach { constraint in
            if constraint.firstAttribute == .height {
                constraint.constant = indicatorHeight
            }
        }
    }

    private func updateConstraints() {
        stackView.spacing = segmentSpacing
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        if style == .胶囊 {
            cornerRadius = bounds.height / 2
            updateCorners()
        }

        updateIndicatorPosition()
    }

    // MARK: - 公共方法

    /// 选择分段
    public func selectSegment(at index: Int, animated: Bool = true) {
        guard index >= 0 && index < segmentButtons.count else { return }

        selectedIndex = index
    }

    /// 添加标题
    public func insertTitle(_ title: String, at index: Int) {
        titles.insert(title, at: index)
        updateSegments()
    }

    /// 移除标题
    public func removeTitle(at index: Int) {
        guard index < titles.count else { return }
        titles.remove(at: index)
        updateSegments()
    }

    /// 设置标题
    public func setTitle(_ title: String, forSegmentAt index: Int) {
        guard index < titles.count else { return }
        titles[index] = title
        segmentButtons[index].setTitle(title, for: .normal)
    }
}

// MARK: - UISegmentedControl Extension

public extension UISegmentedControl {

    /// 设置选中颜色
    func ls_setSelectedColor(_ color: UIColor) {
        if #available(iOS 13.0, *) {
            selectedSegmentTintColor = color
        } else {
            tintColor = color
        }
    }

    /// 设置未选中颜色
    func ls_setUnselectedColor(_ color: UIColor) {
        if #available(iOS 13.0, *) {
            let appearance = self.standardAppearance.copy()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = color
            self.standardAppearance = appearance
        }
    }

    /// 设置标题颜色
    func ls_setTitleColor(_ color: UIColor, for state: UIControl.State = .normal) {
        setTitleTextAttributes([.foregroundColor: color], for: state)
    }

    /// 设置标题字体
    func ls_setTitleFont(_ font: UIFont, for state: UIControl.State = .normal) {
        setTitleTextAttributes([.font: font], for: state)
    }

    /// 设置样式
    func ls_applyStyle(
        normalColor: UIColor = .clear,
        selectedColor: UIColor = .systemBlue,
        titleColor: UIColor = .label,
        selectedTitleColor: UIColor = .white
    ) {
        if #available(iOS 13.0, *) {
            let appearance = UISegmentedControlAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = normalColor
            appearance.selectedBackgroundColor = selectedColor

            standardAppearance = appearance
        }

        setTitleTextAttributes([.foregroundColor: titleColor], for: .normal)
        setTitleTextAttributes([.foregroundColor: selectedTitleColor], for: .selected)
    }

    /// 移除边框和背景
    func ls_removeBorders() {
        if #available(iOS 13.0, *) {
            let appearance = self.standardAppearance.copy()
            appearance.configureWithTransparentBackground()
            self.standardAppearance = appearance
        }

        backgroundColor = .clear
    }

    /// 添加底部指示器
    func ls_addIndicator(color: UIColor = .systemBlue, height: CGFloat = 2) {
        let indicator = UIView()
        indicator.backgroundColor = color
        indicator.translatesAutoresizingMaskIntoConstraints = false

        addSubview(indicator)

        NSLayoutConstraint.activate([
            indicator.leadingAnchor.constraint(equalTo: leadingAnchor),
            indicator.bottomAnchor.constraint(equalTo: bottomAnchor),
            indicator.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1 / CGFloat(numberOfSegments)),
            indicator.heightAnchor.constraint(equalToConstant: height)
        ])

        // 存储指示器引用
        let key = AssociatedKey.indicatorKey
        objc_setAssociatedObject(self, key, indicator, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, AssociatedKey.indicatorColorKey, color, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, AssociatedKey.indicatorHeightKey, height, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        // 监听值变化
        addTarget(self, action: #selector(updateIndicatorPosition), for: .valueChanged)
    }

    @objc private func updateIndicatorPosition() {
        guard let indicator = objc_getAssociatedObject(self, AssociatedKey.indicatorKey) as? UIView else { return }

        let width = bounds.width / CGFloat(numberOfSegments)
        let x = width * CGFloat(selectedSegmentIndex)

        UIView.animate(withDuration: 0.3) {
            indicator.transform = CGAffineTransform(translationX: x, y: 0)
        }
    }
}

// MARK: - Associated Keys

private struct AssociatedKey {
    static var indicatorKey: UInt8 = 0
    static var indicatorColorKey: UInt8 = 0
    static var indicatorHeightKey: UInt8 = 0
}

// MARK: - Underlined Segmented Control

/// 带下划线的分段控制器
public class LSUnderlinedSegmentedControl: UIView {

    /// 选择变化回调
    public typealias SelectionHandler = (Int) -> Void

    /// 标题
    public var titles: [String] = [] {
        didSet {
            updateSegments()
        }
    }

    /// 当前索引
    public private(set) var selectedIndex: Int = 0 {
        didSet {
            onSelectionChanged?(selectedIndex)
            updateIndicator()
        }
    }

    /// 标题颜色
    public var titleColor: UIColor = .secondaryLabel {
        didSet {
            updateTitleColors()
        }
    }

    /// 选中颜色
    public var selectedColor: UIColor = .label {
        didSet {
            updateTitleColors()
        }
    }

    /// 指示器颜色
    public var indicatorColor: UIColor = .systemBlue {
        didSet {
            indicatorView.backgroundColor = indicatorColor
        }
    }

    /// 字体
    public var font: UIFont = .systemFont(ofSize: 16) {
        didSet {
            updateFont()
        }
    }

    /// 选择回调
    public var onSelectionChanged: SelectionHandler?

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 20
        stack.distribution = .equalSpacing
        stack.alignment = .center
        return stack
    }()

    private let indicatorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var buttons: [UIButton] = []

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        addSubview(stackView)
        addSubview(indicatorView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),

            indicatorView.heightAnchor.constraint(equalToConstant: 2),
            indicatorView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func updateSegments() {
        buttons.forEach { $0.removeFromSuperview() }
        buttons.removeAll()

        for (index, title) in titles.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = font
            button.tag = index
            button.setTitleColor(titleColor, for: .normal)
            button.translatesAutoresizingMaskIntoConstraints = false

            button.ls_addAction(for: .touchUpInside) { [weak self] _ in
                self?.selectedIndex = index
            }

            stackView.addArrangedSubview(button)
            buttons.append(button)
        }

        updateTitleColors()
        updateIndicator()
    }

    private func updateTitleColors() {
        for (index, button) in buttons.enumerated() {
            button.setTitleColor(index == selectedIndex ? selectedColor : titleColor, for: .normal)
        }
    }

    private func updateFont() {
        for button in buttons {
            button.titleLabel?.font = font
        }
    }

    private func updateIndicator() {
        guard selectedIndex < buttons.count else { return }

        let button = buttons[selectedIndex]
        indicatorView.backgroundColor = indicatorColor

        UIView.animate(withDuration: 0.3) {
            self.indicatorView.bounds.size.width = button.bounds.width
            self.indicatorView.center.x = button.center.x
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        updateIndicator()
    }

    /// 选择分段
    public func selectSegment(at index: Int) {
        guard index >= 0 && index < buttons.count else { return }
        selectedIndex = index
    }
}

#endif

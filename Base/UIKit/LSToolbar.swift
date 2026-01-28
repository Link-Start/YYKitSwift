//
//  LSToolbar.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  工具栏组件 - 自定义导航栏和工具栏
//

#if canImport(UIKit)
import UIKit

// MARK: - LSToolbar

/// 工具栏
@MainActor
public class LSToolbar: UIView {

    // MARK: - 类型定义

    /// 工具栏项
    public struct ToolbarItem {
        let title: String?
        let image: UIImage?
        let action: (() -> Void)?
        let isEnabled: Bool

        public init(
            title: String? = nil,
            image: UIImage? = nil,
            action: (() -> Void)? = nil,
            isEnabled: Bool = true
        ) {
            self.title = title
            self.image = image
            self.action = action
            self.isEnabled = isEnabled
        }

        /// 创建文本项
        public static func text(_ title: String, action: (() -> Void)? = nil) -> ToolbarItem {
            return ToolbarItem(title: title, action: action)
        }

        /// 创建图片项
        public static func image(_ image: UIImage, action: (() -> Void)? = nil) -> ToolbarItem {
            return ToolbarItem(image: image, action: action)
        }

        /// 灵活项
        public static func flexibleSpace() -> ToolbarItem {
            return ToolbarItem(title: nil, action: nil, isEnabled: false)
        }
    }

    /// 工具栏样式
    public enum ToolbarStyle {
        case `default`       // 默认
        case prominent       // 凸起
        case compact         // 紧凑
    }

    /// 点击回调
    public typealias ItemHandler = (Int, ToolbarItem) -> Void

    // MARK: - 属性

    /// 工具栏项
    public var items: [ToolbarItem] = [] {
        didSet {
            updateToolbar()
        }
    }

    /// 工具栏样式
    public var toolbarStyle: ToolbarStyle = .default {
        didSet {
            updateStyle()
        }
    }

    /// 工具栏颜色
    public var toolbarColor: UIColor = .systemBackground {
        didSet {
            backgroundColor = toolbarColor
        }
    }

    /// 分隔线颜色
    public var separatorColor: UIColor = .separator {
        didSet {
            separatorView.backgroundColor = separatorColor
        }
    }

    /// 是否显示分隔线
    public var showsSeparator: Bool = true {
        didSet {
            separatorView.isHidden = !showsSeparator
        }
    }

    /// 项点击回调
    public var onItemTap: ItemHandler?

    /// 按钮字体
    public var buttonFont: UIFont = .systemFont(ofSize: 17) {
        didSet {
            updateButtonFonts()
        }
    }

    /// 按钮颜色
    public var buttonColor: UIColor = .systemBlue {
        didSet {
            updateButtonColors()
        }
    }

    /// 图片色调
    public var imageTintColor: UIColor? = nil {
        didSet {
            updateImageTint()
        }
    }

    /// 是否显示阴影
    public var showsShadow: Bool = false {
        didSet {
            updateShadow()
        }
    }

    /// 阴影颜色
    public var shadowColor: UIColor = .black {
        didSet {
            updateShadow()
        }
    }

    /// 阴影偏移
    public var shadowOffset: CGSize = CGSize(width: 0, height: -1) {
        didSet {
            updateShadow()
        }
    }

    /// 阴影透明度
    public var shadowOpacity: Float = 0.2 {
        didSet {
            updateShadow()
        }
    }

    /// 阴影半径
    public var shadowRadius: CGFloat = 4 {
        didSet {
            updateShadow()
        }
    }

    // MARK: - UI 组件

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 0
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var buttons: [UIButton] = []

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupToolbar()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupToolbar()
    }

    public convenience init(items: [ToolbarItem] = []) {
        self.init(frame: .zero)
        self.items = items
    }

    // MARK: - 设置

    private func setupToolbar() {
        addSubview(stackView)
        addSubview(separatorView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.heightAnchor.constraint(equalToConstant: 44),

            separatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 0.5)
        ])

        updateStyle()
        updateShadow()
    }

    // MARK: - 更新方法

    private func updateToolbar() {
        // 移除旧按钮
        buttons.forEach { $0.removeFromSuperview() }
        buttons.removeAll()

        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // 创建新按钮
        for (index, item) in items.enumerated() {
            if item.title == nil && item.image == nil {
                // 灵活空间
                let spacer = UIView()
                spacer.translatesAutoresizingMaskIntoConstraints = false
                spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
                stackView.addArrangedSubview(spacer)
                continue
            }

            let button = UIButton(type: .system)
            button.setTitle(item.title, for: .normal)
            button.setImage(item.image, for: .normal)
            button.isEnabled = item.isEnabled
            button.translatesAutoresizingMaskIntoConstraints = false
            button.tag = index

            // 设置字体
            button.titleLabel?.font = buttonFont

            // 设置颜色
            button.setTitleColor(buttonColor, for: .normal)
            button.setTitleColor(buttonColor.withAlphaComponent(0.5), for: .disabled)

            // 图片色调
            if let tintColor = imageTintColor {
                button.tintColor = tintColor
            }

            // 添加事件
            if let action = item.action {
                button.ls_addAction(for: .touchUpInside) { [weak self] in
                    action()
                    self?.onItemTap?(index, item)
                }
            }

            // 添加约束
            let widthConstraint: NSLayoutConstraint
            if item.title == nil && item.image != nil {
                // 只有图片
                widthConstraint = button.widthAnchor.constraint(equalToConstant: 44)
            } else if item.title != nil && item.image == nil {
                // 只有文本
                widthConstraint = button.widthAnchor.constraint(greaterThanOrEqualToConstant: 44)
            } else {
                // 文本和图片
                widthConstraint = button.widthAnchor.constraint(greaterThanOrEqualToConstant: 44)
            }

            widthConstraint.isActive = true

            NSLayoutConstraint.activate([
                button.heightAnchor.constraint(equalToConstant: 44)
            ])

            stackView.addArrangedSubview(button)
            buttons.append(button)
        }
    }

    private func updateStyle() {
        switch toolbarStyle {
        case .default:
            backgroundColor = .systemBackground
            separatorView.isHidden = !showsSeparator

        case .prominent:
            backgroundColor = .systemBackground

        case .compact:
            backgroundColor = .systemBackground
        }
    }

    private func updateButtonFonts() {
        for button in buttons {
            button.titleLabel?.font = buttonFont
        }
    }

    private func updateButtonColors() {
        for button in buttons {
            button.setTitleColor(buttonColor, for: .normal)
            button.setTitleColor(buttonColor.withAlphaComponent(0.5), for: .disabled)
        }
    }

    private func updateImageTint() {
        if let tintColor = imageTintColor {
            for button in buttons {
                button.tintColor = tintColor
            }
        }
    }

    private func updateShadow() {
        if showsShadow {
            layer.shadowColor = shadowColor.cgColor
            layer.shadowOffset = shadowOffset
            layer.shadowOpacity = shadowOpacity
            layer.shadowRadius = shadowRadius
        } else {
            layer.shadowOpacity = 0
        }
    }

    // MARK: - 公共方法

    /// 设置项
    func setItems(_ items: [ToolbarItem]) {
        self.items = items
    }

    /// 获取按钮
    func button(at index: Int) -> UIButton? {
        guard index < buttons.count else { return nil }
        return buttons[index]
    }
}

// MARK: - LSToolbarController

/// 工具栏控制器
public class LSToolbarController: UIViewController {

    // MARK: - 属性

    /// 标题视图
    public var titleView: UIView? {
        didSet {
            navigationItem.titleView = titleView
        }
    }

    /// 标题
    public var title: String? {
        didSet {
            titleView = nil
            navigationItem.title = title
        }
    }

    /// 副景颜色
    public var barTintColor: UIColor? {
        didSet {
            navigationController?.navigationBar.barTintColor = barTintColor
        }
    }

    /// 标题颜色
    public var titleColor: UIColor? {
        didSet {
            if let color = titleColor {
                navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: color]
            }
        }
    }

    /// 工具栏颜色
    public var toolbarTintColor: UIColor? {
        didSet {
            navigationController?.toolbar.tintColor = toolbarTintColor
        }
    }

    /// 是否半透明
    public var isTranslucent: Bool = true {
        didSet {
            navigationController?.navigationBar.isTranslucent = isTranslucent
            navigationController?.toolbar.isTranslucent = isTranslucent
        }
    }

    /// 是否隐藏导航栏
    public var hidesNavigationBar: Bool = false {
        didSet {
            navigationController?.setNavigationBarHidden(hidesNavigationBar, animated: true)
        }
    }

    /// 是否隐藏工具栏
    public var hidesToolbar: Bool = false {
        didSet {
            navigationController?.setToolbarHidden(hidesToolbar, animated: true)
        }
    }

    // MARK: - 初始化

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setupToolbarController()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupToolbarController()
    }

    // MARK: - 设置

    private func setupToolbarController() {
        // 默认配置
        navigationItem.largeTitleDisplayMode = .never
    }
}

// MARK: - LSSegmentedToolbar

/// 分段工具栏
public class LSSegmentedToolbar: LSToolbar {

    // MARK: - 属性

    /// 选项卡标题
    public var segmentTitles: [String] = [] {
        didSet {
            updateSegments()
        }
    }

    /// 图片
    public var segmentImages: [UIImage?] = [] {
        didSet {
            updateSegments()
        }
    }

    /// 选中的索引
    public private(set) var selectedSegmentIndex: Int = 0 {
        didSet {
            updateSelection()
        }
    }

    /// 选择变化回调
    public var onSelectionChanged: ((Int) -> Void)?

    // MARK: - UI 组件

    private let segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl()
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSegmentedToolbar()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSegmentedToolbar()
    }

    public convenience init(titles: [String] = []) {
        self.init(frame: .zero)
        self.segmentTitles = titles
    }

    // MARK: - 设置

    private func setupSegmentedToolbar() {
        addSubview(segmentedControl)

        NSLayoutConstraint.activate([
            segmentedControl.centerXAnchor.constraint(equalTo: centerXAnchor),
            segmentedControl.centerYAnchor.constraint(equalTo: centerYAnchor),
            segmentedControl.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -16)
        ])

        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)

        updateSegments()
    }

    // MARK: - 更新方法

    private func updateSegments() {
        segmentedControl.removeAllSegments()

        for (index, title) in segmentTitles.enumerated() {
            segmentedControl.insertSegment(withTitle: title, at: index)

            if index < segmentImages.count, let image = segmentImages[index] {
                segmentedControl.setImage(image, for: .normal)
            }
        }

        segmentedControl.selectedSegmentIndex = selectedSegmentIndex
    }

    private func updateSelection() {
        segmentedControl.selectedSegmentIndex = selectedSegmentIndex
        onSelectionChanged?(selectedSegmentIndex)
    }

    @objc private func segmentChanged() {
        selectedSegmentIndex = segmentedControl.selectedSegmentIndex
    }

    // MARK: - 公共方法

    /// 设置选中索引
    func setSelectedSegment(_ index: Int) {
        selectedSegmentIndex = index
    }
}

// MARK: - LSNavigationToolbar

/// 导航工具栏
public class LSNavigationToolbar: UIView {

    // MARK: - 属性

    /// 标题
    public var title: String? {
        didSet {
            titleLabel.text = title
        }
    }

    /// 副标题
    public var subtitle: String? {
        didSet {
            subtitleLabel.text = subtitle
            subtitleLabel.isHidden = (subtitle == nil)
        }
    }

    /// 左侧按钮项
    public var leftItems: [LSToolbar.ToolbarItem] = [] {
        didSet {
            updateLeftItems()
        }
    }

    /// 右侧按钮项
    public var rightItems: [LSToolbar.ToolbarItem] = [] {
        didSet {
            updateRightItems()
        }
    }

    /// 点击返回回调
    public var onBack: (() -> Void)?

    /// 点击关闭回调
    public var onClose: (() -> Void)?

    // MARK: - UI 组件

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    private let leftStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let rightStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupNavigationToolbar()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupNavigationToolbar()
    }

    // MARK: - 设置

    private func setupNavigationToolbar() {
        addSubview(leftStackView)
        addSubview(rightStackView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            leftStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            leftStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            leftStackView.heightAnchor.constraint(equalToConstant: 44),

            rightStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            rightStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            rightStackView.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.leadingAnchor.constraint(equalTo: leftStackView.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: rightStackView.leadingAnchor, constant: -8),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2)
        ])
    }

    // MARK: - 更新方法

    private func updateLeftItems() {
        leftStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for item in leftItems {
            let button = createButton(from: item)
            leftStackView.addArrangedSubview(button)
        }
    }

    private func updateRightItems() {
        rightStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for item in rightItems {
            let button = createButton(from: item)
            rightStackView.addArrangedSubview(button)
        }
    }

    private func createButton(from item: LSToolbar.ToolbarItem) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(item.title, for: .normal)
        button.setImage(item.image, for: .normal)
        button.isEnabled = item.isEnabled

        if let action = item.action {
            button.ls_addAction(for: .touchUpInside) { action() }
        }

        return button
    }
}

// MARK: - UIView Extension (Toolbar)

public extension UIView {

    /// 关联的工具栏
    private static var toolbarKey: UInt8 = 0

    var ls_toolbar: LSToolbar? {
        get {
            return objc_getAssociatedObject(self, &UIView.toolbarKey) as? LSToolbar
        }
        set {
            objc_setAssociatedObject(
                self,
                &UIView.toolbarKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// 添加工具栏
    @discardableResult
    func ls_addToolbar(
        items: [LSToolbar.ToolbarItem],
        height: CGFloat = 44,
        position: ToolbarPosition = .bottom
    ) -> LSToolbar {
        let toolbar = LSToolbar(items: items)
        toolbar.translatesAutoresizingMaskIntoConstraints = false

        addSubview(toolbar)

        switch position {
        case .top:
            NSLayoutConstraint.activate([
                toolbar.topAnchor.constraint(equalTo: topAnchor),
                toolbar.leadingAnchor.constraint(equalTo: leadingAnchor),
                toolbar.trailingAnchor.constraint(equalTo: trailingAnchor),
                toolbar.heightAnchor.constraint(equalToConstant: height)
            ])

        case .bottom:
            NSLayoutConstraint.activate([
                toolbar.bottomAnchor.constraint(equalTo: bottomAnchor),
                toolbar.leadingAnchor.constraint(equalTo: leadingAnchor),
                toolbar.trailingAnchor.constraint(equalTo: trailingAnchor),
                toolbar.heightAnchor.constraint(equalToConstant: height)
            ])
        }

        ls_toolbar = toolbar
        return toolbar
    }

    /// 工具栏位置
    enum ToolbarPosition {
        case top
        case bottom
    }
}

// MARK: - UIViewController Extension (Toolbar)

public extension UIViewController {

    /// 设置导航栏样式
    func ls_setNavigationBarStyle(
        backgroundColor: UIColor? = nil,
        titleColor: UIColor? = nil,
        tintColor: UIColor? = nil,
        isTranslucent: Bool = true
    ) {
        if let bgColor = backgroundColor {
            navigationController?.navigationBar.barTintColor = bgColor
        }

        if let titleColor = titleColor {
            navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: titleColor]
            navigationController?.navigationBar.largeTitleTextAttributes = [.foregroundColor: titleColor]
        }

        if let tintColor = tintColor {
            navigationController?.navigationBar.tintColor = tintColor
        }

        navigationController?.navigationBar.isTranslucent = isTranslucent
    }

    /// 设置工具栏样式
    func ls_setToolbarStyle(
        backgroundColor: UIColor? = nil,
        tintColor: UIColor? = nil,
        isTranslucent: Bool = true
    ) {
        if let bgColor = backgroundColor {
            navigationController?.toolbar.barTintColor = bgColor
        }

        if let tintColor = tintColor {
            navigationController?.toolbar.tintColor = tintColor
        }

        navigationController?.toolbar.isTranslucent = isTranslucent
    }

    /// 添加左上角按钮
    @discardableResult
    func ls_addLeftBarButton(
        title: String? = nil,
        image: UIImage? = nil,
        action: (() -> Void)? = nil
    ) -> UIBarButtonItem {
        let button = UIBarButtonItem(
            title: title,
            image: image,
            style: .plain,
            target: self,
            action: #selector(handleBarButtonTap(_:))
        )

        if let action = action {
            // 保存 action
            let key = NSString(format: "%p", action)
            objc_setAssociatedObject(button, key, action, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }

        navigationItem.leftBarButtonItem = button
        return button
    }

    /// 添加右上角按钮
    @discardableResult
    func ls_addRightBarButton(
        title: String? = nil,
        image: UIImage? = nil,
        action: (() -> Void)? = nil
    ) -> UIBarButtonItem {
        let button = UIBarButtonItem(
            title: title,
            image: image,
            style: .plain,
            target: self,
            action: #selector(handleBarButtonTap(_:))
        )

        if let action = action {
            let key = NSString(format: "%p", action)
            objc_setAssociatedObject(button, key, action, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }

        navigationItem.rightBarButtonItem = button
        return button
    }

    @objc private func handleBarButtonTap(_ sender: UIBarButtonItem) {
        if let action = objc_getAssociatedObject(sender, "%p") as? (() -> Void) {
            action()
        }
    }

    /// 添加返回按钮
    func ls_addBackButton(action: @escaping () -> Void) {
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(handleBackTap)
        )

        let key = NSString(format: "%p", action)
        objc_setAssociatedObject(backButton, key, action, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        navigationItem.leftBarButtonItem = backButton
        navigationItem.hidesBackButton = true
    }

    @objc private func handleBackTap() {
        if let action = objc_getAssociatedObject(navigationItem.leftBarButtonItem!, "%p") as? (() -> Void) {
            action()
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    /// 添加关闭按钮
    func ls_addCloseButton(action: @escaping () -> Void) {
        let closeButton = UIBarButtonItem(
            barButtonSystemItem: .close,
        target: self,
        action: #selector(handleCloseTap)
        )

        let key = NSString(format: "%p", action)
        objc_setAssociatedObject(closeButton, key, action, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        navigationItem.rightBarButtonItem = closeButton
    }

    @objc private func handleCloseTap() {
        if let action = objc_getAssociatedObject(navigationItem.rightBarButtonItem!, "%p") as? (() -> Void) {
            action()
        } else {
            dismiss(animated: true)
        }
    }

    /// 自定义标题视图
    func ls_setTitleView(
        title: String,
        subtitle: String? = nil,
        alignment: NSTextAlignment = .center
    ) {
        let titleView = LSNavigationToolbarTitleView()
        titleView.configure(title: title, subtitle: subtitle, alignment: alignment)

        let width: CGFloat
        if let navWidth = navigationController?.navigationBar.bounds.width {
            width = navWidth
        } else {
            width = UIScreen.main.bounds.width
        }
        titleView.bounds.size = CGSize(width: width, height: 44)

        navigationItem.titleView = titleView
    }

    /// 添加分段控件到标题
    func ls_addSegmentedControl(
        titles: [String],
        selectedIndex: Int = 0,
        action: @escaping (Int) -> Void
    ) {
        let segmentedControl = UISegmentedControl(items: titles)
        segmentedControl.selectedSegmentIndex = selectedIndex

        segmentedControl.addTarget(self, action: #selector(handleSegmentChange(_:)), for: .valueChanged)

        navigationItem.titleView = segmentedControl
    }

    @objc private func handleSegmentChange(_ control: UISegmentedControl) {
        // 子类可以重写
    }
}

// MARK: - LSNavigationToolbarTitleView

/// 导航栏标题视图
public class LSNavigationToolbarTitleView: UIView {

    // MARK: - 属性

    /// 标题
    public var title: String? {
        didSet {
            titleLabel.text = title
        }
    }

    /// 副标题
    public var subtitle: String? {
        didSet {
            subtitleLabel.text = subtitle
            subtitleLabel.isHidden = (subtitle == nil)
        }
    }

    /// 对齐方式
    public var alignment: NSTextAlignment = .center {
        didSet {
            stackView.alignment = alignment == .center ? .center : .leading
        }
    }

    // MARK: - UI 组件

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 2
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupTitleView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTitleView()
    }

    // MARK: - 设置

    private func setupTitleView() {
        addSubview(stackView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])
    }

    // MARK: - 配置

    public func configure(title: String?, subtitle: String? = nil, alignment: NSTextAlignment = .center) {
        self.title = title
        self.subtitle = subtitle
        self.alignment = alignment
    }
}

// MARK: - UIToolbarItem Extension

public extension UIToolbar {

    /// 设置徽章
    func ls_setBadgeValue(
        _ value: Int,
        color: UIColor = .systemRed,
        backgroundColor: UIColor = .clear
    ) {
        if value == 0 {
            customView = nil
        } else {
            let badge = LSBadgeView(value: value, style: .number)
            badge.badgeColor = color

            customView = badge
        }
    }
}

#endif

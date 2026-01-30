//
//  LSSegmentView.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  分段视图 - 分段控制器样式组件
//

#if canImport(UIKit)
import UIKit

// MARK: - LSSegmentView

/// 分段视图
@MainActor
public class LSSegmentView: UIView {

    // MARK: - 类型定义

    /// 分段项
    public struct SegmentItem {
        let title: String?
        let image: UIImage?
        let selectedImage: UIImage?
        let isEnabled: Bool

        public init(
            title: String? = nil,
            image: UIImage? = nil,
            selectedImage: UIImage? = nil,
            isEnabled: Bool = true
        ) {
            self.title = title
            self.image = image
            self.selectedImage = selectedImage
            self.isEnabled = isEnabled
        }
    }

    /// 选择变化回调
    public typealias SelectionHandler = (Int) -> Void

    // MARK: - 属性

    /// 分段项
    public var items: [SegmentItem] = [] {
        didSet {
            updateSegments()
        }
    }

    /// 当前选中的索引
    public private(set) var selectedIndex: Int = 0 {
        didSet {
            updateSelectedIndex()
        }
    }

    /// 分段样式
    public var segmentStyle: SegmentStyle = .line {
        didSet {
            updateStyle()
        }
    }

    /// 选中颜色
    public var selectedColor: UIColor = .systemBlue {
        didSet {
            updateColors()
        }
    }

    /// 未选中颜色
    public var normalColor: UIColor = .secondaryLabel {
        didSet {
            updateColors()
        }
    }

    /// 指示器颜色
    public var indicatorColor: UIColor = .systemBlue {
        didSet {
            updateIndicator()
        }
    }

    /// 背景颜色
    public var backgroundColor: UIColor = .systemBackground {
        didSet {
            self.backgroundColor = backgroundColor
        }
    }

    /// 边框颜色
    public var borderColor: UIColor = .separator {
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

    /// 字体
    public var font: UIFont = .systemFont(ofSize: 15, weight: .medium) {
        didSet {
            updateFonts()
        }
    }

    /// 选中字体
    public var selectedFont: UIFont = .systemFont(ofSize: 15, weight: .semibold) {
        didSet {
            updateFonts()
        }
    }

    /// 是否显示指示器
    public var showsIndicator: Bool = true {
        didSet {
            updateIndicator()
        }
    }

    /// 指示器高度
    public var indicatorHeight: CGFloat = 2 {
        didSet {
            updateIndicator()
        }
    }

    /// 选择变化回调
    public var onSelectionChanged: SelectionHandler?

    // MARK: - 分段样式

    public enum SegmentStyle {
        case line            // 线条指示器
        case underline       // 下划线指示器
        case box             // 背景框
        case none            // 无指示器
    }

    // MARK: - UI 组件

    private var segmentViews: [LSSegmentItemView] = []
    private var indicatorView: UIView?

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSegmentView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSegmentView()
    }

    public convenience init(items: [SegmentItem] = []) {
        self.init(frame: .zero)
        self.items = items
    }

    // MARK: - 设置

    private func setupSegmentView() {
        clipsToBounds = true
        layer.cornerRadius = 8
        layer.masksToBounds = true
        updateStyle()
    }

    // MARK: - 布局

    public override func layoutSubviews() {
        super.layoutSubviews()

        updateIndicator()
    }

    // MARK: - 更新方法

    private func updateSegments() {
        // 移除旧的视图
        segmentViews.forEach { $0.removeFromSuperview() }
        segmentViews.removeAll()

        guard !items.isEmpty else { return }

        let segmentWidth = bounds.width / CGFloat(items.count)

        for (index, item) in items.enumerated() {
            let segmentView = LSSegmentItemView(item: item)
            segmentView.frame = CGRect(x: CGFloat(index) * segmentWidth, y: 0, width: segmentWidth, height: bounds.height)
            segmentView.translatesAutoresizingMaskIntoConstraints = false

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSegmentTap(_:)))
            segmentView.addGestureRecognizer(tapGesture)
            segmentView.isUserInteractionEnabled = true
            segmentView.tag = index

            addSubview(segmentView)
            segmentViews.append(segmentView)
        }

        updateSelectedIndex()
        updateColors()
        updateFonts()
    }

    private func updateSelectedIndex() {
        for (index, segmentView) in segmentViews.enumerated() {
            segmentView.isSelected = (index == selectedIndex)
        }
        onSelectionChanged?(selectedIndex)
    }

    private func updateStyle() {
        switch segmentStyle {
        case .line:
            layer.borderWidth = 0

        case .underline:
            layer.borderWidth = 0

        case .box:
            layer.borderWidth = 1

        case .none:
            layer.borderWidth = 0
        }

        layer.borderColor = borderColor.cgColor

        updateIndicator()
    }

    private func updateColors() {
        for segmentView in segmentViews {
            segmentView.normalColor = normalColor
            segmentView.selectedColor = selectedColor
        }
    }

    private func updateFonts() {
        for segmentView in segmentViews {
            segmentView.normalFont = font
            segmentView.selectedFont = selectedFont
        }
    }

    private func updateIndicator() {
        // 移除旧的指示器
        indicatorView?.removeFromSuperview()
        indicatorView = nil

        guard showsIndicator, segmentStyle != .none, !items.isEmpty else { return }

        let indicator = UIView()
        indicator.backgroundColor = indicatorColor
        indicator.translatesAutoresizingMaskIntoConstraints = false

        addSubview(indicator)

        switch segmentStyle {
        case .line:
            NSLayoutConstraint.activate([
                indicator.bottomAnchor.constraint(equalTo: bottomAnchor),
                indicator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
                indicator.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
                indicator.heightAnchor.constraint(equalToConstant: indicatorHeight)
            ])

        case .underline:
            NSLayoutConstraint.activate([
                indicator.bottomAnchor.constraint(equalTo: bottomAnchor),
                indicator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
                indicator.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
                indicator.heightAnchor.constraint(equalToConstant: indicatorHeight)
            ])

        case .box:
            // 不需要指示器，使用边框
            break

        case .none:
            break
        }

        self.indicatorView = indicator
        updateIndicatorPosition()
    }

    private func updateIndicatorPosition() {
        guard !items.isEmpty, let indicator = indicatorView else { return }

        let segmentWidth = bounds.width / CGFloat(items.count)
        let indicatorWidth = segmentWidth

        if segmentStyle == .line {
            indicator.frame = CGRect(
                x: CGFloat(selectedIndex) * segmentWidth,
                y: 0,
                width: indicatorWidth,
                height: indicatorHeight
            )
        } else if segmentStyle == .underline {
            let indicatorWidth = segmentWidth
            indicator.frame = CGRect(
                x: CGFloat(selectedIndex) * segmentWidth,
                y: bounds.height - indicatorHeight,
                width: indicatorWidth,
                height: indicatorHeight
            )
        }

        // 动画
        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
    }

    // MARK: - 手势处理

    @objc private func handleSegmentTap(_ gesture: UITapGestureRecognizer) {
        guard let index = gesture.view?.tag,
              index < items.count,
              items[index].isEnabled else {
            return
        }

        selectedIndex = index
    }

    // MARK: - 公共方法

    /// 设置选中索引
    public func setSelectedIndex(_ index: Int, animated: Bool = true) {
        guard index >= 0 && index < items.count else { return }
        selectedIndex = index
    }

    /// 添加分段项
    public func addSegment(_ item: SegmentItem) {
        items.append(item)
    }

    /// 移除分段项
    public func removeSegment(at index: Int) {
        guard index < items.count else { return }
        items.remove(at: index)
    }

    /// 插入分段项
    public func insertSegment(_ item: SegmentItem, at index: Int) {
        guard index <= items.count else { return }
        items.insert(item, at: index)
    }

    /// 更新分段项
    public func updateSegment(_ item: SegmentItem, at index: Int) {
        guard index < items.count else { return }
        items[index] = item
    }
}

// MARK: - LSSegmentItemView

/// 分段项视图
private class LSSegmentItemView: UIView {

    // MARK: - 属性

    var item: LSSegmentView.SegmentItem

    var isSelected: Bool = false {
        didSet {
            updateSelection()
        }
    }

    var normalColor: UIColor = .secondaryLabel {
        didSet {
            updateColors()
        }
    }

    var selectedColor: UIColor = .systemBlue {
        didSet {
            updateColors()
        }
    }

    var normalFont: UIFont = .systemFont(ofSize: 15) {
        didSet {
            updateFonts()
        }
    }

    var selectedFont: UIFont = .systemFont(ofSize: 15, weight: .semibold) {
        didSet {
            updateFonts()
        }
    }

    // MARK: - UI 组件

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.textColor = .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .label
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    // MARK: - 初始化

    init(item: LSSegmentView.SegmentItem) {
        self.item = item
        super.init(frame: .zero)
        setupItemView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 设置

    private func setupItemView() {
        addSubview(titleLabel)
        addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.trailingAnchor.constraint(equalTo: titleLabel.leadingAnchor, constant: -4),
            imageView.widthAnchor.constraint(equalToConstant: 20),
            imageView.heightAnchor.constraint(equalToConstant: 20),

            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 4)
        ])

        // 设置内容
        titleLabel.text = item.title
        imageView.image = item.image

        if item.title == nil, item.image != nil {
            titleLabel.removeFromSuperview()
        } else if item.title != nil, item.image == nil {
            imageView.removeFromSuperview()
        }

        // 设置状态
        isEnabled = item.isEnabled
    }

    // MARK: - 更新方法

    private func updateSelection() {
        updateColors()
        updateFonts()
    }

    private func updateColors() {
        if isSelected {
            titleLabel.textColor = selectedColor
            imageView.tintColor = selectedColor
        } else {
            titleLabel.textColor = normalColor
            imageView.tintColor = normalColor
        }
    }

    private func updateFonts() {
        titleLabel.font = isSelected ? selectedFont : normalFont
    }
}

// MARK: - LSPillSegmentView

/// 药丸分段视图
public class LSPillSegmentView: LSSegmentView {

    // MARK: - 属性

    /// 胶景颜色
    public var pillBackgroundColor: UIColor = .systemGray6 {
        didSet {
            updatePillStyle()
        }
    }

    /// 选中背景颜色
    public var pillSelectedColor: UIColor = .systemBlue {
        didSet {
            updatePillStyle()
        }
    }

    /// 圆角
    public var pillCornerRadius: CGFloat = 20 {
        didSet {
            layer.cornerRadius = pillCornerRadius
        }
    }

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        segmentStyle = .none
        updatePillStyle()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public convenience init(items: [SegmentItem] = []) {
        self.init(frame: .zero)
        self.items = items
    }

    // MARK: - 更新方法

    private func updatePillStyle() {
        clipsToBounds = true
        layer.cornerRadius = pillCornerRadius
    }

    public override func updateColors() {
        super.updateColors()

        for segmentView in segmentViews {
            if segmentView.isSelected {
                segmentView.backgroundColor = pillSelectedColor
            } else {
                segmentView.backgroundColor = pillBackgroundColor
            }
        }
    }
}

// MARK: - LSTabSegmentView

/// 标签分段视图
public class LSTabSegmentView: LSSegmentView {

    // MARK: - 属性

    /// 选项卡宽度模式
    public var tabWidthMode: TabWidthMode = .fixed {
        didSet {
            updateTabWidth()
        }
    }

    /// 固定宽度
    public var fixedTabWidth: CGFloat = 80 {
        didSet {
            updateTabWidth()
        }
    }

    // MARK: - TabWidthMode

    public enum TabWidthMode {
        case fixed           // 固定宽度
        case proportional     // 按比例
        case dynamic          // 动态（根据内容）
    }

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        segmentStyle = .line
        updateTabWidth()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public convenience init(titles: [String] = []) {
        self.init(frame: .zero)
        items = titles.map { SegmentItem(title: $0) }
    }

    // MARK: - 更新方法

    private func updateTabWidth() {
        switch tabWidthMode {
        case .fixed:
            // 固定宽度由外部设置
            break

        case .proportional:
            // 按比例
            let count = CGFloat(max(items.count, 1))
            for (index, segmentView) in segmentViews {
                let width = bounds.width / count
                segmentView.frame.size.width = width
            }

        case .dynamic:
            // 动态宽度
            var xOffset: CGFloat = 0
            let totalCount = CGFloat(items.count)

            for (index, segmentView) in segmentViews {
                let title
                if let tempTitle = title {
                    title = tempTitle
                } else {
                    title = ""
                }
                let font = isSelected ? selectedFont : normalFont
                let textSize = title.size(withAttributes: [.font: font])
                let width = max(textSize.width + 32, bounds.width / totalCount)

                segmentView.frame = CGRect(x: xOffset, y: 0, width: width, height: bounds.height)
                xOffset += width
            }
        }
    }
}

// MARK: - LSCapsuleSegmentView

/// 胶囊分段视图
public class LSCapsuleSegmentView: LSSegmentView {

    // MARK: - 属性

    /// 胶囊颜色
    public var capsuleColor: UIColor = .systemGray6 {
        didSet {
            updateCapsuleStyle()
        }
    }

    /// 选中胶囊颜色
    public var capsuleSelectedColor: UIColor = .systemBlue {
        didSet {
            updateCapsuleStyle()
        }
    }

    /// 胶囊间距
    public var capsuleSpacing: CGFloat = 4 {
        didSet {
            updateCapsuleLayout()
        }
    }

    /// 胶囊内边距
    public var capsuleInsets: UIEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12) {
        didSet {
            updateCapsuleLayout()
        }
    }

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        segmentStyle = .box
        backgroundColor = .clear
        layer.borderWidth = 0
        updateCapsuleStyle()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public convenience init(items: [SegmentItem] = []) {
        self.init(frame: .zero)
        self.items = items
    }

    // MARK: - 更新方法

    private func updateCapsuleStyle() {
        clipsToBounds = true
        layer.cornerRadius = bounds.height / 2
    }

    public override func updateColors() {
        super.updateColors()

        for segmentView in segmentViews {
            if segmentView.isSelected {
                segmentView.backgroundColor = capsuleSelectedColor
            } else {
                segmentView.backgroundColor = capsuleColor
            }
        }
    }

    private func updateCapsuleLayout() {
        guard !items.isEmpty else { return }

        let totalCount = CGFloat(items.count)
        let totalSpacing = CGFloat(totalCount - 1) * capsuleSpacing
        let availableWidth = bounds.width - totalSpacing
        let width = availableWidth / totalCount

        for (index, segmentView) in segmentViews {
            let x = CGFloat(index) * (width + capsuleSpacing)
            segmentView.frame = CGRect(x: x, y: 0, width: width, height: bounds.height)
        }
    }
}

// MARK: - UIView Extension (Segment)

public extension UIView {

    private enum AssociatedKeys {
        static var segmentViewKey: UInt8 = 0
    }var ls_segmentView: LSSegmentView? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.segmentViewKey) as? LSSegmentView
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.segmentViewKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// 添加分段视图
    @discardableResult
    func ls_addSegmentView(
        titles: [String],
        height: CGFloat = 44,
        style: LSSegmentView.SegmentStyle = .line
    ) -> LSSegmentView {
        let items = titles.map { LSSegmentView.SegmentItem(title: $0) }
        return ls_addSegmentView(items: items, height: height, style: style)
    }

    /// 添加分段视图
    @discardableResult
    func ls_addSegmentView(
        items: [LSSegmentView.SegmentItem],
        height: CGFloat = 44,
        style: LSSegmentView.SegmentStyle = .line
    ) -> LSSegmentView {
        let segmentView = LSSegmentView(items: items)
        segmentView.segmentStyle = style
        segmentView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(segmentView)

        NSLayoutConstraint.activate([
            segmentView.topAnchor.constraint(equalTo: topAnchor),
            segmentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            segmentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            segmentView.heightAnchor.constraint(equalToConstant: height)
        ])

        ls_segmentView = segmentView
        return segmentView
    }

    /// 添加丸丸分段视图
    @discardableResult
    func ls_addPillSegmentView(
        titles: [String],
        height: CGFloat = 32
    ) -> LSPillSegmentView {
        let items = titles.map { LSSegmentView.SegmentItem(title: $0) }
        let segmentView = LSPillSegmentView(items: items)
        segmentView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(segmentView)

        NSLayoutConstraint.activate([
            segmentView.topAnchor.constraint(equalTo: topAnchor),
            segmentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            segmentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            segmentView.heightAnchor.constraint(equalToConstant: height)
        ])

        return segmentView
    }

    /// 添加胶囊分段视图
    @discardableResult
    func ls_addCapsuleSegmentView(
        titles: [String],
        height: CGFloat = 32
    ) -> LSCapsuleSegmentView {
        let items = titles.map { LSSegmentView.SegmentItem(title: $0) }
        let segmentView = LSCapsuleSegmentView(items: items)
        segmentView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(segmentView)

        NSLayoutConstraint.activate([
            segmentView.topAnchor.constraint(equalTo: topAnchor),
            segmentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            segmentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            segmentView.heightAnchor.constraint(equalToConstant: height)
        ])

        return segmentView
    }
}

// MARK: - UIViewController Extension (Segment)

public extension UIViewController {

    /// 添加分段控制器到标题栏
    func ls_addSegmentedControl(
        titles: [String],
        selectedIndex: Int = 0,
        action: @escaping (Int) -> Void
    ) {
        let segmentControl = UISegmentedControl(items: titles)
        segmentControl.selectedSegmentIndex = selectedIndex

        segmentControl.addTarget(self, action: #selector(handleSegmentChange(_:)), for: .valueChanged)

        // 保存 action
        let key = NSString(format: "%p", action)
        objc_setAssociatedObject(segmentControl, key, action, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        navigationItem.titleView = segmentView
    }

    @objc private func handleSegmentChange(_ control: UISegmentedControl) {
        if let action = objc_getAssociatedObject(control, "%p") as? (Int) -> Void {
            action(control.selectedSegmentIndex)
        }
    }
}

#endif

//
//  LSTimelineView.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  时间线视图 - 显示时间序列的事件
//

#if canImport(UIKit)
import UIKit

// MARK: - LSTimelineView

/// 时间线视图
@MainActor
public class LSTimelineView: UIScrollView {

    // MARK: - 类型定义

    /// 时间线索引路径
    public enum TimelineStyle {
        case line            // 直线
        case dotted          // 虚线
        case dashed          // 点线
    }

    /// 时间线方向
    public enum TimelineDirection {
        case vertical        // 垂直
        case horizontal      // 水平
    }

    /// 时间线项
    public struct TimelineItem {
        let title: String?
        let subtitle: String?
        let description: String?
        let date: Date?
        let icon: UIImage?
        let iconColor: UIColor?
        let backgroundColor: UIColor?
        let isSelected: Bool

        public init(
            title: String? = nil,
            subtitle: String? = nil,
            description: String? = nil,
            date: Date? = nil,
            icon: UIImage? = nil,
            iconColor: UIColor? = nil,
            backgroundColor: UIColor? = nil,
            isSelected: Bool = false
        ) {
            self.title = title
            self.subtitle = subtitle
            self.description = description
            self.date = date
            self.icon = icon
            self.iconColor = iconColor
            self.backgroundColor = backgroundColor
            self.isSelected = isSelected
        }
    }

    /// 项点击回调
    public typealias ItemHandler = (Int, TimelineItem) -> Void

    // MARK: - 属性

    /// 时间线数据
    public var items: [TimelineItem] = [] {
        didSet {
            updateTimeline()
        }
    }

    /// 时间线方向
    public var direction: TimelineDirection = .vertical {
        didSet {
            setNeedsLayout()
            updateTimeline()
        }
    }

    /// 时间线样式
    public var timelineStyle: TimelineStyle = .line {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 时间线颜色
    public var timelineColor: UIColor = .systemGray4 {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 时间线宽度
    public var timelineWidth: CGFloat = 2 {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 图标大小
    public var iconSize: CGSize = CGSize(width: 40, height: 40) {
        didSet {
            updateTimeline()
        }
    }

    /// 项间距
    public var itemSpacing: CGFloat = 16 {
        didSet {
            updateTimeline()
        }
    }

    /// 内容边距
    public var contentInsets: UIEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16) {
        didSet {
            updateTimeline()
        }
    }

    /// 是否显示日期
    public var showsDate: Bool = true

    /// 日期格式
    public var dateFormat: String = "yyyy-MM-dd HH:mm"

    /// 项点击回调
    public var onItemTap: ItemHandler?

    // MARK: - 私有属性

    private var itemViews: [LSTimelineItemView] = []

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupTimeline()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTimeline()
    }

    public convenience init(items: [TimelineItem] = []) {
        self.init(frame: .zero)
        self.items = items
    }

    // MARK: - 设置

    private func setupTimeline() {
        backgroundColor = .clear
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: contentInsets.top),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: contentInsets.left),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -contentInsets.right),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -contentInsets.bottom)
        ])
    }

    // MARK: - 更新

    private func updateTimeline() {
        // 移除旧的视图
        itemViews.forEach { $0.removeFromSuperview() }
        itemViews.removeAll()

        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // 创建新的视图
        for (index, item) in items.enumerated() {
            let itemView = LSTimelineItemView(item: item)
            itemView.iconSize = iconSize
            itemView.showsDate = showsDate
            itemView.dateFormat = dateFormat
            itemView.translatesAutoresizingMaskIntoConstraints = false
            itemView.tag = index

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleItemTap(_:)))
            itemView.addGestureRecognizer(tapGesture)
            itemView.isUserInteractionEnabled = true

            stackView.addArrangedSubview(itemView)
            itemViews.append(itemView)
        }

        stackView.spacing = itemSpacing

        setNeedsLayout()
    }

    // MARK: - 手势处理

    @objc private func handleItemTap(_ gesture: UITapGestureRecognizer) {
        guard let index = gesture.view?.tag, index < items.count else { return }

        let item = items[index]
        onItemTap?(index, item)
    }

    // MARK: - 公共方法

    /// 添加项
    public func addItem(_ item: TimelineItem) {
        items.append(item)
        updateTimeline()
    }

    /// 插入项
    public func insertItem(_ item: TimelineItem, at index: Int) {
        items.insert(item, at: index)
        updateTimeline()
    }

    /// 移除项
    public func removeItem(at index: Int) {
        guard index < items.count else { return }
        items.remove(at: index)
        updateTimeline()
    }

    /// 更新项
    public func updateItem(_ item: TimelineItem, at index: Int) {
        guard index < items.count else { return }
        items[index] = item
        updateTimeline()
    }

    /// 选中项
    public func selectItem(at index: Int) {
        guard index < items.count else { return }

        for (i, itemView) in itemViews.enumerated() {
            itemView.isSelected = (i == index)
        }
    }

    /// 滚动到指定项
    public func scrollToItem(at index: Int, animated: Bool = true) {
        guard index < itemViews.count else { return }

        let itemView = itemViews[index]
        let rect = convert(itemView.frame, to: contentView)
        scrollRectToVisible(rect, animated: animated)
    }
}

// MARK: - LSTimelineItemView

/// 时间线项视图
private class LSTimelineItemView: UIView {

    // MARK: - 属性

    var item: LSTimelineView.TimelineItem {
        didSet {
            updateContent()
        }
    }

    var iconSize: CGSize = CGSize(width: 40, height: 40) {
        didSet {
            updateConstraints()
        }
    }

    var showsDate: Bool = true {
        didSet {
            updateContent()
        }
    }

    var dateFormat: String = "yyyy-MM-dd HH:mm" {
        didSet {
            updateContent()
        }
    }

    var isSelected: Bool = false {
        didSet {
            updateSelection()
        }
    }

    // MARK: - UI 组件

    private let iconContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .tertiaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let timeLineView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - 初始化

    init(item: LSTimelineView.TimelineItem) {
        self.item = item
        super.init(frame: .zero)
        setupItemView()
        updateContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 设置

    private func setupItemView() {
        addSubview(timeLineView)
        addSubview(iconContainerView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(descriptionLabel)
        addSubview(dateLabel)
        iconContainerView.addSubview(iconImageView)

        NSLayoutConstraint.activate([
            iconContainerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            iconContainerView.topAnchor.constraint(equalTo: topAnchor),
            iconContainerView.widthAnchor.constraint(equalToConstant: iconSize.width),
            iconContainerView.heightAnchor.constraint(equalToConstant: iconSize.height),

            iconImageView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: iconSize.width * 0.5),
            iconImageView.heightAnchor.constraint(equalToConstant: iconSize.height * 0.5),

            timeLineView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            timeLineView.topAnchor.constraint(equalTo: iconContainerView.bottomAnchor),
            timeLineView.widthAnchor.constraint(equalToConstant: 2),
            timeLineView.bottomAnchor.constraint(equalTo: bottomAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: iconContainerView.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: topAnchor),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),

            dateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            dateLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 4),

            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 8),
            descriptionLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - 更新

    private func updateContent() {
        // 图标
        if let icon = item.icon {
            iconImageView.image = icon
            iconImageView.isHidden = false
        } else {
            iconImageView.isHidden = true
        }

        // 图标容器背景
        if let iconColor = item.iconColor {
            iconContainerView.backgroundColor = iconColor
            iconContainerView.layer.cornerRadius = iconSize.width / 2
        } else if item.isSelected {
            iconContainerView.backgroundColor = .systemBlue
            iconContainerView.layer.cornerRadius = iconSize.width / 2
        } else {
            iconContainerView.backgroundColor = .systemGray6
            iconContainerView.layer.cornerRadius = iconSize.width / 2
        }

        // 标题
        titleLabel.text = item.title
        titleLabel.isHidden = (item.title == nil)

        // 副标题
        subtitleLabel.text = item.subtitle
        subtitleLabel.isHidden = (item.subtitle == nil)

        // 描述
        descriptionLabel.text = item.description
        descriptionLabel.isHidden = (item.description == nil)

        // 日期
        if showsDate, let date = item.date {
            let formatter = DateFormatter()
            formatter.dateFormat = dateFormat
            dateLabel.text = formatter.string(from: date)
            dateLabel.isHidden = false
        } else {
            dateLabel.isHidden = true
        }

        // 背景色
        if let backgroundColor = item.backgroundColor {
            self.backgroundColor = backgroundColor
        } else {
            backgroundColor = nil
        }

        updateSelection()
    }

    private func updateSelection() {
        if isSelected {
            timeLineView.backgroundColor = .systemBlue
        } else {
            timeLineView.backgroundColor = .systemGray4
        }
    }
}

// MARK: - LSHorizontalTimelineView

/// 水平时间线视图
public class LSHorizontalTimelineView: UIScrollView {

    // MARK: - 类型定义

    public typealias Item = LSTimelineView.TimelineItem
    public typealias ItemHandler = LSTimelineView.ItemHandler

    // MARK: - 属性

    /// 时间线数据
    public var items: [Item] = [] {
        didSet {
            updateTimeline()
        }
    }

    /// 图标大小
    public var iconSize: CGSize = CGSize(width: 40, height: 40) {
        didSet {
            updateTimeline()
        }
    }

    /// 项间距
    public var itemSpacing: CGFloat = 20 {
        didSet {
            updateTimeline()
        }
    }

    /// 内容边距
    public var contentInsets: UIEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16) {
        didSet {
            updateTimeline()
        }
    }

    /// 当前选中索引
    public private(set) var selectedIndex: Int = 0 {
        didSet {
            updateSelection()
        }
    }

    /// 项点击回调
    public var onItemTap: ItemHandler?

    /// 选择变化回调
    public var onSelectionChanged: ((Int) -> Void)?

    // MARK: - 私有属性

    private var itemViews: [LSHorizontalTimelineItemView] = []

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 20
        stack.alignment = .top
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupTimeline()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTimeline()
    }

    public convenience init(items: [Item] = []) {
        self.init(frame: .zero)
        self.items = items
    }

    // MARK: - 设置

    private func setupTimeline() {
        backgroundColor = .clear
        showsHorizontalScrollIndicator = true
        showsVerticalScrollIndicator = false

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: contentInsets.top),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: contentInsets.left),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -contentInsets.right),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -contentInsets.bottom),
            stackView.heightAnchor.constraint(equalTo: heightAnchor, constant: -contentInsets.top - contentInsets.bottom)
        ])
    }

    // MARK: - 更新

    private func updateTimeline() {
        // 移除旧的视图
        itemViews.forEach { $0.removeFromSuperview() }
        itemViews.removeAll()

        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // 创建新的视图
        for (index, item) in items.enumerated() {
            let itemView = LSHorizontalTimelineItemView(item: item)
            itemView.iconSize = iconSize
            itemView.isSelected = (index == selectedIndex)
            itemView.translatesAutoresizingMaskIntoConstraints = false
            itemView.tag = index

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleItemTap(_:)))
            itemView.addGestureRecognizer(tapGesture)
            itemView.isUserInteractionEnabled = true

            stackView.addArrangedSubview(itemView)
            itemViews.append(itemView)
        }

        stackView.spacing = itemSpacing

        setNeedsLayout()
    }

    private func updateSelection() {
        for (index, itemView) in itemViews.enumerated() {
            itemView.isSelected = (index == selectedIndex)
        }
        onSelectionChanged?(selectedIndex)
    }

    // MARK: - 手势处理

    @objc private func handleItemTap(_ gesture: UITapGestureRecognizer) {
        guard let index = gesture.view?.tag, index < items.count else { return }

        selectedIndex = index
        let item = items[index]
        onItemTap?(index, item)
    }

    // MARK: - 公共方法

    /// 选择项
    public func selectItem(at index: Int, animated: Bool = true) {
        guard index < items.count else { return }

        selectedIndex = index

        if animated {
            scrollToItem(at: index, animated: true)
        }
    }

    /// 滚动到指定项
    public func scrollToItem(at index: Int, animated: Bool = true) {
        guard index < itemViews.count else { return }

        let itemView = itemViews[index]
        let rect = convert(itemView.frame, to: contentView)
        scrollRectToVisible(rect, animated: animated)
    }

    /// 下一项
    public func selectNext() {
        let nextIndex = min(selectedIndex + 1, items.count - 1)
        selectItem(at: nextIndex, animated: true)
    }

    /// 上一项
    public func selectPrevious() {
        let previousIndex = max(selectedIndex - 1, 0)
        selectItem(at: previousIndex, animated: true)
    }
}

// MARK: - LSHorizontalTimelineItemView

/// 水平时间线项视图
private class LSHorizontalTimelineItemView: UIView {

    // MARK: - 属性

    var item: LSTimelineView.TimelineItem {
        didSet {
            updateContent()
        }
    }

    var iconSize: CGSize = CGSize(width: 40, height: 40) {
        didSet {
            updateConstraints()
        }
    }

    var isSelected: Bool = false {
        didSet {
            updateSelection()
        }
    }

    // MARK: - UI 组件

    private let iconContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let timeLineView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - 初始化

    init(item: LSTimelineView.TimelineItem) {
        self.item = item
        super.init(frame: .zero)
        setupItemView()
        updateContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 设置

    private func setupItemView() {
        addSubview(timeLineView)
        addSubview(iconContainerView)
        addSubview(titleLabel)
        iconContainerView.addSubview(iconImageView)

        NSLayoutConstraint.activate([
            iconContainerView.topAnchor.constraint(equalTo: topAnchor),
            iconContainerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconContainerView.widthAnchor.constraint(equalToConstant: iconSize.width),
            iconContainerView.heightAnchor.constraint(equalToConstant: iconSize.height),

            iconImageView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: iconSize.width * 0.5),
            iconImageView.heightAnchor.constraint(equalToConstant: iconSize.height * 0.5),

            titleLabel.topAnchor.constraint(equalTo: iconContainerView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            titleLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),

            timeLineView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
            timeLineView.leadingAnchor.constraint(equalTo: leadingAnchor),
            timeLineView.heightAnchor.constraint(equalToConstant: 2),
            timeLineView.widthAnchor.constraint(equalToConstant: 20)
        ])
    }

    // MARK: - 更新

    private func updateContent() {
        // 图标
        if let icon = item.icon {
            iconImageView.image = icon
            iconImageView.isHidden = false
        } else {
            iconImageView.isHidden = true
        }

        // 图标容器背景
        if let iconColor = item.iconColor {
            iconContainerView.backgroundColor = iconColor
            iconContainerView.layer.cornerRadius = iconSize.width / 2
        } else if item.isSelected {
            iconContainerView.backgroundColor = .systemBlue
            iconContainerView.layer.cornerRadius = iconSize.width / 2
        } else {
            iconContainerView.backgroundColor = .systemGray6
            iconContainerView.layer.cornerRadius = iconSize.width / 2
        }

        // 标题
        titleLabel.text = item.title

        updateSelection()
    }

    private func updateSelection() {
        if isSelected {
            timeLineView.backgroundColor = .systemBlue
        } else {
            timeLineView.backgroundColor = .systemGray4
        }
    }
}

// MARK: - Convenience Factory

public extension LSTimelineView {

    /// 创建垂直时间线
    static func vertical(items: [TimelineItem] = []) -> LSTimelineView {
        let timeline = LSTimelineView(items: items)
        timeline.direction = .vertical
        return timeline
    }

    /// 创建水平时间线
    static func horizontal(items: [TimelineItem] = []) -> LSHorizontalTimelineView {
        return LSHorizontalTimelineView(items: items)
    }

    /// 从日期创建时间线
    static func from(dates: [(date: Date, title: String?)]) -> [TimelineItem] {
        return dates.map { date, title in
            TimelineItem(title: title, date: date)
        }
    }

    /// 从字符串日期创建时间线
    static func from(dateStrings: [(dateString: String, format: String, title: String?)]) -> [TimelineItem] {
        let formatter = DateFormatter()
        return dateStrings.compactMap { dateString, format, title in
            formatter.dateFormat = format
            guard let date = formatter.date(from: dateString) else { return nil }
            return TimelineItem(title: title, date: date)
        }
    }
}

#endif

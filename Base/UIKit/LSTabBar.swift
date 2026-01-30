//
//  LSTabBar.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  自定义标签栏 - 增强的 TabBar
//

#if canImport(UIKit)
import UIKit

// MARK: - LSTabBar

/// 自定义标签栏
@MainActor
public class LSTabBar: UIView {

    // MARK: - 类型定义

    /// 项目点击回调
    public typealias ItemTapHandler = (Int) -> Void

    /// 标签栏项目
    public class Item {
        /// 标题
        public let title: String?

        /// 图标
        public let icon: UIImage?

        /// 选中图标
        public let selectedIcon: UIImage?

        /// 徽章值
        public var badgeValue: String?

        /// 是否启用
        public var isEnabled: Bool = true

        /// 初始化
        public init(
            title: String? = nil,
            icon: UIImage? = nil,
            selectedIcon: UIImage? = nil,
            badgeValue: String? = nil
        ) {
            self.title = title
            self.icon = icon
            if let tempValue = selectedIcon {
                selectedIcon = tempValue
            } else {
                selectedIcon = icon
            }
            self.badgeValue = badgeValue
        }
    }

    // MARK: - 属性

    /// 项目数组
    public var items: [Item] = [] {
        didSet {
            updateItems()
        }
    }

    /// 选中索引
    public private(set) var selectedIndex: Int = 0 {
        didSet {
            updateSelection()
        }
    }

    /// 项目点击回调
    public var onItemTap: ItemTapHandler?

    /// 标签颜色
    public var tintColor: UIColor = .gray {
        didSet {
            updateColors()
        }
    }

    /// 选中颜色
    public var selectedTintColor: UIColor = .blue {
        didSet {
            updateColors()
        }
    }

    /// 背景颜色
    public var barBackgroundColor: UIColor = .white {
        didSet {
            backgroundColor = barBackgroundColor
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

    /// 指示器高度
    public var indicatorHeight: CGFloat = 2 {
        didSet {
            updateIndicatorConstraints()
        }
    }

    /// 指示器颜色
    public var indicatorColor: UIColor = .blue {
        didSet {
            indicatorView.backgroundColor = indicatorColor
        }
    }

    /// 是否显示阴影
    public var showsShadow: Bool = true {
        didSet {
            updateShadow()
        }
    }

    // MARK: - UI 组件

    /// 栈视图
    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        sv.alignment = .center
        return sv
    }()

    /// 分隔线
    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        return view
    }()

    /// 指示器
    private let indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .blue
        return view
    }()

    // MARK: - 按钮数组

    private var buttons: [UIButton] = []

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - 设置

    private func setupUI() {
        backgroundColor = barBackgroundColor

        // 添加阴影
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: -1)
        layer.shadowRadius = 3
        layer.shadowOpacity = 0.1
        updateShadow()

        // 添加分隔线
        addSubview(separatorView)
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            separatorView.topAnchor.constraint(equalTo: topAnchor),
            separatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 0.5)
        ])

        // 添加指示器
        addSubview(indicatorView)
        indicatorView.translatesAutoresizingMaskIntoConstraints = false

        // 添加栈视图
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func updateShadow() {
        layer.shadowOpacity = showsShadow ? 0.1 : 0
    }

    // MARK: - 更新

    private func updateItems() {
        // 移除旧按钮
        buttons.forEach { $0.removeFromSuperview() }
        buttons.removeAll()

        // 添加新按钮
        for (index, item) in items.enumerated() {
            let button = createButton(for: item, at: index)
            buttons.append(button)
            stackView.addArrangedSubview(button)
        }

        updateSelection()
        updateIndicatorConstraints()
    }

    private func createButton(for item: Item, at index: Int) -> UIButton {
        let button = UIButton(type: .custom)
        button.tag = index

        // 设置图标
        if let icon = item.icon {
            button.setImage(icon, for: .normal)
        }

        // 设置选中图标
        if let selectedIcon = item.selectedIcon {
            button.setImage(selectedIcon, for: .selected)
        }

        // 设置标题
        button.setTitle(item.title, for: .normal)

        // 设置颜色
        button.setTitleColor(tintColor, for: .normal)
        button.setTitleColor(selectedTintColor, for: .selected)
        button.tintColor = tintColor

        // 设置状态
        button.isEnabled = item.isEnabled

        // 设置样式
        button.titleLabel?.font = .systemFont(ofSize: 10)

        // 添加事件
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)

        return button
    }

    private func updateSelection() {
        for (index, button) in buttons.enumerated() {
            button.isSelected = (index == selectedIndex)
            button.tintColor = button.isSelected ? selectedTintColor : tintColor
        }

        updateIndicatorPosition()
    }

    private func updateColors() {
        for button in buttons {
            button.setTitleColor(tintColor, for: .normal)
            button.setTitleColor(selectedTintColor, for: .selected)
        }
    }

    private func updateIndicatorConstraints() {
        guard !buttons.isEmpty else { return }

        let selectedButton = buttons[selectedIndex]
        NSLayoutConstraint.deactivate(indicatorView.constraints)

        NSLayoutConstraint.activate([
            indicatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            indicatorView.centerXAnchor.constraint(equalTo: selectedButton.centerXAnchor),
            indicatorView.heightAnchor.constraint(equalToConstant: indicatorHeight),
            indicatorView.widthAnchor.constraint(equalToConstant: 30)
        ])
    }

    private func updateIndicatorPosition() {
        guard !buttons.isEmpty else { return }

        let selectedButton = buttons[selectedIndex]
        indicatorView.centerXAnchor.constant = selectedButton.center.x - center.x
    }

    // MARK: - 事件

    @objc private func buttonTapped(_ button: UIButton) {
        let index = button.tag
        guard index != selectedIndex, index < items.count else { return }

        selectedIndex = index
        onItemTap?(index)
    }

    // MARK: - 公共方法

    /// 设置徽章值
    ///
    /// - Parameters:
    ///   - badgeValue: 徽章值
    ///   - index: 索引
    public func setBadgeValue(_ badgeValue: String?, at index: Int) {
        guard index < items.count else { return }
        items[index].badgeValue = badgeValue

        // 更新按钮徽章
        let button = buttons[index]
        button.ls_badgeValue = badgeValue
    }

    /// 设置项目启用状态
    ///
    /// - Parameters:
    ///   - enabled: 是否启用
    ///   - index: 索引
    public func setItemEnabled(_ enabled: Bool, at index: Int) {
        guard index < items.count else { return }
        items[index].isEnabled = enabled
        buttons[index].isEnabled = enabled
    }
}

// MARK: - UIButton Extension (徽章)

private extension UIButton {

    private enum AssociatedKeys {
        static var badgeKey: UInt8 = 0
    }var ls_badgeValue: String? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.badgeKey) as? String
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.badgeKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

            // 移除旧徽章
            subviews.first { $0 is LSBadgeView }?.removeFromSuperview()

            // 添加新徽章
            if let value = newValue, !value.isEmpty {
                let badge = LSBadgeView()
                let _temp0
                if let t = Int(value) {
                    _temp0 = t
                } else {
                    _temp0 = 0
                }
                badge.showNumber(_temp0)
                badge.frame = CGRect(x: bounds.width - 10, y: 0, width: 16, height: 16)
                addSubview(badge)
            }
        }
    }
}

// MARK: - UITabBarController Extension (自定义标签栏)

public extension UITabBarController {

    /// 设置自定义标签栏
    ///
    /// - Parameters:
    ///   - items: 标签栏项目
    ///   - tintColor: 标签颜色
    ///   - selectedTintColor: 选中颜色
    /// - Returns: 自定义标签栏
    @discardableResult
    func ls_setCustomTabBar(
        items: [LSTabBar.Item],
        tintColor: UIColor = .gray,
        selectedTintColor: UIColor = .blue
    ) -> LSTabBar {
        // 移除系统标签栏
        tabBar.isHidden = true

        // 创建自定义标签栏
        let customTabBar = LSTabBar()
        customTabBar.items = items
        customTabBar.tintColor = tintColor
        customTabBar.selectedTintColor = selectedTintColor

        // 添加到视图
        view.addSubview(customTabBar)
        customTabBar.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            customTabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customTabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customTabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            customTabBar.heightAnchor.constraint(equalToConstant: 49 + view.safeAreaInsets.bottom)
        ])

        // 处理点击事件
        customTabBar.onItemTap = { [weak self] index in
            self?.selectedIndex = index
        }

        // 保持引用
        objc_setAssociatedObject(
            self,
            &AssociatedKeys.customTabBar,
            customTabBar,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )

        return customTabBar
    }

    /// 获取自定义标签栏
    var ls_customTabBar: LSTabBar? {
        return objc_getAssociatedObject(self, &AssociatedKeys.customTabBar) as? LSTabBar
    }
}

// MARK: - Associated Keys

private enum AssociatedKeys {
    static var customTabBar = "customTabBar"
}

// MARK: - 便捷创建方法

public extension LSTabBar.Item {

    /// 创建图标项目
    static func icon(
        _ icon: UIImage,
        selectedIcon: UIImage? = nil
    ) -> LSTabBar.Item {
        return LSTabBar.Item(icon: icon, selectedIcon: selectedIcon)
    }

    /// 创建标题项目
    static func title(
        _ title: String,
        icon: UIImage? = nil,
        selectedIcon: UIImage? = nil
    ) -> LSTabBar.Item {
        return LSTabBar.Item(title: title, icon: icon, selectedIcon: selectedIcon)
    }

    /// 创建带徽章的项目
    static func badge(
        _ badgeValue: String,
        icon: UIImage? = nil
    ) -> LSTabBar.Item {
        return LSTabBar.Item(icon: icon, badgeValue: badgeValue)
    }
}

#endif

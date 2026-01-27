//
//  LSMenuView.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  菜单视图 - 下拉/弹出菜单组件
//

#if canImport(UIKit)
import UIKit

// MARK: - LSMenuView

/// 菜单视图
public class LSMenuView: UIView {

    // MARK: - 类型定义

    /// 菜单项
    public struct Item {
        let title: String
        let image: UIImage?
        let isSelected: Bool
        let isEnabled: Bool
        let action: (() -> Void)?

        public init(
            title: String,
            image: UIImage? = nil,
            isSelected: Bool = false,
            isEnabled: Bool = true,
            action: (() -> Void)? = nil
        ) {
            self.title = title
            self.image = image
            self.isSelected = isSelected
            self.isEnabled = isEnabled
            self.action = action
        }
    }

    /// 菜单配置
    public struct Configuration {
        var backgroundColor: UIColor = .systemBackground
        var itemHeight: CGFloat = 44
        var maxMenuHeight: CGFloat = 300
        var cornerRadius: CGFloat = 8
        var shadowColor: UIColor = .black
        var shadowOpacity: Float = 0.2
        var shadowRadius: CGFloat = 8
        var shadowOffset: CGSize = CGSize(width: 0, height: 2)
        var separatorColor: UIColor = .separator
        var showsSeparator: Bool = true

        public init() {}
    }

    /// 菜单位置
    public enum MenuPosition {
        case automatic
        case below
        case above
        case right
        case left
    }

    /// 菜单方向
    public enum MenuDirection {
        case vertical
        case horizontal
    }

    // MARK: - 属性

    /// 菜单项
    public var items: [Item] = [] {
        didSet {
            updateItems()
        }
    }

    /// 配置
    public var configuration: Configuration = Configuration() {
        didSet {
            applyConfiguration()
        }
    }

    /// 菜单位置
    public var position: MenuPosition = .automatic

    /// 菜单方向
    public var direction: MenuDirection = .vertical

    /// 锚点视图
    public weak var anchorView: UIView?

    /// 菜单关闭回调
    public var onMenuDismiss: (() -> Void)?

    // MARK: - UI 组件

    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private var menuButtons: [UIButton] = []

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupMenu()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupMenu()
    }

    public init(items: [Item], configuration: Configuration = Configuration()) {
        self.items = items
        self.configuration = configuration
        super.init(frame: .zero)
        setupMenu()
    }

    // MARK: - 设置

    private func setupMenu() {
        addSubview(containerView)
        containerView.addSubview(stackView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        applyConfiguration()
        updateItems()
    }

    // MARK: - 更新

    private func applyConfiguration() {
        let config = configuration

        containerView.backgroundColor = config.backgroundColor
        containerView.layer.cornerRadius = config.cornerRadius
        containerView.layer.masksToBounds = false

        containerView.layer.shadowColor = config.shadowColor.cgColor
        containerView.layer.shadowOpacity = config.shadowOpacity
        containerView.layer.shadowRadius = config.shadowRadius
        containerView.layer.shadowOffset = config.shadowOffset

        stackView.axis = direction == .vertical ? .horizontal : .vertical
    }

    private func updateItems() {
        // 移除旧的按钮
        menuButtons.forEach { $0.removeFromSuperview() }
        menuButtons.removeAll()

        for (index, item) in items.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(item.title, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 16)
            button.setImage(item.image, for: .normal)
            button.isEnabled = item.isEnabled
            button.alpha = item.isEnabled ? 1.0 : 0.5

            if item.isSelected {
                button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
                button.backgroundColor = configuration.separatorColor.withAlphaComponent(0.3)
            }

            button.translatesAutoresizingMaskIntoConstraints = false
            button.heightAnchor.constraint(equalToConstant: configuration.itemHeight).isActive = true

            button.ls_addAction(for: .touchUpInside) { [weak self] in
                item.action?()
                self?.dismiss()
            }

            // 添加分隔线
            if configuration.showsSeparator && index > 0 {
                let separator = UIView()
                separator.backgroundColor = configuration.separatorColor
                separator.translatesAutoresizingMaskIntoConstraints = false
                separator.heightAnchor.constraint(equalToConstant: 0.5).isActive = true

                stackView.addArrangedSubview(separator)
            }

            stackView.addArrangedSubview(button)
            menuButtons.append(button)
        }
    }

    // MARK: - 公共方法

    /// 显示菜单
    func show(from view: UIView, position: MenuPosition = .automatic) {
        anchorView = view
        self.position = position

        guard let window = view.window else { return }

        // 计算位置
        let menuFrame = calculateMenuFrame(from: view, in: window)

        frame = menuFrame
        window.addSubview(self)

        // 动画显示
        alpha = 0
        transform = CGAffineTransform(scaleX: 0.9, y: 0.9)

        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: .curveEaseOut
        ) {
            self.alpha = 1
            self.transform = .identity
        }
    }

    /// 隐藏菜单
    func dismiss() {
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: .curveEaseIn
        ) {
            self.alpha = 0
            self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        } completion: { _ in
            self.removeFromSuperview()
            self.onMenuDismiss?()
        }
    }

    // MARK: - 位置计算

    private func calculateMenuFrame(from view: UIView, in window: UIWindow) -> CGRect {
        let viewFrame = view.convert(view.bounds, to: window)

        var menuWidth = view.bounds.width
        var menuHeight: CGFloat = 0

        // 计算菜单高度
        for button in menuButtons {
            menuHeight += configuration.itemHeight
        }

        if configuration.showsSeparator {
            menuHeight += CGFloat(items.count - 1) * 0.5
        }

        // 限制最大高度
        menuHeight = min(menuHeight, configuration.maxMenuHeight)

        // 计算 X 位置
        var x = viewFrame.origin.x

        // 计算 Y 位置
        var y: CGFloat

        switch position {
        case .automatic:
            let spaceBelow = window.bounds.height - viewFrame.maxY
            let spaceAbove = viewFrame.minY

            if spaceBelow >= menuHeight || spaceBelow >= spaceAbove {
                y = viewFrame.maxY + 4
            } else {
                y = viewFrame.minY - menuHeight - 4
            }

        case .below:
            y = viewFrame.maxY + 4

        case .above:
            y = viewFrame.minY - menuHeight - 4

        case .right:
            x = viewFrame.maxX + 4
            y = viewFrame.minY

        case .left:
            x = viewFrame.minX - menuWidth - 4
            y = viewFrame.minY
        }

        return CGRect(x: x, y: y, width: menuWidth, height: menuHeight)
    }
}

// MARK: - UIButton Extension (Menu)

public extension UIButton {

    /// 关联的菜单视图
    private static var menuViewKey: UInt8 = 0

    var ls_menuView: LSMenuView? {
        get {
            return objc_getAssociatedObject(self, &UIButton.menuViewKey) as? LSMenuView
        }
        set {
            objc_setAssociatedObject(
                self,
                &UIButton.menuViewKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// 设置下拉菜单
    func ls_setMenu(
        items: [LSMenuView.Item],
        configuration: LSMenuView.Configuration = LSMenuView.Configuration(),
        position: LSMenuView.MenuPosition = .automatic
    ) {
        // 移除旧菜单
        ls_removeMenu()

        let menu = LSMenuView(items: items, configuration: configuration)
        ls_menuView = menu

        // 添加箭头图标
        let arrow = UIImage(systemName: "chevron.down")
        setImage(arrow, for: .normal)
        ls_setImageTitleSpacing(4)

        // 点击事件
        ls_addAction(for: .touchUpInside) { [weak self] in
            guard let self = self else { return }

            if let menu = self.ls_menuView {
                if menu.superview == nil {
                    menu.show(from: self, position: position)
                } else {
                    menu.dismiss()
                }
            }
        }
    }

    /// 移除菜单
    func ls_removeMenu() {
        ls_menuView?.dismiss()
        ls_menuView = nil
    }

    /// 是否显示菜单
    var ls_isShowingMenu: Bool {
        return ls_menuView?.superview != nil
    }
}

// MARK: - UIBarButtonItem Extension (Menu)

public extension UIBarButtonItem {

    /// 关联的菜单视图
    private static var menuViewKey: UInt8 = 0

    var ls_menuView: LSMenuView? {
        get {
            return objc_getAssociatedObject(self, &UIBarButtonItem.menuViewKey) as? LSMenuView
        }
        set {
            objc_setAssociatedObject(
                self,
                &UIBarButtonItem.menuViewKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// 设置下拉菜单
    func ls_setMenu(
        items: [LSMenuView.Item],
        configuration: LSMenuView.Configuration = LSMenuView.Configuration()
    ) {
        // 移除旧菜单
        ls_removeMenu()

        let menu = LSMenuView(items: items, configuration: configuration)
        ls_menuView = menu

        // 点击事件
        let action = #selector(handleMenuTap)
        target = self
        selector = NSSelectorFromString(String(format: "%d:", action.hashValue))

        // 保存原始 selector
        let originalActionKey = AssociatedKey.originalActionKey
        objc_setAssociatedObject(self, originalActionKey, action, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    @objc private func handleMenuTap() {
        guard let menu = ls_menuView,
              let barButtonView = value(forKey: "view") as? UIView else {
            return
        }

        if menu.superview == nil {
            menu.show(from: barButtonView, position: .automatic)
        } else {
            menu.dismiss()
        }
    }

    /// 移除菜单
    func ls_removeMenu() {
        ls_menuView?.dismiss()
        ls_menuView = nil
    }
}

// MARK: - 便捷菜单创建

public extension LSMenuView {

    /// 创建简单菜单
    static func create(
        titles: [String],
        images: [UIImage?] = [],
        selection: @escaping (Int) -> Void
    ) -> LSMenuView {
        let items: [Item] = titles.enumerated().map { index, title in
            let image = index < images.count ? images[index] : nil
            return Item(title: title, image: image) {
                selection(index)
            }
        }

        return LSMenuView(items: items)
    }

    /// 创建带图标的菜单
    static func create(
        items: [(title: String, image: UIImage?)],
        selection: @escaping (Int) -> Void
    ) -> LSMenuView {
        let menuItems: [Item] = items.enumerated().map { index, item in
            return Item(title: item.title, image: item.image) {
                selection(index)
            }
        }

        return LSMenuView(items: menuItems)
    }

    /// 创建确认菜单
    static func confirm(
        title: String,
        message: String? = nil,
        confirmTitle: String = "确定",
        cancelTitle: String = "取消",
        confirmAction: @escaping () -> Void
    ) -> LSMenuView {
        var items: [Item] = []

        if let message = message {
            items.append(Item(title: message, isEnabled: false, action: nil))
        }

        items.append(Item(title: cancelTitle, action: nil))
        items.append(Item(title: confirmTitle, action: confirmAction))

        var config = Configuration()
        config.itemHeight = 44

        return LSMenuView(items: items, configuration: config)
    }
}

// MARK: - Context Menu (iOS 13+)

@available(iOS 13.0, *)
public extension UIViewController {

    /// 显示上下文菜单
    func ls_showContextMenu(
        items: [UIAction],
        location: CGPoint = .zero
    ) {
        let menu = UIContextMenuController()

        let menuItems = items.map { item in
            UIAction(
                title: item.title,
                image: item.image,
                identifier: nil,
                discoverabilityTitle: nil,
                attributes: item.attributes,
                state: item.state
            ) { _ in
                item.handler?()
            }
        }

        menu.menu = UIMenu(title: "", children: menuItems)

        if let tableView = view as? UITableView {
            // TableView 需要特殊处理
        } else {
            // 普通视图
            addInteraction(UIContextMenuInteraction(delegate: ContextMenuDelegate()))
        }
    }
}

@available(iOS 13.0, *)
private class ContextMenuDelegate: NSObject, UIContextMenuInteractionDelegate {
    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAt location: CGPoint
    ) -> UIContextMenuConfiguration? {
        return nil
    }
}

// MARK: - Associated Keys

private struct AssociatedKey {
    static var originalActionKey: UInt8 = 0
}

// MARK: - UIAction Extension

@available(iOS 13.0, *)
public extension UIAction {

    /// 创建操作
    static func ls_create(
        title: String,
        image: UIImage? = nil,
        attributes: UIMenuElement.Attributes = [],
        handler: (() -> Void)? = nil
    ) -> UIAction {
        return UIAction(
            title: title,
            image: image,
            identifier: nil,
            discoverabilityTitle: nil,
            attributes: attributes,
            state: .off
        ) { _ in
            handler?()
        }
    }

    /// 创建取消操作
    static func ls_cancel(
        title: String = "取消",
        handler: (() -> Void)? = nil
    ) -> UIAction {
        return ls_create(
            title: title,
            attributes: .destructive,
            handler: handler
        )
    }

    /// 创建删除操作
    static func ls_delete(
        title: String = "删除",
        handler: (() -> Void)? = nil
    ) -> UIAction {
        return ls_create(
            title: title,
            image: UIImage(systemName: "trash"),
            attributes: .destructive,
            handler: handler
        )
    }
}

#endif

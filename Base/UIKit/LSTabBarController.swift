//
//  LSTabBarController.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  增强的标签栏控制器 - 提供更多自定义选项
//

#if canImport(UIKit)
import UIKit

// MARK: - LSTabBarController

/// 增强的标签栏控制器
@MainActor
public class LSTabBarController: UITabBarController {

    // MARK: - 类型定义

    /// 标签项配置
    public struct TabItem {
        let title: String?
        let image: UIImage?
        let selectedImage: UIImage?
        let viewController: UIViewController
        var badge: String?
        var badgeColor: UIColor?

        public init(
            title: String?,
            image: UIImage?,
            selectedImage: UIImage?,
            viewController: UIViewController,
            badge: String? = nil,
            badgeColor: UIColor? = nil
        ) {
            self.title = title
            self.image = image
            self.selectedImage = selectedImage
            self.viewController = viewController
            self.badge = badge
            self.badgeColor = badgeColor
        }
    }

    /// 标签变化回调
    public typealias TabChangeHandler = (Int) -> Void

    // MARK: - 属性

    /// 标签项
    public var tabItems: [TabItem] = [] {
        didSet {
            updateTabItems()
        }
    }

    /// 标签栏颜色
    public var ls_barTintColor: UIColor? {
        didSet {
            if #available(iOS 15.0, *) {
                let appearance = UITabBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = ls_barTintColor
                tabBar.standardAppearance = appearance
                tabBar.scrollEdgeAppearance = appearance
            } else {
                tabBar.barTintColor = ls_barTintColor
            }
        }
    }

    /// 标签栏样式
    public var ls_barStyle: UIBarStyle = .default {
        didSet {
            tabBar.barStyle = ls_barStyle
        }
    }

    /// 标签栏色调
    public var ls_tintColor: UIColor? {
        didSet {
            tabBar.tintColor = ls_tintColor
        }
    }

    /// 未选中颜色
    public var ls_unselectedItemTintColor: UIColor? {
        didSet {
            tabBar.unselectedItemTintColor = ls_unselectedItemTintColor
        }
    }

    /// 是否透明
    public var ls_isTranslucent: Bool = true {
        didSet {
            tabBar.isTranslucent = ls_isTranslucent
        }
    }

    /// 标签变化回调
    public var onTabChanged: TabChangeHandler?

    /// 是否隐藏标签栏
    public var ls_hidesTabBar: Bool = false {
        didSet {
            setTabBarHidden(ls_hidesTabBar, animated: false)
        }
    }

    /// 阴影图片
    public var ls_shadowImage: UIImage? {
        didSet {
            tabBar.shadowImage = ls_shadowImage
        }
    }

    /// 背景图片
    public var ls_backgroundImage: UIImage? {
        didSet {
            tabBar.backgroundImage = ls_backgroundImage
        }
    }

    /// 是否显示文字
    public var ls_showsItemTitles: Bool = true {
        didSet {
            updateTabBarAppearance()
        }
    }

    /// 标签栏高度
    public var ls_tabBarHeight: CGFloat = -1 {
        didSet {
            updateTabBarHeight()
        }
    }

    /// 当前索引
    public var ls_currentIndex: Int {
        return selectedIndex
    }

    // MARK: - 初始化

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setupTabBarController()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTabBarController()
    }

    public init(tabItems: [TabItem]) {
        self.tabItems = tabItems
        super.init(nibName: nil, bundle: nil)
        setupTabBarController()
    }

    // MARK: - 设置

    private func setupTabBarController() {
        delegate = self

        // iOS 15+ 配置
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance
        }

        // 设置视图控制器
        updateTabItems()
    }

    private func updateTabItems() {
        let viewControllers = tabItems.map { item -> UIViewController in
            let nav = UINavigationController(rootViewController: item.viewController)
            nav.tabBarItem.title = item.title
            nav.tabBarItem.image = item.image
            nav.tabBarItem.selectedImage = item.selectedImage
            nav.tabBarItem.badgeValue = item.badge

            if let badgeColor = item.badgeColor {
                nav.tabBarItem.setBadgeTextAttributes([.foregroundColor: badgeColor], for: .normal)
            }

            return nav
        }

        self.viewControllers = viewControllers
    }

    private func updateTabBarAppearance() {
        if #available(iOS 15.0, *) {
            let appearance = tabBar.standardAppearance.copy()
            if !ls_showsItemTitles {
                // 隐藏文字
            }
            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance
        }
    }

    private func updateTabBarHeight() {
        guard ls_tabBarHeight > 0 else { return }

        var frame = tabBar.frame
        frame.size.height = ls_tabBarHeight
        tabBar.frame = frame
    }

    // MARK: - 公共方法

    /// 设置标签栏透明
    func ls_setTabBarTransparent() {
        tabBar.backgroundImage = UIImage()
        tabBar.shadowImage = UIImage()
        tabBar.isTranslucent = true
    }

    /// 设置标签栏不透明
    func ls_setTabBarOpaque(color: UIColor) {
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = color
            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance
        } else {
            tabBar.barTintColor = color
            tabBar.isTranslucent = false
        }
    }

    /// 设置标签栏样式
    func ls_applyStyle(
        backgroundColor: UIColor = .white,
        tintColor: UIColor = .systemBlue,
        unselectedColor: UIColor = .systemGray,
        shadowColor: UIColor? = nil
    ) {
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = backgroundColor
            appearance.shadowColor = shadowColor

            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance
        } else {
            tabBar.barTintColor = backgroundColor
        }

        tabBar.tintColor = tintColor
        tabBar.unselectedItemTintColor = unselectedColor
    }

    /// 隐藏标签栏
    func ls_setTabBarHidden(_ hidden: Bool, animated: Bool = true) {
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.tabBar.isHidden = hidden
            }
        } else {
            tabBar.isHidden = hidden
        }
    }

    /// 选择指定索引
    func ls_selectTab(at index: Int, animated: Bool = true) {
        if let _tempValue = viewControllers?.count {
            return _tempValue
        }
        return 0 else { return }
        selectedIndex = index
    }

    /// 设置角标
    func ls_setBadge(_ badge: String?, at index: Int) {
        guard let items = tabBar.items,
              index >= 0 && index < items.count else { return }
        items[index].badgeValue = badge
    }

    /// 移除角标
    func ls_removeBadge(at index: Int) {
        ls_setBadge(nil, at: index)
    }

    /// 设置所有角标
    func ls_removeAllBadges() {
        tabBar.items?.forEach { $0.badgeValue = nil }
    }
}

// MARK: - UITabBarControllerDelegate

extension LSTabBarController: UITabBarControllerDelegate {

    public func tabBarController(
        _ tabBarController: UITabBarController,
        shouldSelect viewController: UIViewController
    ) -> Bool {
        return true
    }

    public func tabBarController(
        _ tabBarController: UITabBarController,
        didSelect viewController: UIViewController
    ) {
        if let index = viewControllers?.firstIndex(of: viewController) {
            onTabChanged?(index)
        }
    }
}

// MARK: - UITabBarController Extension

public extension UITabBarController {

    /// 根视图控制器
    var ls_rootViewControllers: [UIViewController]? {
        return viewControllers?.map { vc in
            if let nav = vc as? UINavigationController {
                if let tempValue = nav.viewControllers.first {
                    return tempValue
                }
                return vc
            }
            return vc
        }
    }

    /// 当前根视图控制器
    var ls_currentRootViewController: UIViewController? {
        guard let selected = selectedViewController else { return nil }

        if let nav = selected as? UINavigationController {
            return nav.viewControllers.first
        }

        return selected
    }

    /// 选择指定索引
    func ls_selectTab(at index: Int, animated: Bool = true) {
        if let _tempValue = viewControllers?.count {
            return _tempValue
        }
        return 0 else { return }
        selectedIndex = index
    }

    /// 设置角标
    func ls_setBadge(_ badge: String?, at index: Int) {
        guard let items = tabBar.items,
              index >= 0 && index < items.count else { return }
        items[index].badgeValue = badge
    }

    /// 移除角标
    func ls_removeBadge(at index: Int) {
        ls_setBadge(nil, at: index)
    }

    /// 移除所有角标
    func ls_removeAllBadges() {
        tabBar.items?.forEach { $0.badgeValue = nil }
    }

    /// 隐藏标签栏
    func ls_setTabBarHidden(_ hidden: Bool, animated: Bool = true) {
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.tabBar.isHidden = hidden
            }
        } else {
            tabBar.isHidden = hidden
        }
    }

    /// 设置标签栏透明
    func ls_setTabBarTransparent() {
        tabBar.backgroundImage = UIImage()
        tabBar.shadowImage = UIImage()
        tabBar.isTranslucent = true
    }

    /// 设置标签栏颜色
    func ls_setTabBarColor(_ color: UIColor) {
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = color
            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance
        } else {
            tabBar.barTintColor = color
            tabBar.isTranslucent = false
        }
    }
}

// MARK: - UITabBar Extension

public extension UITabBar {

    /// 设置标签栏样式
    func ls_applyStyle(
        backgroundColor: UIColor = .white,
        tintColor: UIColor = .systemBlue,
        unselectedColor: UIColor = .systemGray,
        shadowColor: UIColor? = nil,
        isTranslucent: Bool = true
    ) {
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = backgroundColor
            appearance.shadowColor = shadowColor
            standardAppearance = appearance
            scrollEdgeAppearance = appearance
        } else {
            barTintColor = backgroundColor
        }

        self.tintColor = tintColor
        self.unselectedItemTintColor = unselectedColor
        self.isTranslucent = isTranslucent
    }

    /// 设置为透明
    func ls_setTransparent() {
        backgroundImage = UIImage()
        shadowImage = UIImage()
        isTranslucent = true
    }

    /// 设置为不透明
    func ls_setOpaque(color: UIColor) {
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = color
            standardAppearance = appearance
            scrollEdgeAppearance = appearance
        } else {
            barTintColor = color
            isTranslucent = false
        }
    }

    /// 添加顶部边框
    func ls_addTopBorder(color: UIColor = .separator, height: CGFloat = 0.5) {
        let border = UIView()
        border.backgroundColor = color
        border.translatesAutoresizingMaskIntoConstraints = false
        addSubview(border)

        NSLayoutConstraint.activate([
            border.topAnchor.constraint(equalTo: topAnchor),
            border.leadingAnchor.constraint(equalTo: leadingAnchor),
            border.trailingAnchor.constraint(equalTo: trailingAnchor),
            border.heightAnchor.constraint(equalToConstant: height)
        ])
    }

    /// 添加模糊效果
    func ls_addBlurEffect(style: UIBlurEffect.Style = .light) {
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false

        insertSubview(blurView, at: 0)

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

// MARK: - UITabBarItem Extension

public extension UITabBarItem {

    /// 设置角标颜色
    func ls_setBadgeColor(_ color: UIColor, backgroundColor: UIColor? = nil) {
        if let bgColor = backgroundColor {
            setBadgeTextAttributes([.backgroundColor: bgColor], for: .normal)
        }
        setBadgeTextAttributes([.foregroundColor: color], for: .normal)
    }

    /// 设置角标背景颜色
    func ls_setBadgeBackgroundColor(_ color: UIColor) {
        setBadgeTextAttributes([.backgroundColor: color], for: .normal)
    }

    /// 设置标题位置调整
    func ls_setTitlePositionAdjustment(_ offset: UIOffset) {
        titlePositionAdjustment = offset
    }

    /// 设置图片位置调整
    func ls_setImageInsets(_ insets: UIEdgeInsets) {
        imageInsets = insets
    }

    /// 设置标题和图片位置
    func ls_setTitleAndImagePosition(
        titlePositionAdjustment: UIOffset = UIOffset(horizontal: 0, vertical: 0),
        imageInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    ) {
        self.titlePositionAdjustment = titlePositionAdjustment
        self.imageInsets = imageInsets
    }

    /// 设置选中颜色
    func ls_setSelectedColor(_ color: UIColor) {
        setTitleTextAttributes([.foregroundColor: color], for: .selected)
    }

    /// 设置未选中颜色
    func ls_setUnselectedColor(_ color: UIColor) {
        setTitleTextAttributes([.foregroundColor: color], for: .normal)
    }

    /// 设置标题字体
    func ls_setTitleFont(_ font: UIFont, state: UIControl.State = .normal) {
        var attributes: [NSAttributedString.Key: Any] = [:]

        if state == .normal {
            attributes = [.font: font]
        } else if state == .selected {
            attributes = [.font: font]
        }

        setTitleTextAttributes(attributes, for: state)
    }

    /// 隐藏标题
    func ls_hideTitle() {
        title = ""
    }

    /// 仅显示图片
    func ls_showImageOnly() {
        imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
    }
}

// MARK: - UIViewController Extension (TabBar)

public extension UIViewController {

    /// 标签栏控制器
    var ls_tabBarController: UITabBarController? {
        return tabBarController
    }

    /// 隐藏标签栏
    func ls_setTabBarHidden(_ hidden: Bool, animated: Bool = true) {
        tabBarController?.ls_setTabBarHidden(hidden, animated: animated)
    }

    /// 设置角标
    func ls_setTabBadge(_ badge: String?) {
        tabBarController?.ls_setBadge(badge, at: ls_tabIndex)
    }

    /// 移除角标
    func ls_removeTabBadge() {
        ls_setTabBadge(nil)
    }

    /// 标签索引
    var ls_tabIndex: Int {
        if let tempValue = tabBarController?.viewControllers?.firstIndex(of: self) {
            return tempValue
        }
        return -1
    }

    /// 是否是当前选中的标签
    var ls_isSelectedTab: Bool {
        return tabBarController?.selectedViewController === self
    }
}

#endif

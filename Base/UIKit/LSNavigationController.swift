//
//  LSNavigationController.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  增强的导航控制器 - 提供更多自定义选项
//

#if canImport(UIKit)
import UIKit

// MARK: - LSNavigationController

/// 增强的导航控制器
@MainActor
public class LSNavigationController: UINavigationController {

    // MARK: - 属性

    /// 是否隐藏导航栏
    public var ls_hidesNavigationBar: Bool = false {
        didSet {
            setNavigationBarHidden(ls_hidesNavigationBar, animated: false)
        }
    }

    /// 是否透明
    public var ls_isTranslucent: Bool = true {
        didSet {
            navigationBar.isTranslucent = ls_isTranslucent
        }
    }

    /// 导航栏颜色
    public var ls_barTintColor: UIColor? {
        didSet {
            if #available(iOS 13.0, *) {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = ls_barTintColor

                navigationBar.standardAppearance = appearance
                navigationBar.scrollEdgeAppearance = appearance
            } else {
                navigationBar.barTintColor = ls_barTintColor
            }
        }
    }

    /// 导航栏样式
    public var ls_barStyle: UIBarStyle = .default {
        didSet {
            navigationBar.barStyle = ls_barStyle
        }
    }

    /// 导航栏色调
    public var ls_tintColor: UIColor? {
        didSet {
            navigationBar.tintColor = ls_tintColor
        }
    }

    /// 标题颜色
    public var ls_titleColor: UIColor? {
        didSet {
            if #available(iOS 13.0, *) {
                let appearance = navigationBar.standardAppearance.copy()
                if let titleColor = ls_titleColor {
                    appearance.titleTextAttributes = [.foregroundColor: titleColor]
                    appearance.largeTitleTextAttributes = [.foregroundColor: titleColor]
                }
                navigationBar.standardAppearance = appearance
                navigationBar.scrollEdgeAppearance = appearance
            }
        }
    }

    /// 阴影图片
    public var ls_shadowImage: UIImage? {
        didSet {
            navigationBar.shadowImage = ls_shadowImage
        }
    }

    /// 背景图片
    public var ls_backgroundImage: UIImage? {
        didSet {
            navigationBar.backgroundImage(for: .default)
        }
    }

    /// 是否隐藏底部阴影
    public var ls_hidesShadow: Bool = false {
        didSet {
            navigationBar.shadowImage = ls_hidesShadow ? UIImage() : nil
            navigationBar.setBackgroundImage(ls_hidesShadow ? UIImage() : nil, for: .default)
        }
    }

    /// 偏移手势识别器
    public var ls_interactivePopGestureRecognizerEnabled: Bool = true {
        didSet {
            interactivePopGestureRecognizer?.isEnabled = ls_interactivePopGestureRecognizerEnabled
        }
    }

    /// 全屏手势返回
    public var ls_fullScreenPopGestureEnabled: Bool = false {
        didSet {
            setupFullScreenPopGesture()
        }
    }

    // MARK: - 私有属性

    private var popGestureDelegate: UIGestureRecognizerDelegate?

    // MARK: - 初始化

    public override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        setupNavigationController()
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setupNavigationController()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupNavigationController()
    }

    // MARK: - 设置

    private func setupNavigationController() {
        // 默认透明
        navigationBar.isTranslucent = true

        // iOS 15+ 配置
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
            navigationBar.compactScrollEdgeAppearance = appearance
        }

        // iOS 13-14 配置
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
        }

        // 设置代理
        delegate = self
    }

    private func setupFullScreenPopGesture() {
        guard ls_fullScreenPopGestureEnabled,
              let popGesture = interactivePopGestureRecognizer else {
            return
        }

        popGesture.isEnabled = true
        popGestureDelegate = popGesture.delegate

        // 添加全屏手势
        let panGesture = UIPanGestureRecognizer(
            target: self,
            action: #selector(handleFullScreenPopGesture(_:))
        )
        view.addGestureRecognizer(panGesture)
    }

    // MARK: - 全屏手势

    @objc private func handleFullScreenPopGesture(_ gesture: UIPanGestureRecognizer) {
        guard ls_fullScreenPopGestureEnabled else { return }

        let translation = gesture.translation(in: view)
        let percent = translation.x / view.bounds.width

        switch gesture.state {
        case .began:
            // 开始手势
            break

        case .changed:
            // 手势变化
            break

        case .ended, .cancelled:
            if percent > 0.3 {
                popViewController(animated: true)
            }
            gesture.setTranslation(.zero, in: view)

        default:
            break
        }
    }

    // MARK: - 公共方法

    /// 设置导航栏透明
    func ls_setNavigationBarTransparent() {
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        navigationBar.isTranslucent = true
    }

    /// 设置导航栏不透明
    func ls_setNavigationBarOpaque(color: UIColor) {
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = color
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
        } else {
            navigationBar.barTintColor = color
            navigationBar.isTranslucent = false
        }
    }

    /// 设置导航栏样式
    func ls_applyStyle(
        backgroundColor: UIColor = .white,
        tintColor: UIColor = .systemBlue,
        titleColor: UIColor = .label,
        shadowColor: UIColor? = nil
    ) {
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = backgroundColor
            appearance.shadowColor = shadowColor
            appearance.titleTextAttributes = [.foregroundColor: titleColor]
            appearance.largeTitleTextAttributes = [.foregroundColor: titleColor]

            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
            navigationBar.compactScrollEdgeAppearance = appearance
        } else {
            navigationBar.barTintColor = backgroundColor
            navigationBar.tintColor = tintColor
            navigationBar.titleTextAttributes = [.foregroundColor: titleColor]
            navigationBar.largeTitleTextAttributes = [.foregroundColor: titleColor]
        }
    }

    /// 移除所有视图控制器
    func ls_removeAllViewControllers() {
        viewControllers.removeAll()
    }

    /// 替换根视图控制器
    func ls_replaceRootViewController(_ viewController: UIViewController, animated: Bool = true) {
        if animated {
            setViewControllers([viewController], animated: true)
        } else {
            viewControllers = [viewController]
        }
    }
}

// MARK: - UINavigationControllerDelegate

extension LSNavigationController: UINavigationControllerDelegate {

    public func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        // 处理即将显示的视图控制器
    }

    public func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        // 处理已显示的视图控制器
        interactivePopGestureRecognizer?.isEnabled = viewControllers.count > 1
    }
}

// MARK: - UINavigationController Extension

public extension UINavigationController {

    /// 根视图控制器
    var ls_rootViewController: UIViewController? {
        return viewControllers.first
    }

    /// 是否可以返回
    var ls_canPop: Bool {
        return viewControllers.count > 1
    }

    /// 返回到指定类名的视图控制器
    func ls_popToViewController(ofClass viewControllerClass: AnyClass, animated: Bool = true) {
        for viewController in viewControllers.reversed() {
            if type(of: viewController) == viewControllerClass {
                popToViewController(viewController, animated: animated)
                return
            }
        }
    }

    /// 返回到根视图控制器
    func ls_popToRoot(animated: Bool = true) {
        popToRootViewController(animated: animated)
    }

    /// 移除指定类名的视图控制器
    func ls_removeViewController(ofClass viewControllerClass: AnyClass) {
        viewControllers = viewControllers.filter { type(of: $0) != viewControllerClass }
    }

    /// 移除当前视图控制器之前的所有视图控制器
    func ls_removeAllViewControllersBeforeCurrent() {
        guard let current = topViewController else { return }
        viewControllers = [current]
    }

    /// 替换当前视图控制器
    func ls_replaceTopViewController(_ viewController: UIViewController, animated: Bool = true) {
        var controllers = viewControllers
        controllers.removeLast()
        controllers.append(viewController)

        if animated {
            setViewControllers(controllers, animated: true)
        } else {
            viewControllers = controllers
        }
    }

    /// 设置导航栏透明
    func ls_setNavigationBarTransparent() {
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        navigationBar.isTranslucent = true
    }

    /// 设置导航栏不透明
    func ls_setNavigationBarOpaque(color: UIColor) {
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = color
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
        } else {
            navigationBar.barTintColor = color
            navigationBar.isTranslucent = false
        }
    }

    /// 设置导航栏样式
    func ls_applyStyle(
        backgroundColor: UIColor = .white,
        tintColor: UIColor = .systemBlue,
        titleColor: UIColor = .label,
        shadowColor: UIColor? = nil
    ) {
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = backgroundColor
            appearance.shadowColor = shadowColor
            appearance.titleTextAttributes = [.foregroundColor: titleColor]
            appearance.largeTitleTextAttributes = [.foregroundColor: titleColor]

            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
            navigationBar.compactScrollEdgeAppearance = appearance
        } else {
            navigationBar.barTintColor = backgroundColor
            navigationBar.tintColor = tintColor
            navigationBar.titleTextAttributes = [.foregroundColor: titleColor]
            navigationBar.largeTitleTextAttributes = [.foregroundColor: titleColor]
        }
    }
}

// MARK: - UIViewController Extension (Navigation)

public extension UIViewController {

    /// 导航控制器
    var ls_navigationController: UINavigationController? {
        return navigationController
    }

    /// 推入视图控制器
    @discardableResult
    func ls_push(_ viewController: UIViewController, animated: Bool = true) -> UIViewController? {
        navigationController?.pushViewController(viewController, animated: animated)
        return viewController
    }

    /// 弹出视图控制器
    @discardableResult
    func ls_pop(animated: Bool = true) -> UIViewController? {
        return navigationController?.popViewController(animated: animated)
    }

    /// 弹出到根视图控制器
    func ls_popToRoot(animated: Bool = true) {
        navigationController?.ls_popToRoot(animated: animated)
    }

    /// 是否可以返回
    var ls_canPop: Bool {
        if let tempValue = navigationController?.ls_canPop {
            return tempValue
        }
        return false
    }

    /// 设置导航栏标题
    func ls_setNavigationBarTitle(_ title: String) {
        navigationItem.title = title
    }

    /// 设置大标题
    func ls_setLargeTitleDisplayMode(_ mode: UINavigationItem.LargeTitleDisplayMode) {
        navigationItem.largeTitleDisplayMode = mode
    }

    /// 添加左侧按钮
    func ls_addLeftBarButtonItem(
        _ image: UIImage? = nil,
        title: String? = nil,
        action: @escaping () -> Void
    ) {
        let button: UIButton
        if let image = image {
            button = UIButton(type: .system)
            button.setImage(image, for: .normal)
        } else if let title = title {
            button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
        } else {
            return
        }

        button.ls_addAction(for: .touchUpInside) { _ in
            action()
        }

        let barButtonItem = UIBarButtonItem(customView: button)
        navigationItem.leftBarButtonItem = barButtonItem
    }

    /// 添加右侧按钮
    func ls_addRightBarButtonItem(
        _ image: UIImage? = nil,
        title: String? = nil,
        action: @escaping () -> Void
    ) {
        let button: UIButton
        if let image = image {
            button = UIButton(type: .system)
            button.setImage(image, for: .normal)
        } else if let title = title {
            button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
        } else {
            return
        }

        button.ls_addAction(for: .touchUpInside) { _ in
            action()
        }

        let barButtonItem = UIBarButtonItem(customView: button)
        navigationItem.rightBarButtonItem = barButtonItem
    }

    /// 添加返回按钮
    func ls_addBackButton(action: @escaping () -> Void) {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let image = UIImage(systemName: "chevron.left", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.setTitle("返回", for: .normal)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 0)

        button.ls_addAction(for: .touchUpInside) { _ in
            action()
        }

        let barButtonItem = UIBarButtonItem(customView: button)
        navigationItem.leftBarButtonItem = barButtonItem
    }

    /// 隐藏导航栏
    func ls_setNavigationBarHidden(_ hidden: Bool, animated: Bool = true) {
        navigationController?.setNavigationBarHidden(hidden, animated: animated)
    }

    /// 设置导航栏透明
    func ls_setNavigationBarTransparent() {
        navigationController?.ls_setNavigationBarTransparent()
    }

    /// 设置导航栏颜色
    func ls_setNavigationBarColor(_ color: UIColor) {
        navigationController?.ls_setNavigationBarOpaque(color: color)
    }
}

// MARK: - UINavigationBar Extension

public extension UINavigationBar {

    /// 设置导航栏样式
    func ls_applyStyle(
        backgroundColor: UIColor = .white,
        tintColor: UIColor = .systemBlue,
        titleColor: UIColor = .label,
        shadowColor: UIColor? = nil,
        isTranslucent: Bool = true
    ) {
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = backgroundColor
            appearance.shadowColor = shadowColor
            appearance.titleTextAttributes = [.foregroundColor: titleColor]
            appearance.largeTitleTextAttributes = [.foregroundColor: titleColor]

            standardAppearance = appearance
            scrollEdgeAppearance = appearance
            compactScrollEdgeAppearance = appearance
        } else {
            barTintColor = backgroundColor
            tintColor = tintColor
            titleTextAttributes = [.foregroundColor: titleColor]
            largeTitleTextAttributes = [.foregroundColor: titleColor]
        }

        self.isTranslucent = isTranslucent
    }

    /// 设置为透明
    func ls_setTransparent() {
        setBackgroundImage(UIImage(), for: .default)
        shadowImage = UIImage()
        isTranslucent = true
    }

    /// 设置为不透明
    func ls_setOpaque(color: UIColor) {
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = color
            standardAppearance = appearance
            scrollEdgeAppearance = appearance
        } else {
            barTintColor = color
            isTranslucent = false
        }
    }
}

// MARK: - UINavigationItem Extension

public extension UINavigationItem {

    /// 设置标题视图
    func ls_setTitleView(_ view: UIView) {
        titleView = view
    }

    /// 设置自定义标题视图
    func ls_setCustomTitle(
        title: String,
        font: UIFont = .boldSystemFont(ofSize: 17),
        color: UIColor = .label
    ) {
        let label = UILabel()
        label.text = title
        label.font = font
        label.textColor = color
        label.sizeToFit()
        titleView = label
    }

    /// 设置多行标题
    func ls_setMultilineTitle(
        title: String,
        font: UIFont = .boldSystemFont(ofSize: 17),
        color: UIColor = .label
    ) {
        let label = UILabel()
        label.text = title
        label.font = font
        label.textColor = color
        label.numberOfLines = 0
        label.textAlignment = .center
        label.sizeToFit()
        titleView = label
    }
}

#endif

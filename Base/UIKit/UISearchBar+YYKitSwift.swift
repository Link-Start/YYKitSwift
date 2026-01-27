//
//  LSSearchBar.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  搜索栏增强 - 为 UISearchBar 添加额外功能
//

#if canImport(UIKit)
import UIKit

// MARK: - UISearchBar Extension

public extension UISearchBar {

    // MARK: - 样式定制

    /// 设置搜索栏颜色
    ///
    /// - Parameters:
    ///   - tintColor: 主色调
    ///   - barTintColor: 背景色
    func ls_setColor(tintColor: UIColor, barTintColor: UIColor) {
        self.tintColor = tintColor
        self.barTintColor = barTintColor

        if let textField = ls_textField {
            textField.textColor = tintColor
        }
    }

    /// 设置圆角样式
    ///
    /// - Parameter cornerRadius: 圆角半径
    func ls_setCornerRadius(_ cornerRadius: CGFloat) {
        if let textField = ls_textField {
            textField.layer.cornerRadius = cornerRadius
            textField.clipsToBounds = true
        }
    }

    /// 设置搜索框背景图片
    ///
    /// - Parameters:
    ///   - image: 背景图片
    ///   - state: 状态
    func ls_setSearchFieldBackgroundImage(_ image: UIImage?, for state: UIControl.State) {
        setSearchFieldBackgroundImage(image, for: state)
    }

    /// 设置搜索图标
    ///
    /// - Parameters:
    ///   - icon: 图标
    ///   - mode: 渲染模式
    func ls_setSearchIcon(_ icon: UIImage, mode: UIImage.RenderingMode = .alwaysTemplate) {
        let templateIcon = icon.withRenderingMode(mode)
        setImage(templateIcon, for: .search, state: .normal)
    }

    /// 设置清除图标
    ///
    /// - Parameters:
    ///   - icon: 图标
    ///   - mode: 渲染模式
    func ls_setClearIcon(_ icon: UIImage, mode: UIImage.RenderingMode = .alwaysTemplate) {
        let templateIcon = icon.withRenderingMode(mode)
        setImage(templateIcon, for: .clear, state: .normal)
    }

    /// 设置搜索结果图标
    ///
    /// - Parameters:
    ///   - icon: 图标
    ///   - mode: 渲染模式
    func ls_setResultsListIcon(_ icon: UIImage, mode: UIImage.RenderingMode = .alwaysTemplate) {
        let templateIcon = icon.withRenderingMode(mode)
        setImage(templateIcon, for: .resultsList, state: .normal)
    }

    // MARK: - 文本框访问

    /// 获取内部的 UITextField
    var ls_textField: UITextField? {
        if #available(iOS 13.0, *) {
            return searchTextField
        } else {
            let subviews = subviews.flatMap { $0.subviews }
            for view in subviews {
                if let textField = view as? UITextField {
                    return textField
                }
            }
            return nil
        }
    }

    /// 获取搜索文本
    var ls_searchText: String? {
        get { return text }
        set { text = newValue }
    }

    /// 搜索文本颜色
    var ls_textColor: UIColor? {
        get { return ls_textField?.textColor }
        set { ls_textField?.textColor = newValue }
    }

    /// 占位符
    var ls_placeholder: String? {
        get { return placeholder }
        set { placeholder = newValue }
    }

    /// 占位符颜色
    var ls_placeholderColor: UIColor? {
        get {
            guard let textField = ls_textField else { return nil }
            return textField.value(forKey: "_placeholderLabel") as? UILabel?.textColor
        }
        set {
            if let textField = ls_textField,
               let placeholderLabel = textField.value(forKey: "_placeholderLabel") as? UILabel {
                placeholderLabel.textColor = newValue
            }
        }
    }

    /// 字体
    var ls_font: UIFont? {
        get { return ls_textField?.font }
        set { ls_textField?.font = newValue }
    }

    // MARK: - 光标控制

    /// 光标颜色
    var ls_cursorColor: UIColor? {
        get { return ls_textField?.tintColor }
        set { ls_textField?.tintColor = newValue }
    }

    /// 开始编辑
    func ls_beginEditing() {
        becomeFirstResponder()
    }

    /// 结束编辑
    func ls_endEditing() {
        resignFirstResponder()
    }

    /// 是否正在编辑
    var ls_isEditing: Bool {
        return isFirstResponder
    }

    // MARK: - 动画控制

    /// 显示取消按钮（带动画）
    ///
    /// - Parameter animated: 是否动画
    func ls_showCancelButton(animated: Bool = true) {
        setShowsCancelButton(true, animated: animated)
    }

    /// 隐藏取消按钮（带动画）
    ///
    /// - Parameter animated: 是否动画
    func ls_hideCancelButton(animated: Bool = true) {
        setShowsCancelButton(false, animated: animated)
    }

    // MARK: - 快捷配置

    /// 配置为简洁样式
    func ls_configureMinimalStyle() {
        searchBarStyle = .minimal
        isTranslucent = true
        setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
    }

    /// 配置为默认样式
    func ls_configureDefaultStyle() {
        searchBarStyle = .default
        isTranslucent = true
    }

    /// 配置为 prominent 样式
    func ls_configureProminentStyle() {
        searchBarStyle = .prominent
        isTranslucent = false
    }

    /// 配置深色主题
    func ls_configureDarkTheme() {
        barTintColor = .darkGray
        tintColor = .white
        ls_textColor = .white
        ls_placeholderColor = .lightGray
        if let textField = ls_textField {
            textField.keyboardAppearance = .dark
        }
    }

    /// 配置浅色主题
    func ls_configureLightTheme() {
        barTintColor = .white
        tintColor = .blue
        ls_textColor = .black
        ls_placeholderColor = .gray
        if let textField = ls_textField {
            textField.keyboardAppearance = .light
        }
    }
}

// MARK: - SearchBar 代理助手

/// SearchBar 代理助手
public class LSSearchBarDelegateHelper: NSObject {

    // MARK: - 类型定义

    /// 文本变化回调
    public typealias TextChangeHandler = (String) -> Void

    /// 搜索按钮点击回调
    public typealias SearchHandler = (String) -> Void

    /// 取消按钮点击回调
    public typealias CancelHandler = () -> Void

    /// 开始编辑回调
    public typealias BeginEditingHandler = () -> Void

    /// 结束编辑回调
    public typealias EndEditingHandler = () -> Void

    // MARK: - 属性

    /// 文本变化回调
    public var onTextChange: TextChangeHandler?

    /// 搜索按钮点击回调
    public var onSearch: SearchHandler?

    /// 取消按钮点击回调
    public var onCancel: CancelHandler?

    /// 开始编辑回调
    public var onBeginEditing: BeginEditingHandler?

    /// 结束编辑回调
    public var onEndEditing: EndEditingHandler?

    /// 搜索栏
    public weak var searchBar: UISearchBar? {
        didSet {
            searchBar?.delegate = self
        }
    }

    /// 最小搜索字符数
    public var minimumSearchLength: Int = 0

    /// 延迟搜索时间（秒）
    public var searchDelay: TimeInterval = 0.3

    private var searchWorkItem: DispatchWorkItem?

    // MARK: - 初始化

    /// 创建助手
    ///
    /// - Parameter searchBar: 搜索栏
    public init(searchBar: UISearchBar? = nil) {
        super.init()
        self.searchBar = searchBar
        searchBar?.delegate = self
    }

    // MARK: - 便捷初始化

    /// 创建助手并配置回调
    ///
    /// - Parameters:
    ///   - searchBar: 搜索栏
    ///   - onSearch: 搜索回调
    ///   - onCancel: 取消回调
    /// - Returns: 助手实例
    public static func configure(
        searchBar: UISearchBar,
        onSearch: @escaping SearchHandler,
        onCancel: @escaping CancelHandler? = nil
    ) -> LSSearchBarDelegateHelper {
        let helper = LSSearchBarDelegateHelper(searchBar: searchBar)
        helper.onSearch = onSearch
        helper.onCancel = onCancel
        return helper
    }

    /// 创建助手并配置实时搜索
    ///
    /// - Parameters:
    ///   - searchBar: 搜索栏
    ///   - delay: 延迟时间（秒）
    ///   - onTextChange: 文本变化回调
    /// - Returns: 助手实例
    public static func configureRealTimeSearch(
        searchBar: UISearchBar,
        delay: TimeInterval = 0.3,
        onTextChange: @escaping TextChangeHandler
    ) -> LSSearchBarDelegateHelper {
        let helper = LSSearchBarDelegateHelper(searchBar: searchBar)
        helper.searchDelay = delay
        helper.onTextChange = onTextChange
        return helper
    }
}

// MARK: - UISearchBarDelegate

extension LSSearchBarDelegateHelper: UISearchBarDelegate {

    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // 取消之前的延迟搜索
        searchWorkItem?.cancel()

        // 触发文本变化回调
        onTextChange?(searchText)

        // 如果有搜索回调，延迟执行
        if let onSearch = onSearch, searchText.count >= minimumSearchLength {
            let workItem = DispatchWorkItem {
                if searchBar.text == searchText {
                    onSearch(searchText)
                }
            }
            searchWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + searchDelay, execute: workItem)
        }
    }

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // 取消延迟搜索
        searchWorkItem?.cancel()

        let searchText = searchBar.text ?? ""
        if searchText.count >= minimumSearchLength {
            onSearch?(searchText)
        }

        searchBar.resignFirstResponder()
    }

    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        onCancel?()
    }

    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        onBeginEditing?()
    }

    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        onEndEditing?()
    }
}

// MARK: - SearchBar 样式配置

public extension UISearchBar {

    /// 配置搜索栏外观
    ///
    /// - Parameters:
    ///   - tintColor: 主色调
    ///   - barTintColor: 背景色
    ///   - textColor: 文本颜色
    ///   - placeholderColor: 占位符颜色
    ///   - cornerRadius: 圆角半径
    func ls_configureAppearance(
        tintColor: UIColor? = nil,
        barTintColor: UIColor? = nil,
        textColor: UIColor? = nil,
        placeholderColor: UIColor? = nil,
        cornerRadius: CGFloat? = nil
    ) {
        if let tintColor = tintColor {
            self.tintColor = tintColor
        }

        if let barTintColor = barTintColor {
            self.barTintColor = barTintColor
        }

        if let textColor = textColor {
            self.ls_textColor = textColor
        }

        if let placeholderColor = placeholderColor {
            self.ls_placeholderColor = placeholderColor
        }

        if let cornerRadius = cornerRadius {
            self.ls_setCornerRadius(cornerRadius)
        }
    }

    /// 应用自定义样式配置
    ///
    /// - Parameter configuration: 样式配置
    func ls_applyStyle(_ configuration: SearchBarStyleConfiguration) {
        ls_configureAppearance(
            tintColor: configuration.tintColor,
            barTintColor: configuration.barTintColor,
            textColor: configuration.textColor,
            placeholderColor: configuration.placeholderColor,
            cornerRadius: configuration.cornerRadius
        )
        if let backgroundImage = configuration.backgroundImage {
            setSearchFieldBackgroundImage(backgroundImage, for: .normal)
        }
        if let searchIcon = configuration.searchIcon {
            ls_setSearchIcon(searchIcon, mode: configuration.iconRenderingMode ?? .alwaysTemplate)
        }
    }
}

// MARK: - SearchBarStyleConfiguration

/// 搜索栏样式配置
public struct SearchBarStyleConfiguration {

    /// 主色调
    public var tintColor: UIColor?

    /// 背景色
    public var barTintColor: UIColor?

    /// 文本颜色
    public var textColor: UIColor?

    /// 占位符颜色
    public var placeholderColor: UIColor?

    /// 圆角半径
    public var cornerRadius: CGFloat?

    /// 背景图片
    public var backgroundImage: UIImage?

    /// 搜索图标
    public var searchIcon: UIImage?

    /// 图标渲染模式
    public var iconRenderingMode: UIImage.RenderingMode?

    /// 创建配置
    public init(
        tintColor: UIColor? = nil,
        barTintColor: UIColor? = nil,
        textColor: UIColor? = nil,
        placeholderColor: UIColor? = nil,
        cornerRadius: CGFloat? = nil,
        backgroundImage: UIImage? = nil,
        searchIcon: UIImage? = nil,
        iconRenderingMode: UIImage.RenderingMode? = nil
    ) {
        self.tintColor = tintColor
        self.barTintColor = barTintColor
        self.textColor = textColor
        self.placeholderColor = placeholderColor
        self.cornerRadius = cornerRadius
        self.backgroundImage = backgroundImage
        self.searchIcon = searchIcon
        self.iconRenderingMode = iconRenderingMode
    }

    /// 浅色主题配置
    public static var light: SearchBarStyleConfiguration {
        return SearchBarStyleConfiguration(
            tintColor: .blue,
            barTintColor: .white,
            textColor: .black,
            placeholderColor: .gray,
            cornerRadius: 8
        )
    }

    /// 深色主题配置
    public static var dark: SearchBarStyleConfiguration {
        return SearchBarStyleConfiguration(
            tintColor: .white,
            barTintColor: .darkGray,
            textColor: .white,
            placeholderColor: .lightGray,
            cornerRadius: 8
        )
    }

    /// 自定义配置
    public static func custom(
        primary: UIColor,
        background: UIColor,
        text: UIColor,
        placeholder: UIColor,
        cornerRadius: CGFloat = 8
    ) -> SearchBarStyleConfiguration {
        return SearchBarStyleConfiguration(
            tintColor: primary,
            barTintColor: background,
            textColor: text,
            placeholderColor: placeholder,
            cornerRadius: cornerRadius
        )
    }
}

#endif

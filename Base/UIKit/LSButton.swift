//
//  LSButton.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  增强的按钮 - 提供多种按钮样式和状态
//

#if canImport(UIKit)
import UIKit

// MARK: - LSButton

@MainActor
/// 增强的按钮
public class LSButton: UIButton {

    // MARK: - 样式枚举

    /// 按钮样式
    public enum Style {
        case primary             // 主要按钮
        case secondary           // 次要按钮
        case outline            // 轮廓按钮
        case text               // 文本按钮
        case danger             // 危险按钮
        case custom              // 自定义
    }

    // MARK: - 属性

    /// 按钮样式
    public var style: Style = .primary {
        didSet {
            updateStyle()
        }
    }

    /// 加载状态
    public private(set) var isLoading: Bool = false {
        didSet {
            isUserInteractionEnabled = !isLoading
            updateLoadingState()
        }
    }

    /// 是否禁用
    public var isDisabled: Bool = false {
        didSet {
            isEnabled = !isDisabled
            alpha = isDisabled ? 0.5 : 1.0
        }
    }

    /// 活动指示器
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    /// 原始标题
    private var originalTitle: String?

    /// 加载时显示的文本
    public var loadingText: String = "加载中..."

    // MARK: - 初始化

    public init(style: Style = .primary) {
        self.style = style
        super.init(frame: .zero)
        setupUI()
    }

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
        layer.cornerRadius = 8
        layer.masksToBounds = true
        titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)

        addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        updateStyle()
    }

    private func updateStyle() {
        switch style {
        case .primary:
            backgroundColor = .systemBlue
            setTitleColor(.white, for: .normal)
            setTitleColor(.white.withAlphaComponent(0.5), for: .disabled)

        case .secondary:
            backgroundColor = .systemGray5
            setTitleColor(.label, for: .normal)
            setTitleColor(.secondaryLabel, for: .disabled)

        case .outline:
            backgroundColor = .clear
            setTitleColor(.systemBlue, for: .normal)
            setTitleColor(.systemBlue.withAlphaComponent(0.5), for: .disabled)
            layer.borderWidth = 1
            layer.borderColor = UIColor.systemBlue.cgColor

        case .text:
            backgroundColor = .clear
            setTitleColor(.systemBlue, for: .normal)
            setTitleColor(.systemBlue.withAlphaComponent(0.5), for: .disabled)

        case .danger:
            backgroundColor = .systemRed
            setTitleColor(.white, for: .normal)
            setTitleColor(.white.withAlphaComponent(0.5), for: .disabled)

        case .custom:
            break
        }
    }

    // MARK: - 加载状态

    private func updateLoadingState() {
        if isLoading {
            originalTitle = title(for: .normal)
            setTitle(loadingText, for: .normal)
            activityIndicator.startAnimating()
            activityIndicator.isHidden = false
        } else {
            if let originalTitle = originalTitle {
                setTitle(originalTitle, for: .normal)
            }
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
        }
    }

    // MARK: - 公共方法

    /// 开始加载
    public func startLoading() {
        isLoading = true
    }

    /// 停止加载
    public func stopLoading() {
        isLoading = false
    }

    /// 禁用按钮
    public func disable() {
        isDisabled = true
    }

    /// 启用按钮
    public func enable() {
        isDisabled = false
    }
}

// MARK: - 便捷方法

public extension LSButton {

    /// 创建主要按钮
    ///
    /// - Parameter title: 标题
    /// - Returns: 按钮
    static func primary(title: String) -> LSButton {
        let button = LSButton(style: .primary)
        button.setTitle(title, for: .normal)
        return button
    }

    /// 创建次要按钮
    ///
    /// - Parameter title: 标题
    /// - Returns: 按钮
    static func secondary(title: String) -> LSButton {
        let button = LSButton(style: .secondary)
        button.setTitle(title, for: .normal)
        return button
    }

    /// 创建轮廓按钮
    ///
    /// - Parameter title: 标题
    /// - Returns: 按钮
    static func outline(title: String) -> LSButton {
        let button = LSButton(style: .outline)
        button.setTitle(title, for: .normal)
        return button
    }

    /// 创建文本按钮
    ///
    /// - Parameter title: 标题
    /// - Returns: 按钮
    static func text(title: String) -> LSButton {
        let button = LSButton(style: .text)
        button.setTitle(title, for: .normal)
        return button
    }

    /// 创建危险按钮
    ///
    /// - Parameter title: 标题
    /// - Returns: 按钮
    static func danger(title: String) -> LSButton {
        let button = LSButton(style: .danger)
        button.setTitle(title, for: .normal)
        return button
    }
}

// MARK: - UIButton Extension (样式)

public extension UIButton {

    /// 关联的原始标题
    private static var originalTitleKey: UInt8 = 0

    /// 原始标题
    var ls_originalTitle: String? {
        get {
            return objc_getAssociatedObject(self, &UIButton.originalTitleKey) as? String
        }
        set {
            objc_setAssociatedObject(self, &UIButton.originalTitleKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMATIC)
        }
    }

    /// 开始加载状态
    func ls_startLoading(loadingText: String = "加载中...") {
        ls_originalTitle = title(for: .normal)
        setTitle(loadingText, for: .normal)
        isEnabled = false
    }

    /// 结束加载状态
    func ls_stopLoading() {
        if let originalTitle = ls_originalTitle {
            setTitle(originalTitle, for: .normal)
        }
        isEnabled = true
        ls_originalTitle = nil
    }

    /// 设置主要按钮样式
    ///
    /// - Parameters:
    ///   - backgroundColor: 背景颜色
    ///   - titleColor: 标题颜色
    func ls_applyPrimaryStyle(
        backgroundColor: UIColor = .systemBlue,
        titleColor: UIColor = .white
    ) {
        self.backgroundColor = backgroundColor
        setTitleColor(titleColor, for: .normal)
        setTitleColor(titleColor.withAlphaComponent(0.5), for: .disabled)
        layer.cornerRadius = 8
        layer.masksToBounds = true
        titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
    }

    /// 设置次要按钮样式
    ///
    /// - Parameters:
    ///   - backgroundColor: 背景颜色
    ///   - titleColor: 标题颜色
    func ls_applySecondaryStyle(
        backgroundColor: UIColor = .systemGray5,
        titleColor: UIColor = .label
    ) {
        self.backgroundColor = backgroundColor
        setTitleColor(titleColor, for: .normal)
        setTitleColor(.secondaryLabel, for: .disabled)
        layer.cornerRadius = 8
        layer.masksToBounds = true
    }

    /// 设置轮廓按钮样式
    ///
    /// - Parameters:
    ///   - borderColor: 边框颜色
    ///   - titleColor: 标题颜色
    func ls_applyOutlineStyle(
        borderColor: UIColor = .systemBlue,
        titleColor: UIColor = .systemBlue
    ) {
        backgroundColor = .clear
        setTitleColor(titleColor, for: .normal)
        setTitleColor(titleColor.withAlphaComponent(0.5), for: .disabled)
        layer.borderWidth = 1
        layer.borderColor = borderColor.cgColor
        layer.cornerRadius = 8
        layer.masksToBounds = true
    }

    /// 设置文本按钮样式
    ///
    /// - Parameter titleColor: 标题颜色
    func ls_applyTextStyle(titleColor: UIColor = .systemBlue) {
        backgroundColor = .clear
        setTitleColor(titleColor, for: .normal)
        setTitleColor(titleColor.withAlphaComponent(0.5), for: .disabled)
    }

    /// 设置危险按钮样式
    ///
    /// - Parameters:
    ///   - backgroundColor: 背景颜色
    ///   - titleColor: 标题颜色
    func ls_applyDangerStyle(
        backgroundColor: UIColor = .systemRed,
        titleColor: UIColor = .white
    ) {
        self.backgroundColor = backgroundColor
        setTitleColor(titleColor, for: .normal)
        setTitleColor(titleColor.withAlphaComponent(0.5), for: .disabled)
        layer.cornerRadius = 8
        layer.masksToBounds = true
    }

    /// 设置圆角
    ///
    /// - Parameter cornerRadius: 圆角半径
    func ls_setCornerRadius(_ cornerRadius: CGFloat) {
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true
    }

    /// 设置圆形
    func ls_setCircular() {
        clipsToBounds = true
        layer.cornerRadius = frame.height / 2
    }

    /// 设置图标
    ///
    /// - Parameter image: 图标
    /// - Parameter position: 图标位置
    func ls_setIcon(
        _ image: UIImage?,
        position: UIControl.ContentHorizontalAlignment = .left
    ) {
        imageView?.image = image
        imageEdgeInsets = .zero
    }

    /// 设置图标和文本间距
    ///
    /// - Parameter spacing: 间距
    func ls_setImageTitleSpacing(_ spacing: CGFloat) {
        let spacing = spacing
        imageEdgeInsets = UIEdgeInsets(
            top: 0,
            left: -spacing / 2,
            bottom: 0,
            right: spacing / 2
        )
        titleEdgeInsets = UIEdgeInsets(
            top: 0,
            left: spacing / 2,
            bottom: 0,
            right: -spacing / 2
        )
        contentEdgeInsets = UIEdgeInsets(
            top: 0,
            left: spacing,
            bottom: 0,
            right: spacing
        )
    }
}

// MARK: - 浮动按钮样式

public extension UIButton {

    /// 浮动阴影样式
    ///
    /// - Parameters:
    ///   - color: 按钮颜色
    ///   - shadowColor: 阴影颜色
    func ls_applyFloatingStyle(
        color: UIColor = .systemBlue,
        shadowColor: UIColor = .black
    ) {
        backgroundColor = color
        setTitleColor(.white, for: .normal)
        layer.cornerRadius = bounds.height / 2
        layer.masksToBounds = false

        // 添加阴影
        layer.shadowColor = shadowColor.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 4
    }
}

// MARK: - 块级按钮样式

public extension UIButton {

    /// 块级按钮样式
    ///
    /// - Parameters:
    ///   - color: 背景颜色
    ///   - titleColor: 标题颜色
    func ls_applyBlockStyle(
        color: UIColor = .systemBlue,
        titleColor: UIColor = .white
    ) {
        backgroundColor = color
        setTitleColor(titleColor, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        layer.cornerRadius = 0
    }
}

// MARK: - 网格按钮样式

public extension UIButton {

    /// 网格按钮样式
    ///
    /// - Parameters:
    ///   - color: 背景颜色
    ///   - titleColor: 标题颜色
    func ls_applyGridStyle(
        color: UIColor = .systemGray6,
        titleColor: UIColor = .label
    ) {
        backgroundColor = color
        setTitleColor(titleColor, for: .normal)
        setTitleColor(titleColor.withAlphaComponent(0.5), for: .highlighted)
        layer.cornerRadius = 0
    }
}

#endif

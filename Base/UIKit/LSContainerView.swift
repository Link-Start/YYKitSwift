//
//  LSContainerView.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  容器视图 - 简化多视图容器管理
//

#if canImport(UIKit)
import UIKit

// MARK: - LSStackView

/// 堆栈视图（类似 UIStackView 但更灵活）
@MainActor
public class LSStackView: UIView {

    // MARK: - 轴类型

    /// 轴方向
    public enum Axis {
        case horizontal
        case vertical
    }

    /// 分布方式
    public enum Distribution {
        case fill           // 填充
        case fillEqually    // 等分填充
        case equalSpacing   // 等间距
        case equalCentering  // 中心等距
    }

    /// 对齐方式
    public enum Alignment {
        case leading
        case center
        case trailing
        case fill
    }

    // MARK: - 属性

    /// 轴方向
    public var axis: Axis = .horizontal {
        didSet {
            setNeedsLayout()
        }
    }

    /// 分布方式
    public var distribution: Distribution = .fill {
        didSet {
            setNeedsLayout()
        }
    }

    /// 对齐方式
    public var alignment: Alignment = .center {
        didSet {
            setNeedsLayout()
        }
    }

    /// 间距
    public var spacing: CGFloat = 8 {
        didSet {
            setNeedsLayout()
        }
    }

    /// 子视图
    public var arrangedSubviews: [UIView] = [] {
        didSet {
            oldValue.forEach { $0.removeFromSuperview() }
            arrangedSubviews.forEach { addSubview($0) }
            setNeedsLayout()
        }
    }

    // MARK: - 初始化

    public init(frame: CGRect = .zero) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    /// 便捷初始化
    ///
    /// - Parameters:
    ///   - axis: 轴方向
    ///   - spacing: 间距
    ///   - alignment: 对齐方式
    ///   - distribution: 分布方式
    convenience init(
        axis: Axis = .horizontal,
        spacing: CGFloat = 8,
        alignment: Alignment = .center,
        distribution: Distribution = .fill
    ) {
        self.init(frame: .zero)
        self.axis = axis
        self.spacing = spacing
        self.alignment = alignment
        self.distribution = distribution
    }

    // MARK: - 布局

    public override func layoutSubviews() {
        super.layoutSubviews()

        guard !arrangedSubviews.isEmpty else { return }

        switch axis {
        case .horizontal:
            layoutHorizontal()
        case .vertical:
            layoutVertical()
        }
    }

    private func layoutHorizontal() {
        let spacing = self.spacing
        var x: CGFloat = 0

        for (index, view) in arrangedSubviews.enumerated() {
            view.frame.origin = CGPoint(x: x, y: 0)

            let size: CGSize
            switch distribution {
            case .fill:
                size = CGSize(
                    width: calculateFillWidth(for: view, at: index),
                    height: bounds.height
                )
            case .fillEqually:
                let equalWidth = (bounds.width - CGFloat(arrangedSubviews.count - 1) * spacing) / CGFloat(arrangedSubviews.count)
                size = CGSize(width: equalWidth, height: bounds.height)
            case .equalSpacing:
                size = view.intrinsicContentSize
            case .equalCentering:
                let equalWidth = (bounds.width - CGFloat(arrangedSubviews.count + 1) * spacing) / CGFloat(arrangedSubviews.count)
                size = CGSize(width: equalWidth, height: bounds.height)
            }

            view.frame.size = size

            // 对齐
            switch alignment {
            case .leading:
                // 默认
                break
            case .center:
                view.center.y = bounds.height / 2
            case .trailing:
                view.frame.origin.x = bounds.width - view.frame.width - x
            case .fill:
                view.frame.size.height = bounds.height
            }

            x += size.width + spacing
        }
    }

    private func layoutVertical() {
        let spacing = self.spacing
        var y: CGFloat = 0

        for (index, view) in arrangedSubviews.enumerated() {
            view.frame.origin = CGPoint(x: 0, y: y)

            let size: CGSize
            switch distribution {
            case .fill:
                size = CGSize(
                    width: bounds.width,
                    height: calculateFillHeight(for: view, at: index)
                )
            case .fillEqually:
                let equalHeight = (bounds.height - CGFloat(arrangedSubviews.count - 1) * spacing) / CGFloat(arrangedSubviews.count)
                size = CGSize(width: bounds.width, height: equalHeight)
            case .equalSpacing:
                size = view.intrinsicContentSize
            case .equalCentering:
                let equalHeight = (bounds.height - CGFloat(arrangedSubviews.count + 1) * spacing) / CGFloat(arrangedSubviews.count)
                size = CGSize(width: bounds.width, height: equalHeight)
            }

            view.frame.size = size

            // 对齐
            switch alignment {
            case .leading:
                // 默认
                break
            case .center:
                view.center.x = bounds.width / 2
            case .trailing:
                view.frame.origin.x = bounds.width - view.frame.width
            case .fill:
                view.frame.size.width = bounds.width
            }

            y += size.height + spacing
        }
    }

    private func calculateFillWidth(for view: UIView, at index: Int) -> CGFloat {
        var totalSpacing = CGFloat(arrangedSubviews.count - 1) * spacing
        var otherWidth: CGFloat = 0

        for (i, v) in arrangedSubviews.enumerated() {
            if i != index {
                if v.intrinsicContentSize.width > 0 {
                    otherWidth += v.intrinsicContentSize.width
                } else {
                    otherWidth += bounds.width / CGFloat(arrangedSubviews.count)
                }
            }
        }

        return bounds.width - totalSpacing - otherWidth
    }

    private func calculateFillHeight(for view: UIView, at index: Int) -> CGFloat {
        var totalSpacing = CGFloat(arrangedSubviews.count - 1) * spacing
        var otherHeight: CGFloat = 0

        for (i, v) in arrangedSubviews.enumerated() {
            if i != index {
                if v.intrinsicContentSize.height > 0 {
                    otherHeight += v.intrinsicContentSize.height
                } else {
                    otherHeight += bounds.height / CGFloat(arrangedSubviews.count)
                }
            }
        }

        return bounds.height - totalSpacing - otherHeight
    }

    // MARK: - 便捷方法

    /// 添加子视图
    ///
    /// - Parameter views: 子视图数组
    func addArrangedSubviews(_ views: UIView...) {
        arrangedSubviews.append(contentsOf: views)
    }

    /// 移除子视图
    ///
    /// - Parameter views: 子视图数组
    func removeArrangedSubviews(_ views: UIView...) {
        arrangedSubviews.removeAll { view in views.contains($0) }
    }
}

// MARK: - LSSpacer

/// 占位视图（用于 AutoLayout）
public class LSSpacer: UIView {

    /// 水平占位符
    ///
    /// - Parameters:
    ///   - priority: 优先级
    ///   - identifier: 标识符
    /// - Returns: 占位视图
    public static func horizontal(
        priority: UILayoutPriority = .defaultHigh,
        identifier: String? = nil
    ) -> LSSpacer {
        let spacer = LSSpacer()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.setContentHuggingPriority(priority, for: .horizontal)
        if let identifier = identifier {
            spacer.accessibilityIdentifier = identifier
        }
        return spacer
    }

    /// 垂直占位符
    ///
    /// - Parameters:
    ///   - priority: 优先级
    ///   - identifier: 标识符
    /// - Returns: 占位视图
    public static func vertical(
        priority: UILayoutPriority = .defaultHigh,
        identifier: String? = nil
    ) -> LSSpacer {
        let spacer = LSSpacer()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.setContentHuggingPriority(priority, for: .vertical)
        if let identifier = identifier {
            spacer.accessibilityIdentifier = identifier
        }
        return spacer
    }

    /// 灵活占位符
    ///
    /// - Parameters:
    ///   - width: 宽度
    ///   - height: 高度
    /// - Returns: 占位视图
    public static func flexible(
        width: CGFloat? = nil,
        height: CGFloat? = nil
    ) -> LSSpacer {
        let spacer = LSSpacer()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        if let width = width {
            spacer.frame.size.width = width
        }
        if let height = height {
            spacer.frame.size.height = height
        }
        if width == nil {
            spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        }
        if height == nil {
            spacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        }
        return spacer
    }
}

// MARK: - LSLoadingView

/// 加载视图
public class LSLoadingView: UIView {

    // MARK: - 类型

    /// 加载样式
    public enum Style {
        case system      // 系统样式
        case custom      // 自定义
        case text        // 文本
    }

    // MARK: - 属性

    /// 加载指示器
    public private(set) var activityIndicator: UIActivityIndicatorView?

    /// 文本标签
    public private(set) var textLabel: UILabel?

    /// 样式
    public var style: Style = .system {
        didSet {
            updateStyle()
        }
    }

    /// 加载文本
    public var loadingText: String? {
        didSet {
            textLabel?.text = loadingText
            textLabel?.isHidden = loadingText == nil
        }
    }

    /// 指示器颜色
    public var indicatorColor: UIColor? {
        didSet {
            activityIndicator?.color = indicatorColor
        }
    }

    /// 文本颜色
    public var textColor: UIColor = .gray {
        didSet {
            textLabel?.textColor = textColor
        }
    }

    /// 背景颜色
    public var backgroundColors: UIColor? {
        didSet {
            if let color = backgroundColors {
                self.backgroundColor = color
            }
        }
    }

    // MARK: - 初始化

    public init(frame: CGRect = .zero) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    /// 便捷初始化
    ///
    /// - Parameters:
    ///   - style: 样式
    ///   - text: 加载文本
    convenience init(style: Style = .system, text: String? = nil) {
        self.init(frame: .zero)
        self.style = style
        self.loadingText = text
    }

    // MARK: - 设置

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false

        switch style {
        case .system:
            setupSystemStyle()
        case .custom:
            setupCustomStyle()
        case .text:
            setupTextStyle()
        }
    }

    private func setupSystemStyle() {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(indicator)
        activityIndicator = indicator

        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            indicator.widthAnchor.constraint(equalToConstant: 20),
            indicator.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    private func setupCustomStyle() {
        // 可以添加自定义加载动画
        setupSystemStyle()
    }

    private func setupTextStyle() {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = textColor
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        textLabel = label

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    private func updateStyle() {
        subviews.forEach { $0.removeFromSuperview() }
        activityIndicator = nil
        textLabel = nil
        setupUI()
    }

    // MARK: - 控制

    /// 开始加载
    public func startLoading() {
        isHidden = false
        activityIndicator?.startAnimating()

        if style == .text {
            // 文本闪烁动画
            UIView.animate(
                withDuration: 0.5,
                animations: {
                    self.textLabel?.alpha = 0.3
                },
                completion: { _ in
                    UIView.animate(
                        withDuration: 0.5,
                        animations: {
                            self.textLabel?.alpha = 1
                        }
                    )
                }
            )
        }
    }

    /// 停止加载
    public func stopLoading() {
        activityIndicator?.stopAnimating()
        isHidden = true
    }
}

// MARK: - LSEmptyView

/// 空状态视图
public class LSEmptyView: UIView {

    // MARK: - 属性

    /// 图标
    public var iconView: UIImageView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let icon = iconView {
                addSubview(icon)
                layoutIcon()
            }
        }
    }

    /// 标题
    public var titleLabel: UILabel? {
        didSet {
            oldValue?.removeFromSuperview()
            if let label = titleLabel {
                addSubview(label)
                layoutTitle()
            }
        }
    }

    /// 描述
    public var descriptionLabel: UILabel? {
        didSet {
            oldValue?.removeFromSuperview()
            if let label = descriptionLabel {
                addSubview(label)
                layoutDescription()
            }
        }
    }

    /// 操作按钮
    public var actionButton: UIButton? {
        didSet {
            oldValue?.removeFromSuperview()
            if let button = actionButton {
                addSubview(button)
                layoutButton()
            }
        }
    }

    /// 垂直间距
    public var verticalSpacing: CGFloat = 12

    /// 图标大小
    public var iconSize: CGSize = CGSize(width: 60, height: 60) {
        didSet {
            iconView?.bounds.size = iconSize
            setNeedsLayout()
        }
    }

    // MARK: - 初始化

    public init(frame: CGRect = .zero) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    /// 便捷初始化
    ///
    /// - Parameters:
    ///   - icon: 图标
    ///   - title: 标题
    ///   - description: 描述
    convenience init(
        icon: UIImage? = nil,
        title: String? = nil,
        description: String? = nil
    ) {
        self.init(frame: .zero)

        if let icon = icon {
            iconView = UIImageView(image: icon)
            iconView.contentMode = .scaleAspectFit
        }

        if let title = title {
            titleLabel = UILabel()
            titleLabel?.text = title
            titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            titleLabel?.textColor = .darkGray
            titleLabel?.textAlignment = .center
        }

        if let description = description {
            descriptionLabel = UILabel()
            descriptionLabel?.text = description
            descriptionLabel?.font = UIFont.systemFont(ofSize: 14)
            descriptionLabel?.textColor = .lightGray
            descriptionLabel?.textAlignment = .center
            descriptionLabel?.numberOfLines = 0
        }

        layoutContent()
    }

    // MARK: - 布局

    private func layoutContent() {
        layoutIcon()
        layoutTitle()
        layoutDescription()
        layoutButton()
    }

    private func layoutIcon() {
        guard let iconView = iconView else { return }
        iconView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.topAnchor.constraint(equalTo: topAnchor, constant: 40),
            iconView.widthAnchor.constraint(equalToConstant: iconSize.width),
            iconView.heightAnchor.constraint(equalToConstant: iconSize.height)
        ])
    }

    private func layoutTitle() {
        guard let titleLabel = titleLabel, iconView == nil else {
            // 如果有图标，标题在图标下方
            let topAnchor = iconView != nil ? iconView!.bottomAnchor : topAnchor
            NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
                titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
                titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
            ])
            return
        }

        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }

    private func layoutDescription() {
        guard let descriptionLabel = descriptionLabel else { return }
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false

        let topAnchor
        if let tempTopanchor = iconView?.bottomAnchor {
            topAnchor = tempTopanchor
        } else {
            topAnchor = topAnchor)
        }
        NSLayoutConstraint.activate([
            descriptionLabel.topAnchor.constraint(equalTo: topAnchor, constant: verticalSpacing),
            descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }

    private func layoutButton() {
        guard let actionButton = actionButton else { return }
        actionButton.translatesAutoresizingMaskIntoConstraints = false

        let topAnchor
        if let tempTopanchor = titleLabel?.bottomAnchor {
            topAnchor = tempTopanchor
        } else {
            if let tempValue = .bottomAnchor {
                topAnchor = tempValue
            } else {
                topAnchor = topAnchor
            }
        }
        NSLayoutConstraint.activate([
            actionButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            actionButton.topAnchor.constraint(equalTo: topAnchor, constant: verticalSpacing + 8),
            actionButton.widthAnchor.constraint(equalToConstant: 120),
            actionButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
}

// MARK: - UIView Extension (容器)

public extension UIView {

    /// 包装为堆栈视图
    ///
    /// - Parameters:
    ///   - axis: 轴方向
    ///   - spacing: 间距
    ///   - alignment: 对齐方式
    /// - Returns: 堆栈视图
    @discardableResult
    func ls_wrappedInStackView(
        axis: LSStackView.Axis = .horizontal,
        spacing: CGFloat = 8,
        alignment: LSStackView.Alignment = .center
    ) -> LSStackView {
        let stackView = LSStackView(axis: axis, spacing: spacing, alignment: alignment)
        stackView.arrangedSubviews = [self]
        return stackView
    }

    /// 显示加载视图
    ///
    /// - Parameters:
    ///   - style: 样式
    ///   - text: 加载文本
    /// - Returns: 加载视图
    @discardableResult
    func ls_showLoading(
        style: LSLoadingView.Style = .system,
        text: String? = nil
    ) -> LSLoadingView {
        let loadingView = LSLoadingView(style: style, text: text)
        loadingView.frame = bounds
        loadingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(loadingView)
        loadingView.startLoading()
        return loadingView
    }

    /// 隐藏加载视图
    func ls_hideLoading() {
        subviews.compactMap { $0 as? LSLoadingView }.forEach {
            $0.stopLoading()
            $0.removeFromSuperview()
        }
    }

    /// 显示空状态视图
    ///
    /// - Parameters:
    ///   - icon: 图标
    ///   - title: 标题
    ///   - description: 描述
    /// - actionTitle: 操作按钮标题
    ///   - action: 操作回调
    /// - Returns: 空状态视图
    @discardableResult
    func ls_showEmptyView(
        icon: UIImage? = nil,
        title: String? = nil,
        description: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) -> LSEmptyView {
        let emptyView = LSEmptyView(icon: icon, title: title, description: description)

        if let actionTitle = actionTitle, let action = action {
            let button = UIButton(type: .system)
            button.setTitle(actionTitle, for: .normal)
            button.addTarget(self, action: #selector(handleEmptyAction(_:)), for: .touchUpInside)
            // 存储操作闭包（使用关联对象）
            objc_setAssociatedObject(button, &AssociatedKeys.emptyAction, action, .OBJC_ASSOCIATION_COPY_NONATOMIC)
            emptyView.actionButton = button
        }

        emptyView.frame = bounds
        emptyView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(emptyView)

        return emptyView
    }

    @objc private func handleEmptyAction(_ sender: UIButton) {
        if let action = objc_getAssociatedObject(sender, &AssociatedKeys.emptyAction) as? () -> Void {
            action()
        }
    }
}

// MARK: - Associated Keys

private enum AssociatedKeys {
    static var emptyAction = "emptyAction"
}

#endif

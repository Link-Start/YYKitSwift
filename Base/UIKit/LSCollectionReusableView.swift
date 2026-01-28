//
//  LSCollectionReusableView.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  可复用集合视图组件 - Header、Footer、Background 等
//

#if canImport(UIKit)
import UIKit

// MARK: - LSCollectionReusableView

/// 可复用集合视图基类
@MainActor
public class LSCollectionReusableView: UICollectionReusableView {

    // MARK: - 属性

    /// 标题
    public var title: String? {
        didSet {
            titleLabel.text = title
            titleLabel.isHidden = (title == nil)
        }
    }

    /// 副标题
    public var subtitle: String? {
        didSet {
            subtitleLabel.text = subtitle
            subtitleLabel.isHidden = (subtitle == nil)
        }
    }

    /// 背景颜色
    public var viewBackgroundColor: UIColor = .systemBackground {
        didSet {
            backgroundColor = viewBackgroundColor
        }
    }

    /// 是否显示分隔线
    public var showsSeparator: Bool = false {
        didSet {
            separatorView.isHidden = !showsSeparator
        }
    }

    /// 分隔线颜色
    public var separatorColor: UIColor = .separator {
        didSet {
            separatorView.backgroundColor = separatorColor
        }
    }

    /// 内边距
    public var contentInsets: UIEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16) {
        didSet {
            updateConstraints()
        }
    }

    // MARK: - UI 组件

    public let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    public let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupReusableView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupReusableView()
    }

    // MARK: - 设置

    private func setupReusableView() {
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(separatorView)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: contentInsets.top),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: contentInsets.left),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -contentInsets.right),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -contentInsets.bottom),

            separatorView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: contentInsets.left),
            separatorView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -contentInsets.right),
            separatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }

    private func updateConstraints() {
        titleLabel.superview?.constraints.forEach { constraint in
            if constraint.firstItem === titleLabel && constraint.firstAttribute == .top {
                constraint.constant = contentInsets.top
            }
            if constraint.firstItem === titleLabel && constraint.firstAttribute == .leading {
                constraint.constant = contentInsets.left
            }
            if constraint.firstItem === titleLabel && constraint.firstAttribute == .trailing {
                constraint.constant = -contentInsets.right
            }
        }
    }

    // MARK: - 配置方法

    public func configure(title: String?, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
}

// MARK: - LSCollectionHeaderView

/// 集合视图头部视图
public class LSCollectionHeaderView: LSCollectionReusableView {

    // MARK: - 属性

    /// 是否显示展开按钮
    public var showsExpandButton: Bool = false {
        didSet {
            expandButton.isHidden = !showsExpandButton
        }
    }

    /// 是否展开
    public private(set) var isExpanded: Bool = true

    /// 展开变化回调
    public var onExpandToggle: ((Bool) -> Void)?

    // MARK: - UI 组件

    private let expandButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupHeaderView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupHeaderView()
    }

    // MARK: - 设置

    private func setupHeaderView() {
        addSubview(expandButton)

        NSLayoutConstraint.activate([
            expandButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            expandButton.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        expandButton.ls_addAction(for: .touchUpInside) { [weak self] in
            self?.toggleExpanded()
        }
    }

    // MARK: - 展开/收起

    public func toggleExpanded() {
        isExpanded = !isExpanded
        updateExpandButton()
        onExpandToggle?(isExpanded)
    }

    public func setExpanded(_ expanded: Bool) {
        isExpanded = expanded
        updateExpandButton()
    }

    private func updateExpandButton() {
        let imageName = isExpanded ? "chevron.down" : "chevron.up"
        expandButton.setImage(UIImage(systemName: imageName), for: .normal)

        UIView.animate(withDuration: 0.3) {
            self.expandButton.transform = CGAffineTransform(rotationAngle: self.isExpanded ? 0 : .pi)
        }
    }
}

// MARK: - LSCollectionFooterView

/// 集合视图尾部视图
public class LSCollectionFooterView: LSCollectionReusableView {

    // MARK: - 属性

    /// 加载更多状态
    public private(set) var isLoading: Bool = false

    /// 没有更多数据
    public var noMoreData: Bool = false {
        didSet {
            updateState()
        }
    }

    /// 加载更多回调
    public var onLoadMore: (() -> Void)?

    // MARK: - UI 组件

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private let stateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    private let loadMoreButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("加载更多", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupFooterView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupFooterView()
    }

    // MARK: - 设置

    private func setupFooterView() {
        addSubview(activityIndicator)
        addSubview(stateLabel)
        addSubview(loadMoreButton)

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),

            stateLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            stateLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            loadMoreButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadMoreButton.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        loadMoreButton.ls_addAction(for: .touchUpInside) { [weak self] in
            self?.startLoading()
            self?.onLoadMore?()
        }
    }

    // MARK: - 状态更新

    private func updateState() {
        if noMoreData {
            activityIndicator.stopAnimating()
            stateLabel.text = "没有更多数据"
            stateLabel.isHidden = false
            loadMoreButton.isHidden = true
        } else {
            activityIndicator.stopAnimating()
            stateLabel.isHidden = true
            loadMoreButton.isHidden = false
        }
    }

    // MARK: - 公共方法

    public func startLoading() {
        isLoading = true
        noMoreData = false

        activityIndicator.startAnimating()
        stateLabel.isHidden = true
        loadMoreButton.isHidden = true
    }

    public func stopLoading() {
        isLoading = false

        activityIndicator.stopAnimating()
        loadMoreButton.isHidden = false
    }

    public func showNoMoreData() {
        isLoading = false
        noMoreData = true
        updateState()
    }

    public func reset() {
        isLoading = false
        noMoreData = false
        activityIndicator.stopAnimating()
        stateLabel.isHidden = true
        loadMoreButton.isHidden = false
    }
}

// MARK: - LSCollectionBackgroundView

/// 集合视图背景视图（空状态）
public class LSCollectionBackgroundView: UICollectionReusableView {

    // MARK: - 类型定义

    /// 背景类型
    public enum BackgroundType {
        case empty
        case error
        case noNetwork
        case custom(UIImage?, String?, String?)
    }

    /// 按钮点击回调
    public typealias ButtonHandler = () -> Void

    // MARK: - 属性

    /// 背景类型
    public var backgroundType: BackgroundType = .empty {
        didSet {
            updateBackgroundType()
        }
    }

    /// 图标
    public var iconImage: UIImage? {
        didSet {
            iconImageView.image = iconImage
        }
    }

    /// 标题
    public var titleText: String? {
        didSet {
            titleLabel.text = titleText
        }
    }

    /// 描述文本
    public var messageText: String? {
        didSet {
            messageLabel.text = messageText
        }
    }

    /// 按钮标题
    public var buttonTitle: String? {
        didSet {
            actionButton.setTitle(buttonTitle, for: .normal)
            actionButton.isHidden = (buttonTitle == nil)
        }
    }

    /// 按钮点击回调
    public var onButtonTap: ButtonHandler?

    // MARK: - UI 组件

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .tertiaryLabel
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupBackgroundView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupBackgroundView()
    }

    // MARK: - 设置

    private func setupBackgroundView() {
        addSubview(stackView)

        stackView.addArrangedSubview(iconImageView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(messageLabel)
        stackView.addArrangedSubview(actionButton)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 32),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -32)
        ])

        actionButton.ls_addAction(for: .touchUpInside) { [weak self] in
            self?.onButtonTap?()
        }

        updateBackgroundType()
    }

    // MARK: - 更新方法

    private func updateBackgroundType() {
        switch backgroundType {
        case .empty:
            iconImageView.image = UIImage(systemName: "tray")
            titleLabel.text = "暂无数据"
            messageLabel.text = "这里什么都没有"
            actionButton.isHidden = true

        case .error:
            iconImageView.image = UIImage(systemName: "exclamationmark.triangle")
            titleLabel.text = "出错了"
            messageLabel.text = "加载失败，请稍后重试"
            actionButton.setTitle("重试", for: .normal)
            actionButton.isHidden = false

        case .noNetwork:
            iconImageView.image = UIImage(systemName: "wifi.slash")
            titleLabel.text = "网络连接失败"
            messageLabel.text = "请检查网络设置"
            actionButton.setTitle("重试", for: .normal)
            actionButton.isHidden = false

        case .custom(let image, let title, let message):
            iconImageView.image = image
            titleLabel.text = title
            messageLabel.text = message
            actionButton.isHidden = true
        }
    }

    // MARK: - 便捷创建方法

    public static func emptyView(title: String = "暂无数据", message: String = "这里什么都没有") -> LSCollectionBackgroundView {
        let view = LSCollectionBackgroundView()
        view.backgroundType = .empty
        view.titleText = title
        view.messageText = message
        return view
    }

    public static func errorView(title: String = "出错了", message: String = "加载失败，请稍后重试", buttonTitle: String = "重试") -> LSCollectionBackgroundView {
        let view = LSCollectionBackgroundView()
        view.backgroundType = .error
        view.titleText = title
        view.messageText = message
        view.buttonTitle = buttonTitle
        return view
    }

    public static func noNetworkView(title: String = "网络连接失败", message: String = "请检查网络设置", buttonTitle: String = "重试") -> LSCollectionBackgroundView {
        let view = LSCollectionBackgroundView()
        view.backgroundType = .noNetwork
        view.titleText = title
        view.messageText = message
        view.buttonTitle = buttonTitle
        return view
    }
}

// MARK: - LSCollectionDecorationView

/// 装饰视图（背景）
public class LSCollectionDecorationView: UICollectionReusableView {

    // MARK: - 属性

    /// 背景颜色
    public var decorationColor: UIColor = .systemBackground {
        didSet {
            backgroundColor = decorationColor
        }
    }

    /// 圆角
    public var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }

    /// 边框宽度
    public var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }

    /// 边框颜色
    public var borderColor: UIColor = .clear {
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }

    /// 阴影颜色
    public var shadowColor: UIColor? = nil {
        didSet {
            updateShadow()
        }
    }

    /// 阴影偏移
    public var shadowOffset: CGSize = .zero {
        didSet {
            updateShadow()
        }
    }

    /// 阴影透明度
    public var shadowOpacity: Float = 0 {
        didSet {
            updateShadow()
        }
    }

    /// 阴影半径
    public var shadowRadius: CGFloat = 0 {
        didSet {
            updateShadow()
        }
    }

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupDecorationView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupDecorationView()
    }

    // MARK: - 设置

    private func setupDecorationView() {
        clipsToBounds = false
    }

    // MARK: - 更新方法

    private func updateShadow() {
        if let color = shadowColor {
            layer.shadowColor = color.cgColor
            layer.shadowOffset = shadowOffset
            layer.shadowOpacity = shadowOpacity
            layer.shadowRadius = shadowRadius
        } else {
            layer.shadowColor = nil
            layer.shadowOffset = .zero
            layer.shadowOpacity = 0
            layer.shadowRadius = 0
        }
    }
}

// MARK: - UICollectionViewCell Extension

public extension UICollectionViewCell {

    /// 重用标识符
    static var ls_reuseIdentifier: String {
        return String(describing: self)
    }

    /// 从 nib 加载
    static func ls_fromNib() -> UINib {
        return UINib(nibName: ls_reuseIdentifier, bundle: nil)
    }

    /// 注册到集合视图
    static func ls_register(to collectionView: UICollectionView) {
        collectionView.register(self, forCellWithReuseIdentifier: ls_reuseIdentifier)
    }

    /// 注册 nib 到集合视图
    static func ls_registerNib(to collectionView: UICollectionView) {
        collectionView.register(ls_fromNib(), forCellWithReuseIdentifier: ls_reuseIdentifier)
    }

    /// 从集合视图获取可复用 cell
    static func ls_dequeueReusableCell(from collectionView: UICollectionView, for indexPath: IndexPath) -> Self {
        return collectionView.dequeueReusableCell(withReuseIdentifier: ls_reuseIdentifier, for: indexPath) as! Self
    }
}

// MARK: - UICollectionReusableView Extension

public extension UICollectionReusableView {

    /// 重用标识符
    static var ls_reuseIdentifier: String {
        return String(describing: self)
    }

    /// 从 nib 加载
    static func ls_fromNib() -> UINib {
        return UINib(nibName: ls_reuseIdentifier, bundle: nil)
    }

    /// 注册到集合视图
    static func ls_register(to collectionView: UICollectionView, for kind: String = UICollectionView.elementKindSectionHeader) {
        collectionView.register(self, forSupplementaryViewOfKind: kind, withReuseIdentifier: ls_reuseIdentifier)
    }

    /// 注册 nib 到集合视图
    static func ls_registerNib(to collectionView: UICollectionView, for kind: String = UICollectionView.elementKindSectionHeader) {
        collectionView.register(ls_fromNib(), forSupplementaryViewOfKind: kind, withReuseIdentifier: ls_reuseIdentifier)
    }

    /// 从集合视图获取可复用视图
    static func ls_dequeueReusableSupplementaryView(from collectionView: UICollectionView, ofKind kind: String = UICollectionView.elementKindSectionHeader, for indexPath: IndexPath) -> Self {
        return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ls_reuseIdentifier, for: indexPath) as! Self
    }
}

// MARK: - UICollectionView Extension

public extension UICollectionView {

    /// 注册 cell
    func ls_register<T: UICollectionViewCell>(_ cellType: T.Type) {
        cellType.ls_register(to: self)
    }

    /// 注册 cell nib
    func ls_registerNib<T: UICollectionViewCell>(_ cellType: T.Type) {
        cellType.ls_registerNib(to: self)
    }

    /// 获取可复用 cell
    func ls_dequeueReusableCell<T: UICollectionViewCell>(_ cellType: T.Type, for indexPath: IndexPath) -> T {
        return T.ls_dequeueReusableCell(from: self, for: indexPath)
    }

    /// 注册 supplementary view
    func ls_register<T: UICollectionReusableView>(_ viewType: T.Type, for kind: String = UICollectionView.elementKindSectionHeader) {
        viewType.ls_register(to: self, for: kind)
    }

    /// 注册 supplementary view nib
    func ls_registerNib<T: UICollectionReusableView>(_ viewType: T.Type, for kind: String = UICollectionView.elementKindSectionHeader) {
        viewType.ls_registerNib(to: self, for: kind)
    }

    /// 获取可复用 supplementary view
    func ls_dequeueReusableSupplementaryView<T: UICollectionReusableView>(_ viewType: T.Type, ofKind kind: String = UICollectionView.elementKindSectionHeader, for indexPath: IndexPath) -> T {
        return T.ls_dequeueReusableSupplementaryView(from: self, ofKind: kind, for: indexPath)
    }
}

#endif

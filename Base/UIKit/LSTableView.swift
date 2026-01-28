//
//  LSTableView.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  增强的表格视图 - 提供更多便捷功能
//

#if canImport(UIKit)
import UIKit

// MARK: - LSTableView

/// 增强的表格视图
@MainActor
public class LSTableView: UITableView {

    // MARK: - 类型定义

    /// 空视图配置
    public struct EmptyConfig {
        var image: UIImage?
        var title: String?
        var message: String?
        var buttonTitle: String?
        var buttonAction: (() -> Void)?

        public init(
            image: UIImage? = nil,
            title: String? = nil,
            message: String? = nil,
            buttonTitle: String? = nil,
            buttonAction: (() -> Void)? = nil
        ) {
            self.image = image
            self.title = title
            self.message = message
            self.buttonTitle = buttonTitle
            self.buttonAction = buttonAction
        }
    }

    /// 空视图
    private let emptyView: LSEmptyView = {
        let view = LSEmptyView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    /// 空视图配置
    public var emptyConfig: EmptyConfig? {
        didSet {
            updateEmptyView()
        }
    }

    /// 是否自动显示空视图
    public var autoShowEmpty: Bool = true {
        didSet {
            updateEmptyViewVisibility()
        }
    }

    /// 占位单元格配置
    public var placeholderCell: UITableViewCell?

    // MARK: - 初始化

    public override init(frame: CGRect, style: Style) {
        super.init(frame: frame, style: style)
        setupTableView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTableView()
    }

    // MARK: - 设置

    private func setupTableView() {
        // 添加空视图
        backgroundView = emptyView

        // 约束
        NSLayoutConstraint.activate([
            emptyView.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyView.centerYAnchor.constraint(equalTo: centerYAnchor),
            emptyView.widthAnchor.constraint(equalTo: widthAnchor),
            emptyView.heightAnchor.constraint(equalTo: heightAnchor)
        ])

        // 监听数据变化
        addObserver(self, forKeyPath: "dataSource", options: [.new, .old], context: nil)
    }

    public override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        updateEmptyViewVisibility()
    }

    // MARK: - 空视图管理

    private func updateEmptyView() {
        guard let config = emptyConfig else { return }

        emptyView.image = config.image
        emptyView.title = config.title
        emptyView.message = config.message

        if let buttonTitle = config.buttonTitle {
            emptyView.setButtonTitle(buttonTitle) { [weak self] in
                config.buttonAction?()
            }
            emptyView.showButton = true
        } else {
            emptyView.showButton = false
        }
    }

    private func updateEmptyViewVisibility() {
        guard autoShowEmpty else {
            emptyView.isHidden = true
            return
        }

        let isEmpty = numberOfRows(inSection: 0) == 0
        emptyView.isHidden = !isEmpty
    }

    public override func reloadData() {
        super.reloadData()
        updateEmptyViewVisibility()
    }

    public override func dequeueReusableCell(withIdentifier identifier: String) -> UITableViewCell? {
        return super.dequeueReusableCell(withIdentifier: identifier)
    }

    public override func dequeueReusableCell(
        withIdentifier identifier: String,
        for indexPath: IndexPath
    ) -> UITableViewCell {
        // 如果cell未注册，返回占位cell
        guard let cell = super.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? UITableViewCell,
              !type(of: cell).isPlaceholder else {
            if let tempValue = placeholderCell {
                return tempValue
            }
            return UITableViewCell(style: .default, reuseIdentifier: identifier)
        }

        return cell
    }

    // MARK: - 注册

    /// 注册 cell（使用类名作为 identifier）
    public func ls_register<T: UITableViewCell>(_ cellType: T.Type) {
        let identifier = String(describing: cellType)
        register(cellType, forCellReuseIdentifier: identifier)
    }

    /// 注册 header footer
    public func ls_registerHeaderFooter<T: UIView>(_ viewType: T.Type) {
        let identifier = String(describing: viewType)
        register(viewType, forHeaderFooterViewReuseIdentifier: identifier)
    }

    /// 获取可重用 cell
    public func ls_dequeueReusableCell<T: UITableViewCell>(
        _ cellType: T.Type,
        for indexPath: IndexPath
    ) -> T {
        let identifier = String(describing: cellType)
        guard let cell = dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? T else {
            return T(style: .default, reuseIdentifier: identifier)
        }
        return cell
    }

    /// 获取可重用 header footer
    public func ls_dequeueReusableHeaderFooter<T: UIView>(_ viewType: T.Type) -> T {
        let identifier = String(describing: viewType)
        guard let view = dequeueReusableHeaderFooterView(withIdentifier: identifier) as? T else {
            return T(frame: .zero)
        }
        return view
    }

    // MARK: - 滚动

    /// 滚动到顶部
    func ls_scrollToTop(animated: Bool = true) {
        let indexPath = IndexPath(row: 0, section: 0)
        guard numberOfRows(inSection: 0) > 0 else { return }
        scrollToRow(at: indexPath, at: .top, animated: animated)
    }

    /// 滚动到底部
    func ls_scrollToBottom(animated: Bool = true) {
        let lastSection = numberOfSections - 1
        guard lastSection >= 0 else { return }
        let lastRow = numberOfRows(inSection: lastSection) - 1
        guard lastRow >= 0 else { return }

        let indexPath = IndexPath(row: lastRow, section: lastSection)
        scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }

    // MARK: - 清理

    deinit {
        removeObserver(self, forKeyPath: "dataSource")
    }
}

// MARK: - LSEmptyView

/// 空视图
private class LSEmptyView: UIView {

    /// 图片视图
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .systemGray3
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    /// 标题标签
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 16)
        label.textColor = .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 消息标签
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 按钮
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    /// 栈视图
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    /// 图片
    var image: UIImage? {
        didSet {
            imageView.image = image
            imageView.isHidden = image == nil
        }
    }

    /// 标题
    var title: String? {
        didSet {
            titleLabel.text = title
            titleLabel.isHidden = title == nil
        }
    }

    /// 消息
    var message: String? {
        didSet {
            messageLabel.text = message
            messageLabel.isHidden = message == nil
        }
    }

    /// 是否显示按钮
    var showButton: Bool = false {
        didSet {
            actionButton.isHidden = !showButton
        }
    }

    /// 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    /// 设置 UI
    private func setupUI() {
        addSubview(stackView)

        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(messageLabel)
        stackView.addArrangedSubview(actionButton)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 40),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -40),

            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 80),

            actionButton.widthAnchor.constraint(equalToConstant: 120),
            actionButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    /// 设置按钮
    func setButtonTitle(_ title: String, action: @escaping () -> Void) {
        actionButton.setTitle(title, for: .normal)
        actionButton.ls_removeAllActions()
        actionButton.ls_addAction(for: .touchUpInside) { _ in
            action()
        }
    }
}

// MARK: - UITableViewCell Placeholder

private extension UITableViewCell {

    static var isPlaceholder: Bool {
        return String(describing: self).hasPrefix("UI")
    }
}

// MARK: - UITableView Extension

public extension UITableView {

    /// 注册 cell（类型安全）
    func ls_register<T: UITableViewCell>(_ cellType: T.Type) {
        let identifier = String(describing: cellType)
        register(cellType, forCellReuseIdentifier: identifier)
    }

    /// 注册 header footer（类型安全）
    func ls_registerHeaderFooter<T: UIView>(_ viewType: T.Type) {
        let identifier = String(describing: viewType)
        register(viewType, forHeaderFooterViewReuseIdentifier: identifier)
    }

    /// 获取可重用 cell（类型安全）
    func ls_dequeueReusableCell<T: UITableViewCell>(
        _ cellType: T.Type,
        for indexPath: IndexPath
    ) -> T {
        let identifier = String(describing: cellType)
        guard let cell = dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? T else {
            return T(style: .default, reuseIdentifier: identifier)
        }
        return cell
    }

    /// 获取可重用 header footer（类型安全）
    func ls_dequeueReusableHeaderFooter<T: UIView>(_ viewType: T.Type) -> T {
        let identifier = String(describing: viewType)
        guard let view = dequeueReusableHeaderFooterView(withIdentifier: identifier) as? T else {
            return T(frame: .zero)
        }
        return view
    }

    /// 滚动到顶部
    func ls_scrollToTop(animated: Bool = true) {
        guard numberOfRows(inSection: 0) > 0 else { return }
        let indexPath = IndexPath(row: 0, section: 0)
        scrollToRow(at: indexPath, at: .top, animated: animated)
    }

    /// 滚动到底部
    func ls_scrollToBottom(animated: Bool = true) {
        let lastSection = numberOfSections - 1
        guard lastSection >= 0 else { return }
        let lastRow = numberOfRows(inSection: lastSection) - 1
        guard lastRow >= 0 else { return }

        let indexPath = IndexPath(row: lastRow, section: lastSection)
        scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }

    /// 获取可见的 indexPaths
    var ls_visibleIndexPaths: [IndexPath] {
        if let tempValue = indexPathsForVisibleRows {
            return tempValue
        }
        return []
    }

    /// 获取第一个可见的 indexPath
    var ls_firstVisibleIndexPath: IndexPath? {
        return ls_visibleIndexPaths.first
    }

    /// 获取最后一个可见的 indexPath
    var ls_lastVisibleIndexPath: IndexPath? {
        return ls_visibleIndexPaths.last
    }

    /// 是否有更多内容
    func ls_hasMoreContent(below: IndexPath) -> Bool {
        let lastSection = numberOfSections - 1
        guard lastSection >= 0 else { return false }

        if below.section < lastSection {
            return true
        }

        let lastRow = numberOfRows(inSection: lastSection) - 1
        return below.row < lastRow
    }

    /// 添加下拉刷新
    @discardableResult
    func ls_addRefresh(handler: @escaping () -> Void) -> LSRefreshControl {
        let refresh = ls_addRefreshControl(handler: handler)
        return refresh
    }

    /// 添加无限滚动
    @discardableResult
    func ls_addInfiniteScroll(threshold: CGFloat = 60, handler: @escaping () -> Void) -> LSInfiniteScrollControl {
        let infinite = ls_addInfiniteScroll(threshold: threshold, handler: handler)
        return infinite
    }

    /// 选择项时执行回调
    func ls_onSelect(_ callback: @escaping (IndexPath) -> Void) {
        ls_removeAllActions()

        ls_addAction(for: .valueChanged) { [weak self] _ in
            guard let self = self,
                  let indexPath = self.indexPathForSelectedRow else { return }
            self.deselectRow(at: indexPath, animated: true)
            callback(indexPath)
        }
    }
}

// MARK: - UITableViewCell Extension

public extension UITableViewCell {

    /// 关联的数据
    private static var dataKey: UInt8 = 0

    var ls_data: Any? {
        get {
            return objc_getAssociatedObject(self, &UITableViewCell.dataKey)
        }
        set {
            objc_setAssociatedObject(
                self,
                &UITableViewCell.dataKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// 关联的 indexPath
    private static var indexPathKey: UInt8 = 0

    var ls_indexPath: IndexPath? {
        get {
            return objc_getAssociatedObject(self, &UITableViewCell.indexPathKey) as? IndexPath
        }
        set {
            objc_setAssociatedObject(
                self,
                &UITableViewCell.indexPathKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}

// MARK: - UITableViewHeaderFooterView Extension

public extension UITableViewHeaderFooterView {

    /// 关联的数据
    private static var dataKey: UInt8 = 0

    var ls_data: Any? {
        get {
            return objc_getAssociatedObject(self, &UITableViewHeaderFooterView.dataKey)
        }
        set {
            objc_setAssociatedObject(
                self,
                &UITableViewHeaderFooterView.dataKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// 关联的 section
    private static var sectionKey: UInt8 = 0

    var ls_section: Int? {
        get {
            return objc_getAssociatedObject(self, &UITableViewHeaderFooterView.sectionKey) as? Int
        }
        set {
            objc_setAssociatedObject(
                self,
                &UITableViewHeaderFooterView.sectionKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}

#endif

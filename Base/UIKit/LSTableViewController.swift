//
//  LSTableViewController.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  TableView 简化工具 - 减少样板代码
//

#if canImport(UIKit)
import UIKit

// MARK: - LSTableViewDataSource

/// TableView 数据源简化
@MainActor
public class LSTableViewDataSource: NSObject, UITableViewDataSource, UITableViewDelegate {

    // MARK: - 类型定义

    /// Cell 配置闭包
    public typealias CellConfigurer = (UITableViewCell, IndexPath) -> Void

    /// Cell 选择闭包
    public typealias CellSelector = (IndexPath) -> Void

    /// Cell 高度闭包
    public typealias CellHeightProvider = (IndexPath) -> CGFloat

    /// Header/Footer 配置闭包
    public typealias HeaderFooterConfigurer = (UITableViewHeaderFooterView, Int) -> Void

    /// Header/Footer 高度闭包
    public typealias HeaderFooterHeightProvider = (Int) -> CGFloat

    // MARK: - 属性

    /// 数据项
    public var items: [Any] = []

    /// Cell 重用标识符
    public var cellReuseIdentifier: String = "Cell"

    /// Cell 类
    public var cellClass: UITableViewCell.Type?

    /// Cell 配置闭包
    public var configureCell: CellConfigurer?

    /// Cell 选择闭包
    public var didSelectCell: CellSelector?

    /// Cell 高度闭包
    public var cellHeight: CellHeightProvider?

    /// 固定行高
    public var rowHeight: CGFloat = 44 {
        didSet { tableView?.rowHeight = rowHeight }
    }

    /// 估算行高
    public var estimatedRowHeight: CGFloat = UITableView.automaticDimension

    /// 分节数量
    public var numberOfSections: Int = 1

    /// 每节行数
    public var numberOfRowsInSection: ((Int) -> Int)?

    /// Header 标题
    public var titleForHeaderInSection: ((Int) -> String?)?

    /// Footer 标题
    public var titleForFooterInSection: ((Int) -> String?)?

    /// Header 视图配置
    public var configureHeader: HeaderFooterConfigurer?

    /// Footer 视图配置
    public var configureFooter: HeaderFooterConfigurer?

    /// Header 高度
    public var heightForHeaderInSection: HeaderFooterHeightProvider?

    /// Footer 高度
    public var heightForFooterInSection: HeaderFooterHeightProvider?

    /// 关联的 TableView
    public weak var tableView: UITableView? {
        didSet {
            tableView?.dataSource = self
            tableView?.delegate = self
            tableView?.rowHeight = rowHeight
            tableView?.estimatedRowHeight = estimatedRowHeight
            tableView?.register(cellClass, forCellReuseIdentifier: cellReuseIdentifier)
        }
    }

    // MARK: - 初始化

    public init(
        cellClass: UITableViewCell.Type? = nil,
        reuseIdentifier: String = "Cell"
    ) {
        self.cellClass = cellClass
        self.cellReuseIdentifier = reuseIdentifier
        super.init()
    }

    /// 便捷初始化（使用 UITableViewCell）
    ///
    /// - Parameters:
    ///   - items: 数据项
    ///   - configureCell: Cell 配置闭包
    ///   - didSelectCell: Cell 选择闭包
    /// - Returns: 数据源实例
    public static func create<T>(
        items: [T],
        configureCell: @escaping (UITableViewCell, T, IndexPath) -> Void,
        didSelectCell: ((IndexPath, T) -> Void)? = nil
    ) -> LSTableViewDataSource {
        let dataSource = LSTableViewDataSource()
        dataSource.items = items
        dataSource.configureCell = { cell, indexPath in
            if let item = dataSource.item(at: indexPath) as? T {
                configureCell(cell, item, indexPath)
            }
        }
        if let didSelectCell = didSelectCell {
            dataSource.didSelectCell = { indexPath in
                if let item = dataSource.item(at: indexPath) as? T {
                    didSelectCell(indexPath, item)
                }
            }
        }
        return dataSource
    }

    // MARK: - 数据访问

    /// 获取指定位置的数据项
    ///
    /// - Parameter indexPath: 索引路径
    /// - Returns: 数据项
    public func item(at indexPath: IndexPath) -> Any? {
        if items.isEmpty {
            return nil
        }
        if indexPath.section < numberOfSections {
            return items[indexPath.row]
        }
        return nil
    }

    // MARK: - UITableViewDataSource

    public func numberOfSections(in tableView: UITableView) -> Int {
        return numberOfSections
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let numberOfRows = numberOfRowsInSection {
            return numberOfRows(section)
        }
        return items.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
        configureCell?(cell, indexPath)
        return cell
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return titleForHeaderInSection?(section)
    }

    public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return titleForFooterInSection?(section)
    }

    // MARK: - UITableViewDelegate

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        didSelectCell?(indexPath)
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let tempValue = cellHeight?(indexPath) {
            return tempValue
        }
        return rowHeight
    }

    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return estimatedRowHeight
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let configureHeader = configureHeader else {
            return nil
        }

        let header
        if let tempValue = tableView.dequeueReusableHeaderFooterView(withIdentifier: "Header") {
            header = tempValue
        } else {
            header = UITableViewHeaderFooterView(reuseIdentifier: "Header")
        }
        configureHeader(header, section)
        return header
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let configureFooter = configureFooter else {
            return nil
        }

        let footer
        if let tempValue = tableView.dequeueReusableHeaderFooterView(withIdentifier: "Footer") {
            footer = tempValue
        } else {
            footer = UITableViewHeaderFooterView(reuseIdentifier: "Footer")
        }
        configureFooter(footer, section)
        return footer
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if let tempValue = heightForHeaderInSection?(section) {
            return tempValue
        }
        return UITableView.automaticDimension
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if let tempValue = heightForFooterInSection?(section) {
            return tempValue
        }
        return UITableView.automaticDimension
    }

    // MARK: - 刷新

    /// 重新加载数据
    public func reload() {
        tableView?.reloadData()
    }

    /// 更新数据
    ///
    /// - Parameter items: 新数据
    public func updateItems(_ items: [Any]) {
        self.items = items
        reload()
    }

    /// 追加数据
    ///
    /// - Parameter items: 要追加的数据
    public func appendItems(_ items: [Any]) {
        self.items.append(contentsOf: items)
        reload()
    }

    /// 插入数据
    ///
    /// - Parameters:
    ///   - items: 要插入的数据
    ///   - indexPath: 插入位置
    public func insertItems(_ items: [Any], at indexPath: IndexPath) {
        self.items.insert(contentsOf: items, at: indexPath.row)
        tableView?.insertRows(at: [indexPath], with: .automatic)
    }

    /// 删除数据
    ///
    /// - Parameter indexPaths: 要删除的位置
    public func deleteItems(at indexPaths: [IndexPath]) {
        var indices = indexPaths.map { $0.row }.sorted(by: >)
        for index in indices {
            if index < items.count {
                items.remove(at: index)
            }
        }
        tableView?.deleteRows(at: indexPaths, with: .automatic)
    }
}

// MARK: - UITableView Extension

public extension UITableView {

    private enum AssociatedKeys {
        static var dataSourceKey: UInt8 = 0
    }
    /// LS 数据源
    var ls_dataSource: LSTableViewDataSource? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.dataSourceKey) as? LSTableViewDataSource
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.dataSourceKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            newValue?.tableView = self
        }
    }

    /// 使用数据源配置
    ///
    /// - Parameters:
    ///   - items: 数据项
    ///   - configureCell: Cell 配置闭包
    ///   - didSelectCell: Cell 选择闭包
    /// - Returns: 数据源实例
    @discardableResult
    func ls_configure<T>(
        items: [T],
        configureCell: @escaping (UITableViewCell, T, IndexPath) -> Void,
        didSelectCell: ((IndexPath, T) -> Void)? = nil
    ) -> LSTableViewDataSource {
        let dataSource = LSTableViewDataSource.create(
            items: items,
            configureCell: configureCell,
            didSelectCell: didSelectCell
        )
        ls_dataSource = dataSource
        return dataSource
    }

    /// 注册 Cell 类
    ///
    /// - Parameters:
    ///   - cellClass: Cell 类
    ///   - reuseIdentifier: 重用标识符
    func ls_register<T: UITableViewCell>(_ cellClass: T.Type, reuseIdentifier: String = String(describing: T.self)) {
        register(cellClass, forCellReuseIdentifier: reuseIdentifier)
    }

    /// 注册 Header/Footer 类
    ///
    /// - Parameters:
    ///   - viewClass: Header/Footer 类
    ///   - reuseIdentifier: 重用标识符
    func lsRegisterHeaderFooter<T: UITableViewHeaderFooterView>(_ viewClass: T.Type, reuseIdentifier: String = String(describing: T.self)) {
        register(viewClass, forHeaderFooterViewReuseIdentifier: reuseIdentifier)
    }

    /// 安全地获取 Cell
    ///
    /// - Parameters:
    ///   - reuseIdentifier: 重用标识符
    ///   - indexPath: 索引路径
    /// - Returns: Cell
    func ls_dequeueReusableCell<T: UITableViewCell>(
        withReuseIdentifier reuseIdentifier: String,
        for indexPath: IndexPath
    ) -> T {
        // swiftlint:disable:next force_cast
        return dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! T
    }

    /// 安全地获取 Header
    ///
    /// - Parameters:
    ///   - reuseIdentifier: 重用标识符
    /// - - Returns: Header View
    func ls_dequeueReusableHeaderFooter<T: UITableViewHeaderFooterView>(
        withReuseIdentifier reuseIdentifier: String
    ) -> T {
        // swiftlint:disable:next force_cast
        return dequeueReusableHeaderFooterView(withIdentifier: reuseIdentifier) as! T
    }

    /// 滚动到底部
    func ls_scrollToBottom(animated: Bool = true) {
        guard numberOfSections > 0 else { return }

        let lastSection = numberOfSections - 1
        guard numberOfRows(inSection: lastSection) > 0 else { return }

        let lastRow = numberOfRows(inSection: lastSection) - 1
        let indexPath = IndexPath(row: lastRow, section: lastSection)
        scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }

    /// 滚动到顶部
    func ls_scrollToTop(animated: Bool = true) {
        guard numberOfSections > 0, numberOfRows(inSection: 0) > 0 else { return }

        let indexPath = IndexPath(row: 0, section: 0)
        scrollToRow(at: indexPath, at: .top, animated: animated)
    }

    /// 是否为最后一行
    ///
    /// - Parameter indexPath: 索引路径
    /// - Returns: 是否为最后一行
    func ls_isLastRow(_ indexPath: IndexPath) -> Bool {
        return indexPath.row == numberOfRows(inSection: indexPath.section) - 1
    }

    /// 是否为第一行
    ///
    /// - Parameter indexPath: 索引路径
    /// - Returns: 是否为第一行
    func ls_isFirstRow(_ indexPath: IndexPath) -> Bool {
        return indexPath.row == 0
    }
}

// MARK: - LSTableViewCell

/// TableView Cell 基类
public class LSTableViewCell: UITableViewCell {

    /// 重用标识符
    public static var reuseIdentifier: String {
        return String(describing: self)
    }

    /// Cell 高度
    public class var cellHeight: CGFloat {
        return 44
    }

    /// 估算高度
    public class var estimatedHeight: CGFloat {
        return UITableView.automaticDimension
    }

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    /// 设置 UI（子类重写）
    public func setupUI() {
        // 子类实现
    }

    /// 配置 Cell（子类重写）
    ///
    /// - Parameter item: 数据项
    public func configure(with item: Any) {
        // 子类实现
    }
}

// MARK: - LSTableViewHeaderFooter

/// TableView Header/Footer 基类
public class LSTableViewHeaderFooter: UITableViewHeaderFooterView {

    /// 重用标识符
    public static var reuseIdentifier: String {
        return String(describing: self)
    }

    /// 高度
    public class var viewHeight: CGFloat {
        return UITableView.automaticDimension
    }

    public override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    /// 设置 UI（子类重写）
    public func setupUI() {
        // 子类实现
    }

    /// 配置 Header/Footer（子类重写）
    ///
    /// - Parameter section: 节索引
    /// - Parameter title: 标题
    public func configure(section: Int, title: String?) {
        // 子类实现
    }
}

#endif

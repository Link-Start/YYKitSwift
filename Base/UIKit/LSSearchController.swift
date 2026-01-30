//
//  LSSearchController.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  搜索控制器 - 自定义搜索界面
//

#if canImport(UIKit)
import UIKit

// MARK: - LSSearchController

/// 搜索控制器
@MainActor
public class LSSearchController: UISearchController {

    // MARK: - 类型定义

    /// 搜索结果回调
    public typealias SearchResultsHandler = ([String]) -> Void

    /// 搜索项选择回调
    public typealias SelectionHandler = (String) -> Void

    // MARK: - 属性

    /// 搜索数据源
    public var searchData: [String] = [] {
        didSet {
            filteredData = searchData
        }
    }

    /// 过滤后的数据
    public private(set) var filteredData: [String] = [] {
        didSet {
            searchResultsController?.tableView.reloadData()
        }
    }

    /// 搜索结果回调
    public var onSearchResults: SearchResultsHandler?

    /// 选择回调
    public var onSelect: SelectionHandler?

    /// 占位符
    public var placeholderText: String = "搜索" {
        didSet {
            searchBar.placeholder = placeholderText
        }
    }

    /// 是否显示取消按钮
    public var showsCancelButton: Bool = false {
        didSet {
            searchBar.showsCancelButton = showsCancelButton
        }
    }

    /// 是否自动大写
    public var autocapitalizationType: UITextAutocapitalizationType = .none {
        didSet {
            searchBar.autocapitalizationType = autocapitalizationType
        }
    }

    /// 搜索栏样式
    public var searchBarStyle: UISearchBar.Style = .default {
        didSet {
            searchBar.searchBarStyle = searchBarStyle
        }
    }

    /// 搜索栏颜色
    public var searchBarColor: UIColor? {
        didSet {
            if let color = searchBarColor {
                searchBar.barTintColor = color
                searchBar.tintColor = color
            }
        }
    }

    /// 是否显示搜索历史
    public var showsSearchHistory: Bool = true

    /// 最大历史记录数量
    public var maxHistoryCount: Int = 10

    /// 搜索历史键
    public var historyKey: String = "LSSearchHistory"

    /// 搜索历史
    public private(set) var searchHistory: [String] = [] {
        didSet {
            saveSearchHistory()
            updateSearchHistoryView()
        }
    }

    // MARK: - 私有属性

    private var searchResultsController: LSSearchResultsTableController?

    // MARK: - 初始化

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        let resultsController = LSSearchResultsTableController()
        super.init(searchResultsController: resultsController)

        setupSearchController(resultsController)
    }

    public required init?(coder: NSCoder) {
        let resultsController = LSSearchResultsTableController()
        super.init(coder: coder)
        setupSearchController(resultsController)
    }

    public convenience init(
        data: [String] = [],
        placeholder: String = "搜索"
    ) {
        self.init()
        self.searchData = data
        self.placeholderText = placeholder
    }

    // MARK: - 设置

    private func setupSearchController(_ resultsController: LSSearchResultsTableController) {
        self.searchResultsController = resultsController

        // 配置搜索栏
        searchBar.placeholder = placeholderText
        searchBar.autocapitalizationType = autocapitalizationType
        searchBar.searchBarStyle = searchBarStyle

        // 设置代理
        searchBar.delegate = self
        searchResultsUpdater = self

        // 配置结果控制器
        resultsController.onSelect = { [weak self] item in
            guard let self = self else { return }
            self.onSelect?(item)
            self.dismiss(animated: true)
        }

        resultsController.onHistorySelect = { [weak self] item in
            guard let self = self else { return }
            self.searchBar.text = item
            self.updateSearchResults(for: self)
        }

        resultsController.onHistoryDelete = { [weak self] index in
            guard let self = self else { return }
            self.searchHistory.remove(at: index)
        }

        resultsController.onClearHistory = { [weak self] in
            guard let self = self else { return }
            self.searchHistory.removeAll()
        }

        // 加载搜索历史
        loadSearchHistory()
    }

    // MARK: - 搜索历史

    private func loadSearchHistory() {
        if let history = UserDefaults.standard.array(forKey: historyKey) as? [String] {
            searchHistory = history
        }
    }

    private func saveSearchHistory() {
        UserDefaults.standard.set(searchHistory, forKey: historyKey)
    }

    private func addToSearchHistory(_ text: String) {
        guard !text.isEmpty else { return }

        // 移除重复项
        searchHistory.removeAll { $0 == text }

        // 添加到开头
        searchHistory.insert(text, at: 0)

        // 限制数量
        if searchHistory.count > maxHistoryCount {
            searchHistory = Array(searchHistory.prefix(maxHistoryCount))
        }
    }

    private func updateSearchHistoryView() {
        searchResultsController?.searchHistory = searchHistory
    }

    // MARK: - 公共方法

    /// 清除搜索历史
    public func clearSearchHistory() {
        searchHistory.removeAll()
    }

    /// 设置搜索数据
    public func setSearchData(_ data: [String]) {
        searchData = data
        filteredData = data
    }

    /// 添加搜索历史
    public func addSearchHistory(_ history: String) {
        addToSearchHistory(history)
    }
}

// MARK: - UISearchResultsUpdating

extension LSSearchController: UISearchResultsUpdating {

    public func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else {
            filteredData = searchData
            return
        }

        if searchText.isEmpty {
            filteredData = searchData
            searchResultsController?.showingHistory = showsSearchHistory
        } else {
            // 添加到搜索历史
            addToSearchHistory(searchText)

            // 过滤数据
            filteredData = searchData.filter { item in
                return item.lowercased().contains(searchText.lowercased())
            }

            searchResultsController?.showingHistory = false
        }

        searchResultsController?.filteredData = filteredData
        onSearchResults?(filteredData)
    }
}

// MARK: - UISearchBarDelegate

extension LSSearchController: UISearchBarDelegate {

    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        if showsSearchHistory && searchHistory.count > 0 {
            searchResultsController?.showingHistory = true
        }
    }

    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        filteredData = searchData
    }

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()

        if let searchText = searchBar.text, !searchText.isEmpty {
            addToSearchHistory(searchText)
        }
    }
}

// MARK: - LSSearchResultsTableController

/// 搜索结果表格控制器
private class LSSearchResultsTableController: UITableViewController {

    // MARK: - 类型定义

    typealias SelectionHandler = (String) -> Void
    typealias HistoryDeleteHandler = (Int) -> Void
    typealias ClearHistoryHandler = () -> Void

    // MARK: - 属性

    var filteredData: [String] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    var searchHistory: [String] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    var showingHistory: Bool = false {
        didSet {
            tableView.reloadData()
        }
    }

    var onSelect: SelectionHandler?
    var onHistorySelect: SelectionHandler?
    var onHistoryDelete: HistoryDeleteHandler?
    var onClearHistory: ClearHistoryHandler?

    // MARK: - 初始化

    override init(style: UITableView.Style) {
        super.init(style: style)
        setupTableView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTableView()
    }

    // MARK: - 设置

    private func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return showingHistory && !searchHistory.isEmpty ? 2 : 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if showingHistory && section == 0 {
            return searchHistory.count + 1 // 历史记录 + 清除按钮
        } else {
            return filteredData.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        if showingHistory && indexPath.section == 0 {
            if indexPath.row < searchHistory.count {
                // 历史记录
                cell.textLabel?.text = searchHistory[indexPath.row]
                cell.imageView?.image = UIImage(systemName: "clock")
                cell.imageView?.tintColor = .secondaryLabel
            } else {
                // 清除历史按钮
                cell.textLabel?.text = "清除搜索历史"
                cell.textLabel?.textColor = .systemRed
                cell.imageView?.image = UIImage(systemName: "trash")
                cell.imageView?.tintColor = .systemRed
            }
        } else {
            // 搜索结果
            if indexPath.row < filteredData.count {
                cell.textLabel?.text = filteredData[indexPath.row]
                cell.imageView?.image = UIImage(systemName: "magnifyingglass")
                cell.imageView?.tintColor = .secondaryLabel
            }
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if showingHistory && section == 0 && !searchHistory.isEmpty {
            return "搜索历史"
        }
        return nil
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if showingHistory && indexPath.section == 0 {
            if indexPath.row < searchHistory.count {
                let item = searchHistory[indexPath.row]
                onHistorySelect?(item)
            } else {
                onClearHistory?()
            }
        } else {
            if indexPath.row < filteredData.count {
                let item = filteredData[indexPath.row]
                onSelect?(item)
            }
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return showingHistory && indexPath.section == 0 && indexPath.row < searchHistory.count
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            onHistoryDelete?(indexPath.row)
        }
    }
}

// MARK: - LSSearchBar

/// 搜索栏
public class LSSearchBar: UIView {

    // MARK: - 类型定义

    /// 搜索变化回调
    public typealias SearchHandler = (String) -> Void

    // MARK: - 属性

    /// 占位符
    public var placeholder: String = "搜索" {
        didSet {
            updatePlaceholder()
        }
    }

    /// 搜索文本
    public var searchText: String? {
        get {
            return textField.text
        }
        set {
            textField.text = newValue
        }
    }

    /// 搜索栏样式
    public var searchBarStyle: SearchBarStyle = .default {
        didSet {
            updateStyle()
        }
    }

    /// 是否显示取消按钮
    public var showsCancelButton: Bool = false {
        didSet {
            cancelButton.isHidden = !showsCancelButton
            updateLayout()
        }
    }

    /// 搜索回调
    public var onSearch: SearchHandler?

    /// 文本变化回调
    public var onTextChanged: SearchHandler?

    /// 取消回调
    public var onCancel: (() -> Void)?

    // MARK: - 搜索栏样式

    public enum SearchBarStyle {
        case `default`
        case minimal
        case prominent
    }

    // MARK: - UI 组件

    private let backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let searchIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "magnifyingglass")
        imageView.tintColor = .secondaryLabel
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let textField: UITextField = {
        let field = UITextField()
        field.font = .systemFont(ofSize: 16)
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    private let clearButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .secondaryLabel
        button.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("取消", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSearchBar()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSearchBar()
    }

    public convenience init(placeholder: String = "搜索") {
        self.init(frame: .zero)
        self.placeholder = placeholder
    }

    // MARK: - 设置

    private func setupSearchBar() {
        addSubview(backgroundView)
        backgroundView.addSubview(searchIconView)
        backgroundView.addSubview(textField)
        backgroundView.addSubview(clearButton)
        addSubview(cancelButton)

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            backgroundView.heightAnchor.constraint(equalToConstant: 36),

            searchIconView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 8),
            searchIconView.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor),
            searchIconView.widthAnchor.constraint(equalToConstant: 20),
            searchIconView.heightAnchor.constraint(equalToConstant: 20),

            textField.leadingAnchor.constraint(equalTo: searchIconView.trailingAnchor, constant: 8),
            textField.trailingAnchor.constraint(equalTo: clearButton.leadingAnchor, constant: -8),
            textField.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor),

            clearButton.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -8),
            clearButton.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor),
            clearButton.widthAnchor.constraint(equalToConstant: 20),
            clearButton.heightAnchor.constraint(equalToConstant: 20),

            cancelButton.leadingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: 8),
            cancelButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            cancelButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        ])

        // 设置事件
        clearButton.ls_addAction(for: .touchUpInside) { [weak self] in
            self?.searchText = nil
            self?.clearButton.isHidden = true
        }

        cancelButton.ls_addAction(for: .touchUpInside) { [weak self] in
            self?.resignFirstResponder()
            self?.onCancel?()
        }

        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        textField.addTarget(self, action: #selector(textFieldDidEndOnExit), for: .editingDidEndOnExit)

        updatePlaceholder()
        updateStyle()
    }

    // MARK: - 更新方法

    private func updatePlaceholder() {
        textField.placeholder = placeholder
    }

    private func updateStyle() {
        switch searchBarStyle {
        case .default:
            backgroundView.backgroundColor = .systemGray6
            backgroundView.layer.cornerRadius = 10

        case .minimal:
            backgroundView.backgroundColor = .clear
            backgroundView.layer.cornerRadius = 0

        case .prominent:
            backgroundView.backgroundColor = .systemGray5
            backgroundView.layer.cornerRadius = 10
        }
    }

    private func updateLayout() {
        if showsCancelButton {
            cancelButton.isHidden = false
        } else {
            cancelButton.isHidden = true
        }
    }

    // MARK: - 文本字段事件

    @objc private func textFieldDidChange() {
        if let tempValue = .isEmpty {
            isHidden = tempValue
        } else {
            isHidden = true
        }
        let _tempVar0
        if let t = textField.text {
            _tempVar0 = t
        } else {
            _tempVar0 = ""
        }
        onTextChanged?(_tempVar0)
    }

    @objc private func textFieldDidEndOnExit() {
        if let text = textField.text, !text.isEmpty {
            onSearch?(text)
        }
        textField.resignFirstResponder()
    }

    // MARK: - 公共方法

    /// 成为第一响应者
    public func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }

    /// 放弃第一响应者
    public func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }
}

// MARK: - UIView Extension (Search)

public extension UIView {

    private enum AssociatedKeys {
        static var searchBarKey: UInt8 = 0
    }var ls_searchBar: LSSearchBar? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.searchBarKey) as? LSSearchBar
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.searchBarKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// 添加搜索栏
    @discardableResult
    func ls_addSearchBar(
        placeholder: String = "搜索",
        height: CGFloat = 52
    ) -> LSSearchBar {
        let searchBar = LSSearchBar(placeholder: placeholder)
        searchBar.translatesAutoresizingMaskIntoConstraints = false

        addSubview(searchBar)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            searchBar.heightAnchor.constraint(equalToConstant: height)
        ])

        ls_searchBar = searchBar
        return searchBar
    }
}

// MARK: - UIViewController Extension (Search)

public extension UIViewController {

    /// 添加搜索控制器
    @discardableResult
    func ls_addSearchController(
        data: [String] = [],
        placeholder: String = "搜索"
    ) -> LSSearchController {
        let searchController = LSSearchController(data: data, placeholder: placeholder)

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        return searchController
    }
}

#endif

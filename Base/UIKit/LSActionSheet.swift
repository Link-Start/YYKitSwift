//
//  LSActionSheet.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  操作表单工具 - 简化 UIActionSheet 和 UIAlertController(ActionSheet) 的使用
//

#if canImport(UIKit)
import UIKit

// MARK: - LSActionSheet

/// 操作表单工具类
public enum LSActionSheet {

    // MARK: - 显示 Action Sheet

    /// 显示 Action Sheet（iOS 14+ 使用菜单）
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - message: 消息
    ///   - actions: 操作数组
    ///   - cancelTitle: 取消按钮标题
    ///   - destructive: 销毁操作索引
    ///   - sourceView: 源视图（iPad 需要）
    ///   - completion: 完成回调（返回点击的操作索引，取消返回 -1）
    @available(iOS, deprecated: 13.0, message: "使用 UIAlertController 或 iOS 14+ 的 UIMenu")
    public static func show(
        title: String? = nil,
        message: String? = nil,
        actions: [Action],
        cancelTitle: String = "取消",
        destructive: Int? = nil,
        sourceView: UIView? = nil,
        completion: ((Int) -> Void)? = nil
    ) {
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
              let rootVC = window.rootViewController else {
            return
        }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)

        for (index, action) in actions.enumerated() {
            let alertAction = UIAlertAction(title: action.title, style: action.style) { _ in
                completion?(index)
            }
            alert.addAction(alertAction)
        }

        alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel) { _ in
            completion?(-1)
        })

        // iPad 需要 sourceView
        if let popover = alert.popoverPresentationController, UIDevice.current.userInterfaceIdiom == .pad {
            if let sourceView = sourceView {
                popover.sourceView = sourceView
                popover.sourceRect = sourceView.bounds
            } else {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
        }

        rootVC.present(alert, animated: true)
    }

    /// 简化的 Action Sheet
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - items: 选项数组
    ///   - completion: 完成回调（返回点击的索引，取消返回 nil）
    public static func show(
        title: String? = nil,
        items: [String],
        completion: @escaping (Int?) -> Void
    ) {
        let actions = items.map { Action(title: $0, style: .default) }
        show(
            title: title,
            actions: actions,
            cancelTitle: "取消",
            completion: { index in
                completion(index >= 0 ? index : nil)
            }
        )
    }

    // MARK: - iOS 14+ UIMenu

    /// 显示菜单（iOS 14+）
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - items: 菜单项数组
    ///   - completion: 完成回调
    @available(iOS 14.0, *)
    public static func showMenu(
        title: String? = nil,
        items: [MenuItem],
        completion: @escaping (Int) -> Void
    ) {
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
              let rootVC = window.rootViewController else {
            return
        }

        let menu = UIMenu(title: title ?? "", children: items.map { item in
            UIAction(title: item.title, image: item.image) { _ in
                if let index = items.firstIndex(where: { $0 === item }) {
                    completion(index)
                }
            }
        })

        // 显示菜单
        if #available(iOS 15.0, *) {
            let button = UIButton(type: .system)
            button.menu = menu
            button.showsMenuAsPrimaryAction = true
            rootVC.view.addSubview(button)
        } else {
            // iOS 14 需要手动显示
            let alert = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
            for (index, item) in items.enumerated() {
                alert.addAction(UIAlertAction(title: item.title, style: .default) { _ in
                    completion(index)
                })
            }
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            rootVC.present(alert, animated: true)
        }
    }

    /// 简化的菜单（iOS 14+）
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - items: 选项数组
    ///   - completion: 完成回调
    @available(iOS 14.0, *)
    public static func showMenu(
        title: String? = nil,
        items: [String],
        completion: @escaping (Int) -> Void
    ) {
        let menuItems = items.map { MenuItem(title: $0, image: nil) }
        showMenu(title: title, items: menuItems, completion: completion)
    }

    // MARK: - 带图标的 Action Sheet

    /// 显示带图标的 Action Sheet
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - items: 图标和标题对
    ///   - completion: 完成回调
    public static func showWithIcons(
        title: String? = nil,
        items: [(icon: UIImage?, title: String)],
        completion: @escaping (Int?) -> Void
    ) {
        let actions = items.map { Action(title: $0.title, icon: $0.icon) }
        show(
            title: title,
            actions: actions,
            cancelTitle: "取消",
            completion: { index in
                completion(index >= 0 ? index : nil)
            }
        )
    }
}

// MARK: - Action

public extension LSActionSheet {

    /// 操作定义
    struct Action {
        /// 标题
        public let title: String
        /// 样式
        public let style: UIAlertAction.Style
        /// 图标
        public let icon: UIImage?

        public init(title: String, style: UIAlertAction.Style = .default, icon: UIImage? = nil) {
            self.title = title
            self.style = style
            self.icon = icon
        }
    }

    /// 菜单项（iOS 14+）
    @available(iOS 14.0, *)
    struct MenuItem {
        /// 标题
        public let title: String
        /// 图标
        public let image: UIImage?

        public init(title: String, image: UIImage? = nil) {
            self.title = title
            self.image = image
        }
    }
}

// MARK: - 底部选择器

/// 底部选择器视图控制器
public class LSPickerViewController: UIViewController {

    // MARK: - 类型定义

    /// 选择完成回调
    public typealias SelectionHandler = (Int, String?) -> Void

    // MARK: - 属性

    /// 数据源
    public var items: [String] = []

    /// 选中的索引
    public var selectedIndex: Int = 0

    /// 完成回调
    public var onSelection: SelectionHandler?

    /// 标题
    public var pickerTitle: String? {
        didSet { titleLabel.text = pickerTitle }
    }

    // MARK: - UI 组件

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 17)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var pickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()

    private lazy var toolbar: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false

        let separator = UIView()
        separator.backgroundColor = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(separator)

        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5)
        ])

        return view
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("取消", for: .normal)
        button.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("确定", for: .normal)
        button.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - 初始化

    public init(items: [String], selectedIndex: Int = 0) {
        self.items = items
        self.selectedIndex = selectedIndex
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.items = []
        super.init(coder: coder)
    }

    // MARK: - 生命周期

    public override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupConstraints()
        setupPicker()
    }

    // MARK: - 设置

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(toolbar)
        view.addSubview(pickerView)

        toolbar.addSubview(cancelButton)
        toolbar.addSubview(doneButton)
        toolbar.addSubview(titleLabel)

        pickerView.delegate = self
        pickerView.dataSource = self
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Toolbar
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 44),

            // Cancel button
            cancelButton.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor, constant: 16),
            cancelButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),

            // Done button
            doneButton.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor, constant: -16),
            doneButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),

            // Title label
            titleLabel.centerXAnchor.constraint(equalTo: toolbar.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),

            // Picker
            pickerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pickerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pickerView.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            pickerView.heightAnchor.constraint(equalToConstant: 216)
        ])
    }

    private func setupPicker() {
        if items.count > selectedIndex {
            pickerView.selectRow(selectedIndex, inComponent: 0, animated: false)
        }
    }

    // MARK: - 操作

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func doneTapped() {
        selectedIndex = pickerView.selectedRow(inComponent: 0)
        let selectedItem = items.isEmpty ? nil : items[selectedIndex]
        onSelection?(selectedIndex, selectedItem)
        dismiss(animated: true)
    }

    /// 显示选择器
    ///
    /// - Parameter viewController: 父视图控制器
    public func show(from viewController: UIViewController) {
        modalPresentationStyle = .pageSheet
        viewController.present(self, animated: true)
    }
}

// MARK: - UIPickerViewDataSource

extension LSPickerViewController: UIPickerViewDataSource {

    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return items.count
    }
}

// MARK: - UIPickerViewDelegate

extension LSPickerViewController: UIPickerViewDelegate {

    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return items.count > row ? items[row] : nil
    }
}

// MARK: - 便捷方法

public extension LSActionSheet {

    /// 显示单列选择器
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - items: 选项数组
    ///   - selectedIndex: 默认选中索引
    ///   - viewController: 父视图控制器
    ///   - completion: 完成回调
    @available(iOS 13.0, *)
    static func showPicker(
        title: String? = nil,
        items: [String],
        selectedIndex: Int = 0,
        from viewController: UIViewController,
        completion: @escaping (Int, String?) -> Void
    ) {
        let picker = LSPickerViewController(items: items, selectedIndex: selectedIndex)
        picker.pickerTitle = title
        picker.onSelection = completion
        picker.show(from: viewController)
    }
}

#endif

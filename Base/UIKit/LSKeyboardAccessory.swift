//
//  LSKeyboardAccessory.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  键盘附件视图 - 文本输入上方的工具栏
//

#if canImport(UIKit)
import UIKit

// MARK: - LSKeyboardAccessoryView

/// 键盘附件视图
@MainActor
public class LSKeyboardAccessoryView: UIView {

    // MARK: - 类型定义

    /// 按钮点击回调
    public typealias ButtonHandler = () -> Void

    /// 完成按钮点击回调
    public typealias CompletionHandler = () -> Void

    // MARK: - 属性

    /// 工具栏
    private let toolbar = UIToolbar()

    /// 完成回调
    public var onCompletion: CompletionHandler?

    /// 自动添加完成按钮
    public var autoAddCompletionButton = false

    /// 按钮样式
    public var buttonStyle: UIBarButtonItem.Style = .plain

    // MARK: - 初始化

    public init(frame: CGRect = .zero) {
        super.init(frame: frame)
        setupToolbar()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupToolbar()
    }

    // MARK: - 设置

    private func setupToolbar() {
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(toolbar)

        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: trailingAnchor),
            toolbar.topAnchor.constraint(equalTo: topAnchor),
            toolbar.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        toolbar.barTintColor = .secondarySystemBackground
        toolbar.tintColor = .label
    }

    // MARK: - 工具栏操作

    /// 设置工具栏项
    ///
    /// - Parameter items: 工具栏项数组
    public func setItems(_ items: [UIBarButtonItem]) {
        toolbar.items = items
    }

    /// 添加完成按钮
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - style: 样式
    public func addCompletionButton(title: String = "完成", style: UIBarButtonItem.Style = .done) {
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: title, style: style, target: self, action: #selector(completionTapped))

        if let tempValue = toolbar.items {
            items = tempValue
        } else {
            items = []
        }
    }

    /// 添加自定义按钮
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - image: 图片
    ///   - handler: 点击回调
    /// - Returns: 按钮项
    @discardableResult
    public func addButton(
        title: String? = nil,
        image: UIImage? = nil,
        style: UIBarButtonItem.Style = .plain,
        handler: @escaping ButtonHandler
    ) -> UIBarButtonItem {
        let button: UIBarButtonItem
        if let image = image {
            button = UIBarButtonItem(image: image, style: style, target: self, action: #selector(buttonTapped(_:)))
        } else {
            button = UIBarButtonItem(title: title, style: style, target: self, action: #selector(buttonTapped(_:)))
        }

        button.handler = handler
        if let tempValue = toolbar.items {
            items = tempValue
        } else {
            items = []
        }

        return button
    }

    /// 添加固定间距
    ///
    /// - Parameter width: 间距宽度
    public func addFixedSpace(width: CGFloat) {
        let space = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        space.width = width
        if let tempValue = toolbar.items {
            items = tempValue
        } else {
            items = []
        }
    }

    /// 添加弹性间距
    public func addFlexibleSpace() {
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        if let tempValue = toolbar.items {
            items = tempValue
        } else {
            items = []
        }
    }

    /// 清空所有按钮
    public func clearButtons() {
        toolbar.items = []
    }

    // MARK: - 操作

    @objc private func completionTapped() {
        onCompletion?()
        resignFirstResponder()
    }

    @objc private func buttonTapped(_ sender: UIBarButtonItem) {
        sender.handler?()
    }

    /// 添加上一个/下一个/完成按钮
    ///
    /// - Parameters:
    ///   - previousAction: 上一个动作
    ///   - nextAction: 下一个动作
    ///   - completionTitle: 完成按钮标题
    public func addNavigationControls(
        previousAction: ButtonHandler? = nil,
        nextAction: ButtonHandler? = nil,
        completionTitle: String = "完成"
    ) {
        var items: [UIBarButtonItem] = []

        // 上一个
        if let previousAction = previousAction {
            let prevButton = UIBarButtonItem(
                image: UIImage(systemName: "chevron.up"),
                style: .plain,
                target: self,
                action: #selector(buttonTapped(_:))
            )
            prevButton.handler = previousAction
            items.append(prevButton)
        }

        // 下一个
        if let nextAction = nextAction {
            let nextButton = UIBarButtonItem(
                image: UIImage(systemName: "chevron.down"),
                style: .plain,
                target: self,
                action: #selector(buttonTapped(_:))
            )
            nextButton.handler = nextAction
            items.append(nextButton)
        }

        // 弹性间距
        items.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))

        // 完成按钮
        let doneButton = UIBarButtonItem(title: completionTitle, style: .done, target: self, action: #selector(completionTapped))
        items.append(doneButton)

        toolbar.items = items
    }
}

// MARK: - UIBarButtonItem Extension

private var handlerKey: UInt8 = 0

extension UIBarButtonItem {

    var handler: LSKeyboardAccessoryView.ButtonHandler? {
        get {
            return objc_getAssociatedObject(self, &handlerKey) as? LSKeyboardAccessoryView.ButtonHandler
        }
        set {
            objc_setAssociatedObject(self, &handlerKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
}

// MARK: - UITextField Extension (键盘附件)

public extension UITextField {

    /// 设置键盘附件视图
    ///
    /// - Parameter configure: 配置闭包
    func ls_setKeyboardAccessory(_ configure: (LSKeyboardAccessoryView) -> Void) {
        let accessoryView = LSKeyboardAccessoryView()
        configure(accessoryView)
        inputAccessoryView = accessoryView
    }

    /// 添加完成按钮
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - style: 样式
    func ls_addCompletionButton(title: String = "完成", style: UIBarButtonItem.Style = .done) {
        let accessoryView = LSKeyboardAccessoryView()
        accessoryView.addCompletionButton(title: title, style: style)
        inputAccessoryView = accessoryView
    }

    /// 添加导航按钮（上一个/下一个/完成）
    ///
    /// - Parameters:
    ///   - previousAction: 上一个动作
    ///   - nextAction: 下一个动作
    ///   - completionTitle: 完成标题
    func ls_addNavigationControls(
        previousAction: (() -> Void)? = nil,
        nextAction: (() -> Void)? = nil,
        completionTitle: String = "完成"
    ) {
        ls_setKeyboardAccessory { accessory in
            accessory.addNavigationControls(
                previousAction: previousAction,
                nextAction: nextAction,
                completionTitle: completionTitle
            )
        }
    }
}

// MARK: - UITextView Extension (键盘附件)

public extension UITextView {

    /// 设置键盘附件视图
    ///
    /// - Parameter configure: 配置闭包
    func ls_setKeyboardAccessory(_ configure: (LSKeyboardAccessoryView) -> Void) {
        let accessoryView = LSKeyboardAccessoryView()
        configure(accessoryView)
        inputAccessoryView = accessoryView
    }

    /// 添加完成按钮
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - style: 样式
    func ls_addCompletionButton(title: String = "完成", style: UIBarButtonItem.Style = .done) {
        let accessoryView = LSKeyboardAccessoryView()
        accessoryView.addCompletionButton(title: title, style: style)
        inputAccessoryView = accessoryView
    }

    /// 添加导航按钮（上一个/下一个/完成）
    ///
    /// - Parameters:
    ///   - previousAction: 上一个动作
    ///   - nextAction: 下一个动作
    ///   - completionTitle: 完成标题
    func ls_addNavigationControls(
        previousAction: (() -> Void)? = nil,
        nextAction: (() -> Void)? = nil,
        completionTitle: String = "完成"
    ) {
        ls_setKeyboardAccessory { accessory in
            accessory.addNavigationControls(
                previousAction: previousAction,
                nextAction: nextAction,
                completionTitle: completionTitle
            )
        }
    }
}

// MARK: - LSTextInputAccessory

/// 文本输入附件管理器（管理多个输入控件的导航）
public class LSTextInputAccessory: NSObject {

    // MARK: - 类型定义

    /// 输入控件协议
    public protocol TextInputControl: NSObjectProtocol {
        var becomesFirstResponder: () -> Bool { get }
        var resignFirstResponder: () -> Bool { get }
    }

    // MARK: - 属性

    /// 输入控件列表
    public var textInputs: [TextInputControl] = []

    /// 当前索引
    public private(set) var currentIndex: Int = 0

    // MARK: - 单例

    /// 默认实例
    public static let shared = LSTextInputAccessory()

    // MARK: - 方法

    /// 添加输入控件
    ///
    /// - Parameter textInput: 输入控件
    public func addTextInput(_ textInput: TextInputControl) {
        textInputs.append(textInput)
    }

    /// 移除输入控件
    ///
    /// - Parameter textInput: 输入控件
    public func removeTextInput(_ textInput: TextInputControl) {
        if let index = textInputs.firstIndex(where: { $0 === textInput }) {
            textInputs.remove(at: index)
        }
    }

    /// 清空所有输入控件
    public func clearTextInputs() {
        textInputs.removeAll()
        currentIndex = 0
    }

    /// 移动到上一个
    ///
    /// - Returns: 是否成功
    @discardableResult
    public func moveToPrevious() -> Bool {
        guard currentIndex > 0 else { return false }

        // 放弃当前
        if currentIndex < textInputs.count {
            _ = textInputs[currentIndex].resignFirstResponder()
        }

        // 移动到上一个
        currentIndex -= 1
        if currentIndex < textInputs.count {
            _ = textInputs[currentIndex].becomesFirstResponder()
        }

        return true
    }

    /// 移动到下一个
    ///
    /// - Returns: 是否成功
    @discardableResult
    public func moveToNext() -> Bool {
        guard currentIndex < textInputs.count - 1 else { return false }

        // 放弃当前
        if currentIndex < textInputs.count {
            _ = textInputs[currentIndex].resignFirstResponder()
        }

        // 移动到下一个
        currentIndex += 1
        if currentIndex < textInputs.count {
            _ = textInputs[currentIndex].becomesFirstResponder()
        }

        return true
    }

    /// 移动到指定索引
    ///
    /// - Parameter index: 索引
    /// - Returns: 是否成功
    @discardableResult
    public func moveTo(_ index: Int) -> Bool {
        guard index >= 0 && index < textInputs.count else { return false }

        // 放弃当前
        if currentIndex < textInputs.count {
            _ = textInputs[currentIndex].resignFirstResponder()
        }

        currentIndex = index
        _ = textInputs[currentIndex].becomesFirstResponder()

        return true
    }

    /// 完成编辑
    public func complete() {
        if currentIndex < textInputs.count {
            _ = textInputs[currentIndex].resignFirstResponder()
        }
    }

    /// 是否有上一个
    public var hasPrevious: Bool {
        return currentIndex > 0
    }

    /// 是否有下一个
    public var hasNext: Bool {
        return currentIndex < textInputs.count - 1
    }
}

// MARK: - UITextField/TextView 支持

extension UITextField: LSTextInputAccessory.TextInputControl {}
extension UITextView: LSTextInputAccessory.TextInputControl {}

// MARK: - UIViewController Extension (键盘附件导航)

public extension UIViewController {

    /// 配置键盘附件导航
    ///
    /// - Parameter textInputs: 文本输入控件数组
    func ls_configureKeyboardAccessory(for textInputs: [UIView]) {
        let manager = LSTextInputAccessory.shared

        // 清空之前的
        manager.clearTextInputs()

        // 添加新的
        for input in textInputs {
            if let textField = input as? UITextField {
                manager.addTextInput(textField)
                textField.ls_addNavigationControls(
                    previousAction: { [weak self] in
                        _ = self?.moveToPreviousTextInput()
                    },
                    nextAction: { [weak self] in
                        _ = self?.moveToNextTextInput()
                    }
                )
            } else if let textView = input as? UITextView {
                manager.addTextInput(textView)
                textView.ls_addNavigationControls(
                    previousAction: { [weak self] in
                        _ = self?.moveToPreviousTextInput()
                    },
                    nextAction: { [weak self] in
                        _ = self?.moveToNextTextInput()
                    }
                )
            }
        }
    }

    /// 移动到上一个输入控件
    ///
    /// - Returns: 是否成功
    @discardableResult
    func moveToPreviousTextInput() -> Bool {
        return LSTextInputAccessory.shared.moveToPrevious()
    }

    /// 移动到下一个输入控件
    ///
    /// - Returns: 是否成功
    @discardableResult
    func moveToNextTextInput() -> Bool {
        return LSTextInputAccessory.shared.moveToNext()
    }
}

#endif

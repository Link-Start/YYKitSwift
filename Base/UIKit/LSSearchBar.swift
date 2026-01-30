//
//  LSSearchBar.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  搜索栏 - 类似 UISearchBar 的自定义实现
//

#if canImport(UIKit)
import UIKit

// MARK: - LSSearchBar

/// 搜索栏
@MainActor
public class LSSearchBar: UIView {

    // MARK: - 类型定义

    /// 文本变化回调
    public typealias TextChangeHandler = (String) -> Void

    /// 搜索回调
    public typealias SearchHandler = (String) -> Void

    /// 取消回调
    public typealias CancelHandler = () -> Void

    // MARK: - 属性

    /// 占位符文本
    public var placeholder: String = "搜索" {
        didSet {
            searchField.placeholder = placeholder
        }
    }

    /// 搜索文本
    public var text: String? {
        get { return searchField.text }
        set { searchField.text = newValue }
    }

    /// 是否显示取消按钮
    public var showsCancelButton: Bool = false {
        didSet {
            updateCancelButtonVisibility()
        }
    }

    /// 栏颜色
    public var barTintColor: UIColor = .systemBackground {
        didSet {
            backgroundColor = barTintColor
            searchField.backgroundColor = UIColor.systemGray.withAlphaComponent(0.1)
        }
    }

    /// 文本颜色
    public var textColor: UIColor = .label {
        didSet {
            searchField.textColor = textColor
        }
    }

    /// 占位符颜色
    public var placeholderColor: UIColor = .secondaryLabel {
        didSet {
            searchField.ls_setPlaceholderColor(placeholderColor)
        }
    }

    /// 搜索图标
    public var searchIcon: UIImage? {
        didSet {
            updateSearchIcon()
        }
    }

    /// 清除图标
    public var clearIcon: UIImage? {
        didSet {
            updateClearIcon()
        }
    }

    /// 文本变化回调
    public var onTextChanged: TextChangeHandler?

    /// 搜索回调
    public var onSearch: SearchHandler?

    /// 取消回调
    public var onCancel: CancelHandler?

    /// 是否自动聚焦
    public var autoBecomeFirstResponder: Bool = false

    // MARK: - UI 组件

    /// 搜索框
    private let searchField: UITextField = {
        let tf = UITextField()
        tf.borderStyle = .none
        tf.font = .systemFont(ofSize: 16)
        tf.clearButtonMode = .whileEditing
        return tf
    }()

    /// 搜索图标容器
    private let iconContainerView: UIView = {
        let view = UIView()
        view.frame = CGRect(x: 0, y: 0, width: 36, height: 20)
        return view
    }()

    /// 搜索图标视图
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .secondaryLabel
        return iv
    }()

    /// 取消按钮
    private lazy var cancelButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("取消", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17)
        btn.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        btn.isHidden = true
        return btn
    }()

    /// 分隔线
    private let separatorLine: UIView = {
        let line = UIView()
        line.backgroundColor = .separator
        return line
    }()

    // MARK: - 初始化

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
        backgroundColor = barTintColor

        // 设置搜索框
        searchField.backgroundColor = UIColor.systemGray.withAlphaComponent(0.1)
        searchField.layer.cornerRadius = 8
        searchField.leftView = iconContainerView
        searchField.leftViewMode = .always

        // 设置图标
        iconContainerView.addSubview(iconImageView)
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 16),
            iconImageView.heightAnchor.constraint(equalToConstant: 16)
        ])

        // 添加子视图
        addSubview(searchField)
        addSubview(cancelButton)
        addSubview(separatorLine)

        searchField.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        separatorLine.translatesAutoresizingMaskIntoConstraints = false

        // 约束
        NSLayoutConstraint.activate([
            searchField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            searchField.trailingAnchor.constraint(equalTo: cancelButton.leadingAnchor, constant: -8),
            searchField.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            searchField.heightAnchor.constraint(equalToConstant: 36),

            cancelButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            cancelButton.centerYAnchor.constraint(equalTo: searchField.centerYAnchor),
            cancelButton.widthAnchor.constraint(equalToConstant: 0),

            separatorLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5)
        ])

        // 事件监听
        searchField.addTarget(
            self,
            action: #selector(textFieldDidChange),
            for: .editingChanged
        )

        searchField.addTarget(
            self,
            action: #selector(textFieldDidBeginEditing),
            for: .editingDidBegin
        )

        searchField.addTarget(
            self,
            action: #selector(textFieldDidEndEditing),
            for: .editingDidEnd
        )

        // 更新图标
        updateSearchIcon()

        // 计算高度
        heightAnchor.constraint(equalToConstant: 52).isActive = true
    }

    // MARK: - 更新

    private func updateSearchIcon() {
        if let icon = searchIcon {
            iconImageView.image = icon
        } else {
            // 使用系统图标
            let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
            iconImageView.image = UIImage(systemName: "magnifyingglass", withConfiguration: config)
        }
    }

    private func updateClearIcon() {
        if let icon = clearIcon {
            searchField.ls_setClearButtonImage(icon, for: .whileEditing)
        }
    }

    private func updateCancelButtonVisibility() {
        let width = showsCancelButton ? 60 : 0

        UIView.animate(withDuration: 0.2) {
            self.cancelButtonWidthConstraint?.constant = width
            self.cancelButton.isHidden = !self.showsCancelButton
            self.layoutIfNeeded()
        }
    }

    private var cancelButtonWidthConstraint: NSLayoutConstraint? {
        return cancelButton.constraints.first { $0.firstAttribute == .width }
    }

    // MARK: - 事件

    @objc private func textFieldDidChange() {
        let _tempVar0
        if let t = text {
            _tempVar0 = t
        } else {
            _tempVar0 = ""
        }
        onTextChanged?(_tempVar0)
    }

    @objc private func textFieldDidBeginEditing() {
        if showsCancelButton {
            updateCancelButtonVisibility()
        }
    }

    @objc private func textFieldDidEndEditing() {
        if let isEmpty = text?.isEmpty {
            if !isEmpty {
                updateCancelButtonVisibility()
            }
        } else {
            updateCancelButtonVisibility()
        }
    }

    @objc private func cancelButtonTapped() {
        searchField.resignFirstResponder()
        text = ""
        onCancel?()
    }

    // MARK: - 公共方法

    /// 开始搜索
    public func becomeFirstResponder() -> Bool {
        return searchField.becomeFirstResponder()
    }

    /// 结束搜索
    public func resignFirstResponder() -> Bool {
        return searchField.resignFirstResponder()
    }

    /// 清空文本
    public func clearText() {
        text = ""
        onTextChanged?("")
    }

    /// 触发搜索
    public func triggerSearch() {
        let _tempVar0
        if let t = text {
            _tempVar0 = t
        } else {
            _tempVar0 = ""
        }
        onSearch?(_tempVar0)
    }
}

// MARK: - UITextField Extension (占位符颜色)

private extension UITextField {

    func ls_setPlaceholderColor(_ color: UIColor) {
        let placeholderText: String
        if let temp = placeholder {
            placeholderText = temp
        } else {
            placeholderText = ""
        }
        attributedPlaceholder = NSAttributedString(
            string: placeholderText,
            attributes: [.foregroundColor: color]
        )
    }

    func ls_setClearButtonImage(_ image: UIImage, for controlState: UIControl.State) {
        let clearButton = self.value(forKey: "_clearButton") as? UIButton
        clearButton?.setImage(image, for: controlState)
    }
}

// MARK: - UISearchBar Extension (替代方案)

public extension UISearchBar {

    /// 设置搜索栏样式
    func ls_applyStyle(
        barTintColor: UIColor = .systemBackground,
        textColor: UIColor = .label,
        placeholderColor: UIColor = .secondaryLabel
    ) {
        self.barTintColor = barTintColor
        self.searchTextField.textColor = textColor
        self.searchTextField.ls_setPlaceholderColor(placeholderColor)

        if let backgroundView = self.value(forKey: "backgroundView") as? UIView {
            backgroundView.backgroundColor = barTintColor
        }
    }

    /// 设置圆角样式
    func ls_applyRoundedStyle(cornerRadius: CGFloat = 8) {
        self.searchTextField.layer.cornerRadius = cornerRadius
        self.searchTextField.layer.masksToBounds = true

        if let backgroundView = self.value(forKey: "backgroundView") as? UIView {
            backgroundView.layer.cornerRadius = cornerRadius
            backgroundView.layer.masksToBounds = true
        }
    }

    /// 是否正在编辑
    var ls_isEditing: Bool {
        return self.isFirstResponder
    }

    /// 安全地设置文本
    func ls_setText(_ text: String?, animated: Bool = true) {
        let updateBlock = {
            self.text = text
        }

        if animated {
            UIView.animate(withDuration: 0.2) {
                updateBlock()
            }
        } else {
            updateBlock()
        }
    }
}

// MARK: - UITextField Extension (占位符颜色)

public extension UITextField {

    /// 设置占位符颜色
    func ls_setPlaceholderColor(_ color: UIColor) {
        let placeholderText: String
        if let temp = placeholder {
            placeholderText = temp
        } else {
            placeholderText = ""
        }
        attributedPlaceholder = NSAttributedString(
            string: placeholderText,
            attributes: [.foregroundColor: color]
        )
    }

    /// 设置占位符属性
    func ls_setPlaceholderAttributes(_ attributes: [NSAttributedString.Key: Any]) {
        let placeholderText: String
        if let temp = placeholder {
            placeholderText = temp
        } else {
            placeholderText = ""
        }
        attributedPlaceholder = NSAttributedString(
            string: placeholderText,
            attributes: attributes
        )
    }
}

#endif

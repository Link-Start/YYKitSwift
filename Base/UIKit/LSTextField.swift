//
//  LSTextField.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  增强的文本输入框 - 提供更多便捷功能
//

#if canImport(UIKit)
import UIKit

// MARK: - LSTextField

/// 增强的文本输入框
@MainActor
public class LSTextField: UITextField {

    // MARK: - 类型定义

    /// 文本变化回调
    public typealias TextChangeHandler = (String) -> Void

    /// 验证结果
    public enum ValidationResult {
        case valid
        case invalid(String)
    }

    /// 验证器类型
    public typealias Validator = (String) -> ValidationResult

    // MARK: - 属性

    /// 占位符颜色
    public var placeholderColor: UIColor = .systemGray {
        didSet {
            updatePlaceholder()
        }
    }

    /// 占位符字体
    public var placeholderFont: UIFont? {
        didSet {
            updatePlaceholder()
        }
    }

    /// 文本变化回调
    public var onTextChanged: TextChangeHandler?

    /// 文本结束编辑回调
    public var onTextEnd: ((String) -> Void)?

    /// 验证器
    public var validator: Validator?

    /// 验证状态
    public private(set) var validationResult: ValidationResult = .valid {
        didSet {
            updateValidationState()
        }
    }

    /// 最大长度
    public var maxLength: Int?

    /// 清除按钮
    public let clearButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .systemGray
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()

    /// 内边距
    public var textInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 左侧视图
    public var leftViewImage: UIImage? {
        didSet {
            updateLeftView()
        }
    }

    /// 左侧视图大小
    public var leftViewSize: CGSize = CGSize(width: 30, height: 30) {
        didSet {
            updateLeftView()
        }
    }

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupTextField()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTextField()
    }

    // MARK: - 设置

    private func setupTextField() {
        // 添加清除按钮
        addSubview(clearButton)
        NSLayoutConstraint.activate([
            clearButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            clearButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            clearButton.widthAnchor.constraint(equalToConstant: 20),
            clearButton.heightAnchor.constraint(equalToConstant: 20)
        ])

        clearButton.ls_addAction(for: .touchUpInside) { [weak self] _ in
            self?.text = ""
            self?.sendActions(for: .editingChanged)
        }

        // 添加文本变化监听
        addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        addTarget(self, action: #selector(textDidEnd), for: .editingDidEnd)
    }

    // MARK: - 事件处理

    @objc private func textDidChange() {
        // 更新清除按钮
        let isHidden: Bool
        if let textValue = text {
            isHidden = textValue.isEmpty
        } else {
            isHidden = true
        }
        clearButton.isHidden = isHidden

        // 限制最大长度
        if let maxLength = maxLength,
           let text = text,
           text.count > maxLength {
            self.text = String(text.prefix(maxLength))
        }

        // 验证
        validate()

        // 回调
        let textValue: String
        if let txt = text {
            textValue = txt
        } else {
            textValue = ""
        }
        onTextChanged?(textValue)
    }

    @objc private func textDidEnd() {
        let textValue: String
        if let txt = text {
            textValue = txt
        } else {
            textValue = ""
        }
        onTextEnd?(textValue)
    }

    // MARK: - 验证

    /// 验证文本
    public func validate() -> Bool {
        guard let validator = validator else { return true }

        let textValue: String
        if let txt = text {
            textValue = txt
        } else {
            textValue = ""
        }
        let result = validator(textValue)
        validationResult = result

        return result == .valid
    }

    private func updateValidationState() {
        switch validationResult {
        case .valid:
            layer.borderColor = UIColor.clear.cgColor
            layer.borderWidth = 0

        case .invalid(let message):
            layer.borderColor = UIColor.systemRed.cgColor
            layer.borderWidth = 1

            // 可以显示错误提示
            #if DEBUG
            print("验证失败: \(message)")
            #endif
        }
    }

    // MARK: - 占位符

    private func updatePlaceholder() {
        guard let placeholder = placeholder else { return }

        let fontValue: UIFont
        if let pf = placeholderFont {
            fontValue = pf
        } else if let f = font {
            fontValue = f
        } else {
            fontValue = .systemFont(ofSize: 16)
        }

        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: placeholderColor,
            .font: fontValue
        ]

        attributedPlaceholder = NSAttributedString(string: placeholder, attributes: attributes)
    }

    // MARK: - 左侧视图

    private func updateLeftView() {
        guard let image = leftViewImage else {
            leftView = nil
            leftViewMode = .never
            return
        }

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGray
        imageView.frame = CGRect(origin: .zero, size: leftViewSize)

        leftView = imageView
        leftViewMode = .always
    }

    // MARK: - 绘制

    public override func draw(_ rect: CGRect) {
        super.draw(rect)

        // 如果有内边距，重绘文本
        guard textInsets != .zero else { return }
    }

    public override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: textInsets)
    }

    public override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: textInsets)
    }

    public override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: textInsets)
    }
}

// MARK: - UITextField Extension

public extension UITextField {

    /// 设置占位符颜色
    func ls_setPlaceholderColor(_ color: UIColor) {
        guard let placeholder = placeholder else { return }

        let fontValue: UIFont
        if let f = font {
            fontValue = f
        } else {
            fontValue = .systemFont(ofSize: 16)
        }

        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: color,
            .font: fontValue
        ]

        attributedPlaceholder = NSAttributedString(string: placeholder, attributes: attributes)
    }

    /// 设置占位符字体
    func ls_setPlaceholderFont(_ font: UIFont) {
        guard let placeholder = placeholder else { return }

        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.systemGray,
            .font: font
        ]

        attributedPlaceholder = NSAttributedString(string: placeholder, attributes: attributes)
    }

    /// 添加左侧图标
    func ls_setLeftIcon(_ image: UIImage, size: CGSize = CGSize(width: 30, height: 30)) {
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGray
        imageView.frame = CGRect(origin: .zero, size: size)

        leftView = imageView
        leftViewMode = .always
    }

    /// 添加右侧图标
    func ls_setRightIcon(_ image: UIImage, size: CGSize = CGSize(width: 30, height: 30)) {
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGray
        imageView.frame = CGRect(origin: .zero, size: size)

        rightView = imageView
        rightViewMode = .always
    }

    /// 设置内边距
    func ls_setTextInsets(_ insets: UIEdgeInsets) {
        let textField = LSTextField()
        textField.textInsets = insets
    }

    /// 添加文本变化监听
    func ls_onTextChanged(_ handler: @escaping (String) -> Void) {
        let textField = LSTextField()
        textField.onTextChanged = handler
    }

    /// 添加文本结束监听
    func ls_onTextEnd(_ handler: @escaping (String) -> Void) {
        let textField = LSTextField()
        textField.onTextEnd = handler
    }

    /// 设置最大长度
    func ls_setMaxLength(_ length: Int) {
        let textField = LSTextField()
        textField.maxLength = length
    }

    /// 设置为密码输入框
    func ls_setSecure() {
        isSecureTextEntry = true
    }

    /// 设置为数字键盘
    func ls_setNumberKeyboard() {
        keyboardType = .numberPad
    }

    /// 设置为邮箱键盘
    func ls_setEmailKeyboard() {
        keyboardType = .emailAddress
    }

    /// 设置为电话键盘
    func ls_setPhoneKeyboard() {
        keyboardType = .phonePad
    }

    /// 设置为 URL 键盘
    func ls_setURLKeyboard() {
        keyboardType = .URL
    }

    /// 禁用自动更正
    func ls_disableAutocorrection() {
        autocorrectionType = .no
    }

    /// 设置大写类型
    func ls_setCapitalization(_ type: UITextAutocapitalizationType) {
        autocapitalizationType = type
    }

    /// 设置返回键类型
    func ls_setReturnKeyType(_ type: UIReturnKeyType) {
        returnKeyType = type
    }

    /// 添加输入完成监听
    func ls_onReturn(_ handler: @escaping () -> Bool) {
        let textField = LSTextField()
        textField.ls_addAction(for: .editingDidEndOnExit) { _ in
            handler()
        }
    }

    /// 添加清除按钮
    func ls_addClearButton() {
        let clearButton = UIButton(type: .system)
        clearButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        clearButton.tintColor = .systemGray
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.isHidden = true

        addSubview(clearButton)
        NSLayoutConstraint.activate([
            clearButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            clearButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            clearButton.widthAnchor.constraint(equalToConstant: 20),
            clearButton.heightAnchor.constraint(equalToConstant: 20)
        ])

        clearButton.ls_addAction(for: .touchUpInside) { [weak self] _ in
            self?.text = ""
            self?.sendActions(for: .editingChanged)
        }

        addTarget(self, action: #selector(updateClearButton), for: .editingChanged)
    }

    @objc private func updateClearButton() {
        // 子类重写
    }

    /// 添加左侧按钮
    func ls_addLeftButton(_ image: UIImage, action: @escaping () -> Void) {
        let button = UIButton(type: .system)
        button.setImage(image, for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)

        leftView = button
        leftViewMode = .always

        button.ls_addAction(for: .touchUpInside) { _ in
            action()
        }
    }

    /// 添加右侧按钮
    func ls_addRightButton(_ image: UIImage, action: @escaping () -> Void) {
        let button = UIButton(type: .system)
        button.setImage(image, for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)

        rightView = button
        rightViewMode = .always

        button.ls_addAction(for: .touchUpInside) { _ in
            action()
        }
    }

    /// 是否为空
    var ls_isEmpty: Bool {
        if let textValue = text {
            return textValue.isEmpty
        } else {
            return true
        }
    }

    /// 去除空格后的文本
    var ls_trimmedText: String? {
        return text?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 验证邮箱
    func ls_validateEmail() -> Bool {
        guard let text = text else { return false }
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: text)
    }

    /// 验证手机号
    func ls_validatePhone() -> Bool {
        guard let text = text else { return false }
        let phoneRegex = "^1[3-9]\\d{9}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: text)
    }

    /// 验证数字
    func ls_validateNumber() -> Bool {
        guard let text = text else { return false }
        return Int(text) != nil
    }

    /// 验证密码（6-20位字母数字组合）
    func ls_validatePassword() -> Bool {
        guard let text = text else { return false }
        let passwordRegex = "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{6,20}$"
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        return passwordPredicate.evaluate(with: text)
    }

    /// 验证身份证号
    func ls_validateIDCard() -> Bool {
        guard let text = text else { return false }
        let idCardRegex = "^[1-9]\\d{5}(18|19|20)\\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\\d|3[01])\\d{3}[\\dXx]$"
        let idCardPredicate = NSPredicate(format: "SELF MATCHES %@", idCardRegex)
        return idCardPredicate.evaluate(with: text)
    }

    /// 设置输入框样式
    func ls_applyStyle(
        cornerRadius: CGFloat = 8,
        borderColor: UIColor = .systemGray4,
        borderWidth: CGFloat = 1,
        backgroundColor: UIColor = .systemBackground
    ) {
        layer.cornerRadius = cornerRadius
        layer.borderColor = borderColor.cgColor
        layer.borderWidth = borderWidth
        self.backgroundColor = backgroundColor
        layer.masksToBounds = true
    }

    /// 设置为不可编辑
    func ls_setReadonly(_ readonly: Bool) {
        isUserInteractionEnabled = !readonly
        backgroundColor = readonly ? .systemGray6 : .systemBackground
    }

    /// 聚焦
    func ls_focus() {
        becomeFirstResponder()
    }

    /// 失焦
    func ls_blur() {
        resignFirstResponder()
    }

    /// 选中所有文本
    func ls_selectAll() {
        selectedTextRange = textRange(from: beginningOfDocument, to: endOfDocument)
    }
}

// MARK: - 常用验证器

public extension LSTextField {

    /// 邮箱验证器
    static var emailValidator: Validator {
        return { text in
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)

            if emailPredicate.evaluate(with: text) {
                return .valid
            } else {
                return .invalid("请输入正确的邮箱地址")
            }
        }
    }

    /// 手机号验证器
    static var phoneValidator: Validator {
        return { text in
            let phoneRegex = "^1[3-9]\\d{9}$"
            let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)

            if phonePredicate.evaluate(with: text) {
                return .valid
            } else {
                return .invalid("请输入正确的手机号")
            }
        }
    }

    /// 密码验证器
    static var passwordValidator: Validator {
        return { text in
            let passwordRegex = "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{6,20}$"
            let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)

            if passwordPredicate.evaluate(with: text) {
                return .valid
            } else {
                return .invalid("密码为6-20位字母数字组合")
            }
        }
    }

    /// 身份证验证器
    static var idCardValidator: Validator {
        return { text in
            let idCardRegex = "^[1-9]\\d{5}(18|19|20)\\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\\d|3[01])\\d{3}[\\dXx]$"
            let idCardPredicate = NSPredicate(format: "SELF MATCHES %@", idCardRegex)

            if idCardPredicate.evaluate(with: text) {
                return .valid
            } else {
                return .invalid("请输入正确的身份证号")
            }
        }
    }

    /// 非空验证器
    static func notEmptyValidator(message: String = "内容不能为空") -> Validator {
        return { text in
            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return .valid
            } else {
                return .invalid(message)
            }
        }
    }

    /// 最小长度验证器
    static func minLengthValidator(_ length: Int, message: String? = nil) -> Validator {
        return { text in
            if text.count >= length {
                return .valid
            } else {
                let errorMessage: String
                if let msg = message {
                    errorMessage = msg
                } else {
                    errorMessage = "至少需要 \(length) 个字符"
                }
                return .invalid(errorMessage)
            }
        }
    }

    /// 最大长度验证器
    static func maxLengthValidator(_ length: Int, message: String? = nil) -> Validator {
        return { text in
            if text.count <= length {
                return .valid
            } else {
                let errorMessage: String
                if let msg = message {
                    errorMessage = msg
                } else {
                    errorMessage = "最多 \(length) 个字符"
                }
                return .invalid(errorMessage)
            }
        }
    }

    /// 正则验证器
    static func regexValidator(_ pattern: String, message: String = "格式不正确") -> Validator {
        return { text in
            let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
            if predicate.evaluate(with: text) {
                return .valid
            } else {
                return .invalid(message)
            }
        }
    }
}

// MARK: - UITextView Extension

public extension UITextView {

    /// 添加占位符
    func ls_setPlaceholder(_ text: String, color: UIColor = .systemGray, font: UIFont? = nil) {
        let placeholderLabel = UILabel()
        placeholderLabel.text = text
        placeholderLabel.textColor = color

        let fontValue: UIFont
        if let f = font {
            fontValue = f
        } else if let selfFont = self.font {
            fontValue = selfFont
        } else {
            fontValue = .systemFont(ofSize: 17)
        }
        placeholderLabel.font = fontValue

        placeholderLabel.numberOfLines = 0
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(placeholderLabel)
        NSLayoutConstraint.activate([
            placeholderLabel.topAnchor.constraint(equalTo: topAnchor, constant: textContainerInset.top),
            placeholderLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: textContainerInset.left + 5),
            placeholderLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -textContainerInset.right)
        ])

        // 关联占位符标签
        let key = AssociatedKey.placeholderLabelKey
        objc_setAssociatedObject(self, key, placeholderLabel, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        // 监听文本变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChange),
            name: UITextView.textDidChangeNotification,
            object: self
        )
    }

    @objc private func textDidChange() {
        let key = AssociatedKey.placeholderLabelKey
        let placeholderLabel = objc_getAssociatedObject(self, key) as? UILabel
        placeholderLabel?.isHidden = !text.isEmpty
    }

    /// 设置内边距
    func ls_setTextInsets(_ insets: UIEdgeInsets) {
        textContainerInset = insets
    }

    /// 设置最大长度
    func ls_setMaxLength(_ length: Int) {
        let key = AssociatedKey.maxLengthKey
        objc_setAssociatedObject(self, key, length, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(limitLength),
            name: UITextView.textDidChangeNotification,
            object: self
        )
    }

    @objc private func limitLength() {
        let key = AssociatedKey.maxLengthKey
        guard let maxLength = objc_getAssociatedObject(self, key) as? Int else { return }

        if text.count > maxLength {
            text = String(text.prefix(maxLength))
        }
    }

    /// 是否为空
    var ls_isEmpty: Bool {
        return text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 去除空格后的文本
    var ls_trimmedText: String {
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Associated Keys

private struct AssociatedKey {
    static var placeholderLabelKey: UInt8 = 0
    static var maxLengthKey: UInt8 = 0
}

#endif

//
//  LSValidation.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  表单验证工具 - 常用表单验证规则
//

#if canImport(UIKit)
import UIKit
import Foundation

// MARK: - LSValidation

/// 验证规则
public enum LSValidationRule {

    case required           // 必填
    case email              // 邮箱
    case phone              // 手机号（中国大陆）
    case idCard             // 身份证号
    case url                // URL
    case number             // 数字
    case positiveNumber     // 正数
    case negativeNumber     // 负数
    case integer            // 整数
    case minLength(Int)     // 最小长度
    case maxLength(Int)     // 最大长度
    case range(Int, Int)    // 长度范围
    case regex(String)      // 正则表达式
    case custom((String) -> Bool)  // 自定义验证

    /// 验证
    ///
    /// - Parameter value: 要验证的值
    /// - Returns: 验证结果
    public func validate(_ value: String) -> ValidationResult {
        switch self {
        case .required:
            return !value.isEmpty ? .success : .failure("此项为必填")
        case .email:
            return value.ls_isValidEmail ? .success : .failure("请输入有效的邮箱地址")
        case .phone:
            return value.ls_isValidPhoneNumber ? .success : .failure("请输入有效的手机号")
        case .idCard:
            return value.ls_isValidIDCard ? .success : .failure("请输入有效的身份证号")
        case .url:
            return value.ls_isValidURL ? .success : .failure("请输入有效的URL")
        case .number:
            return value.ls_isNumeric ? .success : .failure("请输入数字")
        case .positiveNumber:
            guard let num = Double(value) else { return .failure("请输入数字") }
            return num > 0 ? .success : .failure("请输入正数")
        case .negativeNumber:
            guard let num = Double(value) else { return .failure("请输入数字") }
            return num < 0 ? .success : .failure("请输入负数")
        case .integer:
            return value.ls_isNumeric ? .success : .failure("请输入整数")
        case .minLength(let length):
            return value.count >= length ? .success : .failure("长度不能少于\(length)位")
        case .maxLength(let length):
            return value.count <= length ? .success : .failure("长度不能超过\(length)位")
        case .range(let min, let max):
            return (min...max).contains(value.count) ? .success : .failure("长度应在\(min)-\(max)位之间")
        case .regex(let pattern):
            return value.ls_matches(regex: pattern) ? .success : .failure("格式不正确")
        case .custom(let validator):
            return validator(value) ? .success : .failure("格式不正确")
        }
    }

    /// 错误消息
    var errorMessage: String {
        switch validate("") {
        case .failure(let message):
            return message
        default:
            return "格式不正确"
        }
    }
}

// MARK: - ValidationResult

/// 验证结果
public enum ValidationResult {
    case success
    case failure(String)

    /// 是否成功
    public var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    /// 是否失败
    public var isFailure: Bool {
        if case .failure = self { return true }
        return false
    }

    /// 错误消息
    public var errorMessage: String? {
        if case .failure(let message) = self { return message }
        return nil
    }
}

// MARK: - LSValidator

/// 表单验证器
public class LSValidator {

    // MARK: - 类型定义

    /// 字段验证结果
    public struct FieldResult {
        let fieldName: String
        let result: ValidationResult
    }

    /// 验证字段定义
    public struct Field {
        let name: String
        let value: () -> String?
        let rules: [LSValidationRule]

        public init(name: String, value: @escaping () -> String?, rules: [LSValidationRule]) {
            self.name = name
            self.value = value
            self.rules = rules
        }
    }

    // MARK: - 属性

    /// 验证字段
    private var fields: [Field] = []

    /// 验证结果
    private var results: [String: ValidationResult] = [:]

    // MARK: - 添加字段

    /// 添加验证字段
    ///
    /// - Parameters:
    ///   - name: 字段名
    ///   - value: 值闭包
    ///   - rules: 验证规则
    /// - Returns: self
    @discardableResult
    public func addField(
        name: String,
        value: @escaping () -> String?,
        rules: [LSValidationRule]
    ) -> Self {
        fields.append(Field(name: name, value: value, rules: rules))
        return self
    }

    /// 添加文本字段验证
    ///
    /// - Parameters:
    ///   - name: 字段名
    ///   - textField: 文本框
    ///   - rules: 验证规则
    /// - Returns: self
    @discardableResult
    public func addTextField(
        name: String,
        textField: UITextField?,
        rules: [LSValidationRule]
    ) -> Self {
        return addField(name: name, value: { textField?.text }, rules: rules)
    }

    /// 添加验证规则到指定字段
    ///
    /// - Parameters:
    ///   - name: 字段名
    ///   - rules: 规则数组
    /// - Returns: self
    @discardableResult
    public func addRules(to name: String, rules: [LSValidationRule]) -> Self {
        if let index = fields.firstIndex(where: { $0.name == name }) {
            fields[index].rules.append(contentsOf: rules)
        }
        return self
    }

    /// 移除字段
    ///
    /// - Parameter name: 字段名
    /// - Returns: self
    @discardableResult
    public func removeField(named name: String) -> Self {
        fields.removeAll { $0.name == name }
        results.removeValue(forKey: name)
        return self
    }

    /// 清空所有字段
    public func clearFields() {
        fields.removeAll()
        results.removeAll()
    }

    // MARK: - 验证

    /// 验证所有字段
    ///
    /// - Returns: 验证结果数组
    public func validate() -> [FieldResult] {
        var allResults: [FieldResult] = []

        for field in fields {
            let value = field.value() ?? ""

            for rule in field.rules {
                let result = rule.validate(value)
                if case .failure = result {
                    allResults.append(FieldResult(fieldName: field.name, result: result))
                    results[field.name] = result
                    break // 该字段验证失败，跳出规则循环
                } else {
                    results[field.name] = result
                }
            }
        }

        return allResults
    }

    /// 验证指定字段
    ///
    /// - Parameter name: 字段名
    /// - Returns: 验证结果
    public func validate(field name: String) -> ValidationResult {
        guard let field = fields.first(where: { $0.name == name }) else {
            return .failure("字段不存在")
        }

        let value = field.value() ?? ""

        for rule in field.rules {
            let result = rule.validate(value)
            if case .failure = result {
                results[field.name] = result
                return result
            }
        }

        results[field.name] = .success
        return .success
    }

    /// 验证所有字段是否成功
    ///
    /// - Returns: 是否全部验证通过
    public func isValid() -> Bool {
        return validate().isEmpty
    }

    /// 获取所有错误
    ///
    /// - Returns: 错误信息数组
    public func errors() -> [String] {
        return validate()
            .filter { $0.result.isFailure }
            .compactMap { $0.result.errorMessage }
    }

    /// 获取第一个错误
    ///
    /// - Returns: 错误信息
    public func firstError() -> String? {
        return validate().first?.result.errorMessage
    }
}

// MARK: - UITextField Extension (验证)

public extension UITextField {

    /// 验证文本
    ///
    /// - Parameter rules: 验证规则
    /// - Returns: 验证结果
    func ls_validate(rules: [LSValidationRule]) -> ValidationResult {
        let text = self.text ?? ""

        for rule in rules {
            let result = rule.validate(text)
            if case .failure = result {
                return result
            }
        }

        return .success
    }

    /// 是否符合规则
    ///
    /// - Parameter rules: 验证规则
    /// - Returns: 是否符合
    func ls_conforms(to rules: [LSValidationRule]) -> Bool {
        return ls_validate(rules: rules).isSuccess
    }

    /// 添加验证指示器
    ///
    /// - Parameters:
    ///   - rules: 验证规则
    ///   - validateOnChange: 是否实时验证
    /// - Returns: 验证结果观察对象
    @discardableResult
    func ls_addValidation(
        rules: [LSValidationRule],
        validateOnChange: Bool = true
    ) -> LSValidationObserver {
        let observer = LSValidationObserver(textField: self, rules: rules)
        observer.validateOnChange = validateOnChange
        return observer
    }
}

// MARK: - UITextView Extension (验证)

public extension UITextView {

    /// 验证文本
    ///
    /// - Parameter rules: 验证规则
    /// - Returns: 验证结果
    func ls_validate(rules: [LSValidationRule]) -> ValidationResult {
        let text = self.text ?? ""

        for rule in rules {
            let result = rule.validate(text)
            if case .failure = result {
                return result
            }
        }

        return .success
    }

    /// 是否符合规则
    ///
    /// - Parameter rules: 验证规则
    /// - Returns: 是否符合
    func ls_conforms(to rules: [LSValidationRule]) -> Bool {
        return ls_validate(rules: rules).isSuccess
    }
}

// MARK: - LSValidationObserver

/// 验证观察者
public class LSValidationObserver: NSObject {

    /// 文本框
    public weak var textField: UITextField? {
        didSet {
            setupObservers()
        }
    }

    /// 验证规则
    public var rules: [LSValidationRule]

    /// 是否实时验证
    public var validateOnChange: Bool = true {
        didSet {
            if validateOnChange {
                setupObservers()
            } else {
                removeObservers()
            }
        }
    }

    /// 验证结果回调
    public var onValidationChange: ((ValidationResult) -> Void)?

    /// 当前验证状态
    public private(set) var validationResult: ValidationResult = .success

    // MARK: - 初始化

    public init(textField: UITextField? = nil, rules: [LSValidationRule]) {
        self.textField = textField
        self.rules = rules
        super.init()
        setupObservers()
    }

    deinit {
        removeObservers()
    }

    // MARK: - 观察

    private func setupObservers() {
        removeObservers()

        guard validateOnChange, let textField = textField else { return }

        textField.addTarget(
            self,
            action: #selector(textFieldDidChange),
            for: .editingChanged
        )
    }

    private func removeObservers() {
        textField?.removeTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }

    @objc private func textFieldDidChange() {
        validate()
    }

    // MARK: - 验证

    /// 执行验证
    public func validate() -> ValidationResult {
        let result = textField?.ls_validate(rules: rules) ?? .success
        validationResult = result
        onValidationChange?(result)
        return result
    }

    /// 是否有效
    public var isValid: Bool {
        return validationResult.isSuccess
    }

    /// 错误消息
    public var errorMessage: String? {
        return validationResult.errorMessage
    }
}

// MARK: - 常用验证规则

public extension LSValidationRule {

    /// 用户名规则（字母、数字、下划线，4-16位）
    static var username: LSValidationRule {
        .regex("^[a-zA-Z0-9_]{4,16}$")
    }

    /// 密码规则（至少8位，包含字母和数字）
    static var password: LSValidationRule {
        .custom { value in
            guard value.count >= 8 else { return false }
            return value.ls_containsLetter && value.ls_containsNumber
        }
    }

    /// 强密码规则（至少8位，包含大小写字母、数字）
    static var strongPassword: LSValidationRule {
        .custom { value in
            guard value.count >= 8 else { return false }
            return value.ls_containsUpperCase && value.ls_containsLowerCase && value.ls_containsNumber
        }
    }

    /// 验证码规则（4-6位数字）
    static var verificationCode: LSValidationRule {
        .regex("^\\d{4,6}$")
    }

    /// 金额规则（正数，最多两位小数）
    static var amount: LSValidationRule {
        .regex("^([1-9]\\d*|0)(\\.\\d{1,2})?$")
    }

    /// 年龄规则（1-150）
    static var age: LSValidationRule {
        .custom { value in
            guard let age = Int(value) else { return false }
            return (1...150).contains(age)
        }
    }

    /// 中文姓名规则
    static var chineseName: LSValidationRule {
        .regex("^[\\u4e00-\\u9fa5]{2,10}$")
    }

    /// 日期格式（YYYY-MM-DD）
    static var dateFormat: LSValidationRule {
        .regex("^\\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\\d|3[01])$")
    }

    /// 时间格式（HH:MM）
    static var timeFormat: LSValidationRule {
        .regex("^([01]\\d|2[0-3]):[0-5]\\d$")
    }
}

// MARK: - 常用验证规则组合

public extension [LSValidationRule] {

    /// 手机号验证规则
    static var phoneNumber: [LSValidationRule] {
        return [.required, .phone]
    }

    /// 密码验证规则
    static var password: [LSValidationRule] {
        return [.required, .minLength(8), LSValidationRule.password]
    }

    /// 邮箱验证规则
    static var email: [LSValidationRule] {
        return [.required, .email]
    }

    /// 用户名验证规则
    static var username: [LSValidationRule] {
        return [.required, .minLength(4), .maxLength(16), LSValidationRule.username]
    }
}

#endif

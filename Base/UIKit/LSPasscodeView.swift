//
//  LSPasscodeView.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  密码输入视图 - 用于输入 PIN 码、密码等
//

#if canImport(UIKit)
import UIKit

// MARK: - LSPasscodeView

/// 密码输入视图
@MainActor
public class LSPasscodeView: UIView {

    // MARK: - 类型定义

    /// 输入完成回调
    public typealias CompletionHandler = (String) -> Void

    /// 输入变化回调
    public typealias ChangeHandler = (String) -> Void

    /// 安全区域回调
    public typealias SecurityHandler = (String, Bool) -> Void

    // MARK: - 属性

    /// 密码长度
    public var passcodeLength: Int = 4 {
        didSet {
            passcodeLength = max(1, passcodeLength)
            updatePasscodeView()
        }
    }

    /// 是否安全输入（隐藏字符）
    public var isSecureEntry: Bool = true {
        didSet {
            updatePasscodeView()
        }
    }

    /// 是否显示密码切换按钮
    public var showsSecureToggle: Bool = true {
        didSet {
            secureToggleButton.isHidden = !showsSecureToggle
        }
    }

    /// 点的样式
    public var dotStyle: DotStyle = .circle {
        didSet {
            updatePasscodeView()
        }
    }

    /// 点的大小
    public var dotSize: CGSize = CGSize(width: 12, height: 12) {
        didSet {
            updatePasscodeView()
        }
    }

    /// 点的颜色
    public var dotColor: UIColor = .label {
        didSet {
            updatePasscodeView()
        }
    }

    /// 空点颜色
    public var emptyDotColor: UIColor = .systemGray4 {
        didSet {
            updatePasscodeView()
        }
    }

    /// 点的间距
    public var dotSpacing: CGFloat = 16 {
        didSet {
            updateConstraints()
        }
    }

    /// 是否显示键盘
    public var showsKeyboard: Bool = true {
        didSet {
            if showsKeyboard {
                becomeFirstResponder()
            } else {
                resignFirstResponder()
            }
        }
    }

    /// 密码
    public private(set) var passcode: String = "" {
        didSet {
            onPasscodeChanged?(passcode)
            updatePasscodeView()

            if passcode.count == passcodeLength {
                onPasscodeComplete?(passcode)
            }
        }
    }

    /// 输入完成回调
    public var onPasscodeComplete: CompletionHandler?

    /// 输入变化回调
    public var onPasscodeChanged: ChangeHandler?

    /// 安全验证回调
    public var onSecurityCheck: SecurityHandler?

    /// 是否自动清除
    public var autoClearOnComplete: Bool = false

    // MARK: - UI 组件

    private var dotViews: [UIView] = []

    private let secureToggleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        button.tintColor = .secondaryLabel
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()

    private let textField: UITextField = {
        let field = UITextField()
        field.keyboardType = .numberPad
        field.isHidden = true
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    // MARK: - 点样式

    public enum DotStyle {
        case circle           // 圆形
        case square           // 方形
        case line             // 线条
        case diamond          // 菱形
    }

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupPasscodeView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPasscodeView()
    }

    public convenience init(length: Int = 4) {
        self.init(frame: .zero)
        self.passcodeLength = length
    }

    // MARK: - 设置

    private func setupPasscodeView() {
        backgroundColor = .clear
        clipsToBounds = true

        addSubview(secureToggleButton)
        addSubview(textField)

        // 文本框事件
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        textField.addTarget(self, action: #selector(textFieldDidEndOnExit), for: .editingDidEndOnExit)

        // 切换按钮事件
        secureToggleButton.ls_addAction(for: .touchUpInside) { [weak self] in
            self?.toggleSecureEntry()
        }

        // 点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)

        updatePasscodeView()
    }

    // MARK: - 布局

    public override func layoutSubviews() {
        super.layoutSubviews()
        updateConstraints()
    }

    private func updateConstraints() {
        let totalWidth = CGFloat(passcodeLength) * dotSize.width + CGFloat(passcodeLength - 1) * dotSpacing
        let startX = (bounds.width - totalWidth) / 2
        let startY = (bounds.height - dotSize.height) / 2

        for (index, dotView) in dotViews.enumerated() {
            let x = startX + CGFloat(index) * (dotSize.width + dotSpacing)
            dotView.frame = CGRect(x: x, y: startY, width: dotSize.width, height: dotSize.height)
        }

        // 切换按钮位置
        secureToggleButton.frame = CGRect(
            x: bounds.width - 44,
            y: (bounds.height - 44) / 2,
            width: 44,
            height: 44
        )

        // 文本框位置（隐藏）
        textField.frame = .zero
    }

    // MARK: - 更新方法

    private func updatePasscodeView() {
        // 移除旧的点
        dotViews.forEach { $0.removeFromSuperview() }
        dotViews.removeAll()

        // 创建新的点
        for i in 0..<passcodeLength {
            let dotView = createDotView(at: i)
            addSubview(dotView)
            dotViews.append(dotView)
        }

        updateDotColors()
        setNeedsLayout()
    }

    private func createDotView(at index: Int) -> UIView {
        let dotView = UIView()
        dotView.backgroundColor = emptyDotColor

        switch dotStyle {
        case .circle:
            dotView.layer.cornerRadius = dotSize.width / 2

        case .square:
            dotView.layer.cornerRadius = 2

        case .line:
            dotView.layer.cornerRadius = dotSize.height / 2

        case .diamond:
            let rotation = 45 * .pi / 180
            dotView.transform = CGAffineTransform(rotationAngle: rotation)
            dotView.layer.cornerRadius = 2
        }

        return dotView
    }

    private func updateDotColors() {
        for (index, dotView) in dotViews.enumerated() {
            let isFilled = index < passcode.count

            if isFilled {
                dotView.backgroundColor = dotColor
            } else {
                dotView.backgroundColor = emptyDotColor
            }
        }
    }

    private func toggleSecureEntry() {
        isSecureEntry.toggle()

        let imageName = isSecureEntry ? "eye.slash" : "eye"
        secureToggleButton.setImage(UIImage(systemName: imageName), for: .normal)
    }

    // MARK: - 事件处理

    @objc private func handleTap() {
        if showsKeyboard {
            textField.becomeFirstResponder()
        }
    }

    @objc private func textFieldDidChange() {
        guard let text = textField.text else { return }

        // 限制长度
        if text.count > passcodeLength {
            textField.text = String(text.prefix(passcodeLength))
            if let tempValue = textField.text {
                passcode = tempValue
            } else {
                passcode = ""
            }
        } else {
            passcode = text
        }

        // 安全检查
        if let onSecurityCheck = onSecurityCheck {
            let isValid = onSecurityCheck(passcode, passcode.count == passcodeLength)
            if !isValid {
                // 移除最后一个字符
                passcode.removeLast()
                textField.text = passcode
            }
        }
    }

    @objc private func textFieldDidEndOnExit() {
        // 处理完成
    }

    // MARK: - UIResponder

    public override var canBecomeFirstResponder: Bool {
        return showsKeyboard && textField.becomeFirstResponder()
    }

    public override var canResignFirstResponder: Bool {
        return super.canResignFirstResponder && textField.canResignFirstResponder
    }

    // MARK: - 公共方法

    /// 清除密码
    public func clear() {
        passcode = ""
        textField.text = ""
    }

    /// 设置密码
    public func setPasscode(_ passcode: String) {
        let maxLength = min(passcode.count, passcodeLength)
        self.passcode = String(passcode.prefix(maxLength))
        textField.text = self.passcode
    }

    /// 获取密码
    public func getPasscode() -> String {
        return passcode
    }

    /// 是否完成
    public var isComplete: Bool {
        return passcode.count == passcodeLength
    }

    /// 验证密码
    public func validate(expected: String) -> Bool {
        return passcode == expected
    }

    /// 设置焦点
    public func becomeFocus() {
        showsKeyboard = true
    }

    /// 失去焦点
    public func resignFocus() {
        showsKeyboard = false
    }
}

// MARK: - LSPasscodeViewController

/// 密码输入视图控制器
public class LSPasscodeViewController: UIViewController {

    // MARK: - 类型定义

    /// 验证结果
    public enum ValidationResult {
        case success
        case failure(message: String?)
        case retry(remainingAttempts: Int)
    }

    /// 验证回调
    public typealias ValidationHandler = (String) -> ValidationResult

    /// 完成回调
    public typealias CompletionHandler = (String) -> Void

    /// 取消回调
    public typealias CancelHandler = () -> Void

    // MARK: - 属性

    /// 标题
    public var titleText: String? {
        didSet {
            titleLabel.text = titleText
        }
    }

    /// 消息
    public var message: String? {
        didSet {
            messageLabel.text = message
            messageLabel.isHidden = (message == nil)
        }
    }

    /// 密码长度
    public var passcodeLength: Int = 4 {
        didSet {
            passcodeView.passcodeLength = passcodeLength
        }
    }

    /// 是否允许取消
    public var allowsCancel: Bool = true {
        didSet {
            updateCancelButton()
        }
    }

    /// 取消按钮文本
    public var cancelTitle: String = "取消" {
        didSet {
            cancelButton.setTitle(cancelTitle, for: .normal)
        }
    }

    /// 验证回调
    public var onValidate: ValidationHandler?

    /// 完成回调
    public var onComplete: CompletionHandler?

    /// 取消回调
    public var onCancel: CancelHandler?

    // MARK: - UI 组件

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    private let passcodeView: LSPasscodeView = {
        let view = LSPasscodeView(length: 4)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let errorLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .systemRed
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - 初始化

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setupPasscodeViewController()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPasscodeViewController()
    }

    public convenience init(
        title: String? = nil,
        message: String? = nil,
        length: Int = 4
    ) {
        self.init()
        self.titleText = title
        self.message = message
        self.passcodeLength = length
    }

    // MARK: - 设置

    private func setupPasscodeViewController() {
        view.backgroundColor = .systemBackground

        view.addSubview(titleLabel)
        view.addSubview(messageLabel)
        view.addSubview(passcodeView)
        view.addSubview(errorLabel)
        view.addSubview(cancelButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            passcodeView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 40),
            passcodeView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            passcodeView.widthAnchor.constraint(equalToConstant: 200),
            passcodeView.heightAnchor.constraint(equalToConstant: 40),

            errorLabel.topAnchor.constraint(equalTo: passcodeView.bottomAnchor, constant: 16),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])

        // 配置密码视图
        passcodeView.onPasscodeComplete = { [weak self] passcode in
            self?.handlePasscodeComplete(passcode)
        }

        // 取消按钮事件
        cancelButton.ls_addAction(for: .touchUpInside) { [weak self] in
            self?.handleCancel()
        }

        updateCancelButton()
    }

    // MARK: - 处理方法

    private func handlePasscodeComplete(_ passcode: String) {
        hideError()

        if let onValidate = onValidate {
            let result = onValidate(passcode)

            switch result {
            case .success:
                onComplete?(passcode)
                dismissPasscode()

            case .failure(let message):
                let _tempVar0
                if let t = message {
                    _tempVar0 = t
                } else {
                    _tempVar0 = "密码错误"
                }
                showError(_tempVar0)
                passcodeView.clear()
                passcodeView.becomeFocus()

            case .retry(let remainingAttempts):
                showError("密码错误，还有 \(remainingAttempts) 次尝试机会")
                passcodeView.clear()
                passcodeView.becomeFocus()
            }
        } else {
            onComplete?(passcode)
            dismissPasscode()
        }
    }

    private func handleCancel() {
        onCancel?()
        dismissPasscode()
    }

    // MARK: - 错误显示

    private func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false

        // 抖动动画
        passcodeView.ls_shake()

        // 自动隐藏
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.hideError()
        }
    }

    private func hideError() {
        errorLabel.isHidden = true
    }

    private func updateCancelButton() {
        cancelButton.isHidden = !allowsCancel
    }

    // MARK: - 公共方法

    /// 显示密码输入
    public func show(in viewController: UIViewController, animated: Bool = true) {
        modalPresentationStyle = .fullScreen
        viewController.present(self, animated: animated)
        passcodeView.becomeFocus()
    }

    /// 隐藏密码输入
    public func dismissPasscode(animated: Bool = true) {
        dismiss(animated: animated)
    }

    /// 显示错误
    public func showError(_ message: String) {
        showError(message)
    }

    /// 清除密码
    public func clear() {
        passcodeView.clear()
        hideError()
    }
}

// MARK: - UIView Extension (Passcode)

public extension UIView {

    /// 添加密码输入视图
    @discardableResult
    func ls_addPasscodeView(
        length: Int = 4,
        size: CGSize = CGSize(width: 200, height: 40)
    ) -> LSPasscodeView {
        let passcodeView = LSPasscodeView(length: length)
        passcodeView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(passcodeView)

        NSLayoutConstraint.activate([
            passcodeView.centerXAnchor.constraint(equalTo: centerXAnchor),
            passcodeView.centerYAnchor.constraint(equalTo: centerYAnchor),
            passcodeView.widthAnchor.constraint(equalToConstant: size.width),
            passcodeView.heightAnchor.constraint(equalToConstant: size.height)
        ])

        return passcodeView
    }
}

// MARK: - UIViewController Extension (Passcode)

public extension UIViewController {

    /// 显示密码输入
    @discardableResult
    func ls_showPasscode(
        title: String? = nil,
        message: String? = nil,
        length: Int = 4,
        allowsCancel: Bool = true,
        validate: ((String) -> Bool)? = nil,
        onComplete: @escaping (String) -> Void,
        onCancel: (() -> Void)? = nil
    ) -> LSPasscodeViewController {
        let passcodeVC = LSPasscodeViewController(
            title: title,
            message: message,
            length: length
        )

        passcodeVC.allowsCancel = allowsCancel

        if let validate = validate {
            passcodeVC.onValidate = { passcode in
                if validate(passcode) {
                    return .success
                } else {
                    return .failure("密码错误")
                }
            }
        }

        passcodeVC.onComplete = onComplete
        passcodeVC.onCancel = onCancel

        passcodeVC.show(in: self)

        return passcodeVC
    }

    /// 显示简单的密码输入
    func ls_showSimplePasscode(
        title: String? = "请输入密码",
        length: Int = 6,
        expected: String? = nil,
        onSuccess: @escaping (String) -> Void
    ) -> LSPasscodeViewController {
        return ls_showPasscode(
            title: title,
            length: length,
            validate: expected.map { expected in
                { passcode in
                    return passcode == expected
                }
            },
            onComplete: { passcode in
                onSuccess(passcode)
            }
        )
    }
}

#endif

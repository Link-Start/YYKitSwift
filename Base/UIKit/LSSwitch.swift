//
//  LSSwitch.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  增强的开关 - 提供更多样式和动画
//

#if canImport(UIKit)
import UIKit

// MARK: - LSSwitch

/// 增强的开关
@MainActor
public class LSSwitch: UIView {

    // MARK: - 类型定义

    /// 状态变化回调
    public typealias StateChangeHandler = (Bool) -> Void

    /// 样式
    public enum SwitchStyle {
        case defaultStyle
        case iOS
        case material
        case custom
    }

    // MARK: - 属性

    /// 是否开启
    public var isOn: Bool = false {
        didSet {
            updateState()
            onStateChanged?(isOn)
        }
    }

    /// 样式
    public var style: SwitchStyle = .iOS {
        didSet {
            updateStyle()
        }
    }

    /// 关闭颜色
    public var offColor: UIColor = .systemGray4 {
        didSet {
            updateColors()
        }
    }

    /// 开启颜色
    public var onColor: UIColor = .systemGreen {
        didSet {
            updateColors()
        }
    }

    /// 滑块颜色
    public var thumbColor: UIColor = .white {
        didSet {
            thumbView.backgroundColor = thumbColor
        }
    }

    /// 是否启用
    public var isEnabled: Bool = true {
        didSet {
            isUserInteractionEnabled = isEnabled
            alpha = isEnabled ? 1.0 : 0.5
        }
    }

    /// 动画时长
    public var animationDuration: TimeInterval = 0.3

    /// 状态变化回调
    public var onStateChanged: StateChangeHandler?

    // MARK: - UI 组件

    private let trackView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let thumbView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 1)
        view.layer.shadowOpacity = 0.3
        view.layer.shadowRadius = 1
        return view
    }()

    private let onLabel: UILabel = {
        let label = UILabel()
        label.text = "ON"
        label.font = .boldSystemFont(ofSize: 10)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let offLabel: UILabel = {
        let label = UILabel()
        label.text = "OFF"
        label.font = .boldSystemFont(ofSize: 10)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - 尺寸常量

    private let trackHeight: CGFloat = 31
    private let trackWidth: CGFloat = 51
    private let thumbSize: CGFloat = 27

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSwitch()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSwitch()
    }

    public init(isOn: Bool = false) {
        self.isOn = isOn
        super.init(frame: .zero)
        setupSwitch()
    }

    // MARK: - 设置

    private func setupSwitch() {
        addSubview(trackView)
        addSubview(thumbView)
        addSubview(onLabel)
        addSubview(offLabel)

        NSLayoutConstraint.activate([
            trackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            trackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            trackView.widthAnchor.constraint(equalToConstant: trackWidth),
            trackView.heightAnchor.constraint(equalToConstant: trackHeight),

            thumbView.centerYAnchor.constraint(equalTo: centerYAnchor),
            thumbView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            thumbView.widthAnchor.constraint(equalToConstant: thumbSize),
            thumbView.heightAnchor.constraint(equalToConstant: thumbSize),

            onLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            onLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            onLabel.widthAnchor.constraint(equalToConstant: 20),
            onLabel.heightAnchor.constraint(equalToConstant: 12),

            offLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            offLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            offLabel.widthAnchor.constraint(equalToConstant: 24),
            offLabel.heightAnchor.constraint(equalToConstant: 12)
        ])

        trackView.layer.cornerRadius = trackHeight / 2
        thumbView.layer.cornerRadius = thumbSize / 2

        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        addGestureRecognizer(tapGesture)

        // 设置固定大小
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: trackWidth).isActive = true
        heightAnchor.constraint(equalToConstant: trackHeight).isActive = true

        updateStyle()
        updateState()
    }

    // MARK: - 更新

    private func updateStyle() {
        switch style {
        case .defaultStyle, .iOS:
            // iOS 样式（圆角矩形）
            trackView.layer.cornerRadius = trackHeight / 2
            thumbView.layer.cornerRadius = thumbSize / 2
            onLabel.isHidden = false
            offLabel.isHidden = false

        case .material:
            // Material Design 样式
            trackView.layer.cornerRadius = trackHeight / 2
            thumbView.layer.cornerRadius = thumbSize / 2
            thumbView.layer.shadowColor = UIColor.black.cgColor
            thumbView.layer.shadowOffset = CGSize(width: 0, height: 2)
            thumbView.layer.shadowOpacity = 0.4
            thumbView.layer.shadowRadius = 2
            onLabel.isHidden = true
            offLabel.isHidden = true

        case .custom:
            // 自定义样式
            trackView.layer.cornerRadius = trackHeight / 2
            thumbView.layer.cornerRadius = thumbSize / 2
        }
    }

    private func updateState() {
        UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseInOut) {
            if self.isOn {
                self.thumbView.transform = CGAffineTransform(translationX: self.trackWidth - self.thumbSize - 4, y: 0)
                self.trackView.backgroundColor = self.onColor
            } else {
                self.thumbView.transform = .identity
                self.trackView.backgroundColor = self.offColor
            }
        }

        onLabel.alpha = isOn ? 1.0 : 0.0
        offLabel.alpha = isOn ? 0.0 : 1.0
    }

    private func updateColors() {
        trackView.backgroundColor = isOn ? onColor : offColor
        thumbView.backgroundColor = thumbColor
    }

    // MARK: - 手势处理

    @objc private func handleTapGesture() {
        guard isEnabled else { return }
        isOn.toggle()
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        guard isEnabled else { return }

        UIView.animate(withDuration: 0.1) {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        UIView.animate(withDuration: 0.1) {
            self.transform = .identity
        }

        guard isEnabled else { return }
        isOn.toggle()
    }

    // MARK: - 公共方法

    /// 设置开关状态
    public func setOn(_ on: Bool, animated: Bool = true) {
        guard animated else {
            isOn = on
            return
        }

        UIView.animate(withDuration: animationDuration) {
            self.isOn = on
        }
    }
}

// MARK: - UISwitch Extension

public extension UISwitch {

    /// 设置开启颜色
    func ls_setOnColor(_ color: UIColor) {
        if #available(iOS 14.0, *) {
            onTintColor = color
        } else {
            onTintColor = color
        }
    }

    /// 设置关闭颜色
    func ls_setOffColor(_ color: UIColor) {
        if #available(iOS 14.0, *) {
            tintColor = color
        } else {
            tintColor = color
        }
    }

    /// 设置滑块颜色
    func ls_setThumbColor(_ color: UIColor) {
        thumbTintColor = color
    }

    /// 设置样式
    func ls_applyStyle(
        onColor: UIColor = .systemGreen,
        offColor: UIColor = .systemGray4,
        thumbColor: UIColor = .white
    ) {
        self.onTintColor = onColor
        self.tintColor = offColor
        self.thumbTintColor = thumbColor
    }

    /// 添加左侧标签
    func ls_setLabel(_ text: String, at position: LabelPosition = .left) {
        // 需要在父视图中添加 UILabel
    }

    /// 标签位置
    enum LabelPosition {
        case left
        case right
    }

    /// 是否开启（绑定）
    var ls_isOn: Bool {
        get { return isOn }
        set { isOn = newValue }
    }

    /// 切换状态
    func ls_toggle() {
        isOn.toggle()
    }

    /// 添加状态变化监听
    func ls_onStateChanged(_ handler: @escaping (Bool) -> Void) {
        let key = AssociatedKey.stateChangeHandlerKey
        objc_setAssociatedObject(self, key, handler, .OBJC_ASSOCIATION_COPY_NONATOMIC)

        addTarget(self, action: #selector(handleStateChanged), for: .valueChanged)
    }

    @objc private func handleStateChanged() {
        let key = AssociatedKey.stateChangeHandlerKey
        let handler = objc_getAssociatedObject(self, key) as? ((Bool) -> Void)
        handler?(isOn)
    }
}

// MARK: - Toggle Button

/// 切换按钮（开关样式）
public class LSToggleButton: UIButton {

    /// 状态变化回调
    public typealias StateChangeHandler = (Bool) -> Void

    /// 是否开启
    public private(set) var isOn: Bool = false {
        didSet {
            updateState()
            onStateChanged?(isOn)
        }
    }

    /// 开启图片
    public var onImage: UIImage? {
        didSet {
            updateImage()
        }
    }

    /// 关闭图片
    public var offImage: UIImage? {
        didSet {
            updateImage()
        }
    }

    /// 状态变化回调
    public var onStateChanged: StateChangeHandler?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupToggleButton()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupToggleButton()
    }

    private func setupToggleButton() {
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        updateState()
    }

    private func updateState() {
        updateImage()
    }

    private func updateImage() {
        if isOn {
            setImage(onImage, for: .normal)
        } else {
            setImage(offImage, for: .normal)
        }
    }

    @objc private func handleTap() {
        isOn.toggle()
    }

    /// 设置开关状态
    public func setOn(_ on: Bool, animated: Bool = true) {
        guard animated else {
            isOn = on
            return
        }

        UIView.animate(withDuration: 0.2) {
            self.isOn = on
        }
    }
}

// MARK: - Checkbox View

/// 复选框视图
public class LSCheckboxView: UIView {

    /// 状态变化回调
    public typealias StateChangeHandler = (Bool) -> Void

    /// 是否选中
    public private(set) var isChecked: Bool = false {
        didSet {
            updateState()
            onStateChanged?(isChecked)
        }
    }

    /// 选中颜色
    public var checkColor: UIColor = .systemBlue {
        didSet {
            updateColors()
        }
    }

    /// 边框颜色
    public var borderColor: UIColor = .systemGray4 {
        didSet {
            updateColors()
        }
    }

    /// 复选框大小
    public var checkboxSize: CGFloat = 24 {
        didSet {
            updateConstraints()
        }
    }

    /// 标题
    public var title: String? {
        didSet {
            titleLabel.text = title
        }
    }

    /// 标题颜色
    public var titleColor: UIColor = .label {
        didSet {
            titleLabel.textColor = titleColor
        }
    }

    /// 状态变化回调
    public var onStateChanged: StateChangeHandler?

    // MARK: - UI 组件

    private let checkboxView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.borderWidth = 2
        return view
    }()

    private let checkmarkView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupCheckbox()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCheckbox()
    }

    public init(title: String = "", isChecked: Bool = false) {
        self.title = title
        self.isChecked = isChecked
        super.init(frame: .zero)
        setupCheckbox()
    }

    // MARK: - 设置

    private func setupCheckbox() {
        addSubview(checkboxView)
        checkboxView.addSubview(checkmarkView)
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            checkboxView.leadingAnchor.constraint(equalTo: leadingAnchor),
            checkboxView.centerYAnchor.constraint(equalTo: centerYAnchor),
            checkboxView.widthAnchor.constraint(equalToConstant: checkboxSize),
            checkboxView.heightAnchor.constraint(equalToConstant: checkboxSize),

            checkmarkView.centerXAnchor.constraint(equalTo: checkboxView.centerXAnchor),
            checkmarkView.centerYAnchor.constraint(equalTo: checkboxView.centerYAnchor),
            checkmarkView.widthAnchor.constraint(equalToConstant: checkboxSize * 0.6),
            checkmarkView.heightAnchor.constraint(equalToConstant: checkboxSize * 0.6),

            titleLabel.leadingAnchor.constraint(equalTo: checkboxView.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        checkboxView.layer.cornerRadius = 4

        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)

        updateState()
        updateColors()
    }

    // MARK: - 更新

    private func updateState() {
        checkmarkView.isHidden = !isChecked
        checkboxView.layer.borderColor = isChecked ? checkColor.cgColor : borderColor.cgColor
        checkboxView.backgroundColor = isChecked ? checkColor.withAlphaComponent(0.1) : .clear
    }

    private func updateColors() {
        checkboxView.layer.borderColor = isChecked ? checkColor.cgColor : borderColor.cgColor

        if let image = UIImage(systemName: "checkmark") {
            checkmarkView.image = image.withTintColor(checkColor, renderingMode: .alwaysOriginal)
        }
    }

    private func updateConstraints() {
        checkboxView.constraints.forEach { constraint in
            if constraint.firstAttribute == .width || constraint.firstAttribute == .height {
                constraint.constant = checkboxSize
            }
        }
    }

    // MARK: - 手势处理

    @objc private func handleTap() {
        isChecked.toggle()
    }

    // MARK: - 公共方法

    /// 设置选中状态
    public func setChecked(_ checked: Bool, animated: Bool = true) {
        guard animated else {
            isChecked = checked
            return
        }

        UIView.animate(withDuration: 0.2) {
            self.isChecked = checked
        }
    }
}

// MARK: - Associated Keys

private struct AssociatedKey {
    static var stateChangeHandlerKey: UInt8 = 0
}

#endif

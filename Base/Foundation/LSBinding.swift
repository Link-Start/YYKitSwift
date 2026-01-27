//
//  LSBinding.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  数据绑定工具 - 简单的数据绑定实现
//

#if canImport( UIKit)
import UIKit

// MARK: - Observable

/// 可观察的值
public class Observable<T> {

    /// 值变化回调
    public typealias Observer = (T) -> Void

    /// 观察者列表
    private var observers: [Observer] = []

    /// 当前值
    private var _value: T

    /// 当前值
    public var value: T {
        get {
            return _value
        }
        set {
            _value = newValue
            notifyObservers()
        }
    }

    // MARK: - 初始化

    public init(_ value: T) {
        self._value = value
    }

    // MARK: - 观察者

    /// 添加观察者
    ///
    /// - Parameter observer: 观察者闭包
    /// - Returns: 观察者令牌（用于移除）
    @discardableResult
    public func bind(_ observer: @escaping Observer) -> ObservationToken {
        observers.append(observer)
        return ObservationToken { [weak self] in
            self?.observers.removeAll { $0 === observer }
        }
    }

    /// 绑定到 UILabel
    ///
    /// - Parameter label: 标签
    /// - Returns: 观察者令牌
    @discardableResult
    public func bind(to label: UILabel) -> ObservationToken {
        return bind { [weak label] in
            label?.text = "\($0)"
        }
    }

    /// 绑定到 UITextField
    ///
    /// - Parameter textField: 文本框
    /// - Returns: 观察者令牌
    @discardableResult
    public func bind(to textField: UITextField) -> ObservationToken {
        return bind { [weak textField] in
            textField.text = "\($0)"
        }
    }

    /// 绑定到 UITextView
    ///
    /// - Parameter textView: 文本视图
    /// - Returns: 观察者令牌
    @discardableResult
    public func bind(to textView: UITextView) -> ObservationToken {
        return bind { [weak textView] in
            textView.text = "\($0)"
        }
    }

    /// 绑定到 UIButton（标题）
    ///
    /// - Parameter button: 按钮
    /// - Returns: 观察者令牌
    @discardableResult
    public func bind(to button: UIButton) -> ObservationToken {
        return bind { [weak button] in
            button.setTitle("\($0)", for: .normal)
        }
    }

    /// 绑定到 UIImageView（隐藏/显示）
    ///
    /// - Parameter imageView: 图片视图
    /// - Returns: 观察者令牌
    @discardableResult
    public func bindVisibility(to imageView: UIImageView) -> ObservationToken {
        return bind { [weak imageView] in
            if let boolValue = $0 as? Bool {
                imageView.isHidden = !boolValue
            }
        }
    }

    /// 绑定到 UIView（alpha）
    ///
    /// - Parameter view: 视图
    /// - Returns: 观察者令牌
    @discardableResult
    public func bindAlpha(to view: UIView) -> ObservationToken {
        return bind { [weak view] in
            if let floatValue = $0 as? CGFloat {
                view.alpha = floatValue
            }
        }
    }

    /// 映射值后绑定
    ///
    /// - Parameters:
    ///   - keyPath: 映射闭包
    ///   - observer: 观察者闭包
    /// - Returns: 观察者令牌
    @discardableResult
    public func map<U>(_ keyPath: @escaping (T) -> U, observer: @escaping (U) -> Void) -> ObservationToken {
        let token = bind { value in
            let mapped = keyPath(value)
            observer(mapped)
        }
        return token
    }

    // MARK: - 私有方法

    private func notifyObservers() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            for observer in self.observers {
                observer(self._value)
            }
        }
    }
}

// MARK: - ObservationToken

/// 观察者令牌
public class ObservationToken {

    /// 取消退包
    private let cancellationClosure: () -> Void

    /// 是否已取消
    private(set) var isCancelled: Bool = false

    /// 初始化
    ///
    /// - Parameter cancellationClosure: 取消退包
    init(cancellationClosure: @escaping () -> Void) {
        self.cancellationClosure = cancellationClosure
    }

    /// 取消观察
    public func cancel() {
        cancellationClosure()
        isCancelled = true
    }
}

// MARK: - LS双向绑定

/// 双向绑定工具
public enum LSBidirectionalBinding {

    /// 绑定两个可观察值
    ///
    /// - Parameters:
    ///   - first: 第一个值
    ///   - second: 第二个值
    /// - Returns: 观察者令牌数组
    @discardableResult
    public static func bind<T>(_ first: Observable<T>, _ second: Observable<T>) -> [ObservationToken] {
        let token1 = first.bind { [weak second] in
            second?.value = $0
        }

        let token2 = second.bind { [weak first] in
            first?.value = $0
        }

        // 初始化第二个值为第一个值
        second.value = first.value

        return [token1, token2]
    }

    /// 绑定文本框和可观察值
    ///
    /// - Parameters:
    ///   - textField: 文本框
    ///   - observable: 可观察值
    /// - Returns: 观察者令牌
    @discardableResult
    public static func bind(_ textField: UITextField, to observable: Observable<String>) -> ObservationToken {
        // 文本框 -> 可观察值
        textField.addAction(UIAction.actionChanged, target: textField, for: .editingChanged)

        let token = observable.bind { [weak textField] in
            textField?.text = $0
        }

        // 通知事件
        NotificationCenter.default.addObserver(
            forName: UITextField.textDidChangeNotification,
            object: textField,
            queue: .main
        ) { [weak textField] _ in
            if let text = textField?.text {
                observable.value = text
            }
        }

        return token
    }

    /// 绑定开关和可观察值
    ///
    /// - Parameters:
    ///   - switch: 开关
    ///   - observable: 可观察值
    /// - Returns: 观察者令牌
    @discardableResult
    public static func bind(_ toggle: UISwitch, to observable: Observable<Bool>) -> ObservationToken {
        // 开关 -> 可观察值
        let token1 = toggle.bind { [weak toggle] in
            observable.value = $0.isOn
        }

        // 可观察值 -> 开关
        let token2 = observable.bind { [weak toggle] in
            toggle?.setOn($0, animated: true)
        }

        // 初始化
        toggle.isOn = observable.value

        return [token1, token2]
    }

    /// 绑定滑块和可观察值
    ///
    /// - Parameters:
    ///   - slider: 滑块
    ///   - observable: 可观察值
    /// - Returns: 观察者令牌
    @discardableResult
    public static func bind(_ slider: UISlider, to observable: Observable<Double>) -> ObservationToken {
        // 滑块 -> 可观察值
        let token1 = slider.bind { [weak slider] in
            observable.value = Double($0.value)
        }

        // 可观察值 -> 滑块
        let token2 = observable.bind { [weak slider] in
            slider?.setValue(Float($0), animated: true)
        }

        // 初始化
        slider.value = Float(observable.value)

        return [token1, token2]
    }

    /// 绑定分段控件和可观察值
    ///
    /// - Parameters:
    ///   - segmentedControl: 分段控件
    ///   - observable: 可观察值
    /// - Returns: 观察者令牌
    @discardableResult
    public static func bind(_ segmentedControl: UISegmentedControl, to observable: Observable<Int>) -> ObservationToken {
        // 分段控件 -> 可观察值
        let token1 = segmentedControl.bind { [weak segmentedControl] in
            if let index = $0.selectedSegmentIndex {
                observable.value = index
            }
        }

        // 可观察值 -> 分段控件
        let token2 = observable.bind { [weak segmentedControl] in
            segmentedControl?.selectedSegmentIndex = $0
        }

        // 初始化
        segmentedControl.selectedSegmentIndex = observable.value

        return [token1, token2]
    }
}

// MARK: - LSViewModel

/// 视图模型基类
public class LSViewModel {

    /// 属性变化通知
    public let didChange = Notification.Name(rawValue: "LSViewModelDidChange")

    /// 通知中心
    private let notificationCenter = NotificationCenter()

    /// 属性值存储
    private var values: [String: Any] = [:]

    /// 获取属性值
    ///
    /// - Parameter key: 属性键
    /// - Returns: 属性值
    public func value<T>(forKey key: String) -> T? {
        return values[key] as? T
    }

    /// 设置属性值
    ///
    /// - Parameters:
    ///   - value: 属性值
    ///   - key: 属性键
    public func setValue<T>(_ value: T, forKey key: String) {
        values[key] = value
        notificationCenter.post(name: didChange, object: self, userInfo: [key: key])
    }

    /// 订阅属性变化
    ///
    /// - Parameters:
    ///   - key: 属性键
    ///   - observer: 观察者闭包
    /// - Returns: 观察者令牌
    @discardResultResult
    public func observe<T>(forKey key: String, observer: @escaping (T?) -> Void) -> ObservationToken {
        let observerWrapper = NotificationCenter.default.addObserver(
            forName: didChange,
            object: self,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let key = notification.userInfo?[key] as? String else {
                observer(nil)
                return
            }
            let value = self.value(for: key)
            observer(value as? T)
        }

        return ObservationToken {
            NotificationCenter.default.removeObserver(observerWrapper)
        }
    }
}

// MARK: - UIControl Extension (绑定)

public extension UIControl {

    /// 添加动作
    ///
    /// - Parameters:
    ///   - controlEvents: 控制事件
    ///   - action: 动作闭包
    /// - Returns: 目标-动作包装器（用于移除）
    @discardableResult
    func ls_addAction(
        for controlEvents: UIControl.Event,
        action: @escaping () -> Void
    ) -> NSObject? {
        let target = TargetActionWrapper(action: action)
        addTarget(target, action: #selector(targetActionTriggered), for: controlEvents)
        return target
    }

    /// 移除动作
    ///
    /// - Parameter wrapper: 目标-动作包装器
    func ls_removeAction(_ wrapper: NSObject?) {
        guard let wrapper = wrapper else { return }
        removeTarget(wrapper, action: nil, for: .allEvents)
    }
}

// MARK: - TargetActionWrapper

private class TargetActionWrapper: NSObject {

    let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
        super.init()
    }

    @objc func targetActionTriggered() {
        action()
    }
}

// MARK: - LSFormBinder

/// 表单绑定工具
public class LSFormBinder {

    // MARK: - 类型定义

    /// 字段绑定
    public struct FieldBinding {
        let key: String
        let view: UIView
        let extractValue: () -> Any?
        let updateValue: (Any) -> Void
    }

    // MARK: - 属性

    /// 字段绑定列表
    private var bindings: [FieldBinding] = []

    /// 视图模型
    public weak var viewModel: LSViewModel?

    // MARK: - 添加绑定

    /// 添加文本框绑定
    ///
    /// - Parameters:
    ///   - textField: 文本框
    ///   - key: 键
    /// - Returns: self
    @discardableResult
    public func bind(_ textField: UITextField, to key: String) -> Self {
        let binding = FieldBinding(
            key: key,
            view: textField
        ) {
            [weak textField] in
            textField?.text ?? ""
        } updateValue: { [weak textField] value in
            if let stringValue = value as? String {
                textField?.text = stringValue
            }
        }

        bindings.append(binding)

        // 监听文本变化
        textField.addTarget(
            self,
            action: #selector(textFieldDidChange(_:)),
            for: .editingChanged
        )

        return self
    }

    @objc private func textFieldDidChange(_ textField: UITextField) {
        guard let binding = bindings.first(where: { $0.view === textField }) else { return }
        viewModel?.setValue(textField.text ?? "", forKey: binding.key)
    }

    /// 添加开关绑定
    ///
    /// - Parameters:
    ///   - toggle: 开关
    ///   - key: 键
    /// - Returns: self
    @discardableResult
    public func bind(_ toggle: UISwitch, to key: String) -> Self {
        let binding = FieldBinding(
            key: key,
            view: toggle
        ) {
            [weak toggle] in
            toggle?.isOn
        } updateValue: { [weak toggle] value in
            if let boolValue = value as? Bool {
                toggle?.setOn(boolValue, animated: true)
            }
        }

        bindings.append(binding)

        toggle.addTarget(
            self,
            action: #selector(switchValueChanged(_:)),
            for: .valueChanged
        )

        return self
    }

    @objc private func switchValueChanged(_ toggle: UISwitch) {
        guard let binding = bindings.first(where: { $0.view === toggle }) else { return }
        viewModel?.setValue(toggle.isOn, forKey: binding.key)
    }

    /// 添加滑块绑定
    ///
    /// - Parameters:
    ///   - slider: 滑块
    ///   - key: 键
    /// - Returns: self
    @discardableResult
    public func bind(_ slider: UISlider, to key: String) -> Self {
        let binding = FieldBinding(
            key: key,
            view: slider
        ) {
            [weak slider] in
            Double(slider.value)
        } updateValue: { [weak slider] value in
            if let doubleValue = value as? Double {
                slider?.setValue(Float(doubleValue), animated: true)
            }
        }

        bindings.append(binding)

        slider.addTarget(
            self,
            action: #selector(sliderValueChanged(_:)),
            for: .valueChanged
        )

        return self
    }

    @objc private func sliderValueChanged(_ slider: UISlider) {
        guard let binding = bindings.first(where: { $0.view === slider }) else { return }
        viewModel?.setValue(Double(slider.value), forKey: binding.key)
    }

    /// 添加分段控件绑定
    ///
    /// - Parameters:
    ///   - segmentedControl: 分段控件
    ///   - key: 键
    /// - Returns: self
    @discardableResult
    public func bind(_ segmentedControl: UISegmentedControl, to key: String) -> Self {
        let binding = FieldBinding(
            key: key,
            view: segmentedControl
        ) {
            [weak segmentedControl] in
            segmentedControl.selectedSegmentIndex
        } updateValue: { [weak segmentedControl] value in
            if let intValue = value as? Int {
                segmentedControl?.selectedSegmentIndex = intValue
            }
        }

        bindings.append(binding)

        segmentedControl.addTarget(
            self,
            action: #selector(segmentedControlValueChanged(_:)),
            for: .valueChanged
        )

        return self
    }

    @objc private func segmentedControlValueChanged(_ segmentedControl: UISegmentedControl) {
        guard let binding = bindings.first(where: { $0.view === segmentedControl }) else { return }
        viewModel?.setValue(segmentedControl.selectedSegmentIndex, forKey: binding.key)
    }

    /// 移除所有绑定
    public func removeAllBindings() {
        for binding in bindings {
            if let textField = binding.view as? UITextField {
                textField.removeTarget(self, action: nil, for: .editingChanged)
            } else if let toggle = binding.view as? UISwitch {
                toggle.removeTarget(self, action: nil, for: .valueChanged)
            } else if let slider = binding.view as? UISlider {
                slider.removeTarget(self, action: nil, for: .valueChanged)
            } else if let segmentedControl = binding.view as? UISegmentedControl {
                segmentedControl.removeTarget(self, action: nil, for: .valueChanged)
            }
        }
        bindings.removeAll()
    }

    /// 同步值到视图模型
    public func syncToViewModel() {
        for binding in bindings {
            if let value = viewModel?.value(forKey: binding.key) {
                binding.updateValue(value)
            }
        }
    }

    /// 从视图模型同步值
    public func syncFromViewModel() {
        for binding in bindings {
            if let value = binding.extractValue() {
                viewModel?.setValue(value, forKey: binding.key)
            }
        }
    }
}

// MARK: - UIBarButtonItem Extension (绑定)

public extension UIBarButtonItem {

    /// 添加动作
    ///
    /// - Parameter action: 动作闭包
    /// - Returns: 包装的目标对象
    @discardableResult
    func ls_setAction(_ action: @escaping () -> Void) -> NSObject? {
        let wrapper = TargetActionWrapper(action: action)
        target = wrapper
        action = #selector(wrapper.targetActionTriggered)
        return wrapper
    }
}

// MARK: - UITapGestureRecognizer Extension (绑定)

public extension UITapGestureRecognizer {

    /// 添加动作
    ///
    /// - Parameter action: 动作闭包
    /// - Returns: 包装器对象
    @discardableResult
    func ls_setAction(_ action: @escaping () -> Void) -> TargetActionWrapper {
        let wrapper = TargetActionWrapper(action: action)
        addTarget(wrapper, action: #selector(wrapper.targetActionTriggered), for: .recognized)
        return wrapper
    }
}

// MARK: - UITapGestureRecognizer Extension (绑定)

public extension UIView {

    /// 添加点击手势
    ///
    /// - Parameters:
    ///   - tapCount: 点击次数
    ///   - action: 动作闭包
    /// - Returns: 手势识别器
    @discardableResult
    func ls_addTapGesture(
        tapCount: Int = 1,
        action: @escaping () -> Void
    ) -> UITapGestureRecognizer {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        gesture.numberOfTapsRequired = tapCount
        addGestureRecognizer(gesture)

        // 存储动作
        let wrapper = TargetActionWrapper(action: action)
        objc_setAssociatedObject(gesture, &AssociatedKeys.gestureAction, wrapper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        return gesture
    }

    @objc private func handleGesture(_ gesture: UIGestureRecognizer) {
        if let wrapper = objc_getAssociatedObject(gesture, &AssociatedKeys.gestureAction) as? TargetActionWrapper {
            wrapper.action()
        }
    }
}

// MARK: - Associated Keys

private enum AssociatedKeys {
    static var gestureAction = "gestureAction"
    static var emptyAction = "emptyAction"
}

#endif

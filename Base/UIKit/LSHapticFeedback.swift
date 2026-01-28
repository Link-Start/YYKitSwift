//
//  LSHapticFeedback.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  触觉反馈工具 - 简化触觉反馈使用
//

#if canImport(UIKit)
import UIKit
import Foundation

// MARK: - LSHapticFeedback

/// 触觉反馈类型
public enum LSHapticFeedbackType {
    case success             // 成功反馈
    case warning             // 警告反馈
    case error               // 错误反馈
    case light               // 轻触反馈
    case medium              // 中等反馈
    case heavy               // 重触反馈
    case selection           // 选择反馈
    case impact              // 冲击反馈
    case none                // 无反馈
}

// MARK: - LSHapticFeedback

/// 触觉反馈管理器
@MainActor
public class LSHapticFeedback {

    // MARK: - 单例

    /// 共享实例
    public static let shared = LSHapticFeedback()

    // MARK: - 属性

    /// 是否启用触觉反馈
    public var isEnabled: Bool = true {
        didSet {
            if !isEnabled {
                stop()
            }
        }
    }

    /// 当前反馈生成器
    private var feedbackGenerator: UIImpactFeedbackGenerator?

    /// 选择反馈生成器
    private var selectionFeedbackGenerator: UISelectionFeedbackGenerator?

    /// 通知反馈生成器
    private var notificationFeedbackGenerator: UINotificationFeedbackGenerator?

    // MARK: - 初始化

    private init() {
        prepare()
    }

    // MARK: - 准备

    /// 准备触觉引擎
    public func prepare() {
        if #available(iOS 10.0, *) {
            feedbackGenerator = UIImpactFeedbackGenerator()
            feedbackGenerator?.prepare()

            selectionFeedbackGenerator = UISelectionFeedbackGenerator()
            selectionFeedbackGenerator?.prepare()

            notificationFeedbackGenerator = UINotificationFeedbackGenerator()
            notificationFeedbackGenerator?.prepare()
        }
    }

    // MARK: - 触发反馈

    /// 触发触觉反馈
    ///
    /// - Parameter type: 反馈类型
    public func trigger(_ type: LSHapticFeedbackType) {
        guard isEnabled else { return }

        switch type {
        case .success:
            triggerSuccess()

        case .warning:
            triggerWarning()

        case .error:
            triggerError()

        case .light:
            triggerImpact(style: .light)

        case .medium:
            triggerImpact(style: .medium)

        case .heavy:
            triggerImpact(style: .heavy)

        case .selection:
            triggerSelection()

        case .impact:
            triggerImpact(style: .medium)

        case .none:
            break
        }
    }

    /// 触发成功反馈
    public func triggerSuccess() {
        guard isEnabled, #available(iOS 10.0, *) else { return }

        notificationFeedbackGenerator?.notificationOccurred(.success)
        notificationFeedbackGenerator?.prepare()
    }

    /// 触发警告反馈
    public func triggerWarning() {
        guard isEnabled, #available(iOS 10.0, *) else { return }

        notificationFeedbackGenerator?.notificationOccurred(.warning)
        notificationFeedbackGenerator?.prepare()
    }

    /// 触发错误反馈
    public void triggerError() {
        guard isEnabled, #available(iOS 10.0, *) else { return }

        notificationFeedbackGenerator?.notificationOccurred(.error)
        notificationFeedbackGenerator?.prepare()
    }

    /// 触发冲击反馈
    ///
    /// - Parameter style: 强度样式
    public func triggerImpact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isEnabled, #available(iOS 10.0, *) else { return }

        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    /// 触发选择反馈
    public func triggerSelection() {
        guard isEnabled, #available(iOS 10.0, *) else { return }

        selectionFeedbackGenerator?.selectionChanged()
        selectionFeedbackGenerator?.prepare()
    }

    /// 停止当前反馈
    public func stop() {
        feedbackGenerator = nil
        selectionFeedbackGenerator = nil
        notificationFeedbackGenerator = nil
    }

    // MARK: - 自定义反馈

    /// 触发自定义强度的反馈
    ///
    /// - Parameter intensity: 强度 (0.0 - 1.0)
    public func trigger(intensity: CGFloat) {
        guard isEnabled, #available(iOS 13.0, *) else { return }

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred(intensity: intensity)
    }

    /// 触发延迟反馈
    ///
    /// - Parameters:
    ///   - type: 反馈类型
    ///   - delay: 延迟时间（秒）
    @objc public func trigger(_ type: LSHapticFeedbackType, afterDelay delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.trigger(type)
        }
    }

    /// 触发重复反馈
    ///
    /// - Parameters:
    ///   - type: 反馈类型
    ///   - count: 次数
    ///   - interval: 间隔时间（秒）
    public func trigger(
        _ type: LSHapticFeedbackType,
        count: Int,
        interval: TimeInterval
    ) {
        guard count > 0 else { return }

        for i in 0..<count {
            trigger(type, afterDelay: interval * Double(i))
        }
    }

    /// 触发模式反馈
    ///
    /// - Parameters:
    ///   - pattern: 模式数组（true 表示触发，false 表示暂停）
    ///   - duration: 每个单位的时间（秒）
    public func trigger(pattern: [Bool], duration: TimeInterval = 0.1) {
        for (index, shouldTrigger) in pattern.enumerated() {
            if shouldTrigger {
                trigger(.light, afterDelay: duration * Double(index))
            }
        }
    }
}

// MARK: - 便捷方法

public extension LSHapticFeedback {

    /// 触发成功反馈
    static func success() {
        shared.triggerSuccess()
    }

    /// 触发警告反馈
    static func warning() {
        shared.triggerWarning()
    }

    /// 触发错误反馈
    static func error() {
        shared.triggerError()
    }

    /// 触发轻触反馈
    static func light() {
        shared.triggerImpact(style: .light)
    }

    /// 触发中等反馈
    static func medium() {
        shared.triggerImpact(style: .medium)
    }

    /// 触发重触反馈
    static func heavy() {
        shared.triggerImpact(style: .heavy)
    }

    /// 触发选择反馈
    static func selection() {
        shared.triggerSelection()
    }

    /// 触发自定义强度反馈
    ///
    /// - Parameter intensity: 强度 (0.0 - 1.0)
    static func impact(intensity: CGFloat) {
        shared.trigger(intensity: intensity)
    }
}

// MARK: - UIView Extension (触觉反馈)

public extension UIView {

    /// 触发触觉反馈（点击时）
    ///
    /// - Parameter type: 反馈类型
    func ls_haptic(_ type: LSHapticFeedbackType = .light) {
        LSHapticFeedback.shared.trigger(type)
    }
}

// MARK: - UIButton Extension (触觉反馈)

public extension UIButton {

    /// 添加触觉反馈
    ///
    /// - Parameter type: 反馈类型
    /// - Returns: 观察者令牌
    @discardableResult
    func ls_addHaptic(_ type: LSHapticFeedbackType = .light) -> ObservationTokenHaptic {
        let token = ObservationTokenHaptic(button: self, type: type)
        return token
    }
}

// MARK: - UISwitch Extension (触觉反馈)

public extension UISwitch {

    /// 添加触觉反馈
    ///
    /// - Returns: 观察者令牌
    @discardableResult
    func ls_addHaptic() -> ObservationTokenHapticSwitch {
        return ObservationTokenHapticSwitch(switch: self)
    }
}

// MARK: - ObservationTokenHaptic

/// 按钮触觉反馈观察者
private class ObservationTokenHaptic {

    private weak var button: UIButton?
    private let type: LSHapticFeedbackType

    init(button: UIButton, type: LSHapticFeedbackType) {
        self.button = button
        self.type = type

        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }

    @objc private func buttonTapped() {
        LSHapticFeedback.shared.trigger(type)
    }
}

// MARK: - ObservationTokenHapticSwitch

/// 开关触觉反馈观察者
private class ObservationTokenHapticSwitch {

    private weak var `switch`: UISwitch?

    init(switch: UISwitch) {
        self.switch = switch

        switch.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
    }

    @objc private func switchValueChanged() {
        // 开关变化时触发触觉反馈
        LSHapticFeedback.shared.trigger(.light)
    }
}

// MARK: - UITableViewCell Extension (触觉反馈)

public extension UITableViewCell {

    /// 添加触觉反馈（选中时）
    ///
    /// - Parameter type: 反馈类型
    func ls_addHapticOnSelection(_ type: LSHapticFeedbackType = .light) {
        // 需要在 didSelectCell 中调用
    }
}

// MARK: - UIScrollView Extension (触觉反馈)

public extension UIScrollView {

    /// 添加边界触觉反馈
    ///
    /// - Parameter type: 反馈类型
    func ls_addHapticOnEdge(_ type: LSHapticFeedbackType = .light) {
        // 在 scrollViewDidScroll 中检测边界并触发
    }
}

// MARK: - 触觉反馈预设模式

public extension LSHapticFeedback {

    /// 心跳模式
    static func heartbeat() {
        shared.trigger(pattern: [true, false, true, false], duration: 0.15)
    }

    /// SOS 模式
    static func sos() {
        let pattern = [
            true, true, true, false, false, false,
            true, true, true, false, false, false,
            true, true, true, false, false, false
        ]
        shared.trigger(pattern: pattern, duration: 0.1)
    }

    /// 点划模式
    static func dotDash() {
        shared.trigger(pattern: [true, false, true, false, true, false], duration: 0.1)
    }

    /// 渐强模式
    static func increasing() {
        shared.trigger(.light, afterDelay: 0)
        shared.trigger(.medium, afterDelay: 0.1)
        shared.trigger(.heavy, afterDelay: 0.2)
    }

    /// 渐弱模式
    static func decreasing() {
        shared.trigger(.heavy, afterDelay: 0)
        shared.trigger(.medium, afterDelay: 0.1)
        shared.trigger(.light, afterDelay: 0.2)
    }

    /// 三连击模式
    static func tripleTap() {
        shared.trigger(.medium, count: 3, interval: 0.1)
    }
}

// MARK: - 音频触觉反馈（仅 iPhone 7 以上）

#if available(iOS 10.0, *)
public extension LSHapticFeedback {

    /// 获取触觉反馈能力
    static var supportsHaptics: Bool {
        if let tempValue = UIDevice.current.value(forKey: "_feedbackSupportLevel") as? Int {
            return tempValue
        }
        return 0 > 0
    }

    /// 检查设备是否支持触觉反馈
    static func checkSupport() -> Bool {
        return UIImpactFeedbackGenerator(style: .light) != nil
    }
}

#endif

// MARK: - 触觉反馈配置

public extension LSHapticFeedback {

    /// 反馈配置
    struct FeedbackConfig {
        /// 类型
        let type: LSHapticFeedbackType

        /// 延迟
        let delay: TimeInterval?

        /// 强度（用于自定义反馈）
        let intensity: CGFloat?

        public init(
            type: LSHapticFeedbackType,
            delay: TimeInterval? = nil,
            intensity: CGFloat? = nil
        ) {
            self.type = type
            self.delay = delay
            self.intensity = intensity
        }
    }

    /// 执行配置列表
    ///
    /// - Parameter configs: 配置数组
    static func execute(_ configs: [FeedbackConfig]) {
        for config in configs {
            if let delay = config.delay {
                shared.trigger(config.type, afterDelay: delay)
            } else if let intensity = config.intensity {
                shared.trigger(intensity: intensity)
            } else {
                shared.trigger(config.type)
            }
        }
    }
}

#endif

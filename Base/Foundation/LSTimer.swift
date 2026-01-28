//
//  LSTimer.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  定时器工具 - 精确定时器、倒计时、验证码倒计时
//

#if canImport(UIKit)
import UIKit
import Foundation

// MARK: - LSTimer

/// 精确定时器
public class LSTimer: NSObject {

    // MARK: - 类型定义

    /// 定时器回调
    public typealias Handler = (LSTimer) -> Void

    /// 定时器状态
    public enum State {
        case suspended      // 暂停
        case resumed        // 运行中
    }

    // MARK: - 属性

    /// 时间间隔
    public private(set) var timeInterval: TimeInterval

    /// 回调
    private let handler: Handler

    /// 是否重复
    public private(set) var repeats: Bool

    /// 定时器状态
    public private(set) var state: State = .suspended

    /// DispatchSourceTimer
    private lazy var timer: DispatchSourceTimer = {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            self.handler(self)
        }
        return timer
    }()

    /// 串行队列
    private let queue: DispatchQueue

    /// 开始时间（用于计算 elapsed）
    private var startDate: Date?

    /// 暂停时的时间
    private var pausedTime: TimeInterval = 0

    // MARK: - 初始化

    /// 创建定时器
    ///
    /// - Parameters:
    ///   - timeInterval: 时间间隔
    ///   - repeats: 是否重复
    ///   - queue: 队列
    ///   - handler: 回调
    public init(
        timeInterval: TimeInterval,
        repeats: Bool = false,
        queue: DispatchQueue = .main,
        handler: @escaping Handler
    ) {
        self.timeInterval = timeInterval
        self.repeats = repeats
        self.queue = queue
        self.handler = handler
        super.init()
    }

    deinit {
        timer.setEventHandler(handler: nil)
        timer.cancel()
    }

    // MARK: - 控制

    /// 启动定时器
    @discardableResult
    public func resume() -> LSTimer {
        guard state == .suspended else { return self }

        state = .resumed
        startDate = Date()

        if repeats {
            timer.schedule(deadline: .now() + timeInterval, repeating: timeInterval)
        } else {
            timer.schedule(deadline: .now() + timeInterval)
        }

        timer.resume()
        return self
    }

    /// 暂停定时器
    @discardableResult
    public func suspend() -> LSTimer {
        guard state == .resumed else { return self }

        state = .suspended
        pausedTime += elapsed
        timer.suspend()
        return self
    }

    /// 停止并重置定时器
    @discardableResult
    public func invalidate() -> LSTimer {
        state = .suspended
        pausedTime = 0
        startDate = nil
        timer.suspend()
        return self
    }

    /// 重置定时器
    @discardableResult
    public func reset() -> LSTimer {
        invalidate()
        resume()
        return self
    }

    // MARK: - 属性

    /// 已过去的时间
    public var elapsed: TimeInterval {
        guard let startDate = startDate else { return pausedTime }
        return pausedTime + Date().timeIntervalSince(startDate)
    }

    /// 是否正在运行
    public var isRunning: Bool {
        return state == .resumed
    }
}

// MARK: - LSCountdownTimer

/// 倒计时定时器
public class LSCountdownTimer: NSObject {

    // MARK: - 类型定义

    /// 倒计时回调
    public typealias CountdownHandler = (Int, Int) -> Void  // (剩余秒数, 总秒数)

    /// 完成回调
    public typealias CompletionHandler = () -> Void

    // MARK: - 属性

    /// 总秒数
    public private(set) var totalSeconds: Int

    /// 剩余秒数
    public private(set) var remainingSeconds: Int

    /// 回调
    private let onTick: CountdownHandler?

    /// 完成回调
    private let onComplete: CompletionHandler?

    /// 定时器
    private var timer: LSTimer?

    /// 开始时间
    private var startDate: Date?

    /// 暂停时的时间
    private var pausedRemainingSeconds: Int = 0

    // MARK: - 初始化

    /// 创建倒计时
    ///
    /// - Parameters:
    ///   - seconds: 总秒数
    ///   - onTick: 每秒回调
    ///   - onComplete: 完成回调
    public init(
        seconds: Int,
        onTick: CountdownHandler? = nil,
        onComplete: CompletionHandler? = nil
    ) {
        self.totalSeconds = seconds
        self.remainingSeconds = seconds
        self.onTick = onTick
        self.onComplete = onComplete
        super.init()
    }

    deinit {
        stop()
    }

    // MARK: - 控制

    /// 启动倒计时
    public func start() {
        stop() // 停止之前的倒计时

        startDate = Date()

        timer = LSTimer(timeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.tick()
        }
        timer?.resume()
    }

    /// 暂停倒计时
    public func pause() {
        pausedRemainingSeconds = remainingSeconds
        timer?.suspend()
        startDate = nil
    }

    /// 恢复倒计时
    public func resume() {
        if remainingSeconds == 0 {
            remainingSeconds = pausedRemainingSeconds
        }
        start()
    }

    /// 停止倒计时
    public func stop() {
        timer?.invalidate()
        timer = nil
        startDate = nil
        remainingSeconds = totalSeconds
    }

    /// 重置倒计时
    public func reset() {
        stop()
        pausedRemainingSeconds = 0
        remainingSeconds = totalSeconds
    }

    // MARK: - 私有方法

    private func tick() {
        remainingSeconds -= 1

        // 回调
        onTick?(remainingSeconds, totalSeconds)

        // 检查是否完成
        if remainingSeconds <= 0 {
            stop()
            onComplete?()
        }
    }

    // MARK: - 属性

    /// 格式化的倒计时字符串 (HH:mm:ss)
    public var formattedTime: String {
        let hours = remainingSeconds / 3600
        let minutes = (remainingSeconds % 3600) / 60
        let seconds = remainingSeconds % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    /// 是否正在运行
    public var isRunning: Bool {
        if let tempValue = timer?.isRunning {
            return tempValue
        }
        return false
    }
}

// MARK: - LSVerificationCodeTimer

/// 验证码倒计时（60秒）
public class LSVerificationCodeTimer: LSCountdownTimer {

    /// 默认倒计时秒数
    public static let defaultSeconds = 60

    /// 验证码倒计时文本
    public var countdownText: String {
        return "\(remainingSeconds)秒后重新获取"
    }

    /// 可重新获取的文本
    public var resendText: String = "获取验证码"

    /// 当前显示文本
    public var currentText: String {
        return isRunning ? countdownText : resendText
    }

    // MARK: - 初始化

    /// 创建验证码倒计时（60秒）
    ///
    /// - Parameters:
    ///   - onTick: 每秒回调
    ///   - onComplete: 完成回调
    public convenience init(
        onTick: ((Int) -> Void)? = nil,
        onComplete: (() -> Void)? = nil
    ) {
        self.init(
            seconds: LSVerificationCodeTimer.defaultSeconds,
            onTick: { remaining, _ in
                onTick?(remaining)
            },
            onComplete: onComplete
        )
    }

    // MARK: - 便捷方法

    /// 绑定到按钮
    ///
    /// - Parameter button: 按钮
    /// - Returns: 观察者令牌
    @discardableResult
    public func bind(to button: UIButton) -> ObservationToken {
        return LSTimerBinder.bind(timer: self, to: button)
    }
}

// MARK: - LSTimerBinder

/// 定时器绑定工具
public class LSTimerBinder {

    /// 绑定验证码倒计时到按钮
    ///
    /// - Parameters:
    ///   - timer: 验证码倒计时
    ///   - button: 按钮
    /// - Returns: 观察者令牌
    @discardableResult
    public static func bind(timer: LSVerificationCodeTimer, to button: UIButton) -> ObservationToken {
        // 更新按钮状态
        let updateButton: () -> Void = {
            button.setTitle(timer.currentText, for: .normal)
            button.isEnabled = !timer.isRunning

            if timer.isRunning {
                button.alpha = 0.5
            } else {
                button.alpha = 1.0
            }
        }

        // 初始状态
        updateButton()

        // 创建观察者
        let token = timer.onTick.sink { _ in
            updateButton()
        }

        return token
    }
}

// MARK: - Convenience Methods

public extension LSTimer {

    /// 创建一次性定时器
    ///
    /// - Parameters:
    ///   - timeInterval: 时间间隔
    ///   - queue: 队列
    ///   - handler: 回调
    /// - Returns: 定时器
    static func after(
        timeInterval: TimeInterval,
        queue: DispatchQueue = .main,
        handler: @escaping () -> Void
    ) -> LSTimer {
        let timer = LSTimer(timeInterval: timeInterval, repeats: false, queue: queue) { _ in
            handler()
        }
        timer.resume()
        return timer
    }

    /// 创建重复定时器
    ///
    /// - Parameters:
    ///   - timeInterval: 时间间隔
    ///   - queue: 队列
    ///   - handler: 回调
    /// - Returns: 定时器
    static func every(
        timeInterval: TimeInterval,
        queue: DispatchQueue = .main,
        handler: @escaping () -> Void
    ) -> LSTimer {
        let timer = LSTimer(timeInterval: timeInterval, repeats: true, queue: queue) { _ in
            handler()
        }
        timer.resume()
        return timer
    }

    /// 延迟执行（简化版）
    ///
    /// - Parameters:
    ///   - timeInterval: 时间间隔
    ///   - handler: 回调
    static func delay(
        _ timeInterval: TimeInterval,
        handler: @escaping () -> Void
    ) {
        after(timeInterval: timeInterval, handler: handler)
    }
}

// MARK: - ObservationToken (简化版)

/// 观察者令牌
public class ObservationToken {
    private let cancellationClosure: () -> Void

    init(cancellationClosure: @escaping () -> Void) {
        self.cancellationClosure = cancellationClosure
    }

    public func cancel() {
        cancellationClosure()
    }
}

// MARK: - Closure Sink (用于定时器回调)

extension LSCountdownTimer.CountdownHandler {
    func sink(_ handler: @escaping (Int) -> Void) -> ObservationToken {
        // 简化的订阅机制
        return ObservationToken {
            // 实际实现中需要维护观察者列表
        }
    }
}

#endif

//
//  LSGCDTimer.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  GCD 定时器 - 基于 dispatch_source_t 的定时器
//

#if canImport(UIKit)
import UIKit
import Foundation

// MARK: - LSGCDTimer

/// LSGCDTimer 是基于 GCD 的精确定时器
///
/// 相比 NSTimer，LSGCDTimer 具有以下优势：
/// - 不依赖 RunLoop，更加精确
/// - 不受 RunLoop 模式影响
/// - 不会因滚动而延迟
/// - 自动处理线程安全
public class LSGCDTimer: NSObject {

    // MARK: - 类型定义

    /// 定时器回调
    public typealias TimerHandler = (LSGCDTimer) -> Void

    // MARK: - 属性

    /// 定时器是否正在运行
    public private(set) var isRunning: Bool = false

    /// 定时器是否已暂停
    public private(set) var isPaused: Bool = false

    /// 重复次数（0 表示无限重复）
    public private(set) var repeatCount: UInt = 0

    /// 当前重复次数
    public private(set) var currentRepeatCount: UInt = 0

    /// 时间间隔
    public private(set) var timeInterval: TimeInterval

    /// 延迟时间
    public private(set) var delay: TimeInterval

    /// 队列
    public let queue: DispatchQueue

    // MARK: - 私有属性

    private var timer: DispatchSourceTimer?
    private var handler: TimerHandler?
    private weak var target: AnyObject?
    private var selector: Selector?

    // MARK: - 初始化

    /// 创建定时器
    ///
    /// - Parameters:
    ///   - timeInterval: 时间间隔（秒）
    ///   - delay: 延迟时间（秒，默认 0）
    ///   - queue: 调度队列（默认主队列）
    ///   - repeats: 是否重复（默认 true）
    ///   - repeatCount: 重复次数（0 表示无限，默认 0）
    ///   - handler: 定时器回调
    /// - Returns: 定时器实例
    public static func timer(
        withTimeInterval timeInterval: TimeInterval,
        delay: TimeInterval = 0,
        queue: DispatchQueue = .main,
        repeats: Bool = true,
        repeatCount: UInt = 0,
        handler: @escaping TimerHandler
    ) -> LSGCDTimer {
        let timer = LSGCDTimer(timeInterval: timeInterval, delay: delay, queue: queue, repeats: repeats, repeatCount: repeatCount)
        timer.handler = handler
        return timer
    }

    /// 创建定时器（目标-动作模式）
    ///
    /// - Parameters:
    ///   - timeInterval: 时间间隔（秒）
    ///   - target: 目标对象
    ///   - selector: 选择器
    ///   - userInfo: 用户信息
    /// - Returns: 定时器实例
    @available(*, deprecated, message: "Use closure-based API instead")
    public static func timer(
        withTimeInterval timeInterval: TimeInterval,
        target: AnyObject,
        selector: Selector
    ) -> LSGCDTimer {
        let timer = LSGCDTimer(timeInterval: timeInterval, delay: 0, queue: .main, repeats: true, repeatCount: 0)
        timer.target = target
        timer.selector = selector
        return timer
    }

    private init(timeInterval: TimeInterval, delay: TimeInterval, queue: DispatchQueue, repeats: Bool, repeatCount: UInt) {
        self.timeInterval = timeInterval
        self.delay = delay
        self.queue = queue
        self.repeatCount = repeats ? repeatCount : 1
        super.init()
    }

    deinit {
        invalidate()
    }

    // MARK: - 公共方法

    /// 启动定时器
    public func start() {
        guard !isRunning else { return }

        isRunning = true
        isPaused = false

        let source = DispatchSource.makeTimerSource(flags: .strict, queue: queue)

        source.schedule(
            deadline: .now() + delay,
            repeating: repeatCount == 1 ? .never : .milliseconds(Int64(timeInterval * 1000))
        )

        source.setEventHandler { [weak self] in
            guard let self = self else { return }

            if let handler = self.handler {
                handler(self)
            } else if let target = self.target, let selector = self.selector {
                _ = target.perform(selector, with: self)
            }

            // 处理重复次数
            if self.repeatCount > 0 {
                self.currentRepeatCount += 1
                if self.currentRepeatCount >= self.repeatCount {
                    self.invalidate()
                }
            }
        }

        source.resume()
        timer = source
    }

    /// 暂停定时器
    public func pause() {
        guard isRunning && !isPaused else { return }
        isPaused = true
        timer?.suspend()
    }

    /// 恢复定时器
    public func resume() {
        guard isRunning && isPaused else { return }
        isPaused = false
        timer?.resume()
    }

    /// 停止定时器
    public func stop() {
        invalidate()
    }

    /// 使定时器失效
    public func invalidate() {
        isRunning = false
        isPaused = false
        timer?.cancel()
        timer = nil
        target = nil
        selector = nil
        handler = nil
        currentRepeatCount = 0
    }
}

// MARK: - 便捷创建方法

extension LSGCDTimer {

    /// 创建一次性定时器
    ///
    /// - Parameters:
    ///   - timeInterval: 时间间隔
    ///   - delay: 延迟时间
    ///   - queue: 调度队列
    ///   - handler: 定时器回调
    /// - Returns: 定时器实例
    public static func scheduledTimer(
        withTimeInterval timeInterval: TimeInterval,
        delay: TimeInterval = 0,
        queue: DispatchQueue = .main,
        handler: @escaping @convention(block) () -> Void
    ) -> LSGCDTimer {
        let timer = LSGCDTimer.timer(withTimeInterval: timeInterval, delay: delay, queue: queue, repeats: false, repeatCount: 1) { _ in
            handler()
        }
        timer.start()
        return timer
    }
}

// MARK: - NSObject Extension (定时器支持)

extension NSObject {

    /// 执行延迟回调
    ///
    /// - Parameters:
    ///   - delay: 延迟时间（秒）
    ///   - handler: 回调闭包
    /// - Returns: 定时器对象
    @discardableResult
    public func ls_perform(
        afterDelay delay: TimeInterval,
        handler: @escaping () -> Void
    ) -> LSGCDTimer {
        let timer = LSGCDTimer.scheduledTimer(withTimeInterval: 0, delay: delay, queue: .main) {
            handler()
        }
        return timer
    }

    /// 取消延迟执行
    ///
    /// - Parameter timer: 定时器对象
    public class func ls_cancelPreviousPerformRequests(withTimer timer: LSGCDTimer) {
        timer.invalidate()
    }
}

#endif

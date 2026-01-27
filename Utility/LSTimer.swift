//
//  LSTimer.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  基于 GCD 的线程安全定时器
//

#if canImport(UIKit)
import UIKit
import Foundation
import Dispatch

/// LSTimer 是基于 GCD 的线程安全定时器
///
/// 与 NSTimer 的区别：
/// - 使用 GCD 产生定时器滴答，不受 runloop 影响
/// - 对 target 使用弱引用，可以避免循环引用
/// - 始终在主线程触发
public class LSTimer: NSObject {

    // MARK: - 属性

    /// 是否重复（只读）
    public private(set) var repeats: Bool = false

    /// 时间间隔（只读）
    public private(set) var timeInterval: TimeInterval = 0

    /// 是否有效（只读）
    public private(set) var isValid: Bool = false

    // MARK: - 内部属性

    private weak var target: AnyObject?
    private var selector: Selector?
    private var source: DispatchSourceTimer?
    private let lock = DispatchSemaphore(value: 1)

    // MARK: - 类方法

    /// 创建定时器
    ///
    /// - Parameters:
    ///   - interval: 时间间隔
    ///   - target: 目标对象（弱引用）
    ///   - selector: 选择器
    ///   - repeats: 是否重复
    /// - Returns: LSTimer 实例
    public static func timer(withTimeInterval interval: TimeInterval,
                             target: AnyObject,
                             selector: Selector,
                             repeats: Bool) -> LSTimer {
        return LSTimer(fireTime: interval,
                       interval: interval,
                       target: target,
                       selector: selector,
                       repeats: repeats)
    }

    // MARK: - 初始化

    /// 使用指定的参数初始化定时器
    ///
    /// - Parameters:
    ///   - start: 启动时间
    ///   - interval: 时间间隔
    ///   - target: 目标对象（弱引用）
    ///   - selector: 选择器
    ///   - repeats: 是否重复
    public init(fireTime start: TimeInterval,
                interval: TimeInterval,
                target: AnyObject,
                selector: Selector,
                repeats: Bool) {
        super.init()

        self.repeats = repeats
        self.timeInterval = interval
        self.isValid = true
        self.target = target
        self.selector = selector

        let queue = DispatchQueue.main
        source = DispatchSource.makeTimerSource(flags: .strict, queue: queue)

        // 使用 weak self 防止循环引用
        source?.schedule(deadline: .now() + start, repeating: repeats ? interval : .infinity, leeway: .nanoseconds(0))
        source?.setEventHandler { [weak self] in
            self?.fire()
        }

        source?.resume()
    }

    deinit {
        invalidate()
    }

    // MARK: - 公共方法

    /// 使定时器无效
    public func invalidate() {
        lock.wait()
        defer { lock.signal() }

        guard isValid else { return }

        source?.cancel()
        source = nil
        target = nil
        selector = nil
        isValid = false
    }

    /// 立即触发定时器
    public func fire() {
        lock.wait()
        let currentTarget = target
        let currentRepeats = repeats
        lock.signal()

        guard let currentTarget = currentTarget else {
            invalidate()
            return
        }

        if !currentRepeats {
            invalidate()
        }

        // 执行 selector
        // swiftlint:disable:next prohibited_interface_builder
        _ = currentTarget.perform(selector, with: self)
    }
}

// MARK: - NSObject Protocol

extension LSTimer {
    override public var hash: Int {
        return ObjectIdentifier(self).hashValue
    }

    override public func isEqual(_ object: Any?) -> Bool {
        return self === object as? LSTimer
    }
}
#endif

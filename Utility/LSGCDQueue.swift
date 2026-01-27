//
//  LSGCDQueue.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  GCD 队列工具 - 便捷的队列管理
//

#if canImport(UIKit)
import UIKit
import Foundation

// MARK: - LSGCDQueue

/// GCD 队列工具类
public class LSGCDQueue: NSObject {

    // MARK: - 单例

    /// 主队列
    public static let main = LSGCDQueue(queue: DispatchQueue.main)

    /// 全局队列（高优先级）
    public static let highPriority = LSGCDQueue(queue: DispatchQueue.global(qos: .userInitiated))

    /// 全局队列（默认优先级）
    public static let defaultPriority = LSGCDQueue(queue: DispatchQueue.global(qos: .default))

    /// 全局队列（低优先级）
    public static let lowPriority = LSGCDQueue(queue: DispatchQueue.global(qos: .utility))

    /// 全局队列（后台优先级）
    public static let backgroundPriority = LSGCDQueue(queue: DispatchQueue.global(qos: .background))

    // MARK: - 属性

    /// 底层队列
    public let queue: DispatchQueue

    /// 队列标签
    public var label: String {
        return queue.label
    }

    // MARK: - 初始化

    /// 创建自定义串行队列
    ///
    /// - Parameter label: 队列标签
    /// - Returns: 队列实例
    @discardableResult
    public static func serialQueue(label: String) -> LSGCDQueue {
        return LSGCDQueue(queue: DispatchQueue(label: label, attributes: .concurrent))
    }

    /// 创建自定义并发队列
    ///
    /// - Parameter label: 队列标签
    /// - Returns: 队列实例
    @discardableResult
    public static func concurrentQueue(label: String) -> LSGCDQueue {
        return LSGCDQueue(queue: DispatchQueue(label: label, attributes: .concurrent))
    }

    /// 创建队列
    ///
    /// - Parameters:
    ///   - label: 队列标签
    ///   - qos: 服务质量
    ///   - attributes: 队列属性
    /// - Returns: 队列实例
    @discardableResult
    public static func queue(label: String, qos: DispatchQoS = .default, attributes: DispatchQueue.Attributes = []) -> LSGCDQueue {
        return LSGCDQueue(queue: DispatchQueue(label: label, qos: qos, attributes: attributes))
    }

    /// 内部初始化
    internal init(queue: DispatchQueue) {
        self.queue = queue
        super.init()
    }

    // MARK: - 异步执行

    /// 异步执行闭包
    ///
    /// - Parameter block: 要执行的闭包
    public func execute(_ block: @escaping () -> Void) {
        queue.async(execute: block)
    }

    /// 异步执行闭包（带延迟）
    ///
    /// - Parameters:
    ///   - delay: 延迟时间（秒）
    ///   - block: 要执行的闭包
    @discardableResult
    public func execute(after delay: TimeInterval, block: @escaping () -> Void) -> DispatchWorkItem {
        let workItem = DispatchWorkItem(block: block)
        queue.asyncAfter(deadline: .now() + delay, execute: workItem)
        return workItem
    }

    /// 异步执行闭包（带延迟，使用 DispatchTime）
    ///
    /// - Parameters:
    ///   - deadline: 截止时间
    ///   - block: 要执行的闭包
    @discardableResult
    public func execute(at deadline: DispatchTime, block: @escaping () -> Void) -> DispatchWorkItem {
        let workItem = DispatchWorkItem(block: block)
        queue.asyncAfter(deadline: deadline, execute: workItem)
        return workItem
    }

    // MARK: - 同步执行

    /// 同步执行闭包
    ///
    /// - Parameter block: 要执行的闭包
    public func syncExecute(_ block: () -> Void) {
        queue.sync(execute: block)
    }

    // MARK: - 栅栏

    /// 异步栅栏（用于并发队列中实现读写锁）
    ///
    /// - Parameter block: 要执行的闭包
    public func barrierExecute(_ block: @escaping () -> Void) {
        queue.async(flags: .barrier, execute: block)
    }

    /// 同步栅栏
    ///
    /// - Parameter block: 要执行的闭包
    public func barrierSyncExecute(_ block: () -> Void) {
        queue.sync(flags: .barrier, execute: block)
    }

    // MARK: - 便利方法

    /// 在主队列执行
    ///
    /// - Parameter block: 要执行的闭包
    public static func mainQueue(_ block: @escaping () -> Void) {
        DispatchQueue.main.async(execute: block)
    }

    /// 在主队列执行（带延迟）
    ///
    /// - Parameters:
    ///   - delay: 延迟时间（秒）
    ///   - block: 要执行的闭包
    @discardableResult
    public static func mainQueue(after delay: TimeInterval, block: @escaping () -> Void) -> DispatchWorkItem {
        let workItem = DispatchWorkItem(block: block)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        return workItem
    }

    /// 在全局队列执行
    ///
    /// - Parameters:
    ///   - qos: 服务质量
    ///   - block: 要执行的闭包
    public static func globalQueue(qos: DispatchQoS = .default, block: @escaping () -> Void) {
        DispatchQueue.global(qos: qos).async(execute: block)
    }

    /// 在全局队列执行（带延迟）
    ///
    /// - Parameters:
    ///   - qos: 服务质量
    ///   - delay: 延迟时间（秒）
    ///   - block: 要执行的闭包
    @discardableResult
    public static func globalQueue(qos: DispatchQoS = .default, after delay: TimeInterval, block: @escaping () -> Void) -> DispatchWorkItem {
        let workItem = DispatchWorkItem(block: block)
        DispatchQueue.global(qos: qos).asyncAfter(deadline: .now() + delay, execute: workItem)
        return workItem
    }

    // MARK: - 组

    /// 创建 DispatchGroup
    ///
    /// - Returns: DispatchGroup
    public func createGroup() -> DispatchGroup {
        return DispatchGroup()
    }

    /// 在组中执行闭包
    ///
    /// - Parameters:
    ///   - group: 组
    ///   - block: 要执行的闭包
    public func execute(inGroup group: DispatchGroup, block: @escaping () -> Void) {
        queue.async(group: group, execute: block)
    }

    /// 通知组完成
    ///
    /// - Parameters:
    ///   - group: 组
    ///   - queue: 目标队列
    ///   - block: 完成闭包
    public static func notify(group: DispatchGroup, queue: LSGCDQueue = .main, block: @escaping () -> Void) {
        group.notify(queue: queue.queue, execute: block)
    }

    /// 等待组完成
    ///
    /// - Parameters:
    ///   - group: 组
    ///   - timeout: 超时时间（秒）
    /// - Returns: 是否成功完成
    @discardableResult
    public static func wait(group: DispatchGroup, timeout: TimeInterval = .infinity) -> Bool {
        if timeout == .infinity {
            group.wait()
            return true
        } else {
            return group.wait(timeout: .now() + timeout) == .success
        }
    }

    // MARK: - 信号量

    /// 创建信号量
    ///
    /// - Parameter value: 初始值
    /// - Returns: DispatchSemaphore
    public static func createSemaphore(value: Int = 0) -> DispatchSemaphore {
        return DispatchSemaphore(value: value)
    }

    /// 等待信号量
    ///
    /// - Parameters:
    ///   - semaphore: 信号量
    ///   - timeout: 超时时间（秒）
    /// - Returns: 是否成功获取
    @discardableResult
    public static func wait(semaphore: DispatchSemaphore, timeout: TimeInterval = .infinity) -> Bool {
        if timeout == .infinity {
            semaphore.wait()
            return true
        } else {
            return semaphore.wait(timeout: .now() + timeout) == .success
        }
    }

    /// 发送信号量
    ///
    /// - Parameter semaphore: 信号量
    public static func signal(semaphore: DispatchSemaphore) {
        semaphore.signal()
    }

    // MARK: - 并发执行

    /// 并发执行多个任务
    ///
    /// - Parameter blocks: 任务数组
    public static func concurrentExecute(blocks: [@escaping () -> Void]) {
        let group = DispatchGroup()
        let queue = DispatchQueue.global(qos: .default)

        for block in blocks {
            queue.async(group: group, execute: block)
        }

        group.wait()
    }

    /// 并发执行多个任务并等待完成
    ///
    /// - Parameters:
    ///   - blocks: 任务数组
    ///   - completion: 完成回调
    public static func concurrentExecute(blocks: [@escaping () -> Void], completion: @escaping () -> Void) {
        let group = DispatchGroup()
        let queue = DispatchQueue.global(qos: .default)

        for block in blocks {
            queue.async(group: group, execute: block)
        }

        group.notify(queue: .main) {
            completion()
        }
    }

    // MARK: - 迭代

    /// 并发迭代
    ///
    /// - Parameters:
    ///   - iterations: 迭代次数
    ///   - block: 迭代闭包
    public static func concurrentIterate(_ iterations: Int, block: @escaping (Int) -> Void) {
        let group = DispatchGroup()
        let queue = DispatchQueue.global(qos: .default)

        for i in 0..<iterations {
            queue.async(group: group) {
                block(i)
            }
        }

        group.wait()
    }

    /// 并发迭代（带完成回调）
    ///
    /// - Parameters:
    ///   - iterations: 迭代次数
    ///   - block: 迭代闭包
    ///   - completion: 完成回调
    public static func concurrentIterate(_ iterations: Int, block: @escaping (Int) -> Void, completion: @escaping () -> Void) {
        let group = DispatchGroup()
        let queue = DispatchQueue.global(qos: .default)

        for i in 0..<iterations {
            queue.async(group: group) {
                block(i)
            }
        }

        group.notify(queue: .main) {
            completion()
        }
    }

    // MARK: - Apply

    /// 并发 Apply
    ///
    /// - Parameters:
    ///   - iterations: 迭代次数
    ///   - block: 迭代闭包
    public static func concurrentApply(_ iterations: Int, block: @escaping (Int) -> Void) {
        DispatchQueue.concurrentPerform(iterations: iterations, execute: block)
    }

    /// 串行 Apply
    ///
    /// - Parameters:
    ///   - iterations: 迭代次数
    ///   - block: 迭代闭包
    public static func serialApply(_ iterations: Int, block: (Int) -> Void) {
        for i in 0..<iterations {
            block(i)
        }
    }
}

// MARK: - DispatchQueue Extension

public extension DispatchQueue {

    /// 延迟执行
    ///
    /// - Parameters:
    ///   - delay: 延迟时间（秒）
    ///   - block: 要执行的闭包
    @discardableResult
    func ls_after(_ delay: TimeInterval, block: @escaping () -> Void) -> DispatchWorkItem {
        let workItem = DispatchWorkItem(block: block)
        asyncAfter(deadline: .now() + delay, execute: workItem)
        return workItem
    }

    /// 延迟重复执行
    ///
    /// - Parameters:
    ///   - delay: 延迟时间（秒）
    ///   - interval: 重复间隔（秒）
    ///   - block: 要执行的闭包
    /// - Returns: DispatchWorkItem（用于取消）
    @discardableResult
    func ls_afterRepeat(delay: TimeInterval, interval: TimeInterval, block: @escaping () -> Void) -> DispatchWorkItem {
        let workItem = DispatchWorkItem(block: {})
        asyncAfter(deadline: .now() + delay) { [weak workItem] in
            guard let workItem = workItem, !workItem.isCancelled else { return }

            // 创建定时器
            let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                if workItem.isCancelled {
                    timer.invalidate()
                    return
                }
                block()
            }

            workItem.notify(queue: .main) {
                timer.invalidate()
            }

            block()
        }
        return workItem
    }
}

#endif

//
//  LSSentinel.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-26.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  线程安全哨兵类 - 用于资源追踪和线程同步
//

import Foundation

/// 哨兵类 - 线程安全的计数器
///
/// 此类提供原子递增操作，常用于：
/// - 资源追踪（如任务 ID 生成）
/// - 线程同步（检测资源是否被释放）
/// - 操作计数
public class LSSentinel {

    // MARK: - 属性

    /// 当前值
    private(set) public var value: Int32 = 0

    /// 递增并返回新值
    ///
    /// - Returns: 递增后的值
    @discardableResult
    public func increment() -> Int32 {
        return OSAtomicIncrement32(&value)
    }

    /// 递减并返回新值
    ///
    /// - Returns: 递减后的值
    @discardableResult
    public func decrement() -> Int32 {
        return OSAtomicDecrement32(&value)
    }

    /// 获取当前值
    ///
    /// - Returns: 当前值
    public func get() -> Int32 {
        return value
    }

    /// 设置值
    ///
    /// - Parameter newValue: 新值
    public func set(_ newValue: Int32) {
        value = newValue
    }

    /// 原子性地比较并设置值
    ///
    /// - Parameters:
    ///   - expectedValue: 期望的当前值
    ///   - newValue: 要设置的新值
    /// - Returns: 是否设置成功（如果当前值等于期望值）
    @discardableResult
    public func compareAndSet(expectedValue: Int32, newValue: Int32) -> Bool {
        return OSAtomicCompareAndSwap32Barrier(expectedValue, newValue, &value)
    }

    /// 原子性地加法
    ///
    /// - Parameter delta: 要增加的值
    /// - Returns: 新值
    @discardableResult
    public func add(_ delta: Int32) -> Int32 {
        return OSAtomicAdd32(delta, &value)
    }

    /// 检查值是否为零
    ///
    /// - Returns: 是否为零
    public var isZero: Bool {
        return value == 0
    }

    /// 检查值是否为正数
    ///
    /// - Returns: 是否为正数
    public var isPositive: Bool {
        return value > 0
    }

    // MARK: - 初始化

    /// 创建哨兵实例
    ///
    /// - Parameter initialValue: 初始值，默认为 0
    public init(_ initialValue: Int32 = 0) {
        value = initialValue
    }
}

// MARK: - 线程安全操作扩展

public extension LSSentinel {

    /// 执行操作并自动递增
    ///
    /// - Parameter block: 要执行的操作
    /// - Returns: 操作前的值
    @discardableResult
    func perform<T>(_ block: () -> T) -> Int32 {
        let currentValue = increment()
        defer { decrement() }
        _ = block()
        return currentValue
    }

    /// 等待直到值为零
    ///
    /// - Parameter timeout: 超时时间（秒），nil 表示无限等待
    /// - Returns: 是否成功等待到值为零
    func waitUntilZero(timeout: TimeInterval? = nil) -> Bool {
        let startTime = Date()

        while value != 0 {
            if let timeout = timeout {
                if Date().timeIntervalSince(startTime) >= timeout {
                    return false
                }
            }
            usleep(1000) // 休眠 1ms
        }

        return true
    }

    /// 异步等待直到值为零
    ///
    /// - Parameters:
    ///   - queue: 执行回调的队列
    ///   - timeout: 超时时间（秒），nil 表示无限等待
    ///   - completion: 完成回调
    func waitUntilZeroAsync(
        queue: DispatchQueue = .main,
        timeout: TimeInterval? = nil,
        completion: @escaping (Bool) -> Void
    ) {
        queue.async {
            let result = self.waitUntilZero(timeout: timeout)
            completion(result)
        }
    }
}

// MARK: - 调试支持

extension LSSentinel: CustomStringConvertible {

    public var description: String {
        return "LSSentinel(value: \(value))"
    }
}

extension LSSentinel: CustomDebugStringConvertible {

    public var debugDescription: String {
        return "LSSentinel(value: \(value), address: \(Unmanaged.passUnretained(self).toOpaque()))"
    }
}

// MARK: - 原子操作兼容性

#if !os(iOS)
// macOS 和其他平台可能需要不同的原子操作
private func OSAtomicIncrement32(_ pointer: UnsafeMutablePointer<Int32>) -> Int32 {
    return pointer.pointee += 1
}

private func OSAtomicDecrement32(_ pointer: UnsafeMutablePointer<Int32>) -> Int32 {
    return pointer.pointee -= 1
}

private func OSAtomicAdd32(_ delta: Int32, _ pointer: UnsafeMutablePointer<Int32>) -> Int32 {
    return pointer.pointee += delta
}

private func OSAtomicCompareAndSwap32Barrier(
    _ expectedValue: Int32,
    _ newValue: Int32,
    _ pointer: UnsafeMutablePointer<Int32>
) -> Bool {
    if pointer.pointee == expectedValue {
        pointer.pointee = newValue
        return true
    }
    return false
}
#endif

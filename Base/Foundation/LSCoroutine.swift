//
//  LSCoroutine.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  协程工具 - 基于 async/await 的异步任务管理
//

#if canImport(UIKit)
import UIKit
import Foundation

// MARK: - LSCoroutine

/// 协程工具类（iOS 13+ 使用闭包模拟）
public enum LSCoroutine {

    // MARK: - 异步执行

    /// 异步执行闭包
    ///
    /// - Parameters:
    ///   - queue: 队列
    ///   - block: 要执行的闭包
    public static func async(on queue: DispatchQueue = .global(qos: .default), block: @escaping () -> Void) {
        queue.async {
            block()
        }
    }

    /// 异步执行闭包并延迟
    ///
    /// - Parameters:
    ///   - delay: 延迟时间（秒）
    ///   - queue: 队列
    ///   - block: 要执行的闭包
    /// - Returns: DispatchWorkItem（用于取消）
    @discardableResult
    public static func async(
        delay: TimeInterval,
        on queue: DispatchQueue = .global(qos: .default),
        block: @escaping () -> Void
    ) -> DispatchWorkItem {
        let workItem = DispatchWorkItem(block: block)
        queue.asyncAfter(deadline: .now() + delay, execute: workItem)
        return workItem
    }

    /// 异步执行并在主线程回调
    ///
    /// - Parameters:
    ///   - queue: 执行队列
    ///   - block: 要执行的闭包
    ///   - completion: 完成回调（主线程）
    public static func async(
        on queue: DispatchQueue = .global(qos: .default),
        block: @escaping () -> Void,
        completion: @escaping () -> Void
    ) {
        queue.async {
            block()
            DispatchQueue.main.async {
                completion()
            }
        }
    }

    // MARK: - 延迟执行

    /// 延迟执行
    ///
    /// - Parameters:
    ///   - delay: 延迟时间（秒）
    ///   - block: 要执行的闭包
    /// - Returns: DispatchWorkItem（用于取消）
    @discardableResult
    public static func delay(_ delay: TimeInterval, block: @escaping () -> Void) -> DispatchWorkItem {
        return async(delay: delay, on: .main, block: block)
    }

    // MARK: - 并发执行

    /// 并发执行多个任务
    ///
    /// - Parameters:
    ///   - blocks: 任务数组
    ///   - completion: 完成回调
    public static func concurrent(
        _ blocks: [@escaping () -> Void],
        completion: @escaping () -> Void
    ) {
        let group = DispatchGroup()
        let queue = DispatchQueue.global(qos: .default)

        for block in blocks {
            queue.async(group: group, execute: block)
        }

        group.notify(queue: .main) {
            completion()
        }
    }

    /// 并发执行多个任务并收集结果
    ///
    /// - Parameters:
    ///   - blocks: 任务数组（返回结果）
    ///   - completion: 完成回调（返回结果数组）
    public static func concurrent<T>(
        _ blocks: [@escaping () -> T],
        completion: @escaping ([T]) -> Void
    ) {
        let queue = DispatchQueue.global(qos: .default)
        let group = DispatchGroup()
        var results: [T?] = Array(repeating: nil, count: blocks.count)

        for (index, block) in blocks.enumerated() {
            group.enter()
            queue.async {
                results[index] = block()
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(results.compactMap { $0 })
        }
    }

    // MARK: - 串行执行

    /// 串行执行多个任务
    ///
    /// - Parameters:
    ///   - blocks: 任务数组
    ///   - completion: 完成回调
    public static func serial(
        _ blocks: [@escaping () -> Void],
        completion: @escaping () -> Void
    ) {
        let queue = DispatchQueue(label: "com.ls coroutine.serial")

        queue.async {
            for block in blocks {
                block()
            }

            DispatchQueue.main.async {
                completion()
            }
        }
    }

    /// 串行执行多个任务并传递结果
    ///
    /// - Parameters:
    ///   - blocks: 任务数组（返回结果）
    ///   - completion: 完成回调（返回结果数组）
    public static func serial<T>(
        _ blocks: [@escaping () -> T],
        completion: @escaping ([T]) -> Void
    ) {
        let queue = DispatchQueue(label: "com.ls coroutine.serial")
        var results: [T] = []

        queue.async {
            for block in blocks {
                results.append(block())
            }

            DispatchQueue.main.async {
                completion(results)
            }
        }
    }

    // MARK: - 重试

    /// 重试执行
    ///
    /// - Parameters:
    ///   - attempts: 最大尝试次数
    ///   - delay: 重试延迟（秒）
    ///   - queue: 执行队列
    ///   - block: 要执行的闭包（返回是否成功）
    ///   - completion: 完成回调
    public static func retry(
        attempts: Int = 3,
        delay: TimeInterval = 1,
        on queue: DispatchQueue = .global(qos: .default),
        block: @escaping () throws -> Bool,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        func attempt(_ remaining: Int) {
            queue.async {
                do {
                    let success = try block()

                    if success || remaining <= 1 {
                        DispatchQueue.main.async {
                            completion(success, nil)
                        }
                    } else {
                        LSCoroutine.async(delay: delay, on: queue) {
                            attempt(remaining - 1)
                        }
                    }
                } catch {
                    if remaining <= 1 {
                        DispatchQueue.main.async {
                            completion(false, error)
                        }
                    } else {
                        LSCoroutine.async(delay: delay, on: queue) {
                            attempt(remaining - 1)
                        }
                    }
                }
            }
        }

        attempt(attempts)
    }

    // MARK: - 超时

    /// 带超时的执行
    ///
    /// - Parameters:
    ///   - timeout: 超时时间（秒）
    ///   - queue: 执行队列
    ///   - block: 要执行的闭包
    ///   - completion: 完成回调
    public static func execute<T>(
        timeout: TimeInterval,
        on queue: DispatchQueue = .global(qos: .default),
        block: @escaping () throws -> T,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        var completed = false
        let lock = NSLock()

        func complete(_ result: Result<T, Error>) {
            lock.lock()
            defer { lock.unlock() }

            guard !completed else { return }
            completed = true

            DispatchQueue.main.async {
                completion(result)
            }
        }

        // 执行任务
        queue.async {
            do {
                let result = try block()
                complete(.success(result))
            } catch {
                complete(.failure(error))
            }
        }

        // 超时检查
        queue.asyncAfter(deadline: .now() + timeout) {
            complete(.failure(TimeoutError()))
        }
    }

    // MARK: - 取消令牌

    /// 创建取消令牌
    ///
    /// - Returns: CancellationToken
    public static func cancellationToken() -> CancellationToken {
        return CancellationToken()
    }

    /// 可取消的异步执行
    ///
    /// - Parameters:
    ///   - token: 取消令牌
    ///   - queue: 执行队列
    ///   - block: 要执行的闭包
    public static func async(
        token: CancellationToken,
        on queue: DispatchQueue = .global(qos: .default),
        block: @escaping () -> Void
    ) {
        queue.async {
            guard !token.isCancelled else { return }
            block()
        }
    }

    /// 可取消的延迟执行
    ///
    /// - Parameters:
    ///   - token: 取消令牌
    ///   - delay: 延迟时间（秒）
    ///   - queue: 执行队列
    ///   - block: 要执行的闭包
    public static func async(
        token: CancellationToken,
        delay: TimeInterval,
        on queue: DispatchQueue = .global(qos: .default),
        block: @escaping () -> Void
    ) {
        queue.asyncAfter(deadline: .now() + delay) {
            guard !token.isCancelled else { return }
            block()
        }
    }

    // MARK: - 任务构建器（简化版）

    /// 创建任务序列
    ///
    /// - Parameter builder: 任务构建闭包
    public static func task(_ builder: () -> Void) {
        builder()
    }

    /// 等待异步操作
    ///
    /// - Parameters:
    ///   - queue: 执行队列
    ///   - block: 异步闭包
    ///   - completion: 完成回调
    public static func await<T>(
        on queue: DispatchQueue = .global(qos: .default),
        block: @escaping () throws -> T,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        queue.async {
            do {
                let result = try block()
                DispatchQueue.main.async {
                    completion(.success(result))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}

// MARK: - CancellationToken

/// 取消令牌
public class CancellationToken {

    private var _cancelled = false
    private let lock = NSLock()

    /// 是否已取消
    public var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _cancelled
    }

    /// 取消
    public func cancel() {
        lock.lock()
        defer { lock.unlock() }
        _cancelled = true
    }

    /// 重置
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        _cancelled = false
    }
}

// MARK: - TimeoutError

/// 超时错误
public struct TimeoutError: Error {
    public let localizedDescription = "操作超时"
}

// MARK: - Task (简化版)

/// 任务基类
public class LSTask {

    /// 任务状态
    public enum State {
        case pending
        case running
        case completed
        case cancelled
        case failed(Error)
    }

    /// 任务状态
    public private(set) var state: State = .pending

    /// 取消令牌
    public let token = LSCoroutine.cancellationToken()

    /// 取消任务
    public func cancel() {
        guard case .pending = state else { return }
        state = .cancelled
        token.cancel()
    }

    /// 启动任务
    public func start() {
        guard case .pending = state else { return }
        state = .running
    }
}

/// 异步任务
public class LSAsyncTask<T>: LSTask {

    /// 完成回调
    private var completion: ((Result<T, Error>) -> Void)?

    /// 创建任务
    ///
    /// - Parameters:
    ///   - queue: 执行队列
    ///   - block: 任务闭包
    /// - Returns: 任务实例
    public static func create(
        on queue: DispatchQueue = .global(qos: .default),
        block: @escaping (CancellationToken) throws -> T
    ) -> LSAsyncTask<T> {
        let task = LSAsyncTask<T>()

        task.completion = { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let value):
                    task.state = .completed
                case .failure(let error):
                    task.state = .failed(error)
                }
            }
        }

        task.start()

        queue.async {
            guard !task.token.isCancelled else {
                task.cancel()
                return
            }

            do {
                let result = try block(task.token)
                task.completion?(.success(result))
            } catch {
                task.completion?(.failure(error))
            }
        }

        return task
    }

    /// 添加完成回调
    ///
    /// - Parameter completion: 完成回调
    /// - Returns: self
    @discardableResult
    public func onCompletion(_ completion: @escaping (Result<T, Error>) -> Void) -> Self {
        self.completion = completion
        return self
    }
}

// MARK: - Promise (简化版)

/// Promise - 用于链式异步操作
public class LSPromise<T> {

    /// 状态
    public enum State {
        case pending
        case fulfilled(T)
        case rejected(Error)
    }

    /// 当前状态
    public private(set) var state: State = .pending

    /// 完成 handlers
    private var successHandlers: [(T) -> Void] = []

    /// 失败 handlers
    private var failureHandlers: [(Error) -> Void] = []

    /// 创建已完成的 Promise
    ///
    /// - Parameter value: 值
    /// - Returns: Promise 实例
    public static func resolve(_ value: T) -> LSPromise<T> {
        let promise = LSPromise<T>()
        promise.resolve(value)
        return promise
    }

    /// 创建已拒绝的 Promise
    ///
    /// - Parameter error: 错误
    /// - Returns: Promise 实例
    public static func reject(_ error: Error) -> LSPromise<T> {
        let promise = LSPromise<T>()
        promise.reject(error)
        return promise
    }

    /// 创建异步 Promise
    ///
    /// - Parameter block: 异步闭包
    /// - Returns: Promise 实例
    public static func async(_ block: @escaping (@escaping (T) -> Void, @escaping (Error) -> Void) -> Void) -> LSPromise<T> {
        let promise = LSPromise<T>()

        block(
            { promise.resolve($0) },
            { promise.reject($0) }
        )

        return promise
    }

    /// 完成
    ///
    /// - Parameter value: 值
    public func resolve(_ value: T) {
        guard case .pending = state else { return }
        state = .fulfilled(value)
        successHandlers.forEach { $0(value) }
        successHandlers.removeAll()
    }

    /// 拒绝
    ///
    /// - Parameter error: 错误
    public func reject(_ error: Error) {
        guard case .pending = state else { return }
        state = .rejected(error)
        failureHandlers.forEach { $0(error) }
        failureHandlers.removeAll()
    }

    /// 添加成功回调
    ///
    /// - Parameter handler: 成功闭包
    /// - Returns: self
    @discardableResult
    public func then(_ handler: @escaping (T) -> Void) -> Self {
        if case let .fulfilled(value) = state {
            handler(value)
        } else {
            successHandlers.append(handler)
        }
        return self
    }

    /// 添加失败回调
    ///
    /// - Parameter handler: 失败闭包
    /// - Returns: self
    @discardableResult
    public func `catch`(_ handler: @escaping (Error) -> Void) -> Self {
        if case let .rejected(error) = state {
            handler(error)
        } else {
            failureHandlers.append(handler)
        }
        return self
    }

    /// 转换值
    ///
    /// - Parameter transform: 转换闭包
    /// - Returns: 新的 Promise
    public func map<U>(_ transform: @escaping (T) throws -> U) -> LSPromise<U> {
        let promise = LSPromise<U>()

        then { value in
            do {
                let transformed = try transform(value)
                promise.resolve(transformed)
            } catch {
                promise.reject(error)
            }
        }

        catch { error in
            promise.reject(error)
        }

        return promise
    }

    /// 链式 Promise
    ///
    /// - Parameter transform: 转换闭包
    /// - Returns: 新的 Promise
    public func flatMap<U>(_ transform: @escaping (T) throws -> LSPromise<U>) -> LSPromise<U> {
        let promise = LSPromise<U>()

        then { value in
            do {
                let transformed = try transform(value)
                transformed.then { promise.resolve($0) }
                transformed.catch { promise.reject($0) }
            } catch {
                promise.reject(error)
            }
        }

        catch { error in
            promise.reject(error)
        }

        return promise
    }

    /// 始终执行
    ///
    /// - Parameter handler: 闭包
    /// - Returns: self
    @discardableResult
    public func finally(_ handler: @escaping () -> Void) -> Self {
        switch state {
        case .fulfilled:
            handler()
        case .rejected:
            handler()
        case .pending:
            // 添加到两个处理器列表
            successHandlers.append { _ in handler() }
            failureHandlers.append { _ in handler() }
        }
        return self
    }
}

// MARK: - 便捷方法

public extension LSCoroutine {

    /// 延迟
    ///
    /// - Parameter seconds: 秒数
    /// - Returns: Promise
    static func sleep(seconds: TimeInterval) -> LSPromise<Void> {
        return LSPromise<Void> { resolve in
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                resolve(())
            }
        }
    }

    /// 获取主线程
    static var main: DispatchQueue {
        return .main
    }

    /// 获取全局队列
    ///
    /// - Parameter qos: 服务质量
    /// - Returns: DispatchQueue
    static func global(qos: DispatchQoS = .default) -> DispatchQueue {
        return .global(qos: qos)
    }
}

#endif

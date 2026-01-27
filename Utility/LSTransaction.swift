//
//  LSTransaction.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  事务集合 - 在当前 runloop 睡眠前执行一次选择器
//

#if canImport(UIKit)
import UIKit
import Foundation
import CoreFoundation

/// LSTransaction 让你在当前 runloop 睡眠前执行一次选择器
///
/// 这个类用于将操作延迟到当前 runloop 循环结束前执行，
/// 可以用于批处理 UI 更新等场景。
public class LSTransaction: NSObject {

    // MARK: - 属性

    private var target: AnyObject?
    private var selector: Selector?

    // MARK: - 静态属性

    private static var transactionSet: Set<LSTransaction> = []
    private static let lock = NSLock()

    // MARK: - 类方法

    /// 创建带有指定目标和选择器的事务
    ///
    /// - Parameters:
    ///   - target: 目标对象
    ///   - selector: 选择器
    /// - Returns: 新的事务，出错返回 nil
    public static func transaction(withTarget target: AnyObject, selector: Selector) -> LSTransaction? {
        guard target != nil && selector != nil else { return nil }

        let transaction = LSTransaction()
        transaction.target = target
        transaction.selector = selector
        return transaction
    }

    // MARK: - 初始化

    private override init() {
        super.init()
    }

    // MARK: - 公共方法

    /// 提交事务到主 runloop
    ///
    /// - Discussion: 将在主 runloop 的当前循环睡眠前执行选择器。
    /// 如果相同的事务（相同的目标和选择器）已经在此循环中提交到 runloop，
    /// 则此方法不执行任何操作。
    public func commit() {
        guard target != nil && selector != nil else { return }

        Self.setupRunLoopObserver()

        lock.lock()
        defer { lock.unlock() }

        Self.transactionSet.insert(self)
    }

    // MARK: - 私有方法

    private static func setupRunLoopObserver() {
        struct Static {
            static var onceToken: Int = 0
        }

        DispatchQueue.once(token: &Static.onceToken) {
            let runloop = CFRunLoopGetMain()
            var observerContext = CFRunLoopObserverContext(
                version: 0,
                info: nil,
                retain: nil,
                release: nil,
                copyDescription: nil
            )

            let observer = CFRunLoopObserverCreate(
                kCFAllocatorDefault,
                CFRunLoopActivity.beforeWaiting.rawValue | CFRunLoopActivity.exit.rawValue,
                true,      // repeat
                0xFFFFFF,  // after CATransaction(2000000)
                { (_, _, _) in
                    LSTransaction.runLoopObserverCallback()
                },
                &observerContext
            )

            CFRunLoopAddObserver(runloop, observer, CFRunLoopMode.commonModes)
        }
    }

    private static func runLoopObserverCallback() {
        lock.lock()
        let currentSet = transactionSet
        transactionSet.removeAll()
        lock.unlock()

        guard !currentSet.isEmpty else { return }

        for transaction in currentSet {
            guard let target = transaction.target,
                  let selector = transaction.selector else { continue }

            // 使用 performSelector 在主线程执行
            // swiftlint:disable:next prohibited_interface_builder
            _ = target.perform(selector)
        }
    }
}

// MARK: - Hashable

extension LSTransaction: Hashable {
    public func hash(into hasher: inout Hasher) {
        let selectorPtr = UnsafeRawPointer(Unmanaged.passUnretained(selector as AnyObject).toOpaque())
        let targetPtr = Unmanaged.passUnretained(target as AnyObject).toOpaque()

        hasher.combine(bitPattern: Int64(Int(bitPattern: selectorPtr)))
        hasher.combine(bitPattern: Int64(Int(bitPattern: targetPtr)))
    }

    public static func == (lhs: LSTransaction, rhs: LSTransaction) -> Bool {
        return lhs.selector == rhs.selector && lhs.target === rhs.target
    }
}

// MARK: - DispatchQueue Extension

private extension DispatchQueue {
    static func once(token: UnsafeMutablePointer<Int>, block: () -> Void) {
        struct Token { }
        let tokenKey = UnsafeRawPointer(token)

        objc_sync_enter(tokenKey)
        defer { objc_sync_exit(tokenKey) }

        if token.pointee == 0 {
            token.pointee = 1
            block()
        }
    }
}
#endif

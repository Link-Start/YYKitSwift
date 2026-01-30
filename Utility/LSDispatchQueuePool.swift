//
//  LSDispatchQueuePool.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  队列池 - 持有多个串行队列
//

#if canImport(UIKit)
import UIKit
import Foundation
import Dispatch

/// LSDispatchQueuePool 持有多个串行队列
///
/// 使用此类来控制队列的线程数（而不是并发队列）
public class LSDispatchQueuePool: NSObject {

    // MARK: - 常量

    private static let maxQueueCount = 32

    // MARK: - 属性

    /// 池名称
    public private(set) var name: String?

    private var context: DispatchContext?

    // MARK: - 初始化

    /// 使用指定的名称、队列数量和服务质量创建队列池
    ///
    /// - Parameters:
    ///   - name: 池名称
    ///   - queueCount: 最大队列数量，应在 (1, 32) 范围内
    ///   - qos: 队列服务质量 (QOS)
    /// - Returns: 新的池，出错返回 nil
    public init?(name: String?, queueCount: UInt, qos: DispatchQoS.QoSClass) {
        guard queueCount > 0 && queueCount <= Self.maxQueueCount else { return nil }
        super.init()

        self.name = name
        self.context = DispatchContext(name: name, queueCount: Int(queueCount), qos: qos)
    }

    // MARK: - 公共方法

    /// 从池中获取串行队列
    ///
    /// - Returns: 串行队列
    public func queue() -> DispatchQueue {
        guard let context = context else {
            return DispatchQueue.main
        }
        return context.queue()
    }

    /// 获取指定 QOS 的默认池
    ///
    /// - Parameter qos: 服务质量
    /// - Returns: 队列池
    public static func defaultPool(for qos: DispatchQoS.QoSClass) -> LSDispatchQueuePool {
        switch qos {
        case .userInteractive:
            struct Static { static let pool = LSDispatchQueuePool(name: "xiaoyueyun.user-interactive", queueCount: processorCount, qos: qos) }
            return Static.pool!
        case .userInitiated:
            struct Static { static let pool = LSDispatchQueuePool(name: "xiaoyueyun.user-initiated", queueCount: processorCount, qos: qos) }
            return Static.pool!
        case .utility:
            struct Static { static let pool = LSDispatchQueuePool(name: "xiaoyueyun.utility", queueCount: processorCount, qos: qos) }
            return Static.pool!
        case .background:
            struct Static { static let pool = LSDispatchQueuePool(name: "xiaoyueyun.background", queueCount: processorCount, qos: qos) }
            return Static.pool!
        default:
            struct Static { static let pool = LSDispatchQueuePool(name: "xiaoyueyun.default", queueCount: processorCount, qos: qos) }
            return Static.pool!
        }
    }

    // MARK: - 全局函数

    /// 从全局队列池获取指定 QOS 的串行队列
    ///
    /// - Parameter qos: 服务质量
    /// - Returns: 串行队列
    public static func queue(for qos: DispatchQoS.QoSClass) -> DispatchQueue {
        return defaultPool(for: qos).queue()
    }

    // MARK: - 私有属性

    private static var processorCount: UInt {
        let count = ProcessInfo.processInfo.activeProcessorCount
        return count < 1 ? 1 : (count > maxQueueCount ? maxQueueCount : UInt(count))
    }
}

// MARK: - DispatchContext

private class DispatchContext {

    private var queues: [DispatchQueue] = []
    private var queueCount: Int = 0
    private var counter = Int32(0)
    private let lock = NSLock()

    init?(name: String?, queueCount: Int, qos: DispatchQoS.QoSClass) {
        guard queueCount > 0 && queueCount <= LSDispatchQueuePool.maxQueueCount else { return nil }

        self.queueCount = queueCount

        let queueLabel: String
        if let n = name {
            queueLabel = n
        } else {
            queueLabel = "com.xiaoyueyun.yykitswift"
        }

        // 创建队列
        for i in 0..<queueCount {
            let label = "\(queueLabel).\(i)"
            let attr: DispatchQueue.Attributes

            if #available(iOS 8.0, *) {
                attr = .serial
            } else {
                attr = []
            }

            let queue = DispatchQueue(label: label, qos: qos, attributes: attr, target: nil)
            queues.append(queue)
        }
    }

    deinit {
        queues.removeAll()
    }

    func queue() -> DispatchQueue {
        lock.lock()
        defer { lock.unlock() }

        let index = Int(OSAtomicIncrement32(&counter)) % queueCount
        return queues[index]
    }
}

// MARK: - OSAtomic Compatibility

private func OSAtomicIncrement32(_ value: UnsafeMutablePointer<Int32>) -> Int32 {
    return OSAtomicIncrement32(value)
}
#endif

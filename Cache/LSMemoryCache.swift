//
//  LSMemoryCache.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  快速内存缓存 - 存储键值对
//

#if canImport(UIKit)
import UIKit
import Foundation

/// LSMemoryCache 是存储键值对的快速内存缓存
///
/// 与 NSDictionary 不同，键被保留而不是复制。
/// API 和性能与 `NSCache` 类似，所有方法都是线程安全的。
///
/// LSMemoryCache 与 NSCache 的不同之处：
/// - 使用 LRU (最近最少使用) 移除对象；NSCache 的回收方法是不确定的
/// - 可以通过成本、数量和年龄控制；NSCache 的限制不精确
/// - 可以配置为在收到内存警告或应用进入后台时自动收回对象
///
/// - Note: 此类使用 NSLock 保护内部状态，在 Swift 6 严格并发模式下
///         使用 @unchecked Sendable 表示手动实现了线程安全。
public final class LSMemoryCache: NSObject, @unchecked Sendable {

    // MARK: - 缓存节点

    private class LinkedNode: NSObject {
        let key: AnyObject
        var value: AnyObject
        var cost: UInt
        var time: TimeInterval
        var prev: LinkedNode?
        var next: LinkedNode?

        init(key: AnyObject, value: AnyObject, cost: UInt) {
            self.key = key
            self.value = value
            self.cost = cost
            self.time = CACurrentMediaTime()
            super.init()
        }
    }

    // MARK: - 属性

    /// 缓存名称
    public var name: String?

    /// 缓存中的对象数量（只读）
    public private(set) var totalCount: UInt = 0

    /// 缓存中对象的总成本（只读）
    public private(set) var totalCost: UInt = 0

    // MARK: - 限制

    /// 缓存应保存的最大对象数量
    /// 默认是 UInt.max，表示无限制
    public var countLimit: UInt = UInt.max

    /// 缓存在开始收回对象之前可以保存的最大总成本
    /// 默认是 UInt.max，表示无限制
    public var costLimit: UInt = UInt.max

    /// 缓存中对象的最大过期时间
    /// 默认是 TimeInterval.greatestFiniteMagnitude，表示无限制
    public var ageLimit: TimeInterval = TimeInterval.greatestFiniteMagnitude

    /// 自动修剪检查时间间隔（秒），默认是 5.0
    public var autoTrimInterval: TimeInterval = 5.0 {
        didSet {
            setupAutoTrimTimer()
        }
    }

    /// 是否在收到内存警告时移除所有对象
    public var shouldRemoveAllObjectsOnMemoryWarning = true

    /// 是否在进入后台时移除所有对象
    public var shouldRemoveAllObjectsWhenEnteringBackground = true

    /// 收到内存警告时执行的块
    public var didReceiveMemoryWarningBlock: (@Sendable (LSMemoryCache) -> Void)?

    /// 进入后台时执行的块
    public var didEnterBackgroundBlock: (@Sendable (LSMemoryCache) -> Void)?

    /// 键值对是否在主线程释放，默认是 NO
    public var releaseOnMainThread = false

    /// 键值对是否异步释放以避免阻塞访问方法，默认是 YES
    public var releaseAsynchronously = true

    // MARK: - 内部属性

    private var dictionary: [String: LinkedNode] = [:]
    private var dllHead: LinkedNode?
    private var dllTail: LinkedNode?
    private let lock = NSLock()
    private var trimTimer: Timer?

    // MARK: - 初始化

    public override init() {
        super.init()
        commonInit()
    }

    public init(name: String?) {
        self.name = name
        super.init()
        commonInit()
    }

    private func commonInit() {
        // 监听内存警告
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )

        // 监听进入后台
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        setupAutoTrimTimer()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        trimTimer?.invalidate()
        removeAllObjects()
    }

    // MARK: - 访问方法

    /// 返回给定键是否在缓存中
    ///
    /// - Parameter key: 标识值的对象，如果为 nil 返回 NO
    /// - Returns: 键是否在缓存中
    public func containsObject(forKey key: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard let key = key as AnyObject? else { return false }
        return dictionary[key.description] != nil
    }

    /// 返回与给定键关联的值
    ///
    /// - Parameter key: 标识值的对象，如果为 nil 返回 nil
    /// - Returns: 与键关联的值，如果没有与键关联的值返回 nil
    public func objectForKey(_ key: String) -> Any? {
        lock.lock()
        defer { lock.unlock() }

        guard let key = key as AnyObject? else { return nil }
        guard let node = dictionary[key.description] else { return nil }

        // 更新访问时间并移到链表头部
        node.time = CACurrentMediaTime()
        bringToFront(node)

        return node.value
    }

    /// 设置缓存中指定键的值（成本为 0）
    ///
    /// - Parameters:
    ///   - object: 要存储在缓存中的对象，如果为 nil 调用 `removeObjectForKey`
    ///   - key: 与值关联的键，如果为 nil 此方法无效
    public func setObject(_ object: Any?, forKey key: String) {
        setObject(object, forKey: key, withCost: 0)
    }

    /// 设置缓存中指定键的值，并将键值对与指定成本关联
    ///
    /// - Parameters:
    ///   - object: 要存储在缓存中的对象，如果为 nil 调用 `removeObjectForKey`
    ///   - key: 与值关联的键，如果为 nil 此方法无效
    ///   - cost: 与键值对关联的成本
    public func setObject(_ object: Any?, forKey key: String, withCost cost: UInt) {
        guard let key = key as AnyObject? else { return }

        if let obj = object {
            setObject(obj as AnyObject, forKey: key.description, withCost: cost)
        } else {
            removeObject(forKey: key)
        }
    }

    /// 移除缓存中指定键的值
    ///
    /// - Parameter key: 标识要移除的值的键，如果为 nil 此方法无效
    public func removeObject(forKey key: String) {
        guard let key = key as AnyObject? else { return }

        lock.lock()

        guard let node = dictionary[key.description] else {
            lock.unlock()
            return
        }

        removeNode(node)
        dictionary.removeValue(forKey: key.description)

        lock.unlock()
    }

    /// 立即清空缓存
    public func removeAllObjects() {
        lock.lock()
        dictionary.removeAll()
        dllHead = nil
        dllTail = nil
        totalCount = 0
        totalCost = 0
        lock.unlock()
    }

    // MARK: - 修剪

    /// 使用 LRU 从缓存移除对象，直到 `totalCount` 低于或等于指定值
    ///
    /// - Parameter count: 缓存修剪后允许保留的总数
    public func trimToCount(_ count: UInt) {
        lock.lock()
        defer { lock.unlock() }

        guard count < UInt.max else { return }

        while totalCount > count {
            guard let node = dllTail else { break }
            removeNode(node)
            if let key = node.key as? String {
                dictionary.removeValue(forKey: key)
            }
        }
    }

    /// 使用 LRU 从缓存移除对象，直到 `totalCost` 低于或等于指定值
    ///
    /// - Parameter cost: 缓存修剪后允许保留的总成本
    public func trimToCost(_ cost: UInt) {
        lock.lock()
        defer { lock.unlock() }

        guard cost < UInt.max else { return }

        while totalCost > cost {
            guard let node = dllTail else { break }
            removeNode(node)
            if let key = node.key as? String {
                dictionary.removeValue(forKey: key)
            }
        }
    }

    /// 使用 LRU 从缓存移除对象，直到移除所有过期对象
    ///
    /// - Parameter age: 对象的最大年龄（秒）
    public func trimToAge(_ age: TimeInterval) {
        lock.lock()
        defer { lock.unlock() }

        guard age > 0 else { return }

        let now = CACurrentMediaTime()

        while let node = dllTail {
            if now - node.time <= age {
                break
            }
            removeNode(node)
            if let key = node.key as? String {
                dictionary.removeValue(forKey: key)
            }
        }
    }

    // MARK: - 内存警告处理

    @objc private func didReceiveMemoryWarning() {
        if shouldRemoveAllObjectsOnMemoryWarning {
            removeAllObjects()
        }

        didReceiveMemoryWarningBlock?(self)
    }

    @objc private func didEnterBackground() {
        if shouldRemoveAllObjectsWhenEnteringBackground {
            removeAllObjects()
        }

        didEnterBackgroundBlock?(self)
    }

    // MARK: - 私有方法

    private func insertNodeAtFront(_ node: LinkedNode) {
        if dllHead === node {
            return
        }

        if dllHead == nil {
            dllHead = node
            dllTail = node
            node.prev = nil
            node.next = nil
        } else {
            node.next = dllHead
            node.prev = nil
            dllHead?.prev = node
            dllHead = node
        }
    }

    private func bringToFront(_ node: LinkedNode) {
        if dllHead === node {
            return
        }

        // 从当前位置移除
        if let prev = node.prev {
            prev.next = node.next
        }
        if let next = node.next {
            next.prev = node.prev
        }
        if dllTail === node {
            dllTail = node.prev
        }

        // 插入到前面
        node.prev = nil
        node.next = dllHead
        dllHead?.prev = node
        dllHead = node

        if dllTail == nil {
            dllTail = node
        }
    }

    private func removeNode(_ node: LinkedNode) {
        if let prev = node.prev {
            prev.next = node.next
        }
        if let next = node.next {
            next.prev = node.prev
        }
        if dllHead === node {
            dllHead = node.next
        }
        if dllTail === node {
            dllTail = node.prev
        }

        totalCount -= 1
        totalCost -= node.cost
    }

    private func setupAutoTrimTimer() {
        trimTimer?.invalidate()

        if autoTrimInterval > 0 {
            trimTimer = Timer.scheduledTimer(withTimeInterval: autoTrimInterval, repeats: true) { [weak self] _ in
                self?.trimToCountLimitIfNeeded()
                self?.trimToCostLimitIfNeeded()
                self?.trimToAgeLimitIfNeeded()
            }
        }
    }

    private func trimToCountLimitIfNeeded() {
        guard countLimit < UInt.max else { return }

        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.trimToCount(self?.countLimit ?? UInt.max)
        }
    }

    private func trimToCostLimitIfNeeded() {
        guard costLimit < UInt.max else { return }

        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.trimToCost(self?.costLimit ?? UInt.max)
        }
    }

    private func trimToAgeLimitIfNeeded() {
        guard ageLimit < TimeInterval.greatestFiniteMagnitude else { return }

        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.trimToAge(self?.ageLimit ?? TimeInterval.greatestFiniteMagnitude)
        }
    }
}

// MARK: - NSObject 扩展

private extension NSObject {
    var ls_description: String {
        return String(format: "<%@: %p>", type(of: self), self)
    }
}
#endif

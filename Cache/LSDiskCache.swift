//
//  LSDiskCache.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  线程安全的磁盘缓存，基于 SQLite 和文件系统
//

#if canImport(UIKit)
import UIKit
import Foundation

/// LSDiskCache 是线程安全缓存，用于存储基于 SQLite 和文件系统的键值对
///
/// 特性:
/// - 使用 LRU (最近最少使用) 移除对象
/// - 可以通过成本、数量和年龄控制
/// - 可以配置为在没有可用磁盘空间时自动收回对象
/// - 可以自动决定每个对象的存储类型 (sqlite/file) 以获得更好的性能
///
/// - Note: 此类使用 NSLock 保护内部状态，在 Swift 6 严格并发模式下
///         使用 @unchecked Sendable 表示手动实现了线程安全。
public final class LSDiskCache: NSObject, @unchecked Sendable {

    // MARK: - 关联对象键

    private static var extendedDataKey: UInt8 = 0

    // MARK: - 属性

    /// 缓存名称
    public var name: String?

    /// 缓存路径（只读）
    public private(set) var path: String

    /// 内联阈值（只读）
    public private(set) var inlineThreshold: UInt

    /// 自定义归档块
    public var customArchiveBlock: (@Sendable (Any) -> Data)?

    /// 自定义解档块
    public var customUnarchiveBlock: (@Sendable (Data) -> Any)?

    /// 自定义文件名块
    public var customFileNameBlock: (@Sendable (String) -> String)?

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

    /// 缓存应保留的最小可用磁盘空间（字节）
    /// 默认是 0，表示无限制
    public var freeDiskSpaceLimit: UInt = 0

    /// 自动修剪检查时间间隔（秒），默认是 60（1 分钟）
    public var autoTrimInterval: TimeInterval = 60 {
        didSet {
            setupAutoTrimTimer()
        }
    }

    /// 是否启用错误日志
    public var errorLogsEnabled = false

    // MARK: - 内部属性

    private var kvStorage: LSKVStorage?
    private var autoTrimTimer: Timer?

    // MARK: - 共享实例

    private static var sharedCaches: [String: LSDiskCache] = [:]
    private static let sharedCachesLock = NSLock()

    // MARK: - 初始化

    /// 使用指定路径创建新缓存
    ///
    /// - Parameter path: 缓存写入数据的目录完整路径
    /// - Returns: 新的缓存对象，如果出错返回 nil
    public convenience init?(path: String) {
        self.init(path: path, inlineThreshold: 20480)  // 20KB
    }

    /// 使用指定路径和内联阈值创建新缓存
    ///
    /// - Parameters:
    ///   - path: 缓存写入数据的目录完整路径
    ///   - inlineThreshold: 数据存储内联阈值（字节）
    /// - Returns: 新的缓存对象，如果出错返回 nil
    public init?(path: String, inlineThreshold: UInt) {
        self.path = path
        self.inlineThreshold = inlineThreshold

        super.init()

        guard let storage = LSKVStorage(path: path, type: .mixed) else {
            return nil
        }

        self.kvStorage = storage
        setupAutoTrimTimer()
    }

    // MARK: - 访问方法

    /// 返回给定键是否在缓存中
    /// 此方法可能会阻塞调用线程直到文件读取完成
    ///
    /// - Parameter key: 标识值的字符串，如果为 nil 返回 NO
    /// - Returns: 键是否在缓存中
    public func containsObject(forKey key: String) -> Bool {
        guard !key.isEmpty else { return false }
        return kvStorage?.itemExists(forKey: key) ?? false
    }

    /// 返回给定键是否在缓存中（异步）
    /// 此方法立即返回并在后台队列调用完成块
    ///
    /// - Parameters:
    ///   - key: 标识值的字符串
    ///   - block: 完成时在后台队列调用的块
    public func containsObject(forKey key: String, withBlock block: ((String, Bool) -> Void)?) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                block?(key, false)
                return
            }

            let contains = self.containsObject(forKey: key)
            block?(key, contains)
        }
    }

    /// 返回与给定键关联的值
    /// 此方法可能会阻塞调用线程直到文件读取完成
    ///
    /// - Parameter key: 标识值的字符串，如果为 nil 返回 nil
    /// - Returns: 与键关联的值，如果没有与键关联的值返回 nil
    public func objectForKey(_ key: String) -> Any? {
        guard !key.isEmpty else { return nil }

        guard let item = kvStorage?.getItem(forKey: key) else {
            return nil
        }

        return decodeObject(from: item)
    }

    /// 返回与给定键关联的值（异步）
    /// 此方法立即返回并在后台队列调用完成块
    ///
    /// - Parameters:
    ///   - key: 标识值的字符串
    ///   - block: 完成时在后台队列调用的块
    public func objectForKey(_ key: String, withBlock block: ((String, Any?) -> Void)?) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                block?(key, nil)
                return
            }

            let object = self.objectForKey(key)
            block?(key, object)
        }
    }

    /// 设置缓存中指定键的值
    /// 此方法可能会阻塞调用线程直到文件写入完成
    ///
    /// - Parameters:
    ///   - object: 要存储在缓存中的对象，如果为 nil 调用 `removeObjectForKey`
    ///   - key: 与值关联的键，如果为 nil 此方法无效
    public func setObject(_ object: Any?, forKey key: String) {
        guard !key.isEmpty else { return }

        if let obj = object {
            saveObject(obj, forKey: key)
        } else {
            removeObject(forKey: key)
        }
    }

    /// 设置缓存中指定键的值（异步）
    /// 此方法立即返回并在后台队列调用完成块
    ///
    /// - Parameters:
    ///   - object: 要存储在缓存中的对象
    ///   - key: 与值关联的键
    ///   - block: 完成时在后台队列调用的块
    public func setObject(_ object: Any?, forKey key: String, withBlock block: (() -> Void)?) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.setObject(object, forKey: key)
            block?()
        }
    }

    /// 移除缓存中指定键的值
    /// 此方法可能会阻塞调用线程直到文件删除完成
    ///
    /// - Parameter key: 标识要移除的值的键，如果为 nil 此方法无效
    public func removeObject(forKey key: String) {
        guard !key.isEmpty else { return }
        kvStorage?.removeItem(forKey: key)
    }

    /// 移除缓存中指定键的值（异步）
    /// 此方法立即返回并在后台队列调用完成块
    ///
    /// - Parameters:
    ///   - key: 标识要移除的值的键
    ///   - block: 完成时在后台队列调用的块
    public func removeObject(forKey key: String, withBlock block: ((String) -> Void)?) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.removeObject(forKey: key)
            block?(key)
        }
    }

    /// 清空缓存
    /// 此方法可能会阻塞调用线程直到文件删除完成
    public func removeAllObjects() {
        kvStorage?.removeAllItems()
    }

    /// 清空缓存（异步）
    /// 此方法立即返回并在后台队列执行清理操作
    ///
    /// - Parameter block: 完成时在后台队列调用的块
    public func removeAllObjects(withBlock block: (() -> Void)?) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.removeAllObjects()
            block?()
        }
    }

    /// 返回缓存中的对象数量
    /// 此方法可能会阻塞调用线程直到文件读取完成
    ///
    /// - Returns: 总对象数量
    public var totalCount: Int {
        return kvStorage?.getItemsCount() ?? 0
    }

    /// 获取缓存中的对象数量（异步）
    /// 此方法立即返回并在后台队列调用完成块
    ///
    /// - Parameter block: 完成时在后台队列调用的块
    public func totalCount(withBlock block: ((Int) -> Void)?) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let count = self?.totalCount ?? 0
            block?(count)
        }
    }

    /// 返回缓存中对象的总成本（字节）
    /// 此方法可能会阻塞调用线程直到文件读取完成
    ///
    /// - Returns: 对象的总成本（字节）
    public var totalCost: Int {
        return kvStorage?.getItemsSize() ?? 0
    }

    /// 获取缓存中对象的总成本（异步）
    /// 此方法立即返回并在后台队列调用完成块
    ///
    /// - Parameter block: 完成时在后台队列调用的块
    public func totalCost(withBlock block: ((Int) -> Void)?) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let cost = self?.totalCost ?? 0
            block?(cost)
        }
    }

    // MARK: - 修剪

    /// 使用 LRU 从缓存移除对象，直到 `totalCount` 低于指定值
    /// 此方法可能会阻塞调用线程直到操作完成
    ///
    /// - Parameter count: 缓存修剪后允许保留的总数
    public func trimToCount(_ count: UInt) {
        kvStorage?.removeItemsToFitCount(Int(count))
    }

    /// 使用 LRU 从缓存移除对象，直到 `totalCount` 低于指定值（异步）
    /// 此方法立即返回并在后台队列调用完成块
    ///
    /// - Parameters:
    ///   - count: 缓存修剪后允许保留的总数
    ///   - block: 完成时在后台队列调用的块
    public func trimToCount(_ count: UInt, withBlock block: (() -> Void)?) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.trimToCount(count)
            block?()
        }
    }

    /// 使用 LRU 从缓存移除对象，直到 `totalCost` 低于指定值
    /// 此方法可能会阻塞调用线程直到操作完成
    ///
    /// - Parameter cost: 缓存修剪后允许保留的总成本
    public func trimToCost(_ cost: UInt) {
        kvStorage?.removeItemsToFitSize(Int(cost))
    }

    /// 使用 LRU 从缓存移除对象，直到 `totalCost` 低于指定值（异步）
    /// 此方法立即返回并在后台队列调用完成块
    ///
    /// - Parameters:
    ///   - cost: 缓存修剪后允许保留的总成本
    ///   - block: 完成时在后台队列调用的块
    public func trimToCost(_ cost: UInt, withBlock block: (() -> Void)?) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.trimToCost(cost)
            block?()
        }
    }

    /// 使用 LRU 从缓存移除对象，直到移除所有过期对象
    /// 此方法可能会阻塞调用线程直到操作完成
    ///
    /// - Parameter age: 对象的最大年龄
    public func trimToAge(_ age: TimeInterval) {
        let time = Int(Date().timeIntervalSince1970 - age)
        kvStorage?.removeItems(earlierThan: time)
    }

    /// 使用 LRU 从缓存移除对象，直到移除所有过期对象（异步）
    /// 此方法立即返回并在后台队列调用完成块
    ///
    /// - Parameters:
    ///   - age: 对象的最大年龄
    ///   - block: 完成时在后台队列调用的块
    public func trimToAge(_ age: TimeInterval, withBlock block: (() -> Void)?) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.trimToAge(age)
            block?()
        }
    }

    // MARK: - 扩展数据

    /// 从对象获取扩展数据
    ///
    /// - Parameter object: 对象
    /// - Returns: 扩展数据
    public static func getExtendedData(from object: Any) -> Data? {
        return objc_getAssociatedObject(object, &extendedDataKey) as? Data
    }

    /// 为对象设置扩展数据
    ///
    /// - Parameters:
    ///   - extendedData: 扩展数据（传 nil 移除）
    ///   - object: 对象
    public static func setExtendedData(_ extendedData: Data?, to object: Any) {
        objc_setAssociatedObject(object, &extendedDataKey, extendedData, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    // MARK: - 私有方法

    private func saveObject(_ object: Any, forKey key: String) -> Bool {
        // 编码对象
        guard let data = encodeObject(object) else {
            return false
        }

        // 获取扩展数据
        let extendedData = Self.getExtendedData(from: object)

        // 确定文件名
        let filename: String?
        if let customFileName = customFileNameBlock?(key) {
            filename = customFileName
        } else if data.count > inlineThreshold {
            filename = key.ls_md5()
        } else {
            filename = nil
        }

        let item = LSKVStorageItem()
        item.key = key
        item.value = data
        item.filename = filename
        item.extendedData = extendedData
        item.size = data.count
        item.modTime = Int(Date().timeIntervalSince1970)
        item.accessTime = Int(Date().timeIntervalSince1970)

        return kvStorage?.saveItem(item) ?? false
    }

    private func encodeObject(_ object: Any) -> Data? {
        // 使用自定义归档块
        if let customArchive = customArchiveBlock {
            return customArchive(object)
        }

        // 使用 NSKeyedArchiver
        if let nsCodingObject = object as? NSCoding {
            return try? NSKeyedArchiver.archivedData(withRootObject: nsCodingObject)
        }

        return nil
    }

    private func decodeObject(from item: LSKVStorageItem) -> Any? {
        guard let data = item.value else { return nil }

        // 使用自定义解档块
        if let customUnarchive = customUnarchiveBlock {
            return customUnarchive(data)
        }

        // 使用 NSKeyedUnarchiver
        return try? NSKeyedUnarchiver.unarchiveTopLevelObject(with: data) as? NSObject
    }

    private func setupAutoTrimTimer() {
        autoTrimTimer?.invalidate()

        if autoTrimInterval > 0 {
            autoTrimTimer = Timer.scheduledTimer(withTimeInterval: autoTrimInterval, repeats: true) { [weak self] _ in
                self?.trimToDiskSizeIfNeeded()
                self?.trimToCountLimitIfNeeded()
                self?.trimToAgeLimitIfNeeded()
            }
        }
    }

    private func trimToDiskSizeIfNeeded() {
        guard freeDiskSpaceLimit > 0 else { return }

        let freeSpace = getFreeDiskSpace()
        guard freeSpace >= 0 && freeSpace < freeDiskSpaceLimit else { return }

        // 清理一些空间
        let targetSize = max(0, Int(freeDiskSpaceLimit) - Int(freeSpace))
        trimToCost(UInt(targetSize))
    }

    private func trimToCountLimitIfNeeded() {
        guard countLimit < UInt.max else { return }

        let currentCount = totalCount
        guard currentCount > countLimit else { return }

        trimToCount(countLimit)
    }

    private func trimToAgeLimitIfNeeded() {
        guard ageLimit < TimeInterval.greatestFiniteMagnitude else { return }

        trimToAge(ageLimit)
    }

    private func getFreeDiskSpace() -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: path)
            if let freeSize = attributes[.systemFreeSize] as? Int64 {
                return freeSize
            }
        } catch {
            // 忽略错误
        }
        return -1
    }
}

// MARK: - String MD5 扩展

private extension String {
    func ls_md5() -> String {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        var digest = [UInt8](repeating: 0, count: length)

        if let data = self.data(using: .utf8) {
            _ = data.withUnsafeBytes { (body: UnsafeRawBufferPointer) in
                CC_MD5(body.baseAddress, CC_LONG(data.count), &digest)
            }
        }

        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
#endif

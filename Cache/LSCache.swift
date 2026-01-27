//
//  LSCache.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  线程安全的键值缓存 - 整合内存缓存和磁盘缓存
//

#if canImport(UIKit)
import UIKit
import Foundation

/// LSCache 是线程安全的键值缓存
///
/// 使用 `LSMemoryCache` 将对象存储在小型快速的内存缓存中，
/// 使用 `LSDiskCache` 将对象持久化到大型慢速磁盘缓存中。
public class LSCache: NSObject {

    // MARK: - 属性

    /// 缓存名称（只读）
    public private(set) var name: String

    /// 底层内存缓存
    public private(set) var memoryCache: LSMemoryCache

    /// 底层磁盘缓存
    public private(set) var diskCache: LSDiskCache

    // MARK: - 共享实例

    private static var sharedCaches: [String: LSCache] = [:]
    private static let sharedCachesLock = NSLock()

    // MARK: - 初始化

    /// 使用指定名称创建新实例
    ///
    /// 多个同名实例会使缓存不稳定
    ///
    /// - Parameter name: 缓存名称
    /// - Returns: 新的缓存对象，如果出错返回 nil
    public convenience init?(name: String) {
        guard let cachePath = cachePath(forName: name) else {
            return nil
        }
        self.init(path: cachePath)
        self.name = name
    }

    /// 使用指定路径创建新实例
    ///
    /// 多个同名实例会使缓存不稳定
    ///
    /// - Parameter path: 缓存写入数据的目录完整路径
    /// - Returns: 新的缓存对象，如果出错返回 nil
    public init?(path: String) {
        self.name = (path as NSString).lastPathComponent

        super.init()

        guard let memoryCache = LSMemoryCache(name: name) else {
            return nil
        }

        guard let diskCache = LSDiskCache(path: path) else {
            return nil
        }

        self.memoryCache = memoryCache
        self.diskCache = diskCache
    }

    /// 禁用默认初始化
    private override init() {
        self.name = ""
        self.memoryCache = LSMemoryCache()
        self.diskCache = LSDiskCache(path: "")!
        super.init()
    }

    // MARK: - 便利初始化器

    /// 使用指定名称创建新实例（静态方法）
    ///
    /// - Parameter name: 缓存名称
    /// - Returns: 新的缓存对象，如果出错返回 nil
    public static func cache(withName name: String) -> LSCache? {
        sharedCachesLock.lock()

        if let cache = sharedCaches[name] {
            sharedCachesLock.unlock()
            return cache
        }

        let cache = LSCache(name: name)
        if let cache = cache {
            sharedCaches[name] = cache
        }

        sharedCachesLock.unlock()

        return cache
    }

    /// 使用指定路径创建新实例（静态方法）
    ///
    /// - Parameter path: 缓存写入数据的目录完整路径
    /// - Returns: 新的缓存对象，如果出错返回 nil
    public static func cache(withPath path: String) -> LSCache? {
        return LSCache(path: path)
    }

    // MARK: - 访问方法

    /// 返回给定键是否在缓存中
    /// 此方法可能会阻塞调用线程直到文件读取完成
    ///
    /// - Parameter key: 标识值的字符串，如果为 nil 返回 NO
    /// - Returns: 键是否在缓存中
    public func containsObject(forKey key: String) -> Bool {
        guard !key.isEmpty else { return false }

        // 先检查内存缓存
        if memoryCache.containsObject(forKey: key) {
            return true
        }

        // 再检查磁盘缓存
        return diskCache.containsObject(forKey: key)
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

        // 先从内存缓存获取
        if let object = memoryCache.objectForKey(key) {
            return object
        }

        // 再从磁盘缓存获取
        if let object = diskCache.objectForKey(key) {
            // 存入内存缓存
            memoryCache.setObject(object, forKey: key)
            return object
        }

        return nil
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
            // 存入内存缓存
            memoryCache.setObject(obj, forKey: key)

            // 异步存入磁盘缓存
            diskCache.setObject(obj, forKey: key, withBlock: nil)
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
        // 同步更新内存缓存
        setObject(object, forKey: key)

        // 异步更新磁盘缓存
        diskCache.setObject(object, forKey: key, withBlock: block)
    }

    /// 移除缓存中指定键的值
    /// 此方法可能会阻塞调用线程直到文件删除完成
    ///
    /// - Parameter key: 标识要移除的值的键，如果为 nil 此方法无效
    public func removeObject(forKey key: String) {
        guard !key.isEmpty else { return }

        memoryCache.removeObject(forKey: key)
        diskCache.removeObject(forKey: key, withBlock: nil)
    }

    /// 移除缓存中指定键的值（异步）
    /// 此方法立即返回并在后台队列调用完成块
    ///
    /// - Parameters:
    ///   - key: 标识要移除的值的键
    ///   - block: 完成时在后台队列调用的块
    public func removeObject(forKey key: String, withBlock block: ((String) -> Void)?) {
        memoryCache.removeObject(forKey: key)
        diskCache.removeObject(forKey: key, withBlock: block)
    }

    /// 清空缓存
    /// 此方法可能会阻塞调用线程直到文件删除完成
    public func removeAllObjects() {
        memoryCache.removeAllObjects()
        diskCache.removeAllObjects()
    }

    /// 清空缓存（异步）
    /// 此方法立即返回并在后台队列调用完成块
    ///
    /// - Parameter block: 完成时在后台队列调用的块
    public func removeAllObjects(withBlock block: (() -> Void)?) {
        memoryCache.removeAllObjects()
        diskCache.removeAllObjects(withBlock: block)
    }

    /// 使用进度块和结束块清空缓存
    /// 此方法立即返回并在后台执行清理操作
    ///
    /// - Parameters:
    ///   - progress: 删除期间调用的块，传 nil 忽略
    ///   - end: 结束时调用的块，传 nil 忽略
    public func removeAllObjects(
        progress: ((Int, Int) -> Void)?,
        end: ((Bool) -> Void)?
    ) {
        memoryCache.removeAllObjects()

        let totalCount = diskCache.totalCount

        // 使用进度和结束块调用磁盘清理
        diskCache.removeAllObjects(withBlock: {
            end?(true)
        })
    }

    // MARK: - 私有方法

    private func cachePath(forName name: String) -> String? {
        let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        let path = (cachePath as NSString).appendingPathComponent(name)
        return path
    }
}
#endif

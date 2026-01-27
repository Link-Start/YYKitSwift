//
//  LSThreadSafeDictionary.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  线程安全字典 - 简单的线程安全可变字典实现
//

#if canImport(UIKit)
import UIKit
import Foundation

/// LSThreadSafeDictionary 是线程安全可变字典的简单实现
///
/// - Discussion: 访问性能通常低于 NSMutableDictionary，但高于使用 @synchronized、NSLock 或 pthread_mutex_t
/// - Warning: 快速枚举(for..in)和枚举器不是线程安全的，请使用基于 block 的枚举方法
///
/// - Note: 此类使用 DispatchSemaphore 保护内部状态，在 Swift 6 严格并发模式下
///         使用 @unchecked Sendable 表示手动实现了线程安全。
@unchecked Sendable
public class LSThreadSafeDictionary<Key: Hashable, Value>: NSObject {

    // MARK: - 属性

    private var dictionary: NSMutableDictionary = NSMutableDictionary()
    private let lock = DispatchSemaphore(value: 1)

    // MARK: - 初始化

    public override init() {
        super.init()
    }

    public init(dictionary: [Key: Value]) {
        super.init()
        for (key, value) in dictionary {
            self.dictionary.setObject(value as AnyObject, forKey: key as AnyObject)
        }
    }

    // MARK: - 属性访问

    /// 字典键数量
    public var count: Int {
        lock.wait()
        defer { lock.signal() }
        return dictionary.count
    }

    /// 所有键
    public var keys: [Key] {
        lock.wait()
        defer { lock.signal() }
        return dictionary.allKeys as! [Key]
    }

    /// 所有值
    public var values: [Value] {
        lock.wait()
        defer { lock.signal() }
        return dictionary.allValues as! [Value]
    }

    // MARK: - 访问方法

    /// 获取指定键的值
    public func object(forKey key: Key) -> Value? {
        lock.wait()
        defer { lock.signal() }
        return dictionary.object(forKey: key as AnyObject) as? Value
    }

    /// 下标访问
    public subscript(key: Key) -> Value? {
        get {
            return object(forKey: key)
        }
        set {
            if let value = newValue {
                set(value, forKey: key)
            } else {
                removeObject(forKey: key)
            }
        }
    }

    /// 检查是否包含指定键
    public func contains(key: Key) -> Bool {
        lock.wait()
        defer { lock.signal() }
        return dictionary.object(forKey: key as AnyObject) != nil
    }

    // MARK: - 修改方法

    /// 设置指定键的值
    public func set(_ value: Value, forKey key: Key) {
        lock.wait()
        defer { lock.signal() }
        dictionary.setObject(value as AnyObject, forKey: key as AnyObject)
    }

    /// 移除指定键的值
    public func removeObject(forKey key: Key) {
        lock.wait()
        defer { lock.signal() }
        dictionary.removeObject(forKey: key as AnyObject)
    }

    /// 移除所有对象
    public func removeAllObjects() {
        lock.wait()
        defer { lock.signal() }
        dictionary.removeAllObjects()
    }

    /// 添加另一个字典中的所有键值对
    public func addEntries(from dictionary: [Key: Value]) {
        lock.wait()
        defer { lock.signal() }
        for (key, value) in dictionary {
            self.dictionary.setObject(value as AnyObject, forKey: key as AnyObject)
        }
    }

    // MARK: - 枚举方法

    /// 使用 block 枚举键值对
    public func enumerateKeysAndObjects(_ block: (Key, Value, UnsafeMutablePointer<Bool>) -> Void) {
        lock.wait()
        defer { lock.signal() }
        dictionary.enumerateKeysAndObjects { key, value, stop in
            if let key = key as? Key, let value = value as? Value {
                block(key, value, stop)
            }
        }
    }

    /// 使用 block 枚举键和对象
    public func enumerateKeysAndObjects(options: NSEnumerationOptions = [], using block: (Key, Value, UnsafeMutablePointer<Bool>) -> Void) {
        lock.wait()
        defer { lock.signal() }
        dictionary.enumerateKeysAndObjects(options: options) { key, value, stop in
            if let key = key as? Key, let value = value as? Value {
                block(key, value, stop)
            }
        }
    }

    /// 获取指定键的值，如果不存在则返回默认值
    public func object(forKey key: Key, default defaultValue: Value) -> Value {
        lock.wait()
        defer { lock.signal() }
        return dictionary.object(forKey: key as AnyObject) as? Value ?? defaultValue
    }

    /// 弹出并移除指定键的值
    @discardableResult
    public func popObject(forKey key: Key) -> Value? {
        lock.wait()
        defer { lock.signal() }
        let value = dictionary.object(forKey: key as AnyObject) as? Value
        dictionary.removeObject(forKey: key as AnyObject)
        return value
    }

    /// 转换为 Swift 字典
    public func toDictionary() -> [Key: Value] {
        lock.wait()
        defer { lock.signal() }
        var result: [Key: Value] = [:]
        for (key, value) in dictionary {
            if let key = key as? Key, let value = value as? Value {
                result[key] = value
            }
        }
        return result
    }

    // MARK: - NSObject

    public override var description: String {
        lock.wait()
        defer { lock.signal() }
        return dictionary.description
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? LSThreadSafeDictionary<Key, Value> else { return false }
        if self === other { return true }

        lock.wait()
        other.lock.wait()
        defer {
            other.lock.signal()
            lock.signal()
        }
        return dictionary.isEqual(to: other.dictionary)
    }

    public override var hash: Int {
        lock.wait()
        defer { lock.signal() }
        return dictionary.hash
    }
}

// MARK: - ExpressibleByDictionaryLiteral

extension LSThreadSafeDictionary: ExpressibleByDictionaryLiteral {
    public convenience init(dictionaryLiteral elements: (Key, Value)...) {
        self.init()
        for (key, value) in elements {
            set(value, forKey: key)
        }
    }
}
#endif

//
//  LSThreadSafeArray.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  线程安全数组 - 简单的线程安全可变数组实现
//

#if canImport(UIKit)
import UIKit
import Foundation

/// LSThreadSafeArray 是线程安全可变数组的简单实现
///
/// - Discussion: 访问性能通常低于 NSMutableArray，但高于使用 @synchronized、NSLock 或 pthread_mutex_t
/// - Warning: 快速枚举(for..in)和枚举器不是线程安全的，请使用基于 block 的枚举方法
///
/// - Note: 此类使用 DispatchSemaphore 保护内部状态，在 Swift 6 严格并发模式下
///         使用 @unchecked Sendable 表示手动实现了线程安全。
public final class LSThreadSafeArray<Element>: NSObject, @unchecked Sendable {

    // MARK: - 属性

    private var array: NSMutableArray = NSMutableArray()
    private let lock = DispatchSemaphore(value: 1)

    // MARK: - 初始化

    public override init() {
        super.init()
    }

    public init(capacity: Int) {
        super.init()
        array = NSMutableArray(capacity: capacity)
    }

    public init(array: [Element]) {
        super.init()
        self.array = NSMutableArray(array: array)
    }

    // MARK: - 属性访问

    /// 数组元素数量
    public var count: Int {
        lock.wait()
        defer { lock.signal() }
        return array.count
    }

    /// 首个元素
    public var first: Element? {
        lock.wait()
        defer { lock.signal() }
        return array.firstObject as? Element
    }

    /// 最后一个元素
    public var last: Element? {
        lock.wait()
        defer { lock.signal() }
        return array.lastObject as? Element
    }

    // MARK: - 访问方法

    /// 获取指定索引的元素
    public func object(at index: Int) -> Element? {
        lock.wait()
        defer { lock.signal() }
        return array.object(at: index) as? Element
    }

    /// 数组下标访问
    public subscript(index: Int) -> Element? {
        return object(at: index)
    }

    /// 检查是否包含指定对象
    public func contains(_ object: Element) -> Bool {
        lock.wait()
        defer { lock.signal() }
        return array.contains(object)
    }

    /// 查找对象的索引
    public func index(of object: Element) -> Int {
        lock.wait()
        defer { lock.signal() }
        return array.index(of: object)
    }

    /// 查找对象在指定范围内的索引
    public func index(of object: Element, in range: NSRange) -> Int {
        lock.wait()
        defer { lock.signal() }
        return array.index(of: object, in: range)
    }

    // MARK: - 修改方法

    /// 添加对象
    public func add(_ object: Element) {
        lock.wait()
        defer { lock.signal() }
        array.add(object)
    }

    /// 在指定索引插入对象
    public func insert(_ object: Element, at index: Int) {
        lock.wait()
        defer { lock.signal() }
        array.insert(object, at: index)
    }

    /// 移除最后一个对象
    public func removeLast() {
        lock.wait()
        defer { lock.signal() }
        array.removeLastObject()
    }

    /// 移除第一个对象
    public func removeFirst() {
        lock.wait()
        defer { lock.signal() }
        if array.count > 0 {
            array.removeObject(at: 0)
        }
    }

    /// 移除指定索引的对象
    public func remove(at index: Int) {
        lock.wait()
        defer { lock.signal() }
        array.removeObject(at: index)
    }

    /// 替换指定索引的对象
    public func replace(at index: Int, with object: Element) {
        lock.wait()
        defer { lock.signal() }
        array.replaceObject(at: index, with: object)
    }

    /// 移除所有对象
    public func removeAll() {
        lock.wait()
        defer { lock.signal() }
        array.removeAllObjects()
    }

    /// 添加数组中的所有对象
    public func addObjects(from array: [Element]) {
        lock.wait()
        defer { lock.signal() }
        self.array.addObjects(from: array as [Any])
    }

    /// 交换两个索引位置的对象
    public func exchange(at idx1: Int, with idx2: Int) {
        lock.wait()
        defer { lock.signal() }
        array.exchangeObject(at: idx1, withObjectAt: idx2)
    }

    /// 弹出并返回第一个对象
    @discardableResult
    public func popFirst() -> Element? {
        lock.wait()
        defer { lock.signal() }
        if array.count > 0 {
            let obj = array.firstObject as? Element
            array.removeObject(at: 0)
            return obj
        }
        return nil
    }

    /// 弹出并返回最后一个对象
    @discardableResult
    public func popLast() -> Element? {
        lock.wait()
        defer { lock.signal() }
        if array.count > 0 {
            let obj = array.lastObject as? Element
            array.removeLastObject()
            return obj
        }
        return nil
    }

    // MARK: - 枚举方法

    /// 使用 block 枚举对象
    public func enumerate(_ block: (Element, Int, UnsafeMutablePointer<ObjCBool>) -> Void) {
        lock.wait()
        defer { lock.signal() }
        array.enumerateObjects { obj, idx, stop in
            if let element = obj as? Element {
                block(element, idx, stop)
            }
        }
    }

    /// 转换为 Swift 数组
    public func toArray() -> [Element] {
        lock.wait()
        defer { lock.signal() }
        return (array as NSArray) as? [Element] ?? []
    }

    // MARK: - NSObject

    public override var description: String {
        lock.wait()
        defer { lock.signal() }
        return array.description
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? LSThreadSafeArray<Element> else { return false }
        if self === other { return true }

        lock.wait()
        other.lock.wait()
        defer {
            other.lock.signal()
            lock.signal()
        }
        return array.isEqual(other.array)
    }

    public override var hash: Int {
        lock.wait()
        defer { lock.signal() }
        return array.hash
    }
}

// MARK: - ExpressibleByArrayLiteral

extension LSThreadSafeArray: ExpressibleByArrayLiteral {
    public convenience init(arrayLiteral elements: Element...) {
        self.init(array: elements)
    }
}
#endif

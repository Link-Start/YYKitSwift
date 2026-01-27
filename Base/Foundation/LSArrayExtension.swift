//
//  LSArrayExtension.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  数组扩展 - 提供常用的数组操作方法
//

#if canImport(UIKit)
import UIKit
import Foundation

// MARK: - Array Extension

public extension Array {

    // MARK: - 安全访问

    /// 安全获取元素
    ///
    /// - Parameter index: 索引
    /// - Returns: 元素值（如果索引有效）
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }

    /// 安全获取第一个元素
    var ls_first: Element? {
        return first
    }

    /// 安全获取最后一个元素
    var ls_last: Element? {
        return last
    }

    // MARK: - 随机访问

    /// 随机元素
    var ls_random: Element? {
        guard !isEmpty else { return nil }
        let randomIndex = Int.random(in: 0..<count)
        return self[randomIndex]
    }

    /// 随机多个不重复元素
    ///
    /// - Parameter count: 数量
    /// - Returns: 随机元素数组
    func ls_random(count: Int) -> [Element] {
        guard count > 0, !isEmpty else { return [] }

        let actualCount = min(count, self.count)
        var indices = Array(indices)
        var result: [Element] = []

        for _ in 0..<actualCount {
            let randomIndex = Int.random(in: 0..<indices.count)
            let index = indices.remove(at: randomIndex)
            result.append(self[index])
        }

        return result
    }

    // MARK: - 分组

    /// 分组数组
    ///
    /// - Parameter size: 每组大小
    /// - Returns: 分组后的二维数组
    func ls_chunked(size: Int) -> [[Element]] {
        guard size > 0 else { return [] }

        var result: [[Element]] = []
        var currentChunk: [Element] = []

        for element in self {
            currentChunk.append(element)

            if currentChunk.count == size {
                result.append(currentChunk)
                currentChunk = []
            }
        }

        if !currentChunk.isEmpty {
            result.append(currentChunk)
        }

        return result
    }

    // MARK: - 去重

    /// 去重（元素需遵循 Equatable）
    func ls_unique() -> [Element] where Element: Equatable {
        var result: [Element] = []
        for element in self {
            if !result.contains(element) {
                result.append(element)
            }
        }
        return result
    }

    /// 去重（基于 KeyPath）
    func ls_unique<T: Equatable>(keyPath: KeyPath<Element, T>) -> [Element] {
        var seenKeys: [T] = []
        var result: [Element] = []

        for element in self {
            let key = element[keyPath: keyPath]
            if !seenKeys.contains(key) {
                seenKeys.append(key)
                result.append(element)
            }
        }

        return result
    }

    // MARK: - 排序

    /// 按 KeyPath 升序排序
    func ls_sorted<T: Comparable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        return sorted { $0[keyPath: keyPath] < $1[keyPath: keyPath] }
    }

    /// 按 KeyPath 降序排序
    func ls_sortedDescending<T: Comparable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        return sorted { $0[keyPath: keyPath] > $1[keyPath: keyPath] }
    }

    // MARK: - 分组

    /// 按 KeyPath 分组
    func ls_grouped<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [T: [Element]] {
        return Dictionary(grouping: self) { $0[keyPath: keyPath] }
    }

    // MARK: - 过滤

    /// 过滤非空元素
    func ls_compactMap<T>() -> [T] where Element == T? {
        return compactMap { $0 }
    }

    /// 过滤非 nil 元素
    func ls_filterNotNil<T>() -> [T] where Element == T? {
        return compactMap { $0 }
    }

    // MARK: - 转换

    /// 转换为字典（基于 KeyPath）
    func ls_dictionary<K: Hashable, V>(key: KeyPath<Element, K>, value: KeyPath<Element, V>) -> [K: V] {
        var result: [K: V] = [:]
        for element in self {
            let k = element[keyPath: key]
            let v = element[keyPath: value]
            result[k] = v
        }
        return result
    }

    /// 转换为字典（元素为键，值由闭包生成）
    func ls_dictionaryValues<T>(keyPath: KeyPath<Element, T>) -> [T: Element] {
        var result: [T: Element] = [:]
        for element in self {
            let key = element[keyPath: keyPath]
            result[key] = element
        }
        return result
    }
}

// MARK: - Array Extension (范围操作)

public extension Array {

    /// 获取指定范围的子数组
    ///
    /// - Parameter range: 范围
    /// - Returns: 子数组
    func ls_subarray(range: Range<Int>) -> [Element] {
        guard range.lowerBound >= 0,
              range.upperBound <= count else {
            return []
        }
        return Array(self[range])
    }

    /// 获取从指定索引开始的子数组
    ///
    /// - Parameters:
    ///   - index: 起始索引
    ///   - length: 长度
    /// - Returns: 子数组
    func ls_subarray(from index: Int, length: Int) -> [Element] {
        guard index >= 0, length >= 0, index + length <= count else {
            return []
        }
        return Array(self[index..<index + length])
    }

    /// 获取前 n 个元素
    ///
    /// - Parameter count: 数量
    /// - Returns: 子数组
    func ls_first(count: Int) -> [Element] {
        guard count >= 0 else { return [] }
        return Array(prefix(count))
    }

    /// 获取后 n 个元素
    ///
    /// - Parameter count: 数量
    /// - Returns: 子数组
    func ls_last(count: Int) -> [Element] {
        guard count >= 0 else { return [] }
        return Array(suffix(count))
    }
}

// MARK: - Array Extension (移动操作)

public extension Array {

    /// 移动元素
    ///
    /// - Parameters:
    ///   - from: 源索引
    ///   - to: 目标索引
    /// - Returns: 新数组
    func ls_moved(from: Int, to: Int) -> [Element] {
        guard from != to,
              indices.contains(from),
              indices.contains(to) else {
            return self
        }

        var result = self
        let element = result.remove(at: from)
        result.insert(element, at: to)
        return result
    }

    /// 移动元素（in-place）
    mutating func ls_move(from: Int, to: Int) {
        guard from != to,
              indices.contains(from),
              indices.contains(to) else {
            return
        }

        let element = remove(at: from)
        insert(element, at: to)
    }
}

// MARK: - Array Extension (分割)

public extension Array {

    /// 分割数组（基于分隔符）
    ///
    /// - Parameter separator: 分隔符元素
    /// - Returns: 分割后的数组
    func ls_split(separator: Element) -> [[Element]] where Element: Equatable {
        var result: [[Element]] = []
        var current: [Element] = []

        for element in self {
            if element == separator {
                result.append(current)
                current = []
            } else {
                current.append(element)
            }
        }

        result.append(current)
        return result
    }

    /// 分割数组（基于条件）
    ///
    /// - Parameter predicate: 分隔条件
    /// - Returns: 分割后的数组
    func ls_split(where predicate: (Element) -> Bool) -> [[Element]] {
        var result: [[Element]] = []
        var current: [Element] = []

        for element in self {
            if predicate(element) {
                result.append(current)
                current = []
            } else {
                current.append(element)
            }
        }

        result.append(current)
        return result
    }
}

// MARK: - Array Extension (统计)

public extension Array {

    /// 元素出现次数
    ///
    /// - Parameter element: 元素
    /// - Returns: 出现次数
    func ls_count(of element: Element) -> Int where Element: Equatable {
        return filter { $0 == element }.count
    }

    /// 统计元素出现次数
    ///
    /// - Returns: 统计字典
    func ls_counted() -> [Element: Int] where Element: Hashable {
        var result: [Element: Int] = [:]
        for element in self {
            result[element, default: 0] += 1
        }
        return result
    }

    /// 出现最多的元素
    ///
    /// - Returns: 元素和出现次数
    func ls_mostCommon() -> (element: Element, count: Int)? where Element: Hashable {
        let counts = ls_counted()
        return counts.max { $0.value < $1.value }
            .map { (element: $0.key, count: $0.value) }
    }
}

// MARK: - Array Extension (组合)

public extension Array {

    /// 两数组组合
    ///
    /// - Parameter other: 另一个数组
    /// - Returns: 组合后的元组数组
    func ls_zipped<U>(with other: [U]) -> [(Element, U)] {
        let minLength = min(count, other.count)
        var result: [(Element, U)] = []

        for i in 0..<minLength {
            result.append((self[i], other[i]))
        }

        return result
    }

    /// 两个数组的笛卡尔积
    ///
    /// - Parameter other: 另一个数组
    /// - Returns: 笛卡尔积
    func ls_cartesianProduct<U>(with other: [U]) -> [(Element, U)] {
        var result: [(Element, U)] = []

        for left in self {
            for right in other {
                result.append((left, right))
            }
        }

        return result
    }
}

// MARK: - Array Extension (JSON)

public extension Array {

    /// 转换为 JSON 字符串
    ///
    /// - Parameter prettyPrinted: 是否格式化
    /// - Returns: JSON 字符串
    func ls_jsonString(prettyPrinted: Bool = false) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: self, options: .fragmentsAllowed) else {
            return nil
        }

        if prettyPrinted {
            return String(data: data, encoding: .utf8)
        }

        return String(data: data, encoding: .utf8)?
            .replacingOccurrences(of: "\\", with: "")
            .replacingOccurrences(of: "\n", with: "")
    }
}

// MARK: - Array Extension (Set 操作)

public extension Array where Element: Hashable {

    /// 并集
    func ls_union(_ other: [Element]) -> [Element] {
        return Array(Set(self).union(other))
    }

    /// 交集
    func ls_intersection(_ other: [Element]) -> [Element] {
        return Array(Set(self).intersection(other))
    }

    /// 差集
    func ls_difference(_ other: [Element]) -> [Element] {
        return Array(Set(self).subtracting(other))
    }

    /// 是否包含另一个数组的所有元素
    func ls_containsAll(_ other: [Element]) -> Bool {
        return Set(other).isSubset(of: Set(self))
    }

    /// 是否包含另一个数组的任一元素
    func ls_containsAny(_ other: [Element]) -> Bool {
        return !Set(other).isDisjoint(with: Set(self))
    }
}

#endif

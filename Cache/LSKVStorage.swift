//
//  LSKVStorage.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  基于 SQLite 和文件系统的键值存储
//

#if canImport(UIKit)
import UIKit
import Foundation
import sqlite3

// MARK: - 存储类型

/// 存储类型，指示 `LSKVStorageItem.value` 存储位置
///
/// - file: 值作为文件存储在文件系统中
/// - sqlite: 值作为 blob 类型存储在 sqlite 中
/// - mixed: 根据选择存储在文件系统或 sqlite 中
public enum LSKVStorageType: UInt {
    case file = 0
    case sqlite = 1
    case mixed = 2
}

// MARK: - 存储项

/// LSKVStorageItem 用于 `LSKVStorage` 存储键值对和元数据
public class LSKVStorageItem: NSObject {

    /// 键
    public var key: String = ""

    /// 值
    public var value: Data?

    /// 文件名（如果是内联则为 nil）
    public var filename: String?

    /// 值的大小（字节）
    public var size: Int = 0

    /// 修改时间（Unix 时间戳）
    public var modTime: Int = 0

    /// 最后访问时间（Unix 时间戳）
    public var accessTime: Int = 0

    /// 扩展数据
    public var extendedData: Data?

    public override init() {
        super.init()
    }
}

// MARK: - KV 存储

/// LSKVStorage 是基于 sqlite 和文件系统的键值存储
///
/// 此类使用 NSLock 保护内部状态，在 Swift 6 严格并发模式下
/// 使用 @unchecked Sendable 表示手动实现了线程安全。
public final class LSKVStorage, @unchecked Sendable {

    // MARK: - 属性

    /// 存储路径
    public private(set) var path: String

    /// 存储类型
    public private(set) var type: LSKVStorageType

    /// 是否启用错误日志
    public var errorLogsEnabled = false

    // MARK: - 内部属性

    private var db: OpaquePointer?
    private var dbPath: String
    private let dataPath: String
    private let trashPath: String
    private let fileManager = FileManager.default
    private let lock = NSLock()

    // MARK: - SQLite 语句

    private var stmtSave: OpaquePointer?
    private var stmtUpdate: OpaquePointer?
    private var stmtGetItem: OpaquePointer?
    private var stmtGetItemInfo: OpaquePointer?
    private var stmtRemoveItem: OpaquePointer?
    private var stmtRemoveItems: OpaquePointer?
    private var stmtGetSize: OpaquePointer?
    private var stmtGetCount: OpaquePointer?
    private var stmtGetItemsGreaterThanSize: OpaquePointer?
    private var stmtGetItemsEarlierThanTime: OpaquePointer?
    private var stmtGetItemsToFitCount: OpaquePointer?
    private var stmtGetItemsToFitSize: OpaquePointer?

    // MARK: - 初始化

    /// 初始化存储
    ///
    /// - Parameters:
    ///   - path: 存储数据的目录完整路径
    ///   - type: 存储类型
    /// - Returns: 新的存储对象，如果出错返回 nil
    public init?(path: String, type: LSKVStorageType) {
        self.path = path
        self.type = type
        self.dbPath = (path as NSString).appendingPathComponent("manifest.sqlite")
        self.dataPath = (path as NSString).appendingPathComponent("data")
        self.trashPath = (path as NSString).appendingPathComponent("trash")

        super.init()

        // 创建目录
        if !createDirectory(path) { return nil }
        if !createDirectory(dataPath) { return nil }
        if !createDirectory(trashPath) { return nil }

        // 打开数据库
        if !openDatabase() { return nil }

        // 创建表
        if !createTable() { return nil }
    }

    deinit {
        closeDatabase()
    }

    // MARK: - 保存项

    /// 保存项或更新现有项
    ///
    /// - Parameter item: 要保存的项
    /// - Returns: 是否成功
    @discardableResult
    public func saveItem(_ item: LSKVStorageItem) -> Bool {
        guard !item.key.isEmpty else { return false }
        guard let value = item.value, !value.isEmpty else { return false }

        lock.lock()
        defer { lock.unlock() }

        let filename = item.filename
        let shouldSaveToFile = type == .file || (type == .mixed && filename != nil)

        if shouldSaveToFile {
            // 保存到文件
            let actualFilename = filename ?? generateFilename(for: item.key)
            let filePath = (dataPath as NSString).appendingPathComponent(actualFilename)

            do {
                try value.write(to: URL(fileURLWithPath: filePath), options: .atomic)

                // 更新数据库
                return updateItem(key: item.key, value: value, filename: actualFilename, extendedData: item.extendedData)
            } catch {
                if errorLogsEnabled {
                    print("LSKVStorage: Failed to write file: \(error)")
                }
                return false
            }
        } else {
            // 保存到 SQLite
            return updateItem(key: item.key, value: value, filename: nil, extendedData: item.extendedData)
        }
    }

    /// 保存键值对
    ///
    /// - Parameters:
    ///   - key: 键
    ///   - value: 值
    /// - Returns: 是否成功
    @discardableResult
    public func saveItem(key: String, value: Data) -> Bool {
        guard !key.isEmpty else { return false }
        guard !value.isEmpty else { return false }

        let item = LSKVStorageItem()
        item.key = key
        item.value = value
        item.size = value.count
        item.modTime = Int(Date().timeIntervalSince1970)
        item.accessTime = Int(Date().timeIntervalSince1970)

        return saveItem(item)
    }

    /// 保存键值对（带文件名和扩展数据）
    ///
    /// - Parameters:
    ///   - key: 键
    ///   - value: 值
    ///   - filename: 文件名
    ///   - extendedData: 扩展数据
    /// - Returns: 是否成功
    @discardableResult
    public func saveItem(key: String, value: Data, filename: String?, extendedData: Data?) -> Bool {
        guard !key.isEmpty else { return false }
        guard !value.isEmpty else { return false }

        let item = LSKVStorageItem()
        item.key = key
        item.value = value
        item.filename = filename
        item.extendedData = extendedData
        item.size = value.count
        item.modTime = Int(Date().timeIntervalSince1970)
        item.accessTime = Int(Date().timeIntervalSince1970)

        return saveItem(item)
    }

    // MARK: - 移除项

    /// 移除指定键的项
    ///
    /// - Parameter key: 项的键
    /// - Returns: 是否成功
    @discardableResult
    public func removeItem(forKey key: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        // 先获取文件名
        let filename = getFilename(forKey: key)

        // 从数据库删除
        guard sqlite3_bind_text(stmtRemoveItem, 1, (key as NSString).utf8String, -1, nil) == SQLITE_OK else {
            return false
        }

        if sqlite3_step(stmtRemoveItem) != SQLITE_DONE {
            sqlite3_reset(stmtRemoveItem)
            return false
        }

        sqlite3_reset(stmtRemoveItem)

        // 删除文件
        if let fn = filename {
            deleteFile(fn)
        }

        return true
    }

    /// 移除指定键的多个项
    ///
    /// - Parameter keys: 指定的键数组
    /// - Returns: 是否成功
    @discardableResult
    public func removeItems(forKeys keys: [String]) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        for key in keys {
            _ = removeItem(forKey: key)
        }

        return true
    }

    /// 移除大于指定大小的所有项
    ///
    /// - Parameter size: 最大大小（字节）
    /// - Returns: 是否成功
    @discardableResult
    public func removeItems(largerThan size: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard sqlite3_bind_int(stmtGetItemsGreaterThanSize, 1, Int32(size)) == SQLITE_OK else {
            return false
        }

        var itemsToDelete: [(key: String, filename: String?)] = []

        while sqlite3_step(stmtGetItemsGreaterThanSize) == SQLITE_ROW {
            let key = String(cString: sqlite3_column_text(stmtGetItemsGreaterThanSize, 0))
            let filenameCString = sqlite3_column_text(stmtGetItemsGreaterThanSize, 1)
            let filename: String? = filenameCString.map { String(cString: $0) }
            itemsToDelete.append((key, filename))
        }

        sqlite3_reset(stmtGetItemsGreaterThanSize)

        for (key, filename) in itemsToDelete {
            _ = removeItem(forKey: key)
            if let fn = filename {
                deleteFile(fn)
            }
        }

        return true
    }

    /// 移除早于指定时间的所有项
    ///
    /// - Parameter time: 指定的 Unix 时间戳
    /// - Returns: 是否成功
    @discardableResult
    public func removeItems(earlierThan time: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard sqlite3_bind_int(stmtGetItemsEarlierThanTime, 1, Int32(time)) == SQLITE_OK else {
            return false
        }

        var itemsToDelete: [(key: String, filename: String?)] = []

        while sqlite3_step(stmtGetItemsEarlierThanTime) == SQLITE_ROW {
            let key = String(cString: sqlite3_column_text(stmtGetItemsEarlierThanTime, 0))
            let filenameCString = sqlite3_column_text(stmtGetItemsEarlierThanTime, 1)
            let filename: String? = filenameCString.map { String(cString: $0) }
            itemsToDelete.append((key, filename))
        }

        sqlite3_reset(stmtGetItemsEarlierThanTime)

        for (key, filename) in itemsToDelete {
            _ = removeItem(forKey: key)
            if let fn = filename {
                deleteFile(fn)
            }
        }

        return true
    }

    /// 移除项以使总大小不超过指定大小
    /// 最少使用的项将首先被移除
    ///
    /// - Parameter maxSize: 指定大小（字节）
    /// - Returns: 是否成功
    @discardableResult
    public func removeItemsToFitSize(_ maxSize: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        var currentSize = getItemsSizeSync()
        guard currentSize > maxSize else { return true }

        guard sqlite3_bind_int(stmtGetItemsToFitSize, 1, Int32(maxSize)) == SQLITE_OK else {
            return false
        }

        var itemsToDelete: [(key: String, filename: String?)] = []

        while currentSize > maxSize && sqlite3_step(stmtGetItemsToFitSize) == SQLITE_ROW {
            let key = String(cString: sqlite3_column_text(stmtGetItemsToFitSize, 0))
            let size = sqlite3_column_int(stmtGetItemsToFitSize, 1)
            let filenameCString = sqlite3_column_text(stmtGetItemsToFitSize, 2)
            let filename: String? = filenameCString.map { String(cString: $0) }
            itemsToDelete.append((key, filename))
            currentSize -= Int(size)
        }

        sqlite3_reset(stmtGetItemsToFitSize)

        for (key, filename) in itemsToDelete {
            _ = removeItem(forKey: key)
            if let fn = filename {
                deleteFile(fn)
            }
        }

        return true
    }

    /// 移除项以使总数量不超过指定数量
    /// 最少使用的项将首先被移除
    ///
    /// - Parameter maxCount: 指定的项数量
    /// - Returns: 是否成功
    @discardableResult
    public func removeItemsToFitCount(_ maxCount: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        var currentCount = getItemsCountSync()
        guard currentCount > maxCount else { return true }

        guard sqlite3_bind_int(stmtGetItemsToFitCount, 1, Int32(maxCount)) == SQLITE_OK else {
            return false
        }

        var itemsToDelete: [(key: String, filename: String?)] = []

        while currentCount > maxCount && sqlite3_step(stmtGetItemsToFitCount) == SQLITE_ROW {
            let key = String(cString: sqlite3_column_text(stmtGetItemsToFitCount, 0))
            let filenameCString = sqlite3_column_text(stmtGetItemsToFitCount, 1)
            let filename: String? = filenameCString.map { String(cString: $0) }
            itemsToDelete.append((key, filename))
            currentCount -= 1
        }

        sqlite3_reset(stmtGetItemsToFitCount)

        for (key, filename) in itemsToDelete {
            _ = removeItem(forKey: key)
            if let fn = filename {
                deleteFile(fn)
            }
        }

        return true
    }

    /// 移除所有项
    ///
    /// - Returns: 是否成功
    @discardableResult
    public func removeAllItems() -> Bool {
        lock.lock()
        defer { lock.unlock() }

        // 关闭数据库
        closeDatabaseSync()

        // 将文件移动到垃圾文件夹
        let trashDataPath = (trashPath as NSString).appendingPathComponent("data")

        do {
            try fileManager.moveItem(atPath: dataPath, toPath: trashDataPath)
        } catch {
            // 忽略错误
        }

        // 在后台清理
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.clearTrash()
        }

        // 重新创建目录和数据库
        _ = createDirectory(dataPath)
        return openDatabase() && createTable()
    }

    // MARK: - 获取项

    /// 获取指定键的项
    ///
    /// - Parameter key: 指定的键
    /// - Returns: 键对应的项，如果不存在或出错返回 nil
    public func getItem(forKey key: String) -> LSKVStorageItem? {
        lock.lock()
        defer { lock.unlock() }

        return getItemSync(key)
    }

    /// 获取指定键的项信息
    /// 项中的 `value` 将被忽略
    ///
    /// - Parameter key: 指定的键
    /// - Returns: 键对应的项信息，如果不存在或出错返回 nil
    public func getItemInfo(forKey key: String) -> LSKVStorageItem? {
        lock.lock()
        defer { lock.unlock() }

        return getItemInfoSync(key)
    }

    /// 获取指定键的项值
    ///
    /// - Parameter key: 指定的键
    /// - Returns: 项的值，如果不存在或出错返回 nil
    public func getItemValue(forKey key: String) -> Data? {
        return getItem(forKey: key)?.value
    }

    // MARK: - 获取存储状态

    /// 指定键的项是否存在
    ///
    /// - Parameter key: 指定的键
    /// - Returns: 如果存在项返回 true，如果不存在或出错返回 false
    public func itemExists(forKey key: String) -> Bool {
        return getItemInfo(forKey: key) != nil
    }

    /// 获取总项数
    ///
    /// - Returns: 总项数，出错时返回 -1
    public func getItemsCount() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return getItemsCountSync()
    }

    /// 获取项值的总大小（字节）
    ///
    /// - Returns: 总大小（字节），出错时返回 -1
    public func getItemsSize() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return getItemsSizeSync()
    }

    // MARK: - 私有方法

    private func createDirectory(_ path: String) -> Bool {
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: path, isDirectory: &isDirectory) {
            return isDirectory.boolValue
        }

        do {
            try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            return true
        } catch {
            if errorLogsEnabled {
                print("LSKVStorage: Failed to create directory: \(error)")
            }
            return false
        }
    }

    private func openDatabase() -> Bool {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            if errorLogsEnabled {
                print("LSKVStorage: Failed to open database")
            }
            return false
        }

        // 准备语句
        prepareStatements()

        return true
    }

    private func closeDatabase() {
        lock.lock()
        closeDatabaseSync()
        lock.unlock()
    }

    private func closeDatabaseSync() {
        finalizeStatements()
        if db != nil {
            sqlite3_close(db)
            db = nil
        }
    }

    private func createTable() -> Bool {
        let sql = """
        CREATE TABLE IF NOT EXISTS manifest (
            key TEXT,
            filename TEXT,
            size INTEGER,
            inline_data BLOB,
            extended_data BLOB,
            modification_time INTEGER,
            last_access_time INTEGER,
            PRIMARY KEY(key)
        );
        CREATE INDEX IF NOT EXISTS last_access_time_index ON manifest(last_access_time);
        """

        let charPointer = (sql as NSString).utf8String
        if sqlite3_exec(db, charPointer, nil, nil, nil) != SQLITE_OK {
            if errorLogsEnabled {
                print("LSKVStorage: Failed to create table: \(String(cString: sqlite3_errmsg(db)))")
            }
            return false
        }

        return true
    }

    private func prepareStatements() {
        let saveSQL = "INSERT OR REPLACE INTO manifest (key, filename, size, inline_data, extended_data, modification_time, last_access_time) VALUES (?, ?, ?, ?, ?, ?, ?);"
        sqlite3_prepare_v2(db, (saveSQL as NSString).utf8String, -1, &stmtSave, nil)

        let updateSQL = "UPDATE manifest SET filename=?, size=?, inline_data=?, extended_data=?, modification_time=?, last_access_time=? WHERE key=?;"
        sqlite3_prepare_v2(db, (updateSQL as NSString).utf8String, -1, &stmtUpdate, nil)

        let getItemSQL = "SELECT key, filename, size, inline_data, extended_data, modification_time, last_access_time FROM manifest WHERE key=?;"
        sqlite3_prepare_v2(db, (getItemSQL as NSString).utf8String, -1, &stmtGetItem, nil)

        let getItemInfoSQL = "SELECT key, filename, size, modification_time, last_access_time FROM manifest WHERE key=?;"
        sqlite3_prepare_v2(db, (getItemInfoSQL as NSString).utf8String, -1, &stmtGetItemInfo, nil)

        let removeItemSQL = "DELETE FROM manifest WHERE key=?;"
        sqlite3_prepare_v2(db, (removeItemSQL as NSString).utf8String, -1, &stmtRemoveItem, nil)

        let getSizeSQL = "SELECT SUM(size) FROM manifest;"
        sqlite3_prepare_v2(db, (getSizeSQL as NSString).utf8String, -1, &stmtGetSize, nil)

        let getCountSQL = "SELECT COUNT(key) FROM manifest;"
        sqlite3_prepare_v2(db, (getCountSQL as NSString).utf8String, -1, &stmtGetCount, nil)

        let getItemsGreaterThanSizeSQL = "SELECT key, filename FROM manifest WHERE size > ?;"
        sqlite3_prepare_v2(db, (getItemsGreaterThanSizeSQL as NSString).utf8String, -1, &stmtGetItemsGreaterThanSize, nil)

        let getItemsEarlierThanTimeSQL = "SELECT key, filename FROM manifest WHERE last_access_time < ?;"
        sqlite3_prepare_v2(db, (getItemsEarlierThanTimeSQL as NSString).utf8String, -1, &stmtGetItemsEarlierThanTime, nil)

        let getItemsToFitSizeSQL = "SELECT key, size, filename FROM manifest ORDER BY last_access_time ASC;"
        sqlite3_prepare_v2(db, (getItemsToFitSizeSQL as NSString).utf8String, -1, &stmtGetItemsToFitSize, nil)

        let getItemsToFitCountSQL = "SELECT key, filename FROM manifest ORDER BY last_access_time ASC;"
        sqlite3_prepare_v2(db, (getItemsToFitCountSQL as NSString).utf8String, -1, &stmtGetItemsToFitCount, nil)
    }

    private func finalizeStatements() {
        sqlite3_finalize(stmtSave)
        sqlite3_finalize(stmtUpdate)
        sqlite3_finalize(stmtGetItem)
        sqlite3_finalize(stmtGetItemInfo)
        sqlite3_finalize(stmtRemoveItem)
        sqlite3_finalize(stmtGetSize)
        sqlite3_finalize(stmtGetCount)
        sqlite3_finalize(stmtGetItemsGreaterThanSize)
        sqlite3_finalize(stmtGetItemsEarlierThanTime)
        sqlite3_finalize(stmtGetItemsToFitSize)
        sqlite3_finalize(stmtGetItemsToFitCount)
    }

    private func updateItem(key: String, value: Data, filename: String?, extendedData: Data?) -> Bool {
        let time = Int(Date().timeIntervalSince1970)
        let shouldSaveInlineData = type == .sqlite || (type == .mixed && filename == nil)

        if shouldSaveInlineData {
            // 保存到 SQLite（内联）
            value.withUnsafeBytes { bytes in
                guard sqlite3_bind_text(stmtUpdate, 1, "", -1, nil) == SQLITE_OK else { return }
                sqlite3_bind_int(stmtUpdate, 2, Int32(value.count))
                sqlite3_bind_blob(stmtUpdate, 3, bytes.baseAddress, Int32(value.count), nil)
                if let extData = extendedData {
                    extData.withUnsafeBytes { extBytes in
                        sqlite3_bind_blob(stmtUpdate, 4, extBytes.baseAddress, Int32(extData.count), nil)
                    }
                } else {
                    sqlite3_bind_null(stmtUpdate, 4)
                }
                sqlite3_bind_int(stmtUpdate, 5, Int32(time))
                sqlite3_bind_int(stmtUpdate, 6, Int32(time))
                sqlite3_bind_text(stmtUpdate, 7, (key as NSString).utf8String, -1, nil)

                if sqlite3_step(stmtUpdate) != SQLITE_DONE {
                    sqlite3_reset(stmtUpdate)
                    return false
                }

                sqlite3_reset(stmtUpdate)
                return true
            }
        } else {
            // 保存到文件（只记录文件名）
            let actualFilename = filename ?? ""
            sqlite3_bind_text(stmtUpdate, 1, (actualFilename as NSString).utf8String, -1, nil)
            sqlite3_bind_int(stmtUpdate, 2, Int32(value.count))
            sqlite3_bind_null(stmtUpdate, 3)
            if let extData = extendedData {
                extData.withUnsafeBytes { extBytes in
                    sqlite3_bind_blob(stmtUpdate, 4, extBytes.baseAddress, Int32(extData.count), nil)
                }
            } else {
                sqlite3_bind_null(stmtUpdate, 4)
            }
            sqlite3_bind_int(stmtUpdate, 5, Int32(time))
            sqlite3_bind_int(stmtUpdate, 6, Int32(time))
            sqlite3_bind_text(stmtUpdate, 7, (key as NSString).utf8String, -1, nil)

            if sqlite3_step(stmtUpdate) != SQLITE_DONE {
                sqlite3_reset(stmtUpdate)
                return false
            }

            sqlite3_reset(stmtUpdate)
            return true
        }
    }

    private func getItemSync(_ key: String) -> LSKVStorageItem? {
        guard sqlite3_bind_text(stmtGetItem, 1, (key as NSString).utf8String, -1, nil) == SQLITE_OK else {
            return nil
        }

        guard sqlite3_step(stmtGetItem) == SQLITE_ROW else {
            sqlite3_reset(stmtGetItem)
            return nil
        }

        let item = parseItem(from: stmtGetItem, includeValue: true)
        sqlite3_reset(stmtGetItem)

        // 更新访问时间
        updateAccessTime(forKey: key)

        return item
    }

    private func getItemInfoSync(_ key: String) -> LSKVStorageItem? {
        guard sqlite3_bind_text(stmtGetItemInfo, 1, (key as NSString).utf8String, -1, nil) == SQLITE_OK else {
            return nil
        }

        guard sqlite3_step(stmtGetItemInfo) == SQLITE_ROW else {
            sqlite3_reset(stmtGetItemInfo)
            return nil
        }

        let item = parseItem(from: stmtGetItemInfo, includeValue: false)
        sqlite3_reset(stmtGetItemInfo)

        // 更新访问时间
        updateAccessTime(forKey: key)

        return item
    }

    private func parseItem(from stmt: OpaquePointer?, includeValue: Bool) -> LSKVStorageItem {
        let item = LSKVStorageItem()

        item.key = String(cString: sqlite3_column_text(stmt, 0))

        let filenameCString = sqlite3_column_text(stmt, 1)
        if let fn = filenameCString {
            item.filename = String(cString: fn)
        }

        item.size = Int(sqlite3_column_int(stmt, 2))
        item.modTime = Int(sqlite3_column_int(stmt, 5))
        item.accessTime = Int(sqlite3_column_int(stmt, 6))

        if includeValue {
            if let filename = item.filename, !filename.isEmpty {
                // 从文件读取
                let filePath = (dataPath as NSString).appendingPathComponent(filename)
                item.value = try? Data(contentsOf: URL(fileURLWithPath: filePath))
            } else {
                // 从内联数据读取
                if let dataBlob = sqlite3_column_blob(stmt, 3) {
                    let dataLength = sqlite3_column_bytes(stmt, 3)
                    item.value = Data(bytes: dataBlob, count: Int(dataLength))
                }
            }

            // 扩展数据
            if let extBlob = sqlite3_column_blob(stmt, 4) {
                let extLength = sqlite3_column_bytes(stmt, 4)
                item.extendedData = Data(bytes: extBlob, count: Int(extLength))
            }
        }

        return item
    }

    private func getFilename(forKey key: String) -> String? {
        guard sqlite3_bind_text(stmtGetItemInfo, 1, (key as NSString).utf8String, -1, nil) == SQLITE_OK else {
            return nil
        }

        guard sqlite3_step(stmtGetItemInfo) == SQLITE_ROW else {
            sqlite3_reset(stmtGetItemInfo)
            return nil
        }

        let filenameCString = sqlite3_column_text(stmtGetItemInfo, 1)
        let filename: String? = filenameCString.map { String(cString: $0) }

        sqlite3_reset(stmtGetItemInfo)

        return filename
    }

    private func updateAccessTime(forKey key: String) {
        let time = Int32(Date().timeIntervalSince1970)

        // 使用简单的 UPDATE 语句
        let sql = "UPDATE manifest SET last_access_time = \(time) WHERE key = ?;"
        let stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, (sql as NSString).utf8String, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (key as NSString).utf8String, -1, nil)
            sqlite3_step(stmt)
            sqlite3_finalize(stmt)
        }
    }

    private func getItemsCountSync() -> Int {
        guard sqlite3_step(stmtGetCount) == SQLITE_ROW else { return -1 }
        let count = Int(sqlite3_column_int(stmtGetCount, 0))
        sqlite3_reset(stmtGetCount)
        return count
    }

    private func getItemsSizeSync() -> Int {
        guard sqlite3_step(stmtGetSize) == SQLITE_ROW else { return -1 }
        let size = Int(sqlite3_column_int(stmtGetSize, 0))
        sqlite3_reset(stmtGetSize)
        return size
    }

    private func generateFilename(for key: String) -> String {
        return key.ls_md5()
    }

    private func deleteFile(_ filename: String) {
        let filePath = (dataPath as NSString).appendingPathComponent(filename)
        try? fileManager.removeItem(atPath: filePath)
    }

    private func clearTrash() {
        try? fileManager.removeItem(atPath: trashPath)
        createDirectory(trashPath)
    }
}

// MARK: - String 扩展（MD5）

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

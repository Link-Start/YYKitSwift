//
//  LSFileManager.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  文件管理工具 - 提供文件操作相关方法
//

#if canImport(UIKit)
import UIKit
import Foundation

// MARK: - LSFileManager

/// 文件管理器
public enum LSFileManager {

    /// 默认管理器
    public static let `default` = FileManager.default

    // MARK: - 目录路径

    /// 主目录
    public static var homeDirectory: URL {
        return default.homeDirectoryForCurrentUser
    }

    /// 文档目录
    public static var documentsDirectory: URL {
        return default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    /// 缓存目录
    public static var cachesDirectory: URL {
        return default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }

    /// 临时目录
    public static var temporaryDirectory: URL {
        return default.temporaryDirectory
    }

    /// 应用程序支持目录
    public static var applicationSupportDirectory: URL {
        return default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    }

    /// 下载目录（iOS 不常用，但提供）
    public static var downloadsDirectory: URL? {
        return default.urls(for: .downloadsDirectory, in: .userDomainMask).first
    }

    /// 应 Bundle 路径
    public static var bundlePath: String {
        return Bundle.main.bundlePath
    }

    /// 资源路径
    public static var resourcePath: String? {
        return Bundle.main.resourcePath
    }

    // MARK: - 文件检查

    /// 检查文件是否存在
    ///
    /// - Parameter path: 文件路径
    /// - Returns: 是否存在
    public static func fileExists(at path: String) -> Bool {
        return default.fileExists(atPath: path)
    }

    /// 检查文件是否可读
    ///
    /// - Parameter path: 文件路径
    /// - Returns: 是否可读
    public static func isReadable(at path: String) -> Bool {
        return default.isReadableFile(atPath: path)
    }

    /// 检查文件是否可写
    ///
    /// - Parameter path: 文件路径
    /// - Returns: 是否可写
    public static func isWritable(at path: String) -> Bool {
        return default.isWritableFile(atPath: path)
    }

    /// 检查文件是否可删除
    ///
    /// - Parameter path: 文件路径
    /// - Returns: 是否可删除
    public static func isDeletable(at path: String) -> Bool {
        return default.isDeletableFile(atPath: path)
    }

    // MARK: - 文件操作

    /// 创建目录
    ///
    /// - Parameter path: 目录路径
    /// - Returns: 是否成功
    @discardableResult
    public static func createDirectory(at path: String) -> Bool {
        do {
            try default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            return true
        } catch {
            print("创建目录失败: \(error)")
            return false
        }
    }

    /// 创建目录（URL 版本）
    ///
    /// - Parameter url: 目录 URL
    /// - Returns: 是否成功
    @discardableResult
    public static func createDirectory(at url: URL) -> Bool {
        do {
            try default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            return true
        } catch {
            print("创建目录失败: \(error)")
            return false
        }
    }

    /// 删除文件
    ///
    /// - Parameter path: 文件路径
    /// - Returns: 是否成功
    @discardableResult
    public static func removeFile(at path: String) -> Bool {
        do {
            try default.removeItem(atPath: path)
            return true
        } catch {
            print("删除文件失败: \(error)")
            return false
        }
    }

    /// 删除文件（URL 版本）
    ///
    /// - Parameter url: 文件 URL
    /// - Returns: 是否成功
    @discardableResult
    public static func removeFile(at url: URL) -> Bool {
        do {
            try default.removeItem(at: url)
            return true
        } catch {
            print("删除文件失败: \(error)")
            return false
        }
    }

    /// 复制文件
    ///
    /// - Parameters:
    ///   - srcPath: 源路径
    ///   - dstPath: 目标路径
    /// - Returns: 是否成功
    @discardableResult
    public static func copyFile(from srcPath: String, to dstPath: String) -> Bool {
        do {
            // 确保目标目录存在
            let dstDir = (dstPath as NSString).deletingLastPathComponent
            if !fileExists(at: dstDir) {
                createDirectory(at: dstDir)
            }

            try default.copyItem(atPath: srcPath, toPath: dstPath)
            return true
        } catch {
            print("复制文件失败: \(error)")
            return false
        }
    }

    /// 移动文件
    ///
    /// - Parameters:
    ///   - srcPath: 源路径
    ///   - dstPath: 目标路径
    /// - Returns: 是否成功
    @discardableResult
    public static func moveFile(from srcPath: String, to dstPath: String) -> Bool {
        do {
            // 确保目标目录存在
            let dstDir = (dstPath as NSString).deletingLastPathComponent
            if !fileExists(at: dstDir) {
                createDirectory(at: dstDir)
            }

            try default.moveItem(atPath: srcPath, toPath: dstPath)
            return true
        } catch {
            print("移动文件失败: \(error)")
            return false
        }
    }

    /// 重命名文件
    ///
    /// - Parameters:
    ///   - path: 文件路径
    ///   - newName: 新名称
    /// - Returns: 是否成功
    @discardableResult
    public static func renameFile(at path: String, to newName: String) -> Bool {
        let dstPath = (path as NSString).deletingLastPathComponent + "/" + newName
        return moveFile(from: path, to: dstPath)
    }

    // MARK: - 文件信息

    /// 获取文件大小
    ///
    /// - Parameter path: 文件路径
    /// - Returns: 文件大小（字节）
    public static func fileSize(at path: String) -> Int64 {
        guard let attrs = try? default.attributesOfItem(atPath: path) else {
            return 0
        }
        if let tempValue = attrs[.size] as? Int64 {
            return tempValue
        }
        return 0
    }

    /// 获取文件大小（格式化字符串）
    ///
    /// - Parameter path: 文件路径
    /// - Returns: 格式化的大小字符串
    public static func fileSizeString(at path: String) -> String {
        let size = fileSize(at: path)
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    /// 获取文件创建日期
    ///
    /// - Parameter path: 文件路径
    /// - Returns: 创建日期
    public static func creationDate(of path: String) -> Date? {
        guard let attrs = try? default.attributesOfItem(atPath: path) else {
            return nil
        }
        return attrs[.creationDate] as? Date
    }

    /// 获取文件修改日期
    ///
    /// - Parameter path: 文件路径
    /// - Returns: 修改日期
    public static func modificationDate(of path: String) -> Date? {
        guard let attrs = try? default.attributesOfItem(atPath: path) else {
            return nil
        }
        return attrs[.modificationDate] as? Date
    }

    /// 获取文件扩展名
    ///
    /// - Parameter path: 文件路径
    /// - Returns: 扩展名（不含点）
    public static func fileExtension(of path: String) -> String {
        return (path as NSString).pathExtension
    }

    /// 获取文件名（不含扩展名）
    ///
    /// - Parameter path: 文件路径
    /// - Returns: 文件名
    public static func fileName(of path: String) -> String {
        return (path as NSString).deletingPathExtension
    }

    /// 获取完整文件名
    ///
    /// - Parameter path: 文件路径
    /// - Returns: 文件名
    public static func fullFileName(of path: String) -> String {
        return (path as NSString).lastPathComponent
    }

    /// 获取目录路径
    ///
    /// - Parameter path: 文件路径
    /// - Returns: 目录路径
    public static func directoryPath(of path: String) -> String {
        return (path as NSString).deletingLastPathComponent
    }

    // MARK: - 目录内容

    /// 获取目录内容
    ///
    /// - Parameter path: 目录路径
    /// - Returns: 文件名数组
    public static func contentsOfDirectory(at path: String) -> [String]? {
        return try? default.contentsOfDirectory(atPath: path)
    }

    /// 获取目录内容（完整路径）
    ///
    /// - Parameter path: 目录路径
    /// - Returns: 文件路径数组
    public static func contentsOfDirectoryFullPath(at path: String) -> [String] {
        guard let contents = contentsOfDirectory(at: path) else {
            return []
        }
        return contents.map { path + "/" + $0 }
    }

    /// 获取目录所有文件（递归）
    ///
    /// - Parameter path: 目录路径
    /// - Returns: 文件路径数组
    public static func allFiles(at path: String) -> [String] {
        var result: [String] = []

        guard let contents = contentsOfDirectory(at: path) else {
            return result
        }

        for item in contents {
            let fullPath = path + "/" + item
            var isDir: ObjCBool = false
            default.fileExists(atPath: fullPath, isDirectory: &isDir)

            if isDir.boolValue {
                result.append(contentsOf: allFiles(at: fullPath))
            } else {
                result.append(fullPath)
            }
        }

        return result
    }

    /// 获取目录大小
    ///
    /// - Parameter path: 目录路径
    /// - Returns: 目录大小（字节）
    public static func directorySize(at path: String) -> Int64 {
        var total: Int64 = 0

        for file in allFiles(at: path) {
            total += fileSize(at: file)
        }

        return total
    }

    /// 获取目录大小（格式化字符串）
    ///
    /// - Parameter path: 目录路径
    /// - Returns: 格式化的大小字符串
    public static func directorySizeString(at path: String) -> String {
        let size = directorySize(at: path)
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    // MARK: - 清理操作

    /// 清空缓存目录
    ///
    /// - Returns: 是否成功
    @discardableResult
    public static func clearCachesDirectory() -> Bool {
        do {
            let contents = try default.contentsOfDirectory(at: cachesDirectory, includingPropertiesForKeys: nil)
            for item in contents {
                try default.removeItem(at: item)
            }
            return true
        } catch {
            print("清空缓存失败: \(error)")
            return false
        }
    }

    /// 清空临时目录
    ///
    /// - Returns: 是否成功
    @discardableResult
    public static func clearTemporaryDirectory() -> Bool {
        do {
            let contents = try default.contentsOfDirectory(at: temporaryDirectory, includingPropertiesForKeys: nil)
            for item in contents {
                try default.removeItem(at: item)
            }
            return true
        } catch {
            print("清空临时目录失败: \(error)")
            return false
        }
    }

    /// 清空目录
    ///
    /// - Parameter path: 目录路径
    /// - Returns: 是否成功
    @discardableResult
    public static func clearDirectory(at path: String) -> Bool {
        do {
            let contents = try default.contentsOfDirectory(atPath: path)
            for item in contents {
                try default.removeItem(atPath: path + "/" + item)
            }
            return true
        } catch {
            print("清空目录失败: \(error)")
            return false
        }
    }
}

// MARK: - URL Extension (文件操作)

public extension URL {

    /// 文件是否存在
    var ls_fileExists: Bool {
        return LSFileManager.fileExists(at: path)
    }

    /// 是否为目录
    var ls_isDirectory: Bool {
        var isDir: ObjCBool = false
        LSFileManager.default.fileExists(atPath: path, isDirectory: &isDir)
        return isDir.boolValue
    }

    /// 文件大小
    var ls_fileSize: Int64 {
        return LSFileManager.fileSize(at: path)
    }

    /// 文件扩展名
    var ls_fileExtension: String {
        return pathExtension
    }

    /// 文件名（不含扩展名）
    var ls_fileName: String {
        return deletingPathExtension().lastPathComponent
    }

    /// 完整文件名
    var ls_fullFileName: String {
        return lastPathComponent
    }

    /// 创建目录
    @discardableResult
    func ls_createDirectory() -> Bool {
        return LSFileManager.createDirectory(at: path)
    }

    /// 删除
    @discardableResult
    func ls_remove() -> Bool {
        return LSFileManager.removeFile(at: self)
    }

    /// 获取目录内容
    func ls_directoryContents() -> [URL]? {
        return try? FileManager.default.contentsOfDirectory(
            at: self,
            includingPropertiesForKeys: nil
        )
    }
}

// MARK: - String Extension (文件路径)

public extension String {

    /// 文件是否存在
    var ls_fileExists: Bool {
        return LSFileManager.fileExists(at: self)
    }

    /// 是否为目录
    var ls_isDirectory: Bool {
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: self, isDirectory: &isDir)
        return isDir.boolValue
    }

    /// 文件扩展名
    var ls_fileExtension: String {
        return (self as NSString).pathExtension
    }

    /// 文件名（不含扩展名）
    var ls_fileName: String {
        return (self as NSString).deletingPathExtension
    }

    /// 完整文件名
    var ls_fullFileName: String {
        return (self as NSString).lastPathComponent
    }

    /// 目录路径
    var ls_directoryPath: String {
        return (self as NSString).deletingLastPathComponent
    }

    /// 转换为 URL
    var ls_fileURL: URL {
        return URL(fileURLWithPath: self)
    }
}

#endif

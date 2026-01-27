//
//  NSKeyedUnarchiver+YYKitSwift.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  NSKeyedUnarchiver 扩展，提供安全的解档方法
//

import Foundation

// MARK: - NSKeyedUnarchiver 扩展

public extension NSKeyedUnarchiver {

    /// 从数据解档对象（返回异常信息）
    /// - Parameter data: 归档的数据
    /// - Returns: 解档后的对象，失败返回 nil
    static func ls_unarchive(_ data: Data) -> Any? {
        do {
            return try unarchiveTopLevelObjectWithData(data)
        } catch {
            #if DEBUG
            print("[YYKitSwift] Unarchive failed: \(error)")
            #endif
            return nil
        }
    }

    /// 从文件解档对象（返回异常信息）
    /// - Parameter path: 归档文件路径
    /// - Returns: 解档后的对象，失败返回 nil
    static func ls_unarchive(file path: String) -> Any? {
        do {
            return try unarchiveTopLevelObject(withFile: path)
        } catch {
            #if DEBUG
            print("[YYKitSwift] Unarchive file failed: \(error)")
            #endif
            return nil
        }
    }
}

// MARK: - Data 便捷扩展

public extension Data {
    /// 解档数据
    var ls_unarchivedObject: Any? {
        return NSKeyedUnarchiver.ls_unarchive(self)
    }
}

// MARK: - String 便捷扩展

public extension String {
    /// 从路径解档文件
    var ls_unarchivedObject: Any? {
        return NSKeyedUnarchiver.ls_unarchive(file: self)
    }
}

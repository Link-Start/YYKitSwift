//
//  YYKitSwift.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//

import Foundation

/// YYKitSwift 主入口
/// YYKitSwift 是 YYKit 的 Swift 6 重写版本，提供iOS 13+ 支持
@objc
public class YYKitSwift: NSObject {

    /// 版本号
    @objc public static let version = "0.1.0"

    /// SDK 版本字符串
    @objc public static let versionString = "YYKitSwift \(version)"

    /// 初始化 YYKitSwift
    /// 默认会自动注册所有扩展，无需手动调用
    @objc public static func initialize() {
        LSExtensions.registerAll()
    }

    /// 调试模式开关
    /// 设置为 true 可输出详细日志
    @objc public static var isDebugEnabled: Bool = false

    /// 日志输出
    @objc public static func log(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        if isDebugEnabled {
            let fileName = (file as NSString).lastPathComponent
            print("[YYKitSwift] \(fileName).\(function)[\(line)]: \(message)")
        }
        #endif
    }
}

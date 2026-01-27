//
//  LSExtensions.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//

import Foundation

/// 扩展注册器
/// 负责注册所有 YYKitSwift 扩展
@objc
public class LSExtensions: NSObject {

    /// 注册所有扩展
    /// 在 YYKitSwift.initialize() 时自动调用
    @objc public static func registerAll() {
        // Foundation 扩展会自动加载，无需手动注册

        // UIKit 扩展会自动加载，无需手动注册

        #if DEBUG
        YYKitSwift.log("All extensions registered successfully")
        #endif
    }

    /// 检查扩展是否已注册
    @objc public static func isExtensionRegistered(_ name: String) -> Bool {
        // 可以扩展此方法来检查特定扩展的注册状态
        return true
    }
}

// MARK: - 扩展协议

/// 扩展协议，用于统一管理扩展
@objc
public protocol LSExtensionProtocol: NSObjectProtocol {
    /// 扩展名称
    static var ls_extensionName: String { get }

    /// 扩展版本
    static var ls_extensionVersion: String { get }

    /// 是否可用
    static var ls_isAvailable: Bool { get }
}

// MARK: - 通用扩展标记

/// 用于标记所有扩展的基本信息
public enum LSExtensionInfo {
    /// 所有已注册的扩展
    public static var allExtensions: [String] {
        var extensions: [String] = []

        // Foundation 扩展
        extensions += [
            "String_ls",
            "Array_ls",
            "Dictionary_ls",
            "Date_ls",
            "Data_ls",
            "Number_ls",
            "NotificationCenter_ls",
            "Bundle_ls",
            "KeyedUnarchiver_ls"
        ]

        // UIKit 扩展
        extensions += [
            "UIView_ls",
            "UIImage_ls",
            "UIColor_ls",
            "UILabel_ls",
            "UIFont_ls",
            "UIScreen_ls",
            "UIDevice_ls",
            "UIControl_ls",
            "UIScrollView_ls",
            "UITableView_ls",
            "UITextField_ls",
            "UIBarButtonItem_ls",
            "UIGestureRecognizer_ls",
            "UIBezierPath_ls",
            "UIApplication_ls"
        ]

        // Quartz 扩展
        extensions += [
            "CALayer_ls",
            "CGUtilities_ls"
        ]

        return extensions
    }

    /// 获取扩展数量
    public static var count: Int {
        allExtensions.count
    }
}

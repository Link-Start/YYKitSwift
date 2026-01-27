//
//  UIApplication+YYKitSwift.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  UIApplication 扩展，提供信息获取方法
//

import UIKit

// MARK: - UIApplication 扩展

public extension UIApplication {

    /// 应用程序版本号
    var ls_version: String? {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    /// 应用程序构建号
    var ls_build: String? {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    }

    /// 应用程序名称
    var ls_appName: String? {
        return Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
            ?? Bundle.main.infoDictionary?["CFBundleName"] as? String
    }

    /// 应用程序 Bundle ID
    var ls_bundleIdentifier: String? {
        return Bundle.main.bundleIdentifier
    }

    /// 设备系统版本
    var ls_systemVersion: String {
        return UIDevice.current.systemVersion
    }

    /// 是否是调试模式
    var ls_isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    /// 当前状态栏方向
    var ls_statusBarOrientation: UIInterfaceOrientation {
        if #available(iOS 13.0, *) {
            guard let windowScene = connectedScenes.first as? UIWindowScene else {
                return .portrait
            }
            return windowScene.interfaceOrientation
        } else {
            return statusBarOrientation
        }
    }

    /// 主窗口
    var ls_keyWindow: UIWindow? {
        if #available(iOS 13.0, *) {
            return connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
        } else {
            return keyWindow
        }
    }
}

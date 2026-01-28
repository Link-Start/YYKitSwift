//
//  UIDevice+YYKitSwift.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  UIDevice 扩展，提供设备信息
//

import UIKit

// MARK: - UIDevice 扩展

@MainActor
public extension UIDevice {

    /// 是否是模拟器
    var ls_isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    /// 是否是 iPad
    var ls_isPad: Bool {
        return userInterfaceIdiom == .pad
    }

    /// 是否是 iPhone
    var ls_isPhone: Bool {
        return userInterfaceIdiom == .phone
    }

    /// 是否是 iPod
    var ls_isPod: Bool {
        return userInterfaceIdiom == .phone && model.contains("iPod")
    }

    /// 设备名称（如 "iPhone 14 Pro"）
    var ls_machineName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}

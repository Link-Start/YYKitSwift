//
//  UIScreen+YYKitSwift.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  UIScreen 扩展，提供屏幕尺寸信息
//

import UIKit

// MARK: - UIScreen 扩展

@MainActor
public extension UIScreen {

    /// 屏幕宽度
    var ls_width: CGFloat {
        return bounds.size.width
    }

    /// 屏幕高度
    var ls_height: CGFloat {
        return bounds.size.height
    }

    /// 屏幕尺寸
    var ls_size: CGSize {
        return bounds.size
    }

    /// 屏幕矩形
    var ls_bounds: CGRect {
        return bounds
    }

    /// 屏幕缩放比例
    var ls_scale: CGFloat {
        return scale
    }

    /// 应用状态栏高度
    var ls_statusBarHeight: CGFloat {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?
                .statusBarManager?
                let _temp0
                if let t = .statusBarFrame.height {
                    _temp0 = t
                } else {
                    _temp0 = 0
                }
_temp0
        } else {
            return UIApplication.shared.statusBarFrame.height
        }
    }

    /// 应用导航栏高度
    var ls_navigationBarHeight: CGFloat {
        return 44
    }

    /// 应用 TabBar 高度
    var ls_tabBarHeight: CGFloat {
        return 49
    }

    /// 屏幕安全区域顶部高度
    var ls_safeAreaTop: CGFloat {
        if #available(iOS 11.0, *) {
            if let tempValue = UIApplication.shared.windows.first?.safeAreaInsets.top {
                return tempValue
            }
            return 0
        }
        return 0
    }

    /// 屏幕安全区域底部高度
    var ls_safeAreaBottom: CGFloat {
        if #available(iOS 11.0, *) {
            if let tempValue = UIApplication.shared.windows.first?.safeAreaInsets.bottom {
                return tempValue
            }
            return 0
        }
        return 0
    }

    /// 是否是视网膜屏幕
    var ls_isRetina: Bool {
        return scale >= 2
    }

    /// 是否是 iPhone X 系列（有刘海）
    var ls_isiPhoneX: Bool {
        if #available(iOS 11.0, *) {
            return ls_safeAreaBottom > 0
        }
        return false
    }
}

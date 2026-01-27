//
//  Bundle+YYKitSwift.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  Bundle 扩展，提供资源文件加载方法
//

import Foundation
import UIKit

// MARK: - Bundle 扩展

public extension Bundle {

    // MARK: - 首选 Scale 列表

    /// 返回按优先级排序的 scale 列表
    /// 例如：iPhone3GS: [1, 2, 3], iPhone5: [2, 3, 1], iPhone6 Plus: [3, 2, 1]
    static var ls_preferredScales: [CGFloat] {
        let scale = UIScreen.main.scale

        switch scale {
        case 3:
            return [3, 2, 1]
        case 2:
            return [2, 3, 1]
        case 1:
            return [1, 2, 3]
        default:
            return [scale, 3, 2, 1].sorted(by: >)
        }
    }

    // MARK: - 查找带 Scale 的资源路径

    /// 查找带 scale 的资源路径
    /// - Parameters:
    ///   - name: 资源名称
    ///   - ext: 文件扩展名
    ///   - bundlePath: bundle 路径
    /// - Returns: 完整路径
    static func ls_pathForScaledResource(name: String, ofType ext: String?, inDirectory bundlePath: String) -> String? {
        for scale in ls_preferredScales {
            var scaleName = name
            if scale != 1 {
                scaleName = "\(name)@\(scale)x"
            }

            if let path = Bundle(path: bundlePath)?.path(forResource: scaleName, ofType: ext) {
                return path
            }
        }

        // 尝试不带 scale 的名称
        return Bundle(path: bundlePath)?.path(forResource: name, ofType: ext)
    }

    /// 查找带 scale 的资源路径（当前 bundle）
    /// - Parameters:
    ///   - name: 资源名称
    ///   - ext: 文件扩展名
    /// - Returns: 完整路径
    func ls_pathForScaledResource(name: String, ofType ext: String?) -> String? {
        return ls_pathForScaledResource(name: name, ofType: ext, inDirectory: nil)
    }

    /// 查找带 scale 的资源路径（指定子目录）
    /// - Parameters:
    ///   - name: 资源名称
    ///   - ext: 文件扩展名
    ///   - subpath: 子目录
    /// - Returns: 完整路径
    func ls_pathForScaledResource(name: String, ofType ext: String?, inDirectory subpath: String?) -> String? {
        for scale in Bundle.ls_preferredScales {
            var scaleName = name
            if scale != 1 {
                scaleName = "\(name)@\(scale)x"
            }

            if let path = self.path(forResource: scaleName, ofType: ext, inDirectory: subpath) {
                return path
            }
        }

        // 尝试不带 scale 的名称
        return self.path(forResource: name, ofType: ext, inDirectory: subpath)
    }
}

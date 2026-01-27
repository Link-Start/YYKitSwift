//
//  YYKitSwiftImage.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-26.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  YYKitSwift 图片模块 - 图片加载、解码和缓存
//

import UIKit

// MARK: - YYKitSwift 图片模块

/// YYKitSwift 图片模块
///
/// 此模块提供完整的图片处理功能，包括：
/// - 图片加载（网络图片、本地图片）
/// - 图片解码（GIF、WebP、APNG）
/// - 图片缓存（内存 + 磁盘）
/// - 动画图片支持
/// - UIImageView 扩展
///
/// ## 主要组件
///
/// - `LSImage`: 图片类
/// - `LSImageCache`: 图片缓存
/// - `LSWebImageManager`: 网络图片管理器
/// - `LSAnimatedImageView`: 动画图片视图
/// - `LSImageCoder`: 图片解码器
///
/// ## 使用示例
///
/// ```swift
/// // UIImageView 加载网络图片
/// imageView.ls_setImage(with: url)
///
/// // 使用缓存
/// let cache = LSImageCache.sharedCache
/// cache.setImage(image, forKey: "key")
/// ```
///
/// ## 依赖关系
///
/// - ⚠️ **依赖 Core**: 需要引入 YYKitSwiftCore
/// - ⚠️ **依赖 Cache**: 需要引入 YYKitSwiftCache
///
// MARK: - 模块导出

// 图片核心
@_exported import class YYKitSwift.LSImage
@_exported import class YYKitSwift.LSAnimatedImageView
@_exported import class YYKitSwift.LSFrameImage
@_exported import class YYKitSwift.LSSpriteSheetImage

// 图片解码
@_exported import class YYKitSwift.LSImageCoder

// 图片缓存
@_exported import class YYKitSwift.LSImageCache

// 网络图片
@_exported import class YYKitSwift.LSWebImageManager
@_exported import class YYKitSwift.LSWebImageOperation
@_exported import struct YYKitSwift.LSWebImageOptions

// UIImageView 扩展
@_exported import class YYKitSwift.UIImage_YYKitSwift

//
//  LSWebImageOptions.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  Web 图片选项和类型定义
//

#if canImport(UIKit)
import UIKit
import Foundation

// MARK: - Web 图片选项

/// 控制图像操作的选项
public struct LSWebImageOptions: OptionSet {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    /// 下载图像时在状态栏显示网络活动
    static let showNetworkActivity = LSWebImageOptions(rawValue: 1 << 0)

    /// 下载期间显示渐进式/隔行/基线图像（与 Web 浏览器相同）
    static let progressive = LSWebImageOptions(rawValue: 1 << 1)

    /// 下载期间显示模糊的渐进式 JPEG 或隔行 PNG 图像
    /// 这将忽略基线图像以获得更好的用户体验
    static let progressiveBlur = LSWebImageOptions(rawValue: 1 << 2)

    /// 使用 NSURLCache 而不是 LSImageCache
    static let useNSURLCache = LSWebImageOptions(rawValue: 1 << 3)

    /// 允许不受信任的 SSL 证书
    static let allowInvalidSSLCertificates = LSWebImageOptions(rawValue: 1 << 4)

    /// 允许后台任务在应用处于后台时下载图像
    static let allowBackgroundTask = LSWebImageOptions(rawValue: 1 << 5)

    /// 处理 NSHTTPCookieStore 中存储的 cookies
    static let handleCookies = LSWebImageOptions(rawValue: 1 << 6)

    /// 从远程加载图像并刷新图像缓存
    static let refreshImageCache = LSWebImageOptions(rawValue: 1 << 7)

    /// 不从/到磁盘缓存加载/存储图像
    static let ignoreDiskCache = LSWebImageOptions(rawValue: 1 << 8)

    /// 在为新 URL 设置视图图像之前不更改视图的图像
    static let ignorePlaceHolder = LSWebImageOptions(rawValue: 1 << 9)

    /// 忽略图像解码
    /// 这可能用于不显示的图像下载
    static let ignoreImageDecoding = LSWebImageOptions(rawValue: 1 << 10)

    /// 忽略多帧图像解码
    /// 这将把 GIF/APNG/WebP/ICO 图像处理为单帧图像
    static let ignoreAnimatedImage = LSWebImageOptions(rawValue: 1 << 11)

    /// 使用淡入动画将图像设置到视图
    /// 这将在图像视图的图层上添加"淡入"动画以获得更好的用户体验
    static let setImageWithFadeAnimation = LSWebImageOptions(rawValue: 1 << 12)

    /// 图像获取完成时不将图像设置到视图
    /// 您可以手动设置图像
    static let avoidSetImage = LSWebImageOptions(rawValue: 1 << 13)

    /// 此标志将在 URL 下载失败时将 URL 添加到黑名单（内存中），
    /// 因此库不会继续尝试
    static let ignoreFailedURL = LSWebImageOptions(rawValue: 1 << 14)
}

// MARK: - 图像来源类型

/// 指示图像的来源
public enum LSWebImageFromType: UInt {
    /// 无值
    case none = 0

    /// 立即从内存缓存获取
    /// 如果调用 "setImageWithURL:..." 并且图像已经在内存中，
    /// 则在同一调用中将获得此值
    case memoryCacheFast

    /// 从内存缓存获取
    case memoryCache

    /// 从磁盘缓存获取
    case diskCache

    /// 从远程（Web 或文件路径）获取
    case remote
}

// MARK: - 图像获取阶段

/// 指示图像获取完成阶段
public enum LSWebImageStage: Int {
    /// 不完整，渐进式图像
    case progress = -1

    /// 已取消
    case cancelled = 0

    /// 已完成（成功或失败）
    case finished = 1
}

// MARK: - 闭包类型

/// 远程图像获取进度中调用的块
///
/// - Parameters:
///   - receivedSize: 当前接收大小（字节）
///   - expectedSize: 预期总大小（字节），-1 表示未知
public typealias LSWebImageProgressBlock = @Sendable (_ receivedSize: Int, _ expectedSize: Int) -> Void

/// 远程图像获取完成之前调用的块，用于进行额外的图像处理
///
/// 此块将在 `LSWebImageCompletionBlock` 之前调用，给您一个机会
/// 进行额外的图像处理（如调整大小或裁剪）。如果不需要转换图像，
/// 只需返回 `image` 参数。
///
/// - Parameters:
///   - image: 从 URL 获取的图像
///   - url: 图像 URL（远程或本地文件路径）
/// - Returns: 转换后的图像
public typealias LSWebImageTransformBlock = @Sendable (_ image: UIImage, _ url: URL) -> UIImage?

/// 图像获取完成或取消时调用的块
///
/// - Parameters:
///   - image: 图像
///   - url: 图像 URL（远程或本地文件路径）
///   - from: 图像的来源
///   - stage: 图像获取阶段
///   - error: 图像获取期间的错误
public typealias LSWebImageCompletionBlock = @Sendable (
    _ image: UIImage?,
    _ url: URL,
    _ from: LSWebImageFromType,
    _ stage: LSWebImageStage,
    _ error: Error?
) -> Void
#endif

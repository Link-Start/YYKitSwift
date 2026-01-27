//
//  LSWebImageManager.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  Web 图片管理器 - 创建和管理 Web 图片操作
//

#if canImport(UIKit)
import UIKit
import Foundation

/// Web 图片管理器 - 创建和管理 Web 图片操作
///
/// 此类用于创建和管理图像下载操作。
/// 支持缓存、自定义转换和请求头过滤。
///
/// - Note: 此类使用 NSLock 保护内部状态，在 Swift 6 严格并发模式下
///         使用 @unchecked Sendable 表示手动实现了线程安全。
@unchecked Sendable
public class LSWebImageManager {

    // MARK: - 共享实例

    /// 返回全局共享的 LSWebImageManager 实例
    public static let sharedManager: LSWebImageManager = {
        return LSWebImageManager(cache: LSImageCache.sharedCache, queue: OperationQueue())
    }()

    // MARK: - 属性

    /// 图像缓存
    public var cache: LSImageCache?

    /// 操作队列
    ///
    /// 可以将其设置为 nil 以使新操作立即开始而不使用队列
    public var queue: OperationQueue? {
        didSet {
            // 配置队列
            queue?.maxConcurrentOperationCount = 6
        }
    }

    /// 共享的转换块
    ///
    /// 当调用 `requestImageWithURL:options:progress:transform:completion` 且 `transform` 为 nil 时，将使用此块
    public var sharedTransformBlock: LSWebImageTransformBlock?

    /// 图像请求超时时间（秒），默认是 15
    public var timeout: TimeInterval = 15

    /// NSURLCredential 使用的用户名，默认是 nil
    public var username: String?

    /// NSURLCredential 使用的密码，默认是 nil
    public var password: String?

    /// 图像 HTTP 请求头，默认是 "Accept:image/webp,image/*;q=0.8"
    public var headers: [String: String] = [
        "Accept": "image/webp,image/*;q=0.8"
    ]

    /// 为每个图像 HTTP 请求调用的块，用于进行额外的 HTTP 头处理
    ///
    /// 使用此块为指定的 URL 添加或移除 HTTP 头字段
    public var headersFilter: (@Sendable (URL, [String: String]?) -> [String: String]?)?

    /// 为每个图像操作调用的块
    ///
    /// 使用此块为指定的 URL 提供自定义的图像缓存键
    public var cacheKeyFilter: (@Sendable (URL) -> String)?

    // MARK: - 内部属性

    private var failedURLs: Set<String> = []
    private let failedURLsLock = NSLock()
    private var runningOperations: [String: LSWebImageOperation] = [:]
    private let operationsLock = NSLock()

    // MARK: - 初始化

    /// 使用图像缓存和操作队列创建管理器
    ///
    /// - Parameters:
    ///   - cache: 使用的图像缓存（传 nil 以避免图像缓存）
    ///   - queue: 操作队列（传 nil 使新操作立即开始而不使用队列）
    /// - Returns: 新的管理器
    public convenience init(cache: LSImageCache?, queue: OperationQueue?) {
        self.init(cache: cache)
        self.queue = queue
        self.queue?.maxConcurrentOperationCount = 6
    }

    /// 使用图像缓存创建管理器
    ///
    /// - Parameter cache: 使用的图像缓存（传 nil 以避免图像缓存）
    public init(cache: LSImageCache?) {
        self.cache = cache
    }

    // MARK: - 请求方法

    /// 创建并返回一个新的图像操作，操作将立即开始
    ///
    /// - Parameters:
    ///   - url: 图像 URL（远程或本地文件路径）
    ///   - options: 控制图像操作的选项
    ///   - progress: 将在后台线程调用的进度块（传 nil 以避免）
    ///   - transform: 将在后台线程调用的转换块（传 nil 以避免）
    ///   - completion: 将在后台线程调用的完成块（传 nil 以避免）
    /// - Returns: 新的图像操作
    @discardableResult
    public func requestImage(
        with url: URL?,
        options: LSWebImageOptions = [],
        progress: LSWebImageProgressBlock? = nil,
        transform: LSWebImageTransformBlock? = nil,
        completion: LSWebImageCompletionBlock? = nil
    ) -> LSWebImageOperation? {
        guard let url = url else {
            DispatchQueue.main.async {
                completion?(nil, URL(fileURLWithPath: ""), .none, .finished, NSError(domain: "LSWebImageManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            }
            return nil
        }

        // 检查失败 URL 黑名单
        if options.contains(.ignoreFailedURL) {
            failedURLsLock.lock()
            let isFailed = failedURLs.contains(url.absoluteString)
            failedURLsLock.unlock()

            if isFailed {
                DispatchQueue.main.async {
                    completion?(nil, url, .none, .finished, NSError(domain: "LSWebImageManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "URL is in blacklist"]))
                }
                return nil
            }
        }

        let cacheKey = self.cacheKey(for: url)

        // 检查内存缓存
        if !options.contains(.refreshImageCache) && !options.contains(.ignoreDiskCache) {
            if let cachedImage = cache?.getImage(forKey: cacheKey) {
                DispatchQueue.main.async {
                    completion?(cachedImage, url, .memoryCacheFast, .finished, nil)
                }
                return nil
            }
        }

        // 创建操作
        let operation = LSWebImageOperation(
            url: url,
            options: options,
            cache: cache,
            timeout: timeout,
            headers: headers(for: url),
            progress: progress,
            transform: transform ?? sharedTransformBlock
        ) { [weak self] image, url, from, stage, error in
            guard let self = self else { return }

            // 移除运行中的操作
            self.operationsLock.lock()
            self.runningOperations.removeValue(forKey: cacheKey)
            self.operationsLock.unlock()

            // 处理错误
            if let error = error, options.contains(.ignoreFailedURL) {
                self.failedURLsLock.lock()
                self.failedURLs.insert(url.absoluteString)
                self.failedURLsLock.unlock()
            }

            completion?(image, url, from, stage, error)
        }

        // 添加到运行中的操作
        operationsLock.lock()
        runningOperations[cacheKey] = operation
        operationsLock.unlock()

        // 添加到队列或直接启动
        if let queue = queue {
            queue.addOperation(operation)
        } else {
            operation.start()
        }

        return operation
    }

    // MARK: - 辅助方法

    /// 返回指定 URL 的 HTTP 头
    ///
    /// - Parameter url: 指定的 URL
    /// - Returns: HTTP 头
    public func headers(for url: URL) -> [String: String]? {
        if let filter = headersFilter {
            return filter(url, headers)
        }
        return headers
    }

    /// 返回指定 URL 的缓存键
    ///
    /// - Parameter url: 指定的 URL
    /// - Returns: 在 LSImageCache 中使用的缓存键
    public func cacheKey(for url: URL) -> String {
        if let filter = cacheKeyFilter {
            return filter(url)
        }
        return url.absoluteString
    }

    /// 取消指定 URL 的图像操作
    ///
    /// - Parameter url: 图像 URL
    public func cancelImageRequest(with url: URL) {
        let cacheKey = self.cacheKey(for: url)

        operationsLock.lock()
        let operation = runningOperations[cacheKey]
        runningOperations.removeValue(forKey: cacheKey)
        operationsLock.unlock()

        operation?.cancel()
    }

    /// 取消所有图像操作
    public func cancelAllRequests() {
        operationsLock.lock()
        let operations = Array(runningOperations.values)
        runningOperations.removeAll()
        operationsLock.unlock()

        for operation in operations {
            operation.cancel()
        }
    }

    /// 清空失败 URL 黑名单
    public func clearFailedURLs() {
        failedURLsLock.lock()
        failedURLs.removeAll()
        failedURLsLock.unlock()
    }
}
#endif

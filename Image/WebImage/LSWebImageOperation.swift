//
//  LSWebImageOperation.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  Web 图片操作 - 处理单个图片下载任务
//

#if canImport(UIKit)
import UIKit
import Foundation

/// Web 图片操作 - 处理单个图片下载任务
///
/// 此类继承自 Operation，用于管理单个图像的下载过程。
/// 支持进度回调、取消操作和后台任务。
public class LSWebImageOperation: Operation {

    // MARK: - 属性

    /// 图像 URL
    public private(set) var url: URL

    /// 选项
    public private(set) var options: LSWebImageOptions

    /// 缓存键
    public private(set) var cacheKey: String

    // MARK: - 内部属性

    private var progressBlock: LSWebImageProgressBlock?
    private var transformBlock: LSWebImageTransformBlock?
    private var completionBlock: LSWebImageCompletionBlock?

    private var urlSession: URLSession?
    private var urlSessionTask: URLSessionDataTask?
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid

    private var executingValue: Bool = false
    private var finishedValue: Bool = false
    private let stateLock = NSLock()

    private var cache: LSImageCache?
    private var timeout: TimeInterval = 15
    private var headers: [String: String]?

    /// 是否已取消
    public private(set) var isCancelledValue = false

    // MARK: - 重写 Operation 属性

    public override var isAsynchronous: Bool {
        return true
    }

    public override var isExecuting: Bool {
        return executingValue
    }

    public override var isFinished: Bool {
        return finishedValue
    }

    public override var isCancelled: Bool {
        return isCancelledValue
    }

    // MARK: - 初始化

    /// 初始化 Web 图片操作
    ///
    /// - Parameters:
    ///   - url: 图像 URL
    ///   - options: 选项
    ///   - cache: 图像缓存
    ///   - timeout: 超时时间
    ///   - headers: HTTP 头部
    ///   - progress: 进度回调
    ///   - transform: 转换回调
    ///   - completion: 完成回调
    init(
        url: URL,
        options: LSWebImageOptions,
        cache: LSImageCache?,
        timeout: TimeInterval,
        headers: [String: String]?,
        progress: LSWebImageProgressBlock?,
        transform: LSWebImageTransformBlock?,
        completion: LSWebImageCompletionBlock?
    ) {
        self.url = url
        self.options = options
        self.cache = cache
        self.timeout = timeout
        self.headers = headers
        self.progressBlock = progress
        self.transformBlock = transform
        self.completionBlock = completion
        self.cacheKey = url.absoluteString

        super.init()
    }

    // MARK: - 启动和取消

    public override func start() {
        stateLock.lock()

        if isCancelledValue {
            stateLock.unlock()
            finish()
            return
        }

        executingValue = true
        stateLock.unlock()

        // 开始后台任务
        if options.contains(.allowBackgroundTask) {
            backgroundTaskID = UIApplication.shared.beginBackgroundTask(expirationHandler: { [weak self] in
                self?.cancel()
            })
        }

        main()
    }

    public override func main() {
        // 首先尝试从缓存获取
        if !options.contains(.refreshImageCache) && !options.contains(.ignoreDiskCache) {
            if let cachedImage = cache?.getImage(forKey: cacheKey) {
                callCompletion(cachedImage, .diskCache, .finished, nil)
                finish()
                return
            }
        }

        // 从网络加载
        loadImageFromURL()
    }

    public override func cancel() {
        stateLock.lock()
        isCancelledValue = true
        stateLock.unlock()

        urlSessionTask?.cancel()
        urlSession?.invalidateAndCancel()

        super.cancel()
    }

    // MARK: - 私有方法

    private func loadImageFromURL() {
        // 创建 URL Session
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeout
        configuration.urlCache = options.contains(.useNSURLCache) ? URLCache.shared : nil

        if let headers = headers {
            configuration.httpAdditionalHeaders = headers
        }

        urlSession = URLSession(configuration: configuration, delegate: nil, delegateQueue: nil)

        // 创建数据任务
        urlSessionTask = urlSession?.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }

            if self.isCancelled {
                self.finish()
                return
            }

            if let error = error {
                self.callCompletion(nil, .none, .finished, error)
                self.finish()
                return
            }

            guard let data = data else {
                let error = NSError(domain: "LSWebImageOperation", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                self.callCompletion(nil, .none, .finished, error)
                self.finish()
                return
            }

            // 处理图像数据
            self.processImageData(data)
        }

        urlSessionTask?.resume()

        // 显示网络活动指示器
        if options.contains(.showNetworkActivity) {
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
        }
    }

    private func processImageData(_ data: Data) {
        // 应用转换（如果有）
        let finalImage: UIImage?

        if options.contains(.ignoreImageDecoding) {
            finalImage = nil
        } else if options.contains(.ignoreAnimatedImage) {
            finalImage = UIImage(data: data)
        } else {
            finalImage = LSImage(data: data, scale: UIScreen.main.scale)
        }

        guard let image = finalImage else {
            let error = NSError(domain: "LSWebImageOperation", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to decode image"])
            callCompletion(nil, .none, .finished, error)
            finish()
            return
        }

        // 应用自定义转换
        let transformedImage: UIImage?
        if let transform = transformBlock {
            transformedImage = transform(image, url)
        } else {
            transformedImage = image
        }

        // 缓存图像
        if let img = transformedImage, !options.contains(.ignoreDiskCache) {
            cache?.setImage(img, imageData: data, forKey: cacheKey, withType: .all)
        }

        callCompletion(transformedImage, .remote, .finished, nil)
        finish()
    }

    private func callCompletion(_ image: UIImage?, _ from: LSWebImageFromType, _ stage: LSWebImageStage, _ error: Error?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // 隐藏网络活动指示器
            if self.options.contains(.showNetworkActivity) {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }

            // 结束后台任务
            if self.backgroundTaskID != .invalid {
                UIApplication.shared.endBackgroundTask(self.backgroundTaskID)
                self.backgroundTaskID = .invalid
            }

            self.completionBlock?(image, self.url, from, stage, error)
        }
    }

    private func finish() {
        stateLock.lock()
        executingValue = false
        finishedValue = true
        stateLock.unlock()
    }
}
#endif

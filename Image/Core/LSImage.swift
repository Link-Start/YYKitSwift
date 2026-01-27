//
//  LSImage.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  图片基类 - 支持动画 WebP, APNG 和 GIF 格式
//

#if canImport(UIKit)
import UIKit
import ImageIO
import Foundation

// Photos 框架导入（用于保存到相册）
#if canImport(Photos)
import Photos
#endif

// MARK: - LSAnimatedImage 协议

/// 动画图片协议
///
/// 子类化 UIImage 并实现此协议，使实例能够在 LSAnimatedImageView 中显示动画。
public protocol LSAnimatedImage: NSObjectProtocol {

    /// 总动画帧数
    /// 如果帧数小于 1，则以下方法将被忽略
    func animatedImageFrameCount() -> UInt

    /// 动画循环次数，0 表示无限循环
    func animatedImageLoopCount() -> UInt

    /// 每帧字节数 (内存中)，可用于优化内存缓冲区大小
    func animatedImageBytesPerFrame() -> UInt

    /// 返回指定索引的帧图像
    /// 此方法可能在后台线程调用
    /// - Parameter index: 帧索引 (从 0 开始)
    func animatedImageFrame(at index: UInt) -> UIImage?

    /// 返回指定索引的帧持续时间
    /// - Parameter index: 帧索引 (从 0 开始)
    func animatedImageDuration(at index: UInt) -> TimeInterval

    /// 可选：图像坐标中定义的子矩形，用于显示
    /// 可用于显示单张图像的精灵动画
    /// - Parameter index: 帧索引 (从 0 开始)
    func animatedImageContentsRect(at index: UInt) -> CGRect
}

// MARK: - LSImage 类

/// LSImage 是显示动画图像数据的高级方式
///
/// 它是完全兼容的 `UIImage` 子类，扩展了 UIImage 以支持
/// 动画 WebP、APNG 和 GIF 格式图像数据解码。还支持 NSCoding 协议
/// 来归档和解档多帧图像数据。
///
/// 如果图像是从多帧图像数据创建的，并且想要播放动画，
/// 请尝试用 `LSAnimatedImageView` 替换 UIImageView。
public class LSImage: UIImage, LSAnimatedImage {

    // MARK: - 属性

    /// 如果图像是从数据或文件创建的，此值指示数据类型
    public private(set) var animatedImageType: LSImageType = .unknown

    /// 如果图像是从动画图像数据（多帧 GIF/APNG/WebP）创建的，
    /// 此属性存储原始图像数据
    public private(set) var animatedImageData: Data?

    /// 如果所有帧图像都加载到内存中，总内存使用量（字节）
    /// 如果图像不是从多帧图像数据创建的，值为 0
    public private(set) var animatedImageMemorySize: UInt = 0

    /// 预加载所有帧图像到内存
    ///
    /// 将此属性设置为 `true` 将阻塞调用线程以解码所有动画帧图像到内存，
    /// 设置为 `false` 将释放预加载的帧。
    /// 如果图像被多个图像视图共享（如表情符号），预加载所有帧将减少 CPU 消耗。
    public var preloadAllAnimatedImageFrames: Bool = false {
        didSet {
            if preloadAllAnimatedImageFrames {
                preloadAllFrames()
            } else {
                clearPreloadedFrames()
            }
        }
    }

    // MARK: - 内部属性

    private var _frameCount: UInt = 0
    private var _loopCount: UInt = 0
    private var _decoder: LSImageDecoder?
    private var _preloadedFrames: [UInt: UIImage] = [:]
    private let frameLock = NSLock()

    // MARK: - 初始化

    /// 从 bundle 加载图像 (无缓存)
    ///
    /// - Parameter name: 图像名称
    /// - Returns: LSImage 实例，如果出错返回 nil
    public override convenience init?(named name: String) {
        // 查找图像文件
        var scale = UIScreen.main.scale
        var path = Bundle.main.path(forResource: name, ofType: "")

        // 如果没有找到，尝试带 @2x/@3x 的路径
        if path == nil {
            path = Bundle.main.path(forResource: name, ofType: "")
            if path == nil {
                // 尝试不同的 scale
                for s in [3, 2, 1] as [CGFloat] {
                    let scaleName = name.appendingFormat("@%dx", Int(s))
                    path = Bundle.main.path(forResource: scaleName, ofType: "")
                    if path != nil {
                        scale = s
                        break
                    }
                }
            }
        }

        guard let imagePath = path else {
            return nil
        }

        self.init(contentsOfFile: imagePath, scale: scale)
    }

    /// 从文件路径加载图像
    ///
    /// - Parameter path: 文件路径
    /// - Returns: LSImage 实例，如果出错返回 nil
    public convenience init?(contentsOfFile path: String) {
        self.init(contentsOfFile: path, scale: UIScreen.main.scale)
    }

    /// 从文件路径加载图像（指定 scale）
    ///
    /// - Parameters:
    ///   - path: 文件路径
    ///   - scale: 图像 scale
    /// - Returns: LSImage 实例，如果出错返回 nil
    public init?(contentsOfFile path: String, scale: CGFloat) {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return nil
        }
        self.init(data: data, scale: scale)
    }

    /// 从数据加载图像
    ///
    /// - Parameter data: 图像数据
    /// - Returns: LSImage 实例，如果出错返回 nil
    public convenience init?(data: Data) {
        self.init(data: data, scale: 1)
    }

    /// 从数据加载图像（指定 scale）
    ///
    /// - Parameters:
    ///   - data: 图像数据
    ///   - scale: 图像 scale
    /// - Returns: LSImage 实例，如果出错返回 nil
    public init?(data: Data, scale: CGFloat) {
        // 检测图像类型
        let type = LSImageTypeDetector.detectType(data)
        let decoder = LSImageDecoder(data: data, scale: scale)

        guard decoder != nil else {
            // 如果解码失败，尝试使用系统解码器
            super.init(data: data, scale: scale)
            return
        }

        // 初始化为单帧图像
        guard let firstFrame = decoder?.frame(at: 0, decodeForDisplay: false) else {
            super.init(data: data, scale: scale)
            return
        }

        guard let cgImage = firstFrame.image?.cgImage else {
            super.init(data: data, scale: scale)
            return
        }

        // 使用 UIImage 的初始化方法
        super.init(cgImage: cgImage, scale: scale, orientation: .up)

        // 设置多帧图像属性
        _decoder = decoder
        animatedImageData = data
        animatedImageType = type
        _frameCount = decoder?.frameCount ?? 1
        _loopCount = decoder?.loopCount ?? 0

        // 计算内存大小
        calculateMemorySize()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        // 从 NSCoding 恢复数据
        if let data = coder.decodeObject(forKey: "animatedImageData") as? Data {
            animatedImageData = data
            animatedImageType = LSImageType(rawValue: coder.decodeInteger(forKey: "animatedImageType")) ?? .unknown
            _frameCount = UInt(coder.decodeInteger(forKey: "frameCount"))
            _loopCount = UInt(coder.decodeInteger(forKey: "loopCount"))

            // 创建解码器
            let scale: CGFloat
            if coder.containsValue(forKey: "scale") {
                scale = coder.decodeFloat(forKey: "scale")
            } else {
                scale = 1
            }

            _decoder = LSImageDecoder(data: data, scale: scale)

            calculateMemorySize()
        }
    }

    // MARK: - NSCoding

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)

        coder.encode(animatedImageData, forKey: "animatedImageData")
        coder.encode(Int(animatedImageType.rawValue), forKey: "animatedImageType")
        coder.encode(Int(_frameCount), forKey: "frameCount")
        coder.encode(Int(_loopCount), forKey: "loopCount")
        coder.encode(scale, forKey: "scale")
    }

    // MARK: - LSAnimatedImage 协议

    public func animatedImageFrameCount() -> UInt {
        return _frameCount
    }

    public func animatedImageLoopCount() -> UInt {
        return _loopCount
    }

    public func animatedImageBytesPerFrame() -> UInt {
        if _frameCount > 0 && animatedImageMemorySize > 0 {
            return animatedImageMemorySize / _frameCount
        }
        return 0
    }

    public func animatedImageFrame(at index: UInt) -> UIImage? {
        guard index < _frameCount else { return nil }

        // 检查预加载的帧
        frameLock.lock()
        if let frame = _preloadedFrames[index] {
            frameLock.unlock()
            return frame
        }
        frameLock.unlock()

        // 从解码器获取帧
        return _decoder?.frame(at: index, decodeForDisplay: false)?.image
    }

    public func animatedImageDuration(at index: UInt) -> TimeInterval {
        guard index < _frameCount else { return 0 }
        return _decoder?.frameDuration(at: index) ?? 0
    }

    public func animatedImageContentsRect(at index: UInt) -> CGRect {
        return CGRect(x: 0, y: 0, width: 1, height: 1)
    }

    // MARK: - 私有方法

    private func calculateMemorySize() {
        guard _frameCount > 0 else { return }

        var totalSize: UInt = 0
        for i in 0..<_frameCount {
            if let frame = _decoder?.frame(at: i, decodeForDisplay: false),
               let cgImage = frame.image?.cgImage {
                let width = cgImage.width
                let height = cgImage.height
                let bitsPerComponent = cgImage.bitsPerComponent
                let bytesPerPixel = cgImage.bitsPerPixel / 8
                totalSize += UInt(width * height * bytesPerPixel)
            }
        }

        animatedImageMemorySize = totalSize
    }

    private func preloadAllFrames() {
        guard _frameCount > 0 && _decoder != nil else { return }

        frameLock.lock()
        defer { frameLock.unlock() }

        // 避免重复加载
        if !_preloadedFrames.isEmpty {
            return
        }

        for i in 0..<_frameCount {
            if let frame = _decoder?.frame(at: i, decodeForDisplay: true),
               let image = frame.image {
                _preloadedFrames[i] = image
            }
        }
    }

    private func clearPreloadedFrames() {
        frameLock.lock()
        _preloadedFrames.removeAll()
        frameLock.unlock()
    }
}

// MARK: - UIImage 扩展

public extension UIImage {

    /// 创建解码后的图像副本
    ///
    /// 如果图像已经被解码或无法解码，则返回自身
    func ls_imageByDecoded() -> UIImage {
        // 检查是否已经是解码格式
        if let cgImage = self.cgImage {
            let alphaInfo = cgImage.alphaInfo
            if alphaInfo == .none || alphaInfo == .noneSkipFirst ||
               alphaInfo == .noneSkipLast || alphaInfo == .premultipliedFirst ||
               alphaInfo == .premultipliedLast {
                return self
            }
        }

        // 解码图像
        guard let decodedCGImage = LSCGImageHelper.createDecodedCopy(self.cgImage, decodeForDisplay: true) else {
            return self
        }

        return UIImage(cgImage: decodedCGImage, scale: scale, orientation: imageOrientation)
    }

    /// 是否可以在不额外解码的情况下显示
    var ls_isDecodedForDisplay: Bool {
        guard let cgImage = self.cgImage else { return false }
        let alphaInfo = cgImage.alphaInfo
        return alphaInfo == .none || alphaInfo == .noneSkipFirst ||
               alphaInfo == .noneSkipLast || alphaInfo == .premultipliedFirst ||
               alphaInfo == .premultipliedLast
    }

    /// 保存图像到相册
    ///
    /// - Parameter completionBlock: 完成回调 (在主线程调用)
    func ls_saveToAlbum(completionBlock: ((URL?, Error?) -> Void)?) {
        // 如果是动画图像，保存原始数据
        if let lsImage = self as? LSImage, let data = lsImage.animatedImageData {
            _saveAnimatedImageData(data, completionBlock: completionBlock)
            return
        }

        // 保存为 JPEG 或 PNG
        var imageData: Data?
        if let cgImage = self.cgImage, let alphaInfo = cgImage.alphaInfo {
            let hasAlpha = alphaInfo != .none && alphaInfo != .noneSkipFirst && alphaInfo != .noneSkipLast
            if hasAlpha {
                imageData = ls_imageDataRepresentation()
            } else {
                // JPEG 不支持 alpha
                imageData = ls_imageDataRepresentation()
            }
        }

        guard let data = imageData else {
            DispatchQueue.main.async {
                completionBlock?(nil, NSError(domain: "LSImage", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法获取图像数据"]))
            }
            return
        }

        // 使用 PHPhotoLibrary 保存
        #if canImport(Photos)
        var placeholderID: String?
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetCreationRequest.forAsset()
            let options = PHAssetResourceCreationOptions()
            options.originalFilename = "image.jpg"
            placeholderID = request.placeholderForCreatedAsset?.localIdentifier
            if let imageData = data as? NSData {
                request.addResource(with: .photo, data: imageData, options: options)
            }
        }) { success, error in
            DispatchQueue.main.async {
                if success, let placeholderID = placeholderID {
                    let result = PHAsset.fetchAssets(withLocalIdentifiers: [placeholderID], options: nil)
                    if let asset = result.firstObject {
                        // 成功保存
                        completionBlock?(nil, nil)
                    } else {
                        completionBlock?(nil, error)
                    }
                } else {
                    completionBlock?(nil, error)
                }
            }
        }
        #else
        // 旧方法
        completionBlock?(nil, NSError(domain: "LSImage", code: -2, userInfo: [NSLocalizedDescriptionKey: "未导入 Photos 框架"]))
        #endif
    }

    /// 保存动画图像数据到相册
    ///
    /// - Parameters:
    ///   - data: 动画图像数据（GIF/APNG）
    ///   - completionBlock: 完成回调
    private func _saveAnimatedImageData(_ data: Data, completionBlock: ((URL?, Error?) -> Void)?) {
        // 写入临时文件
        let tempDir = NSTemporaryDirectory()
        let tempURL = URL(fileURLWithPath: tempDir).appendingPathComponent("ls_temp_\(UUID().uuidString).gif")

        do {
            try data.write(to: tempURL)

            // 使用 PHPhotoLibrary 保存
            #if canImport(Photos)
            var placeholderID: String?
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCreationRequest.forAsset()
                let options = PHAssetResourceCreationOptions()
                options.originalFilename = "animation.gif"

                // 从文件 URL 创建资源
                if let resource = PHAssetResourceCreationOptions(from: tempURL) {
                    request.addResource(with: .photo, fileURL: tempURL, options: options)
                    placeholderID = request.placeholderForCreatedAsset?.localIdentifier
                }
            }) { [tempURL] success, error in
                // 清理临时文件
                try? FileManager.default.removeItem(at: tempURL)

                DispatchQueue.main.async {
                    if success, let placeholderID = placeholderID {
                        let result = PHAsset.fetchAssets(withLocalIdentifiers: [placeholderID], options: nil)
                        if let asset = result.firstObject {
                            // 获取资源 URL
                            let options = PHContentEditingInputRequestOptions()
                            let isSynchronous = true
                            asset.requestContentEditingInput(with: options, completionHandler: { input, _ in
                                if let input = input {
                                    DispatchQueue.main.async {
                                        completionBlock?(input.fullSizeImageURL, nil)
                                    }
                                }
                            })
                        } else {
                            completionBlock?(nil, error)
                        }
                    } else {
                        completionBlock?(nil, error)
                    }
                }
            }
            #else
            // 清理临时文件
            try? FileManager.default.removeItem(at: tempURL)

            DispatchQueue.main.async {
                completionBlock?(nil, NSError(domain: "LSImage", code: -2, userInfo: [NSLocalizedDescriptionKey: "未导入 Photos 框架"]))
            }
            #endif
        } catch {
            // 清理临时文件
            try? FileManager.default.removeItem(at: tempURL)

            DispatchQueue.main.async {
                completionBlock?(nil, error)
            }
        }
    }

    /// 返回图像的"最佳"数据表示
    ///
    /// 转换规则：
    /// 1. 如果图像是从动画 GIF/APNG/WebP 创建的，返回原始数据
    /// 2. 根据 alpha 信息返回 PNG 或 JPEG(0.9) 表示
    func ls_imageDataRepresentation() -> Data? {
        // 如果是 LSImage 且有原始数据，返回原始数据
        if let lsImage = self as? LSImage, let data = lsImage.animatedImageData {
            return data
        }

        guard let cgImage = self.cgImage else { return nil }

        // 检查是否有 alpha 通道
        let hasAlpha = cgImage.alphaInfo != .none &&
                       cgImage.alphaInfo != .noneSkipFirst &&
                       cgImage.alphaInfo != .noneSkipLast

        let type: LSImageType = hasAlpha ? .png : .jpeg
        let quality: CGFloat = hasAlpha ? 1.0 : 0.9

        return LSCGImageHelper.createEncodedData(cgImage, type: type, quality: quality)
    }
}

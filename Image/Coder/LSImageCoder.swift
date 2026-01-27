//
//  LSImageCoder.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  图片编解码器 - 支持 GIF, PNG, JPEG, WebP, APNG 等格式
//

#if canImport(UIKit)
import UIKit
import ImageIO
import CoreGraphics
import Accelerate
import Foundation
import zlib

// MARK: - 图片类型枚举

/// 图片文件类型
public enum LSImageType: UInt {
    case unknown = 0      ///< 未知类型
    case jpeg             ///< jpeg, jpg
    case jpeg2000         ///< jp2
    case tiff             ///< tiff, tif
    case bmp              ///< bmp
    case ico              ///< ico
    case icns             ///< icns
    case gif              ///< gif
    case png              ///< png
    case webP             ///< webp (iOS 14+)
    case other            ///< 其他图片格式
}

// MARK: - APNG 帧处理方法

/// 帧处理方法 - 指定在渲染下一帧之前如何处理当前帧的区域
public enum LSImageDisposeMethod: UInt {
    /// 不做任何处理，画布内容保持原样
    case none = 0
    /// 将帧区域清除为完全透明的黑色
    case background
    /// 将帧区域恢复到之前的内容
    case previous
}

// MARK: - APNG 混合操作

/// 混合操作 - 指定当前帧的透明像素如何与前一帧画布混合
public enum LSImageBlendOperation: UInt {
    /// 包括 alpha 在内的所有颜色分量覆盖画布区域的当前内容
    case none = 0
    /// 帧应该基于其 alpha 合成到输出缓冲区
    case over
}

// MARK: - WebP 预设类型

/// WebP 编码预设类型
@available(iOS 14.0, *)
public enum LSImagePreset: UInt {
    case defaultPreset = 0  ///< 默认预设
    case picture            ///< 数字图片，如肖像、室内拍摄
    case photo              ///< 户外照片，自然光线
    case drawing            ///< 手绘或线条图，高对比度细节
    case icon               ///< 小型彩色图像
    case text               ///< 文本类
}

// MARK: - 图片帧数据类

/// 图片帧数据类
public class LSImageFrame: NSObject, NSCopying {

    /// 帧索引 (从 0 开始)
    public var index: UInt = 0

    /// 帧宽度
    public var width: UInt = 0

    /// 帧高度
    public var height: UInt = 0

    /// 帧在画布中的 X 偏移量 (左下角坐标系)
    public var offsetX: UInt = 0

    /// 帧在画布中的 Y 偏移量 (左下角坐标系)
    public var offsetY: UInt = 0

    /// 帧持续时间 (秒)
    public var duration: TimeInterval = 0

    /// 帧处理方法
    public var dispose: LSImageDisposeMethod = .none

    /// 帧混合操作
    public var blend: LSImageBlendOperation = .none

    /// 帧图像
    public var image: UIImage?

    // MARK: - 初始化

    public override init() {
        super.init()
    }

    /// 使用图像创建帧
    public convenience init(image: UIImage) {
        self.init()
        self.image = image
        self.width = UInt(image.cgImage?.width ?? 0)
        self.height = UInt(image.cgImage?.height ?? 0)
    }

    // MARK: - NSCopying

    public func copy(with zone: NSZone? = nil) -> Any {
        let frame = LSImageFrame()
        frame.index = index
        frame.width = width
        frame.height = height
        frame.offsetX = offsetX
        frame.offsetY = offsetY
        frame.duration = duration
        frame.dispose = dispose
        frame.blend = blend
        frame.image = image
        return frame
    }

    // MARK: - 类方法

    /// 使用图像创建帧
    public static func frame(with image: UIImage) -> LSImageFrame {
        return LSImageFrame(image: image)
    }
}

// MARK: - 颜色空间工具

/// 颜色空间工具类
public enum LSColorSpace {

    private static var deviceRGBSpace: CGColorSpace?
    private static var deviceGraySpace: CGColorSpace?
    private static let lock = NSLock()

    /// 返回共享的 DeviceRGB 颜色空间
    public static var deviceRGB: CGColorSpace {
        lock.lock()
        defer { lock.unlock() }
        if let space = deviceRGBSpace {
            return space
        }
        let space = CGColorSpaceCreateDeviceRGB()
        deviceRGBSpace = space
        return space
    }

    /// 返回共享的 DeviceGray 颜色空间
    public static var deviceGray: CGColorSpace {
        lock.lock()
        defer { lock.unlock() }
        if let space = deviceGraySpace {
            return space
        }
        let space = CGColorSpaceCreateDeviceGray()
        deviceGraySpace = space
        return space
    }

    /// 判断颜色空间是否为 DeviceRGB
    public static func isDeviceRGB(_ space: CGColorSpace?) -> Bool {
        guard let space = space else { return false }
        return space == deviceRGB
    }

    /// 判断颜色空间是否为 DeviceGray
    public static func isDeviceGray(_ space: CGColorSpace?) -> Bool {
        guard let space = space else { return false }
        return space == deviceGray
    }
}

// MARK: - 图片类型检测

/// 图片类型检测工具
public enum LSImageTypeDetector {

    /// PNG 文件头签名
    private static let pngSignature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]

    /// JPEG 文件头
    private static let jpegSignature: UInt16 = 0xFFD8

    /// 通过读取数据的前 16 字节检测图片类型 (非常快)
    public static func detectType(_ data: Data) -> LSImageType {
        guard data.count >= 16 else { return .unknown }

        data.withUnsafeBytes { bytes in
            guard let baseAddress = bytes.baseAddress else { return .unknown }

            // 检查 PNG (89 50 4E 47 0D 0A 1A 0A)
            if data.count >= 8 {
                var isPNG = true
                for i in 0..<8 {
                    if baseAddress.load(fromByteOffset: i, as: UInt8.self) != pngSignature[i] {
                        isPNG = false
                        break
                    }
                }
                if isPNG {
                    // 检查是否为 APNG (查找 acTL chunk)
                    if data.count >= 32 {
                        // 跳过 PNG 签名 (8 bytes)
                        // chunk 格式: length(4) + type(4) + data(length) + crc(4)
                        var offset = 8
                        while offset + 8 <= data.count {
                            let chunkLength = baseAddress.load(fromByteOffset: offset, as: UInt32.self).bigEndian
                            let chunkType = baseAddress.load(fromByteOffset: offset + 4, as: UInt32.self)

                            if chunkType == fourCC("a", "c", "T", "L") {
                                return .png  // APNG 实际上也是 PNG
                            }
                            if chunkType == fourCC("I", "D", "A", "T") {
                                break
                            }
                            if chunkType == fourCC("I", "E", "N", "D") {
                                break
                            }

                            offset += 12 + Int(chunkLength)
                            if offset >= data.count {
                                break
                            }
                        }
                    }
                    return .png
                }
            }

            // 检查 JPEG (FF D8)
            let signature = baseAddress.load(as: UInt16.self).bigEndian
            if signature == jpegSignature {
                return .jpeg
            }

            // 检查 GIF (GIF87a 或 GIF89a)
            if data.count >= 6 {
                let gif1 = baseAddress.load(as: UInt32.self)
                let gif2 = baseAddress.load(fromByteOffset: 4, as: UInt16.self)
                if gif1 == fourCC("G", "I", "F", "8") &&
                   (gif2 == twoCC("7", "a") || gif2 == twoCC("9", "a")) {
                    return .gif
                }
            }

            // 检查 WebP (RIFF....WEBP)
            if data.count >= 12 {
                let riff = baseAddress.load(as: UInt32.self)
                let webp = baseAddress.load(fromByteOffset: 8, as: UInt32.self)
                if riff == fourCC("R", "I", "F", "F") && webp == fourCC("W", "E", "B", "P") {
                    return .webP
                }
            }

            // 检查 BMP (BM)
            if data.count >= 2 {
                let bm = baseAddress.load(as: UInt16.self)
                if bm == twoCC("B", "M") {
                    return .bmp
                }
            }

            // 检查 ICO (从第 0 字节开始是 0)
            if data.count >= 4 {
                let reserved = baseAddress.load(as: UInt16.self)
                let type = baseAddress.load(fromByteOffset: 2, as: UInt16.self)
                if reserved == 0 && type == 1 {
                    return .ico
                }
                if reserved == 0 && type == 2 {
                    return .icns
                }
            }

            return .unknown
        }
    }

    /// 创建 FourCC 码
    internal static func fourCC(_ c1: Character, _ c2: Character, _ c3: Character, _ c4: Character) -> UInt32 {
        let v1 = UInt32(c1.asciiValue ?? 0)
        let v2 = UInt32(c2.asciiValue ?? 0)
        let v3 = UInt32(c3.asciiValue ?? 0)
        let v4 = UInt32(c4.asciiValue ?? 0)
        return (v1 << 24) | (v2 << 16) | (v3 << 8) | v4
    }

    /// 创建 TwoCC 码
    internal static func twoCC(_ c1: Character, _ c2: Character) -> UInt16 {
        let v1 = UInt16(c1.asciiValue ?? 0)
        let v2 = UInt16(c2.asciiValue ?? 0)
        return (v1 << 8) | v2
    }

    /// 将 LSImageType 转换为 UTI (如 kUTTypeJPEG)
    public static func uti(for type: LSImageType) -> CFString {
        switch type {
        case .jpeg:
            return kUTTypeJPEG
        case .jpeg2000:
            return kUTTypeJPEG2000
        case .tiff:
            return kUTTypeTIFF
        case .bmp:
            return kUTTypeBMP
        case .ico:
            return "com.microsoft.ico" as CFString
        case .icns:
            return "com.apple.icns" as CFString
        case .gif:
            return kUTTypeGIF
        case .png:
            return kUTTypePNG
        case .webP:
            return "org.webmproject.webp" as CFString
        default:
            return kUTTypeImage
        }
    }

    /// 将 UTI 转换为 LSImageType
    public static func type(from uti: CFString) -> LSImageType {
        let utiString = uti as String
        if UTTypeConformsTo(uti as CFString, kUTTypeJPEG) {
            return .jpeg
        } else if UTTypeConformsTo(uti as CFString, kUTTypeJPEG2000) {
            return .jpeg2000
        } else if UTTypeConformsTo(uti as CFString, kUTTypeTIFF) {
            return .tiff
        } else if UTTypeConformsTo(uti as CFString, kUTTypeBMP) {
            return .bmp
        } else if UTTypeConformsTo(uti as CFString, kUTTypeGIF) {
            return .gif
        } else if UTTypeConformsTo(uti as CFString, kUTTypePNG) {
            return .png
        } else if utiString == "org.webmproject.webp" {
            return .webP
        } else if utiString == "com.microsoft.ico" {
            return .ico
        } else if utiString == "com.apple.icns" {
            return .icns
        }
        return .unknown
    }

    /// 获取图片类型的文件扩展名 (如 "jpg")
    public static func fileExtension(for type: LSImageType) -> String? {
        switch type {
        case .jpeg:
            return "jpg"
        case .jpeg2000:
            return "jp2"
        case .tiff:
            return "tiff"
        case .bmp:
            return "bmp"
        case .ico:
            return "ico"
        case .icns:
            return "icns"
        case .gif:
            return "gif"
        case .png:
            return "png"
        case .webP:
            return "webp"
        default:
            return nil
        }
    }
}

// MARK: - 图片方向转换

/// 图片方向转换工具
public enum LSImageOrientation {

    /// 将 EXIF 方向值转换为 UIImageOrientation
    public static func fromEXIFValue(_ value: Int) -> UIImage.Orientation {
        switch value {
        case 1: return .up
        case 2: return .upMirrored
        case 3: return .down
        case 4: return .downMirrored
        case 5: return .leftMirrored
        case 6: return .right
        case 7: return .rightMirrored
        case 8: return .left
        default: return .up
        }
    }

    /// 将 UIImageOrientation 转换为 EXIF 方向值
    public static func toEXIFValue(_ orientation: UIImage.Orientation) -> Int {
        switch orientation {
        case .up: return 1
        case .upMirrored: return 2
        case .down: return 3
        case .downMirrored: return 4
        case .leftMirrored: return 5
        case .right: return 6
        case .rightMirrored: return 7
        case .left: return 8
        @unknown default: return 1
        }
    }
}

// MARK: - CGImage 扩展

/// CGImage 解码和编码工具
public enum LSCGImageHelper {

    /// 创建解码后的图像副本
    ///
    /// - Parameters:
    ///   - imageRef: 源图像
    ///   - decodeForDisplay: 是否为显示解码 (转换为 BGRA8888 预乘或 BGRX8888 格式)
    /// - Returns: 解码后的图像，如果出错返回 nil
    public static func createDecodedCopy(_ imageRef: CGImage?, decodeForDisplay: Bool) -> CGImage? {
        guard let imageRef = imageRef else { return nil }

        // 检查是否已经是解码格式
        let alphaInfo = imageRef.alphaInfo
        let bitmapInfo = imageRef.bitmapInfo

        // 如果已经是 ARGB8888/RGB888 且字节序正确，直接返回
        if !decodeForDisplay {
            if alphaInfo == .none || alphaInfo == .noneSkipFirst ||
               alphaInfo == .noneSkipLast || alphaInfo == .premultipliedFirst ||
               alphaInfo == .premultipliedLast {
                return imageRef
            }
        }

        let width = imageRef.width
        let height = imageRef.height
        let colorSpace = imageRef.colorSpace

        // 目标位图信息
        var destBitmapInfo: CGBitmapInfo = []
        var destAlphaInfo: CGImageAlphaInfo = .premultipliedFirst

        if decodeForDisplay {
            // 为显示优化: BGRA8888 (预乘) 或 BGRX8888
            if colorSpace == nil || LSColorSpace.isDeviceRGB(colorSpace) {
                destBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
                destAlphaInfo = .premultipliedFirst
            } else {
                destAlphaInfo = .premultipliedLast
                destBitmapInfo = CGBitmapInfo(rawValue: destAlphaInfo.rawValue)
            }
        } else {
            // 保持原始格式
            destBitmapInfo = bitmapInfo
            destAlphaInfo = alphaInfo
        }

        // 创建目标颜色空间
        let destColorSpace: CGColorSpace
        if let cs = colorSpace, (LSColorSpace.isDeviceRGB(cs) || LSColorSpace.isDeviceGray(cs)) {
            destColorSpace = cs
        } else {
            destColorSpace = LSColorSpace.deviceRGB
        }

        // 创建位图上下文
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: destColorSpace,
            bitmapInfo: destBitmapInfo.rawValue
        ) else {
            return imageRef
        }

        // 绘制图像
        context.draw(imageRef, in: CGRect(x: 0, y: 0, width: width, height: height))

        // 创建新图像
        return context.makeImage()
    }

    /// 创建带有方向的图像副本
    ///
    /// - Parameters:
    ///   - imageRef: 源图像
    ///   - orientation: 图像方向
    ///   - destBitmapInfo: 目标位图信息 (仅支持 32 位格式如 ARGB8888)
    /// - Returns: 新图像，如果出错返回 nil
    public static func createCopyWithOrientation(
        _ imageRef: CGImage?,
        orientation: UIImage.Orientation,
        destBitmapInfo: CGBitmapInfo
    ) -> CGImage? {
        guard let imageRef = imageRef else { return nil }

        let width = imageRef.width
        let height = imageRef.height
        let colorSpace = imageRef.colorSpace ?? LSColorSpace.deviceRGB

        // 根据方向计算目标尺寸
        var destWidth = width
        var destHeight = height
        var transform = CGAffineTransform.identity

        switch orientation {
        case .up, .upMirrored:
            break
        case .down, .downMirrored:
            transform = CGAffineTransform(translationX: CGFloat(width), y: CGFloat(height))
            transform = transform.rotated(by: .pi)
        case .left, .leftMirrored:
            destWidth = height
            destHeight = width
            transform = CGAffineTransform(translationX: CGFloat(height), y: 0)
            transform = transform.rotated(by: .pi / 2)
        case .right, .rightMirrored:
            destWidth = height
            destHeight = width
            transform = CGAffineTransform(translationX: 0, y: CGFloat(width))
            transform = transform.rotated(by: -.pi / 2)
        @unknown default:
            break
        }

        // 处理镜像
        switch orientation {
        case .upMirrored, .downMirrored:
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.scaledBy(x: 1, y: -1)
        default:
            break
        }

        // 创建位图上下文
        guard let context = CGContext(
            data: nil,
            width: destWidth,
            height: destHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: destBitmapInfo.rawValue
        ) else {
            return nil
        }

        // 应用变换并绘制
        context.concatenate(transform)
        context.draw(imageRef, in: CGRect(x: 0, y: 0, width: width, height: height))

        return context.makeImage()
    }

    /// 创建应用仿射变换的图像副本
    ///
    /// - Parameters:
    ///   - imageRef: 源图像
    ///   - transform: 应用于图像的变换 (左下角坐标系)
    ///   - destSize: 目标图像尺寸
    ///   - destBitmapInfo: 目标位图信息 (仅支持 32 位格式如 ARGB8888)
    /// - Returns: 新图像，如果出错返回 nil
    public static func createAffineTransformCopy(
        _ imageRef: CGImage?,
        transform: CGAffineTransform,
        destSize: CGSize,
        destBitmapInfo: CGBitmapInfo
    ) -> CGImage? {
        guard let imageRef = imageRef else { return nil }

        let width = Int(ceil(destSize.width))
        let height = Int(ceil(destSize.height))
        let colorSpace = imageRef.colorSpace ?? LSColorSpace.deviceRGB

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: destBitmapInfo.rawValue
        ) else {
            return nil
        }

        context.concatenate(transform)
        context.draw(imageRef, in: CGRect(x: 0, y: 0, width: imageRef.width, height: imageRef.height))

        return context.makeImage()
    }

    /// 使用 CGImageDestination 将图像编码为数据
    ///
    /// - Parameters:
    ///   - imageRef: 图像
    ///   - type: 图像类型
    ///   - quality: 质量 (0.0~1.0)
    /// - Returns: 图像数据，如果出错返回 nil
    public static func createEncodedData(
        _ imageRef: CGImage?,
        type: LSImageType,
        quality: CGFloat
    ) -> Data? {
        guard let imageRef = imageRef else { return nil }

        let uti = LSImageTypeDetector.uti(for: type)
        guard let destination = CGImageDestinationCreateWithData(
            NSMutableData() as CFMutableData,
            uti,
            1,
            nil
        ) else {
            return nil
        }

        let options: [NSString: Any] = [
            kCGImageDestinationLossyCompressionQuality as NSString: quality
        ]

        CGImageDestinationAddImage(destination, imageRef, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }

        return (destination.data as? Data) ?? nil
    }
}

// MARK: - WebP 可用性检查

/// WebP 支持检查
public enum LSWebPHelper {

    /// 是否支持 WebP
    public static var isWebPAvailable: Bool {
        if #available(iOS 14.0, *) {
            return true
        }
        return false
    }

    /// 获取 WebP 图片帧数
    ///
    /// - Parameter webpData: WebP 数据
    /// - Returns: 图片帧数，如果出错返回 0
    public static func getWebPFrameCount(_ webpData: Data) -> UInt {
        #if canImport(WebP)
        if #available(iOS 14.0, *) {
            import WebP
            // iOS 14+ 使用原生 WebP 框架
            // 这里需要使用 WebP Demux API
            // 由于原生 API 可能不同，这里暂时返回基本检测
            return 1
        }
        #endif
        return 0
    }

    /// 从 WebP 数据解码图像
    ///
    /// - Parameters:
    ///   - webpData: WebP 数据
    ///   - decodeForDisplay: 是否为显示解码
    /// - Returns: 解码后的图像，如果出错返回 nil
    @available(iOS 14.0, *)
    public static func createImageWithWebPData(
        _ webpData: Data,
        decodeForDisplay: Bool
    ) -> CGImage? {
        #if canImport(WebP)
        import WebP
        // iOS 14+ 原生 WebP 解码
        // 需要使用 ImageIO 框架
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: decodeForDisplay
        ]

        guard let source = CGImageSourceCreateWithData(webpData as CFData, options as CFDictionary) else {
            return nil
        }

        return CGImageSourceCreateImageAtIndex(source, 0, options as CFDictionary)
        #else
        return nil
        #endif
    }

    /// 将 CGImage 编码为 WebP 数据
    ///
    /// - Parameters:
    ///   - imageRef: 图像
    ///   - lossless: 是否无损
    ///   - quality: 质量 (0.0~1.0)
    /// - Returns: WebP 数据，如果出错返回 nil
    @available(iOS 14.0, *)
    public static func createEncodedWebPData(
        _ imageRef: CGImage?,
        lossless: Bool,
        quality: CGFloat
    ) -> Data? {
        guard let imageRef = imageRef else { return nil }

        // 使用 ImageIO 框架编码 WebP
        guard let destination = CGImageDestinationCreateWithData(
            NSMutableData() as CFMutableData,
            "org.webmproject.webp" as CFString,
            1,
            nil
        ) else {
            return nil
        }

        let options: [NSString: Any] = [
            kCGImageDestinationLossyCompressionQuality as NSString: quality,
            kCGImagePropertyWebPHasAlpha as NSString: (imageRef.alphaInfo != .none)
        ]

        CGImageDestinationAddImage(destination, imageRef, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }

        return (destination.data as? Data) ?? nil
    }
}

// MARK: - 图片解码器

/// 图像解码器 - 用于解码图像数据
///
/// 此类支持解码动画 WebP、APNG、GIF 和系统图像格式（PNG、JPG、JP2、BMP、TIFF、PIC、ICNS 和 ICO）。
/// 可用于解码完整图像数据，或在图像下载期间解码增量图像数据。
/// 此类是线程安全的。
public class LSImageDecoder {

    // MARK: - 属性

    /// 图像数据
    public private(set) var data: Data?

    /// 图像类型
    public private(set) var type: LSImageType = .unknown

    /// 图像 scale
    public private(set) var scale: CGFloat = 1

    /// 图像帧数
    public private(set) var frameCount: UInt = 1

    /// 循环次数，0 表示无限循环
    public private(set) var loopCount: UInt = 0

    /// 画布宽度
    public private(set) var width: UInt = 0

    /// 画布高度
    public private(set) var height: UInt = 0

    /// 是否已完成 (数据不再更新)
    public private(set) var isFinalized: Bool = false

    // MARK: - 内部属性

    private var imageSource: CGImageSource?
    private var frameProperties: [CFDictionary]?
    private let lock = NSLock()

    // MARK: - 初始化

    /// 创建图像解码器
    ///
    /// - Parameter scale: 图像 scale
    public init(scale: CGFloat = 1) {
        self.scale = scale
    }

    /// 使用数据创建解码器
    ///
    /// - Parameters:
    ///   - data: 图像数据
    ///   - scale: 图像 scale
    /// - Returns: 新的解码器实例，如果出错返回 nil
    public convenience init?(data: Data, scale: CGFloat = 1) {
        self.init(scale: scale)
        guard updateData(data, final: true) else {
            return nil
        }
    }

    // MARK: - 更新数据

    /// 使用新数据更新增量图像
    ///
    /// - Parameters:
    ///   - data: 要添加到图像解码器的数据。每次调用此函数时，data 参数必须包含迄今为止累积的所有图像文件数据。
    ///   - final: 指定数据是否为最终数据集。如果是则传 YES，否则传 NO。当数据已经完成时，无法再更新数据。
    /// - Returns: 是否成功
    public func updateData(_ data: Data?, final: Bool) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        // 如果已经完成，不允许再更新
        if isFinalized {
            return false
        }

        self.data = data
        self.isFinalized = final

        guard let imageData = data, !imageData.isEmpty else {
            return false
        }

        // 检测图像类型
        type = LSImageTypeDetector.detectType(imageData)

        // 创建图像源
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false  // 不立即缓存到内存
        ]

        guard let source = CGImageSourceCreateWithData(imageData as CFData, options as CFDictionary) else {
            return false
        }

        self.imageSource = source

        // 获取图像属性
        if let properties = CGImageSourceCopyProperties(source, nil) as? [CFString: Any] {
            // 获取尺寸
            if let pixelWidth = properties[kCGImagePropertyPixelWidth] as? UInt,
               let pixelHeight = properties[kCGImagePropertyPixelHeight] as? UInt {
                width = pixelWidth
                height = pixelHeight
            }

            // 获取帧数
            frameCount = UInt(CGImageSourceGetCount(source))

            // 获取循环次数 (GIF)
            if let gifProperties = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any],
               let loopCount = gifProperties[kCGImagePropertyGIFLoopCount] as? UInt {
                self.loopCount = loopCount
            }

            // 缓存帧属性
            var frames: [CFDictionary] = []
            for i in 0..<frameCount {
                if let frameProps = CGImageSourceCopyPropertiesAtIndex(source, i, nil) {
                    frames.append(frameProps)
                }
            }
            frameProperties = frames
        }

        return true
    }

    // MARK: - 获取帧

    /// 解码并返回指定索引的帧
    ///
    /// - Parameters:
    ///   - index: 帧索引 (从 0 开始)
    ///   - decodeForDisplay: 是否将图像解码为显示位图。如果 NO，将尝试返回不进行混合的原始帧数据。
    /// - Returns: 包含图像的新帧，如果出错返回 nil
    public func frame(at index: UInt, decodeForDisplay: Bool) -> LSImageFrame? {
        lock.lock()
        defer { lock.unlock() }

        guard index < frameCount else { return nil }
        guard let source = imageSource else { return nil }

        let frame = LSImageFrame()
        frame.index = index

        // 获取 CGImage
        guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else {
            return nil
        }

        // 是否需要解码
        let finalCGImage: CGImage?
        if decodeForDisplay {
            finalCGImage = LSCGImageHelper.createDecodedCopy(cgImage, decodeForDisplay: true)
        } else {
            finalCGImage = cgImage
        }

        guard let decodedCGImage = finalCGImage else {
            return nil
        }

        frame.image = UIImage(cgImage: decodedCGImage, scale: scale, orientation: .up)
        frame.width = UInt(decodedCGImage.width)
        frame.height = UInt(decodedCGImage.height)

        // 获取帧属性
        if let props = frameProperties, Int(index) < props.count {
            let frameProps = props[Int(index)] as [CFString: Any]

            // 获取 GIF 帧持续时间
            if let gifDict = frameProps[kCGImagePropertyGIFDictionary] as? [CFString: Any] {
                let delayTime = gifDict[kCGImagePropertyGIFDelayTime] as? TimeInterval ?? 0
                let unclampedDelayTime = gifDict[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval
                frame.duration = unclampedDelayTime ?? delayTime

                // 获取 GIF 处理方法
                if let disposeMethod = gifDict[kCGImagePropertyGIFUnclampedDelayTime] as? UInt {
                    frame.dispose = LSImageDisposeMethod(rawValue: disposeMethod) ?? .none
                }
            }

            // 获取 PNG/APNG 帧属性
            if let pngDict = frameProps[kCGImagePropertyPNGDictionary] as? [CFString: Any] {
                // APNG 延迟时间
                if let delayTime = pngDict[kCGImagePropertyAPNGDelayTime] as? TimeInterval {
                    frame.duration = delayTime
                }

                // APNG 处理方法 (dispose_op)
                // ImageIO 返回值: 0=none, 1=background, 2=previous
                if let disposeInt = pngDict[kCGImagePropertyAPNGDisposeOp] as? Int {
                    frame.dispose = LSImageDisposeMethod(rawValue: UInt(disposeInt)) ?? .none
                }

                // APNG 混合操作 (blend_op)
                // ImageIO 返回值: 0=source, 1=over
                if let blendInt = pngDict[kCGImagePropertyAPNGBlendOp] as? Int {
                    frame.blend = LSImageBlendOperation(rawValue: UInt(blendInt)) ?? .none
                }
            }
        }

        // 确保持续时间不为 0
        if frame.duration == 0 {
            frame.duration = 0.1  // 默认 100ms
        }

        return frame
    }

    /// 返回指定索引的帧持续时间
    ///
    /// - Parameter index: 帧索引 (从 0 开始)
    /// - Returns: 持续时间 (秒)
    public func frameDuration(at index: UInt) -> TimeInterval {
        guard index < frameCount else { return 0 }
        guard let props = frameProperties, Int(index) < props.count else { return 0.1 }

        let frameProps = props[Int(index)] as [CFString: Any]

        // 尝试从 GIF 获取
        if let gifDict = frameProps[kCGImagePropertyGIFDictionary] as? [CFString: Any] {
            let delayTime = gifDict[kCGImagePropertyGIFDelayTime] as? TimeInterval ?? 0
            let unclampedDelayTime = gifDict[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval
            if let duration = unclampedDelayTime ?? (delayTime > 0 ? delayTime : nil) {
                return duration
            }
        }

        // 尝试从 PNG/APNG 获取
        if let pngDict = frameProps[kCGImagePropertyPNGDictionary] as? [CFString: Any] {
            if let delayTime = pngDict[kCGImagePropertyAPNGDelayTime] as? TimeInterval, delayTime > 0 {
                return delayTime
            }
        }

        return 0.1  // 默认 100ms
    }

    /// 返回指定索引的帧属性
    ///
    /// 参考 ImageIO 框架中的 "CGImageProperties.h" 获取更多信息
    ///
    /// - Parameter index: 帧索引 (从 0 开始)
    /// - Returns: ImageIO 帧属性
    public func frameProperties(at index: UInt) -> [CFString: Any]? {
        guard index < frameCount else { return nil }
        guard let props = frameProperties, Int(index) < props.count else { return nil }
        return props[Int(index)] as? [CFString: Any]
    }

    /// 返回图像属性
    ///
    /// 参考 ImageIO 框架中的 "CGImageProperties.h" 获取更多信息
    public var imageProperties: [CFString: Any]? {
        guard let source = imageSource else { return nil }
        return CGImageSourceCopyProperties(source, nil) as? [CFString: Any]
    }

    // MARK: - 便捷属性访问方法

    /// 获取图像宽度
    public var pixelWidth: UInt {
        return width
    }

    /// 获取图像高度
    public var pixelHeight: UInt {
        return height
    }

    /// 获取 DPI 信息
    ///
    /// - Returns: (dpiWidth, dpiHeight) 元组，如果无法获取返回 nil
    public var dpi: (width: UInt, height: UInt)? {
        guard let props = imageProperties,
              let width = props[kCGImagePropertyDPIWidth] as? UInt,
              let height = props[kCGImagePropertyDPIHeight] as? UInt else {
            return nil
        }
        return (width, height)
    }

    /// 获取 EXIF 数据
    ///
    /// - Returns: EXIF 字典数据
    public var exifProperties: [CFString: Any]? {
        guard let props = imageProperties,
              let exif = props[kCGImagePropertyExifDictionary] as? [CFString: Any] else {
            return nil
        }
        return exif
    }

    /// 获取 GPS 数据
    ///
    /// - Returns: GPS 字典数据
    public var gpsProperties: [CFString: Any]? {
        guard let props = imageProperties,
              let gps = props[kCGImagePropertyGPSDictionary] as? [CFString: Any] else {
            return nil
        }
        return gps
    }

    /// 获取 TIFF 数据
    ///
    /// - Returns: TIFF 字典数据
    public var tiffProperties: [CFString: Any]? {
        guard let props = imageProperties,
              let tiff = props[kCGImagePropertyTIFFDictionary] as? [CFString: Any] else {
            return nil
        }
        return tiff
    }

    /// 获取颜色空间信息
    ///
    /// - Returns: 颜色模型字符串 (如 RGB, Gray, CMYK 等)
    public var colorModel: String? {
        return imageProperties?[kCGImagePropertyColorModel] as? String
    }

    /// 获取位深度
    ///
    /// - Returns: 位深度 (如 8, 16, 32 等)
    public var depth: UInt? {
        return imageProperties?[kCGImagePropertyDepth] as? UInt
    }

    /// 获取是否有 alpha 通道
    public var hasAlpha: Bool {
        return imageProperties?[kCGImagePropertyHasAlpha] as? Bool ?? false
    }

    /// 获取方向信息
    ///
    /// - Returns: 图像方向 (1-8)
    public var orientation: UInt? {
        return imageProperties?[kCGImagePropertyOrientation] as? UInt
    }

    /// 获取是否为浮点像素
    public var isFloat: Bool? {
        return imageProperties?[kCGImagePropertyIsFloat] as? Bool
    }

    /// 获取索引图像的调色板
    ///
    /// - Returns: 调色板数据
    public var paletteProperties: [CFString: Any]? {
        guard let props = imageProperties,
              let palette = props[kCGImagePropertyPalette] as? [CFString: Any] else {
            return nil
        }
        return palette
    }

    /// 获取指定索引帧的 EXIF 数据
    ///
    /// - Parameter index: 帧索引
    /// - Returns: EXIF 字典数据
    public func exifProperties(at index: UInt) -> [CFString: Any]? {
        guard let props = frameProperties(at: index),
              let exif = props[kCGImagePropertyExifDictionary] as? [CFString: Any] else {
            return nil
        }
        return exif
    }
}

// MARK: - 图片编码器

/// 图像编码器 - 用于将图像编码为数据
///
/// 支持编码 LSImageType 中定义的单帧图像类型。
/// 还支持使用 GIF、APNG 和 WebP 编码多帧图像。
///
/// 编码多帧图像时，只是简单地将图像打包在一起。
/// 如果要减少图像文件大小，请尝试使用 imagemagick/ffmpeg 处理 GIF 和 WebP，
/// 使用 apngasm 处理 APNG。
public class LSImageEncoder {

    // MARK: - 属性

    /// 图像类型
    public private(set) var type: LSImageType = .png

    /// 循环次数，0 表示无限循环 (仅适用于 GIF/APNG/WebP)
    public var loopCount: UInt = 0

    /// 是否无损 (仅适用于 WebP)
    public var lossless: Bool = false

    /// 压缩质量，0.0~1.0 (仅适用于 JPG/JP2/WebP)
    public var quality: CGFloat = 0.9

    // MARK: - 内部属性

    private var images: [UIImage] = []
    private var durations: [TimeInterval] = []
    private let lock = NSLock()

    // MARK: - 初始化

    /// 禁用默认初始化
    private init() {}

    /// 使用指定类型创建图像编码器
    ///
    /// - Parameter type: 图像类型
    /// - Returns: 新的编码器实例，如果出错返回 nil
    public init?(type: LSImageType) {
        self.type = type

        // 验证类型是否支持
        switch type {
        case .jpeg, .jpeg2000, .tiff, .bmp, .gif, .png, .webP:
            break
        default:
            return nil
        }

        // 检查 WebP 支持
        if type == .webP && !LSWebPHelper.isWebPAvailable {
            return nil
        }
    }

    // MARK: - 添加图像

    /// 添加图像到编码器
    ///
    /// - Parameters:
    ///   - image: 图像
    ///   - duration: 动画的图像持续时间。传 0 忽略此参数。
    public func addImage(_ image: UIImage, duration: TimeInterval = 0) {
        lock.lock()
        defer { lock.unlock() }
        images.append(image)
        durations.append(duration)
    }

    /// 使用图像数据添加图像到编码器
    ///
    /// - Parameters:
    ///   - data: 图像数据
    ///   - duration: 动画的图像持续时间。传 0 忽略此参数。
    public func addImage(with data: Data, duration: TimeInterval = 0) {
        guard let image = UIImage(data: data, scale: 1) else { return }
        addImage(image, duration: duration)
    }

    /// 从文件路径添加图像到编码器
    ///
    /// - Parameters:
    ///   - path: 图像文件路径
    ///   - duration: 动画的图像持续时间。传 0 忽略此参数。
    public func addImage(withFile path: String, duration: TimeInterval = 0) {
        guard let image = UIImage(contentsOfFile: path) else { return }
        addImage(image, duration: duration)
    }

    // MARK: - 编码

    /// 编码图像并返回图像数据
    ///
    /// - Returns: 图像数据，如果出错返回 nil
    public func encode() -> Data? {
        lock.lock()
        defer { lock.unlock() }

        guard !images.isEmpty else { return nil }

        // 单帧图像
        if images.count == 1 {
            return encodeSingleImage(images[0], type: type, quality: quality)
        }

        // 多帧图像 - 只支持 GIF、APNG、WebP
        switch type {
        case .gif:
            return encodeAnimatedGIF()
        case .png:
            return encodeAnimatedPNG()
        case .webP:
            return encodeAnimatedWebP()
        default:
            // 不支持其他格式的多帧编码
            return encodeSingleImage(images[0], type: type, quality: quality)
        }
    }

    /// 将图像编码到文件
    ///
    /// - Parameter path: 文件路径 (如果存在则覆盖)
    /// - Returns: 是否成功
    public func encode(toFile path: String) -> Bool {
        guard let data = encode() else { return false }
        do {
            try data.write(to: URL(fileURLWithPath: path))
            return true
        } catch {
            return false
        }
    }

    // MARK: - 便利方法

    /// 编码单帧图像的便利方法
    ///
    /// - Parameters:
    ///   - image: 图像
    ///   - type: 目标图像类型
    ///   - quality: 图像质量，0.0~1.0
    /// - Returns: 图像数据，如果出错返回 nil
    public static func encode(_ image: UIImage, type: LSImageType, quality: CGFloat) -> Data? {
        return encodeSingleImage(image, type: type, quality: quality)
    }

    /// 使用解码器编码图像的便利方法
    ///
    /// - Parameters:
    ///   - decoder: 图像解码器
    ///   - type: 目标图像类型
    ///   - quality: 图像质量，0.0~1.0
    /// - Returns: 图像数据，如果出错返回 nil
    public static func encode(_ decoder: LSImageDecoder, type: LSImageType, quality: CGFloat) -> Data? {
        // 单帧
        if decoder.frameCount == 1,
           let frame = decoder.frame(at: 0, decodeForDisplay: false),
           let image = frame.image {
            return encodeSingleImage(image, type: type, quality: quality)
        }

        // 多帧
        guard let encoder = LSImageEncoder(type: type) else { return nil }
        encoder.quality = quality

        for i in 0..<decoder.frameCount {
            if let frame = decoder.frame(at: i, decodeForDisplay: false),
               let image = frame.image {
                let duration = decoder.frameDuration(at: i)
                encoder.addImage(image, duration: duration)
            }
        }

        return encoder.encode()
    }

    // MARK: - 私有方法

    private func encodeSingleImage(_ image: UIImage, type: LSImageType, quality: CGFloat) -> Data? {
        guard let cgImage = image.cgImage else { return nil }

        let uti = LSImageTypeDetector.uti(for: type)
        guard let destination = CGImageDestinationCreateWithData(
            NSMutableData() as CFMutableData,
            uti,
            1,
            nil
        ) else {
            return nil
        }

        let options: [NSString: Any] = [
            kCGImageDestinationLossyCompressionQuality as NSString: quality
        ]

        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }

        return (destination.data as? Data) ?? nil
    }

    private func encodeAnimatedGIF() -> Data? {
        let uti = LSImageTypeDetector.uti(for: .gif)
        guard let destination = CGImageDestinationCreateWithData(
            NSMutableData() as CFMutableData,
            uti,
            images.count,
            nil
        ) else {
            return nil
        }

        // 设置 GIF 循环次数
        let gifProperties: [NSString: Any] = [
            kCGImagePropertyGIFLoopCount as NSString: Int(loopCount)
        ]
        let frameProperties: [NSString: Any] = [
            kCGImagePropertyGIFDictionary as NSString: gifProperties
        ]

        for (index, image) in images.enumerated() {
            guard let cgImage = image.cgImage else { continue }

            var delay = durations[index]
            if delay == 0 { delay = 0.1 }

            // 转换为 GIF 延迟时间 (以厘秒为单位，1/100 秒)
            let delayTime = Int(delay * 100)

            let gifDict: [NSString: Any] = [
                kCGImagePropertyGIFDelayTime as NSString: delay
            ]

            let properties: [NSString: Any] = [
                kCGImagePropertyGIFDictionary as NSString: gifDict
            ]

            CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
        }

        guard CGImageDestinationFinalize(destination) else {
            return nil
        }

        return (destination.data as? Data) ?? nil
    }

    private func encodeAnimatedPNG() -> Data? {
        // 注意：ImageIO 不直接支持 APNG 编码
        // 这里回退到普通 PNG
        if images.isEmpty { return nil }
        return encodeSingleImage(images[0], type: .png, quality: 1.0)
    }

    private func encodeAnimatedWebP() -> Data? {
        // 注意：iOS 14+ 的 ImageIO 可能支持 WebP 动画编码
        // 这里需要检查并实现
        if #available(iOS 14.0, *) {
            if images.isEmpty { return nil }

            let uti = LSImageTypeDetector.uti(for: .webP)
            guard let destination = CGImageDestinationCreateWithData(
                NSMutableData() as CFMutableData,
                uti,
                images.count,
                nil
            ) else {
                return nil
            }

            for (index, image) in images.enumerated() {
                guard let cgImage = image.cgImage else { continue }

                let properties: [NSString: Any] = [
                    kCGImagePropertyWebPHasAlpha as NSString: (cgImage.alphaInfo != .none)
                ]

                CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
            }

            guard CGImageDestinationFinalize(destination) else {
                return nil
            }

            return (destination.data as? Data) ?? nil
        }

        return nil
    }
}

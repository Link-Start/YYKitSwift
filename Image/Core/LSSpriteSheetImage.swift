//
//  LSSpriteSheetImage.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  精灵图图片 - 从单张大图切割多个帧
//

#if canImport(UIKit)
import UIKit
import Foundation

/// 精灵图图片 - 从单张大图切割多个帧
///
/// 此类从单张大图中根据 contentRects 切割多个帧。
/// 可以在 LSAnimatedImageView 中播放精灵图动画。
public class LSSpriteSheetImage: UIImage, LSAnimatedImage {

    // MARK: - 属性

    private var _contentRects: [CGRect] = []
    private var _frameDurations: [TimeInterval] = []
    private var _frameCount: UInt = 0
    private var _loopCount: UInt = 0
    private var _canvasSize: CGSize = .zero
    private var _bytesPerFrame: UInt = 0

    /// 内容矩形数组 (归一化坐标，0-1)
    public var contentRects: [CGRect] {
        return _contentRects
    }

    /// 帧持续时间数组
    public var frameDurations: [TimeInterval] {
        return _frameDurations
    }

    // MARK: - 初始化

    /// 使用精灵图图像和内容矩形创建精灵图图像
    ///
    /// - Parameters:
    ///   - spriteSheet: 精灵图大图
    ///   - contentRects: 内容矩形数组（像素坐标）
    ///   - frameDurations: 每帧的持续时间数组
    ///   - loopCount: 循环次数，0 表示无限循环
    public init?(
        spriteSheet: UIImage,
        contentRects: [CGRect],
        frameDurations: [TimeInterval],
        loopCount: UInt = 0
    ) {
        guard !contentRects.isEmpty else { return nil }
        guard contentRects.count == frameDurations.count else { return nil }

        guard let cgImage = spriteSheet.cgImage else { return nil }

        _canvasSize = CGSize(width: cgImage.width, height: cgImage.height)
        _contentRects = contentRects
        _frameDurations = frameDurations
        _frameCount = UInt(contentRects.count)
        _loopCount = loopCount

        // 计算每帧字节数（基于第一帧）
        let firstRect = contentRects[0]
        let frameWidth = Int(firstRect.width)
        let frameHeight = Int(firstRect.height)
        _bytesPerFrame = UInt(frameWidth * frameHeight * 4)  // RGBA8888

        super.init(cgImage: cgImage, scale: spriteSheet.scale, orientation: spriteSheet.imageOrientation)
    }

    /// 从文件路径加载精灵图图像
    ///
    /// 文件格式示例 (JSON):
    /// ```json
    /// {
    ///   "spriteSheet": "sprite.png",
    ///   "contentRects": [
    ///     {"x": 0, "y": 0, "width": 100, "height": 100},
    ///     {"x": 100, "y": 0, "width": 100, "height": 100}
    ///   ],
    ///   "frameDurations": [0.1, 0.1],
    ///   "loopCount": 0
    /// }
    /// ```
    ///
    /// - Parameter path: 配置文件路径
    /// - Returns: LSSpriteSheetImage 实例，如果出错返回 nil
    public convenience init?(contentsOfFile path: String) {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return nil
        }

        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return nil
        }

        guard let spriteSheetPath = json["spriteSheet"] as? String else {
            return nil
        }

        let basePath = (path as NSString).deletingLastPathComponent
        let fullPath = basePath.isEmpty ? spriteSheetPath : "\(basePath)/\(spriteSheetPath)"

        guard let spriteSheet = UIImage(contentsOfFile: fullPath) else {
            return nil
        }

        guard let rectsArray = json["contentRects"] as? [[String: Any]] else {
            return nil
        }

        guard let durationsArray = json["frameDurations"] as? [TimeInterval] else {
            return nil
        }

        let loopCount: UInt
        if let lc = json["loopCount"] as? UInt {
            loopCount = lc
        } else {
            loopCount = 0
        }

        var contentRects: [CGRect] = []
        for rectInfo in rectsArray {
            guard let x = rectInfo["x"] as? CGFloat,
                  let y = rectInfo["y"] as? CGFloat,
                  let width = rectInfo["width"] as? CGFloat,
                  let height = rectInfo["height"] as? CGFloat else {
                continue
            }
            contentRects.append(CGRect(x: x, y: y, width: width, height: height))
        }

        guard contentRects.count == durationsArray.count else {
            return nil
        }

        self.init(
            spriteSheet: spriteSheet,
            contentRects: contentRects,
            frameDurations: durationsArray,
            loopCount: loopCount
        )
    }

    /// 使用帧网格配置创建精灵图图像
    ///
    /// - Parameters:
    ///   - spriteSheet: 精灵图大图
    ///   - rows: 行数
    ///   - columns: 列数
    ///   - frameDuration: 每帧持续时间
    ///   - loopCount: 循环次数
    /// - Returns: LSSpriteSheetImage 实例，如果出错返回 nil
    public convenience init?(
        spriteSheet: UIImage,
        rows: UInt,
        columns: UInt,
        frameDuration: TimeInterval,
        loopCount: UInt = 0
    ) {
        guard let cgImage = spriteSheet.cgImage else { return nil }

        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)

        let frameWidth = imageWidth / CGFloat(columns)
        let frameHeight = imageHeight / CGFloat(rows)

        var contentRects: [CGRect] = []
        var frameDurations: [TimeInterval] = []

        for row in 0..<rows {
            for col in 0..<columns {
                let x = CGFloat(col) * frameWidth
                let y = CGFloat(row) * frameHeight
                contentRects.append(CGRect(x: x, y: y, width: frameWidth, height: frameHeight))
                frameDurations.append(frameDuration)
            }
        }

        self.init(
            spriteSheet: spriteSheet,
            contentRects: contentRects,
            frameDurations: frameDurations,
            loopCount: loopCount
        )
    }

    required init?(coder: NSCoder) {
        guard let spriteSheetData = coder.decodeObject(forKey: "spriteSheetData") as? Data else {
            return nil
        }

        guard let spriteSheet = UIImage(data: spriteSheetData) else {
            return nil
        }

        guard let rectsData = coder.decodeObject(forKey: "contentRectsData") as? [String] else {
            return nil
        }

        guard let durationsData = coder.decodeObject(forKey: "frameDurationsData") as? [TimeInterval] else {
            return nil
        }

        let loopCount = UInt(coder.decodeInteger(forKey: "loopCount"))

        var contentRects: [CGRect] = []
        for rectString in rectsData {
            if let rect = NSCoder.cgRect(for: rectString) {
                contentRects.append(rect)
            }
        }

        self.init(
            spriteSheet: spriteSheet,
            contentRects: contentRects,
            frameDurations: durationsData,
            loopCount: loopCount
        )
    }

    // MARK: - LSAnimatedImage 协议

    public func animatedImageFrameCount() -> UInt {
        return _frameCount
    }

    public func animatedImageLoopCount() -> UInt {
        return _loopCount
    }

    public func animatedImageBytesPerFrame() -> UInt {
        return _bytesPerFrame
    }

    public func animatedImageFrame(at index: UInt) -> UIImage? {
        // 精灵图不创建单独的帧图像
        // 而是通过 animatedImageContentsRect 来显示
        return self
    }

    public func animatedImageDuration(at index: UInt) -> TimeInterval {
        guard index < _frameCount else { return 0 }
        return _frameDurations[Int(index)]
    }

    public func animatedImageContentsRect(at index: UInt) -> CGRect {
        guard index < _frameCount else { return CGRect(x: 0, y: 0, width: 1, height: 1) }

        let rect = _contentRects[Int(index)]

        // 转换为归一化坐标 (0-1)
        return CGRect(
            x: rect.origin.x / _canvasSize.width,
            y: rect.origin.y / _canvasSize.height,
            width: rect.size.width / _canvasSize.width,
            height: rect.size.height / _canvasSize.height
        )
    }

    // MARK: - NSCoding

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)

        let spriteSheetData = pngData()
        coder.encode(spriteSheetData, forKey: "spriteSheetData")

        let rectsData = _contentRects.map { NSCoder.string(for: $0) }
        coder.encode(rectsData, forKey: "contentRectsData")

        coder.encode(_frameDurations, forKey: "frameDurationsData")
        coder.encode(Int(_loopCount), forKey: "loopCount")
    }
}
#endif

//
//  LSFrameImage.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  帧动画图片 - 从多张 UIImage 创建动画图片
//

#if canImport(UIKit)
import UIKit
import Foundation

/// 帧动画图片 - 从多张 UIImage 创建动画图片
///
/// 此类可以用于从一系列 UIImage 创建动画图像。
/// 可以在 LSAnimatedImageView 中播放。
public class LSFrameImage: UIImage, LSAnimatedImage {

    // MARK: - 属性

    private var _frames: [UIImage] = []
    private var _durations: [TimeInterval] = []
    private var _frameCount: UInt = 0
    private var _loopCount: UInt = 0
    private var _bytesPerFrame: UInt = 0

    /// 图像尺寸（所有帧应该具有相同的尺寸）
    public private(set) var frameSize: CGSize = .zero

    // MARK: - 初始化

    /// 使用帧图像和持续时间创建帧动画图像
    ///
    /// - Parameters:
    ///   - frames: 帧图像数组
    ///   - durations: 每帧的持续时间数组
    public init?(frames: [UIImage], durations: [TimeInterval]) {
        guard !frames.isEmpty else { return nil }
        guard frames.count == durations.count else { return nil }

        // 获取第一帧的尺寸
        guard let firstFrame = frames.first,
              let cgImage = firstFrame.cgImage else { return nil }

        self.frameSize = CGSize(width: cgImage.width, height: cgImage.height)
        self._frames = frames
        self._durations = durations
        self._frameCount = UInt(frames.count)

        // 计算每帧字节数
        _bytesPerFrame = UInt(cgImage.width * cgImage.height * 4)  // RGBA8888

        // 使用第一帧初始化 UIImage
        super.init(cgImage: cgImage, scale: firstFrame.scale, orientation: firstFrame.imageOrientation)
    }

    /// 从文件路径加载帧动画图像
    ///
    /// 文件格式示例 (JSON):
    /// ```json
    /// {
    ///   "frames": [
    ///     {"path": "frame1.png", "duration": 0.1},
    ///     {"path": "frame2.png", "duration": 0.15}
    ///   ],
    ///   "loopCount": 0
    /// }
    /// ```
    ///
    /// - Parameter path: 配置文件路径
    /// - Returns: LSFrameImage 实例，如果出错返回 nil
    public convenience init?(contentsOfFile path: String) {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return nil
        }

        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return nil
        }

        guard let framesArray = json["frames"] as? [[String: Any]] else {
            return nil
        }

        let loopCount = (json["loopCount"] as? UInt) ?? 0

        var frames: [UIImage] = []
        var durations: [TimeInterval] = []

        let basePath = (path as NSString).deletingLastPathComponent

        for frameInfo in framesArray {
            guard let framePath = frameInfo["path"] as? String else { continue }
            let fullPath = basePath.isEmpty ? framePath : "\(basePath)/\(framePath)"

            guard let image = UIImage(contentsOfFile: fullPath) else { continue }
            let duration = (frameInfo["duration"] as? TimeInterval) ?? 0.1

            frames.append(image)
            durations.append(duration)
        }

        self.init(frames: frames, durations: durations)
        _loopCount = loopCount
    }

    required init?(coder: NSCoder) {
        guard let framesData = coder.decodeObject(forKey: "framesData") as? [Data] else {
            return nil
        }

        let durationsData = coder.decodeObject(forKey: "durationsData") as? [TimeInterval] ?? []
        _loopCount = UInt(coder.decodeInteger(forKey: "loopCount"))

        var frames: [UIImage] = []
        for data in framesData {
            if let image = UIImage(data: data) {
                frames.append(image)
            }
        }

        guard !frames.isEmpty else { return nil }

        guard let firstFrame = frames.first,
              let cgImage = firstFrame.cgImage else {
            return nil
        }

        self.frameSize = CGSize(width: cgImage.width, height: cgImage.height)
        self._frames = frames
        self._durations = durationsData
        self._frameCount = UInt(frames.count)
        _bytesPerFrame = UInt(cgImage.width * cgImage.height * 4)

        super.init(cgImage: cgImage, scale: firstFrame.scale, orientation: firstFrame.imageOrientation)
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
        guard index < _frameCount else { return nil }
        return _frames[Int(index)]
    }

    public func animatedImageDuration(at index: UInt) -> TimeInterval {
        guard index < _frameCount else { return 0 }
        return _durations[Int(index)]
    }

    public func animatedImageContentsRect(at index: UInt) -> CGRect {
        return CGRect(x: 0, y: 0, width: 1, height: 1)
    }

    // MARK: - NSCoding

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)

        let framesData = _frames.compactMap { $0.pngData() }
        coder.encode(framesData, forKey: "framesData")
        coder.encode(_durations, forKey: "durationsData")
        coder.encode(Int(_loopCount), forKey: "loopCount")
    }
}
#endif

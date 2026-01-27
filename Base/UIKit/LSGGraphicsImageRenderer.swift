//
//  LSGraphicsImageRenderer.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  图形图像渲染器 - 用于高性能图像绘制
//

#if canImport(UIKit)
import UIKit
import Accelerate

// MARK: - LSGraphicsImageRenderer

/// LSGraphicsImageRenderer 是一个高性能的图像渲染器
///
/// 类似 UIGraphicsImageRenderer，但提供更多功能和更好的性能
public class LSGraphicsImageRenderer: NSObject {

    // MARK: - 属性

    /// 图像尺寸
    public var size: CGSize = .zero

    /// 缩放比例
    public var scale: CGFloat = 0

    /// 是否不透明
    public var opaque: Bool = false

    /// 图像上下文
    public var cgContext: CGContext? {
        didSet {
            _cgContext = oldValue
        }
    }

    // MARK: - 私有属性

    private var _cgContext: CGContext?
    private var _bounds: CGRect = .zero

    // MARK: - 初始化

    /// 创建渲染器
    ///
    /// - Parameters:
    ///   - size: 图像尺寸
    ///   - scale: 缩放比例（默认屏幕比例）
    ///   - opaque: 是否不透明
    public init(size: CGSize, scale: CGFloat = 0, opaque: Bool = false) {
        self.size = size
        self.scale = scale == 0 ? UIScreen.main.scale : scale
        self.opaque = opaque
        super.init()
        _createContext()
    }

    /// 从图片创建渲染器
    ///
    /// - Parameter image: 原始图片
    public convenience init(image: UIImage) {
        self.init(size: image.size, scale: image.scale, opaque: true)
        image.draw(at: .zero)
    }

    // MARK: - 私有方法

    private func _createContext() {
        let width = Int(size.width * scale)
        let height = Int(size.height * scale)

        guard width > 0 && height > 0 else { return }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = opaque ? CGImageAlphaInfo.noneSkipFirst : CGImageAlphaInfo.premultipliedFirst

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else { return }

        context.scaleBy(x: scale, y: scale)
        _cgContext = context
        _bounds = CGRect(origin: .zero, size: size)
    }

    // MARK: - 图像生成

    /// 生成图像
    ///
    /// - Returns: 图像对象
    public func makeImage() -> UIImage? {
        guard let context = _cgContext else { return nil }

        guard let cgImage = context.makeImage() else { return nil }

        return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
    }

    /// 生成图像（异步）
    ///
    /// - Parameter completion: 完成回调
    public func makeImage(completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            let image = self.makeImage()

            DispatchQueue.main.async {
                completion(image)
            }
        }
    }

    // MARK: - 绘图方法

    /// 执行绘制操作
    ///
    /// - Parameter drawing: 绘制闭包
    public func image(withDrawing drawing: (CGContext) -> Void) -> UIImage? {
        drawing(_cgContext!)
        return makeImage()
    }

    /// 执行异步绘制操作
    ///
    /// - Parameters:
    ///   - drawing: 绘制闭包
    ///   - completion: 完成回调
    public func image(withDrawing drawing: @escaping (CGContext) -> Void, completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            let image = self.image(withDrawing: drawing)

            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
}

// MARK: - UIImage Extension (高性能渲染)

public extension UIImage {

    /// 使用高性能渲染器创建图片
    ///
    /// - Parameters:
    ///   - size: 图像尺寸
    ///   - scale: 缩放比例
    ///   - opaque: 是否不透明
    ///   - drawing: 绘制闭包
    /// - Returns: 新的图片
    static func ls_render(
        size: CGSize,
        scale: CGFloat = 0,
        opaque: Bool = false,
        drawing: (CGContext) -> Void
    ) -> UIImage? {
        let renderer = LSGraphicsImageRenderer(size: size, scale: scale, opaque: opaque)
        return renderer.image(withDrawing: drawing)
    }

    /// 异步渲染图片
    ///
    /// - Parameters:
    ///   - size: 图像尺寸
    ///   - scale: 缩放比例
    ///   - opaque: 是否不透明
    ///   - drawing: 绘制闭包
    ///   - completion: 完成回调
    static func ls_renderAsync(
        size: CGSize,
        scale: CGFloat = 0,
        opaque: Bool = false,
        drawing: @escaping (CGContext) -> Void,
        completion: @escaping (UIImage?) -> Void
    ) {
        let renderer = LSGraphicsImageRenderer(size: size, scale: scale, opaque: opaque)
        renderer.image(withDrawing: drawing, completion: completion)
    }
}

// MARK: - 图像处理工具

public extension UIImage {

    /// 调整图片大小
    ///
    /// - Parameters:
    ///   - size: 目标尺寸
    ///   - contentMode: 内容模式
    /// - Returns: 调整后的图片
    func ls_resized(to size: CGSize, contentMode: UIView.ContentMode = .scaleToFill) -> UIImage? {
        return LSImageTransformer.shared.resize(self, to: size, contentMode: contentMode)
    }

    /// 裁剪图片到指定尺寸
    ///
    /// - Parameters:
    ///   - size: 目标尺寸
    ///   - anchorPoint: 裁剪锚点
    /// - Returns: 裁剪后的图片
    func ls_cropped(to size: CGSize, anchorPoint: CGPoint = CGPoint(x: 0.5, y: 0.5)) -> UIImage? {
        return LSImageTransformer.shared.crop(self, to: size, anchorPoint: anchorPoint)
    }

    /// 旋转图片
    ///
    /// - Parameters:
    ///   - angle: 旋转角度（弧度）
    ///   - fitSize: 是否适应尺寸
    /// - Returns: 旋转后的图片
    func ls_rotated(by angle: CGFloat, fitSize: Bool = false) -> UIImage? {
        return LSImageTransformer.shared.rotate(self, by: angle, fitSize: fitSize)
    }

    /// 翻转图片
    ///
    /// - Parameters:
    ///   - horizontal: 是否水平翻转
    ///   - vertical: 是否垂直翻转
    /// - Returns: 翻转后的图片
    func ls_flipped(horizontally: Bool = false, vertically: Bool = false) -> UIImage? {
        return LSImageTransformer.shared.flip(self, horizontally: horizontally, vertically: vertically)
    }

    /// 圆角图片
    ///
    /// - Parameters:
    ///   - cornerRadius: 圆角半径
    ///   - borderWidth: 边框宽度
    ///   - borderColor: 边框颜色
    /// - Returns: 圆角图片
    func ls_rounded(cornerRadius: CGFloat, borderWidth: CGFloat = 0, borderColor: UIColor? = nil) -> UIImage? {
        return LSImageTransformer.shared.roundCorner(self, cornerRadius: cornerRadius, borderWidth: borderWidth, borderColor: borderColor)
    }

    /// 圆形图片
    ///
    /// - Parameters:
    ///   - borderWidth: 边框宽度
    ///   - borderColor: 边框颜色
    /// - Returns: 圆形图片
    func ls_circular(borderWidth: CGFloat = 0, borderColor: UIColor? = nil) -> UIImage? {
        return LSImageTransformer.shared.circular(self, borderWidth: borderWidth, borderColor: borderColor)
    }

    /// 模糊图片
    ///
    /// - Parameter radius: 模糊半径
    /// - Returns: 模糊后的图片
    func ls_blurred(radius: CGFloat) -> UIImage? {
        return LSImageTransformer.shared.blur(self, radius: radius)
    }

    /// 灰度图片
    ///
    /// - Returns: 灰度图片
    func ls_grayscale() -> UIImage? {
        return LSImageTransformer.shared.grayscale(self)
    }

    /// 应用滤镜效果
    ///
    /// - Parameter filterName: 滤镜名称
    /// - Returns: 处理后的图片
    func ls_applyingFilter(_ filterName: String) -> UIImage? {
        guard let cgImage = cgImage else { return self }

        #if !os(tvOS)
        let inputImage = CIImage(cgImage: cgImage)
        let context = CIContext(options: nil)

        guard let filter = CIFilter(name: filterName) else { return nil }
        filter.setValue(inputImage, forKey: kCIInputImageKey)

        guard let outputImage = filter.outputImage else { return nil }

        guard let outputCGImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }

        return UIImage(cgImage: outputCGImage, scale: scale, orientation: imageOrientation)
        #else
        return nil
        #endif
    }

    /// 调整亮度
    ///
    /// - Parameter delta: 亮度增量（-1.0 ~ 1.0）
    /// - Returns: 调整后的图片
    func ls_adjustingBrightness(by delta: CGFloat) -> UIImage? {
        return LSImageTransformer.shared.brightness(self, value: delta)
    }

    /// 混合颜色
    ///
    /// - Parameters:
    ///   - color: 要混合的颜色
    ///   - ratio: 混合比例
    /// - Returns: 混合后的图片
    func ls_blended(with color: UIColor, ratio: CGFloat) -> UIImage? {
        return LSImageTransformer.shared.blend(with: color, ratio: ratio)
    }
}

#endif

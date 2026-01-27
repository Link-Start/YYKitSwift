//
//  LSImageTransformer.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  图片变换器 - 用于图片处理和变换
//

#if canImport(UIKit)
import UIKit
import CoreGraphics

// MARK: - LSImageTransformer

/// LSImageTransformer 用于对图片进行各种变换处理
///
/// 支持的变换包括：
/// - 裁剪
/// - 圆角
/// - 缩放
/// - 旋转
/// - 滤镜效果
public class LSImageTransformer: NSObject {

    // MARK: - 单例

    /// 共享变换器
    public static let shared = LSImageTransformer()

    // MARK: - 裁剪

    /// 裁剪图片到指定尺寸
    ///
    /// - Parameters:
    ///   - image: 原始图片
    ///   - size: 目标尺寸
    /// - anchorPoint: 裁剪锚点（默认中心）
    /// - Returns: 裁剪后的图片
    public func crop(_ image: UIImage, to size: CGSize, anchorPoint: CGPoint = CGPoint(x: 0.5, y: 0.5)) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)
        let imageScale = image.scale

        // 计算裁剪区域
        let cropRect = CGRect(
            x: (imageWidth - size.width) * anchorPoint.x,
            y: (imageHeight - size.height) * anchorPoint.y,
            width: size.width,
            height: size.height
        )

        guard let croppedCGImage = cgImage.cropping(to: cropRect) else { return nil }

        return UIImage(cgImage: croppedCGImage, scale: imageScale, orientation: image.imageOrientation)
    }

    /// 裁剪图片到指定区域
    ///
    /// - Parameters:
    ///   - image: 原始图片
    ///   - rect: 裁剪区域
    /// - Returns: 裁剪后的图片
    public func crop(_ image: UIImage, to rect: CGRect) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let scale = image.scale
        let scaledRect = CGRect(
            x: rect.origin.x * scale,
            y: rect.origin.y * scale,
            width: rect.size.width * scale,
            height: rect.size.height * scale
        )

        guard let croppedCGImage = cgImage.cropping(to: scaledRect) else { return nil }

        return UIImage(cgImage: croppedCGImage, scale: scale, orientation: image.imageOrientation)
    }

    // MARK: - 圆角

    /// 创建圆角图片
    ///
    /// - Parameters:
    ///   - image: 原始图片
    ///   - cornerRadius: 圆角半径
    ///   - borderWidth: 边框宽度
    ///   - borderColor: 边框颜色
    /// - Returns: 圆角图片
    public func roundCorner(
        _ image: UIImage,
        cornerRadius: CGFloat,
        borderWidth: CGFloat = 0,
        borderColor: UIColor? = nil
    ) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)

        let rect = CGRect(origin: .zero, size: image.size)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)

        path.clip()

        image.draw(at: .zero)

        // 绘制边框
        if borderWidth > 0, let borderColor = borderColor {
            let borderPath = UIBezierPath(roundedRect: rect.insetBy(dx: borderWidth / 2, dy: borderWidth / 2), cornerRadius: cornerRadius)
            borderPath.lineWidth = borderWidth
            borderColor.setStroke()
            borderPath.stroke()
        }

        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return result
    }

    /// 创建圆形图片
    ///
    /// - Parameters:
    ///   - image: 原始图片
    ///   - borderWidth: 边框宽度
    ///   - borderColor: 边框颜色
    /// - Returns: 圆形图片
    public func circular(
        _ image: UIImage,
        borderWidth: CGFloat = 0,
        borderColor: UIColor? = nil
    ) -> UIImage? {
        let size = image.size
        let cornerRadius = min(size.width, size.height) / 2
        return roundCorner(image, cornerRadius: cornerRadius, borderWidth: borderWidth, borderColor: borderColor)
    }

    // MARK: - 缩放

    /// 缩放图片到指定尺寸
    ///
    /// - Parameters:
    ///   - image: 原始图片
    ///   - size: 目标尺寸
    /// - contentMode: 内容模式
    /// - Returns: 缩放后的图片
    public func resize(_ image: UIImage, to size: CGSize, contentMode: UIView.ContentMode = .scaleToFill) -> UIImage? {
        switch contentMode {
        case .scaleToFill:
            return scaleFill(image, to: size)
        case .scaleAspectFit:
            return scaleAspectFit(image, to: size)
        case .scaleAspectFill:
            return scaleAspectFill(image, to: size)
        default:
            return scaleFill(image, to: size)
        }
    }

    private func scaleFill(_ image: UIImage, to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: size))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }

    private func scaleAspectFit(_ image: UIImage, to size: CGSize) -> UIImage? {
        let imageRatio = image.size.width / image.size.height
        let sizeRatio = size.width / size.height

        let scaledSize: CGSize
        if imageRatio > sizeRatio {
            scaledSize = CGSize(width: size.width, height: size.width / imageRatio)
        } else {
            scaledSize = CGSize(width: size.height * imageRatio, height: size.height)
        }

        UIGraphicsBeginImageContextWithOptions(scaledSize, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: scaledSize))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return result
    }

    private func scaleAspectFill(_ image: UIImage, to size: CGSize) -> UIImage? {
        let imageRatio = image.size.width / image.size.height
        let sizeRatio = size.width / size.height

        let scaledSize: CGSize
        if imageRatio < sizeRatio {
            scaledSize = CGSize(width: size.width, height: size.width / imageRatio)
        } else {
            scaledSize = CGSize(width: size.height * imageRatio, height: size.height)
        }

        UIGraphicsBeginImageContextWithOptions(scaledSize, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: scaledSize))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        // 裁剪到目标尺寸
        return crop(result ?? image, to: size)
    }

    // MARK: - 旋转

    /// 旋转图片
    ///
    /// - Parameters:
    ///   - image: 原始图片
    ///   - angle: 旋转角度（弧度）
    ///   - fitSize: 是否适应尺寸（避免旋转后被裁剪）
    /// - Returns: 旋转后的图片
    public func rotate(_ image: UIImage, by angle: CGFloat, fitSize: Bool = false) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)
        let imageScale = image.scale

        var drawRect: CGRect
        var rotatedSize: CGSize

        if fitSize {
            // 计算旋转后的尺寸
            let radian = angle * .pi / 180.0
            rotatedSize = CGSize(
                width: abs(imageWidth * cos(radian)) + abs(imageHeight * sin(radian)),
                height: abs(imageWidth * sin(radian)) + abs(imageHeight * cos(radian))
            )
            drawRect = CGRect(
                x: (rotatedSize.width - imageWidth) / 2,
                y: (rotatedSize.height - imageHeight) / 2,
                width: imageWidth,
                height: imageHeight
            )
        } else {
            rotatedSize = CGSize(width: imageWidth, height: imageHeight)
            drawRect = CGRect(origin: .zero, size: rotatedSize)
        }

        UIGraphicsBeginImageContextWithOptions(rotatedSize, false, imageScale)
        let context = UIGraphicsGetCurrentContext()

        context?.saveGState()
        context?.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        context?.rotate(by: angle)
        context?.translateBy(x: -rotatedSize.width / 2, y: -rotatedSize.height / 2)

        image.draw(in: drawRect)
        context?.restoreGState()

        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return result
    }

    /// 翻转图片
    ///
    /// - Parameters:
    ///   - image: 原始图片
    ///   - horizontal: 是否水平翻转
    ///   - vertical: 是否垂直翻转
    /// - Returns: 翻转后的图片
    public func flip(_ image: UIImage, horizontally: Bool = false, vertically: Bool = false) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)
        let imageScale = image.scale

        UIGraphicsBeginImageContextWithOptions(CGSize(width: imageWidth, height: imageHeight), false, imageScale)
        let context = UIGraphicsGetCurrentContext()

        context?.translateBy(x: imageWidth / 2, y: imageHeight / 2)

        if horizontally && vertically {
            context?.rotate(by: .pi)
        } else if horizontally {
            context?.rotate(by: .pi)
            context?.scaleBy(x: 1, y: -1)
        } else if vertically {
            context?.scaleBy(x: 1, y: -1)
        }

        context?.translateBy(x: -imageWidth / 2, y: -imageHeight / 2)

        image.draw(at: .zero)

        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return result
    }

    // MARK: - 滤镜

    /// 应用模糊效果
    ///
    /// - Parameters:
    ///   - image: 原始图片
    ///   - radius: 模糊半径
    /// - Returns: 模糊后的图片
    public func blur(_ image: UIImage, radius: CGFloat) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        // 使用 CIImage 进行模糊处理
        #if !os(tvOS)
        let inputImage = CIImage(cgImage: cgImage)
        let context = CIContext(options: nil)

        guard let filter = CIFilter(name: "CIGaussianBlur") else { return nil }
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(radius, forKey: kCIInputRadiusKey)

        guard let outputImage = filter.outputImage else { return nil }

        guard let outputCGImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }

        return UIImage(cgImage: outputCGImage, scale: image.scale, orientation: image.imageOrientation)
        #else
        return nil
        #endif
    }

    /// 应用灰度效果
    ///
    /// - Parameter image: 原始图片
    /// - Returns: 灰度图片
    public func grayscale(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        // 使用 CIImage 进行灰度处理
        #if !os(tvOS)
        let inputImage = CIImage(cgImage: cgImage)
        let context = CIContext(options: nil)

        guard let filter = CIFilter(name: "CIPhotoEffectNoir") else { return nil }
        filter.setValue(inputImage, forKey: kCIInputImageKey)

        guard let outputImage = filter.outputImage else { return nil }

        guard let outputCGImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }

        return UIImage(cgImage: outputCGImage, scale: image.scale, orientation: image.imageOrientation)
        #else
        return nil
        #endif
    }

    /// 调整图片亮度
    ///
    /// - Parameters:
    ///   - image: 原始图片
    ///   - brightness: 亮度值（-1.0 ~ 1.0）
    /// - Returns: 调整后的图片
    public func brightness(_ image: UIImage, value: CGFloat) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        #if !os(tvOS)
        let inputImage = CIImage(cgImage: cgImage)
        let context = CIContext(options: nil)

        guard let filter = CIFilter(name: "CIColorControls") else { return nil }
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(value, forKey: kCIInputBrightnessKey)

        guard let outputImage = filter.outputImage else { return nil }

        guard let outputCGImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }

        return UIImage(cgImage: outputCGImage, scale: image.scale, orientation: image.imageOrientation)
        #else
        return nil
        #endif
    }

    // MARK: - 组合变换

    /// 应用多个变换
    ///
    /// - Parameters:
    ///   - image: 原始图片
    ///   - transforms: 变换闭包数组
    /// - Returns: 变换后的图片
    public func apply(_ image: UIImage, transforms: [(LSImageTransformer) -> UIImage?]) -> UIImage? {
        var result = image
        for transform in transforms {
            guard let transformed = transform(self) else { return nil }
            result = transformed
        }
        return result
    }
}

// MARK: - UIImage Extension

public extension UIImage {

    /// 裁剪图片
    ///
    /// - Parameter size: 目标尺寸
    /// - Returns: 裁剪后的图片
    func ls_cropped(to size: CGSize) -> UIImage? {
        return LSImageTransformer.shared.crop(self, to: size)
    }

    /// 创建圆角图片
    ///
    /// - Parameter cornerRadius: 圆角半径
    /// - Returns: 圆角图片
    func ls_rounded(cornerRadius: CGFloat) -> UIImage? {
        return LSImageTransformer.shared.roundCorner(self, cornerRadius: cornerRadius)
    }

    /// 创建圆形图片
    ///
    /// - Returns: 圆形图片
    func ls_circular() -> UIImage? {
        return LSImageTransformer.shared.circular(self)
    }

    /// 缩放图片
    ///
    /// - Parameter size: 目标尺寸
    /// - Returns: 缩放后的图片
    func ls_resized(to size: CGSize) -> UIImage? {
        return LSImageTransformer.shared.resize(self, to: size)
    }

    /// 旋转图片
    ///
    /// - Parameter angle: 旋转角度（弧度）
    /// - Returns: 旋转后的图片
    func ls_rotated(by angle: CGFloat) -> UIImage? {
        return LSImageTransformer.shared.rotate(self, by: angle)
    }

    /// 模糊图片
    ///
    /// - Parameter radius: 模糊半径
    /// - Returns: 模糊后的图片
    func ls_blurred(radius: CGFloat) -> UIImage? {
        return LSImageTransformer.shared.blur(self, radius: radius)
    }
}

#endif

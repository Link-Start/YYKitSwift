//
//  LSImageView.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  增强的图像视图 - 支持占位图、加载状态、图片处理等
//

#if canImport(UIKit)
import UIKit

// MARK: - LSImageView

/// 增强的图像视图
@MainActor
public class LSImageView: UIImageView {

    // MARK: - 类型定义

    /// 内容模式动画
    public enum ContentModeAnimation {
        case none
        case fade
        case scale
        case custom((UIImageView) -> Void)
    }

    /// 加载状态
    public enum LoadingState {
        case idle
        case loading
        case success
        case failed(Error)
    }

    // MARK: - 属性

    /// 占位图
    public var placeholderImage: UIImage? {
        didSet {
            if image == nil {
                super.image = placeholderImage
            }
        }
    }

    /// 错误图
    public var errorImage: UIImage? {
        didSet {
            updateErrorState()
        }
    }

    /// 加载状态
    public private(set) var loadingState: LoadingState = .idle {
        didSet {
            handleLoadingStateChange()
        }
    }

    /// 是否显示加载指示器
    public var showsLoadingIndicator: Bool = true {
        didSet {
            updateLoadingIndicator()
        }
    }

    /// 内容模式切换动画
    public var contentModeAnimation: ContentModeAnimation = .none

    /// 是否允许缩放
    public var isZoomEnabled: Bool = false

    /// 最小缩放比例
    public var minimumZoomScale: CGFloat = 1.0

    /// 最大缩放比例
    public var maximumZoomScale: CGFloat = 3.0

    /// 图片 URL
    public private(set) var currentImageURL: URL?

    /// 图片加载完成回调
    public var onImageLoaded: ((UIImage?) -> Void)?

    /// 图片加载失败回调
    public var onImageLoadFailed: ((Error) -> Void)?

    // MARK: - 私有属性

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private var activityControlView: UIActivityIndicatorView?

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupImageView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupImageView()
    }

    public convenience init(image: UIImage? = nil, placeholder: UIImage? = nil) {
        self.init(frame: .zero)
        self.image = image
        self.placeholderImage = placeholder
    }

    // MARK: - 设置

    private func setupImageView() {
        clipsToBounds = true
        contentMode = .scaleAspectFill

        // 添加加载指示器
        addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    // MARK: - 图片设置

    public override var image: UIImage? {
        didSet {
            onImageLoaded?(image)
        }
    }

    /// 设置图片并带动画
    public func ls_setImage(_ image: UIImage?, animated: Bool = true) {
        guard animated else {
            self.image = image
            return
        }

        switch contentModeAnimation {
        case .none:
            self.image = image

        case .fade:
            UIView.transition(with: self, duration: 0.3, options: .transitionCrossDissolve) {
                self.image = image
            }

        case .scale:
            alpha = 0
            transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.image = image

            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
                self.alpha = 1
                self.transform = .identity
            }

        case .custom(let animation):
            animation(self)
        }
    }

    /// 从 URL 加载图片（需配合 SDWebImage 或类似库）
    public func ls_setImage(with url: URL?, placeholder: UIImage? = nil) {
        currentImageURL = url

        guard let url = url else {
            let img: UIImage?
            if let ph = placeholder {
                img = ph
            } else {
                img = placeholderImage
            }
            image = img
            loadingState = .idle
            return
        }

        loadingState = .loading

        let img2: UIImage?
        if let ph = placeholder {
            img2 = ph
        } else {
            img2 = placeholderImage
        }
        image = img2

        // 这里应该使用 SDWebImage 或类似库
        // 暂时使用系统方法
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            if let data = try? Data(contentsOf: url) {
                let loadedImage = UIImage(data: data)

                DispatchQueue.main.async {
                    self.loadingState = .success
                    self.ls_setImage(loadedImage, animated: true)
                }
            } else {
                let error = NSError(domain: "LSImageView", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to load image"
                ])

                DispatchQueue.main.async {
                    self.loadingState = .failed(error)
                }
            }
        }
    }

    /// 取消图片加载
    public func ls_cancelImageLoad() {
        currentImageURL = nil
        loadingState = .idle
    }

    // MARK: - 加载状态处理

    private func handleLoadingStateChange() {
        switch loadingState {
        case .idle:
            loadingIndicator.stopAnimating()
            image = placeholderImage

        case .loading:
            if showsLoadingIndicator {
                loadingIndicator.startAnimating()
            }

        case .success:
            loadingIndicator.stopAnimating()

        case .failed(let error):
            loadingIndicator.stopAnimating()
            updateErrorState()
            onImageLoadFailed?(error)
        }
    }

    private func updateLoadingIndicator() {
        if showsLoadingIndicator && loadingState == .loading {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
    }

    private func updateErrorState() {
        if case .failed = loadingState {
            let img: UIImage?
            if let errImg = errorImage {
                img = errImg
            } else {
                img = placeholderImage
            }
            image = img
        }
    }

    // MARK: - 图片处理

    /// 获取裁剪后的图片
    public var ls_croppedImage: UIImage? {
        guard let image = image else { return nil }

        let scale = image.scale
        let rect = CGRect(
            x: bounds.origin.x * scale,
            y: bounds.origin.y * scale,
            width: bounds.size.width * scale,
            height: bounds.size.height * scale
        )

        guard let cgImage = image.cgImage?.cropping(to: rect) else { return nil }
        return UIImage(cgImage: cgImage, scale: scale, orientation: image.imageOrientation)
    }

    /// 获取模糊图片
    public func ls_blurredImage(radius: CGFloat = 10) -> UIImage? {
        guard let image = image else { return nil }

        let inputImage = CIImage(cgImage: image.cgImage!)
        let blurFilter = CIFilter(name: "CIGaussianBlur")
        blurFilter?.setValue(inputImage, forKey: kCIInputImageKey)
        blurFilter?.setValue(radius, forKey: kCIInputRadiusKey)

        guard let outputImage = blurFilter?.outputImage else { return nil }

        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(outputImage, from: inputImage.extent) else { return nil }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

    /// 获取灰度图片
    public var ls_grayscaleImage: UIImage? {
        guard let image = image else { return nil }

        let context = CIContext(options: nil)
        let ciImage = CIImage(cgImage: image.cgImage!)

        guard let filter = CIFilter(name: "CIColorMonochrome") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(CIColor(gray: 0.5), forKey: kCIInputColorKey)
        filter.setValue(1.0, forKey: kCIInputIntensityKey)

        guard let outputImage = filter.outputImage else { return nil }
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

    /// 获取圆形图片
    public var ls_circularImage: UIImage? {
        guard let image = image else { return nil }

        let size = CGSize(width: min(bounds.width, bounds.height), height: min(bounds.width, bounds.height))
        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)

        let rect = CGRect(origin: .zero, size: size)
        UIBezierPath(ovalIn: rect).addClip()
        image.draw(in: rect)

        let circularImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return circularImage
    }

    /// 获取带圆角的图片
    public func ls_roundedImage(cornerRadius: CGFloat) -> UIImage? {
        guard let image = image else { return nil }

        UIGraphicsBeginImageContextWithOptions(bounds.size, false, image.scale)

        let rect = CGRect(origin: .zero, size: bounds.size)
        UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).addClip()
        image.draw(in: rect)

        let roundedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return roundedImage
    }

    /// 获取带边框的图片
    public func ls_imageWithBorder(color: UIColor, width: CGFloat) -> UIImage? {
        guard let image = image else { return nil }

        let size = CGSize(
            width: image.size.width + width * 2,
            height: image.size.height + width * 2
        )

        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)

        let rect = CGRect(
            origin: CGPoint(x: width, y: width),
            size: image.size
        )

        color.set()
        UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: width).fill()

        UIBezierPath(roundedRect: rect, cornerRadius: width).addClip()
        image.draw(at: CGPoint(x: width, y: width))

        let borderedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return borderedImage
    }

    // MARK: - 动画

    /// 淡入动画
    public func ls_fadeIn(duration: TimeInterval = 0.3) {
        alpha = 0
        UIView.animate(withDuration: duration) {
            self.alpha = 1
        }
    }

    /// 淡出动画
    public func ls_fadeOut(duration: TimeInterval = 0.3) {
        UIView.animate(withDuration: duration) {
            self.alpha = 0
        }
    }

    /// 缩放动画
    public func ls_scale(from: CGFloat, to: CGFloat, duration: TimeInterval = 0.3) {
        transform = CGAffineTransform(scaleX: from, y: from)
        UIView.animate(withDuration: duration) {
            self.transform = CGAffineTransform(scaleX: to, y: to)
        }
    }

    /// 旋转动画
    public func ls_rotate(angle: CGFloat, duration: TimeInterval = 0.3) {
        UIView.animate(withDuration: duration) {
            self.transform = CGAffineTransform(rotationAngle: angle)
        }
    }

    /// 抖动动画
    public func ls_shake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.5
        animation.values = [-10, 10, -8, 8, -5, 5, 0]
        layer.add(animation, forKey: "shake")
    }

    /// 脉冲动画
    public func ls_pulse(duration: TimeInterval = 0.3) {
        UIView.animate(withDuration: duration, animations: {
            self.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }) { _ in
            UIView.animate(withDuration: duration) {
                self.transform = .identity
            }
        }
    }
}

// MARK: - UIImageView Extension

public extension UIImageView {

    /// 创建预配置的图像视图
    static func ls_imageView(
        image: UIImage? = nil,
        contentMode: UIView.ContentMode = .scaleAspectFill
    ) -> UIImageView {
        let imageView = UIImageView(image: image)
        imageView.contentMode = contentMode
        imageView.clipsToBounds = true
        return imageView
    }

    /// 设置圆形图像
    func ls_setCircular(image: UIImage?, borderWidth: CGFloat = 0, borderColor: UIColor = .clear) {
        self.image = image
        layer.masksToBounds = true
        layer.cornerRadius = bounds.width / 2
        layer.borderWidth = borderWidth
        layer.borderColor = borderColor.cgColor
    }

    /// 设置带阴影的图像
    func ls_setShadow(
        color: UIColor = .black,
        offset: CGSize = CGSize(width: 0, height: 2),
        opacity: Float = 0.3,
        radius: CGFloat = 4
    ) {
        layer.shadowColor = color.cgColor
        layer.shadowOffset = offset
        layer.shadowOpacity = opacity
        layer.shadowRadius = radius
        clipsToBounds = false
    }

    /// 从颜色创建图像
    static func ls_image(with color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    /// 从渐变创建图像
    static func ls_gradientImage(
        colors: [UIColor],
        size: CGSize = CGSize(width: 100, height: 100),
        startPoint: CGPoint = CGPoint(x: 0, y: 0),
        endPoint: CGPoint = CGPoint(x: 1, y: 1)
    ) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)

        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let cgColors = colors.map { $0.cgColor } as CFArray

        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: cgColors, locations: nil) else {
            UIGraphicsEndImageContext()
            return nil
        }

        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: size.width * startPoint.x, y: size.height * startPoint.y),
            end: CGPoint(x: size.width * endPoint.x, y: size.height * endPoint.y),
            options: []
        )

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }

    /// 从视图创建图像
    static func ls_image(from view: UIView) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
        return renderer.image { context in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
    }
}

// MARK: - Async Image Loading (Future)

#if canImport(Async)
import Async

@available(iOS 15.0, *)
public extension LSImageView {

    /// 使用 async/await 加载图片
    func ls_loadImage(from url: URL) async throws -> UIImage {
        loadingState = .loading

        return try await withCheckedThrowingContinuation { continuation in
            // 这里应该使用 URLSession 或 SDWebImage 的 async 版本
            DispatchQueue.global(qos: .userInitiated).async {
                if let data = try? Data(contentsOf: url),
                   let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.loadingState = .success
                        self.ls_setImage(image, animated: true)
                        continuation.resume(returning: image)
                    }
                } else {
                    let error = NSError(domain: "LSImageView", code: -1, userInfo: nil)
                    DispatchQueue.main.async {
                        self.loadingState = .failed(error)
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
}
#endif

// MARK: - Image Extensions

public extension UIImage {

    /// 调整图片大小
    func ls_resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }

    /// 裁剪图片
    func ls_cropped(to rect: CGRect) -> UIImage? {
        guard let cgImage = cgImage?.cropping(to: rect) else { return nil }
        return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
    }

    /// 获取圆形图片
    var ls_circular: UIImage? {
        let targetSize = CGSize(width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(targetSize, false, scale)

        let rect = CGRect(origin: .zero, size: targetSize)
        UIBezierPath(ovalIn: rect).addClip()
        draw(in: rect)

        let circularImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return circularImage
    }

    /// 获取带圆角的图片
    func ls_rounded(cornerRadius: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)

        let rect = CGRect(origin: .zero, size: size)
        UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).addClip()
        draw(in: rect)

        let roundedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return roundedImage
    }

    /// 获取灰度图片
    var ls_grayscale: UIImage? {
        guard let ciImage = CIImage(image: self) else { return nil }

        guard let filter = CIFilter(name: "CIColorMonochrome") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(CIColor(gray: 0.5), forKey: kCIInputColorKey)
        filter.setValue(1.0, forKey: kCIInputIntensityKey)

        guard let outputImage = filter.outputImage else { return nil }

        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }

        return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
    }

    /// 获取模糊图片
    func ls_blurred(radius: CGFloat = 10) -> UIImage? {
        guard let ciImage = CIImage(image: self) else { return nil }

        guard let filter = CIFilter(name: "CIGaussianBlur") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(radius, forKey: kCIInputRadiusKey)

        guard let outputImage = filter.outputImage else { return nil }

        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(outputImage, from: ciImage.extent) else { return nil }

        return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
    }

    /// 获取带颜色的图片（适用于模板图片）
    func ls_tinted(with color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)

        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }

        color.setFill()
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)

        context.setBlendMode(.normal)
        if let cgImage = cgImage {
            context.draw(cgImage, in: CGRect(origin: .zero, size: size))
        }

        context.setBlendMode(.sourceIn)
        context.fill(CGRect(origin: .zero, size: size))

        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return tintedImage
    }

    /// 合并图片
    func ls_combined(with image: UIImage) -> UIImage? {
        let combinedSize = CGSize(
            width: max(size.width, image.size.width),
            height: max(size.height, image.size.height)
        )

        UIGraphicsBeginImageContextWithOptions(combinedSize, false, scale)
        draw(at: .zero)
        image.draw(at: .zero)
        let combinedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return combinedImage
    }

    /// 添加水印
    func ls_watermarked(
        with watermarkImage: UIImage,
        at position: CGPoint = CGPoint(x: 0, y: 0),
        alpha: CGFloat = 0.5
    ) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: .zero)

        watermarkImage.withAlpha(alpha).draw(at: position)

        let watermarkedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return watermarkedImage
    }

    /// 调整透明度
    func ls_withAlpha(_ alpha: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)

        draw(at: .zero, blendMode: .normal, alpha: alpha)

        let alphaImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return alphaImage
    }

    /// 旋转图片
    func ls_rotated(by angle: CGFloat) -> UIImage? {
        let rotatedSize = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: angle))
            .integral.size

        UIGraphicsBeginImageContextWithOptions(rotatedSize, false, scale)

        if let context = UIGraphicsGetCurrentContext() {
            let origin = CGPoint(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
            context.translateBy(x: origin.x, y: origin.y)
            context.rotate(by: angle)
            draw(in: CGRect(origin: CGPoint(x: -size.width / 2, y: -size.height / 2), size: size))
        }

        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return rotatedImage
    }

    /// 翻转图片
    func ls_flipped(horizontally: Bool = false, vertically: Bool = false) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)

        if let context = UIGraphicsGetCurrentContext() {
            let origin = CGPoint(x: size.width / 2, y: size.height / 2)
            context.translateBy(x: origin.x, y: origin.y)

            if horizontally {
                context.scaleBy(x: -1, y: 1)
            }
            if vertically {
                context.scaleBy(x: 1, y: -1)
            }

            context.translateBy(x: -origin.x, y: -origin.y)
            draw(in: CGRect(origin: .zero, size: size))
        }

        let flippedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return flippedImage
    }

    /// 获取平均颜色
    var ls_averageColor: UIColor? {
        guard let cgImage = cgImage else { return nil }

        let size = CGSize(width: 1, height: 1)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else { return nil }

        context.draw(cgImage, in: CGRect(origin: .zero, size: size))

        guard let data = context.data else { return nil }
        let pointer = data.bindMemory(to: UInt8.self, capacity: 4)

        let r = CGFloat(pointer[0]) / 255.0
        let g = CGFloat(pointer[1]) / 255.0
        let b = CGFloat(pointer[2]) / 255.0
        let a = CGFloat(pointer[3]) / 255.0

        return UIColor(red: r, green: g, blue: b, alpha: a)
    }

    /// 获取主题色（最常用的颜色）
    func ls_dominantColor() -> UIColor? {
        guard let cgImage = cgImage else { return nil }

        let size = CGSize(width: 50, height: 50)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else { return nil }

        context.draw(cgImage, in: CGRect(origin: .zero, width: size.width, height: size.height))

        guard let data = context.data else { return nil }
        let pointer = data.bindMemory(to: UInt32.self, capacity: Int(size.width * size.height))

        var colorCounts: [UInt32: Int] = [:]

        for i in 0..<Int(size.width * size.height) {
            let color = pointer[i]
            colorCounts[color, default: 0] += 1
        }

        let dominantColor = colorCounts.max(by: { $0.value < $1.value })?.key

        guard let hex = dominantColor else { return nil }

        let r = CGFloat((hex >> 16) & 0xFF) / 255.0
        let g = CGFloat((hex >> 8) & 0xFF) / 255.0
        let b = CGFloat(hex & 0xFF) / 255.0
        let a = CGFloat((hex >> 24) & 0xFF) / 255.0

        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}

#endif

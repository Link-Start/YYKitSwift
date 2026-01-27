//
//  UIImage+QRCode.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-26.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  UIImage 二维码生成扩展
//

#if canImport(UIKit)
import UIKit

// MARK: - UIImage 二维码扩展

public extension UIImage {

    // MARK: - 二维码配置

    /// 二维码生成配置
    struct LSQRCodeConfig {

        /// 二维码颜色，默认黑色
        var codeColor: UIColor = UIColor.black

        /// 背景颜色，默认白色
        var backgroundColor: UIColor = UIColor.white

        /// Logo 图片
        var logoImage: UIImage?

        /// Logo 相对二维码的比例（0.0 ~ 0.3），默认 0.2
        var logoRatio: CGFloat = 0.2

        /// Logo 外边框圆角（0.0 ~ 10.0），默认 5.0
        var logoCornerRadius: CGFloat = 5.0

        /// Logo 外边框宽度（0.0 ~ 10.0），默认 5.0
        var logoBorderWidth: CGFloat = 5.0

        /// Logo 外边框颜色，默认白色
        var logoBorderColor: UIColor = UIColor.white

        /// 纠错级别，默认 H（30%）
        var correctionLevel: LSQRCodeCorrectionLevel = .high

        /// 默认配置
        public static var `default`: LSQRCodeConfig {
            LSQRCodeConfig()
        }

        /// 创建配置
        public init(
            codeColor: UIColor = UIColor.black,
            backgroundColor: UIColor = UIColor.white,
            logoImage: UIImage? = nil,
            logoRatio: CGFloat = 0.2,
            logoCornerRadius: CGFloat = 5.0,
            logoBorderWidth: CGFloat = 5.0,
            logoBorderColor: UIColor = UIColor.white,
            correctionLevel: LSQRCodeCorrectionLevel = .high
        ) {
            self.codeColor = codeColor
            self.backgroundColor = backgroundColor
            self.logoImage = logoImage
            self.logoRatio = min(max(logoRatio, 0), 0.3)
            self.logoCornerRadius = min(max(logoCornerRadius, 0), 10)
            self.logoBorderWidth = min(max(logoBorderWidth, 0), 10)
            self.logoBorderColor = logoBorderColor
            self.correctionLevel = correctionLevel
        }
    }

    /// 二维码纠错级别
    enum LSQRCodeCorrectionLevel: String {
        case low = "L"      // 7% 纠错
        case medium = "M"   // 15% 纠错
        case quartile = "Q" // 25% 纠错
        case high = "H"     // 30% 纠错
    }

    // MARK: - 二维码生成

    /// 生成二维码（基础）
    ///
    /// - Parameters:
    ///   - string: 二维码内容
    ///   - size: 二维码尺寸，默认 300
    /// - Returns: 二维码图片
    static func ls_qrCode(_ string: String, size: CGFloat = 300) -> UIImage? {
        ls_qrCode(string, size: size, config: .default)
    }

    /// 生成二维码（自定义颜色）
    ///
    /// - Parameters:
    ///   - string: 二维码内容
    ///   - size: 二维码尺寸，默认 300
    ///   - codeColor: 二维码颜色，默认黑色
    ///   - backgroundColor: 背景颜色，默认白色
    /// - Returns: 二维码图片
    static func ls_qrCode(
        _ string: String,
        size: CGFloat = 300,
        codeColor: UIColor,
        backgroundColor: UIColor = UIColor.white
    ) -> UIImage? {
        var config = LSQRCodeConfig.default
        config.codeColor = codeColor
        config.backgroundColor = backgroundColor
        return ls_qrCode(string, size: size, config: config)
    }

    /// 生成二维码（带 Logo）
    ///
    /// - Parameters:
    ///   - string: 二维码内容
    ///   - size: 二维码尺寸，默认 300
    ///   - logoImage: Logo 图片
    ///   - logoRatio: Logo 相对二维码的比例（0.0 ~ 0.3），默认 0.2
    /// - Returns: 二维码图片
    static func ls_qrCode(
        _ string: String,
        size: CGFloat = 300,
        logoImage: UIImage,
        logoRatio: CGFloat = 0.2
    ) -> UIImage? {
        var config = LSQRCodeConfig.default
        config.logoImage = logoImage
        config.logoRatio = logoRatio
        return ls_qrCode(string, size: size, config: config)
    }

    /// 生成二维码（完整配置）
    ///
    /// - Parameters:
    ///   - string: 二维码内容
    ///   - size: 二维码尺寸，默认 300
    ///   - config: 二维码配置
    /// - Returns: 二维码图片
    static func ls_qrCode(
        _ string: String,
        size: CGFloat = 300,
        config: LSQRCodeConfig
    ) -> UIImage? {
        // 1. 生成 QRCode
        guard let qrImage = generateQRCodeImage(string, size: size, config: config) else {
            return nil
        }

        // 2. 如果有 Logo，添加 Logo
        if let logo = config.logoImage {
            return addLogo(to: qrImage, logo: logo, config: config)
        }

        return qrImage
    }

    // MARK: - 私有方法

    /// 生成 QRCode 基础图片
    private static func generateQRCodeImage(
        _ string: String,
        size: CGFloat,
        config: LSQRCodeConfig
    ) -> UIImage? {
        // 将字符串转换为 Data
        guard let data = string.data(using: .utf8) else { return nil }

        // 创建滤镜
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue(config.correctionLevel.rawValue, forKey: "inputCorrectionLevel")

        // 生成二维码
        guard let ciImage = filter.outputImage else { return nil }

        // 计算缩放比例
        let scaleX = size / ciImage.extent.width
        let scaleY = size / ciImage.extent.height
        let transformedImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        // 颜色处理
        let coloredImage = applyColors(to: transformedImage, codeColor: config.codeColor, backgroundColor: config.backgroundColor)

        // 转换为 UIImage
        return UIImage(ciImage: coloredImage)
    }

    /// 为二维码应用颜色
    private static func applyColors(to ciImage: CIImage, codeColor: UIColor, backgroundColor: UIColor) -> CIImage {
        // 创建颜色滤镜
        let colorFilter = CIFilter(name: "CIFalseColor")
        colorFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        colorFilter?.setValue(CIColor(cgColor: codeColor.cgColor), forKey: "inputColor0")
        colorFilter?.setValue(CIColor(cgColor: backgroundColor.cgColor), forKey: "inputColor1")
        return colorFilter?.outputImage ?? ciImage
    }

    /// 添加 Logo 到二维码
    private static func addLogo(to qrImage: UIImage, logo: UIImage, config: LSQRCodeConfig) -> UIImage {
        let size = qrImage.size

        // 1. 创建图形上下文
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }

        // 2. 绘制二维码
        qrImage.draw(in: CGRect(origin: .zero, size: size))

        // 3. 计算 Logo 尺寸和位置
        let logoSize = CGSize(width: size.width * config.logoRatio, height: size.height * config.logoRatio)
        let logoOrigin = CGPoint(x: (size.width - logoSize.width) / 2, y: (size.height - logoSize.height) / 2)

        // 4. 绘制 Logo 外边框
        if config.logoBorderWidth > 0 {
            let borderPath = UIBezierPath(
                roundedRect: CGRect(
                    x: logoOrigin.x - config.logoBorderWidth,
                    y: logoOrigin.y - config.logoBorderWidth,
                    width: logoSize.width + config.logoBorderWidth * 2,
                    height: logoSize.height + config.logoBorderWidth * 2
                ),
                cornerRadius: config.logoCornerRadius
            )
            config.logoBorderColor.setFill()
            borderPath.fill()
        }

        // 5. 绘制 Logo（带圆角）
        UIGraphicsBeginImageContextWithOptions(logoSize, false, UIScreen.main.scale)
        let logoPath = UIBezierPath(roundedRect: CGRect(origin: .zero, size: logoSize), cornerRadius: config.logoCornerRadius)
        logoPath.addClip()
        logo.draw(in: CGRect(origin: .zero, size: logoSize))
        let roundedLogo = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        // 6. 绘制圆角 Logo
        roundedLogo?.draw(in: CGRect(origin: logoOrigin, size: logoSize))

        // 7. 获取最终图片
        return UIGraphicsGetImageFromCurrentImageContext() ?? qrImage
    }
}

// MARK: - NSString 二维码扩展

public extension String {

    /// 生成二维码
    ///
    /// - Parameters:
    ///   - size: 二维码尺寸，默认 300
    ///   - config: 二维码配置
    /// - Returns: 二维码图片
    func ls_qrCode(size: CGFloat = 300, config: UIImage.LSQRCodeConfig = .default) -> UIImage? {
        UIImage.ls_qrCode(self, size: size, config: config)
    }

    /// 生成二维码（自定义颜色）
    ///
    /// - Parameters:
    ///   - size: 二维码尺寸
    ///   - codeColor: 二维码颜色
    ///   - backgroundColor: 背景颜色
    /// - Returns: 二维码图片
    func ls_qrCode(
        size: CGFloat = 300,
        codeColor: UIColor,
        backgroundColor: UIColor = .white
    ) -> UIImage? {
        UIImage.ls_qrCode(self, size: size, codeColor: codeColor, backgroundColor: backgroundColor)
    }

    /// 生成二维码（带 Logo）
    ///
    /// - Parameters:
    ///   - size: 二维码尺寸
    ///   - logoImage: Logo 图片
    ///   - logoRatio: Logo 比例
    /// - Returns: 二维码图片
    func ls_qrCode(
        size: CGFloat = 300,
        logoImage: UIImage,
        logoRatio: CGFloat = 0.2
    ) -> UIImage? {
        UIImage.ls_qrCode(self, size: size, logoImage: logoImage, logoRatio: logoRatio)
    }
}

// MARK: - 使用示例

/*
 ## 基础使用

 ```swift
 // 1. 生成基础二维码
 let qrCode = UIImage.ls_qrCode("https://example.com", size: 300)
 imageView.image = qrCode

 // 2. 生成自定义颜色二维码
 let qrCode = UIImage.ls_qrCode(
     "https://example.com",
     size: 300,
     codeColor: UIColor.systemBlue,
     backgroundColor: UIColor.white
 )

 // 3. 生成带 Logo 的二维码
 let qrCode = UIImage.ls_qrCode(
     "https://example.com",
     size: 300,
     logoImage: logoImage,
     logoRatio: 0.2
 )

 // 4. 完整配置
 var config = UIImage.LSQRCodeConfig.default
 config.codeColor = .black
 config.backgroundColor = .white
 config.logoImage = logoImage
 config.logoRatio = 0.25
 config.logoCornerRadius = 8.0
 config.logoBorderWidth = 6.0
 config.logoBorderColor = .white
 config.correctionLevel = .high

 let qrCode = UIImage.ls_qrCode("https://example.com", size: 300, config: config)

 // 5. String 扩展
 let qrCode = "https://example.com".ls_qrCode(size: 300)
 ```
 */
#endif

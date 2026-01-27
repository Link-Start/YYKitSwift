//
//  UIImage+YYKitSwift.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  UIImage 扩展，提供图片创建、修改和效果方法
//

import UIKit
import ImageIO
import Accelerate

// MARK: - UIImage 扩展

public extension UIImage {

    // MARK: - 创建图片

    /// 从颜色创建 1x1 图片
    static func ls_color(_ color: UIColor) -> UIImage? {
        return ls_color(color, size: CGSize(width: 1, height: 1))
    }

    /// 从颜色创建指定尺寸的图片
    static func ls_color(_ color: UIColor, size: CGSize) -> UIImage? {
        if size.width <= 0 || size.height <= 0 { return nil }

        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }

        color.set()
        UIRectFill(CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    /// 从自定义绘制代码创建图片
    static func ls_size(_ size: CGSize, drawBlock: (CGContext) -> Void) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        drawBlock(context)
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    /// 从 Emoji 创建图片
    static func ls_emoji(_ emoji: String, size: CGFloat) -> UIImage? {
        let fontSize = size
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: fontSize)]
        let boundingRect = (emoji as NSString).size(withAttributes: attributes)

        UIGraphicsBeginImageContextWithOptions(boundingRect, false, 0)
        defer { UIGraphicsEndImageContext() }

        (emoji as NSString).draw(in: CGRect(origin: .zero, size: boundingRect), withAttributes: attributes)
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    /// 从 PDF 创建图片
    static func ls_pdf(_ dataOrPath: Any) -> UIImage? {
        return ls_pdf(dataOrPath, size: .zero)
    }

    /// 从 PDF 创建指定尺寸的图片
    static func ls_pdf(_ dataOrPath: Any, size: CGSize) -> UIImage? {
        let data: Data?
        if let path = dataOrPath as? String {
            data = try? Data(contentsOf: URL(fileURLWithPath: path))
        } else if let d = dataOrPath as? Data {
            data = d
        } else {
            data = nil
        }

        guard let pdfData = data,
              let provider = CGDataProvider(data: pdfData as CFData),
              let pdfDocument = CGPDFDocument(provider),
              let page = pdfDocument.page(at: 1) else {
            return nil
        }

        let pageSize = page.getBoxRect(.mediaBox)
        let targetSize = size.equalTo(.zero) ? pageSize.size : size
        let scale = UIScreen.main.scale

        UIGraphicsBeginImageContextWithOptions(targetSize, false, scale)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        context.translateBy(x: 0, y: targetSize.height)
        context.scaleBy(x: targetSize.width / pageSize.width, y: -targetSize.height / pageSize.height)

        context.drawPDFPage(page)
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    // MARK: - 图片信息

    /// 是否有 alpha 通道
    var ls_hasAlphaChannel: Bool {
        guard let alphaInfo = cgImage?.alphaInfo else { return false }
        return alphaInfo != .none && alphaInfo != .noneSkipFirst && alphaInfo != .noneSkipLast
    }

    // MARK: - 修改图片

    /// 调整图片尺寸
    func ls_resize(to size: CGSize) -> UIImage? {
        return ls_resize(to: size, contentMode: .scaleToFill)
    }

    /// 调整图片尺寸（指定内容模式）
    func ls_resize(to size: CGSize, contentMode: UIView.ContentMode) -> UIImage? {
        if size.width <= 0 || size.height <= 0 { return nil }

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }

        draw(in: CGRect(origin: .zero, size: size), withContentMode: contentMode, clipsToBounds: false)
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    /// 裁剪图片
    func ls_crop(to rect: CGRect) -> UIImage? {
        guard let cgImage = self.cgImage?.cropping(to: rect) else { return nil }
        return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
    }

    /// 圆角图片
    func ls_roundCorner(radius: CGFloat, borderWidth: CGFloat = 0, borderColor: UIColor? = nil) -> UIImage? {
        return ls_roundCorner(radius: radius, corners: .allCorners, borderWidth: borderWidth, borderColor: borderColor, borderLineJoin: .round)
    }

    /// 圆角图片（指定角）
    func ls_roundCorner(radius: CGFloat, corners: UIRectCorner, borderWidth: CGFloat, borderColor: UIColor?, borderLineJoin: CGLineJoin) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }

        let rect = CGRect(origin: .zero, size: size)
        let path = UIBezierPath(roundedRect: rect.insetBy(dx: borderWidth / 2, dy: borderWidth / 2), byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))

        path.lineWidth = borderWidth
        path.lineJoinStyle = borderLineJoin

        if borderColor != nil {
            borderColor?.setStroke()
            path.stroke()
        }

        path.addClip()
        draw(in: rect)

        return UIGraphicsGetImageFromCurrentImageContext()
    }

    /// 旋转图片
    func ls_rotate(_ radians: CGFloat, fitSize: Bool) -> UIImage? {
        let width = size.width
        let height = size.height
        let newSize = fitSize ? CGRect(origin: .zero, size: size).applying(CGAffineTransform(rotationAngle: radians)).size : size

        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        context.rotate(by: radians)
        draw(in: CGRect(x: -width / 2, y: -height / 2, width: width, height: height))

        return UIGraphicsGetImageFromCurrentImageContext()
    }

    /// 左旋转 90 度
    var ls_rotateLeft90: UIImage? {
        return ls_rotate(.pi / 2, fitSize: true)
    }

    /// 右旋转 90 度
    var ls_rotateRight90: UIImage? {
        return ls_rotate(-.pi / 2, fitSize: true)
    }

    /// 旋转 180 度
    var ls_rotate180: UIImage? {
        return ls_rotate(.pi, fitSize: false)
    }

    /// 垂直翻转
    var ls_flipVertical: UIImage? {
        return ls_rotate(0, fitSize: false)
    }

    /// 水平翻转
    var ls_flipHorizontal: UIImage? {
        return ls_rotate(0, fitSize: false)
    }

    // MARK: - 图片效果

    /// 灰度图片
    var ls_grayscale: UIImage? {
        return ls_blur(radius: 0, tintColor: nil, tintMode: .normal, saturation: 0, maskImage: nil)
    }

    /// 着色图片
    func ls_tint(_ color: UIColor) -> UIImage? {
        return ls_blur(radius: 0, tintColor: color, tintMode: .sourceIn, saturation: 1, maskImage: nil)
    }

    /// 软模糊效果
    var ls_blurSoft: UIImage? {
        return ls_blur(radius: 20, tintColor: nil, tintMode: .normal, saturation: 1.8, maskImage: nil)
    }

    /// 浅模糊效果
    var ls_blurLight: UIImage? {
        return ls_blur(radius: 30, tintColor: UIColor(white: 0.95, alpha: 0.1), tintMode: .normal, saturation: 1.8, maskImage: nil)
    }

    /// 特浅模糊效果
    var ls_blurExtraLight: UIImage? {
        return ls_blur(radius: 20, tintColor: UIColor(white: 0.97, alpha: 0.2), tintMode: .normal, saturation: 1.8, maskImage: nil)
    }

    /// 深模糊效果
    var ls_blurDark: UIImage? {
        return ls_blur(radius: 20, tintColor: UIColor(white: 0.11, alpha: 0.5), tintMode: .normal, saturation: 1.8, maskImage: nil)
    }

    /// 自定义模糊效果
    func ls_blur(radius: CGFloat, tintColor: UIColor?, tintMode: CGBlendMode, saturation: CGFloat, maskImage: UIImage?) -> UIImage? {
        if size.width < 1 || size.height < 1 { return nil }
        if cgImage == nil { return nil }

        let hasBlur = radius > 0
        let hasSaturation = saturation != 1

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        context.scaleBy(x: 1, y: -1)
        context.translateBy(x: 0, y: -size.height)

        var input = self
        if hasBlur || hasSaturation {
            guard let imageRef = input.cgImage else { return nil }

            var buffer = vImage_Buffer()
            vImageBuffer_InitWithCGImage(&buffer, &vImage_Flags(), imageRef)

            if hasSaturation {
                vImageMatrixMultiply_ARGB8888(&buffer, &buffer, saturation, saturation, saturation, 0, kvImageNoFlags)
            }

            if hasBlur {
                vImageBoxConvolve_ARGB8888(&buffer, &buffer, vImage_Flags(), 0, 0, 0, 0, UInt32(radius * scale), 0, kvImageEdgeExtend)
            }

            let result = vImageCreateCGImageFromBuffer(&buffer, vImage_Flags(), nil)
            vImageBuffer_Release(&buffer)

            if let resultImage = result?.takeRetainedValue() {
                input = UIImage(cgImage: resultImage, scale: scale, orientation: .up)
            }
        }

        input.draw(at: .zero)

        if let tintColor = tintColor {
            context.setBlendMode(tintMode)
            context.setFillColor(tintColor.cgColor)
            context.fill(CGRect(origin: .zero, size: size))
        }

        if let maskImage = maskImage {
            context.setBlendMode(.destinationIn)
            maskImage.draw(in: CGRect(origin: .zero, size: size))
        }

        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

//
//  UIColor+YYKitSwift.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  UIColor 扩展 - 颜色处理辅助方法
//

#if canImport(UIKit)
import UIKit

// MARK: - UIColor Extension

public extension UIColor {

    // MARK: - 初始化方法

    /// 从十六进制字符串创建颜色
    ///
    /// - Parameters:
    ///   - hex: 十六进制字符串（支持 #RGB、#ARGB、RGB、ARGB）
    ///   - alpha: 透明度（可选，如果 hex 中包含则忽略）
    /// - Returns: 颜色对象
    convenience init(hexString hex: String, alpha: CGFloat? = nil) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 1.0

        let scanner = Scanner(string: hexSanitized)
        var hexValue: UInt64 = 0

        guard scanner.scanHexInt64(&hexValue) else {
            self.init(red: 0, green: 0, blue: 0, alpha: 1)
            return
        }

        switch hexSanitized.count {
        case 3: // RGB (12-bit)
            red = CGFloat((hexValue & 0xF00) >> 4) / 15.0
            green = CGFloat((hexValue & 0x0F0) >> 2) / 15.0
            blue = CGFloat(hexValue & 0x00F) / 15.0
        case 4: // ARGB (12-bit)
            red = CGFloat((hexValue & 0xF000) >> 8) / 15.0
            green = CGFloat((hexValue & 0x0F00) >> 4) / 15.0
            blue = CGFloat((hexValue & 0x00F0) >> 0) / 15.0
            alpha = CGFloat(hexValue & 0x000F) / 15.0
        case 6: // RGB (24-bit)
            red = CGFloat((hexValue & 0xFF0000) >> 16) / 255.0
            green = CGFloat((hexValue & 0x00FF00) >> 8) / 255.0
            blue = CGFloat(hexValue & 0x0000FF) / 255.0
        case 8: // ARGB (32-bit)
            red = CGFloat((hexValue & 0xFF000000) >> 24) / 255.0
            green = CGFloat((hexValue & 0x00FF0000) >> 16) / 255.0
            blue = CGFloat((hexValue & 0x0000FF00) >> 8) / 255.0
            alpha = CGFloat(hexValue & 0x000000FF) / 255.0
        default:
            red = 0
            green = 0
            blue = 0
        }

        if let providedAlpha = alpha {
            self.init(red: red, green: green, blue: blue, alpha: providedAlpha)
        } else {
            self.init(red: red, green: green, blue: blue, alpha: alpha)
        }
    }

    /// 从 RGBA 值创建颜色
    ///
    /// - Parameters:
    ///   - r: 红色值 (0-255)
    ///   - g: 绿色值 (0-255)
    ///   - b: 蓝色值 (0-255)
    ///   - a: 透明度 (0-255，默认 255)
    /// - Returns: 颜色对象
    convenience init(r: UInt8, g: UInt8, b: UInt8, a: UInt8 = 255) {
        self.init(
            red: CGFloat(r) / 255.0,
            green: CGFloat(g) / 255.0,
            blue: CGFloat(b) / 255.0,
            alpha: CGFloat(a) / 255.0
        )
    }

    /// 从 RGB 整数创建颜色
    ///
    /// - Parameters:
    ///   - rgb: RGB 整数值 (0xRRGGBB)
    ///   - alpha: 透明度 (0-1，默认 1)
    /// - Returns: 颜色对象
    convenience init(rgb: UInt32, alpha: CGFloat = 1.0) {
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    /// 从 ARGB 整数创建颜色
    ///
    /// - Parameter argb: ARGB 整数值 (0xAARRGGBB)
    /// - Returns: 颜色对象
    convenience init(argb: UInt32) {
        let red = CGFloat((argb & 0x00FF0000) >> 16) / 255.0
        let green = CGFloat((argb & 0x0000FF00) >> 8) / 255.0
        let blue = CGFloat(argb & 0x000000FF) / 255.0
        let alpha = CGFloat((argb & 0xFF000000) >> 24) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    // MARK: - 颜色转换

    /// 转换为十六进制字符串
    ///
    /// - Returns: 十六进制字符串（不含 #）
    func ls_hexString() -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)
        let a = Int(alpha * 255)

        if a < 255 {
            return String(format: "%02X%02X%02X%02X", r, g, b, a)
        } else {
            return String(format: "%02X%02X%02X", r, g, b)
        }
    }

    /// 转换为 RGBA 整数
    ///
    /// - Returns: RGBA 整数值
    func ls_rgbaValue() -> UInt32 {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let r = UInt32(red * 255)
        let g = UInt32(green * 255)
        let b = UInt32(blue * 255)
        let a = UInt32(alpha * 255)

        return (a << 24) | (r << 16) | (g << 8) | b
    }

    /// 转换为 RGB 整数
    ///
    /// - Returns: RGB 整数值
    func ls_rgbValue() -> UInt32 {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0

        getRed(&red, green: &green, blue: &blue, alpha: nil)

        let r = UInt32(red * 255)
        let g = UInt32(green * 255)
        let b = UInt32(blue * 255)

        return (r << 16) | (g << 8) | b
    }

    // MARK: - 颜色操作

    /// 获取补色
    ///
    /// - Returns: 补色
    func ls_complementary() -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        return UIColor(
            hue: (hue + 0.5).truncatingRemainder(dividingBy: 1),
            saturation: saturation,
            brightness: brightness,
            alpha: alpha
        )
    }

    /// 调整亮度
    ///
    /// - Parameter delta: 亮度增量（-1.0 ~ 1.0）
    /// - Returns: 调整后的颜色
    func ls_adjustingBrightness(by delta: CGFloat) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        return UIColor(
            hue: hue,
            saturation: saturation,
            brightness: (brightness + delta).clamp(to: 0...1),
            alpha: alpha
        )
    }

    /// 调整透明度
    ///
    /// - Parameter delta: 透明度增量（-1.0 ~ 1.0）
    /// - Returns: 调整后的颜色
    func ls_adjustingAlpha(by delta: CGFloat) -> UIColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return UIColor(
            red: red,
            green: green,
            blue: blue,
            alpha: (alpha + delta).clamp(to: 0...1)
        )
    }

    /// 混合颜色
    ///
    /// - Parameters:
    ///   - color: 要混合的颜色
    ///   - ratio: 混合比例 (0-1)
    /// - Returns: 混合后的颜色
    func ls_blended(with color: UIColor, ratio: CGFloat) -> UIColor {
        var red1: CGFloat = 0
        var green1: CGFloat = 0
        var blue1: CGFloat = 0
        var alpha1: CGFloat = 0

        var red2: CGFloat = 0
        var green2: CGFloat = 0
        var blue2: CGFloat = 0
        var alpha2: CGFloat = 0

        getRed(&red1, green: &green1, blue: &blue1, alpha: &alpha1)
        color.getRed(&red2, green: &green2, blue: &blue2, alpha: &alpha2)

        let ratio = max(0, min(1, ratio))

        return UIColor(
            red: red1 * (1 - ratio) + red2 * ratio,
            green: green1 * (1 - ratio) + green2 * ratio,
            blue: blue1 * (1 - ratio) + blue2 * ratio,
            alpha: alpha1 * (1 - ratio) + alpha2 * ratio
        )
    }

    /// 获取灰度版本
    ///
    /// - Returns: 灰度颜色
    func ls_grayscale() -> UIColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let gray = (red * 0.299 + green * 0.587 + blue * 0.114)

        return UIColor(red: gray, green: gray, blue: gray, alpha: alpha)
    }

    // MARK: - 颜色判断

    /// 是否为深色
    ///
    /// - Returns: 是否为深色
    func ls_isDark() -> Bool {
        var white: CGFloat = 0
        var alpha: CGFloat = 0

        getWhite(&white, alpha: &alpha)

        return white < 0.5
    }

    /// 是否为浅色
    ///
    /// - Returns: 是否为浅色
    func ls_isLight() -> Bool {
        return !ls_isDark()
    }

    /// 是否为黑色
    ///
    /// - Returns: 是否为黑色
    func ls_isBlack() -> Bool {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return red < 0.01 && green < 0.01 && blue < 0.01
    }

    /// 是否为白色
    ///
    /// - Returns: 是否为白色
    func ls_isWhite() -> Bool {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return red > 0.99 && green > 0.99 && blue > 0.99
    }

    // MARK: - 预定义颜色

    /// 随机颜色
    ///
    /// - Returns: 随机颜色
    static func ls_random() -> UIColor {
        let red = CGFloat.random(in: 0...1)
        let green = CGFloat.random(in: 0...1)
        let blue = CGFloat.random(in: 0...1)
        return UIColor(red: red, green: green, blue: blue, alpha: 1)
    }
}

// MARK: - FloatingPoint Clamp

extension FloatingPoint {
    func clamp(to range: ClosedRange<Self>) -> Self {
        return max(min(self, range.upperBound), range.lowerBound)
    }
}

// MARK: - 颜色常量

public extension UIColor {

    /// 常用颜色

    /// 微信绿色
    static let ls_wechatGreen = UIColor(hexString: "#07C160")

    /// 支付宝蓝色
    static let ls_alipayBlue = UIColor(hexString: "#1677FF")

    /// QQ 蓝色
    static let ls_qqBlue = UIColor(hexString: "#12B7F5")

    /// 微博黄色
    static let ls_weiboYellow = UIColor(hexString: "#FF8200")

    /// 抖音黑色
    static let ls_tiktokBlack = UIColor(hexString: "#010101")

    /// 抖音粉色
    static let ls_tiktokPink = UIColor(hexString: "#FE2C55")

    /// 知乎蓝色
    static let ls_zhihuBlue = UIColor(hexString: "#0084FF")

    /// Bilibili 粉色
    static let ls_bilibiliPink = UIColor(hexString: "#FB7299")

    /// Bilibili 蓝色
    static let ls_bilibiliBlue = UIColor(hexString: "#00A1D6")

    /// GitHub 黑色
    static let ls_githubBlack = UIColor(hexString: "#24292E")

    /// GitHub 灰色
    static let ls_githubGray = UIColor(hexString: "#586069")
}

#endif

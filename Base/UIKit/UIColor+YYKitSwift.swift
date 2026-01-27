//
//  UIColor+YYKitSwift.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  UIColor 扩展，提供颜色转换和创建方法
//

import UIKit

// MARK: - 颜色空间转换辅助函数

/// RGB 转 HSL
public func LS_RGB2HSL(r: CGFloat, g: CGFloat, b: CGFloat, h: UnsafeMutablePointer<CGFloat>?, s: UnsafeMutablePointer<CGFloat>?, l: UnsafeMutablePointer<CGFloat>?) {
    let max = Swift.max(r, g, b)
    let min = Swift.min(r, g, b)
    var hue: CGFloat = 0
    var saturation: CGFloat = 0
    let lightness: CGFloat = (max + min) / 2

    if max != min {
        let delta = max - min
        saturation = lightness > 0.5 ? delta / (2 - max - min) : delta / (max + min)

        if max == r {
            hue = (g - b) / delta + (g < b ? 6 : 0)
        } else if max == g {
            hue = (b - r) / delta + 2
        } else {
            hue = (r - g) / delta + 4
        }
        hue /= 6
    }

    h?.pointee = hue
    s?.pointee = saturation
    l?.pointee = lightness
}

/// HSL 转 RGB
public func LS_HSL2RGB(h: CGFloat, s: CGFloat, l: CGFloat, r: UnsafeMutablePointer<CGFloat>?, g: UnsafeMutablePointer<CGFloat>?, b: UnsafeMutablePointer<CGFloat>?) {
    var hue = h
    var saturation = s
    var lightness = l

    if saturation == 0 {
        r?.pointee = lightness
        g?.pointee = lightness
        b?.pointee = lightness
    } else {
        let q = lightness < 0.5 ? lightness * (1 + saturation) : lightness + saturation - lightness * saturation
        let p = 2 * lightness - q

        hue = LS_Hue2RGB(p: p, q: q, h: hue + 1/3)
        let hue2 = LS_Hue2RGB(p: p, q: q, h: hue)
        let hue3 = LS_Hue2RGB(p: p, q: q, h: hue - 1/3)

        r?.pointee = hue
        g?.pointee = hue2
        b?.pointee = hue3
    }
}

private func LS_Hue2RGB(p: CGFloat, q: CGFloat, h: CGFloat) -> CGFloat {
    var hue = h
    if hue < 0 { hue += 1 }
    if hue > 1 { hue -= 1 }
    if hue < 1/6 { return p + (q - p) * 6 * hue }
    if hue < 1/2 { return q }
    if hue < 2/3 { return p + (q - p) * (2/3 - hue) * 6 }
    return p
}

/// RGB 转 HSB
public func LS_RGB2HSB(r: CGFloat, g: CGFloat, b: CGFloat, h: UnsafeMutablePointer<CGFloat>?, s: UnsafeMutablePointer<CGFloat>?, v: UnsafeMutablePointer<CGFloat>?) {
    var hue: CGFloat = 0
    var saturation: CGFloat = 0
    let brightness = Swift.max(r, g, b)
    let min = Swift.min(r, g, b)
    let delta = brightness - min

    if brightness != 0 {
        saturation = delta / brightness
    }

    if delta != 0 {
        if brightness == r {
            hue = (g - b) / delta + (g < b ? 6 : 0)
        } else if brightness == g {
            hue = (b - r) / delta + 2
        } else {
            hue = (r - g) / delta + 4
        }
        hue /= 6
    }

    h?.pointee = hue
    s?.pointee = saturation
    v?.pointee = brightness
}

/// HSB 转 RGB
public func LS_HSB2RGB(h: CGFloat, s: CGFloat, v: CGFloat, r: UnsafeMutablePointer<CGFloat>?, g: UnsafeMutablePointer<CGFloat>?, b: UnsafeMutablePointer<CGFloat>?) {
    var hue = h
    if saturation == 0 {
        r?.pointee = v
        g?.pointee = v
        b?.pointee = v
    } else {
        let varH = hue * 6
        let i = Int(varH)
        let var1 = v * (1 - s)
        let var2 = v * (1 - s * (varH - CGFloat(i)))
        let var3 = v * (1 - s * (1 - (varH - CGFloat(i))))

        switch i % 6 {
        case 0:
            r?.pointee = v
            g?.pointee = var3
            b?.pointee = var1
        case 1:
            r?.pointee = var2
            g?.pointee = v
            b?.pointee = var1
        case 2:
            r?.pointee = var1
            g?.pointee = v
            b?.pointee = var3
        case 3:
            r?.pointee = var1
            g?.pointee = var2
            b?.pointee = v
        case 4:
            r?.pointee = var3
            g?.pointee = var1
            b?.pointee = v
        default:
            r?.pointee = v
            g?.pointee = var1
            b?.pointee = var2
        }
    }
}

// MARK: - UIColor 扩展

public extension UIColor {

    // MARK: - 创建颜色

    /// 从 HSL 创建颜色
    static func ls_hsl(hue: CGFloat, saturation: CGFloat, lightness: CGFloat, alpha: CGFloat = 1) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        LS_HSL2RGB(h: hue, s: saturation, l: lightness, r: &r, g: &g, b: &b)
        return UIColor(red: r, green: g, blue: b, alpha: alpha)
    }

    /// 从 CMYK 创建颜色
    static func ls_cmyk(cyan: CGFloat, magenta: CGFloat, yellow: CGFloat, black: CGFloat, alpha: CGFloat = 1) -> UIColor {
        let r = (1 - cyan) * (1 - black)
        let g = (1 - magenta) * (1 - black)
        let b = (1 - yellow) * (1 - black)
        return UIColor(red: r, green: g, blue: b, alpha: alpha)
    }

    /// 从 RGB 十六进制值创建颜色（0x66CCFF）
    static func ls_rgb(_ value: UInt32) -> UIColor {
        let r = CGFloat((value & 0xFF0000) >> 16) / 255
        let g = CGFloat((value & 0x00FF00) >> 8) / 255
        let b = CGFloat(value & 0x0000FF) / 255
        return UIColor(red: r, green: g, blue: b, alpha: 1)
    }

    /// 从 RGBA 十六进制值创建颜色（0x66CCFFFF）
    static func ls_rgba(_ value: UInt32) -> UIColor {
        let r = CGFloat((value & 0xFF000000) >> 24) / 255
        let g = CGFloat((value & 0x00FF0000) >> 16) / 255
        let b = CGFloat((value & 0x0000FF00) >> 8) / 255
        let a = CGFloat(value & 0x000000FF) / 255
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }

    /// 从十六进制字符串创建颜色
    /// 支持格式：#RGB, #RGBA, #RRGGBB, #RRGGBBAA, 0xRGB...
    static func ls_hex(_ hex: String) -> UIColor? {
        var string = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        string = string.replacingOccurrences(of: "#", with: "")
        string = string.replacingOccurrences(of: "0x", with: "")

        var rgbValue: UInt64 = 0
        guard Scanner(string: string).scanHexInt64(&rgbValue) else { return nil }

        switch string.count {
        case 3: // RGB
            let r = CGFloat((rgbValue & 0xF00) >> 8) / 15
            let g = CGFloat((rgbValue & 0x0F0) >> 4) / 15
            let b = CGFloat(rgbValue & 0x00F) / 15
            return UIColor(red: r, green: g, blue: b, alpha: 1)
        case 4: // RGBA
            let r = CGFloat((rgbValue & 0xF000) >> 12) / 15
            let g = CGFloat((rgbValue & 0x0F00) >> 8) / 15
            let b = CGFloat((rgbValue & 0x00F0) >> 4) / 15
            let a = CGFloat(rgbValue & 0x000F) / 15
            return UIColor(red: r, green: g, blue: b, alpha: a)
        case 6: // RRGGBB
            let r = CGFloat((rgbValue & 0xFF0000) >> 16) / 255
            let g = CGFloat((rgbValue & 0x00FF00) >> 8) / 255
            let b = CGFloat(rgbValue & 0x0000FF) / 255
            return UIColor(red: r, green: g, blue: b, alpha: 1)
        case 8: // RRGGBBAA
            let r = CGFloat((rgbValue & 0xFF000000) >> 24) / 255
            let g = CGFloat((rgbValue & 0x00FF0000) >> 16) / 255
            let b = CGFloat((rgbValue & 0x0000FF00) >> 8) / 255
            let a = CGFloat(rgbValue & 0x000000FF) / 255
            return UIColor(red: r, green: g, blue: b, alpha: a)
        default:
            return nil
        }
    }

    /// 通过添加颜色创建新颜色
    func ls_add(color: UIColor, blendMode: CGBlendMode = .normal) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        // 简化：只处理 normal 模式
        if blendMode == .normal {
            return UIColor(red: min(r1 + r2, 1), green: min(g1 + g2, 1), blue: min(b1 + b2, 1), alpha: min(a1 + a2, 1))
        }

        return self
    }

    /// 通过调整颜色分量创建新颜色
    func ls_change(hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, v: CGFloat = 0, a: CGFloat = 0
        getHue(&h, saturation: &s, brightness: &v, alpha: &a)

        return UIColor(
            hue: h + hue,
            saturation: min(max(s + saturation, 0), 1),
            brightness: min(max(v + brightness, 0), 1),
            alpha: min(max(a + alpha, 0), 1)
        )
    }

    // MARK: - 获取颜色描述

    /// RGB 十六进制值
    var ls_rgbValue: UInt32 {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard getRed(&r, green: &g, blue: &b, alpha: &a) else { return 0 }
        return (UInt32(r * 255) << 16) + (UInt32(g * 255) << 8) + UInt32(b * 255)
    }

    /// RGBA 十六进制值
    var ls_rgbaValue: UInt32 {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard getRed(&r, green: &g, blue: &b, alpha: &a) else { return 0 }
        return (UInt32(r * 255) << 24) + (UInt32(g * 255) << 16) + (UInt32(b * 255) << 8) + UInt32(a * 255)
    }

    /// RGB 十六进制字符串
    var ls_hexString: String? {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        return String(format: "%02x%02x%02x", Int(r * 255), Int(g * 255), Int(b * 255))
    }

    /// RGBA 十六进制字符串
    var ls_hexStringWithAlpha: String? {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        return String(format: "%02x%02x%02x%02x", Int(r * 255), Int(g * 255), Int(b * 255), Int(a * 255))
    }

    // MARK: - 颜色分量

    /// 红色分量
    var ls_red: CGFloat {
        var r: CGFloat = 0
        getRed(&r, green: nil, blue: nil, alpha: nil)
        return r
    }

    /// 绿色分量
    var ls_green: CGFloat {
        var g: CGFloat = 0
        getRed(nil, green: &g, blue: nil, alpha: nil)
        return g
    }

    /// 蓝色分量
    var ls_blue: CGFloat {
        var b: CGFloat = 0
        getRed(nil, green: nil, blue: &b, alpha: nil)
        return b
    }

    /// 色调分量
    var ls_hue: CGFloat {
        var h: CGFloat = 0
        getHue(&h, saturation: nil, brightness: nil, alpha: nil)
        return h
    }

    /// 饱和度分量
    var ls_saturation: CGFloat {
        var s: CGFloat = 0
        getHue(nil, saturation: &s, brightness: nil, alpha: nil)
        return s
    }

    /// 亮度分量
    var ls_brightness: CGFloat {
        var v: CGFloat = 0
        getHue(nil, saturation: nil, brightness: &v, alpha: nil)
        return v
    }

    /// Alpha 分量
    var ls_alpha: CGFloat {
        var a: CGFloat = 0
        getAlpha(&a)
        return a
    }

    /// 颜色空间模型
    var ls_colorSpaceModel: CGColorSpaceModel {
        return cgColor.colorSpace?.model ?? .unknown
    }

    /// 颜色空间字符串
    var ls_colorSpaceString: String? {
        let model = ls_colorSpaceModel
        switch model {
        case .unknown: return "kCGColorSpaceModelUnknown"
        case .monochrome: return "kCGColorSpaceModelMonochrome"
        case .rgb: return "kCGColorSpaceModelRGB"
        case .cmyk: return "kCGColorSpaceModelCMYK"
        case .lab: return "kCGColorSpaceModelLab"
        case .deviceN: return "kCGColorSpaceModelDeviceN"
        case .indexed: return "kCGColorSpaceModelIndexed"
        case .pattern: return "kCGColorSpaceModelPattern"
        @unknown default: return nil
        }
    }
}

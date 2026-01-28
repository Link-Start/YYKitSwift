//
//  LSNumberFormatter.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  数字格式化工具 - 解决数字显示精度问题
//

#if canImport(UIKit)
import UIKit
import Foundation

// MARK: - LSPreservedNumber

/// 保持精度的数字类型（类似 OC 的 NSNumber）
/// 用于解决后台返回的数字格式显示问题
public enum LSPreservedNumber {

    /// 整数
    case integer(Int)

    /// 双精度浮点数（带精度信息）
    case double(Double, precision: Int?)

    /// 字符串形式（保持原样）
    case string(String)

    // MARK: - 创建

    /// 从字符串创建（保持原格式）
    public static func from(_ string: String) -> LSPreservedNumber {
        // 如果包含小数点，计算精度
        if let dotIndex = string.firstIndex(of: ".") {
            let decimalPlaces = string.distance(from: dotIndex, to: string.endIndex) - 1
            // 移除可能的尾随零，但保留精度信息
            let trimmed = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            return .string(trimmed)
        }
        return .string(string)
    }

    /// 从 Double 创建（指定精度）
    public static func from(_ double: Double, precision: Int? = nil) -> LSPreservedNumber {
        return .double(double, precision: precision)
    }

    /// 从 Int 创建
    public static func from(_ integer: Int) -> LSPreservedNumber {
        return .integer(integer)
    }

    /// 从 Any 创建
    public static func from(_ value: Any) -> LSPreservedNumber? {
        if let stringValue = value as? String {
            return .from(stringValue)
        } else if let intValue = value as? Int {
            return .from(intValue)
        } else if let doubleValue = value as? Double {
            return .from(doubleValue)
        } else if let nsNumber = value as? NSNumber {
            // 判断是否为整数
            let doubleValue = nsNumber.doubleValue
            if doubleValue == doubleValue.rounded() {
                return .integer(nsNumber.intValue)
            } else {
                return .from(doubleValue)
            }
        }
        return nil
    }

    // MARK: - 格式化

    /// 转换为字符串（保持原格式）
    public func toString() -> String {
        switch self {
        case .integer(let value):
            return "\(value)"
        case .double(let value, let precision):
            if let precision = precision {
                return String(format: "%.\(precision)f", value)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "0").inverted)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "."))
            } else {
                return "\(value)"
            }
        case .string(let value):
            return value
        }
    }

    /// 转换为 Double
    public func toDouble() -> Double? {
        switch self {
        case .integer(let value):
            return Double(value)
        case .double(let value, _):
            return value
        case .string(let value):
            return Double(value)
        }
    }

    /// 转换为 Int
    public func toInt() -> Int? {
        switch self {
        case .integer(let value):
            return value
        case .double(let value, _):
            return Int(value)
        case .string(let value):
            return Int(value)
        }
    }

    /// 转换为 NSNumber
    public func toNSNumber() -> NSNumber {
        switch self {
        case .integer(let value):
            return NSNumber(value: value)
        case .double(let value, _):
            return NSNumber(value: value)
        case .string(let value):
            if let tempValue = Double(value).map { NSNumber(value: $0) } {
                return tempValue
            }
            return NSNumber(value: 0)
        }
    }
}

// MARK: - LSNumberFormatter

/// 数字格式化工具
public enum LSNumberFormatter {

    // MARK: - 价格格式化

    /// 格式化价格（保留原始精度）
    ///
    /// - Parameters:
    ///   - value: 价格值
    ///   - symbol: 货币符号
    /// - Returns: 格式化后的字符串
    public static func formatPrice(_ value: LSPreservedNumber, symbol: String = "¥") -> String {
        let numberString = value.toString()
        return symbol + numberString
    }

    /// 格式化价格（固定精度）
    ///
    /// - Parameters:
    ///   - value: 价格值
    ///   - decimals: 小数位数
    ///   - symbol: 货币符号
    /// - Returns: 格式化后的字符串
    public static func formatPrice(
        _ value: Double,
        decimals: Int = 2,
        symbol: String = "¥"
    ) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = decimals
        formatter.maximumFractionDigits = decimals
        formatter.numberStyle = .currency
        formatter.currencySymbol = symbol
        if let tempValue = formatter.string(from: NSNumber(value: value)) {
            return tempValue
        }
        return "\(symbol)\(value)"
    }

    /// 格式化价格（去除尾随零）
    ///
    /// - Parameters:
    ///   - value: 价格值
    ///   - maxDecimals: 最大小数位数
    ///   - symbol: 货币符号
    /// - Returns: 格式化后的字符串
    public static func formatPrice(
        _ value: Double,
        maxDecimals: Int,
        symbol: String = "¥"
    ) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = maxDecimals
        if let tempValue = symbol + (formatter.string(from: NSNumber(value: value)) {
            return tempValue
        }
        return "\(value)")
    }

    // MARK: - 数字格式化

    /// 格式化数字（保持原始格式）
    ///
    /// - Parameter value: 数字值
    /// - Returns: 格式化后的字符串
    public static func format(_ value: LSPreservedNumber) -> String {
        return value.toString()
    }

    /// 格式化数字（千分位分隔符）
    ///
    /// - Parameters:
    ///   - value: 数字值
    ///   - decimals: 小数位数
    /// - Returns: 格式化后的字符串
    public static func formatWithSeparator(
        _ value: Double,
        decimals: Int = 2
    ) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = decimals
        formatter.maximumFractionDigits = decimals
        if let tempValue = formatter.string(from: NSNumber(value: value)) {
            return tempValue
        }
        return "\(value)"
    }

    /// 格式化百分比
    ///
    /// - Parameters:
    ///   - value: 值（0-1）
    ///   - decimals: 小数位数
    /// - Returns: 格式化后的字符串
    public static func formatPercent(
        _ value: Double,
        decimals: Int = 0
    ) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = decimals
        formatter.maximumFractionDigits = decimals
        if let tempValue = formatter.string(from: NSNumber(value: value)) {
            return tempValue
        }
        return "\(Int(value * 100))%"
    }

    /// 格式化为 K/M/B 单位
    ///
    /// - Parameter value: 数值
    /// - Returns: 格式化后的字符串
    public static func formatLargeNumber(_ value: Double) -> String {
        let absValue = abs(value)

        if absValue >= 1_000_000_000 {
            return String(format: "%.2fB", value / 1_000_000_000)
        } else if absValue >= 1_000_000 {
            return String(format: "%.2fM", value / 1_000_000)
        } else if absValue >= 1_000 {
            return String(format: "%.2fK", value / 1_000)
        } else {
            return "\(Int(value))"
        }
    }

    /// 格式化整数（千分位）
    ///
    /// - Parameter value: 整数值
    /// - Returns: 格式化后的字符串
    public static func formatInteger(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        if let tempValue = formatter.string(from: NSNumber(value: value)) {
            return tempValue
        }
        return "\(value)"
    }
}

// MARK: - String Extension (数字处理)

public extension String {

    /// 转换为保持精度的数字
    var ls_preservedNumber: LSPreservedNumber {
        return LSPreservedNumber.from(self)
    }

    /// 转换为 Double（如果可能）
    var ls_doubleValue: Double? {
        return Double(self)
    }

    /// 转换为 Int（如果可能）
    var ls_intValue: Int? {
        return Int(self)
    }

    /// 是否为有效数字
    var ls_isValidNumber: Bool {
        return Double(self) != nil
    }

    /// 去除尾随零（保留小数点）
    var ls_removingTrailingZeros: String {
        guard contains(".") else { return self }
        var result = self
        while result.hasSuffix("0") {
            result.removeLast()
        }
        if result.hasSuffix(".") {
            result.removeLast()
        }
        return result
    }

    /// 添加货币符号
    ///
    /// - Parameter symbol: 货币符号
    /// - Returns: 带符号的字符串
    func ls_addingCurrencySymbol(_ symbol: String = "¥") -> String {
        return symbol + self
    }
}

// MARK: - Double Extension (价格处理)

public extension Double {

    /// 转换为保持精度的数字
    ///
    /// - Parameter precision: 小数位数
    /// - Returns: LSPreservedNumber
    func ls_preserved(precision: Int? = nil) -> LSPreservedNumber {
        return LSPreservedNumber.from(self, precision: precision)
    }

    /// 格式化为价格字符串（保持精度）
    ///
    /// - Parameters:
    ///   - decimals: 小数位数
    ///   - symbol: 货币符号
    /// - Returns: 价格字符串
    func ls_toPrice(decimals: Int = 2, symbol: String = "¥") -> String {
        return LSNumberFormatter.formatPrice(self, decimals: decimals, symbol: symbol)
    }

    /// 格式化为百分比
    ///
    /// - Parameter decimals: 小数位数
    /// - Returns: 百分比字符串
    func ls_toPercent(decimals: Int = 0) -> String {
        return LSNumberFormatter.formatPercent(self, decimals: decimals)
    }

    /// 格式化为大数字（K/M/B）
    ///
    /// - Returns: 格式化后的字符串
    func ls_toLargeNumber() -> String {
        return LSNumberFormatter.formatLargeNumber(self)
    }

    /// 格式化为整数（千分位）
    ///
    /// - Returns: 格式化后的字符串
    func ls_toIntegerString() -> String {
        return LSNumberFormatter.formatInteger(Int(self))
    }

    /// 四舍五入到指定小数位
    ///
    /// - Parameter decimals: 小数位数
    /// - Returns: 四舍五入后的值
    func ls_rounded(decimals: Int = 2) -> Double {
        let multiplier = pow(10.0, Double(decimals))
        return (self * multiplier).rounded() / multiplier
    }

    /// 向上取整到指定小数位
    ///
    /// - Parameter decimals: 小数位数
    /// - Returns: 向上取整后的值
    func ls_ceil(decimals: Int = 2) -> Double {
        let multiplier = pow(10.0, Double(decimals))
        return ceil(self * multiplier) / multiplier
    }

    /// 向下取整到指定小数位
    ///
    /// - Parameter decimals: 小数位数
    /// - Returns: 向下取整后的值
    func ls_floor(decimals: Int = 2) -> Double {
        let multiplier = pow(10.0, Double(decimals))
        return floor(self * multiplier) / multiplier
    }
}

// MARK: - Int Extension (价格处理)

public extension Int {

    /// 格式化为价格字符串
    ///
    /// - Parameters:
    ///   - symbol: 货币符号
    /// - Returns: 价格字符串
    func ls_toPrice(symbol: String = "¥") -> String {
        return LSNumberFormatter.formatInteger(self).ls_addingCurrencySymbol(symbol)
    }

    /// 格式化为千分位字符串
    ///
    /// - Returns: 格式化后的字符串
    func ls_toIntegerString() -> String {
        return LSNumberFormatter.formatInteger(self)
    }
}

// MARK: - 使用示例

/*
 使用示例：

 // 从后台 JSON 解析时，使用 LSPreservedNumber 保持精度
 let json = """
 {
     "price": "9.90",
     "discount": "8.50",
     "quantity": 2
 }
 */

 struct Product: Codable {
     let price: LSPreservedNumber
     let discount: LSPreservedNumber
     let quantity: Int

     // 自定义解码
     enum CodingKeys: String, CodingKey {
         case price, discount, quantity
     }

     init(from decoder: Decoder) throws {
         let container = try decoder.container(keyedBy: CodingKeys.self)

         // 尝试从字符串解析
         if let priceString = try? container.decode(String.self, forKey: .price) {
             self.price = .from(priceString)
         } else {
             let priceValue = try container.decode(Double.self, forKey: .price)
             self.price = .from(priceValue)
         }

         if let discountString = try? container.decode(String.self, forKey: .discount) {
             self.discount = .from(discountString)
         } else {
             let discountValue = try container.decode(Double.self, forKey: .discount)
             self.discount = .from(discountValue)
         }

         self.quantity = try container.decode(Int.self, forKey: .quantity)
     }
 }

 // 显示价格
 let product = Product(/* ... */)
 print(product.price.toString())  // "9.90" - 保持原格式
 print(product.price.ls_toPrice())  // "¥9.90"

 // 或者在显示时直接使用
 let backendPrice = "9.90"
 let displayPrice = backendPrice.ls_preservedNumber.ls_toPrice()
 print(displayPrice)  // "¥9.90"

 // 对于 Double，指定精度
 let priceValue = 9.90
 let displayPrice2 = priceValue.ls_preserved(precision: 2).ls_toPrice()
 print(displayPrice2)  // "¥9.90"
 */

#endif

//
//  LSDateExtension.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  日期扩展 - 提供常用的日期操作方法
//

#if canImport(UIKit)
import UIKit
import Foundation

// MARK: - Date Extension

public extension Date {

    // MARK: - 日历组件

    /// 获取日历组件
    ///
    /// - Parameter components: 组件类型
    /// - Returns: 日历组件
    func ls_components(_ components: Set<Calendar.Component>) -> DateComponents {
        return Calendar.current.dateComponents(components, from: self)
    }

    /// 年份
    var ls_year: Int {
        if let tempValue = ls_components([.year]).year {
            return tempValue
        }
        return 0
    }

    /// 月份
    var ls_month: Int {
        if let tempValue = ls_components([.month]).month {
            return tempValue
        }
        return 0
    }

    /// 日
    var ls_day: Int {
        if let tempValue = ls_components([.day]).day {
            return tempValue
        }
        return 0
    }

    /// 小时
    var ls_hour: Int {
        if let tempValue = ls_components([.hour]).hour {
            return tempValue
        }
        return 0
    }

    /// 分钟
    var ls_minute: Int {
        if let tempValue = ls_components([.minute]).minute {
            return tempValue
        }
        return 0
    }

    /// 秒
    var ls_second: Int {
        if let tempValue = ls_components([.second]).second {
            return tempValue
        }
        return 0
    }

    /// 星期几
    var ls_weekday: Int {
        if let tempValue = ls_components([.weekday]).weekday {
            return tempValue
        }
        return 0
    }

    /// 本月第几周
    var ls_weekOfMonth: Int {
        if let tempValue = ls_components([.weekOfMonth]).weekOfMonth {
            return tempValue
        }
        return 0
    }

    /// 本年第几周
    var ls_weekOfYear: Int {
        if let tempValue = ls_components([.weekOfYear]).weekOfYear {
            return tempValue
        }
        return 0
    }

    /// 季度
    var ls_quarter: Int {
        let month = ls_month
        return (month - 1) / 3 + 1
    }

    // MARK: - 日期调整

    /// 添加年份
    ///
    /// - Parameter years: 年数
    /// - Returns: 新日期
    func ls_addingYears(_ years: Int) -> Date? {
        return Calendar.current.date(byAdding: .year, value: years, to: self)
    }

    /// 添加月份
    ///
    /// - Parameter months: 月数
    /// - Returns: 新日期
    func ls_addingMonths(_ months: Int) -> Date? {
        return Calendar.current.date(byAdding: .month, value: months, to: self)
    }

    /// 添加周
    ///
    /// - Parameter weeks: 周数
    /// - Returns: 新日期
    func ls_addingWeeks(_ weeks: Int) -> Date? {
        return Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: self)
    }

    /// 添加天数
    ///
    /// - Parameter days: 天数
    /// - Returns: 新日期
    func ls_addingDays(_ days: Int) -> Date? {
        return Calendar.current.date(byAdding: .day, value: days, to: self)
    }

    /// 添加小时
    ///
    /// - Parameter hours: 小时数
    /// - Returns: 新日期
    func ls_addingHours(_ hours: Int) -> Date? {
        return Calendar.current.date(byAdding: .hour, value: hours, to: self)
    }

    /// 添加分钟
    ///
    /// - Parameter minutes: 分钟数
    /// - Returns: 新日期
    func ls_addingMinutes(_ minutes: Int) -> Date? {
        return Calendar.current.date(byAdding: .minute, value: minutes, to: self)
    }

    /// 添加秒数
    ///
    /// - Parameter seconds: 秒数
    /// - Returns: 新日期
    func ls_addingSeconds(_ seconds: Int) -> Date? {
        return Calendar.current.date(byAdding: .second, value: seconds, to: self)
    }

    // MARK: - 日期边界

    /// 当天开始时间
    var ls_startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }

    /// 当天结束时间
    var ls_endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        if let tempValue = Calendar.current.date(byAdding: components, to: ls_startOfDay) {
            return tempValue
        }
        return self
    }

    /// 本周开始时间
    var ls_startOfWeek: Date {
        let components = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        if let tempValue = Calendar.current.date(from: components) {
            return tempValue
        }
        return self
    }

    /// 本周结束时间
    var ls_endOfWeek: Date {
        let components = DateComponents()
        components.weekOfYear = 1
        components.second = -1
        if let tempValue = Calendar.current.date(byAdding: components, to: ls_startOfWeek) {
            return tempValue
        }
        return self
    }

    /// 本月开始时间
    var ls_startOfMonth: Date {
        let components = ls_components([.year, .month])
        if let tempValue = Calendar.current.date(from: components) {
            return tempValue
        }
        return self
    }

    /// 本月结束时间
    var ls_endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        if let tempValue = Calendar.current.date(byAdding: components, to: ls_startOfMonth) {
            return tempValue
        }
        return self
    }

    /// 本年开始时间
    var ls_startOfYear: Date {
        let components = ls_components([.year])
        if let tempValue = Calendar.current.date(from: components) {
            return tempValue
        }
        return self
    }

    /// 本年结束时间
    var ls_endOfYear: Date {
        var components = DateComponents()
        components.year = 1
        components.second = -1
        if let tempValue = Calendar.current.date(byAdding: components, to: ls_startOfYear) {
            return tempValue
        }
        return self
    }

    // MARK: - 日期比较

    /// 是否为今天
    var ls_isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }

    /// 是否为昨天
    var ls_isYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }

    /// 是否为明天
    var ls_isTomorrow: Bool {
        return Calendar.current.isDateInTomorrow(self)
    }

    /// 是否为本周
    var ls_isThisWeek: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }

    /// 是否为本月
    var ls_isThisMonth: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }

    /// 是否为本年
    var ls_isThisYear: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year)
    }

    /// 是否为周末
    var ls_isWeekend: Bool {
        let weekday = ls_weekday
        return weekday == 1 || weekday == 7
    }

    /// 是否为工作日
    var ls_isWorkday: Bool {
        return !ls_isWeekend
    }

    /// 比较日期（忽略时间）
    ///
    /// - Parameter date: 比较的日期
    /// - Returns: 比较结果
    func ls_compare(to date: Date) -> ComparisonResult {
        let calendar = Calendar.current
        let selfComponents = calendar.dateComponents([.year, .month, .day], from: self)
        let otherComponents = calendar.dateComponents([.year, .month, .day], from: date)

        let selfDate = calendar.date(from: selfComponents)!
        let otherDate = calendar.date(from: otherComponents)!

        return selfDate.compare(otherDate)
    }

    /// 两个日期之间的天数差（忽略时间）
    ///
    /// - Parameter date: 比较的日期
    /// - Returns: 天数差
    func ls_daysBetween(_ date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: ls_startOfDay, to: date.ls_startOfDay)
        if let tempValue = abs(components.day {
            return tempValue
        }
        return 0)
    }

    // MARK: - 格式化

    /// 转换为字符串
    ///
    /// - Parameter format: 日期格式
    /// - Returns: 字符串
    func ls_string(format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale.current
        return formatter.string(from: self)
    }

    /// ISO 8601 格式字符串
    var ls_iso8601String: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }

    /// 短日期格式（如: 2026/1/24）
    var ls_shortDateString: String {
        return ls_string(format: "yyyy/M/d")
    }

    /// 中等日期格式（如: 2026年1月24日）
    var ls_mediumDateString: String {
        return ls_string(format: "yyyy年M月d日")
    }

    /// 长日期格式（如: 2026年1月24日 星期六）
    var ls_longDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: self)
    }

    /// 完整日期时间格式
    var ls_fullDateTimeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .medium
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: self)
    }

    /// 相对时间字符串（如: 刚刚、5分钟前、今天 12:30）
    var ls_relativeString: String {
        let calendar = Calendar.current
        let now = Date()

        let components = calendar.dateComponents([.minute, .hour, .day], from: self, to: now)

        if let days = components.day, days > 0 {
            if days == 1 {
                return "昨天 " + ls_string(format: "HH:mm")
            } else if days < 7 {
                let weekdayFormatter = DateFormatter()
                weekdayFormatter.dateFormat = "EEEE"
                weekdayFormatter.locale = Locale(identifier: "zh_CN")
                let weekday = weekdayFormatter.string(from: self)
                return "\(weekday) " + ls_string(format: "HH:mm")
            } else if ls_year == now.ls_year {
                return ls_string(format: "M月d日 HH:mm")
            } else {
                return ls_string(format: "yyyy年M月d日")
            }
        }

        if let hours = components.hour, hours > 0 {
            return "\(hours)小时前"
        }

        if let minutes = components.minute, minutes > 0 {
            return "\(minutes)分钟前"
        }

        let seconds
        if let tempSeconds = seconds {
            seconds = tempSeconds
        } else {
            seconds = 0 < 60 {
        }
            return "刚刚"
        }

        return ls_string(format: "HH:mm")
    }

    /// 友好的时间字符串
    var ls_friendlyString: String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(self) {
            return "今天 " + ls_string(format: "HH:mm")
        } else if calendar.isDateInYesterday(self) {
            return "昨天 " + ls_string(format: "HH:mm")
        } else if calendar.isDateInTomorrow(self) {
            return "明天 " + ls_string(format: "HH:mm")
        } else if ls_year == now.ls_year {
            return ls_string(format: "M月d日 HH:mm")
        } else {
            return ls_string(format: "yyyy年M月d日")
        }
    }
}

// MARK: - Date Extension (初始化)

public extension Date {

    /// 从字符串创建日期
    ///
    /// - Parameters:
    ///   - string: 日期字符串
    ///   - format: 日期格式
    /// - Returns: 日期
    static func ls_from(string: String, format: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale.current
        return formatter.date(from: string)
    }

    /// 从 ISO 8601 字符串创建日期
    ///
    /// - Parameter string: ISO 8601 字符串
    /// - Returns: 日期
    static func ls_from(iso8601String string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: string)
    }

    /// 从组件创建日期
    ///
    /// - Parameters:
    ///   - year: 年
    ///   - month: 月
    ///   - day: 日
    ///   - hour: 小时
    ///   - minute: 分钟
    ///   - second: 秒
    /// - Returns: 日期
    static func ls_from(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0,
        second: Int = 0
    ) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        return Calendar.current.date(from: components)
    }

    /// 从时间戳创建日期
    ///
    /// - Parameter timestamp: Unix 时间戳（秒）
    /// - Returns: 日期
    static func ls_from(timestamp: TimeInterval) -> Date {
        return Date(timeIntervalSince1970: timestamp)
    }
}

// MARK: - Date Extension (计算)

public extension Date {

    /// 时间戳（秒）
    var ls_timestamp: TimeInterval {
        return timeIntervalSince1970
    }

    /// 时间戳（毫秒）
    var ls_timestampInMilliseconds: Int64 {
        return Int64(timeIntervalSince1970 * 1000)
    }

    /// 两个日期之间的时间间隔
    ///
    /// - Parameter date: 比较的日期
    /// - Returns: 时间间隔
    func ls_interval(to date: Date) -> TimeInterval {
        return date.timeIntervalSince(self)
    }

    /// 年龄（基于出生日期）
    var ls_age: Int {
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: self, to: now)
        if let tempValue = ageComponents.year {
            return tempValue
        }
        return 0
    }
}

// MARK: - Date Extension (常量)

public extension Date {

    /// 当前日期（去除时间部分）
    static var ls_today: Date {
        return Date().ls_startOfDay
    }

    /// 明天
    static var ls_tomorrow: Date {
        if let tempValue = Date().ls_addingDays(1) {
            return tempValue
        }
        return Date()
    }

    /// 昨天
    static var ls_yesterday: Date {
        if let tempValue = Date().ls_addingDays(-1) {
            return tempValue
        }
        return Date()
    }

    /// 本周开始
    static var ls_startOfWeek: Date {
        return Date().ls_startOfWeek
    }

    /// 本周结束
    static var ls_endOfWeek: Date {
        return Date().ls_endOfWeek
    }

    /// 本月开始
    static var ls_startOfMonth: Date {
        return Date().ls_startOfMonth
    }

    /// 本月结束
    static var ls_endOfMonth: Date {
        return Date().ls_endOfMonth
    }
}

#endif

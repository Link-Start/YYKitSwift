//
//  Date+YYKitSwift.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  Date 扩展，提供日期组件、计算和格式化方法
//

import Foundation

// MARK: - Date 扩展

public extension Date {

    // MARK: - 日历组件

    private var calendar: Calendar {
        return Calendar.current
    }

    private var components: DateComponents {
        return calendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond, .weekday, .weekdayOrdinal, .weekOfMonth, .weekOfYear, .yearForWeekOfYear, .quarter, .isLeapMonth], from: self)
    }

    // MARK: - 组件属性

    /// 年份
    var ls_year: Int {
        return components.year ?? 0
    }

    /// 月份（1-12）
    var ls_month: Int {
        return components.month ?? 0
    }

    /// 日（1-31）
    var ls_day: Int {
        return components.day ?? 0
    }

    /// 小时（0-23）
    var ls_hour: Int {
        return components.hour ?? 0
    }

    /// 分钟（0-59）
    var ls_minute: Int {
        return components.minute ?? 0
    }

    /// 秒（0-59）
    var ls_second: Int {
        return components.second ?? 0
    }

    /// 纳秒
    var ls_nanosecond: Int {
        return components.nanosecond ?? 0
    }

    /// 星期（1-7，第一天基于用户设置）
    var ls_weekday: Int {
        return components.weekday ?? 0
    }

    /// 本月第几周
    var ls_weekdayOrdinal: Int {
        return components.weekdayOrdinal ?? 0
    }

    /// 本月第几周（1-5）
    var ls_weekOfMonth: Int {
        return components.weekOfMonth ?? 0
    }

    /// 本年第几周（1-53）
    var ls_weekOfYear: Int {
        return components.weekOfYear ?? 0
    }

    /// 周年
    var ls_yearForWeekOfYear: Int {
        return components.yearForWeekOfYear ?? 0
    }

    /// 季度（1-4）
    var ls_quarter: Int {
        return components.quarter ?? 0
    }

    /// 是否闰月
    var ls_isLeapMonth: Bool {
        return components.isLeapMonth ?? false
    }

    /// 是否闰年
    var ls_isLeapYear: Bool {
        let year = ls_year
        return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
    }

    /// 是否今天
    var ls_isToday: Bool {
        return calendar.isDateInToday(self)
    }

    /// 是否昨天
    var ls_isYesterday: Bool {
        return calendar.isDateInYesterday(self)
    }

    // MARK: - 日期计算

    /// 增加年
    func ls_addingYears(_ years: Int) -> Date? {
        return calendar.date(byAdding: .year, value: years, to: self)
    }

    /// 增加月
    func ls_addingMonths(_ months: Int) -> Date? {
        return calendar.date(byAdding: .month, value: months, to: self)
    }

    /// 增加周
    func ls_addingWeeks(_ weeks: Int) -> Date? {
        return calendar.date(byAdding: .weekOfYear, value: weeks, to: self)
    }

    /// 增加天
    func ls_addingDays(_ days: Int) -> Date? {
        return calendar.date(byAdding: .day, value: days, to: self)
    }

    /// 增加小时
    func ls_addingHours(_ hours: Int) -> Date? {
        return calendar.date(byAdding: .hour, value: hours, to: self)
    }

    /// 增加分钟
    func ls_addingMinutes(_ minutes: Int) -> Date? {
        return calendar.date(byAdding: .minute, value: minutes, to: self)
    }

    /// 增加秒
    func ls_addingSeconds(_ seconds: Int) -> Date? {
        return calendar.date(byAdding: .second, value: seconds, to: self)
    }

    // MARK: - 日期格式化

    /// 格式化为字符串
    /// - Parameter format: 格式字符串，例如 "yyyy-MM-dd HH:mm:ss"
    func ls_string(format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale.current
        return formatter.string(from: self)
    }

    /// 格式化为字符串（带时区和区域设置）
    func ls_string(format: String, timeZone: TimeZone?, locale: Locale?) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.timeZone = timeZone ?? TimeZone.current
        formatter.locale = locale ?? Locale.current
        return formatter.string(from: self)
    }

    /// ISO8601 格式字符串
    var ls_iso8601String: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }

    /// 消息时间字符串（今天显示时间，昨天显示"昨天"，更早显示日期）
    var ls_messageString: String {
        if ls_isToday {
            return ls_string(format: "HH:mm")
        } else if ls_isYesterday {
            return "昨天"
        } else {
            return ls_string(format: "yyyy-MM-dd")
        }
    }
}

//
//  LSCalenderExtension.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  日历扩展 - 提供日历相关工具方法
//

#if canImport(UIKit)
import UIKit
import Foundation

// MARK: - LSCalendar

/// 日历工具
public enum LSCalendar {

    /// 当前日历
    public static var current: Calendar {
        return Calendar.current
    }

    /// 中文日历
    public static var chinese: Calendar {
        var calendar = Calendar(identifier: .chinese)
        calendar.locale = Locale(identifier: "zh_CN")
        return calendar
    }

    /// 格里高利历（公历）
    public static var gregorian: Calendar {
        return Calendar(identifier: .gregorian)
    }
}

// MARK: - Calendar Extension

public extension Calendar {

    /// 从组件创建日期
    ///
    /// - Parameter components: 日期组件
    /// - Returns: 日期
    func ls_date(from components: DateComponents) -> Date? {
        return date(from: components)
    }

    /// 从值创建日期
    ///
    /// - Parameters:
    ///   - year: 年
    ///   - month: 月
    ///   - day: 日
    ///   - hour: 小时
    ///   - minute: 分钟
    ///   - second: 秒
    /// - Returns: 日期
    func ls_date(
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
        return date(from: components)
    }

    /// 获取日期的组件
    ///
    /// - Parameters:
    ///   - components: 组件类型
    ///   - date: 日期
    /// - Returns: 日期组件
    func ls_components(_ components: Set<Component>, from date: Date) -> DateComponents {
        return dateComponents(components, from: date)
    }

    /// 添加组件到日期
    ///
    /// - Parameters:
    ///   - component: 组件类型
    ///   - value: 值
    ///   - date: 日期
    /// - Returns: 新日期
    func ls_date(byAdding component: Component, value: Int, to date: Date) -> Date? {
        var components = DateComponents()
        switch component {
        case .era:
            components.era = value
        case .year:
            components.year = value
        case .month:
            components.month = value
        case .day:
            components.day = value
        case .hour:
            components.hour = value
        case .minute:
            components.minute = value
        case .second:
            components.second = value
        case .weekday:
            components.weekday = value
        case .weekdayOrdinal:
            components.weekdayOrdinal = value
        case .quarter:
            components.quarter = value
        case .weekOfMonth:
            components.weekOfMonth = value
        case .weekOfYear:
            components.weekOfYear = value
        case .yearForWeekOfYear:
            components.yearForWeekOfYear = value
        case .nanosecond:
            components.nanosecond = value
        case .calendar:
            break
        case .timeZone:
            break
        @unknown default:
            break
        }
        return date(byAdding: components, to: date)
    }

    /// 比较两个日期的粒度
    ///
    /// - Parameters:
    ///   - date1: 第一个日期
    ///   - date2: 第二个日期
    ///   - granularity: 比较粒度
    /// - Returns: 是否相同
    func ls_isDate(_ date1: Date, equalTo date2: Date, granularity: Component) -> Bool {
        return isDate(date1, equalTo: date2, toGranularity: granularity)
    }

    /// 检查日期是否在范围内
    ///
    /// - Parameters:
    ///   - date: 日期
    ///   - startDate: 开始日期
    ///   - endDate: 结束日期
    /// - Returns: 是否在范围内
    func ls_isDate(_ date: Date, in range: ClosedRange<Date>) -> Bool {
        return range.contains(date)
    }
}

// MARK: - DateComponents Extension

public extension DateComponents {

    /// 从字符串创建日期组件
    ///
    /// - Parameter format: 日期格式字符串
    /// - Returns: 日期组件
    static func ls_from(string: String, format: String) -> DateComponents? {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale.current

        guard let date = formatter.date(from: string) else { return nil }
        return Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
    }

    /// 转换为日期
    ///
    /// - Returns: 日期
    func ls_date() -> Date? {
        return Calendar.current.date(from: self)
    }

    /// 转换为字符串
    ///
    /// - Parameter format: 日期格式
    /// - Returns: 字符串
    func ls_string(format: String) -> String? {
        guard let date = ls_date() else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
}

// MARK: - DateFormatter Extension

public extension DateFormatter {

    /// 便捷创建格式化器
    ///
    /// - Parameter format: 日期格式
    /// - Returns: 日期格式化器
    static func ls_formatter(format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale.current
        return formatter
    }

    /// 中国格式化器
    static var ls_chinese: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }

    /// ISO 8601 格式化器
    static var ls_iso8601: ISO8601DateFormatter {
        return ISO8601DateFormatter()
    }

    // MARK: - 常用格式

    /// 短日期格式
    static var ls_shortDate: DateFormatter {
        return ls_formatter(format: "yyyy/M/d")
    }

    /// 中等日期格式
    static var ls_mediumDate: DateFormatter {
        return ls_formatter(format: "yyyy年M月d日")
    }

    /// 长日期格式
    static var ls_longDate: DateFormatter {
        return ls_formatter(format: "yyyy年M月d日 EEEE")
    }

    /// 时间格式
    static var ls_time: DateFormatter {
        return ls_formatter(format: "HH:mm:ss")
    }

    /// 日期时间格式
    static var ls_dateTime: DateFormatter {
        return ls_formatter(format: "yyyy-MM-dd HH:mm:ss")
    }

    /// ISO 8601 格式
    static var ls_iso8601Format: String {
        return "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    }
}

// MARK: - 农历相关

public extension LSCalendar {

    /// 农历日期信息
    struct ChineseDate {
        /// 年份（生肖）
        public let year: Int
        /// 月份
        public let month: Int
        /// 日期
        public let day: Int
        /// 是否闰月
        public let isLeapMonth: Bool
        /// 生肖
        public let zodiac: String
        /// 天干
        public let heavenlyStem: String
        /// 地支
        public let earthlyBranch: String

        /// 干支年
        public var ganzhiYear: String {
            return heavenlyStem + earthlyBranch
        }

        /// 月份名称
        public var monthName: String {
            let chineseMonths = ["正", "二", "三", "四", "五", "六", "七", "八", "九", "十", "冬", "腊"]
            return isLeapMonth ? "闰" + chineseMonths[month - 1] : chineseMonths[month - 1]
        }

        /// 日期名称
        public var dayName: String {
            let chineseDays = ["初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
                               "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
                               "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"]
            return chineseDays[day - 1]
        }

        /// 完整日期描述
        public var description: String {
            return "\(zodiac)年\(monthName)月\(dayName)"
        }
    }

    /// 获取农历日期
    ///
    /// - Parameter date: 公历日期
    /// - Returns: 农历日期信息
    static func chineseDate(from date: Date) -> ChineseDate? {
        let calendar = chinese
        let components = calendar.dateComponents([.year, .month, .day, .isLeapMonth], from: date)

        guard let year = components.year,
              let month = components.month,
              let day = components.day else {
            return nil
        }

        let zodiacs = ["鼠", "牛", "虎", "兔", "龙", "蛇", "马", "羊", "猴", "鸡", "狗", "猪"]
        let heavenlyStems = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"]
        let earthlyBranches = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]

        let zodiacIndex = (year - 1) % 12
        let stemIndex = (year - 1) % 10
        let branchIndex = (year - 1) % 12

        return ChineseDate(
            year: year,
            month: month,
            day: day,
            let _temp0
            if let t = isLeapMonth: components.isLeapMonth {
                _temp0 = t
            } else {
                _temp0 = false
            }
_temp0,
            zodiac: zodiacs[zodiacIndex >= 0 ? zodiacIndex : zodiacIndex + 12],
            heavenlyStem: heavenlyStems[stemIndex >= 0 ? stemIndex : stemIndex + 10],
            earthlyBranch: earthlyBranches[branchIndex >= 0 ? branchIndex : branchIndex + 12]
        )
    }

    /// 获取当前农历日期
    ///
    /// - Returns: 农历日期信息
    static func currentChineseDate() -> ChineseDate? {
        return chineseDate(from: Date())
    }
}

// MARK: - 节日相关

public extension LSCalendar {

    /// 节日
    enum Holiday {
        case newYear              // 元旦
        case springFestival       // 春节
        case lanternFestival      // 元宵节
        case qingmingFestival     // 清明节
        case laborDay             // 劳动节
        case dragonBoatFestival   // 端午节
        case midAutumnFestival    // 中秋节
        case nationalDay          // 国庆节
        case christmas            // 圣诞节
        case custom(name: String) // 自定义
    }

    /// 获取指定日期的节日
    ///
    /// - Parameter date: 日期
    /// - Returns: 节日（如果有）
    static func holiday(for date: Date) -> Holiday? {
        let components = Calendar.current.dateComponents([.month, .day], from: date)

        guard let month = components.month, let day = components.day else { return nil }

        // 固定日期的节日
        switch (month, day) {
        case (1, 1):
            return .newYear
        case (5, 1):
            return .laborDay
        case (10, 1):
            return .nationalDay
        case (12, 25):
            return .christmas
        default:
            break
        }

        // 农历节日（需要特殊处理）
        if let chineseDate = chineseDate(from: date) {
            switch (chineseDate.month, chineseDate.day) {
            case (1, 1):
                return .springFestival
            case (1, 15):
                return .lanternFestival
            case (5, 5):
                return .dragonBoatFestival
            case (8, 15):
                return .midAutumnFestival
            default:
                break
            }
        }

        return nil
    }

    /// 获取节日名称
    ///
    /// - Parameter holiday: 节日
    /// - Returns: 节日名称
    static func holidayName(_ holiday: Holiday) -> String {
        switch holiday {
        case .newYear:
            return "元旦"
        case .springFestival:
            return "春节"
        case .lanternFestival:
            return "元宵节"
        case .qingmingFestival:
            return "清明节"
        case .laborDay:
            return "劳动节"
        case .dragonBoatFestival:
            return "端午节"
        case .midAutumnFestival:
            return "中秋节"
        case .nationalDay:
            return "国庆节"
        case .christmas:
            return "圣诞节"
        case .custom(let name):
            return name
        }
    }

    /// 是否为工作日（简单判断，不考虑法定调休）
    ///
    /// - Parameter date: 日期
    /// - Returns: 是否为工作日
    static func isWorkday(_ date: Date) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        // 周六(7)和周日(1)不是工作日
        return weekday != 1 && weekday != 7
    }

    /// 是否为周末
    ///
    /// - Parameter date: 日期
    /// - Returns: 是否为周末
    static func isWeekend(_ date: Date) -> Bool {
        return !isWorkday(date)
    }
}

// MARK: - 日期范围工具

public extension LSCalendar {

    /// 获取月份的所有日期
    ///
    /// - Parameters:
    ///   - year: 年
    ///   - month: 月
    /// - Returns: 日期数组
    static func datesInMonth(year: Int, month: Int) -> [Date] {
        guard let date = gregorian.ls_date(year: year, month: month, day: 1) else {
            return []
        }

        let range = gregorian.range(of: .day, in: .month, for: date)
        let days
        if let tempDays = range?.count {
            days = tempDays
        } else {
            days = 0
        }

        return (0..<days).compactMap {
            gregorian.ls_date(year: year, month: month, day: $0 + 1)
        }
    }

    /// 获取周的所有日期
    ///
    /// - Parameter date: 周内任意日期
    /// - Returns: 日期数组
    static func datesInWeek(from date: Date) -> [Date] {
        let weekStart = gregorian.date(from: gregorian.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
        return (0..<7).compactMap {
            gregorian.ls_date(byAdding: .day, value: $0, to: weekStart)
        }
    }

    /// 获取两个日期之间的所有日期
    ///
    /// - Parameters:
    ///   - start: 开始日期
    ///   - end: 结束日期
    /// - Returns: 日期数组
    static func dates(from start: Date, to end: Date) -> [Date] {
        guard start <= end else { return [] }

        var dates: [Date] = []
        var current = start

        while current <= end {
            dates.append(current)
            if let tempValue = gregorian.ls_date(byAdding: .day, value: 1, to: current) {
                current = tempValue
            } else {
                current = current
            }
        }

        return dates
    }
}

#endif

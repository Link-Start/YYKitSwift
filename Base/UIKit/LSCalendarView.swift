//
//  LSCalendarView.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  日历视图 - 自定义日历组件
//

#if canImport(UIKit)
import UIKit

// MARK: - LSCalendarView

/// 日历视图
@MainActor
public class LSCalendarView: UIView {

    // MARK: - 类型定义

    /// 日历模式
    public enum CalendarMode {
        case month           // 月视图
        case week            // 周视图
        case day             // 日视图
    }

    /// 选择模式
    public enum SelectionMode {
        case single          // 单选
        case multiple        // 多选
        case range           // 范围选择
    }

    /// 星期起始日
    public enum WeekStartDay {
        case sunday
        case monday
        case saturday
    }

    /// 日期数据
    public struct DateData {
        let date: Date
        let isToday: Bool
        let isSelected: Bool
        let isInRange: Bool
        let isPreviousMonth: Bool
        let isNextMonth: Bool
        let isDisabled: Bool
        let events: [Event]

        public init(
            date: Date,
            isToday: Bool = false,
            isSelected: Bool = false,
            isInRange: Bool = false,
            isPreviousMonth: Bool = false,
            isNextMonth: Bool = false,
            isDisabled: Bool = false,
            events: [Event] = []
        ) {
            self.date = date
            self.isToday = isToday
            self.isSelected = isSelected
            self.isInRange = isInRange
            self.isPreviousMonth = isPreviousMonth
            self.isNextMonth = isNextMonth
            self.isDisabled = isDisabled
            self.events = events
        }

        /// 事件
        public struct Event {
            let title: String?
            let color: UIColor?
            let startDate: Date?
            let endDate: Date?

            public init(
                title: String? = nil,
                color: UIColor? = nil,
                startDate: Date? = nil,
                endDate: Date? = nil
            ) {
                self.title = title
                self.color = color
                self.startDate = startDate
                self.endDate = endDate
            }
        }
    }

    /// 日期选择回调
    public typealias DateHandler = (Date) -> Void

    /// 日期范围回调
    public typealias DateRangeHandler = (Date?, Date?) -> Void

    // MARK: - 属性

    /// 当前显示的日期
    public var currentDate: Date = Date() {
        didSet {
            updateCalendar()
        }
    }

    /// 日历模式
    public var calendarMode: CalendarMode = .month {
        didSet {
            updateCalendar()
        }
    }

    /// 选择模式
    public var selectionMode: SelectionMode = .single {
        didSet {
            clearSelection()
        }
    }

    /// 星期起始日
    public var weekStartDay: WeekStartDay = .sunday {
        didSet {
            updateCalendar()
        }
    }

    /// 日历（默认公历）
    public var calendar: Calendar = Calendar.current {
        didSet {
            updateCalendar()
        }
    }

    /// 选中的日期
    public private(set) var selectedDates: Set<Date> = []

    /// 日期范围
    public private(set) var dateRange: (start: Date?, end: Date?) = (nil, nil)

    /// 最小日期
    public var minimumDate: Date?

    /// 最大日期
    public var maximumDate: Date?

    /// 禁用日期
    public var disabledDates: Set<Date> = [] {
        didSet {
            updateCalendar()
        }
    }

    /// 事件数据
    public var events: [Date: [DateData.Event]] = [:] {
        didSet {
            updateCalendar()
        }
    }

    /// 日期选择回调
    public var onDateSelected: DateHandler?

    /// 日期范围回调
    public var onDateRangeChanged: DateRangeHandler?

    /// 月份变化回调
    public var onMonthChanged: ((Date) -> Void)?

    // MARK: - 样式属性

    /// 日期字体
    public var dayFont: UIFont = .systemFont(ofSize: 16)

    /// 今天字体
    public var todayFont: UIFont = .systemFont(ofSize: 16, weight: .bold)

    /// 选中日期颜色
    public var selectedColor: UIColor = .systemBlue {
        didSet {
            updateCalendar()
        }
    }

    /// 今天颜色
    public var todayColor: UIColor = .systemRed {
        didSet {
            updateCalendar()
        }
    }

    /// 范围颜色
    public var rangeColor: UIColor = .systemBlue.withAlphaComponent(0.3)

    /// 禁用日期颜色
    public var disabledColor: UIColor = .systemGray3

    /// 星期标题颜色
    public var weekdayColor: UIColor = .secondaryLabel

    /// 日期颜色
    public var dayColor: UIColor = .label

    /// 其他月份日期颜色
    public var otherMonthColor: UIColor = .tertiaryLabel

    // MARK: - 私有属性

    private var monthStartDate: Date = Date()
    private var monthEndDate: Date = Date()

    private let weekdayHeaderView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let monthHeaderView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let previousMonthButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("<", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let nextMonthButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(">", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let monthLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private var dayButtons: [UIButton] = []
    private var weekdayLabels: [UILabel] = []

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupCalendar()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCalendar()
    }

    public convenience init(date: Date = Date()) {
        self.init(frame: .zero)
        self.currentDate = date
    }

    // MARK: - 设置

    private func setupCalendar() {
        backgroundColor = .systemBackground

        addSubview(monthHeaderView)
        addSubview(weekdayHeaderView)

        // 设置月份标题
        monthHeaderView.addSubview(previousMonthButton)
        monthHeaderView.addSubview(nextMonthButton)
        monthHeaderView.addSubview(monthLabel)

        NSLayoutConstraint.activate([
            monthHeaderView.topAnchor.constraint(equalTo: topAnchor),
            monthHeaderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            monthHeaderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            monthHeaderView.heightAnchor.constraint(equalToConstant: 44),

            previousMonthButton.leadingAnchor.constraint(equalTo: monthHeaderView.leadingAnchor, constant: 16),
            previousMonthButton.centerYAnchor.constraint(equalTo: monthHeaderView.centerYAnchor),

            nextMonthButton.trailingAnchor.constraint(equalTo: monthHeaderView.trailingAnchor, constant: -16),
            nextMonthButton.centerYAnchor.constraint(equalTo: monthHeaderView.centerYAnchor),

            monthLabel.centerXAnchor.constraint(equalTo: monthHeaderView.centerXAnchor),
            monthLabel.centerYAnchor.constraint(equalTo: monthHeaderView.centerYAnchor),

            weekdayHeaderView.topAnchor.constraint(equalTo: monthHeaderView.bottomAnchor, constant: 8),
            weekdayHeaderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            weekdayHeaderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            weekdayHeaderView.heightAnchor.constraint(equalToConstant: 20)
        ])

        // 按钮事件
        previousMonthButton.ls_addAction(for: .touchUpInside) { [weak self] in
            self?.showPreviousMonth()
        }

        nextMonthButton.ls_addAction(for: .touchUpInside) { [weak self] in
            self?.showNextMonth()
        }

        // 创建星期标签
        createWeekdayLabels()

        updateCalendar()
    }

    private func createWeekdayLabels() {
        let weekdays = ["日", "一", "二", "三", "四", "五", "六"]
        let startIndex = weekdayStartDay == .sunday ? 0 : (weekdayStartDay == .monday ? 1 : 6)

        for i in 0..<7 {
            let label = UILabel()
            label.text = weekdays[(startIndex + i) % 7]
            label.font = .systemFont(ofSize: 12, weight: .medium)
            label.textColor = weekdayColor
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false

            weekdayHeaderView.addSubview(label)
            weekdayLabels.append(label)
        }

        // 布局星期标签
        let spacing: CGFloat = 8
        let labelWidth = (weekdayHeaderView.bounds.width - spacing * 6) / 7

        for (index, label) in weekdayLabels.enumerated() {
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: weekdayHeaderView.topAnchor),
                label.bottomAnchor.constraint(equalTo: weekdayHeaderView.bottomAnchor),
                label.widthAnchor.constraint(equalToConstant: labelWidth),
                label.leadingAnchor.constraint(equalTo: weekdayHeaderView.leadingAnchor, constant: CGFloat(index) * (labelWidth + spacing))
            ])
        }
    }

    // MARK: - 布局

    public override func layoutSubviews() {
        super.layoutSubviews()

        updateWeekdayLabelsLayout()
    }

    private func updateWeekdayLabelsLayout() {
        let spacing = weekdayHeaderView.bounds.width / 7

        for (index, label) in weekdayLabels.enumerated() {
            label.frame = CGRect(
                x: CGFloat(index) * spacing,
                y: 0,
                width: spacing,
                height: weekdayHeaderView.bounds.height
            )
        }
    }

    // MARK: - 日历更新

    private func updateCalendar() {
        // 计算月份范围
        calculateMonthRange()

        // 更新月份标题
        updateMonthLabel()

        // 创建日期按钮
        createDayButtons()
    }

    private func calculateMonthRange() {
        let components = calendar.dateComponents([.year, .month], from: currentDate)
        guard let monthStart = calendar.date(from: components) else { return }

        monthStartDate = monthStart

        guard let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart),
              let monthEndDate = calendar.date(byAdding: .day, value: -1, to: monthEnd) else {
            return
        }

        self.monthEndDate = monthEndDate
    }

    private func updateMonthLabel() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年 MM月"
        monthLabel.text = formatter.string(from: currentDate)
    }

    private func createDayButtons() {
        // 移除旧的按钮
        dayButtons.forEach { $0.removeFromSuperview() }
        dayButtons.removeAll()

        // 计算月份的第一天
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate)) else {
            return
        }

        // 计算第一天是星期几
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let startIndex = weekdayStartDay == .sunday ? 1 : (weekdayStartDay == .monday ? 2 : 7)
        let offset = (firstWeekday - startIndex + 7) % 7

        // 计算月份天数
        let range = calendar.range(of: .day, in: .month, for: currentDate)!
        let daysInMonth = range.count

        // 计算上个月的天数
        guard let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentDate),
              let previousMonthRange = calendar.range(of: .day, in: .month, for: previousMonth) else {
            return
        }
        let daysInPreviousMonth = previousMonthRange.count

        // 计算下个月的天数
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentDate),
              let nextMonthRange = calendar.range(of: .day, in: .month, for: nextMonth) else {
            return
        }
        let daysInNextMonth = nextMonthRange.count

        // 总行数
        let totalDays = offset + daysInMonth
        let numberOfRows = (totalDays + 6) / 7

        // 创建按钮
        var day = 1
        var nextMonthDay = 1

        let spacing: CGFloat = 8
        let buttonWidth = (bounds.width - spacing * 6) / 7
        let buttonHeight: CGFloat = 40
        let startY = weekdayHeaderView.frame.maxY + 8

        for row in 0..<numberOfRows {
            for col in 0..<7 {
                let button = UIButton(type: .system)
                button.titleLabel?.font = dayFont
                button.layer.cornerRadius = buttonWidth / 2
                button.clipsToBounds = true
                button.translatesAutoresizingMaskIntoConstraints = false
                addSubview(button)

                let x = CGFloat(col) * (buttonWidth + spacing)
                let y = startY + CGFloat(row) * (buttonHeight + spacing)

                button.frame = CGRect(x: x, y: y, width: buttonWidth, height: buttonHeight)

                let index = row * 7 + col
                var buttonDate: Date?
                var isPreviousMonth = false
                var isNextMonth = false
                var isDisabled = false

                if index < offset {
                    // 上个月
                    let dayInPreviousMonth = daysInPreviousMonth - offset + index + 1
                    button.setTitle(String(dayInPreviousMonth), for: .normal)
                    button.setTitleColor(otherMonthColor, for: .normal)
                    isPreviousMonth = true

                    if let date = calendar.date(byAdding: .day, value: -offset + index, to: monthStart) {
                        buttonDate = date
                    }
                } else if day <= daysInMonth {
                    // 当前月
                    button.setTitle(String(day), for: .normal)

                    if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                        buttonDate = date

                        // 检查是否是今天
                        if calendar.isDateInToday(date) {
                            button.titleLabel?.font = todayFont
                            button.setTitleColor(todayColor, for: .normal)
                        } else {
                            button.setTitleColor(dayColor, for: .normal)
                        }

                        // 检查是否选中
                        if selectedDates.contains(where: { calendar.isDate($0, inSameDayAs: date) }) {
                            button.backgroundColor = selectedColor
                            button.setTitleColor(.white, for: .normal)
                        }

                        // 检查是否在范围内
                        if let rangeStart = dateRange.start, let rangeEnd = dateRange.end {
                            if date > rangeStart && date < rangeEnd {
                                button.backgroundColor = rangeColor
                            }
                        }

                        // 检查是否禁用
                        if let minDate = minimumDate, date < minDate {
                            isDisabled = true
                        } else if let maxDate = maximumDate, date > maxDate {
                            isDisabled = true
                        } else if disabledDates.contains(where: { calendar.isDate($0, inSameDayAs: date) }) {
                            isDisabled = true
                        }

                        if isDisabled {
                            button.setTitleColor(disabledColor, for: .normal)
                            button.isEnabled = false
                        }
                    }

                    day += 1
                } else {
                    // 下个月
                    button.setTitle(String(nextMonthDay), for: .normal)
                    button.setTitleColor(otherMonthColor, for: .normal)
                    isNextMonth = true

                    if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                        buttonDate = date
                    }

                    nextMonthDay += 1
                }

                // 存储日期
                if let date = buttonDate {
                    button.ls_associatedObject = date
                }

                button.ls_addAction(for: .touchUpInside) { [weak self, weak button] in
                    guard let self = self, let button = button else { return }
                    self.handleDayTap(button)
                }

                dayButtons.append(button)
            }
        }

        // 更新内容大小
        let contentHeight = startY + CGFloat(numberOfRows) * (buttonHeight + spacing) + 8
        contentSize = CGSize(width: bounds.width, height: contentHeight)
    }

    // MARK: - 日期处理

    private func handleDayTap(_ button: UIButton) {
        guard let date = button.ls_associatedObject as? Date else { return }

        switch selectionMode {
        case .single:
            selectedDates.removeAll()
            selectedDates.insert(date)
            onDateSelected?(date)

        case .multiple:
            if selectedDates.contains(where: { calendar.isDate($0, inSameDayAs: date) }) {
                selectedDates.remove(where: { calendar.isDate($0, inSameDayAs: date) })
            } else {
                selectedDates.insert(date)
            }
            onDateSelected?(date)

        case .range:
            if let rangeStart = dateRange.start, let rangeEnd = dateRange.end {
                // 已有范围，重新开始
                dateRange = (start: date, end: nil)
            } else if let rangeStart = dateRange.start {
                // 有开始日期，设置结束日期
                if date > rangeStart {
                    dateRange = (start: rangeStart, end: date)
                } else {
                    dateRange = (start: date, end: rangeStart)
                }
                onDateRangeChanged?(dateRange.start, dateRange.end)
            } else {
                // 设置开始日期
                dateRange = (start: date, end: nil)
            }
        }

        updateCalendar()
    }

    // MARK: - 公共方法

    /// 选择日期
    public func selectDate(_ date: Date) {
        selectedDates.removeAll()
        selectedDates.insert(date)
        currentDate = date
        updateCalendar()
    }

    /// 选择日期范围
    public func selectDateRange(start: Date, end: Date) {
        dateRange = (start: start, end: end)
        updateCalendar()
    }

    /// 清除选择
    public func clearSelection() {
        selectedDates.removeAll()
        dateRange = (nil, nil)
        updateCalendar()
    }

    /// 显示上个月
    public func showPreviousMonth() {
        if let date = calendar.date(byAdding: .month, value: -1, to: currentDate) {
            currentDate = date
            onMonthChanged?(date)
        }
    }

    /// 显示下个月
    public func showNextMonth() {
        if let date = calendar.date(byAdding: .month, value: 1, to: currentDate) {
            currentDate = date
            onMonthChanged?(date)
        }
    }

    /// 跳转到今天
    public func goToToday() {
        currentDate = Date()
        updateCalendar()
    }

    /// 跳转到指定日期
    public func goTo(date: Date) {
        currentDate = date
        updateCalendar()
    }
}

// MARK: - UIButton Extension (Associated Object)

private var associatedObjectKey: UInt8 = 0

extension UIButton {
    var ls_associatedObject: Any? {
        get {
            return objc_getAssociatedObject(self, &associatedObjectKey)
        }
        set {
            objc_setAssociatedObject(
                self,
                &associatedObjectKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}

// MARK: - LSCalendarHeaderView

/// 日历头部视图（简化版）
public class LSCalendarHeaderView: UIView {

    /// 标题
    public var title: String? {
        didSet {
            titleLabel.text = title
        }
    }

    /// 前一个月按钮
    public let previousButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("<", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    /// 下一个月按钮
    public let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(">", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupHeaderView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupHeaderView()
    }

    // MARK: - 设置

    private func setupHeaderView() {
        addSubview(previousButton)
        addSubview(nextButton)
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            previousButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            previousButton.centerYAnchor.constraint(equalTo: centerYAnchor),

            nextButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            nextButton.centerYAnchor.constraint(equalTo: centerYAnchor),

            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}

// MARK: - UIView Extension (Calendar)

public extension UIView {

    private enum AssociatedKeys {
        static var calendarViewKey: UInt8 = 0
    }var ls_calendarView: LSCalendarView? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.calendarViewKey) as? LSCalendarView
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.calendarViewKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// 添加日历视图
    @discardableResult
    func ls_addCalendar(
        height: CGFloat = 400,
        date: Date = Date(),
        mode: LSCalendarView.CalendarMode = .month
    ) -> LSCalendarView {
        let calendar = LSCalendarView(date: date)
        calendar.calendarMode = mode
        calendar.translatesAutoresizingMaskIntoConstraints = false

        addSubview(calendar)

        NSLayoutConstraint.activate([
            calendar.topAnchor.constraint(equalTo: topAnchor),
            calendar.leadingAnchor.constraint(equalTo: leadingAnchor),
            calendar.trailingAnchor.constraint(equalTo: trailingAnchor),
            calendar.heightAnchor.constraint(equalToConstant: height)
        ])

        ls_calendarView = calendar
        return calendar
    }
}

#endif

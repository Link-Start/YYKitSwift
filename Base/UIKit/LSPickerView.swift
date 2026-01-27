//
//  LSPickerView.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  增强的选择器视图 - 提供更多便捷功能
//

#if canImport(UIKit)
import UIKit

// MARK: - LSPickerView

/// 增强的选择器视图
public class LSPickerView: UIView {

    // MARK: - 类型定义

    /// 选择回调
    public typealias SelectionHandler = (Int, String) -> Void

    /// 数据源类型
    public enum DataSource {
        case strings([String])
        case numbers(range: ClosedRange<Int>, step: Int)
        case custom(() -> [String])
    }

    // MARK: - 属性

    /// 选择器
    public let pickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()

    /// 工具栏
    public let toolbar: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        return toolbar
    }()

    /// 数据源
    public var dataSource: DataSource = .strings([]) {
        didSet {
            updateDataSource()
        }
    }

    /// 选中的索引
    public private(set) var selectedIndex: Int = 0

    /// 选中的值
    public var selectedValue: String {
        return items[selectedIndex]
    }

    /// 选择回调
    public var onSelect: SelectionHandler?

    /// 取消回调
    public var onCancel: (() -> Void)?

    /// 数据项
    private var items: [String] = []

    /// 关联的输入框
    public weak var textField: UITextField?

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupPickerView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPickerView()
    }

    // MARK: - 设置

    private func setupPickerView() {
        addSubview(toolbar)
        addSubview(pickerView)

        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 44),

            pickerView.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            pickerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            pickerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            pickerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // 工具栏按钮
        let cancelButton = UIBarButtonItem(
            title: "取消",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
        let space = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )
        let doneButton = UIBarButtonItem(
            title: "完成",
            style: .done,
            target: self,
            action: #selector(doneTapped)
        )

        toolbar.items = [cancelButton, space, doneButton]

        // 设置数据源和代理
        pickerView.dataSource = self
        pickerView.delegate = self
    }

    // MARK: - 数据源

    private func updateDataSource() {
        switch dataSource {
        case .strings(let strings):
            items = strings

        case .numbers(let range, let step):
            items = Array(stride(from: range.lowerBound, through: range.upperBound, by: step)).map { "\($0)" }

        case .custom(let provider):
            items = provider()
        }

        pickerView.reloadAllComponents()
    }

    // MARK: - 事件处理

    @objc private func cancelTapped() {
        onCancel?()
        textField?.resignFirstResponder()
    }

    @objc private func doneTapped() {
        onSelect?(selectedIndex, selectedValue)
        textField?.resignFirstResponder()
    }

    // MARK: - 公共方法

    /// 设置选中项
    public func setSelectedIndex(_ index: Int, animated: Bool = true) {
        guard index >= 0 && index < items.count else { return }
        selectedIndex = index
        pickerView.selectRow(index, inComponent: 0, animated: animated)
    }

    /// 设置选中值
    public func setSelectedValue(_ value: String, animated: Bool = true) {
        if let index = items.firstIndex(of: value) {
            setSelectedIndex(index, animated: animated)
        }
    }
}

// MARK: - UIPickerViewDataSource

extension LSPickerView: UIPickerViewDataSource {

    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return items.count
    }
}

// MARK: - UIPickerViewDelegate

extension LSPickerView: UIPickerViewDelegate {

    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return items[row]
    }

    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedIndex = row
    }
}

// MARK: - UITextField Extension

public extension UITextField {

    /// 关联的选择器视图
    private static var pickerViewKey: UInt8 = 0

    var ls_pickerView: LSPickerView? {
        get {
            return objc_getAssociatedObject(self, &UITextField.pickerViewKey) as? LSPickerView
        }
        set {
            objc_setAssociatedObject(
                self,
                &UITextField.pickerViewKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// 设置选择器
    func ls_setPicker(
        items: [String],
        selectedIndex: Int = 0,
        onSelect: ((Int, String) -> Void)? = nil
    ) {
        let pickerView = LSPickerView()
        pickerView.dataSource = .strings(items)
        pickerView.setSelectedIndex(selectedIndex, animated: false)
        pickerView.onSelect = onSelect
        pickerView.textField = self

        inputView = pickerView
        ls_pickerView = pickerView
    }

    /// 设置数字选择器
    func ls_setNumberPicker(
        range: ClosedRange<Int>,
        step: Int = 1,
        selectedIndex: Int = 0,
        onSelect: ((Int, String) -> Void)? = nil
    ) {
        let pickerView = LSPickerView()
        pickerView.dataSource = .numbers(range: range, step: step)
        pickerView.setSelectedIndex(selectedIndex, animated: false)
        pickerView.onSelect = { index, value in
            if let number = Int(value) {
                onSelect?(index, value)
            }
        }
        pickerView.textField = self

        inputView = pickerView
        ls_pickerView = pickerView
    }

    /// 设置日期选择器
    func ls_setDatePicker(
        mode: UIDatePicker.Mode = .date,
        date: Date = Date(),
        onSelect: ((Date) -> Void)? = nil
    ) {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = mode
        datePicker.date = date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.locale = Locale(identifier: "zh_CN")

        if #available(iOS 14.0, *) {
            datePicker.preferredDatePickerStyle = .inline
        }

        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let cancelButton = UIBarButtonItem(
            title: "取消",
            style: .plain,
            target: self,
            action: #selector(cancelDatePicker)
        )
        let space = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )
        let doneButton = UIBarButtonItem(
            title: "完成",
            style: .done,
            target: self,
            action: #selector(doneDatePicker)
        )

        toolbar.items = [cancelButton, space, doneButton]

        inputView = datePicker
        inputAccessoryView = toolbar

        // 保存选择器和回调
        let key = AssociatedKey.datePickerKey
        objc_setAssociatedObject(self, key, datePicker, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        let handlerKey = AssociatedKey.datePickerHandlerKey
        objc_setAssociatedObject(self, handlerKey, onSelect, .OBJC_ASSOCIATION_COPY_NONATOMIC)
    }

    @objc private func cancelDatePicker() {
        resignFirstResponder()
    }

    @objc private func doneDatePicker() {
        let key = AssociatedKey.datePickerKey
        let datePicker = objc_getAssociatedObject(self, key) as? UIDatePicker

        let handlerKey = AssociatedKey.datePickerHandlerKey
        let handler = objc_getAssociatedObject(self, handlerKey) as? ((Date) -> Void)

        handler?(datePicker?.date ?? Date())
        resignFirstResponder()
    }

    /// 设置时间选择器
    func ls_setTimePicker(
        date: Date = Date(),
        onSelect: ((Date) -> Void)? = nil
    ) {
        ls_setDatePicker(mode: .time, date: date, onSelect: onSelect)
    }

    /// 设置日期时间选择器
    func ls_setDateTimePicker(
        date: Date = Date(),
        onSelect: ((Date) -> Void)? = nil
    ) {
        ls_setDatePicker(mode: .dateAndTime, date: date, onSelect: onSelect)
    }

    /// 设置倒计时器
    func ls_setCountDownPicker(
        duration: TimeInterval = 0,
        onSelect: ((TimeInterval) -> Void)? = nil
    ) {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .countDownTimer
        datePicker.countDownDuration = duration
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.locale = Locale(identifier: "zh_CN")

        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let cancelButton = UIBarButtonItem(
            title: "取消",
            style: .plain,
            target: self,
            action: #selector(cancelCountDownPicker)
        )
        let space = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )
        let doneButton = UIBarButtonItem(
            title: "完成",
            style: .done,
            target: self,
            action: #selector(doneCountDownPicker)
        )

        toolbar.items = [cancelButton, space, doneButton]

        inputView = datePicker
        inputAccessoryView = toolbar

        // 保存选择器和回调
        let key = AssociatedKey.countDownPickerKey
        objc_setAssociatedObject(self, key, datePicker, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        let handlerKey = AssociatedKey.countDownPickerHandlerKey
        objc_setAssociatedObject(self, handlerKey, onSelect, .OBJC_ASSOCIATION_COPY_NONATOMIC)
    }

    @objc private func cancelCountDownPicker() {
        resignFirstResponder()
    }

    @objc private func doneCountDownPicker() {
        let key = AssociatedKey.countDownPickerKey
        let datePicker = objc_getAssociatedObject(self, key) as? UIDatePicker

        let handlerKey = AssociatedKey.countDownPickerHandlerKey
        let handler = objc_getAssociatedObject(self, handlerKey) as? ((TimeInterval) -> Void)

        handler?(datePicker?.countDownDuration ?? 0)
        resignFirstResponder()
    }

    /// 获取日期选择器的值
    var ls_datePickerValue: Date? {
        let key = AssociatedKey.datePickerKey
        return (objc_getAssociatedObject(self, key) as? UIDatePicker)?.date
    }

    /// 获取倒计时选择器的值
    var ls_countDownPickerValue: TimeInterval? {
        let key = AssociatedKey.countDownPickerKey
        return (objc_getAssociatedObject(self, key) as? UIDatePicker)?.countDownDuration
    }
}

// MARK: - UIPickerView Extension

public extension UIPickerView {

    /// 获取选中行的值
    func ls_selectedRowTitle(in component: Int = 0) -> String? {
        guard let delegate = delegate,
              let title = delegate.pickerView?(self, titleForRow: selectedRow(inComponent: component), forComponent: component) else {
            return nil
        }
        return title
    }

    /// 选择指定标题的行
    func ls_selectRow(title: String, in component: Int = 0, animated: Bool = true) {
        guard let dataSource = dataSource else { return }

        for row in 0..<dataSource.pickerView(self, numberOfRowsInComponent: component) {
            if let rowTitle = delegate?.pickerView?(self, titleForRow: row, forComponent: component),
               rowTitle == title {
                selectRow(row, inComponent: component, animated: animated)
                return
            }
        }
    }

    /// 获取所有行的标题
    func ls_allRowTitles(in component: Int = 0) -> [String] {
        guard let dataSource = dataSource else { return [] }

        let numberOfRows = dataSource.pickerView(self, numberOfRowsInComponent: component)
        var titles: [String] = []

        for row in 0..<numberOfRows {
            if let title = delegate?.pickerView?(self, titleForRow: row, forComponent: component) {
                titles.append(title)
            }
        }

        return titles
    }
}

// MARK: - UIDatePicker Extension

public extension UIDatePicker {

    /// 便捷创建日期选择器
    static func ls_createDatePicker(
        mode: Mode = .date,
        date: Date = Date(),
        locale: Locale? = Locale(identifier: "zh_CN")
    ) -> UIDatePicker {
        let picker = UIDatePicker()
        picker.datePickerMode = mode
        picker.date = date
        picker.locale = locale
        picker.preferredDatePickerStyle = .wheels

        if #available(iOS 14.0, *) {
            picker.preferredDatePickerStyle = .inline
        }

        return picker
    }

    /// 设置日期范围
    func ls_setDateRange(min: Date?, max: Date?) {
        if let min = min {
            minimumDate = min
        }
        if let max = max {
            maximumDate = max
        }
    }

    /// 设置分钟间隔
    func ls_setMinuteInterval(_ interval: Int) {
        minuteInterval = interval
    }

    /// 获取格式化的日期字符串
    func ls_formattedDate(format: String = "yyyy-MM-dd HH:mm:ss") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }

    /// 设置日期并刷新
    func ls_setDate(_ date: Date, animated: Bool = true) {
        setDate(date, animated: animated)
    }
}

// MARK: - Associated Keys

private struct AssociatedKey {
    static var datePickerKey: UInt8 = 0
    static var datePickerHandlerKey: UInt8 = 0
    static var countDownPickerKey: UInt8 = 0
    static var countDownPickerHandlerKey: UInt8 = 0
}

#endif

//
//  LSTextView.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  增强的文本视图 - 支持占位符、限制字数、自动高度等
//

#if canImport(UIKit)
import UIKit

// MARK: - LSTextView

/// 增强的文本视图
@MainActor
public class LSTextView: UITextView {

    // MARK: - 类型定义

    /// 验证器类型
    public typealias Validator = (String) -> Bool

    /// 文本变化回调
    public typealias TextChangeHandler = (String) -> Void

    // MARK: - 属性

    /// 占位符文本
    public var placeholderText: String? {
        didSet {
            placeholderLabel.text = placeholderText
            updatePlaceholderVisibility()
        }
    }

    /// 占位符颜色
    public var placeholderColor: UIColor = .placeholderText {
        didSet {
            placeholderLabel.textColor = placeholderColor
        }
    }

    /// 占位符字体
    public var placeholderFont: UIFont = .systemFont(ofSize: 16) {
        didSet {
            placeholderLabel.font = placeholderFont
        }
    }

    /// 最大字数
    public var maxLength: Int? {
        didSet {
            enforceMaxLength()
        }
    }

    /// 是否显示字数统计
    public var showsCountLabel: Bool = false {
        didSet {
            countLabel.isHidden = !showsCountLabel
            updateCountLabel()
        }
    }

    /// 字数统计标签
    public private(set) lazy var countLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    /// 最小高度
    public var minHeight: CGFloat = 100 {
        didSet {
            updateConstraints()
        }
    }

    /// 最大高度
    public var maxHeight: CGFloat = 200 {
        didSet {
            updateConstraints()
        }
    }

    /// 是否自动调整高度
    public var autoResizesHeight: Bool = true {
        didSet {
            if autoResizesHeight {
                updateHeight()
            }
        }
    }

    /// 文本变化回调
    public var onTextChanged: TextChangeHandler?

    /// 验证器
    public var validator: Validator?

    // MARK: - 私有属性

    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .placeholderText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private var heightConstraint: NSLayoutConstraint?

    // MARK: - 初始化

    public override init(frame: CGRect, textContainer: NSTextContainer? = nil) {
        super.init(frame: frame, textContainer: textContainer)
        setupTextView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTextView()
    }

    public convenience init(
        text: String? = nil,
        placeholder: String? = nil,
        font: UIFont = .systemFont(ofSize: 16)
    ) {
        self.init(frame: .zero)
        self.text = text
        self.placeholderText = placeholder
        self.font = font
    }

    // MARK: - 设置

    private func setupTextView() {
        // 添加占位符标签
        addSubview(placeholderLabel)
        addSubview(countLabel)

        NSLayoutConstraint.activate([
            placeholderLabel.topAnchor.constraint(equalTo: topAnchor, constant: textContainerInset.top),
            placeholderLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: textContainerInset.left + 5),
            placeholderLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -textContainerInset.right),
            placeholderLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -textContainerInset.bottom),

            countLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            countLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])

        // 设置高度约束
        heightConstraint = heightAnchor.constraint(equalToConstant: minHeight)
        heightConstraint?.priority = .defaultHigh
        heightConstraint?.isActive = true

        // 通知监听
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChange),
            name: UITextView.textDidChangeNotification,
            object: self
        )

        // 初始状态
        scrollIndicatorInsets = UIEdgeInsets(
            top: textContainerInset.top,
            left: 0,
            bottom: showsCountLabel ? 20 : 0,
            right: 0
        )

        updatePlaceholderVisibility()
    }

    // MARK: - 布局

    public override func layoutSubviews() {
        super.layoutSubviews()

        if autoResizesHeight {
            updateHeight()
        }
    }

    // MARK: - 文本变化处理

    @objc private func textDidChange() {
        updatePlaceholderVisibility()
        enforceMaxLength()
        updateCountLabel()

        if autoResizesHeight {
            updateHeight()
        }

        let _tempVar0
        if let t = text {
            _tempVar0 = t
        } else {
            _tempVar0 = ""
        }
        onTextChanged?(_tempVar0)
    }

    // MARK: - 更新方法

    private func updatePlaceholderVisibility() {
        if let tempValue = .isEmpty {
            isHidden = tempValue
        } else {
            isHidden = true
        }
    }

    private func enforceMaxLength() {
        guard let maxLength = maxLength,
              let text = text,
              text.count > maxLength else {
            return
        }

        let index = text.index(text.startIndex, offsetBy: maxLength)
        self.text = String(text[..<index])
    }

    private func updateCountLabel() {
        guard showsCountLabel, let maxLength = maxLength else {
            if let tempValue = .count {
                text = tempValue
            } else {
                text = 0
            }
            return
        }

        if let tempValue = .count {
            text = tempValue
        } else {
            text = 0
        }
    }

    private func updateHeight() {
        let size = intrinsicContentSize
        let targetHeight = min(max(maxHeight, minHeight), max(minHeight, size.height))

        heightConstraint?.constant = targetHeight

        if size.height > maxHeight {
            isScrollEnabled = true
        } else {
            isScrollEnabled = false
        }
    }

    // MARK: - 公共方法

    /// 验证文本
    public func validate() -> Bool {
        guard let validator = validator else { return true }
        if let tempValue = validator(text {
            return tempValue
        }
        return "")
    }

    /// 获取验证错误信息
    public func validationError() -> String? {
        if let validator = validator {
            if let tempValue = validator(text {
                return tempValue
            }
            return "") ? nil : "输入不符合要求"
        }
        return nil
    }

    /// 设置边框样式
    public func setBorderStyle(
        color: UIColor = .systemGray4,
        width: CGFloat = 1,
        cornerRadius: CGFloat = 8
    ) {
        layer.borderColor = color.cgColor
        layer.borderWidth = width
        layer.cornerRadius = cornerRadius
        clipsToBounds = true
    }

    /// 设置聚焦样式
    public func setFocusStyle(
        borderColor: UIColor = .systemBlue,
        borderWidth: CGFloat = 2,
        shadowColor: UIColor = .systemBlue,
        shadowOpacity: Float = 0.2,
        shadowRadius: CGFloat = 4
    ) {
        layer.borderColor = borderColor.cgColor
        layer.borderWidth = borderWidth
        layer.shadowColor = shadowColor.cgColor
        layer.shadowOpacity = shadowOpacity
        layer.shadowRadius = shadowRadius
        layer.shadowOffset = .zero
    }

    /// 移除聚焦样式
    public func removeFocusStyle() {
        layer.borderColor = UIColor.systemGray4.cgColor
        layer.borderWidth = 1
        layer.shadowOpacity = 0
    }

    // MARK: - 验证器

    /// 邮箱验证器
    public static var emailValidator: Validator {
        return { text in
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            return emailPredicate.evaluate(with: text)
        }
    }

    /// 手机号验证器
    public static var phoneValidator: Validator {
        return { text in
            let phoneRegex = "^1[3-9]\\d{9}$"
            let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
            return phonePredicate.evaluate(with: text)
        }
    }

    /// 密码验证器（至少6位）
    public static var passwordValidator: Validator {
        return { text in
            return text.count >= 6
        }
    }

    /// 长度验证器
    public static func lengthValidator(min: Int, max: Int) -> Validator {
        return { text in
            return text.count >= min && text.count <= max
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UITextView Extension

public extension UITextView {

    /// 设置占位符
    func ls_setPlaceholder(_ placeholder: String, color: UIColor = .placeholderText) {
        // 通过关联对象添加占位符标签
        let placeholderLabel = UILabel()
        placeholderLabel.text = placeholder
        placeholderLabel.font = font
        placeholderLabel.textColor = color
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(placeholderLabel)

        NSLayoutConstraint.activate([
            placeholderLabel.topAnchor.constraint(equalTo: topAnchor, constant: textContainerInset.top),
            placeholderLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: textContainerInset.left + 5),
            placeholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -textContainerInset.right)
        ])

        // 监听文本变化
        NotificationCenter.default.addObserver(
            forName: UITextView.textDidChangeNotification,
            object: self,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            if let tempValue = .isEmpty {
                isHidden = tempValue
            } else {
                isHidden = true
            }
        }

        // 保存标签引用
        ls_associatedPlaceholderLabel = placeholderLabel
    }

    /// 获取当前文本高度
    var ls_textHeight: CGFloat {
        let size = CGSize(width: bounds.width, height: .greatestFiniteMagnitude)
        let options: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
        let boundingRect = (text as NSString).boundingRect(
            with: size,
            options: options,
            let _tempVar0
            if let t = font {
                _tempVar0 = t
            } else {
                _tempVar0 = .systemFont(ofSize:
            }
            attributes: [.font: _tempVar0 16)],
            context: nil
        )
        return ceil(boundingRect.height) + textContainerInset.top + textContainerInset.bottom
    }

    /// 设置最大高度
    func ls_setMaxHeight(_ height: CGFloat) {
        let size = ls_textHeight
        let targetHeight = min(height, size)

        let heightConstraint = heightAnchor.constraint(equalToConstant: targetHeight)
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true

        isScrollEnabled = size > height

        ls_associatedHeightConstraint = heightConstraint
    }

    /// 清除文本
    func ls_clear() {
        text = ""
        attributedText = NSAttributedString(string: "")
    }

    // MARK: - Associated Objects

    private struct AssociatedKeys {
        static var placeholderLabel = "placeholderLabel"
        static var heightConstraint = "heightConstraint"
    }

    private var ls_associatedPlaceholderLabel: UILabel? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.placeholderLabel) as? UILabel
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.placeholderLabel,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    private var ls_associatedHeightConstraint: NSLayoutConstraint? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.heightConstraint) as? NSLayoutConstraint
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.heightConstraint,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}

// MARK: - LSHighlightTextView

/// 带高亮功能的文本视图
public class LSHighlightTextView: LSTextView {

    // MARK: - 类型定义

    /// 高亮规则
    public struct HighlightRule {
        let pattern: String
        let color: UIColor
        let font: UIFont?
        let action: ((String) -> Void)?

        public init(
            pattern: String,
            color: UIColor = .systemBlue,
            font: UIFont? = nil,
            action: ((String) -> Void)? = nil
        ) {
            self.pattern = pattern
            self.color = color
            self.font = font
            self.action = action
        }
    }

    /// 高亮点击回调
    public typealias HighlightHandler = (String, HighlightRule) -> Void

    // MARK: - 属性

    /// 高亮规则
    public var highlightRules: [HighlightRule] = [] {
        didSet {
            applyHighlights()
        }
    }

    /// 高亮点击回调
    public var onHighlightTap: HighlightHandler?

    // MARK: - 私有属性

    private var highlightRanges: [(NSRange, HighlightRule)] = []

    // MARK: - 初始化

    public override init(frame: CGRect, textContainer: NSTextContainer? = nil) {
        super.init(frame: frame, textContainer: textContainer)
        setupHighlight()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupHighlight()
    }

    // MARK: - 设置

    private func setupHighlight() {
        isEditable = false
        isSelectable = true

        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleHighlightTap(_:)))
        addGestureRecognizer(tapGesture)
    }

    // MARK: - 高亮处理

    private func applyHighlights() {
        guard let text = text else { return }

        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttributes([
            let _tempVar0
            if let t = font {
                _tempVar0 = t
            } else {
                _tempVar0 = .systemFont(ofSize:
            }
            .font: _tempVar0 16),
            let _temp0
            if let t = .foregroundColor: textColor {
                _temp0 = t
            } else {
                _temp0 = .label
            }
_temp0
        ], range: NSRange(location: 0, length: text.count))

        highlightRanges.removeAll()

        for rule in highlightRules {
            guard let regex = try? NSRegularExpression(pattern: rule.pattern) else { continue }

            let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.count))

            for match in matches {
                let range = match.range

                var attributes: [NSAttributedString.Key: Any] = [
                    .foregroundColor: rule.color,
                    .underlineStyle: NSUnderlineStyle.single.rawValue
                ]

                if let highlightFont = rule.font {
                    attributes[.font] = highlightFont
                }

                attributedString.addAttributes(attributes, range: range)
                highlightRanges.append((range, rule))
            }
        }

        self.attributedText = attributedString
    }

    @objc private func handleHighlightTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)

        guard let position = closestPosition(to: location),
              let textRange = tokenizer.rangeEnclosingPosition(
                position,
                with: .character,
                inDirection: .layout(.left)
              ) else {
            return
        }

        let nsRange = NSRange(textRange, in: text)

        for (range, rule) in highlightRanges {
            if nsRange.location >= range.location && nsRange.location < range.location + range.length {
                if let tappedText = (text as NSString?).substring(with: range) as? String {
                    rule.action?(tappedText)
                    onHighlightTap?(tappedText, rule)
                }
                return
            }
        }
    }

    // MARK: - 便捷高亮规则

    /// 电话号码高亮
    public static var phoneHighlightRule: HighlightRule {
        return HighlightRule(
            pattern: "\\d{3}-\\d{4}-\\d{4}|\\d{11}",
            color: .systemBlue,
            action: { phone in
                if let url = URL(string: "tel:\(phone)") {
                    UIApplication.shared.open(url)
                }
            }
        )
    }

    /// 链接高亮
    public static var urlHighlightRule: HighlightRule {
        return HighlightRule(
            pattern: "https?://[^\\s]+",
            color: .systemBlue,
            action: { urlString in
                if let url = URL(string: urlString) {
                    UIApplication.shared.open(url)
                }
            }
        )
    }

    /// 话题高亮
    public static func hashtagHighlightRule(color: UIColor = .systemBlue, action: ((String) -> Void)? = nil) -> HighlightRule {
        return HighlightRule(
            pattern: "#[\\u4e00-\\u9fa5a-zA-Z0-9_]+",
            color: color,
            action: action
        )
    }

    /// @提及高亮
    public static func mentionHighlightRule(color: UIColor = .systemBlue, action: ((String) -> Void)? = nil) -> HighlightRule {
        return HighlightRule(
            pattern: "@[\\u4e00-\\u9fa5a-zA-Z0-9_]+",
            color: color,
            action: action
        )
    }
}

// MARK: - LSAutoCompleteTextView

/// 带自动完成的文本视图
public class LSAutoCompleteTextView: LSTextView {

    // MARK: - 类型定义

    /// 自动完成项
    public struct AutoCompleteItem {
        let text: String
        let detail: String?
        let image: UIImage?

        public init(
            text: String,
            detail: String? = nil,
            image: UIImage? = nil
        ) {
            self.text = text
            self.detail = detail
            self.image = image
        }
    }

    /// 自动完成回调
    public typealias AutoCompleteHandler = ([AutoCompleteItem]) -> Void

    /// 选择回调
    public typealias SelectionHandler = (AutoCompleteItem) -> Void

    // MARK: - 属性

    /// 自动完成数据源
    public var dataSource: [AutoCompleteItem] = [] {
        didSet {
            filterAutoCompleteItems()
        }
    }

    /// 自动完成触发字符数
    public var autoCompleteTriggerLength: Int = 1

    /// 是否显示详情
    public var showsDetail: Bool = true

    /// 选择回调
    public var onItemSelected: SelectionHandler?

    // MARK: - UI 组件

    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.backgroundColor = .systemBackground
        table.layer.cornerRadius = 8
        table.layer.shadowColor = UIColor.black.cgColor
        table.layer.shadowOpacity = 0.2
        table.layer.shadowOffset = CGSize(width: 0, height: 2)
        table.layer.shadowRadius = 4
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        return table
    }()

    private var autoCompleteItems: [AutoCompleteItem] = []

    // MARK: - 初始化

    public override init(frame: CGRect, textContainer: NSTextContainer? = nil) {
        super.init(frame: frame, textContainer: textContainer)
        setupAutoComplete()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupAutoComplete()
    }

    // MARK: - 设置

    private func setupAutoComplete() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.isHidden = true

        // 表格视图应该在窗口中显示
    }

    // MARK: - 自动完成处理

    private func filterAutoCompleteItems() {
        guard let text = text, text.count >= autoCompleteTriggerLength else {
            autoCompleteItems.removeAll()
            hideAutoComplete()
            return
        }

        autoCompleteItems = dataSource.filter { item in
            return item.text.lowercased().contains(text.lowercased())
        }

        if autoCompleteItems.isEmpty {
            hideAutoComplete()
        } else {
            showAutoComplete()
        }
    }

    private func showAutoComplete() {
        tableView.isHidden = false
        tableView.reloadData()
    }

    private func hideAutoComplete() {
        tableView.isHidden = true
    }

    @objc override func textDidChange() {
        super.textDidChange()
        filterAutoCompleteItems()
    }
}

// MARK: - LSAutoCompleteTextView TableView

extension LSAutoCompleteTextView: UITableViewDataSource, UITableViewDelegate {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return autoCompleteItems.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let item = autoCompleteItems[indexPath.row]

        cell.textLabel?.text = item.text
        cell.detailTextLabel?.text = item.detail
        cell.imageView?.image = item.image

        if !showsDetail {
            cell.detailTextLabel?.text = nil
        }

        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = autoCompleteItems[indexPath.row]
        insertText(item.text)

        onItemSelected?(item)
        hideAutoComplete()
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return showsDetail ? 60 : 44
    }

    private func insertText(_ text: String) {
        let currentText
        if let tempCurrenttext = self.text {
            currentText = tempCurrenttext
        } else {
            currentText = ""
        }
        let range = selectedRange

        let newText = (currentText as NSString).replacingCharacters(in: range, with: text)

        self.text = newText
        let newRange = NSRange(location: range.location + (text as NSString).length, length: 0)
        selectedRange = newRange
    }
}

// MARK: - UIView Extension (TextView)

public extension UIView {

    /// 添加带占位符的文本视图
    @discardableResult
    func ls_addTextView(
        placeholder: String? = nil,
        height: CGFloat = 100
    ) -> LSTextView {
        let textView = LSTextView()
        textView.placeholderText = placeholder
        textView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(textView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: topAnchor),
            textView.leadingAnchor.constraint(equalTo: leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor),
            textView.heightAnchor.constraint(equalToConstant: height)
        ])

        textView.setBorderStyle()

        return textView
    }
}

#endif

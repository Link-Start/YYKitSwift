//
//  LSTextView.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  富文本输入框 - 支持富文本编辑、文本附件、占位符等
//

#if canImport(UIKit)
import UIKit
import CoreText

// MARK: - 常量

/// 默认占位符颜色
private let kDefaultPlaceholderColor = UIColor(white: 0.7, alpha: 1)

/// 最大文本长度（默认无限制）
private let kDefaultMaxLength = 0

// MARK: - LSTextViewDelegate

/// LSTextView 代理协议
///
/// 扩展 UITextViewDelegate，添加额外的文本变化和操作回调
@MainActor
public protocol LSTextViewDelegate: UITextViewDelegate {
    /// 文本即将变化（支持取消）
    ///
    /// - Parameters:
    ///   - textView: 文本视图
    ///   - range: 文本范围
    ///   - text: 替换文本
    /// - Returns: true 允许变化，false 取消变化
    @objc optional func textView(_ textView: LSTextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool

    /// 文本已变化
    ///
    /// - Parameters:
    ///   - textView: 文本视图
    ///   - text: 新的富文本
    @objc optional func textViewDidChange(_ textView: LSTextView)

    /// 文本达到最大长度
    ///
    /// - Parameter textView: 文本视图
    @objc optional func textViewDidReachMaxLength(_ textView: LSTextView)

    /// 自定义菜单项
    ///
    /// - Parameters:
    ///   - textView: 文本视图
    ///   - menu: 菜单控制器
    /// - Returns: 自定义菜单项数组
    @objc optional func textView(_ textView: LSTextView, menuFor menu: UIMenuController) -> [UIMenuItem]?
}

// MARK: - LSTextView

/// LSTextView 是一个功能强大的富文本输入框
///
/// 主要特性：
/// - 支持富文本编辑
/// - 支持文本附件（图片、自定义视图）
/// - 支持占位符
/// - 支持最大长度限制
/// - 支持自定义菜单
/// - 支持撤销/重做
/// - 支持键盘类型
/// - 支持自动大写
/// - 支持自动纠错
/// - 支持安全输入
@MainActor
public class LSTextView: UITextView {

    // MARK: - 代理

    /// 扩展代理（LS 专用回调）
    public weak var lsDelegate: LSTextViewDelegate? {
        didSet {
            // 设置标准代理为 self，内部转发到 lsDelegate
            super.delegate = self
        }
    }

    // MARK: - 占位符属性

    /// 占位符文本
    public var placeholder: String? {
        didSet {
            _updatePlaceholderVisibility()
        }
    }

    /// 占位符颜色
    public var placeholderColor: UIColor = kDefaultPlaceholderColor {
        didSet {
            _updatePlaceholderLabel()
        }
    }

    /// 占位符字体（nil 时使用 textFont）
    public var placeholderFont: UIFont? {
        didSet {
            _updatePlaceholderLabel()
        }
    }

    // MARK: - 文本属性

    /// 文本字体（默认 17pt 系统字体）
    public var textFont: UIFont = UIFont.systemFont(ofSize: 17) {
        didSet {
            typingAttributes[.font] = textFont
            _updatePlaceholderLabel()
        }
    }

    /// 文本颜色
    public var textColor_value: UIColor? {
        didSet {
            if let color = textColor_value {
                typingAttributes[.foregroundColor] = color
            }
        }
    }

    // MARK: - 限制属性

    /// 最大文本长度（0 表示无限制）
    public var maxLength: UInt = kDefaultMaxLength

    /// 是否在达到最大长度时震动反馈
    public var vibrateOnMaxLength: Bool = true

    // MARK: - 键盘属性

    /// 键盘类型
    public var keyboardStyle: UIKeyboardType = .default {
        didSet {
            keyboardAppearance = keyboardStyle
        }
    }

    /// 自动大写类型
    public var autocapitalizationType_value: UITextAutocapitalizationType = .sentences {
        didSet {
            autocapitalizationType = autocapitalizationType_value
        }
    }

    /// 自动纠错类型
    public var autocorrectionType_value: UITextAutocorrectionType = .default {
        didSet {
            autocorrectionType = autocorrectionType_value
        }
    }

    /// 安全输入
    public var isSecureTextEntry_value: Bool = false {
        didSet {
            isSecureTextEntry = isSecureTextEntry_value
        }
    }

    // MARK: - 菜单属性

    /// 是否允许显示菜单
    public var allowsMenu: Bool = true

    /// 自定义菜单项
    public var customMenuItems: [UIMenuItem] = []

    // MARK: - 只读属性

    /// 当前文本长度
    public var currentLength: UInt {
        return UInt(text.length)
    }

    /// 是否达到最大长度
    public var isMaxLengthReached: Bool {
        return maxLength > 0 && currentLength >= maxLength
    }

    /// 占位符是否可见
    public var isPlaceholderVisible: Bool {
        return _placeholderLabel?.isHidden == false
    }

    // MARK: - 私有属性

    private var _placeholderLabel: UILabel?

    // 状态标志
    private struct State {
        var isDeleting: Bool = false
        var isInserting: Bool = false
        var didChangeText: Bool = false
    }

    private var _state = State()

    // MARK: - 初始化

    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        _commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _commonInit()
    }

    private func _commonInit() {
        // 设置默认属性
        font = textFont
        textColor = .black
        backgroundColor = .white
        tintColor = .blue

        // 设置默认输入属性
        typingAttributes = [
            .font: textFont,
            .foregroundColor: UIColor.black
        ]

        // 设置代理
        super.delegate = self

        // 添加通知观察
        _addNotificationObservers()

        // 设置占位符
        _setupPlaceholderLabel()

        // 允许检测链接、电话等
        dataDetectorTypes = []
    }

    // MARK: - 布局

    public override func layoutSubviews() {
        super.layoutSubviews()
        _layoutPlaceholderLabel()
    }

    // MARK: - 占位符

    private func _setupPlaceholderLabel() {
        let label = UILabel()
        label.font = textFont
        label.textColor = placeholderColor
        label.backgroundColor = .clear
        label.isUserInteractionEnabled = false
        label.numberOfLines = 0
        label.lineBreakMode = .byTruncatingTail
        label.textAlignment = textAlignment
        label.isHidden = true

        insertSubview(label, at: 0)
        _placeholderLabel = label
    }

    private func _layoutPlaceholderLabel() {
        guard let placeholderLabel = _placeholderLabel else { return }

        let insets = textContainerInset
        var rect = bounds

        // 减去内边距
        rect.origin.x += insets.left + textContainer.lineFragmentPadding
        rect.origin.y += insets.top
        rect.size.width -= insets.left + insets.right + textContainer.lineFragmentPadding * 2
        rect.size.height -= insets.top + insets.bottom

        placeholderLabel.frame = rect
    }

    private func _updatePlaceholderLabel() {
        guard let placeholderLabel = _placeholderLabel else { return }

        placeholderLabel.font = placeholderFont ?? textFont
        placeholderLabel.textColor = placeholderColor
        placeholderLabel.text = placeholder
        placeholderLabel.textAlignment = textAlignment
    }

    private func _updatePlaceholderVisibility() {
        guard let placeholderLabel = _placeholderLabel else { return }

        let isEmpty = text.isEmpty
        placeholderLabel.isHidden = !isEmpty

        if isEmpty, let placeholder = placeholder {
            placeholderLabel.text = placeholder
        }
    }

    // MARK: - 文本操作

    /// 设置富文本
    ///
    /// - Parameters:
    ///   - text: 富文本内容
    ///   - attributes: 文本属性（nil 使用当前属性）
    public func ls_setText(_ text: NSAttributedString?, attributes: [NSAttributedString.Key: Any]? = nil) {
        guard let text = text else {
            self.text = ""
            return
        }

        let mutable = NSMutableAttributedString(attributedString: text)

        // 应用属性
        if let attributes = attributes {
            let range = NSRange(location: 0, length: mutable.length)
            mutable.addAttributes(attributes, range: range)
        }

        attributedText = mutable
        _updatePlaceholderVisibility()
    }

    /// 插入文本
    ///
    /// - Parameter text: 要插入的文本
    public func ls_insertText(_ text: String) {
        let currentRange = selectedRange

        // 检查长度限制
        if !_shouldChangeText(in: currentRange, replacementText: text) {
            return
        }

        textStorage.replaceCharacters(in: currentRange, with: text)
        selectedRange = NSRange(location: currentRange.location + text.count, length: 0)

        _notifyTextDidChange()
    }

    /// 删除选中文本
    public func ls_deleteText() {
        let currentRange = selectedRange

        guard currentRange.length > 0 else { return }

        textStorage.replaceCharacters(in: currentRange, with: "")
        selectedRange = NSRange(location: currentRange.location, length: 0)

        _notifyTextDidChange()
    }

    /// 清空所有文本
    public func ls_clearText() {
        text = ""
        _updatePlaceholderVisibility()
    }

    /// 附加文本
    ///
    /// - Parameter text: 要附加的文本
    public func ls_appendText(_ text: String) {
        guard !text.isEmpty else { return }

        let currentLength = self.text.count

        // 检查长度限制
        if maxLength > 0 {
            let remainingLength = Int(maxLength) - currentLength
            if remainingLength <= 0 {
                _notifyMaxLengthReached()
                return
            }

            let toAppend = String(text.prefix(remainingLength))
            self.text += toAppend

            if toAppend.count < text.count {
                _notifyMaxLengthReached()
            }
        } else {
            self.text += text
        }

        _notifyTextDidChange()
    }

    // MARK: - 长度检查

    private func _shouldChangeText(in range: NSRange, replacementText text: String) -> Bool {
        // 询问代理
        if let delegate = lsDelegate, let result = delegate.textView?(self, shouldChangeTextIn: range, replacementText: text) {
            if !result {
                return false
            }
        }

        // 检查长度限制
        if maxLength > 0 {
            let currentLength = self.text.count
            let inputLength = text.count
            let replaceLength = range.length

            let newLength = currentLength - replaceLength + inputLength

            if newLength > Int(maxLength) {
                // 尝试截断
                let remainingLength = Int(maxLength) - (currentLength - replaceLength)
                if remainingLength > 0 {
                    // 允许部分输入
                } else {
                    _notifyMaxLengthReached()
                    return false
                }
            }
        }

        return true
    }

    private func _notifyMaxLengthReached() {
        if vibrateOnMaxLength {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }

        lsDelegate?.textViewDidReachMaxLength?(self)
    }

    private func _notifyTextDidChange() {
        _updatePlaceholderVisibility()

        if _state.didChangeText {
            lsDelegate?.textViewDidChange?(self)
        }
    }

    // MARK: - 通知

    private func _addNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(_textDidChange),
            name: UITextView.textDidChangeNotification,
            object: self
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(_keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(_keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func _textDidChange() {
        _state.didChangeText = true
        _notifyTextDidChange()
    }

    @objc private func _keyboardWillShow(_ notification: Notification) {
        // 子类可以重写实现自定义行为
    }

    @objc private func _keyboardWillHide(_ notification: Notification) {
        // 子类可以重写实现自定义行为
    }

    // MARK: - 菜单

    public override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        guard allowsMenu else { return false }

        // 检查是否可以执行标准操作
        if action == #selector(cut(_:)) {
            return selectedRange.length > 0
        }

        if action == #selector(copy(_:)) {
            return selectedRange.length > 0
        }

        if action == #selector(paste(_:)) {
            return UIPasteboard.general.hasStrings
        }

        if action == #selector(selectAll(_:)) {
            return text.count > 0
        }

        if action == #selector(delete(_:)) {
            return selectedRange.length > 0
        }

        return super.canPerformAction(action, withSender: sender)
    }

    public override func canBecomeFirstResponder() -> Bool {
        return true
    }

    public override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()

        if result {
            // 隐藏键盘时更新占位符
            _updatePlaceholderVisibility()
        }

        return result
    }

    // MARK: - UITextViewDelegate

    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return lsDelegate?.textViewShouldBeginEditing?(textView) ?? true
    }

    public func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        return lsDelegate?.textViewShouldEndEditing?(textView) ?? true
    }

    public func textViewDidBeginEditing(_ textView: UITextView) {
        lsDelegate?.textViewDidBeginEditing?(textView)
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
        _updatePlaceholderVisibility()
        lsDelegate?.textViewDidEndEditing?(textView)
    }

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return _shouldChangeText(in: range, replacementText: text)
    }

    public func textViewDidChange(_ textView: UITextView) {
        _state.didChangeText = true
        _notifyTextDidChange()
        lsDelegate?.textViewDidChange?(self)
    }

    public func textViewDidChangeSelection(_ textView: UITextView) {
        lsDelegate?.textViewDidChangeSelection?(textView)
    }

    public func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in range: NSRange) -> Bool {
        return lsDelegate?.textView?(textView, shouldInteractWith: textAttachment, in: range) ?? true
    }

    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in range: NSRange) -> Bool {
        return lsDelegate?.textView?(textView, shouldInteractWith: URL, in: range) ?? true
    }

    // MARK: - 析构

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UIMenuController 支持

extension LSTextView {

    /// 显示菜单
    ///
    /// - Parameters:
    ///   - rect: 菜单位置（nil 使用选区）
    ///   - animated: 是否动画
    public func ls_showMenu(at rect: CGRect? = nil, animated: Bool = true) {
        guard allowsMenu, becomesFirstResponder else { return }

        var menuRect = rect ?? rectForSelection()

        // 确保菜单在视图范围内
        menuRect = bounds.intersection(menuRect)

        guard !menuRect.isEmpty else { return }

        UIMenuController.shared.showMenu(from: self, rect: menuRect, animated: animated)
    }

    /// 获取选区矩形
    private func rectForSelection() -> CGRect {
        guard selectedRange.length > 0 else {
            return caretRect(for: selectedRange)
        }

        // 获取选区范围
        let layoutManager = layoutManager
        let textContainer = textContainer
        let location = selectedRange.location

        var rect = CGRect.zero

        if let glyphRange = layoutManager.glyphRange(forCharacterRange: selectedRange, actualCharacterRange: nil) {
            layoutManager.enumerateEnclosingRects(forGlyphRange: glyphRange, withinSelectedGlyphRange: glyphRange, in: textContainer) { rectPointer, stop in
                rect = rect!.union(rectPointer.pointee)
            }
        }

        // 添加 textContainerInset
        rect.origin.x += textContainerInset.left
        rect.origin.y += textContainerInset.top

        return rect
    }
}

// MARK: - 附件支持

extension LSTextView {

    /// 插入图片附件
    ///
    /// - Parameters:
    ///   - image: 图片
    ///   - imageSize: 图片尺寸（nil 使用原始尺寸）
    ///   - alignment: 对齐方式
    public func ls_insertImage(_ image: UIImage, size: CGSize? = nil, alignment: LSTextAttachmentAlignment = .center) {
        let attachment = LSTextAttachment()
        attachment.content = image
        attachment.contentMode = .scaleToFill

        let finalSize = size ?? image.size
        attachment.contentSize = finalSize

        // 使用现有的 NSAttributedString.ls_attributedString(with:) 创建
        let attrString = NSAttributedString.ls_attributedString(with: attachment)

        // 插入附件
        let currentRange = selectedRange
        textStorage.replaceCharacters(in: currentRange, with: attrString)
        selectedRange = NSRange(location: currentRange.location + 1, length: 0)

        _notifyTextDidChange()
    }

    /// 插入视图附件
    ///
    /// - Parameters:
    ///   - view: 视图
    ///   - size: 视图尺寸
    public func ls_insertView(_ view: UIView, size: CGSize) {
        let attachment = LSTextAttachment()
        attachment.content = view
        attachment.contentMode = .scaleToFill
        attachment.contentSize = size

        // 使用现有的 NSAttributedString.ls_attributedString(with:) 创建
        let attrString = NSAttributedString.ls_attributedString(with: attachment)

        // 插入附件
        let currentRange = selectedRange
        textStorage.replaceCharacters(in: currentRange, with: attrString)
        selectedRange = NSRange(location: currentRange.location + 1, length: 0)

        _notifyTextDidChange()
    }
}

// MARK: - 附件对齐

/// 附件对齐方式
public enum LSTextAttachmentAlignment: Int {
    case left = 0
    case center = 1
    case right = 2
}

// MARK: - 快捷方法扩展

extension LSTextView {

    /// 设置纯文本
    ///
    /// - Parameters:
    ///   - text: 纯文本
    ///   - font: 字体（nil 使用默认）
    ///   - color: 颜色（nil 使用默认）
    public func ls_setPlainText(_ text: String, font: UIFont? = nil, color: UIColor? = nil) {
        var attributes: [NSAttributedString.Key: Any] = [:]

        if let font = font {
            attributes[.font] = font
        } else {
            attributes[.font] = textFont
        }

        if let color = color {
            attributes[.foregroundColor] = color
        } else if let color = textColor_value {
            attributes[.foregroundColor] = color
        }

        let attrString = NSAttributedString(string: text, attributes: attributes)
        attributedText = attrString
        _updatePlaceholderVisibility()
    }

    /// 获取选中的文本
    ///
    /// - Returns: 选中的文本（nil 表示无选中）
    public func ls_selectedText() -> NSAttributedString? {
        guard selectedRange.length > 0 else { return nil }

        let text = attributedText
        return text.attributedSubstring(from: selectedRange)
    }

    /// 选择所有文本
    public func ls_selectAll() {
        selectedRange = NSRange(location: 0, length: attributedText.length)
    }

    /// 滚动到光标位置
    public func ls_scrollToCursor() {
        let caretRect = caretRect(for: selectedRange)
        scrollRectToVisible(caretRect.insetBy(dx: 0, dy: -10), animated: true)
    }

    /// 获取光标所在行
    ///
    /// - Returns: 光标所在行的范围
    public func ls_currentLineRange() -> NSRange {
        let location = selectedRange.location
        let text = attributedText.string as NSString

        var lineStart = 0
        var lineEnd = 0
        var contentsEnd = 0

        text.getLineStart(&lineStart, end: &lineEnd, contentsEnd: &contentsEnd, for: NSRange(location: location, length: 0))

        return NSRange(location: lineStart, length: lineEnd - lineStart)
    }
}

#endif

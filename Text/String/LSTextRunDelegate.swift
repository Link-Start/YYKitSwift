//
//  LSTextRunDelegate.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  文本 Run Delegate - 用于控制 CTRun 的排版行为
//

#if canImport(UIKit)
import UIKit
import CoreText

// MARK: - LSTextRunDelegate

/// LSTextRunDelegate 用于创建和管理 CTRunDelegate
///
/// CTRunDelegate 允许自定义文本附件的尺寸和排版行为
public class LSTextRunDelegate: NSObject {

    // MARK: - 属性

    /// 附件内容
    public var content: Any?

    /// 内容尺寸
    public var contentSize: CGSize = .zero

    /// 内容模式（用于图片附件）
    public var contentMode: UIView.ContentMode = .scaleToFill

    /// 内容内边距
    public var contentInsets: UIEdgeInsets = .zero

    /// 字形上升部
    public var ascent: CGFloat = 0

    /// 字形下降部
    public var descent: CGFloat = 0

    /// 字形宽度
    public var width: CGFloat = 0

    // MARK: - 初始化

    public override init() {
        super.init()
    }

    public init(content: Any?, contentSize: CGSize) {
        self.content = content
        self.contentSize = contentSize
        super.init()
        _updateMetrics()
    }

    // MARK: - 公共方法

    /// 创建 CTRunDelegate
    ///
    /// - Returns: CTRunDelegate 对象
    public func createCTRunDelegate() -> CTRunDelegate {
        let callbacks = CTRunDelegateCallbacks(
            version: kCTRunDelegateCurrentVersion,
            dealloc: { pointer in
                // 释放委托时清理
                _ = Unmanaged<LSTextRunDelegate>.fromOpaque(pointer!).takeRetainedValue()
            },
            getAscent: { pointer in
                let delegate = Unmanaged<LSTextRunDelegate>.fromOpaque(pointer!).takeUnretainedValue()
                return delegate.ascent
            },
            getDescent: { pointer in
                let delegate = Unmanaged<LSTextRunDelegate>.fromOpaque(pointer!).takeUnretainedValue()
                return delegate.descent
            },
            getWidth: { pointer in
                let delegate = Unmanaged<LSTextRunDelegate>.fromOpaque(pointer!).takeUnretainedValue()
                return delegate.width
            }
        )

        let pointer = Unmanaged.passRetained(self).toOpaque()
        return CTRunDelegateCreate(&callbacks, pointer)!
    }

    /// 更新度量值
    private func _updateMetrics() {
        var size = contentSize

        // 应用内边距
        size.width += contentInsets.left + contentInsets.right
        size.height += contentInsets.top + contentInsets.bottom

        // 根据内容模式调整
        if let image = content as? UIImage {
            let imageSize = image.size
            switch contentMode {
            case .scaleToFill:
                size = CGSize(width: max(size.width, size.height), height: max(size.width, size.height))
            case .scaleAspectFit:
                let scale = min(size.width / imageSize.width, size.height / imageSize.height)
                size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
            case .scaleAspectFill:
                let scale = max(size.width / imageSize.width, size.height / imageSize.height)
                size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
            default:
                break
            }
        }

        width = size.width
        ascent = size.height
        descent = 0
    }
}

// MARK: - NSAttributedString Extension (附件支持)

extension NSAttributedString {

    /// 使用附件创建属性字符串
    ///
    /// - Parameter attachment: 文本附件
    /// - Returns: 属性字符串
    public static func ls_attributedString(with attachment: LSTextAttachment) -> NSAttributedString {
        let delegate = LSTextRunDelegate(content: attachment.content, contentSize: attachment.contentSize)
        delegate.contentMode = attachment.contentMode
        delegate.contentInsets = attachment.contentInsets

        var attrs: [NSAttributedString.Key: Any] = [:]
        attrs[kCTRunDelegateAttributeName as NSAttributedString.Key] = delegate.createCTRunDelegate()
        attrs[LSTextAttachmentAttributeName] = attachment

        return NSAttributedString(string: LSTextAttachmentToken, attributes: attrs)
    }
}

extension NSMutableAttributedString {

    /// 添加附件到字符串
    ///
    /// - Parameters:
    ///   - attachment: 文本附件
    ///   - location: 插入位置
    public func ls_append(_ attachment: LSTextAttachment) {
        let string = NSAttributedString.ls_attributedString(with: attachment)
        append(string)
    }

    /// 在指定位置插入附件
    ///
    /// - Parameters:
    ///   - attachment: 文本附件
    ///   - location: 插入位置
    public func ls_insert(_ attachment: LSTextAttachment, at location: Int) {
        let string = NSAttributedString.ls_attributedString(with: attachment)
        insert(string, at: location)
    }
}

// MARK: - LSTextAttachment Extension

extension LSTextAttachment {

    /// 获取显示尺寸
    ///
    /// - Returns: 实际显示尺寸
    public var displaySize: CGSize {
        var size = contentSize
        size.width += contentInsets.left + contentInsets.right
        size.height += contentInsets.top + contentInsets.bottom
        return size
    }

    /// 获取内容矩形
    ///
    /// - Parameter bounds: 附件边界
    /// - Returns: 内容矩形
    public func contentRect(in bounds: CGRect) -> CGRect {
        return bounds.inset(by: contentInsets)
    }
}

#endif

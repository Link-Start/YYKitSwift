//
//  UILabel+YYKitSwift.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  UILabel 扩展，提供文本尺寸计算方法和 contentEdgeInsets 支持
//

import UIKit
import ObjectiveC

// MARK: - 关联对象键

private var kContentEdgeInsetsKey: UInt8 = 0
private var kYYKitSwiftSwizzleToken: UInt8 = 0

// MARK: - UILabel 扩展

@MainActor
public extension UILabel {

    /// 计算文本所需尺寸
    func ls_sizeThatFits(_ size: CGSize) -> CGSize {
        guard let text = text, let font = font else {
            return CGSize(width: bounds.width, height: bounds.height)
        }

        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let boundingRect = (text as NSString).boundingRect(
            with: size,
            options: .usesLineFragmentOrigin,
            attributes: attributes,
            context: nil
        )

        return CGSize(
            width: ceil(boundingRect.width),
            height: ceil(boundingRect.height)
        )
    }

    /// 计算单行文本宽度
    var ls_textWidth: CGFloat {
        guard let text = text, let font = font else { return 0 }
        let attributes = [NSAttributedString.Key.font: font]
        return (text as NSString).size(withAttributes: attributes).width
    }

    /// 计算多行文本高度（指定宽度）
    func ls_textHeight(forWidth width: CGFloat) -> CGFloat {
        return ls_sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
    }
}

// MARK: - YYKitSwift 命名空间扩展

public extension YYKitSwift where Base: UILabel {

    /// 内容边距 - 用于在 label 内容周围添加内边距
    ///
    /// 设置此属性后，label 会自动调整文本绘制区域和尺寸计算
    ///
    /// 使用示例：
    /// ```swift
    /// label.yy.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
    /// ```
    var contentEdgeInsets: UIEdgeInsets {
        get {
            if let insets = objc_getAssociatedObject(base, &kContentEdgeInsetsKey) as? NSValue {
                return insets.uiEdgeInsetsValue
            }
            return .zero
        }
        set {
            let insets = NSValue(uiEdgeInsets: newValue)
            objc_setAssociatedObject(base, &kContentEdgeInsetsKey, insets, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

            // 启用方法交换（只执行一次）
            UILabel.yyKitSwiftEnableSwizzle()

            base.setNeedsDisplay()
            base.invalidateIntrinsicContentSize()
        }
    }
}

// MARK: - UILabel Swizzle 支持

extension UILabel {

    /// 启用 YYKitSwift 的 contentEdgeInsets 支持
    /// 此方法会自动调用，无需手动执行
    @objc public class func yyKitSwiftEnableSwizzle() {
        DispatchQueue.yyKitSwiftOnce(token: &kYYKitSwiftSwizzleToken) {
            swizzleSizeThatFits()
            swizzleIntrinsicContentSize()
            swizzleDrawTextInRect()
        }
    }

    private static func swizzleSizeThatFits() {
        let original = #selector(UILabel.sizeThatFits(_:))
        let swizzled = #selector(UILabel.yy_swizzleSizeThatFits(_:))

        guard let originalMethod = class_getInstanceMethod(UILabel.self, original),
              let swizzledMethod = class_getInstanceMethod(UILabel.self, swizzled) else {
            return
        }

        method_exchangeImplementations(originalMethod, swizzledMethod)
    }

    private static func swizzleIntrinsicContentSize() {
        let original = #selector(getter: UIView.intrinsicContentSize)
        let swizzled = #selector(UILabel.yy_swizzleIntrinsicContentSize)

        guard let originalMethod = class_getInstanceMethod(UILabel.self, original),
              let swizzledMethod = class_getInstanceMethod(UILabel.self, swizzled) else {
            return
        }

        method_exchangeImplementations(originalMethod, swizzledMethod)
    }

    private static func swizzleDrawTextInRect() {
        let original = #selector(UILabel.drawText(in:))
        let swizzled = #selector(UILabel.yy_swizzleDrawText(in:))

        guard let originalMethod = class_getInstanceMethod(UILabel.self, original),
              let swizzledMethod = class_getInstanceMethod(UILabel.self, swizzled) else {
            return
        }

        method_exchangeImplementations(originalMethod, swizzledMethod)
    }

    // MARK: Swizzle 实现

    @objc private func yy_swizzleSizeThatFits(_ size: CGSize) -> CGSize {
        let insets = yy.contentEdgeInsets
        let horizontalInset = insets.left + insets.right
        let verticalInset = insets.top + insets.bottom

        var adjustedSize = CGSize(
            width: max(0, size.width - horizontalInset),
            height: max(0, size.height - verticalInset)
        )

        // 调用原始方法（实际是交换后的方法）
        adjustedSize = yy_swizzleSizeThatFits(adjustedSize)

        adjustedSize.width = ceil(adjustedSize.width + horizontalInset)
        adjustedSize.height = ceil(adjustedSize.height + verticalInset)

        return adjustedSize
    }

    @objc private var yy_swizzleIntrinsicContentSize: CGSize {
        let insets = yy.contentEdgeInsets
        let maxWidth: CGFloat
        if preferredMaxLayoutWidth > 0 {
            maxWidth = preferredMaxLayoutWidth
        } else {
            maxWidth = .greatestFiniteMagnitude
        }

        var size = yy_swizzleSizeThatFits(CGSize(width: maxWidth, height: .greatestFiniteMagnitude))

        // 添加边距
        size.width = ceil(size.width + insets.left + insets.right)
        size.height = ceil(size.height + insets.top + insets.bottom)

        return size
    }

    @objc private func yy_swizzleDrawText(in rect: CGRect) -> CGRect {
        let insets = yy.contentEdgeInsets
        var adjustedRect = rect

        adjustedRect.origin.x += insets.left
        adjustedRect.origin.y += insets.top
        adjustedRect.size.width = max(0, adjustedRect.size.width - insets.left - insets.right)
        adjustedRect.size.height = max(0, adjustedRect.size.height - insets.top - insets.bottom)

        // 单行文本换行模式保护
        // 参考 QMUI_iOS: https://github.com/Tencent/QMUI_iOS/issues/529
        if numberOfLines == 1 &&
           (lineBreakMode == .byWordWrapping || lineBreakMode == .byCharWrapping) {
            adjustedRect.size.height += insets.top * 2
        }

        return yy_swizzleDrawText(in: adjustedRect)
    }
}

// MARK: - DispatchQueue Once 扩展

private extension DispatchQueue {
    static func yyKitSwiftOnce(token: UnsafeRawPointer, block: () -> Void) {
        objc_sync_enter(token)
        defer { objc_sync_exit(token) }

        if objc_getAssociatedObject(token) != nil {
            return
        }

        block()
        objc_setAssociatedObject(token, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

// MARK: - 使用示例

/*
 // 使用示例

 let label = UILabel()
 label.text = "Hello, World!"

 // 设置内容边距
 label.yy.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)

 // 或使用普通 UILabel
 let label2 = UILabel()
 label2.text = "Padding Label"
 label2.yy.contentEdgeInsets = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)

 // 对于使用 LSQMUILabel 的代码，可以保持不变
 let label3 = LSQMUILabel()
 label3.text = "Existing Code"
 label3.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
 */

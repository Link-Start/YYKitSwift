//
//  UIButton+YYKitSwift.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-26.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  UIButton 图片文字布局扩展 - 优化版本，解决边界溢出问题
//

#if canImport(UIKit)
import UIKit
import ObjectiveC

// MARK: - 关联对象键

private var kLayoutStyleKey: UInt8 = 0
private var kImageSpacingKey: UInt8 = 0
private var kImageMarginKey: UInt8 = 0

// MARK: - UIButton 扩展

public extension UIButton {

    // MARK: - 嵌套类型定义

    /// 图片文字布局样式
    enum LSButtonContentLayoutStyle: Int {
        case normal               // 内容居中，图左文右
        case centerImageRight    // 内容居中，图右文左
        case centerImageTop      // 内容居中，图上文下
        case centerImageBottom   // 内容居中，图下文上
        case leftImageLeft        // 内容居左，图左文右
        case leftImageRight       // 内容居左，图右文左
        case rightImageLeft      // 内容居右，图左文右
        case rightImageRight     // 内容居右，图右文左
    }

    // MARK: - 布局样式设置

    /// 设置图片文字布局样式
    ///
    /// 此方法会修复原 KJContentLayout 中的边界溢出问题，
    /// 通过正确计算 edgeInsets 确保内容不会超出按钮边界。
    ///
    /// - Parameters:
    ///   - style: 布局样式
    ///   - spacing: 图文间距，默认 0
    ///   - margin: 边界间距，默认 5
    func ls_setContentLayoutStyle(_ style: LSButtonContentLayoutStyle,
                           spacing: CGFloat = 0,
                           margin: CGFloat = 5) {
        // 保存参数
        objc_setAssociatedObject(self, &kLayoutStyleKey, NSNumber(value: style.rawValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &kImageSpacingKey, NSNumber(value: spacing), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &kImageMarginKey, NSNumber(value: margin), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        // 执行布局
        ls_applyContentLayout()
    }

    /// 获取内容所需的最小尺寸
    ///
    /// 此方法计算当前按钮内容（图片+文字+间距+边距）所需的最小尺寸，
    /// 可用于设置按钮的约束，确保内容不会被裁剪。
    ///
    /// - Returns: 内容所需的最小尺寸
    func ls_intrinsicContentSize(spacing: CGFloat = 0, margin: CGFloat = 5) -> CGSize {
        guard let image = imageView.image,
              let text = titleLabel.text else {
            return CGSize(width: margin * 2, height: margin * 2)
        }

        let style = LSButtonContentLayoutStyle(rawValue: currentLayoutStyle) ?? .normal
        let imageSize = image.size
        let font = titleLabel.font ?? UIFont.systemFont(ofSize: 17)
        let textSize = text.size(withAttributes: [.font: font])

        let imageWidth = imageSize.width
        let imageHeight = imageSize.height
        let labelWidth = textSize.width
        let labelHeight = textSize.height

        switch style {
        case .normal, .centerImageRight:
            return CGSize(
                width: imageWidth + spacing + labelWidth + margin * 2,
                height: max(imageHeight, labelHeight) + margin * 2
            )

        case .centerImageTop, .centerImageBottom:
            return CGSize(
                width: max(imageWidth, labelWidth) + margin * 2,
                height: imageHeight + spacing + labelHeight + margin * 2
            )

        case .leftImageLeft, .leftImageRight:
            return CGSize(
                width: imageWidth + spacing + labelWidth + margin * 2,
                height: max(imageHeight, labelHeight) + margin * 2
            )

        case .rightImageLeft, .rightImageRight:
            return CGSize(
                width: imageWidth + spacing + labelWidth + margin * 2,
                height: max(imageHeight, labelHeight) + margin * 2
            )
        }
    }

    // MARK: - 私有方法

    private var currentLayoutStyle: Int {
        objc_getAssociatedObject(self, &kLayoutStyleKey) as? Int ?? 0
    }

    private var currentSpacing: CGFloat {
        objc_getAssociatedObject(self, &kImageSpacingKey) as? CGFloat ?? 0
    }

    private var currentMargin: CGFloat {
        objc_getAssociatedObject(self, &kImageMarginKey) as? CGFloat ?? 5
    }

    /// 应用内容布局
    private func ls_applyContentLayout() {
        guard let image = imageView.image,
              let _ = titleLabel.text else {
            // 无内容时不处理
            return
        }

        let style = LSButtonContentLayoutStyle(rawValue: currentLayoutStyle) ?? .normal

        // 获取图片和文字尺寸
        let imageSize = image.size
        let font = titleLabel.font ?? UIFont.systemFont(ofSize: 17)
        let textSize = (titleLabel.text ?? "").size(withAttributes: [.font: font])

        let imageWidth = imageSize.width
        let imageHeight = imageSize.height
        let labelWidth = textSize.width
        let labelHeight = textSize.height

        // 计算可用空间
        let availableWidth = bounds.size.width
        let availableHeight = bounds.size.height

        var imageEdge: UIEdgeInsets = .zero
        var titleEdge: UIEdgeInsets = .zero
        var alignment: UIControl.ContentHorizontalAlignment = .center

        switch style {
        case .normal:
            // 图左文右，水平排列
            imageEdge = UIEdgeInsets(
                top: (availableHeight - imageHeight) / 2,
                left: currentMargin,
                bottom: (availableHeight - imageHeight) / 2,
                right: currentSpacing
            )
            titleEdge = UIEdgeInsets(
                top: (availableHeight - labelHeight) / 2,
                left: imageWidth + currentSpacing,
                bottom: (availableHeight - labelHeight) / 2,
                right: currentMargin
            )
            alignment = .center

        case .centerImageRight:
            // 图右文左，水平排列
            let totalWidth = imageWidth + currentSpacing + labelWidth
            let horizontalOffset = max(0, (availableWidth - totalWidth) / 2)

            imageEdge = UIEdgeInsets(
                top: (availableHeight - imageHeight) / 2,
                left: labelWidth + currentSpacing - horizontalOffset,
                bottom: (availableHeight - imageHeight) / 2,
                right: currentMargin
            )
            titleEdge = UIEdgeInsets(
                top: (availableHeight - labelHeight) / 2,
                left: currentMargin,
                bottom: (availableHeight - labelHeight) / 2,
                right: imageWidth + currentSpacing - horizontalOffset
            )
            alignment = .center

        case .centerImageTop:
            // 图上文下，垂直排列
            let totalHeight = imageHeight + currentSpacing + labelHeight
            let verticalOffset = max(0, (availableHeight - totalHeight) / 2)

            imageEdge = UIEdgeInsets(
                top: verticalOffset,
                left: (bounds.size.width - imageWidth) / 2,
                bottom: currentSpacing + labelHeight,
                right: (bounds.size.width - imageWidth) / 2
            )
            titleEdge = UIEdgeInsets(
                top: imageHeight + currentSpacing - verticalOffset,
                left: (bounds.size.width - labelWidth) / 2,
                bottom: verticalOffset,
                right: (bounds.size.width - labelWidth) / 2
            )
            alignment = .center

        case .centerImageBottom:
            // 图下文上，垂直排列
            let totalHeight = labelHeight + currentSpacing + imageHeight
            let verticalOffset = max(0, (availableHeight - totalHeight) / 2)

            titleEdge = UIEdgeInsets(
                top: verticalOffset,
                left: (bounds.size.width - labelWidth) / 2,
                bottom: currentSpacing + imageHeight,
                right: (bounds.size.width - labelWidth) / 2
            )
            imageEdge = UIEdgeInsets(
                top: labelHeight + currentSpacing - verticalOffset,
                left: (bounds.size.width - imageWidth) / 2,
                bottom: verticalOffset,
                right: (bounds.size.width - imageWidth) / 2
            )
            alignment = .center

        case .leftImageLeft:
            // 左对齐，图左文右
            imageEdge = UIEdgeInsets(
                top: (availableHeight - imageHeight) / 2,
                left: currentMargin,
                bottom: (availableHeight - imageHeight) / 2,
                right: currentSpacing
            )
            titleEdge = UIEdgeInsets(
                top: (availableHeight - labelHeight) / 2,
                left: imageWidth + currentSpacing,
                bottom: (availableHeight - labelHeight) / 2,
                right: currentMargin
            )
            alignment = .left

        case .leftImageRight:
            // 左对齐，图右文左
            let totalWidth = imageWidth + currentSpacing + labelWidth
            let horizontalOffset = max(0, (availableWidth - totalWidth - currentMargin * 2) / 2)

            imageEdge = UIEdgeInsets(
                top: (availableHeight - imageHeight) / 2,
                left: currentMargin + horizontalOffset,
                bottom: (availableHeight - imageHeight) / 2,
                right: currentSpacing
            )
            titleEdge = UIEdgeInsets(
                top: (availableHeight - labelHeight) / 2,
                left: imageWidth + currentSpacing,
                bottom: (availableHeight - labelHeight) / 2,
                right: currentMargin + horizontalOffset
            )
            alignment = .left

        case .rightImageLeft:
            // 右对齐，图左文右
            let totalWidth = imageWidth + currentSpacing + labelWidth
            let horizontalOffset = max(0, (availableWidth - totalWidth - currentMargin * 2) / 2)

            imageEdge = UIEdgeInsets(
                top: (availableHeight - imageHeight) / 2,
                left: horizontalOffset,
                bottom: (availableHeight - imageHeight) / 2,
                right: currentSpacing
            )
            titleEdge = UIEdgeInsets(
                top: (availableHeight - labelHeight) / 2,
                left: currentMargin + horizontalOffset,
                bottom: (availableHeight - labelHeight) / 2,
                right: imageWidth + currentSpacing
            )
            alignment = .right

        case .rightImageRight:
            // 右对齐，图右文左
            imageEdge = UIEdgeInsets(
                top: (availableHeight - imageHeight) / 2,
                left: currentMargin,
                bottom: (availableHeight - imageHeight) / 2,
                right: currentSpacing
            )
            titleEdge = UIEdgeInsets(
                top: (availableHeight - labelHeight) / 2,
                left: imageWidth + currentSpacing,
                bottom: (availableHeight - labelHeight) / 2,
                right: currentMargin
            )
            alignment = .right
        }

        imageEdgeInsets = imageEdge
        titleEdgeInsets = titleEdge
        contentHorizontalAlignment = alignment
    }
}
#endif

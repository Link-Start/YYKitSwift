//
//  UIBarButtonItem+YYKitSwift.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  UIBarButtonItem 扩展，提供 Block 创建方法
//

import UIKit

// MARK: - UIBarButtonItem 扩展

public extension UIBarButtonItem {

    /// 创建 UIBarButtonItem（使用 Block）
    static func ls_item(image: UIImage?, style: UIBarButtonItem.Style = .plain, callback: @escaping (UIBarButtonItem) -> Void) -> UIBarButtonItem {
        let item = UIBarButtonItem(image: image, style: style, target: nil, action: nil)
        ls_setupAction(item: item, callback: callback)
        return item
    }

    /// 创建 UIBarButtonItem（使用标题）
    static func ls_item(title: String?, style: UIBarButtonItem.Style = .plain, callback: @escaping (UIBarButtonItem) -> Void) -> UIBarButtonItem {
        let item = UIBarButtonItem(title: title, style: style, target: nil, action: nil)
        ls_setupAction(item: item, callback: callback)
        return item
    }

    /// 创建 UIBarButtonItem（使用系统样式）
    static func ls_item(systemItem: UIBarButtonItem.SystemItem, callback: @escaping (UIBarButtonItem) -> Void) -> UIBarButtonItem {
        let item = UIBarButtonItem(barButtonSystemItem: systemItem, target: nil, action: nil)
        ls_setupAction(item: item, callback: callback)
        return item
    }

    // MARK: - 私有方法

    private static func ls_setupAction(item: UIBarButtonItem, callback: @escaping (UIBarButtonItem) -> Void) {
        let wrapper = ActionWrapper(callback: callback)
        item.target = wrapper
        item.action = #selector(ActionWrapper.invoke(_:))

        // 使用关联对象保持引用
        let key = UnsafeRawPointer(Unmanaged.passUnretained(item).toOpaque())
        objc_setAssociatedObject(item, key, wrapper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

// MARK: - Action Wrapper

private class ActionWrapper: NSObject {
    var callback: (UIBarButtonItem) -> Void

    init(callback: @escaping (UIBarButtonItem) -> Void) {
        self.callback = callback
    }

    @objc func invoke(_ sender: UIBarButtonItem) {
        callback(sender)
    }
}

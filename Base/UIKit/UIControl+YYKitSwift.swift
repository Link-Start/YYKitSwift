//
//  UIControl+YYKitSwift.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  UIControl 扩展，提供 Block 回调支持
//

import UIKit

// MARK: - UIControl 扩展

@MainActor
public extension UIControl {

    /// 添加事件回调
    func ls_addEvent(_ event: UIControl.Event, callback: @escaping (UIControl) -> Void) {
        let actionWrapper = ActionWrapper(action: callback)
        let key = UnsafeRawPointer(Unmanaged.passUnretained(actionWrapper).toOpaque())

        addTarget(actionWrapper, action: #selector(ActionWrapper.invoke(_:)), for: event)

        // 使用关联对象保持引用
        objc_setAssociatedObject(self, key, actionWrapper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

// MARK: - Action Wrapper

private class ActionWrapper: NSObject {
    var action: (UIControl) -> Void

    init(action: @escaping (UIControl) -> Void) {
        self.action = action
    }

    @objc func invoke(_ sender: UIControl) {
        action(sender)
    }
}

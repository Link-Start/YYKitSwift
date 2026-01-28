//
//  UITextField+YYKitSwift.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  UITextField 扩展，提供文本处理方法
//

import UIKit

// MARK: - UITextField 扩展

@MainActor
public extension UITextField {

    /// 关联对象 key
    private static var maxLenghtKey: UInt8 = 0

    /// 最大长度限制
    var ls_maxLength: Int? {
        get {
            return objc_getAssociatedObject(self, &Self.maxLenghtKey) as? Int
        }
        set {
            objc_setAssociatedObject(self, &Self.maxLenghtKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            setupMaxLengthObserver()
        }
    }

    /// 文本变化回调
    func ls_textChange(_ callback: @escaping (String) -> Void) {
        let wrapper = TextChangeWrapper(callback: callback)
        let key = UnsafeRawPointer(Unmanaged.passUnretained(wrapper).toOpaque())
        objc_setAssociatedObject(self, key, wrapper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        addTarget(wrapper, action: #selector(TextChangeWrapper.textChanged(_:)), for: .editingChanged)
    }

    // MARK: - 私有方法

    private func setupMaxLengthObserver() {
        // 移除旧的观察者
        NotificationCenter.default.removeObserver(self, name: UITextField.textDidChangeNotification, object: self)

        // 添加新的观察者
        if ls_maxLength != nil {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleMaxLength),
                name: UITextField.textDidChangeNotification,
                object: self
            )
        }
    }

    @objc private func handleMaxLength() {
        guard let maxLength = ls_maxLength, let text = text else { return }

        if text.count > maxLength {
            let index = text.index(text.startIndex, offsetBy: maxLength)
            self.text = String(text[..<index])
        }
    }
}

// MARK: - Text Change Wrapper

private class TextChangeWrapper: NSObject {
    var callback: (String) -> Void

    init(callback: @escaping (String) -> Void) {
        self.callback = callback
    }

    @objc func textChanged(_ sender: UITextField) {
        let _tempVar0
        if let t = sender.text {
            _tempVar0 = t
        } else {
            _tempVar0 = ""
        }
        callback(_tempVar0)
    }
}

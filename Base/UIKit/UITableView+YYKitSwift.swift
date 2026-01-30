//
//  UITableView+YYKitSwift.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  UITableView 扩展，提供空视图和快捷方法
//

import UIKit

// MARK: - UITableView 扩展

@MainActor
public extension UITableView {

    private enum AssociatedKeys {
        static var emptyViewKey: UInt8 = 0
    }
    /// 空视图
    var ls_emptyView: UIView? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.emptyViewKey) as? UIView
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.emptyViewKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            updateEmptyViewVisibility()
        }
    }

    /// 更新空视图显示状态
    func ls_updateEmptyView() {
        updateEmptyViewVisibility()
    }

    // MARK: - 注册 Cell

    /// 使用类名注册 Cell（自动复用标识符）
    func ls_register<T: UITableViewCell>(_ cellClass: T.Type) {
        register(cellClass, forCellReuseIdentifier: String(describing: cellClass))
    }

    /// 使用 Xib 注册 Cell（自动复用标识符）
    func ls_register<T: UITableViewCell>(_ cellClass: T.Type, bundle: Bundle? = nil) {
        let nib = UINib(nibName: String(describing: cellClass), bundle: bundle)
        register(nib, forCellReuseIdentifier: String(describing: cellClass))
    }

    /// 使用类名注册 HeaderFooter（自动复用标识符）
    func ls_register<T: UITableViewHeaderFooterView>(_ viewClass: T.Type) {
        register(viewClass, forHeaderFooterViewReuseIdentifier: String(describing: viewClass))
    }

    // MARK: - 安全出队

    /// 安全出队 Cell（自动类型转换）
    func ls_dequeueReusableCell<T: UITableViewCell>(_ cellClass: T.Type, for indexPath: IndexPath) -> T {
        let identifier = String(describing: cellClass)
        return dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! T
    }

    /// 安全出队 HeaderFooter（自动类型转换）
    func ls_dequeueReusableHeaderFooter<T: UITableViewHeaderFooterView>(_ viewClass: T.Type) -> T {
        let identifier = String(describing: viewClass)
        return dequeueReusableHeaderFooterView(withIdentifier: identifier) as! T
    }

    // MARK: - 私有方法

    private func updateEmptyViewVisibility() {
        if let emptyView = ls_emptyView {
            let isEmpty = dataSource?.tableView(self, numberOfRowsInSection: 0) == 0
            emptyView.isHidden = !isEmpty
        }
    }
}

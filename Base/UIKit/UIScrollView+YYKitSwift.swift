//
//  UIScrollView+YYKitSwift.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  UIScrollView 扩展，提供快捷方法
//

import UIKit

// MARK: - UIScrollView 扩展

public extension UIScrollView {

    /// 滚动到顶部
    func ls_scrollToTop(animated: Bool = true) {
        setContentOffset(.zero, animated: animated)
    }

    /// 滚动到底部
    func ls_scrollToBottom(animated: Bool = true) {
        let bottomOffset = CGPoint(x: 0, y: max(0, contentSize.height - bounds.height))
        setContentOffset(bottomOffset, animated: animated)
    }

    /// 滚动到左边
    func ls_scrollToLeft(animated: Bool = true) {
        setContentOffset(.zero, animated: animated)
    }

    /// 滚动到右边
    func ls_scrollToRight(animated: Bool = true) {
        let rightOffset = CGPoint(x: max(0, contentSize.width - bounds.width), y: 0)
        setContentOffset(rightOffset, animated: animated)
    }

    /// 是否滚动到顶部
    var ls_isAtTop: Bool {
        return contentOffset.y <= -contentInset.top
    }

    /// 是否滚动到底部
    var ls_isAtBottom: Bool {
        return contentOffset.y >= contentSize.height - bounds.height - contentInset.bottom
    }
}

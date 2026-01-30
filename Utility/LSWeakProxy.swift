//
//  LSWeakProxy.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  弱引用代理 - 用于避免循环引用
//

#if canImport(UIKit)
import UIKit
import Foundation

/// LSWeakProxy 是用于持有弱对象的代理
///
/// 可以用于避免循环引用，例如 NSTimer 或 CADisplayLink 中的 target
///
/// 示例代码:
/// ```swift
/// class MyView: UIView {
///     private var timer: Timer?
///
///     func initTimer() {
///         let proxy = LSWeakProxy(target: self)
///         timer = Timer.scheduledTimer(timeInterval: 0.1,
///                                      target: proxy,
///                                      selector: #selector(tick(_:)),
///                                      userInfo: nil,
///                                      repeats: true)
///     }
///
///     @objc func tick(_ timer: Timer) {
///         // 处理定时器事件
///     }
/// }
/// ```
public class LSWeakProxy: NSObject {

    // MARK: - 属性

    /// 代理的目标对象（弱引用）
    public private(set) weak var target: NSObject?

    // MARK: - 初始化

    /// 使用指定的目标对象初始化代理
    ///
    /// - Parameter target: 目标对象
    public init(target: NSObject) {
        self.target = target
        super.init()
    }

    /// 创建指向指定目标对象的弱代理
    ///
    /// - Parameter target: 目标对象
    /// - Returns: 新的代理对象
    public static func proxy(withTarget target: NSObject) -> LSWeakProxy {
        return LSWeakProxy(target: target)
    }

    // MARK: - 消息转发

    override public func forwardingTarget(for aSelector: Selector!) -> Any? {
        // 将所有消息转发到目标对象
        return target
    }

    // 注意: 在 Swift 中，NSMethodSignature 和 NSInvocation 不可用
    // 大多数情况下，forwardingTarget(for:) 已经足够处理消息转发
    // 如果需要更复杂的消息转发，可以使用 @objc 协议或其他方法

    // MARK: - NSObject Protocol Override

    override public func responds(to aSelector: Selector!) -> Bool {
        if let t = target {
            return t.responds(to: aSelector)
        }
        return super.responds(to: aSelector)
    }

    override public func isEqual(_ object: Any?) -> Bool {
        if let t = target {
            return t.isEqual(object)
        }
        return super.isEqual(object)
    }

    override public var hash: Int {
        if let t = target {
            return t.hash
        }
        return super.hash
    }

    override public var superclass: AnyClass? {
        return target?.superclass
    }

    public var `class`: AnyClass {
        if let target = target {
            return type(of: target)
        }
        return type(of: self)
    }

    override public func isKind(of aClass: AnyClass) -> Bool {
        if let t = target {
            return t.isKind(of: aClass)
        }
        return super.isKind(of: aClass)
    }

    override public func isMember(of aClass: AnyClass) -> Bool {
        if let t = target {
            return t.isMember(of: aClass)
        }
        return super.isMember(of: aClass)
    }

    override public func conforms(to aProtocol: Protocol) -> Bool {
        if let t = target {
            return t.conforms(to: aProtocol)
        }
        return super.conforms(to: aProtocol)
    }

    public var isProxy: Bool {
        return true
    }

    override public var description: String {
        if let t = target {
            return t.description
        }
        return super.description
    }

    override public var debugDescription: String {
        if let t = target {
            return t.debugDescription
        }
        return super.debugDescription
    }
}
#endif

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
        return target
    }

    override public func methodSignature(for aSelector: Selector!) -> NSMethodSignature? {
        guard let target = target else {
            // 如果 target 已释放，返回一个默认的方法签名
            return NSObject.instanceMethodSignature(for: Selector(("init")))
        }

        // 让 target 处理方法签名
        guard let sig = target.methodSignature(for: aSelector) else {
            return super.methodSignature(for: aSelector)
        }

        return sig
    }

    override public func forward(_ aSelector: Selector!) -> UNrecognized {
        // 如果 target 已释放，不做任何操作
        guard let target = target else {
            return super.forward(aSelector)
        }

        // 尝试让 target 处理
        if target.responds(to: aSelector) {
            return super.forward(aSelector)
        }

        return super.forward(aSelector)
    }

    // MARK: - NSObject Protocol Override

    override public func responds(to aSelector: Selector!) -> Bool {
        return target?.responds(to: aSelector) ?? super.responds(to: aSelector)
    }

    override public func isEqual(_ object: Any?) -> Bool {
        return target?.isEqual(object) ?? super.isEqual(object)
    }

    override public var hash: Int {
        return target?.hash ?? super.hash
    }

    override public var superclass: AnyClass? {
        return target?.superclass
    }

    override public var `class`: AnyClass {
        return type(of: target ?? self)
    }

    override public func isKind(of aClass: AnyClass) -> Bool {
        return target?.isKind(of: aClass) ?? super.isKind(of: aClass)
    }

    override public func isMember(of aClass: AnyClass) -> Bool {
        return target?.isMember(of: aClass) ?? super.isMember(of: aClass)
    }

    override public func conforms(to aProtocol: Protocol) -> Bool {
        return target?.conforms(to: aProtocol) ?? super.conforms(to: aProtocol)
    }

    override public var isProxy: Bool {
        return true
    }

    override public var description: String {
        return target?.description ?? super.description
    }

    override public var debugDescription: String {
        return target?.debugDescription ?? super.debugDescription
    }
}
#endif

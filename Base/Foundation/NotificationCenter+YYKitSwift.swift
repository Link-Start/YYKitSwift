//
//  NotificationCenter+YYKitSwift.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  NotificationCenter 扩展，提供线程安全的通知发送
//

import Foundation

// MARK: - NotificationCenter 扩展

public extension NotificationCenter {

    // MARK: - 在主线程发送通知

    /// 在主线程发送通知
    /// 如果当前是主线程则同步发送，否则异步发送
    /// - Parameter notification: 要发送的通知
    func ls_postOnMain(_ notification: Notification) {
        ls_postOnMain(notification, waitUntilDone: false)
    }

    /// 在主线程发送通知
    /// - Parameters:
    ///   - notification: 要发送的通知
    ///   - waitUntilDone: 是否等待发送完成
    func ls_postOnMain(_ notification: Notification, waitUntilDone: Bool) {
        if Thread.isMainThread {
            post(notification)
        } else {
            OperationQueue.main.addOperation {
                self.post(notification)
            }

            if waitUntilDone {
                OperationQueue.main.waitUntilAllOperationsAreFinished()
            }
        }
    }

    /// 在主线程发送通知（通过名称和对象）
    /// - Parameters:
    ///   - name: 通知名称
    ///   - object: 发送对象
    func ls_postOnMain(name: Notification.Name, object: Any?) {
        ls_postOnMain(name: name, object: object, userInfo: nil, waitUntilDone: false)
    }

    /// 在主线程发送通知（通过名称、对象和用户信息）
    /// - Parameters:
    ///   - name: 通知名称
    ///   - object: 发送对象
    ///   - userInfo: 用户信息
    func ls_postOnMain(name: Notification.Name, object: Any?, userInfo: [AnyHashable: Any]?) {
        ls_postOnMain(name: name, object: object, userInfo: userInfo, waitUntilDone: false)
    }

    /// 在主线程发送通知（完整参数）
    /// - Parameters:
    ///   - name: 通知名称
    ///   - object: 发送对象
    ///   - userInfo: 用户信息
    ///   - waitUntilDone: 是否等待发送完成
    func ls_postOnMain(name: Notification.Name, object: Any?, userInfo: [AnyHashable: Any]?, waitUntilDone: Bool) {
        if Thread.isMainThread {
            post(name: name, object: object, userInfo: userInfo)
        } else {
            OperationQueue.main.addOperation {
                self.post(name: name, object: object, userInfo: userInfo)
            }

            if waitUntilDone {
                OperationQueue.main.waitUntilAllOperationsAreFinished()
            }
        }
    }
}

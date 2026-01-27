//
//  LSNotificationHelper.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  通知工具 - 简化本地通知和远程通知
//

#if canImport(UIKit)
import UIKit
import Foundation
import UserNotifications

// MARK: - LSNotificationHelper

/// 通知助手
public class LSNotificationHelper: NSObject {

    // MARK: - 单例

    /// 共享实例
    public static let shared = LSNotificationHelper()

    // MARK: - 属性

    /// 代理
    public weak var delegate: UNUserNotificationCenterDelegate?

    /// 授权状态
    public private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    // MARK: - 初始化

    private override init() {
        super.init()
        setupNotificationCenter()
    }

    // MARK: - 设置

    private func setupNotificationCenter() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        // 获取当前授权状态
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }

    // MARK: - 授权

    /// 请求通知权限
    ///
    /// - Parameter completion: 完成回调
    public func requestAuthorization(options: UNAuthorizationOptions = [.alert, .sound, .badge], completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
            DispatchQueue.main.async {
                self.authorizationStatus = granted ? .authorized : .denied
                completion?(granted)
            }
        }
    }

    /// 检查通知权限状态
    ///
    /// - Parameter completion: 完成回调
    public func checkAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
                completion(settings.authorizationStatus)
            }
        }
    }

    /// 是否已授权
    public var isAuthorized: Bool {
        return authorizationStatus == .authorized
    }

    // MARK: - 本地通知

    /// 发送本地通知
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - body: 内容
    ///   - identifier: 标识符
    ///   - delay: 延迟时间（秒）
    ///   - userInfo: 用户信息
    ///   - completionHandler: 完成回调
    public func send(
        title: String,
        body: String,
        identifier: String = UUID().uuidString,
        delay: TimeInterval = 0,
        userInfo: [String: Any]? = nil,
        completionHandler: ((Error?) -> Void)? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        if let userInfo = userInfo {
            content.userInfo = userInfo
        }

        let trigger: UNNotificationTrigger
        if delay > 0 {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        } else {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        }

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                completionHandler?(error)
            }
        }
    }

    /// 发送定时通知（每天重复）
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - body: 内容
    ///   - hour: 小时
    ///   - minute: 分钟
    ///   - identifier: 标识符
    ///   - completionHandler: 完成回调
    public func sendRepeating(
        title: String,
        body: String,
        hour: Int,
        minute: Int,
        identifier: String = UUID().uuidString,
        completionHandler: ((Error?) -> Void)? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                completionHandler?(error)
            }
        }
    }

    /// 取消通知
    ///
    /// - Parameter identifier: 标识符
    public func cancel(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// 取消所有通知
    public func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    /// 获取待发送的通知
    ///
    /// - Parameter completion: 完成回调
    public func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completion(requests)
            }
        }
    }

    /// 获取已发送的通知
    ///
    /// - Parameter completion: 完成回调
    public func getDeliveredNotifications(completion: @escaping ([UNNotification]) -> Void) {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            DispatchQueue.main.async {
                completion(notifications)
            }
        }
    }

    // MARK: - 徽章

    /// 设置应用徽章数量
    ///
    /// - Parameter count: 数量
    public func setBadgeCount(_ count: Int) {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }

    /// 清除徽章
    public func clearBadge() {
        setBadgeCount(0)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension LSNotificationHelper: UNUserNotificationCenterDelegate {

    /// 前台展示通知
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // 前台也显示通知
        completionHandler([.banner, .sound, .badge])
    }

    /// 处理通知点击
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // 获取用户信息
        let userInfo = response.notification.request.content.userInfo

        // 发送自定义通知
        NotificationCenter.default.post(
            name: .LSNotificationDidReceive,
            object: self,
            userInfo: userInfo
        )

        completionHandler()
    }
}

// MARK: - Notification.Name Extension

extension Notification.Name {
    /// 收到通知
    public static let LSNotificationDidReceive = Notification.Name("LSNotificationDidReceive")
}

// MARK: - 便捷方法

public extension LSNotificationHelper {

    /// 发送简单通知
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - body: 内容
    ///   - delay: 延迟时间（秒）
    static func send(
        title: String,
        body: String,
        delay: TimeInterval = 0
    ) {
        shared.send(title: title, body: body, delay: delay)
    }

    /// 检查是否已授权
    static var isAuthorized: Bool {
        return shared.isAuthorized
    }

    /// 请求授权
    static func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        shared.requestAuthorization(completion: completion)
    }
}

// MARK: - UNMutableNotificationContent Extension

public extension UNMutableNotificationContent {

    /// 便捷配置
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - body: 内容
    ///   - userInfo: 用户信息
    /// - Returns: self
    @discardableResult
    func ls_configure(
        title: String,
        body: String,
        userInfo: [String: Any]? = nil
    ) -> Self {
        self.title = title
        self.body = body
        if let userInfo = userInfo {
            self.userInfo = userInfo
        }
        return self
    }

    /// 设置声音
    ///
    /// - Parameter soundName: 声音名称（nil 表示默认声音）
    /// - Returns: self
    @discardableResult
    func ls_sound(_ soundName: String? = nil) -> Self {
        if let soundName = soundName {
            sound = UNNotificationSound(named: UNNotificationSoundName(soundName))
        } else {
            sound = .default
        }
        return self
    }

    /// 设置徽章
    ///
    /// - Parameter count: 徽章数量
    /// - Returns: self
    @discardableResult
    func ls_badge(_ count: Int) -> Self {
        badge = count
        return self
    }

    /// 设置附件
    ///
    /// - Parameter identifier: 附件标识符
    /// - Returns: self
    @discardableResult
    func ls_attachment(identifier: String) -> Self {
        do {
            let url = URL(fileURLWithPath: identifier)
            let attachment = try UNNotificationAttachment(identifier: identifier, url: url, options: nil)
            self.attachments = [attachment]
        } catch {
            print("添加附件失败: \(error)")
        }
        return self
    }

    /// 设置类别
    ///
    /// - Parameter identifier: 类别标识符
    /// - Returns: self
    @discardableResult
    func ls_category(_ identifier: String) -> Self {
        categoryIdentifier = identifier
        return self
    }

    /// 设置线程 ID
    ///
    /// - Parameter threadIdentifier: 线程标识符
    /// - Returns: self
    @discardableResult
    func ls_thread(_ threadIdentifier: String) -> Self {
        self.threadIdentifier = threadIdentifier
        return self
    }
}

// MARK: - UNNotificationRequest Extension

public extension UNNotificationRequest {

    /// 便捷创建请求
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - body: 内容
    ///   - identifier: 标识符
    ///   - delay: 延迟时间（秒）
    ///   - userInfo: 用户信息
    /// - Returns: 通知请求
    static func ls_create(
        title: String,
        body: String,
        identifier: String = UUID().uuidString,
        delay: TimeInterval = 0,
        userInfo: [String: Any]? = nil
    ) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        if let userInfo = userInfo {
            content.userInfo = userInfo
        }

        let trigger: UNNotificationTrigger
        if delay > 0 {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        } else {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        }

        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }
}

// MARK: - 通知类别管理

public extension LSNotificationHelper {

    /// 注册通知类别
    ///
    /// - Parameter categories: 类别数组
    static func registerCategories(_ categories: [UNNotificationCategory]) {
        UNUserNotificationCenter.current().setNotificationCategories(categories)
    }

    /// 创建交互式通知类别
    ///
    /// - Parameters:
    ///   - identifier: 类别标识符
    ///   - actions: 操作数组
    ///   - intentIdentifiers: Intent 标识符数组
    /// - Returns: 通知类别
    static func createCategory(
        identifier: String,
        actions: [UNNotificationAction] = [],
        intentIdentifiers: [String] = []
    ) -> UNNotificationCategory {
        return UNNotificationCategory(
            identifier: identifier,
            actions: actions,
            intentIdentifiers: intentIdentifiers,
            options: []
        )
    }

    /// 创建通知操作
    ///
    /// - Parameters:
    ///   - id: 操作 ID
    ///   - title: 标题
    ///   - options: 选项
    /// - Returns: 通知操作
    static func createAction(
        id: String,
        title: String,
        options: UNNotificationActionOptions = []
    ) -> UNNotificationAction {
        return UNNotificationAction(identifier: id, title: title, options: options)
    }
}

// MARK: - 应用程序扩展

public extension UIApplication {

    /// 设置徽章数量
    ///
    /// - Parameter count: 数量
    func ls_setBadgeCount(_ count: Int) {
        DispatchQueue.main.async {
            self.applicationIconBadgeNumber = count
        }
    }

    /// 清除徽章
    func ls_clearBadge() {
        ls_setBadgeCount(0)
    }

    /// 注册远程通知
    ///
    /// - Parameter completion: 完成回调
    func ls_registerForRemoteNotifications(completion: ((Bool, Error?) -> Void)? = nil) {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if granted {
                    DispatchQueue.main.async {
                        self.registerForRemoteNotifications()
                    }
                }
                completion?(granted, error)
            }
        } else {
            let settings = UIUserNotificationSettings(
                types: [.alert, .sound, .badge],
                categories: nil
            )
            self.registerUserNotificationSettings(settings)
            self.registerForRemoteNotifications()
        }
    }
}

#endif

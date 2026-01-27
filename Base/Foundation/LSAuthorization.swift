//
//  LSAuthorization.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  权限管理工具 - 统一管理各种系统权限请求
//

#if canImport(UIKit)
import UIKit
import Foundation
import AVFoundation
import Photos
import CoreLocation
import UserNotifications
import AddressBook
import Contacts
import EventKit

// MARK: - LSAuthorization

/// 权限管理工具
public enum LSAuthorization {

    // MARK: - 权限类型

    /// 权限类型
    public enum PermissionType {
        case camera               // 相机
        case photoLibrary         // 相册
        case microphone           // 麦克风
        case location             // 定位
        case locationAlways       // 始终定位
        case notifications        // 通知
        case contacts             // 通讯录
        case events               // 日历
        case reminders            // 提醒事项
    }

    /// 权限状态
    public enum Status {
        case authorized           // 已授权
        case denied               // 已拒绝
        case notDetermined        // 未确定
        case restricted           // 受限（如家长控制）
    }

    // MARK: - 相机权限

    /// 相机权限状态
    public static func cameraAuthorizationStatus() -> Status {
        #if !targetEnvironment(simulator)
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
        #else
        return .authorized // 模拟器默认授权
        #endif
    }

    /// 请求相机权限
    ///
    /// - Parameter completion: 完成回调
    public static func requestCameraPermission(completion: @escaping (Status) -> Void) {
        #if !targetEnvironment(simulator)
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                completion(granted ? .authorized : .denied)
            }
        }
        #else
        completion(.authorized)
        #endif
    }

    // MARK: - 相册权限

    /// 相册权限状态
    public static func photoLibraryAuthorizationStatus() -> Status {
        let status: PHAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        } else {
            status = PHPhotoLibrary.authorizationStatus()
        }

        switch status {
        case .authorized, .limited:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }

    /// 请求相册权限
    ///
    /// - Parameter completion: 完成回调
    public static func requestPhotoLibraryPermission(completion: @escaping (Status) -> Void) {
        if #available(iOS 14.0, *) {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async {
                    switch status {
                    case .authorized, .limited:
                        completion(.authorized)
                    case .denied, .restricted:
                        completion(.denied)
                    case .notDetermined:
                        completion(.notDetermined)
                    @unknown default:
                        completion(.denied)
                    }
                }
            }
        } else {
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    switch status {
                    case .authorized:
                        completion(.authorized)
                    case .denied, .restricted:
                        completion(.denied)
                    case .notDetermined:
                        completion(.notDetermined)
                    @unknown default:
                        completion(.denied)
                    }
                }
            }
        }
    }

    // MARK: - 麦克风权限

    /// 麦克风权限状态
    public static func microphoneAuthorizationStatus() -> Status {
        #if !targetEnvironment(simulator)
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .authorized:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
        #else
        return .authorized
        #endif
    }

    /// 请求麦克风权限
    ///
    /// - Parameter completion: 完成回调
    public static func requestMicrophonePermission(completion: @escaping (Status) -> Void) {
        #if !targetEnvironment(simulator)
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async {
                completion(granted ? .authorized : .denied)
            }
        }
        #else
        completion(.authorized)
        #endif
    }

    // MARK: - 定位权限

    /// 定位权限状态
    public static func locationAuthorizationStatus() -> Status {
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }

    /// 始终定位权限状态
    public static func locationAlwaysAuthorizationStatus() -> Status {
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .authorizedAlways:
            return .authorized
        case .authorizedWhenInUse, .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }

    /// 请求定位权限
    ///
    /// - Parameters:
    ///   - always: 是否请求始终定位
    ///   - completion: 完成回调
    public static func requestLocationPermission(always: Bool = false, completion: @escaping (Status) -> Void) {
        guard CLLocationManager.locationServicesEnabled() else {
            completion(.denied)
            return
        }

        let manager = CLLocationManager()

        if always {
            if #available(iOS 13.0, *) {
                // iOS 13+ 需要分步请求
                if manager.authorizationStatus == .notDetermined {
                    manager.requestWhenInUseAuthorization()
                    // 延迟请求 always
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        manager.requestAlwaysAuthorization()
                    }
                } else if manager.authorizationStatus == .authorizedWhenInUse {
                    manager.requestAlwaysAuthorization()
                }
            } else {
                manager.requestAlwaysAuthorization()
            }
        } else {
            manager.requestWhenInUseAuthorization()
        }

        // 延迟检查结果
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let status = always ? locationAlwaysAuthorizationStatus() : locationAuthorizationStatus()
            completion(status)
        }
    }

    // MARK: - 通知权限

    /// 通知权限状态
    public static func notificationAuthorizationStatus() -> Status {
        if #available(iOS 10.0, *) {
            let settings = UNUserNotificationCenter.current().notificationSettings
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                return .authorized
            case .denied:
                return .denied
            case .notDetermined:
                return .notDetermined
            @unknown default:
                return .denied
            }
        } else {
            return .notDetermined
        }
    }

    /// 请求通知权限
    ///
    /// - Parameter completion: 完成回调
    public static func requestNotificationPermission(completion: @escaping (Status) -> Void) {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted in
                DispatchQueue.main.async {
                    completion(granted ? .authorized : .denied)
                }
            }
        } else {
            completion(.notDetermined)
        }
    }

    // MARK: - 通讯录权限

    /// 通讯录权限状态
    public static func contactsAuthorizationStatus() -> Status {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        switch status {
        case .authorized:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }

    /// 请求通讯录权限
    ///
    /// - Parameter completion: 完成回调
    public static func requestContactsPermission(completion: @escaping (Status) -> Void) {
        CNContactStore().requestAccess(for: .contacts) { granted, error in
            DispatchQueue.main.async {
                completion(granted ? .authorized : .denied)
            }
        }
    }

    // MARK: - 日历权限

    /// 日历权限状态
    public static func eventsAuthorizationStatus() -> Status {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .authorized:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }

    /// 请求日历权限
    ///
    /// - Parameter completion: 完成回调
    public static func requestEventsPermission(completion: @escaping (Status) -> Void) {
        let store = EKEventStore()
        store.requestAccess(to: .event) { granted, error in
            DispatchQueue.main.async {
                completion(granted ? .authorized : .denied)
            }
        }
    }

    // MARK: - 通用权限请求

    /// 请求指定类型权限
    ///
    /// - Parameters:
    ///   - type: 权限类型
    ///   - completion: 完成回调
    public static func request(_ type: PermissionType, completion: @escaping (Status) -> Void) {
        switch type {
        case .camera:
            requestCameraPermission(completion: completion)
        case .photoLibrary:
            requestPhotoLibraryPermission(completion: completion)
        case .microphone:
            requestMicrophonePermission(completion: completion)
        case .location:
            requestLocationPermission(always: false, completion: completion)
        case .locationAlways:
            requestLocationPermission(always: true, completion: completion)
        case .notifications:
            requestNotificationPermission(completion: completion)
        case .contacts:
            requestContactsPermission(completion: completion)
        case .events:
            requestEventsPermission(completion: completion)
        case .reminders:
            // 提醒事项使用相同的权限
            requestEventsPermission(completion: completion)
        }
    }

    /// 获取指定类型权限状态
    ///
    /// - Parameter type: 权限类型
    /// - Returns: 权限状态
    public static func status(for type: PermissionType) -> Status {
        switch type {
        case .camera:
            return cameraAuthorizationStatus()
        case .photoLibrary:
            return photoLibraryAuthorizationStatus()
        case .microphone:
            return microphoneAuthorizationStatus()
        case .location:
            return locationAuthorizationStatus()
        case .locationAlways:
            return locationAlwaysAuthorizationStatus()
        case .notifications:
            return notificationAuthorizationStatus()
        case .contacts:
            return contactsAuthorizationStatus()
        case .events:
            return eventsAuthorizationStatus()
        case .reminders:
            return eventsAuthorizationStatus()
        }
    }

    // MARK: - 系统设置跳转

    /// 打开系统设置页面
    ///
    /// - Parameter type: 权限类型（用于跳转到具体设置页）
    public static func openSettings(for type: PermissionType? = nil) {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    /// 检查并提示开启权限
    ///
    /// - Parameters:
    ///   - type: 权限类型
    ///   - message: 提示消息
    ///   - completion: 完成回调
    public static func checkAndPrompt(
        for type: PermissionType,
        message: String? = nil,
        completion: ((Bool) -> Void)? = nil
    ) {
        let status = self.status(for: type)

        switch status {
        case .authorized:
            completion?(true)
        case .notDetermined:
            request(type) { newStatus in
                completion?(newStatus == .authorized)
            }
        case .denied, .restricted:
            let alertMessage = message ?? "请在设置中开启相应权限"
            // 显示提示对话框
            if let topVC = UIApplication.shared.topViewController() {
                let alert = UIAlertController(
                    title: "需要权限",
                    message: alertMessage,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in
                    completion?(false)
                })
                alert.addAction(UIAlertAction(title: "去设置", style: .default) { _ in
                    LSAuthorization.openSettings(for: type)
                    completion?(false)
                })
                topVC.present(alert, animated: true)
            } else {
                completion?(false)
            }
        }
    }

    // MARK: - 批量权限请求

    /// 批量请求权限
    ///
    /// - Parameters:
    ///   - types: 权限类型数组
    ///   - completion: 完成回调（返回每种权限的状态）
    public static func requestPermissions(
        _ types: [PermissionType],
        completion: @escaping ([PermissionType: Status]) -> Void
    ) {
        let group = DispatchGroup()
        var results: [PermissionType: Status] = [:]
        let lock = NSLock()

        for type in types {
            group.enter()
            request(type) { status in
                lock.lock()
                results[type] = status
                lock.unlock()
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(results)
        }
    }
}

// MARK: - UIApplication Extension

extension UIApplication {

    /// 获取最顶层的视图控制器
    static func topViewController(_ base: UIViewController? = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return topViewController(tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return topViewController(presented)
        }
        return base
    }
}

#endif

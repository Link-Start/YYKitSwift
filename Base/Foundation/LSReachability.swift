//
//  LSReachability.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  网络可达性检测工具
//

#if canImport(UIKit)
import UIKit
import Foundation
import SystemConfiguration

// MARK: - LSReachability

/// 网络可达性状态
public enum LSReachabilityStatus: Equatable {
    case notReachable          // 不可达
    case wwan(Status)          // 蜂窝网络
    case wifi                  // Wi-Fi

    /// 蜂窝网络状态
    public enum Status {
        case unknown
        case gprs2G            // 2G
        case edge3G            // EDGE
        case wcdma3G           // 3G
        case hsdpa3G           // HSDPA
        case lte4G             // 4G
    }

    /// 是否可达
    public var isReachable: Bool {
        if case .notReachable = self { return false }
        return true
    }
}

/// 网络可达性管理器
public class LSReachability: NSObject {

    // MARK: - 单例

    /// 共享实例
    public static let shared = LSReachability()

    // MARK: - 属性

    /// 当前状态
    public private(set) var status: LSReachabilityStatus = .unknown {
        didSet {
            guard oldValue != status else { return }
            postNotification()
        }
    }

    /// 之前的漫游状态
    private var previousReachabilityFlags: SCNetworkReachabilityFlags?

    /// 可达性引用
    private var reachability: SCNetworkReachability?

    /// 回调队列
    private let callbackQueue = DispatchQueue(label: "com.xiaoyueyun.reachability")

    // MARK: - 回调

    /// 状态变化回调
    public typealias StatusChangeHandler = (LSReachabilityStatus) -> Void

    /// 回调列表
    private var handlers: [String: StatusChangeHandler] = [:]

    // MARK: - 初始化

    private override init() {
        super.init()
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - 监控

    /// 开始监控
    public func startMonitoring() {
        guard reachability == nil else { return }

        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)

        reachability = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, $0)
            }
        }

        guard let reachability = reachability else { return }

        var context = SCNetworkReachabilityContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        SCNetworkReachabilitySetCallback(
            reachability,
            { (_, flags, info) in
                guard let info = info else { return }
                let reachability = Unmanaged<LSReachability>.fromOpaque(info).takeUnretainedValue()
                reachability.reachabilityChanged(flags: flags)
            },
            &context
        )

        SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)

        // 初始检查
        var flags = SCNetworkReachabilityFlags()
        SCNetworkReachabilityGetFlags(reachability, &flags)
        reachabilityChanged(flags: flags)
    }

    /// 停止监控
    public func stopMonitoring() {
        guard let reachability = reachability else { return }

        SCNetworkReachabilityUnscheduleFromRunLoop(reachability, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
        self.reachability = nil
    }

    // MARK: - 状态变化

    private func reachabilityChanged(flags: SCNetworkReachabilityFlags) {
        // 避免重复调用
        guard previousReachabilityFlags != flags else { return }
        previousReachabilityFlags = flags

        let newStatus = calculateStatus(from: flags)

        DispatchQueue.main.async { [weak self] in
            self?.status = newStatus
        }
    }

    private func calculateStatus(from flags: SCNetworkReachabilityFlags) -> LSReachabilityStatus {
        guard flags.contains(.reachable) else {
            return .notReachable
        }

        // 检查是否需要连接
        if !flags.contains(.connectionRequired) {
            return .wifi
        }

        // 检查是否为 WWAN
        if flags.contains(.isWWAN) {
            return .wwan(detectWWANStatus())
        }

        // 检查是否为自动连接
        if !flags.contains(.connectionOnDemand) && !flags.contains(.connectionOnTraffic) {
            return .notReachable
        }

        // 检查是否可以自动建立连接
        if flags.contains(.interventionRequired) {
            return .notReachable
        }

        return .wifi
    }

    private func detectWWANStatus() -> LSReachabilityStatus.Status {
        // 使用 Core Telephony 检测详细状态
        #if canImport(CoreTelephony)
        import CoreTelephony

        let networkInfo = CTTelephonyNetworkInfo()
        let carrierType = networkInfo.serviceSubscriberCellularProviders?.values.first?.radioAccessTechnology

        switch carrierType {
        case CTRadioAccessTechnologyGPRS:
            return .gprs2G
        case CTRadioAccessTechnologyEdge:
            return .edge3G
        case CTRadioAccessTechnologyWCDMA:
            return .wcdma3G
        case CTRadioAccessTechnologyHSDPA:
            return .hsdpa3G
        case CTRadioAccessTechnologyLTE:
            return .lte4G
        default:
            return .unknown
        }
        #else
        return .unknown
        #endif
    }

    // MARK: - 添加观察者

    /// 添加状态变化监听
    ///
    /// - Parameters:
    ///   - handler: 回调闭包
    /// - Returns: 观察者令牌
    @discardableResult
    public func addObserver(_ handler: @escaping StatusChangeHandler) -> String {
        let token = UUID().uuidString
        handlers[token] = handler
        return token
    }

    /// 移除观察者
    ///
    /// - Parameter token: 观察者令牌
    public func removeObserver(token: String) {
        handlers.removeValue(forKey: token)
    }

    // MARK: - 通知

    private func postNotification() {
        let notification = Notification(
            name: .LSReachabilityStatusChanged,
            object: self,
            userInfo: ["status": status]
        )

        NotificationCenter.default.post(notification)

        // 执行回调
        for handler in handlers.values {
            handler(status)
        }
    }
}

// MARK: - Notification.Name

extension Notification.Name {
    /// 网络可达性状态变化通知
    public static let LSReachabilityStatusChanged = Notification.Name("LSReachabilityStatusChanged")
}

// MARK: - SCNetworkReachabilityFlags Extension

extension SCNetworkReachabilityFlags {
    func contains(_ flag: SCNetworkReachabilityFlags) -> Bool {
        return self.intersection(flag) != []
    }
}

// MARK: - LSReachabilityStatus Extension

extension LSReachabilityStatus {
    /// 未知状态（用于初始化）
    static var unknown: LSReachabilityStatus {
        return .notReachable
    }
}

// MARK: - 便捷检查

public extension LSReachability {

    /// 是否可达
    var isReachable: Bool {
        return status.isReachable
    }

    /// 是否为 Wi-Fi
    var isReachableViaWiFi: Bool {
        if case .wifi = status { return true }
        return false
    }

    /// 是否为蜂窝网络
    var isReachableViaWWAN: Bool {
        if case .wwan = status { return true }
        return false
    }

    /// 是否为 4G
    var is4G: Bool {
        if case .wwan(let wwanStatus) = status {
            if case .lte4G = wwanStatus { return true }
        }
        return false
    }
}

// MARK: - 全局函数

/// 检查网络是否可达
public func LSIsReachable() -> Bool {
    return LSReachability.shared.isReachable
}

/// 检查是否为 Wi-Fi
public func LSIsReachableViaWiFi() -> Bool {
    return LSReachability.shared.isReachableViaWiFi
}

/// 检查是否为蜂窝网络
public func LSIsReachableViaWWAN() -> Bool {
    return LSReachability.shared.isReachableViaWWAN
}

#endif

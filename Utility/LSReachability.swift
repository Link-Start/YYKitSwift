//
//  LSReachability.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  网络状态监听 - 基于 SystemConfiguration 框架
//

#if canImport(UIKit)
import UIKit
import Foundation
import SystemConfiguration
import CoreTelephony

/// 网络状态枚举
public enum LSReachabilityStatus: UInt {
    case none = 0   // 不可达
    case wwan = 1   // WWAN (2G/3G/4G/5G)
    case wifi = 2   // WiFi
}

/// WWAN 网络类型枚举
public enum LSReachabilityWWANStatus: UInt {
    case none = 0   // 不可达
    case _2G = 2    // 2G (GPRS/EDGE) 10~100Kbps
    case _3G = 3    // 3G (WCDMA/HSDPA/...) 1~10Mbps
    case _4G = 4    // 4G (eHRPD/LTE) 100Mbps
    case _5G = 5    // 5G (NR) 1Gbps+
}

/// LSReachability 用于监听 iOS 设备的网络状态
public class LSReachability: NSObject {

    // MARK: - 属性

    /// 当前网络标志（只读）
    public private(set) var flags: SCNetworkReachabilityFlags = 0

    /// 当前网络状态（只读）
    public private(set) var status: LSReachabilityStatus = .none

    /// 当前 WWAN 状态（只读，iOS 7+）
    public private(set) var wwanStatus: LSReachabilityWWANStatus = .none

    /// 当前是否可达（只读）
    public var isReachable: Bool {
        return status != .none
    }

    /// 网络变化通知块，在主线程调用
    public var notifyBlock: ((LSReachability) -> Void)? {
        didSet {
            scheduled = (notifyBlock != nil)
        }
    }

    // MARK: - 内部属性

    private var ref: SCNetworkReachability?
    private var scheduled = false
    private var allowWWAN = true
    private var networkInfo: CTTelephonyNetworkInfo?

    // MARK: - 共享队列

    private static let sharedQueue: DispatchQueue = {
        DispatchQueue(label: "com.xiaoyueyun.yykitswift.reachability", attributes: .serial)
    }()

    // MARK: - 初始化

    /// 创建默认路由的可达性监听对象
    public convenience override init() {
        /*
         See Apple's Reachability implementation and readme:
         The address 0.0.0.0, which reachability treats as a special token that
         causes it to actually monitor the general routing status of the device,
         both IPv4 and IPv6.
         https://developer.apple.com/library/ios/samplecode/Reachability/Listings/ReadMe_md.html#//apple_ref/doc/uid/DTS40007324-ReadMe_md-DontLinkElementID_11
         */
        var zeroAddr = sockaddr_in()
        bzero(&zeroAddr, MemoryLayout<sockaddr_in>.size)
        zeroAddr.sin_len = __uint8_t(MemoryLayout<sockaddr_in>.size)
        zeroAddr.sin_family = sa_family_t(AF_INET)

        let addressPtr = withUnsafePointer(to: &zeroAddr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { $0 }
        }

        guard let ref = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, addressPtr) else {
            fatalError("Failed to create SCNetworkReachability")
        }

        self.init(ref: ref)
    }

    /// 使用指定的 SCNetworkReachabilityRef 创建实例
    ///
    /// - Parameter ref: SCNetworkReachabilityRef
    private init(ref: SCNetworkReachability) {
        self.ref = ref
        super.init()

        if #available(iOS 7.0, *) {
            networkInfo = CTTelephonyNetworkInfo()
        }

        updateFlags()
    }

    deinit {
        notifyBlock = nil
        scheduled = false
    }

    // MARK: - 访问方法

    /// 创建默认路由的可达性监听对象
    ///
    /// - Returns: LSReachability 实例
    public static func reachability() -> LSReachability {
        return LSReachability()
    }

    /// 创建本地 WiFi 的可达性监听对象（已废弃）
    ///
    /// - Returns: LSReachability 实例
    @available(*, deprecated, message: "unnecessary and potentially harmful")
    public static func reachabilityForLocalWifi() -> LSReachability {
        var localWifiAddr = sockaddr_in()
        bzero(&localWifiAddr, MemoryLayout<sockaddr_in>.size)
        localWifiAddr.sin_len = __uint8_t(MemoryLayout<sockaddr_in>.size)
        localWifiAddr.sin_family = sa_family_t(AF_INET)
        localWifiAddr.sin_addr.s_addr = UInt32(IN_LINKLOCALNETNUM).bigEndian

        let addressPtr = withUnsafePointer(to: &localWifiAddr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { $0 }
        }

        guard let ref = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, addressPtr) else {
            fatalError("Failed to create SCNetworkReachability")
        }

        let reachability = LSReachability(ref: ref)
        reachability.allowWWAN = false
        return reachability
    }

    /// 创建指定主机名的可达性监听对象
    ///
    /// - Parameter hostname: 主机名
    /// - Returns: LSReachability 实例，失败返回 nil
    public static func reachability(withHostname hostname: String) -> LSReachability? {
        guard let ref = SCNetworkReachabilityCreateWithName(nil, hostname) else {
            return nil
        }
        return LSReachability(ref: ref)
    }

    /// 创建指定 IP 地址的可达性监听对象
    ///
    /// - Parameter hostAddress: sockaddr_in (IPv4) 或 sockaddr_in6 (IPv6)
    /// - Returns: LSReachability 实例，失败返回 nil
    public static func reachability(withAddress hostAddress: sockaddr) -> LSReachability? {
        let addressPtr = withUnsafePointer(to: hostAddress) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { $0 }
        }

        guard let ref = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, addressPtr) else {
            return nil
        }
        return LSReachability(ref: ref)
    }

    // MARK: - 私有方法

    private var scheduled: Bool {
        get {
            return scheduled
        }
        set {
            if scheduled == newValue { return }
            scheduled = newValue

            guard let ref = ref else { return }

            if scheduled {
                var context = SCNetworkReachabilityContext(
                    version: 0,
                    info: Unmanaged.passUnretained(self).toOpaque(),
                    retain: nil,
                    release: nil,
                    copyDescription: nil
                )
                SCNetworkReachabilitySetCallback(ref, { (_, flags, info) in
                    guard let info = info else { return }
                    let reachability = Unmanaged<LSReachability>.fromOpaque(info).takeUnretainedValue()
                    reachability.updateFlags()
                    if let block = reachability.notifyBlock {
                        DispatchQueue.main.async {
                            block(reachability)
                        }
                    }
                }, &context)
                SCNetworkReachabilitySetDispatchQueue(ref, Self.sharedQueue)
            } else {
                SCNetworkReachabilitySetCallback(ref, nil, nil)
                SCNetworkReachabilitySetDispatchQueue(ref, nil)
            }
        }
    }

    private func updateFlags() {
        guard let ref = ref else { return }
        var flags: SCNetworkReachabilityFlags = 0
        SCNetworkReachabilityGetFlags(ref, &flags)
        self.flags = flags
        self.status = Self.statusFromFlags(flags, allowWWAN: allowWWAN)
        self.wwanStatus = Self.wwanStatusFromFlags(flags)
    }

    private static func statusFromFlags(_ flags: SCNetworkReachabilityFlags, allowWWAN: Bool) -> LSReachabilityStatus {
        if flags.contains(.reachable) == false {
            return .none
        }

        if flags.contains(.connectionRequired) && flags.contains(.transientConnection) {
            return .none
        }

        if flags.contains(.isWWAN) && allowWWAN {
            return .wwan
        }

        return .wifi
    }

    private static func wwanStatusFromFlags(_ flags: SCNetworkReachabilityFlags) -> LSReachabilityWWANStatus {
        #if !targetEnvironment(simulator)
        if #available(iOS 7.0, *) {
            let networkInfo = CTTelephonyNetworkInfo()
            if let status = networkInfo.serviceCurrentRadioAccessTechnology {
                return wwanStatusFromRadioTechnology(status)
            }
        }
        #endif
        return .none
    }

    private static func wwanStatusFromRadioTechnology(_ radioTech: String) -> LSReachabilityWWANStatus {
        let radioMap: [String: LSReachabilityWWANStatus] = [
            // 2G
            CTRadioAccessTechnologyGPRS: ._2G,          // 2.5G  171Kbps
            CTRadioAccessTechnologyEdge: ._2G,          // 2.75G 384Kbps
            CTRadioAccessTechnologyCDMA1x: ._3G,        // 2.5G

            // 3G
            CTRadioAccessTechnologyWCDMA: ._3G,         // 3G
            CTRadioAccessTechnologyHSDPA: ._3G,         // 3.5G
            CTRadioAccessTechnologyHSUPA: ._3G,         // 3.75G
            CTRadioAccessTechnologyCDMAEVDORev0: ._3G,
            CTRadioAccessTechnologyCDMAEVDORevA: ._3G,
            CTRadioAccessTechnologyCDMAEVDORevB: ._3G,
            CTRadioAccessTechnologyeHRPD: ._3G,

            // 4G
            CTRadioAccessTechnologyLTE: ._4G            // LTE: 3.9G
        ]

        // 5G 检测 (iOS 14+)
        if #available(iOS 14.0, *) {
            if radioTech == CTRadioAccessTechnologyNR {
                return ._5G
            }
        }

        if let networkType = radioMap[radioTech] {
            return networkType
        }
        return .none
    }
}

// MARK: - SCNetworkReachabilityFlags Extension

private extension SCNetworkReachabilityFlags {
    func contains(_ flag: SCNetworkReachabilityFlags) -> Bool {
        return self.contains(flag)
    }
}
#endif

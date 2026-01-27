//
//  LSApplication.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  应用信息工具 - 获取应用和设备相关信息
//

#if canImport(UIKit)
import UIKit
import Foundation
import AdSupport

// MARK: - LSApplication

/// 应用信息工具类
public enum LSApplication {

    // MARK: - 应用信息

    /// 应用名称
    public static var appName: String {
        return Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
            ?? Bundle.main.infoDictionary?["CFBundleName"] as? String
            ?? "Unknown"
    }

    /// 应用 Bundle ID
    public static var bundleIdentifier: String {
        return Bundle.main.bundleIdentifier ?? ""
    }

    /// 应用版本号
    public static var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    /// 应用 Build 版本
    public static var buildVersion: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    }

    /// 完整版本信息（版本 + Build）
    public static var fullVersion: String {
        return "\(appVersion)(\(buildVersion))"
    }

    /// 应用图标
    public static var appIcon: UIImage? {
        guard let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
              let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
              let iconName = iconFiles.last else {
            return nil
        }

        return UIImage(named: iconName)
    }

    /// 应用启动图
    public static var launchImage: UIImage? {
        let launchImages = [
            "LaunchImage", "Default", "LaunchScreen"
        ]

        for name in launchImages {
            if let image = UIImage(named: name) {
                return image
            }
        }

        // 尝试从 LaunchStoryboard 获取
        guard let launchScreenStoryboard = UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateInitialViewController() else {
            return nil
        }

        return launchScreenViewControllerToImage(launchScreenStoryboard)
    }

    // MARK: - 设备信息

    /// 设备名称
    public static var deviceName: String {
        return UIDevice.current.name
    }

    /// 设备型号
    public static var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value))!)
        }
        return identifier
    }

    /// 设备型号描述
    public static var deviceModelDescription: String {
        let model = deviceModel

        // iPhone
        if model.hasPrefix("iPhone") {
            let version = model.replacingOccurrences(of: "iPhone", with: "")
            return "iPhone" + iPhoneVersion(version)
        }

        // iPad
        if model.hasPrefix("iPad") {
            let version = model.replacingOccurrences(of: "iPad", with: "")
            return "iPad" + iPadVersion(version)
        }

        // iPod
        if model.hasPrefix("iPod") {
            return "iPod Touch"
        }

        // Apple Watch
        if model.hasPrefix("Watch") {
            return "Apple Watch"
        }

        // Apple TV
        if model.hasPrefix("AppleTV") {
            return "Apple TV"
        }

        // Simulator
        if model == "i386" || model == "x86_64" || model.hasPrefix("arm64") {
            return "Simulator"
        }

        return model
    }

    /// 系统名称
    public static var systemName: String {
        return UIDevice.current.systemName
    }

    /// 系统版本
    public static var systemVersion: String {
        return UIDevice.current.systemVersion
    }

    /// 系统版本号（浮点数）
    public static var systemVersionFloat: CGFloat {
        return CGFloat(systemVersion) ?? 0
    }

    /// 是否越狱
    public static var isJailbroken: Bool {
        #if TARGET_IPHONE_SIMULATOR
        return false
        #else

        // 检查常见越狱文件
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/cydia.py",
            "/usr/bin/sshd"
        ]

        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }

        // 检查能否打开 cydia URL
        if let url = URL(string: "cydia://") {
            if UIApplication.shared.canOpenURL(url) {
                return true
            }
        }

        // 检查能否写入系统目录
        let string = "test"
        do {
            try string.write(toFile: "/private/jailbreak_test.txt", atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: "/private/jailbreak_test.txt")
            return true
        } catch {
            return false
        }

        #endif
    }

    // MARK: - 内存信息

    /// 可用内存
    public static var availableMemory: UInt64 {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else { return 0 }

        let pageSize = vm_kernel_page_size
        return UInt64(stats.free_count + stats.inactive_count) * UInt64(pageSize)
    }

    /// 已用内存
    public static var usedMemory: UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        guard kerr == KERN_SUCCESS else { return 0 }
        return info.resident_size
    }

    /// 总内存
    public static var totalMemory: UInt64 {
        return ProcessInfo.processInfo.physicalMemory
    }

    // MARK: - 磁盘信息

    /// 可用磁盘空间
    public static var availableDiskSpace: Int64 {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            return attributes[.systemFreeSize] as? Int64 ?? 0
        } catch {
            return 0
        }
    }

    /// 总磁盘空间
    public static var totalDiskSpace: Int64 {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            return attributes[.systemSize] as? Int64 ?? 0
        } catch {
            return 0
        }
    }

    /// 已用磁盘空间
    public static var usedDiskSpace: Int64 {
        return totalDiskSpace - availableDiskSpace
    }

    // MARK: - 网络

    /// IPv4 地址
    public static var ipAddressIPv4: String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return nil
        }

        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            guard let interface = ptr.pointee else { continue }

            let addrFamily = interface.ifa_addr.pointee.sa_family

            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" { // WiFi
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(
                        interface.ifa_addr,
                        socklen_t(interface.ifa_addr.pointee.sa_len),
                        &hostname,
                        socklen_t(hostname.count),
                        nil,
                        socklen_t(0),
                        NI_NUMERICHOST
                    )
                    address = String(cString: hostname)
                }
            }
        }

        return address
    }

    /// MAC 地址
    public static var macAddress: String? {
        #if targetEnvironment(simulator)
        return "02:00:00:00:00:00"
        #else

        var managementInfoBase = [CTL_NET, AF_ROUTE, 0, AF_LINK, NET_RT_IFLIST, if_nametoindex("en0")]
        var len: Int = 0

        sysctl(&managementInfoBase, UInt32(managementInfoBase.count), nil, &len, nil, 0)

        var buffer = [UInt8](repeating: 0, count: len)
        sysctl(&managementInfoBase, UInt32(managementInfoBase.count), &buffer, &len, nil, 0)

        let info = buffer.withUnsafeBytes {
            $0.load(as: if_msghdr.self)
        }

        let offset = MemoryLayout<if_msghdr>.stride
        guard let ifm = buffer.withUnsafeBytes({ $0.baseAddress?.advanced(by: offset)?.assumingMemoryBound(to: if_data.self).pointee }) else {
            return nil
        }

        let macAddress = withUnsafePointer(to: ifm.ifi_mac) {
            $0.withMemoryRebound(to: UInt8.self, capacity: 6) {
                String(format: "%02X:%02X:%02X:%02X:%02X:%02X",
                        $0[0], $0[1], $0[2], $0[3], $0[4], $0[5])
            }
        }

        return macAddress
        #endif
    }

    // MARK: - 标识符

    /// IDFV (Identifier for Vendor)
    public static var idfv: String? {
        return UIDevice.current.identifierForVendor?.uuidString
    }

    /// IDFA (Identifier for Advertising)
    public static var idfa: String? {
        guard ASIdentifierManager.shared().isAdvertisingTrackingEnabled else {
            return nil
        }
        return ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }

    /// UUID（应用沙盒唯一标识）
    public static var uuid: String {
        let key = "LSApplication_UUID"

        if let uuid = UserDefaults.standard.string(forKey: key) {
            return uuid
        }

        let newUUID = UUID().uuidString
        UserDefaults.standard.set(newUUID, forKey: key)
        return newUUID
    }

    // MARK: - 语言和地区

    /// 当前语言
    public static var language: String {
        return Locale.current.languageCode ?? "en"
    }

    /// 当前地区
    public static var region: String {
        return Locale.current.regionCode ?? "US"
    }

    /// 语言代码（如 zh-Hans）
    public static var currentLanguage: String {
        return Locale.current.identifier
    }

    /// 是否中国
    public static var isChina: Bool {
        return region == "CN"
    }

    // MARK: - 应用状态

    /// 是否在后台
    public static var isInBackground: Bool {
        return UIApplication.shared.applicationState == .background
    }

    /// 是否在前台
    public static var isInForeground: Bool {
        return UIApplication.shared.applicationState == .active
    }

    /// 应用状态
    public static var applicationState: UIApplication.State {
        return UIApplication.shared.applicationState
    }

    // MARK: - 通知权限

    /// 通知权限状态
    public static var notificationAuthorizationStatus: UNAuthorizationStatus {
        if #available(iOS 10.0, *) {
            var options: UNAuthorizationOptions = [.alert, .sound, .badge]
            return UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        }
        return .notDetermined
    }

    /// 请求通知权限
    public static func requestNotificationAuthorization(completion: @escaping (Bool) -> Void) {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        }
    }

    // MARK: - App Store 信息

    /// 在 App Store 中打开应用
    ///
    /// - Parameter appId: App ID
    public static func openInAppStore(appId: String) {
        let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appId)") ??
                  URL(string: "https://apps.apple.com/app/id\(appId)")

        if let url = url {
            UIApplication.shared.open(url)
        }
    }

    /// 获取 App Store 上的应用版本号
    ///
    /// - Parameter appId: App ID
    /// - Parameter completion: 完成回调
    public static func fetchAppStoreVersion(appId: String, completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://itunes.apple.com/lookup?id=\(appId)")!

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let results = json["results"] as? [[String: Any]],
                  let version = results.first?["version"] as? String else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            DispatchQueue.main.async {
                completion(version)
            }
        }.resume()
    }

    /// 检查是否有新版本
    ///
    /// - Parameter appId: App ID
    /// - Parameter completion: 完成回调（有新版本时返回新版本号，否则返回 nil）
    public static func checkForUpdate(appId: String, completion: @escaping (String?) -> Void) {
        fetchAppStoreVersion(appId: appId) { storeVersion in
            guard let storeVersion = storeVersion else {
                completion(nil)
                return
            }

            let currentVersion = appVersion
            if storeVersion != currentVersion {
                completion(storeVersion)
            } else {
                completion(nil)
            }
        }
    }

    // MARK: - 辅助方法

    private static func iPhoneVersion(_ version: String) -> String {
        let number = (version as NSString).integerValue

        switch number {
        case 14...16: return "14 Pro" // 示例，实际需要更详细的映射
        case 10...13: return "12"
        case 8...9: return "11"
        case 6...7: return "XS/X"
        case 5...6: return "10"
        case 4...5: return "9"
        case 3...4: return "8"
        case 2...3: return "7"
        default: return ""
        }
    }

    private static func iPadVersion(_ version: String) -> String {
        let number = (version as NSString).integerValue

        switch number {
        case 13...14: return "Air 4"
        case 11...12: return "Pro 11"
        case 8...10: return "Pro 12.9"
        case 6...7: return "Pro 10.5"
        default: return ""
        }
    }

    private static func launchScreenViewControllerToImage(_ viewController: UIViewController) -> UIImage? {
        let size = viewController.view.bounds.size
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }

        viewController.view.drawHierarchy(in: viewController.view.bounds, afterScreenUpdates: true)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

// MARK: - Bundle Extension

public extension Bundle {

    /// 应用名称
    var ls_appName: String {
        return infoDictionary?["CFBundleDisplayName"] as? String
            ?? infoDictionary?["CFBundleName"] as? String
            ?? "Unknown"
    }

    /// 应用版本号
    var ls_appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    /// Build 版本
    var ls_buildVersion: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? ""
    }

    /// Bundle ID
    var ls_bundleIdentifier: String {
        return bundleIdentifier ?? ""
    }
}

#endif

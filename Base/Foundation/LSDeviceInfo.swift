//
//  LSDeviceInfo.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  设备信息工具 - 获取设备硬件和系统信息
//

#if canImport(UIKit)
import UIKit
import Foundation

// MARK: - LSDeviceInfo

/// 设备信息工具
public enum LSDeviceInfo {

    // MARK: - 设备型号

    /// 设备型号
    public static var machineModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    /// 设备名称（可读）
    public static var machineModelName: String {
        let model = machineModel
        switch model {
        // iPhone
        case "iPhone14,2": return "iPhone 13 Pro"
        case "iPhone14,3": return "iPhone 13 Pro Max"
        case "iPhone14,4": return "iPhone 13 mini"
        case "iPhone14,5": return "iPhone 13"
        case "iPhone14,6": return "iPhone SE (3rd generation)"
        case "iPhone14,7": return "iPhone 14"
        case "iPhone14,8": return "iPhone 14 Plus"
        case "iPhone15,2": return "iPhone 14 Pro"
        case "iPhone15,3": return "iPhone 14 Pro Max"
        case "iPhone15,4": return "iPhone 15"
        case "iPhone15,5": return "iPhone 15 Plus"
        case "iPhone16,1": return "iPhone 15 Pro"
        case "iPhone16,2": return "iPhone 15 Pro Max"

        // iPad
        case "iPad13,16", "iPad13,17": return "iPad Air (5th generation)"
        case "iPad13,18", "iPad13,19": return "iPad (10th generation)"
        case "iPad14,1", "iPad14,2": return "iPad mini (6th generation)"
        case "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7": return "iPad Pro 11-inch (4th generation)"
        case "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11": return "iPad Pro 12.9-inch (6th generation)"
        case "iPad14,5", "iPad14,6": return "iPad Air (5th generation)"
        case "iPad14,8", "iPad14,9", "iPad14,10", "iPad14,11": return "iPad Pro 11-inch (4th generation)"
        case "iPad14,12", "iPad14,13", "iPad14,14", "iPad14,15": return "iPad Pro 12.9-inch (6th generation)"

        // Simulator
        case "i386", "x86_64", "arm64": return "Simulator"

        default:
            return model
        }
    }

    /// 是否为模拟器
    public static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    /// 是否为真机
    public static var isDevice: Bool {
        return !isSimulator
    }

    // MARK: - 设备类型

    /// 是否为 iPhone
    public static var isPhone: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }

    /// 是否为 iPad
    public static var isPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }

    /// 是否为 Mac
    public static var isMac: Bool {
        #if os(macOS)
        return true
        #else
        return UIDevice.current.userInterfaceIdiom == .mac
        #endif
    }

    /// 是否为 CarPlay
    public static var isCarPlay: Bool {
        return UIDevice.current.userInterfaceIdiom == .carPlay
    }

    /// 是否为 TV
    public static var isTV: Bool {
        return UIDevice.current.userInterfaceIdiom == .tv
    }

    // MARK: - 屏幕信息

    /// 屏幕尺寸
    public static var screenSize: CGSize {
        return UIScreen.main.bounds.size
    }

    /// 屏幕宽度
    public static var screenWidth: CGFloat {
        return screenSize.width
    }

    /// 屏幕高度
    public static var screenHeight: CGFloat {
        return screenSize.height
    }

    /// 状态栏高度
    public static var statusBarHeight: CGFloat {
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.windows.first
            return window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            return UIApplication.shared.statusBarFrame.height
        }
    }

    /// 安全区域顶部
    public static var safeAreaTop: CGFloat {
        if #available(iOS 11.0, *) {
            let window = UIApplication.shared.windows.first
            return window?.safeAreaInsets.top ?? 0
        }
        return 0
    }

    /// 安全区域底部
    public static var safeAreaBottom: CGFloat {
        if #available(iOS 11.0, *) {
            let window = UIApplication.shared.windows.first
            return window?.safeAreaInsets.bottom ?? 0
        }
        return 0
    }

    /// 是否为刘海屏
    public static var hasNotch: Bool {
        if #available(iOS 11.0, *) {
            return safeAreaTop > 20
        }
        return false
    }

    /// 屏幕比例
    public static var screenScale: CGFloat {
        return UIScreen.main.scale
    }

    /// 是否为 Retina 屏幕
    public static var isRetina: Bool {
        return screenScale >= 2.0
    }

    /// 是否为 ProMotion 屏幕（120Hz）
    public static var hasProMotion: Bool {
        if #available(iOS 10.3, *) {
            return UIScreen.main.maximumFramesPerSecond > 60
        }
        return false
    }

    // MARK: - 应用信息

    /// 应用名称
    public static var appName: String {
        return Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
            ?? Bundle.main.infoDictionary?["CFBundleName"] as? String
            ?? ""
    }

    /// 应用版本号
    public static var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    /// 应用构建号
    public static var appBuild: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    }

    /// 应用 Bundle ID
    public static var appBundleIdentifier: String {
        return Bundle.main.bundleIdentifier ?? ""
    }

    /// 应用完整版本（版本号+构建号）
    public static var appFullVersion: String {
        return "\(appVersion) (\(appBuild))"
    }

    // MARK: - 系统信息

    /// 系统名称
    public static var systemName: String {
        return UIDevice.current.systemName
    }

    /// 系统版本
    public static var systemVersion: String {
        return UIDevice.current.systemVersion
    }

    /// 系统版本号（浮点数）
    public static var systemVersionNumber: Float {
        return Float(systemVersion) ?? 0
    }

    /// iOS 版本是否大于等于指定版本
    public static func isSystemVersion(atLeast version: Float) -> Bool {
        return systemVersionNumber >= version
    }

    // MARK: - 内存信息

    /// 总内存大小（字节）
    public static var totalMemory: UInt64 {
        return ProcessInfo.processInfo.physicalMemory
    }

    /// 总内存大小（格式化）
    public static var totalMemoryString: String {
        return ByteCountFormatter.string(fromByteCount: Int64(totalMemory))
    }

    /// 可用内存大小（字节）
    public static var availableMemory: UInt64 {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        if result == KERN_SUCCESS {
            let pageSize = UInt64(vm_page_size)
            return UInt64(stats.free_count + stats.inactive_count) * pageSize
        }

        return 0
    }

    /// 可用内存大小（格式化）
    public static var availableMemoryString: String {
        return ByteCountFormatter.string(fromByteCount: Int64(availableMemory))
    }

    /// 内存使用率
    public static var memoryUsageRatio: Double {
        guard totalMemory > 0 else { return 0 }
        return 1.0 - Double(availableMemory) / Double(totalMemory)
    }

    // MARK: - 磁盘信息

    /// 总磁盘空间（字节）
    public static var totalDiskSpace: Int64 {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            return attributes[.systemSize] as? Int64 ?? 0
        } catch {
            return 0
        }
    }

    /// 总磁盘空间（格式化）
    public static var totalDiskSpaceString: String {
        return ByteCountFormatter.string(fromByteCount: totalDiskSpace)
    }

    /// 可用磁盘空间（字节）
    public static var freeDiskSpace: Int64 {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            return attributes[.systemFreeSize] as? Int64 ?? 0
        } catch {
            return 0
        }
    }

    /// 可用磁盘空间（格式化）
    public static var freeDiskSpaceString: String {
        return ByteCountFormatter.string(fromByteCount: freeDiskSpace)
    }

    /// 已用磁盘空间（字节）
    public static var usedDiskSpace: Int64 {
        return totalDiskSpace - freeDiskSpace
    }

    /// 已用磁盘空间（格式化）
    public static var usedDiskSpaceString: String {
        return ByteCountFormatter.string(fromByteCount: usedDiskSpace)
    }

    // MARK: - CPU 信息

    /// CPU 核心数
    public static var cpuCount: Int {
        return ProcessInfo.processInfo.processorCount
    }

    /// 活动CPU核心数
    public static var activeCPUCount: Int {
        return ProcessInfo.processInfo.activeProcessorCount
    }

    // MARK: - 电池信息

    /// 电池状态
    public static var batteryState: UIDevice.BatteryState {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return UIDevice.current.batteryState
    }

    /// 电池电量（0-1）
    public static var batteryLevel: Float {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return UIDevice.current.batteryLevel
    }

    /// 电池电量百分比
    public static var batteryPercentage: Int {
        return Int(batteryLevel * 100)
    }

    /// 是否正在充电
    public static var isCharging: Bool {
        return batteryState == .charging || batteryState == .full
    }

    /// 电池状态是否低电量
    public static var isLowPowerModeEnabled: Bool {
        if #available(iOS 9.0, *) {
            return ProcessInfo.processInfo.isLowPowerModeEnabled
        }
        return false
    }

    // MARK: - 网络信息

    /// 网络运营商信息
    public static var carrierName: String? {
        #if canImport(CoreTelephony)
        import CoreTelephony
        let networkInfo = CTTelephonyNetworkInfo()
        if let carrier = networkInfo.subscriberCellularProvider {
            return carrier.carrierName
        }
        #endif
        return nil
    }

    /// 网络类型
    public static var networkType: String? {
        #if canImport(CoreTelephony)
        import CoreTelephony
        let networkInfo = CTTelephonyNetworkInfo()
        return networkInfo.serviceSubscriberCellularProviders?.values.first?.radioAccessTechnology
        #endif
        return nil
    }

    // MARK: - 时区信息

    /// 当前时区
    public static var timeZone: TimeZone {
        return TimeZone.current
    }

    /// 时区名称
    public static var timeZoneName: String {
        return timeZone.abbreviation() ?? ""
    }

    /// 时区偏移秒数
    public static var timeZoneOffset: Int {
        return timeZone.secondsFromGMT()
    }

    // MARK: - 语言和区域

    /// 当前语言
    public static var currentLanguage: String {
        return Locale.current.language.languageCode?.identifier ?? ""
    }

    /// 系统语言列表
    public static var preferredLanguages: [String] {
        return Locale.preferredLanguages
    }

    /// 当前区域
    public static var currentRegion: String {
        return Locale.current.region?.identifier ?? ""
    }

    // MARK: - 设备方向

    /// 设备方向
    public static var deviceOrientation: UIDeviceOrientation {
        return UIDevice.current.orientation
    }

    /// 是否为横屏
    public static var isLandscape: Bool {
        return UIDevice.current.orientation.isLandscape
    }

    /// 是否为竖屏
    public static var isPortrait: Bool {
        return UIDevice.current.orientation.isPortrait
    }

    // MARK: - 其他信息

    /// 设备名称（用户设置）
    public static var deviceName: String {
        return UIDevice.current.name
    }

    /// 是否支持多任务
    public static var isMultitaskingSupported: Bool {
        return UIDevice.current.isMultitaskingSupported
    }

    /// 是否开启定位服务
    public static var locationServicesEnabled: Bool {
        return CLLocationManager.locationServicesEnabled()
    }
}

// MARK: - ByteCountFormatter Extension

private extension ByteCountFormatter {
    static func string(fromByteCount byteCount: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: byteCount)
    }
}

#endif

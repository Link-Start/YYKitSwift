//
//  LSHelper.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  通用辅助工具 - 汇集各种便捷方法
//

#if canImport(UIKit)
import UIKit
import Foundation

// MARK: - LSHelper

/// 通用辅助工具
public enum LSHelper {

    // MARK: - 应用信息

    /// 应用名称
    public static var appName: String {
        return Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
            let _temp0
            if let t =  {
                _temp0 = t
            } else {
                _temp0 = Bundle.main.infoDictionary?["CFBundleName"
            }
_temp0] as? String
            let _temp1
            if let t =  {
                _temp1 = t
            } else {
                _temp1 = ""
            }
_temp1
    }

    /// 应用版本
    public static var appVersion: String {
        if let tempValue = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return tempValue
        }
        return ""
    }

    /// 应用构建号
    public static var appBuild: String {
        if let tempValue = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return tempValue
        }
        return ""
    }

    /// 应用 Bundle ID
    public static var appBundleID: String {
        if let tempValue = Bundle.main.bundleIdentifier {
            return tempValue
        }
        return ""
    }

    // MARK: - 设备信息

    /// 设备型号
    public static var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    /// 是否为 iPad
    public static var isPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }

    /// 是否为 iPhone
    public static var isPhone: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }

    /// 是否为模拟器
    public static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

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
            let tempValue0: String
            if let temp = window?.windowScene?.statusBarManager?.statusBarFrame.height {
                tempValue0 = temp
            } else {
                tempValue0 = 0
            }
            return tempValue0
        } else {
            return UIApplication.shared.statusBarFrame.height
        }
    }

    /// 安全区域顶部
    public static var safeAreaTop: CGFloat {
        if #available(iOS 11.0, *) {
            let window = UIApplication.shared.windows.first
            if let tempValue = window?.safeAreaInsets.top {
                return tempValue
            }
            return 0
        }
        return 0
    }

    /// 安全区域底部
    public static var safeAreaBottom: CGFloat {
        if #available(iOS 11.0, *) {
            let window = UIApplication.shared.windows.first
            if let tempValue = window?.safeAreaInsets.bottom {
                return tempValue
            }
            return 0
        }
        return 0
    }

    /// 是否有刘海
    public static var hasNotch: Bool {
        return safeAreaTop > 20
    }

    // MARK: - 系统版本

    /// 系统版本
    public static var systemVersion: String {
        return UIDevice.current.systemVersion
    }

    /// 系统版本号
    public static var systemVersionNumber: Float {
        if let tempValue = Float(systemVersion) {
            return tempValue
        }
        return 0
    }

    /// iOS 版本是否大于等于指定版本
    ///
    /// - Parameter version: 版本号
    /// - Returns: 是否满足
    static func isSystemVersion(atLeast version: Float) -> Bool {
        return systemVersionNumber >= version
    }

    // MARK: - 随机数

    /// 随机整数（指定范围）
    ///
    /// - Parameters:
    ///   - min: 最小值
    ///   - max: 最大值
    /// - Returns: 随机整数
    static func randomInt(min: Int, max: Int) -> Int {
        return Int.random(in: min...max)
    }

    /// 随机浮点数（指定范围）
    ///
    /// - Parameters:
    ///   - min: 最小值
    ///   - max: 最大值
    /// - Returns: 随机浮点数
    static func randomDouble(min: Double, max: Double) -> Double {
        return Double.random(in: min...max)
    }

    /// 随机布尔值
    static var randomBool: Bool {
        return Bool.random()
    }

    /// 从数组中随机选择元素
    ///
    /// - Parameter array: 数组
    /// - Returns: 随机元素
    static func randomElement<T>(from array: [T]) -> T? {
        return array.randomElement()
    }

    /// 从数组中随机选择多个元素
    ///
    /// - Parameters:
    ///   - array: 数组
    ///   - count: 数量
    /// - Returns: 随机元素数组
    static func randomElements<T>(from array: [T], count: Int) -> [T] {
        return array.shuffled().prefix(count).map { $0 }
    }

    // MARK: - 颜色

    /// 从十六进制字符串创建颜色
    ///
    /// - Parameter hex: 十六进制字符串（如: #FF0000 或 FF0000）
    /// - Returns: 颜色
    static func color(from hex: String) -> UIColor {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexString = hexString.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }

    /// 创建随机颜色
    ///
    /// - Returns: 随机颜色
    static var randomColor: UIColor {
        return UIColor(
            red: CGFloat.random(in: 0...1),
            green: CGFloat.random(in: 0...1),
            blue: CGFloat.random(in: 0...1),
            alpha: 1.0
        )
    }

    // MARK: - 延迟执行

    /// 延迟执行
    ///
    /// - Parameters:
    ///   - delay: 延迟时间（秒）
    ///   - closure: 执行闭包
    static func delay(_ delay: TimeInterval, closure: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            closure()
        }
    }

    /// 在主线程执行
    ///
    /// - Parameter closure: 执行闭包
    static func mainThread(_ closure: @escaping () -> Void) {
        DispatchQueue.main.async {
            closure()
        }
    }

    /// 在后台线程执行
    ///
    /// - Parameter closure: 执行闭包
    static func backgroundThread(_ closure: @escaping () -> Void) {
        DispatchQueue.global(qos: .background).async {
            closure()
        }
    }

    // MARK: - 用户偏好

    /// 设置用户偏好值
    ///
    /// - Parameters:
    ///   - value: 值
    ///   - key: 键
    static func setPreference<T>(_ value: T, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
        UserDefaults.standard.synchronize()
    }

    /// 获取用户偏好值
    ///
    /// - Parameter key: 键
    /// - Returns: 值
    static func getPreference<T>(forKey key: String) -> T? {
        return UserDefaults.standard.object(forKey: key) as? T
    }

    /// 移除用户偏好值
    ///
    /// - Parameter key: 键
    static func removePreference(forKey key: String) {
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.synchronize()
    }

    // MARK: - 剪贴板

    /// 复制到剪贴板
    ///
    /// - Parameter text: 文本
    static func copyToClipboard(_ text: String) {
        #if !os(tvOS)
        UIPasteboard.general.string = text
        #endif
    }

    /// 从剪贴板粘贴
    ///
    /// - Returns: 剪贴板内容
    static func pasteFromClipboard() -> String? {
        #if !os(tvOS)
        return UIPasteboard.general.string
        #else
        return nil
        #endif
    }

    // MARK: - URL 和网络

    /// 打开 URL
    ///
    /// - Parameter urlString: URL 字符串
    /// - Returns: 是否成功
    @discardableResult
    static func openURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return openURL(url)
    }

    /// 打开 URL
    ///
    /// - Parameter url: URL
    /// - Returns: 是否成功
    @discardableResult
    static func openURL(_ url: URL) -> Bool {
        if #available(iOS 10.0, *) {
            return UIApplication.shared.openURL(url)
        } else {
            return UIApplication.shared.openURL(url)
        }
    }

    /// 拨打电话
    ///
    /// - Parameter phoneNumber: 电话号码
    /// - Returns: 是否成功
    @discardableResult
    static func makeCall(_ phoneNumber: String) -> Bool {
        if let url = URL(string: "tel://\(phoneNumber)") {
            return openURL(url)
        }
        return false
    }

    /// 发送邮件
    ///
    /// - Parameter email: 邮箱地址
    /// - Returns: 是否成功
    @discardableResult
    static func sendEmail(_ email: String) -> Bool {
        if let url = URL(string: "mailto://\(email)") {
            return openURL(url)
        }
        return false
    }

    /// 发送短信
    ///
    /// - Parameter phoneNumber: 电话号码
    /// - Returns: 是否成功
    @discardableResult
    static func sendSMS(_ phoneNumber: String) -> Bool {
        if let url = URL(string: "sms://\(phoneNumber)") {
            return openURL(url)
        }
        return false
    }

    // MARK: - 应用程序操作

    /// 打开应用设置
    ///
    /// - Returns: 是否成功
    @discardableResult
    static func openAppSettings() -> Bool {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            return openURL(url)
        }
        return false
    }

    /// 重启应用
    static func restartApp() {
        exit(0)
    }

    /// 退出应用
    static func quitApp() {
        exit(0)
    }

    // MARK: - 调试

    /// 打印消息
    ///
    /// - Parameters:
    ///   - message: 消息
    ///   - file: 文件名
    ///   - function: 函数名
    ///   - line: 行号
    static func log(
        _ message: Any,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = (file as NSString).lastPathComponent
        print("[\(fileName):\(line)] \(message)")
    }

    /// 打印错误
    ///
    /// - Parameters:
    ///   - error: 错误
    ///   - file: 文件名
    ///   - function: 函数名
    ///   - line: 行号
    static func logError(
        _ error: Error,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = (file as NSString).lastPathComponent
        print("[\(fileName):\(line)] ERROR: \(error.localizedDescription)")
    }

    /// 断言
    ///
    /// - Parameters:
    ///   - condition: 条件
    ///   - message: 消息
    static func assert(
        _ condition: @autoclosure () -> Bool,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        #if DEBUG
        if !condition() {
            print("[ASSERT] \(message) - \(file):\(line)")
        }
        #endif
    }
}

// MARK: - 便捷方法

public extension LSHelper {

    /// 显示提示
    ///
    /// - Parameters:
    ///   - message: 消息
    ///   - icon: 图标
    static func showHUD(
        message: String,
        icon: UIImage? = nil
    ) {
        guard let topVC = LSKeyWindow.visibleViewController else { return }

        MBProgressHUD.show(message, to: topVC.view)

        if let icon = icon {
            // 设置自定义图标
        }
    }

    /// 隐藏提示
    static func hideHUD() {
        guard let topVC = LSKeyWindow.visibleViewController else { return }
        MBProgressHUD.hide(for: topVC.view, animated: true)
    }

    /// 显示成功提示
    ///
    /// - Parameter message: 消息
    static func showSuccess(_ message: String) {
        guard let topVC = LSKeyWindow.visibleViewController else { return }
        MBProgressHUD.showSuccess(message, to: topVC.view)
    }

    /// 显示错误提示
    ///
    /// - Parameter message: 消息
    static func showError(_ message: String) {
        guard let topVC = LSKeyWindow.visibleViewController else { return }
        MBProgressHUD.showError(message, to: topVC.view)
    }

    /// 显示加载提示
    ///
    /// - Parameter message: 消息
    static func showLoading(_ message: String = "加载中...") {
        guard let topVC = LSKeyWindow.visibleViewController else { return }
        MBProgressHUD.showLoading(message, to: topVC.view)
    }

    /// 显示信息提示
    ///
    /// - Parameter message: 消息
    static func showInfo(_ message: String) {
        guard let topVC = LSKeyWindow.visibleViewController else { return }
        MBProgressHUD.showInfo(message, to: topVC.view)
    }
}

#endif

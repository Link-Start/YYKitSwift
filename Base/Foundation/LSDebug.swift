//
//  LSDebug.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  调试工具 - 开发阶段使用的调试功能
//

#if canImport(UIKit)
import UIKit
import Foundation

// MARK: - LSDebug

/// 调试工具
public enum LSDebug {

    /// 是否启用调试模式
    public static var isEnabled: Bool = false

    /// 是否打印日志
    public static var isLoggingEnabled: Bool = true

    // MARK: - 日志

    /// 打印日志
    ///
    /// - Parameters:
    ///   - message: 消息
    ///   - level: 日志级别
    ///   - file: 文件名
    ///   - function: 函数名
    ///   - line: 行号
    public static func log(
        _ message: Any,
        level: LogLevel = .info,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard isLoggingEnabled else { return }

        let fileName = (file as NSString).lastPathComponent
        let timestamp = Date().ls_string(format: "HH:mm:ss.SSS")

        var levelString: String
        switch level {
        case .verbose:
            levelString = "🔵 VERBOSE"
        case .debug:
            levelString = "🟢 DEBUG"
        case .info:
            levelString = "⚪️ INFO"
        case .warning:
            levelString = "🟠 WARNING"
        case .error:
            levelString = "🔴 ERROR"
        }

        print("[\(timestamp)] \(levelString) [\(fileName):\(line)] \(message)")
    }

    /// 打印详细日志
    ///
    /// - Parameters:
    ///   - message: 消息
    ///   - file: 文件名
    ///   - function: 函数名
    ///   - line: 行号
    public static func verbose(
        _ message: Any,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .verbose, file: file, function: function, line: line)
    }

    /// 打印调试日志
    ///
    /// - Parameters:
    ///   - message: 消息
    ///   - file: 文件名
    ///   - function: 函数名
    ///   - line: 行号
    public static func debug(
        _ message: Any,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .debug, file: file, function: function, line: line)
    }

    /// 打印信息日志
    ///
    /// - Parameters:
    ///   - message: 消息
    ///   - file: 文件名
    ///   - function: 函数名
    ///   - line: 行号
    public static func info(
        _ message: Any,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .info, file: file, function: function, line: line)
    }

    /// 打印警告日志
    ///
    /// - Parameters:
    ///   - message: 消息
    ///   - file: 文件名
    ///   - function: 函数名
    ///   - line: 行号
    public static func warning(
        _ message: Any,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .warning, file: file, function: function, line: line)
    }

    /// 打印错误日志
    ///
    /// - Parameters:
    ///   - message: 消息
    ///   - file: 文件名
    ///   - function: 函数名
    ///   - line: 行号
    public static func error(
        _ message: Any,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .error, file: file, function: function, line: line)
    }

    // MARK: - 日志级别

    /// 日志级别
    public enum LogLevel {
        case verbose
        case debug
        case info
        case warning
        case error
    }

    // MARK: - 性能监测

    /// 测量执行时间
    ///
    /// - Parameters:
    ///   - name: 名称
    ///   - block: 要测量的代码块
    /// - Returns: 执行结果
    static func measure<T>(
        _ name: String,
        block: () throws -> T
    ) rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        defer {
            let end = CFAbsoluteTimeGetCurrent()
            let duration = (end - start) * 1000
            log("⏱ \(name) 耗时: \(String(format: "%.2f", duration))ms")
        }
        return try block()
    }

    /// 开始性能监测
    ///
    /// - Parameter name: 名称
    /// - Returns: 性能令牌
    @discardableResult
    static func startPerformance(_ name: String) -> PerformanceToken {
        return PerformanceToken(name: name)
    }

    // MARK: - 内存监测

    /// 打印内存使用情况
    static func printMemoryUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count
                )
            }
        }

        if result == KERN_SUCCESS {
            let usedMB = Double(info.resident_size) / 1024.0 / 1024.0
            log("📊 内存使用: \(String(format: "%.2f", usedMB))MB")
        }
    }

    /// 打印当前堆栈
    static func printStackTrace() {
        log("📚 堆栈跟踪:")
        Thread.callStackSymbols.forEach {
            log("  \($0)")
        }
    }

    // MARK: - 视图调试

    /// 打印视图层级
    ///
    /// - Parameter view: 视图
    static func printViewHierarchy(_ view: UIView) {
        log("🌳 视图层级:")
        printViewTree(view, level: 0)
    }

    private static func printViewTree(_ view: UIView, level: Int) {
        let indent = String(repeating: "  ", count: level)
        let frame = view.frame
        let className = String(describing: type(of: view))

        log("\(indent)📱 \(className) frame: \(frame)")

        for subview in view.subviews {
            printViewTree(subview, level: level + 1)
        }
    }

    /// 高亮视图边界
    ///
    /// - Parameter view: 视图
    static func highlightViewBorders(_ view: UIView) {
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.red.cgColor

        for subview in view.subviews {
            subview.layer.borderWidth = 1
            subview.layer.borderColor = UIColor(
                red: CGFloat.random(in: 0...1),
                green: CGFloat.random(in: 0...1),
                blue: CGFloat.random(in: 0...1),
                alpha: 1.0
            ).cgColor
            highlightViewBorders(subview)
        }
    }

    /// 移除视图边界高亮
    ///
    /// - Parameter view: 视图
    static func removeViewBorders(_ view: UIView) {
        view.layer.borderWidth = 0

        for subview in view.subviews {
            subview.layer.borderWidth = 0
            removeViewBorders(subview)
        }
    }

    // MARK: - 断点

    /// 条件断言（仅调试模式）
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
            log("❌ 断言失败: \(message)", level: .error, file: String(describing: file), line: Int(line))
            printStackTrace()
        }
        #endif
    }

    /// 条件断言（带返回值）
    ///
    /// - Parameters:
    ///   - condition: 条件
    ///   - message: 消息
    /// - Returns: 是否满足条件
    static func check(
        _ condition: @autoclosure () -> Bool,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) -> Bool {
        assert(condition, message: message, file: file, line: line)
        return condition()
    }
}

// MARK: - PerformanceToken

/// 性能监测令牌
public class LSDebug.PerformanceToken {

    /// 名称
    public let name: String

    /// 开始时间
    private let startTime: CFAbsoluteTime

    /// 是否已停止
    private(set) var isStopped: Bool = false

    /// 初始化
    ///
    /// - Parameter name: 名称
    init(name: String) {
        self.name = name
        self.startTime = CFAbsoluteTimeGetCurrent()
        LSDebug.log("⏱ 开始监测: \(name)")
    }

    /// 停止监测
    ///
    /// - Returns: 耗时（毫秒）
    @discardableResult
    func stop() -> TimeInterval {
        guard !isStopped else { return 0 }

        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = (endTime - startTime) * 1000

        isStopped = true
        LSDebug.log("⏱ 结束监测: \(name) - 耗时: \(String(format: "%.2f", duration))ms")

        return duration
    }

    /// 打印当前耗时
    ///
    /// - Returns: 当前耗时（毫秒）
    @discardableResult
    func printCurrent() -> TimeInterval {
        let currentTime = CFAbsoluteTimeGetCurrent()
        let duration = (currentTime - startTime) * 1000
        LSDebug.log("⏱ \(name) 当前耗时: \(String(format: "%.2f", duration))ms")
        return duration
    }

    /// 析构时自动停止
    deinit {
        if !isStopped {
            stop()
        }
    }
}

// MARK: - 条件编译调试

#if DEBUG

public extension LSDebug {

    /// 仅在 DEBUG 模式下执行
    ///
    /// - Parameter block: 执行块
    static func debugOnly(_ block: () -> Void) {
        block()
    }

    /// 仅在 DEBUG 模式下延迟执行
    ///
    /// - Parameters:
    ///   - delay: 延迟时间
    ///   - block: 执行块
    static func debugOnly(
        delay: TimeInterval,
        block: @escaping () -> Void
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            block()
        }
    }
}

#else

public extension LSDebug {

    /// 仅在 DEBUG 模式下执行（Release 中不执行）
    static func debugOnly(_ block: () -> Void) {}

    /// 仅在 DEBUG 模式下延迟执行（Release 中不执行）
    static func debugOnly(delay: TimeInterval, block: @escaping () -> Void) {}
}

#endif

// MARK: - UIView Extension (调试)

public extension UIView {

    /// 打印视图信息
    func ls_printInfo() {
        LSDebug.log("📱 视图信息: \(type(of: self))")
        LSDebug.log("  frame: \(frame)")
        LSDebug.log("  bounds: \(bounds)")
        LSDebug.log("  center: \(center)")
        LSDebug.log("  alpha: \(alpha)")
        LSDebug.log("  isHidden: \(isHidden)")
        LSDebug.log("  subviews count: \(subviews.count)")
    }

    /// 打印视图层级
    func ls_printHierarchy() {
        LSDebug.printViewHierarchy(self)
    }

    /// 高亮边框
    func ls_highlightBorders() {
        LSDebug.highlightViewBorders(self)
    }

    /// 移除边框高亮
    func ls_removeBorders() {
        LSDebug.removeViewBorders(self)
    }
}

// MARK: - UIViewController Extension (调试)

public extension UIViewController {

    /// 打印控制器信息
    func ls_printInfo() {
        LSDebug.log("🎮 控制器信息: \(type(of: self))")
        LSDebug.log("  title: \(title ?? "nil")")
        LSDebug.log("  view.frame: \(view.frame)")
        LSDebug.log("  isMovingToParent: \(isMovingToParent)")
    }
}

// MARK: - 便捷宏定义

/// 调试日志宏（可在开发中使用）
public func LSLogVerbose(
    _ message: Any,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    LSDebug.verbose(message, file: file, function: function, line: line)
}

/// 调试日志宏
public func LSLogDebug(
    _ message: Any,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    LSDebug.debug(message, file: file, function: function, line: line)
}

/// 信息日志宏
public func LSLogInfo(
    _ message: Any,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    LSDebug.info(message, file: file, function: function, line: line)
}

/// 警告日志宏
public func LSLogWarning(
    _ message: Any,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    LSDebug.warning(message, file: file, function: function, line: line)
}

/// 错误日志宏
public func LSLogError(
    _ message: Any,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    LSDebug.error(message, file: file, function: function, line: line)
}

#endif

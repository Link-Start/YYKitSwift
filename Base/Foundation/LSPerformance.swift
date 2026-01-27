//
//  LSPerformance.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  性能监控工具 - 监控和优化应用性能
//

#if canImport(UIKit)
import UIKit
import Foundation
import os.signpost

// MARK: - LSPerformance

/// 性能监控工具类
public enum LSPerformance {

    // MARK: - 性能追踪

    /// 开始追踪
    ///
    /// - Parameter name: 追踪名称
    /// - Returns: 追踪令牌
    @discardableResult
    public static func beginTrace(name: String) -> TraceToken {
        if #available(iOS 12.0, *) {
            let log = OSLog(subsystem: "com.lsperformance", category: .pointsOfInterest)
            os_signpost(.event, log: log, name: "Begin Trace: %{public}@", name)
        }
        return TraceToken(name: name, startTime: CFAbsoluteTimeGetCurrent())
    }

    /// 结束追踪
    ///
    /// - Parameter token: 追踪令牌
    /// - Returns: 耗时（秒）
    @discardableResult
    public static func endTrace(_ token: TraceToken) -> TimeInterval {
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - token.startTime

        if #available(iOS 12.0, *) {
            let log = OSLog(subsystem: "com.lsperformance", category: .pointsOfInterest)
            os_signpost(.event, log: log, name: "End Trace: %{public}@ (%.3fms)", token.name, duration * 1000)
        }

        return duration
    }

    /// 追踪代码执行时间
    ///
    /// - Parameters:
    ///   - name: 追踪名称
    ///   - block: 要执行的代码
    /// - Returns: 耗时（秒）
    @discardableResult
    public static func measure(name: String, block: () -> Void) -> TimeInterval {
        let token = beginTrace(name: name)
        block()
        return endTrace(token)
    }

    /// 追踪代码执行时间（带返回值）
    ///
    /// - Parameters:
    ///   - name: 追踪名称
    ///   - block: 要执行的代码
    /// - Returns: 执行结果和耗时
    @discardableResult
    public static func measure<T>(name: String, block: () -> T) -> (result: T, duration: TimeInterval) {
        let token = beginTrace(name: name)
        let result = block()
        let duration = endTrace(token)
        return (result, duration)
    }

    // MARK: - 内存监控

    /// 获取当前内存使用量（MB）
    public static var memoryUsage: UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        guard kerr == KERN_SUCCESS else { return 0 }
        return info.resident_size / 1024 / 1024
    }

    /// 获取可用内存（MB）
    public static var availableMemory: UInt64 {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size) / MemoryLayout<integer_t>.size

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else { return 0 }

        let pageSize = vm_kernel_page_size
        return UInt64(stats.free_count + stats.inactive_count) * UInt64(pageSize) / 1024 / 1024
    }

    /// 获取总内存（MB）
    public static var totalMemory: UInt64 {
        return ProcessInfo.processInfo.physicalMemory / 1024 / 1024
    }

    /// 内存使用率
    public static var memoryUsagePercentage: Double {
        let used = Double(memoryUsage)
        let total = Double(totalMemory)
        return (used / total) * 100
    }

    // MARK: - CPU 监控

    /// 获取当前 CPU 使用率
    public static var cpuUsage: Double {
        var totalUsageOfCPU: Double = 0
        var threadsList: thread_act_array_t?
        var threadsCount = mach_msg_type_number_t(0)
        let threadsResult = withUnsafeMutablePointer(to: &threadsList) {
            return $0.withMemoryRebound(to: thread_act_array_t?.self, capacity: 1) {
                task_threads(mach_task_self_, $0, &threadsCount)
            }
        }

        if threadsResult == KERN_SUCCESS, let threadsList = threadsList {
            for index in 0..<threadsCount {
                var threadInfo = thread_basic_info()
                var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
                let infoResult = withUnsafeMutablePointer(to: &threadInfo) {
                    $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                        thread_info(threadsList[Int(index)], thread_flavor_t(THREAD_BASIC_INFO), $0, &threadInfoCount)
                    }
                }

                guard infoResult == KERN_SUCCESS else { continue }

                let threadBasicInfo = threadInfo as thread_basic_info
                if threadBasicInfo.flags & TH_FLAGS_IDLE == 0 {
                    totalUsageOfCPU += (Double(threadBasicInfo.cpu_usage) / Double(TH_USAGE_SCALE)) * 100
                }
            }

            vm_deallocate(mach_task_self_, vm_address_t(UInt64(bitPattern: threadsList)), vm_size_t(Int(threadsCount) * MemoryLayout<thread_t>.stride))
        }

        return totalUsageOfCPU
    }

    // MARK: - FPS 监控

    /// 创建 FPS 监控器
    ///
    /// - Parameter handler: FPS 变化回调
    /// - Returns: FPSMonitor 实例
    public static func createFPSMonitor(handler: @escaping (Double) -> Void) -> FPSMonitor {
        return FPSMonitor(handler: handler)
    }

    // MARK: - 帧渲染时间

    /// 创建帧渲染时间监控器
    ///
    /// - Parameter handler: 渲染时间回调
    /// - Returns: FrameRenderMonitor 实例
    public static func createFrameRenderMonitor(handler: @escaping (TimeInterval) -> Void) -> FrameRenderMonitor {
        return FrameRenderMonitor(handler: handler)
    }
}

// MARK: - TraceToken

/// 追踪令牌
public class TraceToken {
    let name: String
    let startTime: TimeInterval

    init(name: String, startTime: TimeInterval) {
        self.name = name
        self.startTime = startTime
    }
}

// MARK: - FPSMonitor

/// FPS 监控器
public class FPSMonitor {

    private var displayLink: CADisplayLink?
    private var handler: (Double) -> Void
    private var lastTimestamp: TimeInterval = 0
    private var frameCount: Int = 0
    private var currentFPS: Double = 0

    /// 是否正在监控
    public private(set) var isMonitoring = false

    /// 初始化
    init(handler: @escaping (Double) -> Void) {
        self.handler = handler
    }

    /// 开始监控
    public func start() {
        guard !isMonitoring else { return }
        isMonitoring = true

        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkFired))
        displayLink?.add(to: .main, forMode: .common)
    }

    /// 停止监控
    public func stop() {
        isMonitoring = false
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func displayLinkFired() {
        guard let displayLink = displayLink else { return }

        frameCount += 1

        if lastTimestamp == 0 {
            lastTimestamp = displayLink.timestamp
            return
        }

        let elapsed = displayLink.timestamp - lastTimestamp

        if elapsed >= 1 {
            currentFPS = Double(frameCount) / elapsed
            handler(currentFPS)
            frameCount = 0
            lastTimestamp = displayLink.timestamp
        }
    }
}

// MARK: - FrameRenderMonitor

/// 帧渲染时间监控器
public class FrameRenderMonitor {

    private var displayLink: CADisplayLink?
    private var handler: (TimeInterval) -> Void
    private var lastTimestamp: TimeInterval = 0

    /// 是否正在监控
    public private(set) var isMonitoring = false

    /// 当前渲染时间
    public private(set) var renderTime: TimeInterval = 0

    /// 最大渲染时间阈值（超过则认为掉帧）
    public var threshold: TimeInterval = 0.0167 // 60FPS

    /// 是否掉帧
    public var isDroppingFrames: Bool {
        return renderTime > threshold
    }

    /// 初始化
    init(handler: @escaping (TimeInterval) -> Void) {
        self.handler = handler
    }

    /// 开始监控
    public func start() {
        guard !isMonitoring else { return }
        isMonitoring = true

        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkFired))
        displayLink?.add(to: .main, forMode: .common)
    }

    /// 停止监控
    public func stop() {
        isMonitoring = false
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func displayLinkFired() {
        guard let displayLink = displayLink else { return }

        if lastTimestamp > 0 {
            renderTime = displayLink.timestamp - lastTimestamp
            handler(renderTime)
        }

        lastTimestamp = displayLink.timestamp
    }
}

// MARK: - AutoTimer

/// 自动计时器 - 用于代码执行时间测量
public class AutoTimer {

    private let name: String
    private let startTime: TimeInterval
    private let handler: (String, TimeInterval) -> Void

    /// 初始化
    ///
    /// - Parameters:
    ///   - name: 计时器名称
    ///   - handler: 完成回调
    init(name: String, handler: @escaping (String, TimeInterval) -> Void = { _, _ in }) {
        self.name = name
        self.startTime = CFAbsoluteTimeGetCurrent()
        self.handler = handler
    }

    /// 停止计时
    func stop() {
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        handler(name, duration)
    }
}

// MARK: - 性能测量宏（简化版）

/// 性能测量块
///
/// - Parameter block: 要测量的代码
public func LSMeasure(_ name: String = "Performance", block: () -> Void) {
    _ = LSPerformance.measure(name: name, block: block)
}

/// 性能测量块（带返回值）
///
/// - Parameter block: 要测量的代码
/// - Returns: 执行结果
public func LSMeasure<T>(_ name: String = "Performance", block: () -> T) -> T {
    let (result, _) = LSPerformance.measure(name: name, block: block)
    return result
}

// MARK: - 性能警告阈值

public extension LSPerformance {

    /// 设置内存警告阈值（MB）
    static var memoryWarningThreshold: UInt64 = 200

    /// 设置 CPU 警告阈值（百分比）
    static var cpuWarningThreshold: Double = 80

    /// 检查是否需要警告
    static func shouldWarnMemory() -> Bool {
        return memoryUsage > memoryWarningThreshold
    }

    /// 检查是否需要 CPU 警告
    static func shouldWarnCPU() -> Bool {
        return cpuUsage > cpuWarningThreshold
    }

    /// 获取性能报告
    static func performanceReport() -> String {
        return """
        性能报告
        ========
        内存使用: \(memoryUsage) MB / \(totalMemory) MB (\(String(format: "%.1f", memoryUsagePercentage))%)
        可用内存: \(availableMemory) MB
        CPU 使用率: \(String(format: "%.1f", cpuUsage))%
        """
    }
}

// MARK: - UIView Extension (性能调试)

public extension UIView {

    /// 检查是否在主线程
    func ls_assertMainThread() {
        assert(Thread.isMainThread, "\(self) 必须在主线程操作")
    }

    /// 安全执行（确保在主线程）
    func ls_safeMain(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }
}

// MARK: - 性能优化提示

public extension LSPerformance {

    /// 检查图像是否过大
    static func isImageTooLarge(_ image: UIImage) -> Bool {
        let size = image.size
        let pixels = Int(size.width * size.height)
        return pixels > 4096 * 4096 // 超过 4K
    }

    /// 检查是否应该异步解码图像
    static func shouldDecodeImageAsync(_ image: UIImage) -> Bool {
        let size = image.size
        let pixels = Int(size.width * size.height)
        return pixels > 1000 * 1000 // 超过 1000x1000
    }

    /// 获取推荐的图像尺寸
    static func recommendedImageSize(for view: UIView) -> CGSize {
        let scale = UIScreen.main.scale
        return CGSize(
            width: view.bounds.width * scale,
            height: view.bounds.height * scale
        )
    }
}

#endif

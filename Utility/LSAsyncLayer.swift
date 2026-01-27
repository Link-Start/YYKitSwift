//
//  LSAsyncLayer.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  异步绘制层 - 用于在后台线程渲染内容
//

#if canImport(UIKit)
import UIKit
import QuartzCore

/// LSAsyncLayer 是 CALayer 的子类，用于异步渲染内容
///
/// - Discussion: 当图层需要更新其内容时，它会向代理请求异步显示任务，
/// 以在后台队列中渲染内容。
public class LSAsyncLayer: CALayer {

    // MARK: - 属性

    /// 渲染代码是否在后台执行，默认为 YES
    public var displaysAsynchronously: Bool = true

    /// 代理
    public weak var asyncDelegate: LSAsyncLayerDelegate?

    // MARK: - CALayer Override

    public override func display() {
        super.contents = super.contents

        guard let task = asyncDelegate?.newAsyncDisplayTask() else {
            super.display()
            return
        }

        // 执行 willDisplay
        if let willDisplay = task.willDisplay {
            willDisplay(self)
        }

        // 检查是否需要异步绘制
        let isAsync = displaysAsynchronously && task.display != nil
        guard let display = task.display else {
            super.display()
            if let didDisplay = task.didDisplay {
                didDisplay(self, true)
            }
            return
        }

        if isAsync {
            // 异步绘制
            let isCancelledKey = UnsafeMutablePointer<Bool>.allocate(capacity: 1)
            isCancelledKey.pointee = false

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }

                // 创建 bitmap 上下文
                let size = self.bounds.size
                guard size.width > 0 && size.height > 0 else {
                    DispatchQueue.main.async {
                        if let didDisplay = task.didDisplay {
                            didDisplay(self, false)
                        }
                    }
                    return
                }

                // 创建上下文
                let scale = UIScreen.main.scale
                let width = Int(size.width * scale)
                let height = Int(size.height * scale)

                guard let context = CGContext(
                    data: nil,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: width * 4,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
                ) else {
                    DispatchQueue.main.async {
                        if let didDisplay = task.didDisplay {
                            didDisplay(self, false)
                        }
                    }
                    return
                }

                context.scaleBy(x: scale, y: scale)

                // 执行绘制
                let isCancelledBlock: () -> Bool = {
                    return isCancelledKey.pointee
                }

                if !isCancelledBlock() {
                    display(context, size, isCancelledBlock)
                }

                // 获取图像
                var image: CGImage?
                if !isCancelledBlock() {
                    image = context.makeImage()
                }

                // 在主线程设置内容
                DispatchQueue.main.async {
                    if let image = image {
                        self.contents = image
                    }
                    if let didDisplay = task.didDisplay {
                        didDisplay(self, !isCancelledBlock())
                    }
                    isCancelledKey.deallocate()
                }
            }
        } else {
            // 同步绘制
            let size = self.bounds.size
            guard size.width > 0 && size.height > 0 else {
                if let didDisplay = task.didDisplay {
                    didDisplay(self, false)
                }
                return
            }

            let scale = UIScreen.main.scale
            let width = Int(size.width * scale)
            let height = Int(size.height * scale)

            guard let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
            ) else {
                if let didDisplay = task.didDisplay {
                    didDisplay(self, false)
                }
                return
            }

            context.scaleBy(x: scale, y: scale)

            let isCancelledKey = UnsafeMutablePointer<Bool>.allocate(capacity: 1)
            isCancelledKey.pointee = false

            let isCancelledBlock: () -> Bool = {
                return isCancelledKey.pointee
            }

            display(context, size, isCancelledBlock)
            isCancelledKey.deallocate()

            if let image = context.makeImage() {
                self.contents = image
            }

            if let didDisplay = task.didDisplay {
                didDisplay(self, true)
            }
        }
    }
}

// MARK: - LSAsyncLayerDelegate

/// LSAsyncLayer 的代理协议
public protocol LSAsyncLayerDelegate: AnyObject {
    /// 当图层内容需要更新时调用此方法以返回新的显示任务
    func newAsyncDisplayTask() -> LSAsyncLayerDisplayTask
}

// MARK: - LSAsyncLayerDisplayTask

/// LSAsyncLayer 用于在后台队列中渲染内容的显示任务
public class LSAsyncLayerDisplayTask: NSObject {

    // MARK: - 闭包类型

    /// 在异步绘制开始之前调用的块
    /// - 在主线程调用
    public typealias WillDisplayBlock = @Sendable (CALayer) -> Void

    /// 绘制图层内容的块
    /// - 可能在主线程或后台线程调用，应该是线程安全的
    public typealias DisplayBlock = @Sendable (CGContext, CGSize, @Sendable () -> Bool) -> Void

    /// 在异步绘制完成后调用的块
    /// - 在主线程调用
    public typealias DidDisplayBlock = @Sendable (CALayer, Bool) -> Void

    // MARK: - 属性

    /// 在异步绘制开始之前调用，在主线程调用
    public var willDisplay: WillDisplayBlock?

    /// 绘制图层内容，可能在主线程或后台线程调用，应该是线程安全的
    public var display: DisplayBlock?

    /// 在异步绘制完成后调用，在主线程调用
    public var didDisplay: DidDisplayBlock?

    // MARK: - 初始化

    public override init() {
        super.init()
    }

    // MARK: - 便捷初始化

    /// 创建带有指定绘制块的显示任务
    ///
    /// - Parameter display: 绘制块
    /// - Returns: 新的显示任务
    public static func task(display: @escaping DisplayBlock) -> LSAsyncLayerDisplayTask {
        let task = LSAsyncLayerDisplayTask()
        task.display = display
        return task
    }

    /// 创建带有完整回调的显示任务
    ///
    /// - Parameters:
    ///   - willDisplay: 绘制前回调
    ///   - display: 绘制回调
    ///   - didDisplay: 绘制后回调
    /// - Returns: 新的显示任务
    public static func task(
        willDisplay: WillDisplayBlock? = nil,
        display: DisplayBlock? = nil,
        didDisplay: DidDisplayBlock? = nil
    ) -> LSAsyncLayerDisplayTask {
        let task = LSAsyncLayerDisplayTask()
        task.willDisplay = willDisplay
        task.display = display
        task.didDisplay = didDisplay
        return task
    }
}
#endif

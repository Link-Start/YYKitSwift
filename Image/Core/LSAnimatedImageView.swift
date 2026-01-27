//
//  LSAnimatedImageView.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  动画图片视图 - 用于显示动画图像 (GIF/APNG/WebP)
//

#if canImport(UIKit)
import UIKit
import QuartzCore

/// 动画图片视图 - 用于显示动画图像
///
/// 这是一个完全兼容的 `UIImageView` 子类。
/// 如果 `image` 或 `highlightedImage` 属性采用 `LSAnimatedImage` 协议，
/// 则可以用来播放多帧动画。动画也可以使用 UIImageView 的方法
/// `-startAnimating`, `-stopAnimating` 和 `-isAnimating` 来控制。
///
/// 此视图按需请求数据。当设备有足够的空闲内存时，
/// 此视图可能会在内部缓冲区中缓存一些或所有未来帧，以降低 CPU 消耗。
/// 缓冲区大小根据当前设备内存状态动态调整。
@MainActor
public class LSAnimatedImageView: UIImageView {

    // MARK: - 属性

    /// 如果图像有多帧，将此值设置为 `true` 将在视图可见/不可见时自动播放/停止动画
    /// 默认值是 `true`
    public var autoPlayAnimatedImage = true

    /// 当前显示帧的索引 (从 0 开始)
    ///
    /// 设置新值将导致立即显示新帧。
    /// 如果新值无效，此方法无效。
    ///
    /// 可以为此属性添加观察者来观察播放状态
    public var currentAnimatedImageIndex: UInt = 0 {
        didSet {
            if currentAnimatedImageIndex != oldValue {
                updateFrame()
            }
        }
    }

    /// 图像视图当前是否正在播放动画
    ///
    /// 可以为此属性添加观察者来观察播放状态
    public private(set) var currentIsPlayingAnimation = false

    /// 动画定时器的 runloop 模式，默认是 `RunLoop.Mode.common`
    ///
    /// 将此属性设置为 `RunLoop.Mode.default` 将使动画在 UIScrollView 滚动期间暂停
    public var runloopMode: RunLoop.Mode = .common {
        didSet {
            if runloopMode != oldValue {
                stopAnimation()
                if currentIsPlayingAnimation {
                    startAnimation()
                }
            }
        }
    }

    /// 内部帧缓冲区的最大大小（字节），默认是 0（动态）
    ///
    /// 当设备有足够的空闲内存时，此视图将请求并解码一些或所有未来帧图像到内部缓冲区。
    /// 如果此属性的值为 0，则最大缓冲区大小将根据当前设备空闲内存状态动态调整。
    /// 否则，缓冲区大小将受此值限制。
    ///
    /// 当收到内存警告或应用进入后台时，缓冲区将立即释放，
    /// 并可能在适当的时候重新增长。
    public var maxBufferSize: UInt = 0

    // MARK: - 内部属性

    private var displayLink: CADisplayLink?
    private var frameTimer: Timer?
    private var lastTime: CFTimeInterval = 0
    private var accumulatedTime: CFTimeInterval = 0
    private var buffer: [UInt: UIImage] = [:]
    private var bufferLock = NSLock()
    private var currentLoopCount = 0

    /// 当前动画图像（如果实现了 LSAnimatedImage 协议）
    private var animatedImage: LSAnimatedImage? {
        return image as? LSAnimatedImage ?? highlightedImage as? LSAnimatedImage
    }

    /// 是否有有效的动画图像
    private var hasAnimatedImage: Bool {
        let img = isHighlighted ? highlightedImage : image
        guard let animImage = img as? LSAnimatedImage else { return false }
        return animImage.animatedImageFrameCount() > 1
    }

    // MARK: - 初始化

    public override init(image: UIImage?, highlightedImage: UIImage? = nil) {
        super.init(image: image, highlightedImage: highlightedImage)
        commonInit()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        // 监听应用状态
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    deinit {
        stopAnimation()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - 生命周期

    public override var image: UIImage? {
        didSet {
            if image !== oldValue {
                clearBuffer()
                if autoPlayAnimatedImage && window != nil {
                    updateShouldPlay()
                }
            }
        }
    }

    public override var highlightedImage: UIImage? {
        didSet {
            if highlightedImage !== oldValue {
                clearBuffer()
                if autoPlayAnimatedImage && window != nil && isHighlighted {
                    updateShouldPlay()
                }
            }
        }
    }

    public override var isHighlighted: Bool {
        didSet {
            if isHighlighted != oldValue {
                clearBuffer()
                updateShouldPlay()
            }
        }
    }

    public override var frame: CGRect {
        didSet {
            if frame.size != oldValue.size {
                clearBuffer()
            }
        }
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()

        if autoPlayAnimatedImage {
            updateShouldPlay()
        }
    }

    public override func didMoveToSuperview() {
        super.didMoveToSuperview()

        if autoPlayAnimatedImage {
            updateShouldPlay()
        }
    }

    // MARK: - 动画控制

    public override func startAnimating() {
        super.startAnimating()
        updateShouldPlay()
    }

    public override func stopAnimating() {
        super.stopAnimating()
        updateShouldPlay()
    }

    public override var isAnimating: Bool {
        return currentIsPlayingAnimation
    }

    // MARK: - 内存警告

    @objc private func didReceiveMemoryWarning() {
        clearBuffer()
    }

    @objc private func didEnterBackground() {
        stopAnimation()
        clearBuffer()
    }

    @objc private func didBecomeActive() {
        if autoPlayAnimatedImage {
            updateShouldPlay()
        }
    }

    // MARK: - 内部方法

    private func updateShouldPlay() {
        let shouldPlay = hasAnimatedImage && (isAnimating || autoPlayAnimatedImage) && window != nil

        if shouldPlay && !currentIsPlayingAnimation {
            startAnimation()
        } else if !shouldPlay && currentIsPlayingAnimation {
            stopAnimation()
        }
    }

    private func startAnimation() {
        guard hasAnimatedImage else { return }

        stopAnimation()

        currentIsPlayingAnimation = true

        // 使用 CADisplayLink 实现更精确的帧控制
        displayLink = CADisplayLink(target: LSDisplayLinkProxy(target: self), selector: #selector(LSDisplayLinkProxy.displayLinkFired))
        displayLink?.add(to: .main, forMode: runloopMode)
        lastTime = CACurrentMediaTime()
        accumulatedTime = 0
    }

    private func stopAnimation() {
        currentIsPlayingAnimation = false

        displayLink?.invalidate()
        displayLink = nil

        frameTimer?.invalidate()
        frameTimer = nil
    }

    @objc private func step() {
        guard let animImage = animatedImage else { return }

        let frameCount = animImage.animatedImageFrameCount()
        guard frameCount > 1 else { return }

        // 获取当前帧的持续时间
        let duration = animImage.animatedImageDuration(at: currentAnimatedImageIndex)

        accumulatedTime += duration

        // 移动到下一帧
        currentAnimatedImageIndex += 1
        if currentAnimatedImageIndex >= frameCount {
            currentAnimatedImageIndex = 0
            currentLoopCount += 1

            // 检查循环次数
            let loopCount = animImage.animatedImageLoopCount()
            if loopCount > 0 && currentLoopCount >= loopCount {
                stopAnimation()
                currentLoopCount = 0
            }
        }

        updateFrame()
    }

    private func updateFrame() {
        guard let animImage = animatedImage else { return }
        guard currentAnimatedImageIndex < animImage.animatedImageFrameCount() else { return }

        // 从缓冲区或直接获取帧
        var frameImage: UIImage?
        bufferLock.lock()
        if let buffered = buffer[currentAnimatedImageIndex] {
            frameImage = buffered
        } else {
            frameImage = animImage.animatedImageFrame(at: currentAnimatedImageIndex)
        }
        bufferLock.unlock()

        if let img = frameImage {
            // 检查是否需要更新 contentsRect
            let contentsRect: CGRect
            if let rect = getContentsRect(at: currentAnimatedImageIndex) {
                contentsRect = rect
            } else {
                contentsRect = CGRect(x: 0, y: 0, width: 1, height: 1)
            }

            // 更新图像
            layer.contents = img.cgImage
            layer.contentsRect = contentsRect

            // 预加载下一帧
            preloadNextFrame()
        }
    }

    private func getContentsRect(at index: UInt) -> CGRect? {
        guard let animImage = animatedImage else { return nil }
        return animImage.animatedImageContentsRect?(at: index)
    }

    private func preloadNextFrame() {
        guard let animImage = animatedImage else { return }

        let frameCount = animImage.animatedImageFrameCount()
        let nextIndex = (currentAnimatedImageIndex + 1) % frameCount

        // 检查是否已经在缓冲区中
        bufferLock.lock()
        if buffer[nextIndex] != nil {
            bufferLock.unlock()
            return
        }
        bufferLock.unlock()

        // 异步预加载下一帧
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            guard let frame = animImage.animatedImageFrame(at: nextIndex) else { return }

            // 检查缓冲区大小
            let currentBufferSize = self.getBufferSize()
            let maxBuffer = self.maxBufferSize == 0 ? self.calculateMaxBufferSize() : self.maxBufferSize

            if currentBufferSize < maxBuffer {
                let frameSize = self.getFrameSize(frame)

                if currentBufferSize + frameSize <= maxBuffer {
                    self.bufferLock.lock()
                    self.buffer[nextIndex] = frame
                    self.bufferLock.unlock()
                }
            }
        }
    }

    private func clearBuffer() {
        bufferLock.lock()
        buffer.removeAll()
        bufferLock.unlock()
    }

    private func getBufferSize() -> UInt {
        var size: UInt = 0
        bufferLock.lock()
        for frame in buffer.values {
            size += getFrameSize(frame)
        }
        bufferLock.unlock()
        return size
    }

    private func getFrameSize(_ image: UIImage) -> UInt {
        guard let cgImage = image.cgImage else { return 0 }
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4  // 假设 RGBA8888
        return UInt(width * height * bytesPerPixel)
    }

    private func calculateMaxBufferSize() -> UInt {
        // 根据设备内存动态计算缓冲区大小
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let availableMemory = totalMemory / 4  // 使用 25% 的物理内存

        // 限制在合理范围内
        let minBuffer: UInt = 10 * 1024 * 1024  // 10MB
        let maxBuffer: UInt = 100 * 1024 * 1024  // 100MB

        return min(max(availableMemory, minBuffer), maxBuffer)
    }
}

// MARK: - CADisplayLink 代理

/// CADisplayLink 目标代理，避免循环引用
private class LSDisplayLinkProxy {
    private weak var target: LSAnimatedImageView?

    init(target: LSAnimatedImageView) {
        self.target = target
    }

    @objc func displayLinkFired() {
        guard let target = target else { return }

        let currentTime = CACurrentMediaTime()
        let deltaTime = currentTime - target.lastTime
        target.lastTime = currentTime

        target.accumulatedTime += deltaTime

        // 检查是否应该切换到下一帧
        if let animImage = target.animatedImage {
            let currentDuration = animImage.animatedImageDuration(at: target.currentAnimatedImageIndex)

            if target.accumulatedTime >= currentDuration {
                target.accumulatedTime -= currentDuration
                target.step()
            }
        }
    }
}
#endif

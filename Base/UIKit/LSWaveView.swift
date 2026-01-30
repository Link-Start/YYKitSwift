//
//  LSWaveView.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  波浪动画视图 - 水波纹/液体波浪动画效果
//

#if canImport(UIKit)
import UIKit

// MARK: - LSWaveView

/// 波浪视图
@MainActor
public class LSWaveView: UIView {

    // MARK: - 类型定义

    /// 波浪形状
    public enum WaveShape {
        case sine            // 正弦波
        case cosine          // 余弦波
        case tangent         // 正切波
        case custom((CGFloat) -> CGFloat)  // 自定义波形
    }

    /// 波浪方向
    public enum WaveDirection {
        case left            // 向左
        case right           // 向右
    }

    // MARK: - 属性

    /// 波幅
    public var amplitude: CGFloat = 10 {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 波长
    public var waveLength: CGFloat = 100 {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 波浪速度
    public var speed: CGFloat = 2 {
        didSet {
            updateTimer()
        }
    }

    /// 波浪方向
    public var direction: WaveDirection = .left {
        didSet {
            phase = direction == .left ? phase : -phase
        }
    }

    /// 波浪形状
    public var shape: WaveShape = .sine {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 波浪颜色
    public var waveColor: UIColor = .systemBlue {
        didSet {
            waveLayer.fillColor = waveColor.cgColor
        }
    }

    /// 第二波浪颜色
    public var secondWaveColor: UIColor = .systemBlue.withAlphaComponent(0.5) {
        didSet {
            secondWaveLayer.fillColor = secondWaveColor.cgColor
        }
    }

    /// 是否显示第二波浪
    public var showsSecondWave: Bool = true {
        didSet {
            secondWaveLayer.isHidden = !showsSecondWave
        }
    }

    /// 是否填充
    public var isFilled: Bool = true {
        didSet {
            updateWaveLayers()
        }
    }

    /// 相位偏移
    public var phase: CGFloat = 0

    /// 是否动画
    public var isAnimating: Bool = true {
        didSet {
            updateTimer()
        }
    }

    /// 动画时间间隔
    public var animationInterval: TimeInterval = 1.0 / 60.0

    // MARK: - 私有属性

    private let waveLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.systemBlue.cgColor
        return layer
    }()

    private let secondWaveLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.systemBlue.withAlphaComponent(0.5).cgColor
        return layer
    }()

    private var timer: Timer?
    private var secondPhase: CGFloat = 0

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupWaveView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupWaveView()
    }

    public convenience init(color: UIColor = .systemBlue, amplitude: CGFloat = 10) {
        self.init(frame: .zero)
        self.waveColor = color
        self.amplitude = amplitude
    }

    // MARK: - 设置

    private func setupWaveView() {
        layer.addSublayer(secondWaveLayer)
        layer.addSublayer(waveLayer)

        updateTimer()
    }

    // MARK: - 布局

    public override func layoutSubviews() {
        super.layoutSubviews()
        updateWaveLayers()
    }

    // MARK: - 波浪绘制

    private func updateWaveLayers() {
        waveLayer.path = createWavePath(phase: phase).cgPath
        secondWaveLayer.path = createWavePath(phase: secondPhase).cgPath
    }

    private func createWavePath(phase: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        let width = bounds.width
        let height = bounds.height
        let midY = height / 2

        path.move(to: CGPoint(x: 0, y: midY))

        for x in stride(from: 0, through: width, by: 1) {
            let normalizedX = x / waveLength
            let angle = 2 * .pi * normalizedX + phase
            let y: CGFloat

            switch shape {
            case .sine:
                y = midY + amplitude * sin(angle)
            case .cosine:
                y = midY + amplitude * cos(angle)
            case .tangent:
                let tanValue = tan(angle / 2)
                y = midY + amplitude * (tanValue / (1 + abs(tanValue)))
            case .custom(let function):
                y = midY + amplitude * function(angle)
            }

            path.addLine(to: CGPoint(x: x, y: y))
        }

        if isFilled {
            path.addLine(to: CGPoint(x: width, y: height))
            path.addLine(to: CGPoint(x: 0, y: height))
            path.close()
        }

        return path
    }

    // MARK: - 动画

    private func updateTimer() {
        timer?.invalidate()
        timer = nil

        guard isAnimating else { return }

        timer = Timer.scheduledTimer(withTimeInterval: animationInterval, repeats: true) { [weak self] _ in
            self?.updatePhase()
        }
    }

    private func updatePhase() {
        let delta = speed * 0.02

        switch direction {
        case .left:
            phase += delta
            secondPhase += delta * 0.8
        case .right:
            phase -= delta
            secondPhase -= delta * 0.8
        }

        updateWaveLayers()
    }

    // MARK: - 公共方法

    /// 开始动画
    public func startAnimating() {
        isAnimating = true
    }

    /// 停止动画
    public func stopAnimating() {
        isAnimating = false
    }

    /// 设置进度（0.0 - 1.0）
    public func setProgress(_ progress: CGFloat) {
        let height = bounds.height
        let offset = height * (1 - progress)

        var transform = CGAffineTransform(translationX: 0, y: offset)
        waveLayer.setAffineTransform(transform)
        secondWaveLayer.setAffineTransform(transform)
    }
}

// MARK: - LSWaterWaveView

/// 水波纹视图（圆形）
public class LSWaterWaveView: UIView {

    // MARK: - 属性

    /// 波浪颜色
    public var waveColor: UIColor = .systemBlue {
        didSet {
            waveLayer.fillColor = waveColor.cgColor
        }
    }

    /// 波幅
    public var amplitude: CGFloat = 10 {
        didSet {
            updateWave()
        }
    }

    /// 波长
    public var waveLength: CGFloat = 100 {
        didSet {
            updateWave()
        }
    }

    /// 波浪速度
    public var speed: CGFloat = 2

    /// 填充比例 (0.0 - 1.0)
    public var fillRatio: CGFloat = 0.5 {
        didSet {
            fillRatio = max(0, min(1, fillRatio))
            updateWave()
        }
    }

    /// 是否动画
    public var isAnimating: Bool = true {
        didSet {
            updateTimer()
        }
    }

    // MARK: - 私有属性

    private let waveLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.systemBlue.cgColor
        return layer
    }()

    private let maskLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        return layer
    }()

    private var phase: CGFloat = 0
    private var timer: Timer?

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupWaterWave()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupWaterWave()
    }

    // MARK: - 设置

    private func setupWaterWave() {
        layer.addSublayer(waveLayer)
        waveLayer.mask = maskLayer

        clipsToBounds = true
        layer.cornerRadius = bounds.width / 2

        updateTimer()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = bounds.width / 2
        updateWave()
    }

    // MARK: - 波浪更新

    private func updateWave() {
        let width = bounds.width
        let height = bounds.height
        let midY = height * (1 - fillRatio)

        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: midY))

        for x in stride(from: 0, through: width, by: 1) {
            let normalizedX = x / waveLength
            let angle = 2 * .pi * normalizedX + phase
            let y = midY + amplitude * sin(angle)
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.close()

        waveLayer.path = path.cgPath
        waveLayer.frame = bounds

        // 圆形遮罩
        let maskPath = UIBezierPath(ovalIn: bounds)
        maskLayer.path = maskPath.cgPath
    }

    private func updateTimer() {
        timer?.invalidate()
        timer = nil

        guard isAnimating else { return }

        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            self.phase += self.speed * 0.02
            self.updateWave()
        }
    }

    // MARK: - 公共方法

    /// 开始动画
    public func startAnimating() {
        isAnimating = true
    }

    /// 停止动画
    public func stopAnimating() {
        isAnimating = false
    }

    /// 设置填充比例（带动画）
    public func setFillRatio(_ ratio: CGFloat, animated: Bool = true) {
        let targetRatio = max(0, min(1, ratio))

        if animated {
            UIView.animate(withDuration: 0.3) {
                self.fillRatio = targetRatio
            }
        } else {
            fillRatio = targetRatio
        }
    }
}

// MARK: - LSRippleEffectView

/// 涟漪效果视图
public class LSRippleEffectView: UIView {

    // MARK: - 属性

    /// 涟漪颜色
    public var rippleColor: UIColor = .white.withAlphaComponent(0.5)

    /// 涟漪数量
    public var rippleCount: Int = 3

    /// 涟漪持续时间
    public var rippleDuration: TimeInterval = 1.5

    /// 涟漪最大半径
    public var maxRadius: CGFloat = 100

    // MARK: - 私有属性

    private var rippleLayers: [CAShapeLayer] = []

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupRipple()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupRipple()
    }

    // MARK: - 设置

    private func setupRipple() {
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    // MARK: - 涟漪动画

    /// 开始涟漪动画
    public func startRipple(from point: CGPoint) {
        for i in 0..<rippleCount {
            let delay = TimeInterval(i) * rippleDuration / Double(rippleCount)

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.createRipple(at: point)
            }
        }
    }

    private func createRipple(at point: CGPoint) {
        let rippleLayer = CAShapeLayer()
        rippleLayer.fillColor = UIColor.clear.cgColor
        rippleLayer.strokeColor = rippleColor.cgColor
        rippleLayer.lineWidth = 2
        rippleLayer.opacity = 1

        layer.addSublayer(rippleLayer)
        rippleLayers.append(rippleLayer)

        // 创建动画
        let path = UIBezierPath(arcCenter: point, radius: 0, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        rippleLayer.path = path.cgPath

        // 放大动画
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1
        scaleAnimation.toValue = maxRadius / 10

        // 路径动画
        let pathAnimation = CABasicAnimation(keyPath: "path")
        let finalPath = UIBezierPath(arcCenter: point, radius: maxRadius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        pathAnimation.toValue = finalPath.cgPath

        // 透明度动画
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 1
        opacityAnimation.toValue = 0

        // 组合动画
        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [scaleAnimation, pathAnimation, opacityAnimation]
        animationGroup.duration = rippleDuration
        animationGroup.timingFunction = CAMediaTimingFunction(name: .easeOut)
        animationGroup.fillMode = .forwards
        animationGroup.isRemovedOnCompletion = false

        rippleLayer.add(animationGroup, forKey: "ripple")

        // 移除
        DispatchQueue.main.asyncAfter(deadline: .now() + rippleDuration) { [weak self, weak rippleLayer] in
            rippleLayer?.removeFromSuperlayer()
            if let index = self?.rippleLayers.firstIndex(where: { $0 === rippleLayer }) {
                self?.rippleLayers.remove(at: index)
            }
        }
    }

    /// 停止所有涟漪
    public func stopAllRipples() {
        rippleLayers.forEach { $0.removeAllAnimations() }
        rippleLayers.forEach { $0.removeFromSuperlayer() }
        rippleLayers.removeAll()
    }
}

// MARK: - LSRippleButton

/// 带涟漪效果的按钮
public class LSRippleButton: UIButton {

    // MARK: - 属性

    /// 涟漪颜色
    public var rippleColor: UIColor = .white.withAlphaComponent(0.3)

    /// 涟漪持续时间
    public var rippleDuration: TimeInterval = 0.6

    /// 是否启用涟漪
    public var rippleEnabled: Bool = true

    // MARK: - 私有属性

    private var rippleLayers: [CAShapeLayer] = []

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupRipple()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupRipple()
    }

    // MARK: - 设置

    private func setupRipple() {
        clipsToBounds = true
    }

    // MARK: - 触摸处理

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        guard rippleEnabled, let touch = touches.first else { return }

        let point = touch.location(in: self)
        createRipple(at: point)
    }

    private func createRipple(at point: CGPoint) {
        let rippleLayer = CAShapeLayer()
        rippleLayer.fillColor = rippleColor.cgColor
        rippleLayer.opacity = 1

        layer.insertSublayer(rippleLayer, at: 0)
        rippleLayers.append(rippleLayer)

        let maxRadius = max(bounds.width, bounds.height)
        let path = UIBezierPath(ovalIn: CGRect(x: point.x - 5, y: point.y - 5, width: 10, height: 10))
        rippleLayer.path = path.cgPath

        // 放大动画
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1
        scaleAnimation.toValue = maxRadius / 10

        // 路径动画
        let pathAnimation = CABasicAnimation(keyPath: "path")
        let finalPath = UIBezierPath(ovalIn: CGRect(x: point.x - maxRadius / 2, y: point.y - maxRadius / 2, width: maxRadius, height: maxRadius))
        pathAnimation.toValue = finalPath.cgPath

        // 透明度动画
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 1
        opacityAnimation.toValue = 0

        // 组合动画
        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [scaleAnimation, pathAnimation, opacityAnimation]
        animationGroup.duration = rippleDuration
        animationGroup.timingFunction = CAMediaTimingFunction(name: .easeOut)
        animationGroup.fillMode = .forwards
        animationGroup.isRemovedOnCompletion = false

        rippleLayer.add(animationGroup, forKey: "ripple")

        DispatchQueue.main.asyncAfter(deadline: .now() + rippleDuration) { [weak self, weak rippleLayer] in
            rippleLayer?.removeFromSuperlayer()
            if let index = self?.rippleLayers.firstIndex(where: { $0 === rippleLayer }) {
                self?.rippleLayers.remove(at: index)
            }
        }
    }
}

// MARK: - UIView Extension (Wave)

public extension UIView {

    private enum AssociatedKeys {
        static var waveViewKey: UInt8 = 0
    }var ls_waveView: LSWaveView? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.waveViewKey) as? LSWaveView
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.waveViewKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// 添加波浪视图
    @discardableResult
    func ls_addWave(
        color: UIColor = .systemBlue,
        amplitude: CGFloat = 10,
        position: WavePosition = .bottom
    ) -> LSWaveView {
        let waveView = LSWaveView(color: color, amplitude: amplitude)
        waveView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(waveView)

        switch position {
        case .top:
            NSLayoutConstraint.activate([
                waveView.topAnchor.constraint(equalTo: topAnchor),
                waveView.leadingAnchor.constraint(equalTo: leadingAnchor),
                waveView.trailingAnchor.constraint(equalTo: trailingAnchor),
                waveView.heightAnchor.constraint(equalToConstant: 100)
            ])
        case .bottom:
            NSLayoutConstraint.activate([
                waveView.bottomAnchor.constraint(equalTo: bottomAnchor),
                waveView.leadingAnchor.constraint(equalTo: leadingAnchor),
                waveView.trailingAnchor.constraint(equalTo: trailingAnchor),
                waveView.heightAnchor.constraint(equalToConstant: 100)
            ])
        }

        ls_waveView = waveView
        return waveView
    }

    /// 波浪位置
    enum WavePosition {
        case top
        case bottom
    }

    /// 添加水波纹视图
    @discardableResult
    func ls_addWaterWave(
        size: CGFloat = 100,
        color: UIColor = .systemBlue
    ) -> LSWaterWaveView {
        let waterWave = LSWaterWaveView()
        waterWave.waveColor = color
        waterWave.translatesAutoresizingMaskIntoConstraints = false

        addSubview(waterWave)

        NSLayoutConstraint.activate([
            waterWave.centerXAnchor.constraint(equalTo: centerXAnchor),
            waterWave.centerYAnchor.constraint(equalTo: centerYAnchor),
            waterWave.widthAnchor.constraint(equalToConstant: size),
            waterWave.heightAnchor.constraint(equalToConstant: size)
        ])

        return waterWave
    }

    /// 添加涟漪效果
    func ls_showRipple(at point: CGPoint) {
        let rippleView = LSRippleEffectView(frame: bounds)
        addSubview(rippleView)
        rippleView.startRipple(from: point)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            rippleView.removeFromSuperview()
        }
    }
}

// MARK: - UIButton Extension (Ripple)

public extension UIButton {

    /// 添加涟漪效果
    func ls_addRipple(color: UIColor = .white.withAlphaComponent(0.3)) {
        let rippleButton = LSRippleButton(type: custom)
        rippleButton.rippleColor = color
        rippleButton.translatesAutoresizingMaskIntoConstraints = false

        insertSubview(rippleButton, at: 0)

        NSLayoutConstraint.activate([
            rippleButton.topAnchor.constraint(equalTo: topAnchor),
            rippleButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            rippleButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            rippleButton.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

#endif

//
//  LSActivityIndicatorView.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  活动指示器 - 自定义加载动画
//

#if canImport(UIKit)
import UIKit

// MARK: - LSActivityIndicatorView

/// 活动指示器
public class LSActivityIndicatorView: UIView {

    // MARK: - 样式枚举

    /// 指示器样式
    public enum Style {
        case system             // 系统样式（UIActivityIndicatorView）
        case custom             // 自定义样式
        case dots               // 点动画
        case bars               // 条动画
        case circle             // 圆环动画
        case pacman             // 吃豆人动画
        case arc                // 弧形动画
    }

    // MARK: - 属性

    /// 样式
    public var style: Style = .system {
        didSet {
            updateStyle()
        }
    }

    /// 颜色
    public var color: UIColor = .gray {
        didSet {
            tintColor = color
            updateColor()
        }
    }

    /// 是否正在动画
    public private(set) var isAnimating: Bool = false

    /// 动画持续时间（秒）
    public var duration: TimeInterval = 1.0

    /// 系统指示器
    private lazy var systemIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = false
        return indicator
    }()

    /// 自定义动画图层
    private var animationLayers: [CAShapeLayer] = []

    /// 动画计时器
    private var displayLink: CADisplayLink?

    /// 动画开始时间
    private var animationStartTime: CFTimeInterval?

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - 设置

    private func setupUI() {
        clipsToBounds = true
        updateStyle()
    }

    private func updateStyle() {
        // 清除旧图层
        animationLayers.forEach { $0.removeFromSuperlayer() }
        animationLayers.removeAll()
        systemIndicator.removeFromSuperview()

        switch style {
        case .system:
            addSubview(systemIndicator)
            systemIndicator.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                systemIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
                systemIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
            systemIndicator.color = color

        case .custom:
            setupCustomAnimation()

        case .dots:
            setupDotsAnimation()

        case .bars:
            setupBarsAnimation()

        case .circle:
            setupCircleAnimation()

        case .pacman:
            setupPacmanAnimation()

        case .arc:
            setupArcAnimation()
        }
    }

    private func updateColor() {
        systemIndicator.color = color
        animationLayers.forEach { $0.strokeColor = color.cgColor }
        animationLayers.forEach { $0.fillColor = color.cgColor }
    }

    // MARK: - 动画设置

    private func setupCustomAnimation() {
        // 创建简单的旋转动画
        let shape = CAShapeLayer()
        shape.path = UIBezierPath(
            arcCenter: .zero,
            radius: 15,
            startAngle: 0,
            endAngle: .pi * 1.5,
            clockwise: true
        ).cgPath
        shape.strokeColor = color.cgColor
        shape.fillColor = UIColor.clear.cgColor
        shape.lineWidth = 3
        shape.lineCap = .round

        let bounds = CGRect(x: 0, y: 0, width: 40, height: 40)
        shape.bounds = bounds
        shape.position = CGPoint(x: bounds.width / 2, y: bounds.height / 2)

        layer.addSublayer(shape)
        animationLayers.append(shape)

        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = .pi * 2
        rotation.duration = duration
        rotation.repeatCount = .infinity
        shape.add(rotation, forKey: "rotation")
    }

    private func setupDotsAnimation() {
        let dotSize: CGFloat = 8
        let spacing: CGFloat = 12
        let totalWidth = CGFloat(3) * dotSize + CGFloat(2) * spacing

        for i in 0..<3 {
            let dot = CAShapeLayer()
            let path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: dotSize, height: dotSize))
            dot.path = path.cgPath
            dot.fillColor = color.cgColor
            dot.bounds = CGRect(x: 0, y: 0, width: dotSize, height: dotSize)

            let x = (bounds.width - totalWidth) / 2 + CGFloat(i) * (dotSize + spacing)
            dot.position = CGPoint(x: x + dotSize / 2, y: bounds.height / 2)

            layer.addSublayer(dot)
            animationLayers.append(dot)
        }
    }

    private func setupBarsAnimation() {
        let barWidth: CGFloat = 4
        let barHeight: CGFloat = 20
        let spacing: CGFloat = 4
        let totalWidth = CGFloat(5) * barWidth + CGFloat(4) * spacing

        for i in 0..<5 {
            let bar = CAShapeLayer()
            let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: barWidth, height: barHeight), cornerRadius: 2)
            bar.path = path.cgPath
            bar.fillColor = color.cgColor
            bar.bounds = CGRect(x: 0, y: 0, width: barWidth, height: barHeight)

            let x = (bounds.width - totalWidth) / 2 + CGFloat(i) * (barWidth + spacing)
            bar.position = CGPoint(x: x + barWidth / 2, y: bounds.height / 2)

            layer.addSublayer(bar)
            animationLayers.append(bar)
        }
    }

    private func setupCircleAnimation() {
        let shape = CAShapeLayer()
        let rect = CGRect inset: CGRect(x: 0, y: 0, width: 36, height: 36))
        let path = UIBezierPath(ovalIn: rect)
        shape.path = path.cgPath
        shape.strokeColor = color.cgColor
        shape.fillColor = UIColor.clear.cgColor
        shape.lineWidth = 3
        shape.bounds = CGRect(x: 0, y: 0, width: 40, height: 40)
        shape.position = CGPoint(x: bounds.width / 2, y: bounds.height / 2)

        layer.addSublayer(shape)
        animationLayers.append(shape)
    }

    private func setupPacmanAnimation() {
        let shape = CAShapeLayer()
        let path = UIBezierPath(
            arcCenter: .zero,
            radius: 15,
            startAngle: .pi * 0.2,
            endAngle: .pi * 1.8,
            clockwise: true
        )
        path.close()
        shape.path = path.cgPath
        shape.fillColor = color.cgColor
        shape.bounds = CGRect(x: 0, y: 0, width: 36, height: 36)
        shape.position = CGPoint(x: bounds.width / 2, y: bounds.height / 2)

        layer.addSublayer(shape)
        animationLayers.append(shape)

        // 张嘴动画
        let animation = CABasicAnimation(keyPath: "path")
        animation.duration = duration / 2
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.toValue = UIBezierPath(
            arcCenter: .zero,
            radius: 15,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: true
        ).cgPath
        shape.add(animation, forKey: "mouth")
    }

    private func setupArcAnimation() {
        let shape = CAShapeLayer()
        let rect = CGRect(x: 0, y: 0, width: 36, height: 36)
        let path = UIBezierPath(
            arcCenter: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2 - 3,
            startAngle: -.pi / 2,
            endAngle: -.pi / 2 + .pi * 1.5,
            clockwise: true
        )
        shape.path = path.cgPath
        shape.strokeColor = color.cgColor
        shape.fillColor = UIColor.clear.cgColor
        shape.lineWidth = 3
        shape.lineCap = .round
        shape.bounds = CGRect(x: 0, y: 0, width: 40, height: 40)
        shape.position = CGPoint(x: bounds.width / 2, y: bounds.height / 2)

        layer.addSublayer(shape)
        animationLayers.append(shape)

        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = .pi * 2
        rotation.duration = duration
        rotation.repeatCount = .infinity
        shape.add(rotation, forKey: "rotation")
    }

    // MARK: - 动画控制

    /// 开始动画
    public func startAnimating() {
        guard !isAnimating else { return }

        isAnimating = true
        isHidden = false

        switch style {
        case .system:
            systemIndicator.startAnimating()

        case .dots, .bars:
            startDisplayLinkAnimation()

        case .custom, .circle, .arc, .pacman:
            // 动画已在 setup 中配置
            break
        }
    }

    /// 停止动画
    public func stopAnimating() {
        isAnimating = false

        switch style {
        case .system:
            systemIndicator.stopAnimating()

        case .dots, .bars:
            stopDisplayLinkAnimation()

        default:
            animationLayers.forEach { $0.removeAllAnimations() }
        }
    }

    private func startDisplayLinkAnimation() {
        stopDisplayLinkAnimation()

        let displayLink = CADisplayLink(target: self, selector: #selector(animationTick))
        displayLink.add(to: .main, forMode: .common)
        self.displayLink = displayLink
        animationStartTime = CACurrentMediaTime()
    }

    private func stopDisplayLinkAnimation() {
        displayLink?.invalidate()
        displayLink = nil
        animationStartTime = nil
    }

    @objc private func animationTick() {
        guard let startTime = animationStartTime else { return }
        let elapsed = CACurrentMediaTime() - startTime

        switch style {
        case .dots:
            animateDots(elapsed: elapsed)
        case .bars:
            animateBars(elapsed: elapsed)
        default:
            break
        }
    }

    private func animateDots(elapsed: CFTimeInterval) {
        let cycle = elapsed.truncatingRemainder(dividingBy: duration)
        let phase = cycle / (duration / 3)

        for (index, layer) in animationLayers.enumerated() {
            let delay = Double(index) * (duration / 6)
            var scale: CGFloat = 1.0

            if cycle > delay {
                let localCycle = cycle - delay
                let progress = (localCycle / (duration / 3)).truncatingRemainder(dividingBy: 1)
                scale = 0.5 + 0.5 * sin(progress * .pi)
            } else {
                scale = 0.5
            }

            layer.setAffineTransform(CGAffineTransform(scaleX: scale, y: scale))
        }
    }

    private func animateBars(elapsed: CFTimeInterval) {
        let cycle = elapsed.truncatingRemainder(dividingBy: duration)

        for (index, layer) in animationLayers.enumerated() {
            let delay = Double(index) * (duration / 10)
            var scaleY: CGFloat = 1.0

            if cycle > delay {
                let localCycle = cycle - delay
                let progress = (localCycle / (duration / 5)).truncatingRemainder(dividingBy: 1)
                scaleY = 0.3 + 0.7 * sin(progress * .pi)
            } else {
                scaleY = 0.3
            }

            layer.setAffineTransform(CGAffineTransform(scaleX: 1, y: scaleY))
        }
    }

    // MARK: - 便捷方法

    /// 创建默认指示器
    static func defaultIndicator() -> LSActivityIndicatorView {
        let indicator = LSActivityIndicatorView()
        indicator.style = .system
        indicator.color = .gray
        return indicator
    }

    /// 创建自定义指示器
    static func customIndicator(style: Style, color: UIColor = .gray) -> LSActivityIndicatorView {
        let indicator = LSActivityIndicatorView()
        indicator.style = style
        indicator.color = color
        return indicator
    }
}

// MARK: - UIView Extension (加载指示器)

public extension UIView {

    /// 关联的加载指示器
    private static var activityIndicatorKey: UInt8 = 0

    /// 加载指示器
    var ls_activityIndicator: LSActivityIndicatorView? {
        get {
            return objc_getAssociatedObject(self, &UIView.activityIndicatorKey) as? LSActivityIndicatorView
        }
        set {
            objc_setAssociatedObject(self, &UIView.activityIndicatorKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// 显示加载指示器
    ///
    /// - Parameters:
    ///   - style: 样式
    ///   - color: 颜色
    func ls_showLoading(
        style: LSActivityIndicatorView.Style = .system,
        color: UIColor = .gray
    ) {
        // 移除旧的
        ls_hideLoading()

        // 创建新的
        let indicator = LSActivityIndicatorView()
        indicator.style = style
        indicator.color = color
        indicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        indicator.center = center
        indicator.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        addSubview(indicator)
        ls_activityIndicator = indicator
        indicator.startAnimating()
    }

    /// 隐藏加载指示器
    func ls_hideLoading() {
        ls_activityIndicator?.stopAnimating()
        ls_activityIndicator?.removeFromSuperview()
        ls_activityIndicator = nil
    }
}

// MARK: - UIViewController Extension (加载指示器)

public extension UIViewController {

    /// 显示加载指示器
    ///
    /// - Parameters:
    ///   - style: 样式
    ///   - color: 颜色
    func ls_showLoading(
        style: LSActivityIndicatorView.Style = .system,
        color: UIColor = .gray
    ) {
        guard let view = view ?? navigationController?.view else { return }
        view.ls_showLoading(style: style, color: color)
    }

    /// 隐藏加载指示器
    func ls_hideLoading() {
        view?.ls_hideLoading()
    }
}

#endif

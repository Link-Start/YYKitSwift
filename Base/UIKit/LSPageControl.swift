//
//  LSPageControl.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  页面指示器 - 自定义样式的页面控制组件
//

#if canImport(UIKit)
import UIKit

// MARK: - LSPageControl

/// 页面指示器
@MainActor
public class LSPageControl: UIView {

    // MARK: - 类型定义

    /// 指示器样式
    public enum IndicatorStyle {
        case defaultStyle    // 默认圆点
        case scale          // 缩放效果
        case image          // 自定义图片
        case line           // 线条
        case segment        // 分段
    }

    /// 页面变化回调
    public typealias PageChangeHandler = (Int) -> Void

    // MARK: - 属性

    /// 页面数量
    public var numberOfPages: Int = 0 {
        didSet {
            numberOfPages = max(0, numberOfPages)
            updateIndicators()
        }
    }

    /// 当前页面
    public var currentPage: Int = 0 {
        didSet {
            currentPage = max(0, min(numberOfPages - 1, currentPage))
            updateCurrentPage()
        }
    }

    /// 指示器样式
    public var indicatorStyle: IndicatorStyle = .defaultStyle {
        didSet {
            updateStyle()
        }
    }

    /// 指示器大小
    public var indicatorSize: CGSize = CGSize(width: 8, height: 8) {
        didSet {
            updateIndicatorSize()
        }
    }

    /// 指示器间距
    public var indicatorSpacing: CGFloat = 8 {
        didSet {
            updateLayout()
        }
    }

    /// 当前指示器颜色
    public var currentPageIndicatorTintColor: UIColor = .systemBlue {
        didSet {
            updateColors()
        }
    }

    /// 页面指示器颜色
    public var pageIndicatorTintColor: UIColor = .systemGray4 {
        didSet {
            updateColors()
        }
    }

    /// 是否隐藏单页指示器
    public var hidesForSinglePage: Bool = true {
        didSet {
            updateVisibility()
        }
    }

    /// 页面变化回调
    public var onPageChanged: PageChangeHandler?

    /// 是否允许交互
    public var allowsUserInteraction: Bool = true {
        didSet {
            updateInteraction()
        }
    }

    /// 缩放比例（用于 scale 样式）
    public var scaleRatio: CGFloat = 1.5

    /// 当前页图片
    public var currentPageImage: UIImage? {
        didSet {
            if indicatorStyle == .image {
                updateImages()
            }
        }
    }

    /// 页面图片
    public var pageImage: UIImage? {
        didSet {
            if indicatorStyle == .image {
                updateImages()
            }
        }
    }

    // MARK: - 私有属性

    private var indicatorViews: [UIView] = []

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupPageControl()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPageControl()
    }

    public convenience init(numberOfPages: Int = 0, currentPage: Int = 0) {
        self.init(frame: .zero)
        self.numberOfPages = numberOfPages
        self.currentPage = currentPage
    }

    // MARK: - 设置

    private func setupPageControl() {
        backgroundColor = .clear
        clipsToBounds = true

        updateIndicators()
        updateVisibility()
    }

    // MARK: - 布局

    public override func layoutSubviews() {
        super.layoutSubviews()
        updateLayout()
    }

    // MARK: - 更新方法

    private func updateIndicators() {
        // 移除旧的指示器
        indicatorViews.forEach { $0.removeFromSuperview() }
        indicatorViews.removeAll()

        // 创建新的指示器
        for i in 0..<numberOfPages {
            let indicator = createIndicator(for: i)
            indicator.translatesAutoresizingMaskIntoConstraints = false
            addSubview(indicator)
            indicatorViews.append(indicator)

            // 添加点击手势
            if allowsUserInteraction {
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleIndicatorTap(_:)))
                indicator.addGestureRecognizer(tapGesture)
                indicator.isUserInteractionEnabled = true
                indicator.tag = i
            }
        }

        updateCurrentPage()
        updateColors()
        updateStyle()
        updateLayout()
        updateVisibility()
    }

    private func createIndicator(for index: Int) -> UIView {
        let indicator = UIView()
        indicator.backgroundColor = pageIndicatorTintColor
        return indicator
    }

    private func updateCurrentPage() {
        for (index, indicator) in indicatorViews.enumerated() {
            let isCurrent = (index == currentPage)

            switch indicatorStyle {
            case .defaultStyle:
                indicator.backgroundColor = isCurrent ? currentPageIndicatorTintColor : pageIndicatorTintColor

            case .scale:
                indicator.backgroundColor = isCurrent ? currentPageIndicatorTintColor : pageIndicatorTintColor

                if isCurrent {
                    UIView.animate(withDuration: 0.2) {
                        indicator.transform = CGAffineTransform(scaleX: self.scaleRatio, y: self.scaleRatio)
                    }
                } else {
                    UIView.animate(withDuration: 0.2) {
                        indicator.transform = .identity
                    }
                }

            case .image:
                indicator.layer.contents = isCurrent ? currentPageImage?.cgImage : pageImage?.cgImage

            case .line:
                let width = isCurrent ? indicatorSize.width * 2 : indicatorSize.width
                UIView.animate(withDuration: 0.2) {
                    indicator.frame.size.width = width
                }

            case .segment:
                indicator.backgroundColor = isCurrent ? currentPageIndicatorTintColor : pageIndicatorTintColor
            }
        }

        onPageChanged?(currentPage)
    }

    private func updateColors() {
        for (index, indicator) in indicatorViews.enumerated() {
            let isCurrent = (index == currentPage)

            if indicatorStyle == .defaultStyle || indicatorStyle == .segment {
                indicator.backgroundColor = isCurrent ? currentPageIndicatorTintColor : pageIndicatorTintColor
            }
        }
    }

    private func updateStyle() {
        for indicator in indicatorViews {
            switch indicatorStyle {
            case .defaultStyle:
                indicator.layer.cornerRadius = indicatorSize.width / 2

            case .scale:
                indicator.layer.cornerRadius = indicatorSize.width / 2

            case .image:
                indicator.layer.cornerRadius = 0
                indicator.backgroundColor = .clear

            case .line:
                indicator.layer.cornerRadius = indicatorSize.height / 2

            case .segment:
                indicator.layer.cornerRadius = 2
            }
        }
    }

    private func updateIndicatorSize() {
        updateLayout()
    }

    private func updateLayout() {
        let totalWidth = CGFloat(indicatorViews.count) * indicatorSize.width + CGFloat(indicatorViews.count - 1) * indicatorSpacing
        let startX = (bounds.width - totalWidth) / 2

        for (index, indicator) in indicatorViews.enumerated() {
            let x = startX + CGFloat(index) * (indicatorSize.width + indicatorSpacing)
            let y = (bounds.height - indicatorSize.height) / 2

            indicator.frame = CGRect(x: x, y: y, width: indicatorSize.width, height: indicatorSize.height)

            if indicatorStyle == .line {
                let isCurrent = (index == currentPage)
                let width = isCurrent ? indicatorSize.width * 2 : indicatorSize.width
                indicator.frame.size.width = width
            }
        }
    }

    private func updateVisibility() {
        isHidden = hidesForSinglePage && numberOfPages <= 1
    }

    private func updateInteraction() {
        for indicator in indicatorViews {
            indicator.isUserInteractionEnabled = allowsUserInteraction
        }
    }

    private func updateImages() {
        for (index, indicator) in indicatorViews.enumerated() {
            let isCurrent = (index == currentPage)
            indicator.layer.contents = isCurrent ? currentPageImage?.cgImage : pageImage?.cgImage
        }
    }

    // MARK: - 手势处理

    @objc private func handleIndicatorTap(_ gesture: UITapGestureRecognizer) {
        guard allowsUserInteraction,
              let index = gesture.view?.tag,
              index < numberOfPages else {
            return
        }

        currentPage = index
    }

    // MARK: - 公共方法

    /// 更新当前页面（带动画）
    public func setCurrentPage(_ page: Int, animated: Bool = true) {
        let targetPage = max(0, min(numberOfPages - 1, page))

        if animated && currentPage != targetPage {
            UIView.animate(withDuration: 0.3) {
                self.currentPage = targetPage
            }
        } else {
            currentPage = targetPage
        }
    }

    /// 计算所需宽度
    public var sizeForNumberOfPages: CGSize {
        let width = CGFloat(numberOfPages) * indicatorSize.width + CGFloat(max(0, numberOfPages - 1)) * indicatorSpacing
        return CGSize(width: width, height: indicatorSize.height)
    }
}

// MARK: - LSAnimatedPageControl

/// 动画页面指示器
public class LSAnimatedPageControl: LSPageControl {

    // MARK: - 属性

    /// 动画时长
    public var animationDuration: TimeInterval = 0.3

    /// 是否弹性动画
    public var isSpringAnimation: Bool = true

    // MARK: - 更新当前页面

    private override func updateCurrentPage() {
        guard currentPage < indicatorViews.count else { return }

        for (index, indicator) in indicatorViews.enumerated() {
            let isCurrent = (index == currentPage)
            let targetScale = isCurrent ? scaleRatio : 1.0
            let targetColor = isCurrent ? currentPageIndicatorTintColor : pageIndicatorTintColor

            if isSpringAnimation {
                UIView.animate(
                    withDuration: animationDuration,
                    delay: 0,
                    usingSpringWithDamping: 0.6,
                    initialSpringVelocity: 0.5,
                    options: .curveEaseInOut
                ) {
                    indicator.transform = CGAffineTransform(scaleX: targetScale, y: targetScale)
                    indicator.backgroundColor = targetColor
                }
            } else {
                UIView.animate(withDuration: animationDuration) {
                    indicator.transform = CGAffineTransform(scaleX: targetScale, y: targetScale)
                    indicator.backgroundColor = targetColor
                }
            }
        }

        onPageChanged?(currentPage)
    }
}

// MARK: - LSProgressPageControl

/// 进度页面指示器（连续线条）
public class LSProgressPageControl: LSPageControl {

    // MARK: - 属性

    /// 进度条高度
    public var progressHeight: CGFloat = 2

    /// 进度条圆角
    public var progressCornerRadius: CGFloat = 1

    // MARK: - UI 组件

    private let trackView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let progressView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        indicatorStyle = .line
        setupProgressControl()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        indicatorStyle = .line
        setupProgressControl()
    }

    // MARK: - 设置

    private func setupProgressControl() {
        addSubview(trackView)
        addSubview(progressView)

        NSLayoutConstraint.activate([
            trackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            trackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            trackView.heightAnchor.constraint(equalToConstant: progressHeight),

            progressView.centerYAnchor.constraint(equalTo: centerYAnchor),
            progressView.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: progressHeight)
        ])

        trackView.layer.cornerRadius = progressCornerRadius
        progressView.layer.cornerRadius = progressCornerRadius
    }

    // MARK: - 更新

    private override func updateCurrentPage() {
        guard numberOfPages > 0 else { return }

        let progress = CGFloat(currentPage) / CGFloat(numberOfPages - 1)
        let width = bounds.width * progress

        UIView.animate(withDuration: 0.3) {
            self.progressView.frame.size.width = width
        }
    }

    private override func updateColors() {
        trackView.backgroundColor = pageIndicatorTintColor
        progressView.backgroundColor = currentPageIndicatorTintColor
    }
}

// MARK: - LSDotPageControl

/// 圆点页面指示器（带动画）
public class LSDotPageControl: LSPageControl {

    // MARK: - 属性

    /// 是否脉冲动画
    public var isPulseAnimation: Bool = false

    /// 脉冲颜色
    public var pulseColor: UIColor = .systemBlue.withAlphaComponent(0.3)

    // MARK: - UI 组件

    private var pulseLayers: [CAShapeLayer] = []

    // MARK: - 更新

    private override func updateCurrentPage() {
        super.updateCurrentPage()

        if isPulseAnimation {
            addPulseAnimation()
        }
    }

    private func addPulseAnimation() {
        // 移除旧的脉冲
        pulseLayers.forEach { $0.removeFromSuperlayer() }
        pulseLayers.removeAll()

        guard currentPage < indicatorViews.count else { return }

        let indicator = indicatorViews[currentPage]
        let pulseLayer = CAShapeLayer()
        pulseLayer.path = UIBezierPath(
            ovalIn: CGRect(
                x: -indicatorSize.width,
                y: -indicatorSize.height,
                width: indicatorSize.width * 3,
                height: indicatorSize.height * 3
            )
        ).cgPath
        pulseLayer.fillColor = pulseColor.cgColor
        pulseLayer.opacity = 0
        indicator.layer.insertSublayer(pulseLayer, at: 0)
        pulseLayers.append(pulseLayer)

        // 脉冲动画
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 0.5
        scaleAnimation.toValue = 1.5

        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 0.5
        opacityAnimation.toValue = 0

        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [scaleAnimation, opacityAnimation]
        animationGroup.duration = 1.5
        animationGroup.repeatCount = .infinity
        pulseLayer.add(animationGroup, forKey: "pulse")
    }
}

// MARK: - UIScrollView Extension (PageControl)

public extension UIScrollView {

    /// 关联的页面指示器
    private static var pageControlKey: UInt8 = 0

    var ls_pageControl: LSPageControl? {
        get {
            return objc_getAssociatedObject(self, &UIScrollView.pageControlKey) as? LSPageControl
        }
        set {
            objc_setAssociatedObject(
                self,
                &UIScrollView.pageControlKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// 添加页面指示器
    @discardableResult
    func ls_addPageControl(
        position: PageControlPosition = .bottomCenter,
        numberOfPages: Int = 0
    ) -> LSPageControl {
        let pageControl = LSPageControl(numberOfPages: numberOfPages)
        pageControl.translatesAutoresizingMaskIntoConstraints = false

        // 查找父视图
        var currentView: UIView? = superview
        while currentView != nil {
            if let scrollView = currentView as? UIScrollView {
                scrollView.addSubview(pageControl)

                switch position {
                case .topCenter:
                    NSLayoutConstraint.activate([
                        pageControl.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 8),
                        pageControl.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor)
                    ])

                case .topLeft:
                    NSLayoutConstraint.activate([
                        pageControl.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 8),
                        pageControl.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16)
                    ])

                case .topRight:
                    NSLayoutConstraint.activate([
                        pageControl.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 8),
                        pageControl.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16)
                    ])

                case .bottomCenter:
                    NSLayoutConstraint.activate([
                        pageControl.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -8),
                        pageControl.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor)
                    ])

                case .bottomLeft:
                    NSLayoutConstraint.activate([
                        pageControl.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -8),
                        pageControl.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16)
                    ])

                case .bottomRight:
                    NSLayoutConstraint.activate([
                        pageControl.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -8),
                        pageControl.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16)
                    ])
                }

                // 监听滚动
                pageControl.ls_pageControl = pageControl
                setupPageControlSync()

                break
            }
            currentView = currentView?.superview
        }

        return pageControl
    }

    /// 页面指示器位置
    enum PageControlPosition {
        case topCenter
        case topLeft
        case topRight
        case bottomCenter
        case bottomLeft
        case bottomRight
    }

    private func setupPageControlSync() {
        // 使用 KVO 监听 contentOffset
        addObserver(self, forKeyPath: "contentOffset", options: .new, context: nil)
    }

    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentOffset" {
            updatePageControl()
        }
    }

    private func updatePageControl() {
        guard let pageControl = ls_pageControl,
              pageControl.numberOfPages > 0 else {
            return
        }

        let pageWidth = bounds.width
        let currentPage = Int(round(contentOffset.x / pageWidth))
        pageControl.currentPage = currentPage
    }
}

// MARK: - UIPageViewController Extension

public extension UIPageViewController {

    /// 添加页面指示器
    @discardableResult
    func ls_addPageControl(
        position: UIScrollView.PageControlPosition = .bottomCenter
    ) -> LSPageControl {
        guard let scrollView = view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView else {
            return LSPageControl()
        }

        return scrollView.ls_addPageControl(position: position)
    }
}

#endif

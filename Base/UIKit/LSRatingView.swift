//
//  LSRatingView.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  评分视图 - 星级评分组件
//

#if canImport(UIKit)
import UIKit

// MARK: - LSRatingView

/// 评分视图
public class LSRatingView: UIView {

    // MARK: - 类型定义

    /// 评分变化回调
    public typealias RatingChangeHandler = (Float) -> Void

    /// 评分模式
    public enum RatingMode {
        case whole         // 整星
        case half          // 半星
        case precise       // 精确
    }

    /// 图标样式
    public enum IconStyle {
        case star          // 星星
        case heart         // 心形
        case circle        // 圆形
        case custom(UIImage) // 自定义
    }

    // MARK: - 属性

    /// 最大评分
    public var maximumRating: Int = 5 {
        didSet {
            updateStars()
        }
    }

    /// 当前评分
    public var rating: Float = 0 {
        didSet {
            updateRatingDisplay()
        }
    }

    /// 评分模式
    public var ratingMode: RatingMode = .whole {
        didSet {
            updateRatingDisplay()
        }
    }

    /// 图标样式
    public var iconStyle: IconStyle = .star {
        didSet {
            updateStars()
        }
    }

    /// 填充颜色
    public var fillColor: UIColor = .systemYellow {
        didSet {
            updateColors()
        }
    }

    /// 空心颜色
    public var emptyColor: UIColor = .systemGray4 {
        didSet {
            updateColors()
        }
    }

    /// 星星大小
    public var starSize: CGSize = CGSize(width: 24, height: 24) {
        didSet {
            updateConstraints()
        }
    }

    /// 星星间距
    public var starSpacing: CGFloat = 4 {
        didSet {
            updateConstraints()
        }
    }

    /// 是否可编辑
    public var isEditable: Bool = true {
        didSet {
            updateGestureRecognizer()
        }
    }

    /// 评分变化回调
    public var onRatingChanged: RatingChangeHandler?

    // MARK: - UI 组件

    private var starViews: [UIImageView] = []

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupRatingView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupRatingView()
    }

    public init(
        maximumRating: Int = 5,
        rating: Float = 0,
        starSize: CGSize = CGSize(width: 24, height: 24),
        spacing: CGFloat = 4
    ) {
        self.maximumRating = maximumRating
        self.rating = rating
        self.starSize = starSize
        self.starSpacing = spacing
        super.init(frame: .zero)
        setupRatingView()
    }

    // MARK: - 设置

    private func setupRatingView() {
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.heightAnchor.constraint(equalToConstant: starSize.height)
        ])

        updateStars()
        updateRatingDisplay()
        updateGestureRecognizer()
    }

    // MARK: - 更新

    private func updateStars() {
        // 移除旧的星星
        starViews.forEach { $0.removeFromSuperview() }
        starViews.removeAll()

        // 添加新的星星
        for _ in 0..<maximumRating {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalToConstant: starSize.width),
                imageView.heightAnchor.constraint(equalToConstant: starSize.height)
            ])

            stackView.addArrangedSubview(imageView)
            starViews.append(imageView)
        }

        stackView.spacing = starSpacing

        updateColors()
    }

    private func updateColors() {
        let image = iconImage

        for starView in starViews {
            let templateImage = image.withRenderingMode(.alwaysTemplate)
            starView.image = templateImage
            starView.tintColor = emptyColor
        }
    }

    private func updateRatingDisplay() {
        switch ratingMode {
        case .whole:
            updateWholeStarRating()
        case .half:
            updateHalfStarRating()
        case .precise:
            updatePreciseRating()
        }

        onRatingChanged?(rating)
    }

    private func updateWholeStarRating() {
        let fullStars = Int(round(rating))

        for (index, starView) in starViews.enumerated() {
            if index < fullStars {
                starView.tintColor = fillColor
            } else {
                starView.tintColor = emptyColor
            }
        }
    }

    private func updateHalfStarRating() {
        let fullStars = Int(rating)
        let hasHalfStar = rating - Float(fullStars) >= 0.5

        for (index, starView) in starViews.enumerated() {
            if index < fullStars {
                starView.tintColor = fillColor
            } else if index == fullStars && hasHalfStar {
                // 半星效果（用渐变实现）
                starView.tintColor = fillColor
                starView.layer.mask = halfStarMask(for: starView)
            } else {
                starView.tintColor = emptyColor
            }
        }
    }

    private func updatePreciseRating() {
        for (index, starView) in starViews.enumerated() {
            let starRating = Float(index + 1)
            let progress = min(max(rating - Float(index), 0), 1)

            if progress >= 1 {
                starView.tintColor = fillColor
            } else if progress > 0 {
                starView.tintColor = fillColor
                starView.layer.mask = progressMask(for: starView, progress: progress)
            } else {
                starView.tintColor = emptyColor
            }
        }
    }

    private func halfStarMask(for view: UIView) -> CALayer {
        let maskLayer = CALayer()
        maskLayer.frame = view.bounds
        maskLayer.backgroundColor = UIColor.white.cgColor

        let halfLayer = CALayer()
        halfLayer.frame = CGRect(x: 0, y: 0, width: view.bounds.width / 2, height: view.bounds.height)
        halfLayer.backgroundColor = UIColor.black.cgColor
        maskLayer.addSublayer(halfLayer)

        return maskLayer
    }

    private func progressMask(for view: UIView, progress: Float) -> CALayer {
        let maskLayer = CALayer()
        maskLayer.frame = view.bounds

        let progressLayer = CALayer()
        progressLayer.frame = CGRect(
            x: 0,
            y: 0,
            width: view.bounds.width * CGFloat(progress),
            height: view.bounds.height
        )
        progressLayer.backgroundColor = UIColor.black.cgColor
        maskLayer.addSublayer(progressLayer)

        return maskLayer
    }

    private func updateGestureRecognizer() {
        gestureRecognizers?.forEach { removeGestureRecognizer($0) }

        guard isEditable else { return }

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        addGestureRecognizer(panGesture)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        addGestureRecognizer(tapGesture)
    }

    private func updateConstraints() {
        // 更新星星大小和间距
        stackView.spacing = starSpacing

        for starView in starViews {
            starView.constraints.forEach { constraint in
                if constraint.firstAttribute == .width {
                    constraint.constant = starSize.width
                } else if constraint.firstAttribute == .height {
                    constraint.constant = starSize.height
                }
            }
        }

        invalidateIntrinsicContentSize()
    }

    // MARK: - 手势处理

    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard isEditable else { return }

        let location = gesture.location(in: stackView)
        let newRating = ratingForLocation(location)

        rating = newRating

        if gesture.state == .ended {
            onRatingChanged?(rating)
        }
    }

    @objc private func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        guard isEditable else { return }

        let location = gesture.location(in: stackView)
        rating = ratingForLocation(location)

        onRatingChanged?(rating)
    }

    private func ratingForLocation(_ location: CGPoint) -> Float {
        var totalWidth: CGFloat = 0
        let spacing = stackView.spacing

        for (index, starView) in starViews.enumerated() {
            let starWidth = starView.bounds.width

            if location.x <= totalWidth + starWidth {
                // 在当前星星范围内
                let offset = location.x - totalWidth
                let ratio = offset / starWidth

                switch ratingMode {
                case .whole:
                    return ratio > 0.5 ? Float(index + 1) : Float(index)
                case .half:
                    return ratio > 0.75 ? Float(index + 1) : (ratio > 0.25 ? Float(index) + 0.5 : Float(index))
                case .precise:
                    return Float(index) + Float(ratio)
                }
            }

            totalWidth += starWidth + spacing
        }

        return Float(maximumRating)
    }

    // MARK: - 辅助属性

    private var iconImage: UIImage {
        switch iconStyle {
        case .star:
            return UIImage(systemName: "star.fill") ?? UIImage()
        case .heart:
            return UIImage(systemName: "heart.fill") ?? UIImage()
        case .circle:
            return UIImage(systemName: "circle.fill") ?? UIImage()
        case .custom(let image):
            return image
        }
    }

    // MARK: - 公共方法

    /// 设置评分
    public func setRating(_ rating: Float, animated: Bool = false) {
        let clampedRating = max(0, min(Float(maximumRating), rating))

        if animated {
            UIView.animate(withDuration: 0.3) {
                self.rating = clampedRating
            }
        } else {
            self.rating = clampedRating
        }
    }

    /// 重置评分
    public func reset() {
        rating = 0
    }
}

// MARK: - 便捷创建

public extension LSRatingView {

    /// 创建星星评分视图
    static func starRating(
        maximumRating: Int = 5,
        rating: Float = 0,
        starSize: CGSize = CGSize(width: 24, height: 24),
        spacing: CGFloat = 4,
        fillColor: UIColor = .systemYellow,
        emptyColor: UIColor = .systemGray4
    ) -> LSRatingView {
        let ratingView = LSRatingView(
            maximumRating: maximumRating,
            rating: rating,
            starSize: starSize,
            spacing: spacing
        )
        ratingView.iconStyle = .star
        ratingView.fillColor = fillColor
        ratingView.emptyColor = emptyColor
        return ratingView
    }

    /// 创建心形评分视图
    static func heartRating(
        maximumRating: Int = 5,
        rating: Float = 0,
        starSize: CGSize = CGSize(width: 24, height: 24),
        spacing: CGFloat = 4
    ) -> LSRatingView {
        let ratingView = LSRatingView(
            maximumRating: maximumRating,
            rating: rating,
            starSize: starSize,
            spacing: spacing
        )
        ratingView.iconStyle = .heart
        ratingView.fillColor = .systemRed
        return ratingView
    }
}

// MARK: - 只读评分视图

/// 只读评分视图（简化版）
public class LSReadOnlyRatingView: UIView {

    /// 最大评分
    public var maximumRating: Int = 5 {
        didSet {
            updateDisplay()
        }
    }

    /// 当前评分
    public var rating: Float = 0 {
        didSet {
            updateDisplay()
        }
    }

    /// 填充颜色
    public var fillColor: UIColor = .systemYellow {
        didSet {
            updateDisplay()
        }
    }

    /// 空心颜色
    public var emptyColor: UIColor = .systemGray4 {
        didSet {
            updateDisplay()
        }
    }

    /// 星星大小
    public var starSize: CGFloat = 16 {
        didSet {
            updateDisplay()
        }
    }

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 2
        return stack
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.heightAnchor.constraint(equalToConstant: starSize)
        ])
    }

    private func updateDisplay() {
        // 移除旧的星星
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let fullStars = Int(round(rating))

        for i in 0..<maximumRating {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit

            if i < fullStars {
                imageView.image = UIImage(systemName: "star.fill")?.withTintColor(fillColor, renderingMode: .alwaysOriginal)
            } else {
                imageView.image = UIImage(systemName: "star")?.withTintColor(emptyColor, renderingMode: .alwaysOriginal)
            }

            imageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalToConstant: starSize),
                imageView.heightAnchor.constraint(equalToConstant: starSize)
            ])

            stackView.addArrangedSubview(imageView)
        }
    }

    /// 设置评分
    public func setRating(_ rating: Float) {
        self.rating = max(0, min(Float(maximumRating), rating))
    }
}

#endif

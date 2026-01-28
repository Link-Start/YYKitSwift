//
//  LSCardView.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  卡片视图 - 卡片式布局容器
//

#if canImport(UIKit)
import UIKit

// MARK: - LSCardView

/// 卡片视图
@MainActor
public class LSCardView: UIView {

    // MARK: - 属性

    /// 卡片内容视图
    public let contentView: UIView = {
        let cv = UIView()
        cv.backgroundColor = .white
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    /// 卡片样式
    public var style: CardStyle = .default {
        didSet {
            updateStyle()
        }
    }

    /// 卡片颜色
    public var cardColor: UIColor = .white {
        didSet {
            contentView.backgroundColor = cardColor
        }
    }

    /// 卡片圆角
    public var cornerRadius: CGFloat = 12 {
        didSet {
            contentView.layer.cornerRadius = cornerRadius
        }
    }

    /// 阴影
    public var shadowColor: UIColor = .black {
        didSet {
            updateShadow()
        }
    }

    /// 阴影不透明度
    public var shadowOpacity: Float = 0.1 {
        didSet {
            updateShadow()
        }
    }

    /// 阴影半径
    public var shadowRadius: CGFloat = 4 {
        didSet {
            updateShadow()
        }
    }

    /// 阴影偏移
    public var shadowOffset: CGSize = CGSize(width: 0, height: 2) {
        didSet {
            updateShadow()
        }
    }

    /// 卡片内边距
    public var cardInsets: UIEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12) {
        didSet {
            updateInsets()
        }
    }

    /// 是否显示阴影
    public var showsShadow: Bool = true {
        didSet {
            updateShadow()
        }
    }

    /// 是否可交互
    public var isInteractive: Bool = false {
        didSet {
            isUserInteractionEnabled = isInteractive
        }
    }

    // MARK: - 枚举

    /// 卡片样式
    public enum CardStyle {
        case `default`          // 默认样式（圆角+阴影）
        case flat                // 平面样式（无圆角+无阴影）
        case elevated            // 抬升样式（更大阴影）
        case outlined            // 轮廓样式（边框）
    }

    // MARK: - 初始化

    public init(frame: CGRect = .zero) {
        super.init(frame: frame)
        setupUI()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - 设置

    private func setupUI() {
        backgroundColor = .clear

        addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        // 初始设置
        contentView.layer.cornerRadius = cornerRadius
        contentView.layer.masksToBounds = true

        updateStyle()
        updateInsets()
        updateShadow()

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor, constant: cardInsets.top),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: cardInsets.left),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -cardInsets.right),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -cardInsets.bottom)
        ])
    }

    private func updateStyle() {
        switch style {
        case .default:
            contentView.layer.cornerRadius = cornerRadius
            contentView.layer.borderWidth = 0
            showsShadow = true

        case .flat:
            contentView.layer.cornerRadius = 0
            contentView.layer.borderWidth = 0
            showsShadow = false

        case .elevated:
            contentView.layer.cornerRadius = cornerRadius
            contentView.layer.borderWidth = 0
            shadowOpacity = 0.2
            shadowRadius = 8
            showsShadow = true

        case .outlined:
            contentView.layer.cornerRadius = cornerRadius
            contentView.layer.borderWidth = 1
            contentView.layer.borderColor = UIColor.systemGray4.cgColor
            showsShadow = false
        }
    }

    private func updateInsets() {
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor, constant: cardInsets.top),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: cardInsets.left),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -cardInsets.right),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -cardInsets.bottom)
        ])
    }

    private func updateShadow() {
        guard showsShadow else {
            layer.shadowColor = nil
            layer.shadowOffset = .zero
            layer.shadowOpacity = 0
            layer.shadowRadius = 0
            return
        }

        layer.shadowColor = shadowColor.cgColor
        layer.shadowOffset = shadowOffset
        layer.shadowOpacity = shadowOpacity
        layer.shadowRadius = shadowRadius
    }
}

// MARK: - LSCardContainerView

/// 卡片容器视图
public class LSCardContainerView: UIView {

    // MARK: - 属性

    /// 卡片间距
    public var cardSpacing: CGFloat = 12 {
        didSet {
            stackView.spacing = cardSpacing
        }
    }

    /// 卡片边距
    public var cardInsets: UIEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16) {
        didSet {
            updateInsets()
        }
    }

    /// 滚动方向
    public var scrollDirection: UICollectionView.ScrollDirection = .vertical {
        didSet {
            updateLayout()
        }
    }

    /// 卡片数组
    private var cardViews: [LSCardView] = []

    /// 栈视图
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = false
        cv.register(LSCardCell.self, forCellWithReuseIdentifier: LSCardCell.reuseIdentifier)
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

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
        backgroundColor = .clear

        addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func updateInsets() {
        collectionView.contentInset = cardInsets
    }

    private func updateLayout() {
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = scrollDirection
        }
    }

    // MARK: - 卡片管理

    /// 添加卡片
    ///
    /// - Parameter cards: 卡片数组
    public func addCards(_ cards: [LSCardView]) {
        cardViews.append(contentsOf: cards)
        collectionView.reloadData()
    }

    /// 清空卡片
    public func clearCards() {
        cardViews.removeAll()
        collectionView.reloadData()
    }

    /// 获取卡片数量
    public var cardCount: Int {
        return cardViews.count
    }

    /// 获取指定索引的卡片
    ///
    /// - Parameter index: 索引
    /// - Returns: 卡片视图
    public func card(at index: Int) -> LSCardView? {
        guard index < cardViews.count else { return nil }
        return cardViews[index]
    }
}

// MARK: - UICollectionViewDataSource

extension LSCardContainerView: UICollectionViewDataSource {

    public func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        return cardViews.count
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: LSCardCell.reuseIdentifier,
            for: indexPath
        ) as! LSCardCell

        let card = cardViews[indexPath.item]
        cell.configure(with: card)

        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension LSCardContainerView: UICollectionViewDelegate {

    public func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        let card = cardViews[indexPath.item]

        // 卡片点击动画
        UIView.animate(withDuration: 0.1) {
            card.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        } completion: { _ in
            UIView.animate(withDuration: 0.1) {
                card.transform = .identity
            }
        }
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        // 即将显示卡片
    }
}

// MARK: - UICollectionViewFlowLayout

extension LSCardContainerView: UICollectionViewDelegateFlowLayout {

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else {
            return .zero
        }

        let width: CGFloat
        let height: CGFloat

        if scrollDirection == .horizontal {
            // 水平滚动：固定高度，宽度自适应
            height = collectionView.bounds.height - cardInsets.top - cardInsets.bottom
            width = height * 0.75 // 3:4 比例
        } else {
            // 垂直滚动：固定宽度，高度自适应
            width = collectionView.bounds.width - cardInsets.left - cardInsets.right
            height = width * 0.75 // 4:3 比例
        }

        return CGSize(width: width, height: height)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 0
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 0
    }
}

// MARK: - LSCardCell

/// 卡片单元格
private class LSCardCell: UICollectionViewCell {

    /// 重用标识符
    static let reuseIdentifier = "LSCardCell"

    /// 卡片视图
    private var cardView: LSCardView?

    /// 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    /// 配置卡片
    ///
    /// - Parameter card: 卡片视图
    func configure(with card: LSCardView) {
        // 移除旧的
        cardView?.removeFromSuperview()

        // 添加新的
        contentView.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        self.cardView = card
    }

    override func prepareForReuse() {
        cardView?.removeFromSuperview()
        cardView = nil
    }
}

// MARK: - 便捷卡片创建

public extension LSCardView {

    /// 创建简单的文本卡片
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - subtitle: 副标题
    ///   - color: 背景颜色
    /// - Returns: 卡片视图
    static func textCard(
        title: String,
        subtitle: String? = nil,
        color: UIColor = .white
    ) -> LSCardView {
        let card = LSCardView()
        card.cardColor = color

        // 添加标题标签
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // 添加副标题标签
        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false

        stackView.addArrangedSubview(titleLabel)
        if let subtitle = subtitle {
            stackView.addArrangedSubview(subtitleLabel)
        }

        card.contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
        ])

        return card
    }

    /// 创建图片卡片
    ///
    /// - Parameters:
    ///   - image: 图片
    ///   - title: 标题
    /// - Returns: 卡片视图
    static func imageCard(
        image: UIImage,
        title: String? = nil
    ) -> LSCardView {
        let card = LSCardView()
        card.cardColor = .white

        let imageView = UIImageView()
        imageView.image = image
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.translatesAutoresizingMaskIntoConstraints = false

        card.contentView.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            imageView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            imageView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            imageView.heightAnchor.constraint(equalToConstant: 120)
        ])

        if let title = title {
            let titleLabel = UILabel()
            titleLabel.text = title
            titleLabel.font = .systemFont(ofSize: 16)
            titleLabel.textColor = .label
            titleLabel.translatesAutoresizingMaskIntoConstraints = false

            card.contentView.addSubview(titleLabel)

            NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 12),
                titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
                titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
                titleLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
            ])
        }

        return card
    }
}

// MARK: - 便捷方法

public extension UIView {

    /// 添加卡片视图
    ///
    /// - Parameters:
    ///   - insets: 内边距
    ///   - cornerRadius: 圆角半径
    /// - shadowColor: 阴影颜色
    /// - Returns: 卡片视图
    @discardableResult
    func ls_addCard(
        insets: UIEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16),
        cornerRadius: CGFloat = 12,
        shadowColor: UIColor = .black
    ) -> LSCardView {
        let card = LSCardView()
        card.cardInsets = insets
        card.cornerRadius = cornerRadius
        card.shadowColor = shadowColor

        addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            card.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
            card.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right),
            card.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom)
        ])

        return card
    }
}

#endif

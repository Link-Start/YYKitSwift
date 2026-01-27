//
//  LSCollectionViewFlowLayout.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  增强的集合流式布局 - 提供更多布局选项
//

#if canImport(UIKit)
import UIKit

// MARK: - LSCollectionViewFlowLayout

/// 增强的集合流式布局
public class LSCollectionViewFlowLayout: UICollectionViewFlowLayout {

    // MARK: - 属性

    /// 每行单元格数量
    public var itemsPerRow: Int = 2 {
        didSet {
            invalidateLayout()
        }
    }

    /// 单元格间距
    public var cellSpacing: CGFloat = 10 {
        didSet {
            invalidateLayout()
        }
    }

    /// 行间距
    public var lineSpacing: CGFloat = 10 {
        didSet {
            invalidateLayout()
        }
    }

    /// 内容边距
    public var contentInsets: UIEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10) {
        didSet {
            invalidateLayout()
        }
    }

    /// 是否保持宽高比
    public var keepsAspectRatio: Bool = false {
        didSet {
            invalidateLayout()
        }
    }

    /// 宽高比
    public var aspectRatio: CGFloat = 1.0 {
        didSet {
            invalidateLayout()
        }
    }

    // MARK: - 初始化

    public override init() {
        super.init()
        setupLayout()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
    }

    // MARK: - 设置

    private func setupLayout() {
        scrollDirection = .vertical
    }

    // MARK: - 布局计算

    public override func prepare() {
        super.prepare()

        guard let collectionView = collectionView else { return }

        let availableWidth = collectionView.bounds.width - contentInsets.left - contentInsets.right
        let spacing = CGFloat(itemsPerRow - 1) * cellSpacing
        let itemWidth = (availableWidth - spacing) / CGFloat(itemsPerRow)

        var itemHeight = itemWidth

        if keepsAspectRatio {
            itemHeight = itemWidth / aspectRatio
        }

        itemSize = CGSize(width: itemWidth, height: itemHeight)

        minimumLineSpacing = lineSpacing
        minimumInteritemSpacing = cellSpacing

        sectionInset = contentInsets
    }

    // MARK: - 便捷创建

    /// 创建网格布局
    public static func gridLayout(
        itemsPerRow: Int = 2,
        spacing: CGFloat = 10,
        insets: UIEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    ) -> LSCollectionViewFlowLayout {
        let layout = LSCollectionViewFlowLayout()
        layout.itemsPerRow = itemsPerRow
        layout.cellSpacing = spacing
        layout.lineSpacing = spacing
        layout.contentInsets = insets
        return layout
    }

    /// 创建列表布局
    public static func listLayout(
        itemHeight: CGFloat = 80,
        spacing: CGFloat = 10,
        insets: UIEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    ) -> LSCollectionViewFlowLayout {
        let layout = LSCollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width - 20, height: itemHeight)
        layout.minimumLineSpacing = spacing
        layout.sectionInset = insets
        return layout
    }

    /// 创建横向滚动布局
    public static func horizontalLayout(
        itemWidth: CGFloat = 100,
        itemHeight: CGFloat = 100,
        spacing: CGFloat = 10,
        insets: UIEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    ) -> LSCollectionViewFlowLayout {
        let layout = LSCollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        layout.minimumLineSpacing = spacing
        layout.sectionInset = insets
        return layout
    }
}

// MARK: - Waterfall Layout

/// 瀀单的瀑布流布局
public class LSWaterfallLayout: UICollectionViewLayout {

    // MARK: - 属性

    /// 列数
    public var columns: Int = 2 {
        didSet {
            invalidateLayout()
        }
    }

    /// 列间距
    public var columnSpacing: CGFloat = 10 {
        didSet {
            invalidateLayout()
        }
    }

    /// 行间距
    public var lineSpacing: CGFloat = 10 {
        didSet {
            invalidateLayout()
        }
    }

    /// 内容边距
    public var contentInsets: UIEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10) {
        didSet {
            invalidateLayout()
        }
    }

    /// 代理
    public weak var delegate: WaterfallDelegate?

    // MARK: - 缓存

    private var cache: [UICollectionViewLayoutAttributes] = []
    private var contentHeight: CGFloat = 0
    private var contentWidth: CGFloat = 0

    // MARK: - 类型定义

    public protocol WaterfallDelegate: AnyObject {
        func waterfallLayout(_ layout: LSWaterfallLayout, heightForItemAt indexPath: IndexPath) -> CGFloat
    }

    // MARK: - 初始化

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - 布局

    public override func prepare() {
        guard let collectionView = collectionView else { return }

        cache.removeAll()
        contentHeight = 0
        contentWidth = collectionView.bounds.width

        let availableWidth = contentWidth - contentInsets.left - contentInsets.right - CGFloat(columns - 1) * columnSpacing
        let columnWidth = availableWidth / CGFloat(columns)

        var columnHeights = [CGFloat](repeating: contentInsets.top, count: columns)

        guard let dataSource = collectionView.dataSource else { return }

        let itemCount = dataSource.collectionView(collectionView, numberOfItemsInSection: 0)

        for i in 0..<itemCount {
            let indexPath = IndexPath(item: i, section: 0)

            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            cache.append(attributes)

            let itemHeight = delegate?.waterfallLayout(self, heightForItemAt: indexPath) ?? 100

            // 找到最短的列
            var shortestColumn = 0
            var shortestHeight = columnHeights[0]

            for i in 1..<columns {
                if columnHeights[i] < shortestHeight {
                    shortestColumn = i
                    shortestHeight = columnHeights[i]
                }
            }

            let xOffset = contentInsets.left + CGFloat(shortestColumn) * (columnWidth + columnSpacing)
            let yOffset = columnHeights[shortestColumn]

            attributes.frame = CGRect(x: xOffset, y: yOffset, width: columnWidth, height: itemHeight)

            columnHeights[shortestColumn] = yOffset + itemHeight + lineSpacing
            contentHeight = max(contentHeight, columnHeights[shortestColumn])
        }

        contentHeight -= lineSpacing
    }

    public override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: max(contentHeight + contentInsets.bottom, 0))
    }

    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return cache.filter { $0.frame.intersects(rect) }
    }

    public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache[indexPath.item]
    }
}

// MARK: - Card Layout

/// 卡片布局
public class LSCardLayout: UICollectionViewFlowLayout {

    // MARK: - 属性

    /// 卡片宽度
    public var cardWidth: CGFloat = 300

    /// 卡片高度
    public var cardHeight: CGFloat = 200

    /// 横向滚动时是否居中
    public var centersCardsWhenScrolling: Bool = true

    // MARK: - 布局

    public override func prepare() {
        super.prepare()

        guard let collectionView = collectionView, collectionView.bounds.width > 0 else { return }

        if scrollDirection == .horizontal {
            let horizontalInset = (collectionView.bounds.width - cardWidth) / 2
            sectionInset = UIEdgeInsets(top: 0, left: horizontalInset, bottom: 0, right: horizontalInset)
        }

        itemSize = CGSize(width: cardWidth, height: cardHeight)
    }

    public override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard centersCardsWhenScrolling,
              let collectionView = collectionView else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
        }

        let layoutAttributes = super.layoutAttributesForElements(in: CGRect(x: 0, y: 0, width: collectionView.bounds.size.width, height: collectionView.bounds.size.height))

        let midX = proposedContentOffset.x + collectionView.bounds.size.width / 2

        var closestAttribute: UICollectionViewLayoutAttributes?

        for attributes in layoutAttributes {
            if attributes.representedElementCategory != .cell { continue }

            let candidateMidX = attributes.center.x
            if closestAttribute == nil {
                closestAttribute = attributes
            } else {
                if abs(candidateMidX - midX) < abs(closestAttribute.center.x - midX) {
                    closestAttribute = attributes
                }
            }
        }

        if let closest = closestAttribute {
            return CGPoint(x: closest.center.x - collectionView.bounds.size.width / 2, y: proposedContentOffset.y)
        }

        return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
    }
}

// MARK: - Date Picker Layout

/// 日期选择器布局（类似日历）
public class LSDatePickerLayout: UICollectionViewFlowLayout {

    // MARK: - 属性

    /// 每周天数
    public var daysPerWeek: Int = 7

    /// 单元格大小
    public var dayCellSize: CGSize = CGSize(width: 40, height: 40)

    /// 间距
    public var spacing: CGFloat = 8

    /// 边距
    public var insets: UIEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

    // MARK: - 布局

    public override func prepare() {
        super.prepare()

        itemSize = dayCellSize
        minimumLineSpacing = spacing
        minimumInteritemSpacing = spacing
        sectionInset = insets
    }

    // MARK: - 便捷创建

    public static func create(
        daysPerWeek: Int = 7,
        cellSize: CGSize = CGSize(width: 40, height: 40),
        spacing: CGFloat = 8
    ) -> LSDatePickerLayout {
        let layout = LSDatePickerLayout()
        layout.daysPerWeek = daysPerWeek
        layout.dayCellSize = cellSize
        layout.spacing = spacing
        return layout
    }
}

// MARK: - Tag Layout

/// 标签布局（自动换行）
public class LSTagLayout: UICollectionViewLayout {

    // MARK: - 属性

    /// 标签间距
    public var tagSpacing: CGFloat = 8

    /// 行间距
    public var lineSpacing: CGFloat = 8

    /// 内容边距
    public var contentInsets: UIEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

    /// 代理
    public weak var delegate: TagLayoutDelegate?

    // MARK: - 缓存

    private var cache: [UICollectionViewLayoutAttributes] = []
    private var contentSize: CGSize = .zero

    // MARK: - 类型定义

    public protocol TagLayoutDelegate: AnyObject {
        func tagLayout(_ layout: LSTagLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    }

    // MARK: - 布局

    public override func prepare() {
        guard let collectionView = collectionView else { return }

        cache.removeAll()

        let availableWidth = collectionView.bounds.width - contentInsets.left - contentInsets.right

        guard let dataSource = collectionView.dataSource else { return }

        let itemCount = dataSource.collectionView(collectionView, numberOfItemsInSection: 0)

        var xOffset: CGFloat = contentInsets.left
        var yOffset: CGFloat = contentInsets.top
        var lineHeight: CGFloat = 0

        for i in 0..<itemCount {
            let indexPath = IndexPath(item: i, section: 0)

            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            cache.append(attributes)

            let itemSize = delegate?.tagLayout(self, sizeForItemAt: indexPath) ?? CGSize(width: 50, height: 30)

            if xOffset + itemSize.width > availableWidth && xOffset > contentInsets.left {
                // 换行
                xOffset = contentInsets.left
                yOffset += lineHeight + lineSpacing
                lineHeight = 0
            }

            attributes.frame = CGRect(x: xOffset, y: yOffset, width: itemSize.width, height: itemSize.height)

            xOffset += itemSize.width + tagSpacing
            lineHeight = max(lineHeight, itemSize.height)
        }

        contentSize = CGSize(
            width: collectionView.bounds.width,
            height: yOffset + lineHeight + contentInsets.bottom
        )
    }

    public override var collectionViewContentSize: CGSize {
        return contentSize
    }

    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return cache.filter { $0.frame.intersects(rect) }
    }

    public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache[indexPath.item]
    }
}

// MARK: - Staggered Grid Layout

/// 交错网格布局（类似 Pinterest）
public class LSStaggeredGridLayout: UICollectionViewLayout {

    // MARK: - 属性

    /// 列数
    public var columns: Int = 2

    /// 列间距
    public var columnSpacing: CGFloat = 10

    /// 行间距
    public var rowSpacing: CGFloat = 10

    /// 内容边距
    public var contentInsets: UIEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

    /// 代理
    public weak var delegate: StaggeredDelegate?

    // MARK: - 缓存

    private var cache: [UICollectionViewLayoutAttributes] = []
    private var columnOffsets: [CGFloat] = []
    private var contentHeight: CGFloat = 0

    // MARK: - 类型定义

    public protocol StaggeredDelegate: AnyObject {
        func staggeredLayout(_ layout: LSStaggeredGridLayout, heightForItemAt indexPath: IndexPath) -> CGFloat
    }

    // MARK: - 初始化

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - 准备布局

    public override func prepare() {
        guard let collectionView = collectionView else { return }

        cache.removeAll()
        columnOffsets = [CGFloat](repeating: contentInsets.top, count: columns)
        contentHeight = 0

        guard let dataSource = collectionView.dataSource else { return }

        let itemCount = dataSource.collectionView(collectionView, numberOfItemsInSection: 0)

        let availableWidth = collectionView.bounds.width - contentInsets.left - contentInsets.right
        let itemWidth = (availableWidth - CGFloat(columns - 1) * columnSpacing) / CGFloat(columns)

        for i in 0..<itemCount {
            let indexPath = IndexPath(item: i, section: 0)

            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            cache.append(attributes)

            let itemHeight = delegate?.staggeredLayout(self, heightForItemAt: indexPath) ?? 100

            // 找到最短的列
            var shortestColumn = 0
            for i in 1..<columns {
                if columnOffsets[i] < columnOffsets[shortestColumn] {
                    shortestColumn = i
                }
            }

            let xOffset = contentInsets.left + CGFloat(shortestColumn) * (itemWidth + columnSpacing)
            let yOffset = columnOffsets[shortestColumn]

            attributes.frame = CGRect(x: xOffset, y: yOffset, width: itemWidth, height: itemHeight)

            columnOffsets[shortestColumn] = yOffset + itemHeight + rowSpacing
            contentHeight = max(contentHeight, columnOffsets[shortestColumn])
        }
    }

    public override var collectionViewContentSize: CGSize {
        guard let collectionView = collectionView else {
            return CGSize(width: 100, height: 100)
        }

        return CGSize(
            width: collectionView.bounds.width,
            height: max(contentHeight + contentInsets.bottom - rowSpacing, 0)
        )
    }

    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return cache.filter { $0.frame.intersects(rect) }
    }

    public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache[indexPath.item]
    }
}

// MARK: - 便捷扩展

public extension UICollectionViewLayout {

    /// 转换为流式布局
    var ls_asFlowLayout: LSCollectionViewFlowLayout? {
        return self as? LSCollectionViewFlowLayout
    }

    /// 转换为瀑布流布局
    var ls_asWaterfallLayout: LSWaterfallLayout? {
        return self as? LSWaterfallLayout
    }

    /// 转换为标签布局
    var ls_asTagLayout: LSTagLayout? {
        return self as? LSTagLayout
    }

    /// 转换为交错网格布局
    var ls_asStaggeredLayout: LSStaggeredGridLayout? {
        return self as? LSStaggeredGridLayout
    }
}

#endif

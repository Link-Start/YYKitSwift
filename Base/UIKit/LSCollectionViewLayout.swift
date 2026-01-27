//
//  LSCollectionViewLayout.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  CollectionView 布局工具 - 简化自定义布局实现
//

#if canImport(UIKit)
import UIKit

// MARK: - LSFlowLayout

/// 流式布局
public class LSFlowLayout: UICollectionViewFlowLayout {

    // MARK: - 属性

    /// 每行最小间距
    public var minimumInterItemSpacing: CGFloat = 8 {
        didSet { invalidateLayout() }
    }

    /// 每行最小行间距
    public var minimumLineSpacing: CGFloat = 8 {
        didSet { invalidateLayout() }
    }

    /// 内容边距
    public var contentInset: UIEdgeInsets = .zero {
        didSet { invalidateLayout() }
    }

    /// 每行最大元素数
    public var maxItemsPerRow: Int = 0 {
        didSet { invalidateLayout() }
    }

    /// 固定元素尺寸
    public var fixedItemSize: CGSize? {
        didSet { invalidateLayout() }
    }

    /// 是否自动调整间距以填满宽度
    public var shouldDistributeSpacing = false {
        didSet { invalidateLayout() }
    }

    // MARK: - 初始化

    public init(
        scrollDirection: UICollectionView.ScrollDirection = .vertical,
        itemSize: CGSize = CGSize(width: 80, height: 80),
        minimumLineSpacing: CGFloat = 8,
        minimumInterItemSpacing: CGFloat = 8
    ) {
        super.init()
        self.scrollDirection = scrollDirection
        self.itemSize = itemSize
        self.minimumLineSpacing = minimumLineSpacing
        self.minimumInterItemSpacing = minimumInterItemSpacing
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - 布局

    public override func prepare() {
        super.prepare()

        guard let collectionView = collectionView else { return }

        let availableWidth = collectionView.bounds.width - contentInset.left - contentInset.right

        if scrollDirection == .vertical {
            prepareVerticalLayout(availableWidth: availableWidth)
        } else {
            prepareHorizontalLayout(availableHeight: collectionView.bounds.height - contentInset.top - contentInset.bottom)
        }
    }

    private func prepareVerticalLayout(availableWidth: CGFloat) {
        guard let collectionView = collectionView else { return }

        var itemsPerRow: Int

        if maxItemsPerRow > 0 {
            itemsPerRow = maxItemsPerRow
        } else if let fixedSize = fixedItemSize {
            itemsPerRow = Int((availableWidth + minimumInterItemSpacing) / (fixedSize.width + minimumInterItemSpacing))
        } else {
            itemsPerRow = Int((availableWidth + minimumInterItemSpacing) / (itemSize.width + minimumInterItemSpacing))
        }

        itemsPerRow = max(1, itemsPerRow)

        let actualInterItemSpacing: CGFloat
        if shouldDistributeSpacing {
            actualInterItemSpacing = (availableWidth - CGFloat(itemsPerRow) * itemSize.width) / CGFloat(itemsPerRow - 1)
        } else {
            actualInterItemSpacing = minimumInterItemSpacing
        }

        self.minimumInterItemSpacing = actualInterItemSpacing
    }

    private func prepareHorizontalLayout(availableHeight: CGFloat) {
        guard let collectionView = collectionView else { return }

        var itemsPerColumn: Int

        if maxItemsPerRow > 0 {
            itemsPerColumn = maxItemsPerRow
        } else if let fixedSize = fixedItemSize {
            itemsPerColumn = Int((availableHeight + minimumLineSpacing) / (fixedSize.height + minimumLineSpacing))
        } else {
            itemsPerColumn = Int((availableHeight + minimumLineSpacing) / (itemSize.height + minimumLineSpacing))
        }

        itemsPerColumn = max(1, itemsPerColumn)

        if shouldDistributeSpacing {
            let actualLineSpacing = (availableHeight - CGFloat(itemsPerColumn) * itemSize.height) / CGFloat(itemsPerColumn - 1)
            self.minimumLineSpacing = actualLineSpacing
        }
    }

    // MARK: - 便捷方法

    /// 创建 3 列布局
    public static func threeColumnLayout(spacing: CGFloat = 8) -> LSFlowLayout {
        let layout = LSFlowLayout()
        layout.maxItemsPerRow = 3
        layout.minimumInterItemSpacing = spacing
        layout.minimumLineSpacing = spacing
        return layout
    }

    /// 创建 4 列布局
    public static func fourColumnLayout(spacing: CGFloat = 8) -> LSFlowLayout {
        let layout = LSFlowLayout()
        layout.maxItemsPerRow = 4
        layout.minimumInterItemSpacing = spacing
        layout.minimumLineSpacing = spacing
        return layout
    }

    /// 创建自适应布局
    ///
    /// - Parameters:
    ///   - itemSize: 元素尺寸
    ///   - spacing: 间距
    /// - Returns: 流式布局
    public static func autoLayout(itemSize: CGSize, spacing: CGFloat = 8) -> LSFlowLayout {
        let layout = LSFlowLayout()
        layout.fixedItemSize = itemSize
        layout.minimumInterItemSpacing = spacing
        layout.minimumLineSpacing = spacing
        layout.shouldDistributeSpacing = true
        return layout
    }
}

// MARK: - LSTagFlowLayout

/// 标签流式布局（自动换行）
public class LSTagFlowLayout: UICollectionViewFlowLayout {

    // MARK: - 属性

    /// 标签边距
    public var tagEdgeInsets: UIEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

    /// 标签间距
    public var tagSpacing: CGFloat = 8

    /// 行间距
    public var lineSpacing: CGFloat = 8

    /// 对齐方式
    public var alignment: Alignment = .left

    /// 缓存的布局属性
    private var cache: [UICollectionViewLayoutAttributes] = []

    /// 内容高度
    private var contentHeight: CGFloat = 0

    /// 内容宽度
    private var contentWidth: CGFloat {
        guard let collectionView = collectionView else { return 0 }
        return collectionView.bounds.width - sectionInset.left - sectionInset.right
    }

    // MARK: - 对齐方式

    public enum Alignment {
        case left
        case center
        case right
    }

    // MARK: - 初始化

    public init(alignment: Alignment = .left) {
        super.init()
        self.alignment = alignment
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - 布局

    public override func prepare() {
        super.prepare()

        guard let collectionView = collectionView,
              cache.isEmpty || collectionView.bounds.size != collectionView.contentSize else {
            return
        }

        cache.removeAll()
        contentHeight = 0

        let xOffset = sectionInset.left
        var yOffset = sectionInset.top
        var lineWidth: CGFloat = 0
        var lineAttributes: [UICollectionViewLayoutAttributes] = []

        for item in 0..<collectionView.numberOfItems(inSection: 0) {
            let indexPath = IndexPath(item: item, section: 0)
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)

            let itemSize = self.itemSize(at: indexPath)

            // 检查是否需要换行
            if lineWidth + itemSize.width > contentWidth && !lineAttributes.isEmpty {
                // 对齐当前行
                let alignedWidth = contentWidth - (lineWidth - itemSize.width)
                alignLineAttributes(lineAttributes, lineWidth: alignedWidth, xOffset: xOffset)

                yOffset += itemSize.height + lineSpacing
                lineWidth = 0
                lineAttributes.removeAll()
            }

            attributes.frame = CGRect(x: xOffset + lineWidth, y: yOffset, width: itemSize.width, height: itemSize.height)
            lineAttributes.append(attributes)
            cache.append(attributes)

            lineWidth += itemSize.width + tagSpacing
        }

        // 对齐最后一行
        if !lineAttributes.isEmpty {
            let alignedWidth = contentWidth - (lineWidth - tagSpacing)
            alignLineAttributes(lineAttributes, lineWidth: alignedWidth, xOffset: xOffset)
        }

        contentHeight = yOffset + (lineAttributes.first?.frame.height ?? 0) + sectionInset.bottom
    }

    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return cache.filter { $0.frame.intersects(rect) }
    }

    public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache[indexPath.item]
    }

    public override var collectionViewContentSize: CGSize {
        guard let collectionView = collectionView else { return .zero }
        return CGSize(width: collectionView.bounds.width, height: contentHeight)
    }

    // MARK: - 辅助方法

    private func itemSize(at indexPath: IndexPath) -> CGSize {
        if let delegate = collectionView?.delegate as? UICollectionViewDelegateFlowLayout,
           let size = delegate.collectionView?(collectionView, layout: self, sizeForItemAt: indexPath) {
            return size
        }
        return self.itemSize
    }

    private func alignLineAttributes(_ attributes: [UICollectionViewLayoutAttributes], lineWidth: CGFloat, xOffset: CGFloat) {
        let lineItemsWidth = lineWidth - tagSpacing
        var offset: CGFloat

        switch alignment {
        case .left:
            offset = 0
        case .center:
            offset = (contentWidth - lineItemsWidth) / 2
        case .right:
            offset = contentWidth - lineItemsWidth
        }

        for attribute in attributes {
            attribute.frame.origin.x += offset
        }
    }

    // MARK: - 无效化布局

    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return newBounds.width != collectionView?.bounds.width
    }

    public override func invalidateLayout() {
        cache.removeAll()
        super.invalidateLayout()
    }
}

// MARK: - LSWaterfallLayout

/// 瀑布流布局
public class LSWaterfallLayout: UICollectionViewLayout {

    // MARK: - 属性

    /// 列数
    public var columnCount: Int = 2 {
        didSet { invalidateLayout() }
    }

    /// 列间距
    public var columnSpacing: CGFloat = 8 {
        didSet { invalidateLayout() }
    }

    /// 行间距
    public var lineSpacing: CGFloat = 8 {
        didSet { invalidateLayout() }
    }

    /// 内容边距
    public var contentInset: UIEdgeInsets = .zero {
        didSet { invalidateLayout() }
    }

    /// 使用的布局
    private var cache: [UICollectionViewLayoutAttributes] = []

    /// 列高度
    private var columnHeights: [CGFloat] = []

    /// 内容高度
    private var contentHeight: CGFloat = 0

    /// 内容宽度
    private var contentWidth: CGFloat {
        guard let collectionView = collectionView else { return 0 }
        return collectionView.bounds.width
    }

    /// 列宽
    private var columnWidth: CGFloat {
        let totalSpacing = CGFloat(columnCount - 1) * columnSpacing
        return (contentWidth - contentInset.left - contentInset.right - totalSpacing) / CGFloat(columnCount)
    }

    /// 代理
    public weak var delegate: WaterfallLayoutDelegate?

    // MARK: - 初始化

    public init(columnCount: Int = 2, columnSpacing: CGFloat = 8, lineSpacing: CGFloat = 8) {
        super.init()
        self.columnCount = columnCount
        self.columnSpacing = columnSpacing
        self.lineSpacing = lineSpacing
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - 代理协议

    public protocol WaterfallLayoutDelegate: AnyObject {
        func collectionView(_ collectionView: UICollectionView, layout: LSWaterfallLayout, heightForItemAt indexPath: IndexPath) -> CGFloat
    }

    // MARK: - 布局

    public override func prepare() {
        super.prepare()

        guard let collectionView = collectionView else { return }

        cache.removeAll()
        columnHeights = Array(repeating: contentInset.top, count: columnCount)
        contentHeight = 0

        for item in 0..<collectionView.numberOfItems(inSection: 0) {
            let indexPath = IndexPath(item: item, section: 0)
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)

            let frame = frameForItem(at: indexPath)
            attributes.frame = frame
            cache.append(attributes)

            columnHeights[shortestColumnIndex] = frame.maxY
            contentHeight = max(contentHeight, frame.maxY)
        }
    }

    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return cache.filter { $0.frame.intersects(rect) }
    }

    public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache[indexPath.item]
    }

    public override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight + contentInset.bottom)
    }

    // MARK: - 辅助方法

    private func frameForItem(at indexPath: IndexPath) -> CGRect {
        let column = shortestColumnIndex
        let x = contentInset.left + CGFloat(column) * (columnWidth + columnSpacing)
        let y = columnHeights[column]
        let height = delegate?.collectionView(collectionView!, layout: self, heightForItemAt: indexPath) ?? 100
        return CGRect(x: x, y: y, width: columnWidth, height: height)
    }

    private var shortestColumnIndex: Int {
        return columnHeights.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
    }

    // MARK: - 无效化布局

    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return newBounds.width != collectionView?.bounds.width
    }

    public override func invalidateLayout() {
        cache.removeAll()
        columnHeights.removeAll()
        super.invalidateLayout()
    }
}

// MARK: - 便捷方法

public extension UICollectionView {

    /// 应用流式布局
    ///
    /// - Parameters:
    ///   - itemsPerRow: 每行元素数
    ///   - spacing: 间距
    func ls_applyFlowLayout(itemsPerRow: Int = 3, spacing: CGFloat = 8) {
        let layout = LSFlowLayout()
        layout.maxItemsPerRow = itemsPerRow
        layout.minimumInterItemSpacing = spacing
        layout.minimumLineSpacing = spacing
        layout.shouldDistributeSpacing = true
        collectionViewLayout = layout
    }

    /// 应用标签流式布局
    ///
    /// - Parameters:
    ///   - alignment: 对齐方式
    ///   - tagSpacing: 标签间距
    ///   - lineSpacing: 行间距
    func ls_applyTagFlowLayout(alignment: LSTagFlowLayout.Alignment = .left, tagSpacing: CGFloat = 8, lineSpacing: CGFloat = 8) {
        let layout = LSTagFlowLayout(alignment: alignment)
        layout.tagSpacing = tagSpacing
        layout.lineSpacing = lineSpacing
        collectionViewLayout = layout
    }

    /// 应用瀑布流布局
    ///
    /// - Parameters:
    ///   - columnCount: 列数
    ///   - columnSpacing: 列间距
    ///   - lineSpacing: 行间距
    func ls_applyWaterfallLayout(columnCount: Int = 2, columnSpacing: CGFloat = 8, lineSpacing: CGFloat = 8) {
        let layout = LSWaterfallLayout(columnCount: columnCount, columnSpacing: columnSpacing, lineSpacing: lineSpacing)
        collectionViewLayout = layout
    }
}

#endif

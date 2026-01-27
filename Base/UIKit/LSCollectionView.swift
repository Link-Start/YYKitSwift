//
//  LSCollectionView.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  增强的集合视图 - 提供更多便捷功能
//

#if canImport(UIKit)
import UIKit

// MARK: - LSCollectionView

/// 增强的集合视图
public class LSCollectionView: UICollectionView {

    // MARK: - 类型定义

    /// 空视图配置
    public struct EmptyConfig {
        var image: UIImage?
        var title: String?
        var message: String?
        var buttonTitle: String?
        var buttonAction: (() -> Void)?

        public init(
            image: UIImage? = nil,
            title: String? = nil,
            message: String? = nil,
            buttonTitle: String? = nil,
            buttonAction: (() -> Void)? = nil
        ) {
            self.image = image
            self.title = title
            self.message = message
            self.buttonTitle = buttonTitle
            self.buttonAction = buttonAction
        }
    }

    /// 空视图
    private let emptyView: LSEmptyView = {
        let view = LSEmptyView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    /// 空视图配置
    public var emptyConfig: EmptyConfig? {
        didSet {
            updateEmptyView()
        }
    }

    /// 是否自动显示空视图
    public var autoShowEmpty: Bool = true {
        didSet {
            updateEmptyViewVisibility()
        }
    }

    // MARK: - 初始化

    public override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        setupCollectionView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCollectionView()
    }

    // MARK: - 设置

    private func setupCollectionView() {
        // 添加空视图
        backgroundView = emptyView

        // 约束
        NSLayoutConstraint.activate([
            emptyView.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyView.centerYAnchor.constraint(equalTo: centerYAnchor),
            emptyView.widthAnchor.constraint(equalTo: widthAnchor),
            emptyView.heightAnchor.constraint(equalTo: heightAnchor)
        ])
    }

    // MARK: - 空视图管理

    private func updateEmptyView() {
        guard let config = emptyConfig else { return }

        emptyView.image = config.image
        emptyView.title = config.title
        emptyView.message = config.message

        if let buttonTitle = config.buttonTitle {
            emptyView.setButtonTitle(buttonTitle) { [weak self] in
                config.buttonAction?()
            }
            emptyView.showButton = true
        } else {
            emptyView.showButton = false
        }
    }

    private func updateEmptyViewVisibility() {
        guard autoShowEmpty,
              let dataSource = dataSource else {
            emptyView.isHidden = true
            return
        }

        let itemCount = dataSource.collectionView(self, numberOfItemsInSection: 0)
        emptyView.isHidden = itemCount > 0
    }

    public override func reloadData() {
        super.reloadData()
        updateEmptyViewVisibility()
    }

    // MARK: - 注册

    /// 注册 cell（使用类名作为 identifier）
    public func ls_register<T: UICollectionViewCell>(_ cellType: T.Type) {
        let identifier = String(describing: cellType)
        register(cellType, forCellWithReuseIdentifier: identifier)
    }

    /// 注册 supplementary view
    public func ls_registerSupplementaryView<T: UICollectionReusableView>(
        _ viewType: T.Type,
        ofKind kind: String
    ) {
        let identifier = String(describing: viewType)
        register(viewType, forSupplementaryViewOfKind: kind, withReuseIdentifier: identifier)
    }

    /// 获取可重用 cell
    public func ls_dequeueReusableCell<T: UICollectionViewCell>(
        _ cellType: T.Type,
        for indexPath: IndexPath
    ) -> T {
        let identifier = String(describing: cellType)
        guard let cell = dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? T else {
            return T(frame: .zero)
        }
        return cell
    }

    /// 获取可重用 supplementary view
    public func ls_dequeueReusableSupplementaryView<T: UICollectionReusableView>(
        _ viewType: T.Type,
        ofKind kind: String,
        for indexPath: IndexPath
    ) -> T {
        let identifier = String(describing: viewType)
        guard let view = dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: identifier,
            for: indexPath
        ) as? T else {
            return T(frame: .zero)
        }
        return view
    }

    // MARK: - 滚动

    /// 滚动到顶部
    func ls_scrollToTop(animated: Bool = true) {
        guard numberOfItems(inSection: 0) > 0 else { return }
        let indexPath = IndexPath(item: 0, section: 0)
        scrollToItem(at: indexPath, at: .top, animated: animated)
    }

    /// 滚动到底部
    func ls_scrollToBottom(animated: Bool = true) {
        let lastSection = numberOfSections - 1
        guard lastSection >= 0 else { return }
        let lastItem = numberOfItems(inSection: lastSection) - 1
        guard lastItem >= 0 else { return }

        let indexPath = IndexPath(item: lastItem, section: lastSection)
        scrollToItem(at: indexPath, at: .bottom, animated: animated)
    }
}

// MARK: - UICollectionView Extension

public extension UICollectionView {

    /// 注册 cell（类型安全）
    func ls_register<T: UICollectionViewCell>(_ cellType: T.Type) {
        let identifier = String(describing: cellType)
        register(cellType, forCellWithReuseIdentifier: identifier)
    }

    /// 注册 supplementary view（类型安全）
    func ls_registerSupplementaryView<T: UICollectionReusableView>(
        _ viewType: T.Type,
        ofKind kind: String
    ) {
        let identifier = String(describing: viewType)
        register(viewType, forSupplementaryViewOfKind: kind, withReuseIdentifier: identifier)
    }

    /// 获取可重用 cell（类型安全）
    func ls_dequeueReusableCell<T: UICollectionViewCell>(
        _ cellType: T.Type,
        for indexPath: IndexPath
    ) -> T {
        let identifier = String(describing: cellType)
        guard let cell = dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? T else {
            return T(frame: .zero)
        }
        return cell
    }

    /// 获取可重用 supplementary view（类型安全）
    func ls_dequeueReusableSupplementaryView<T: UICollectionReusableView>(
        _ viewType: T.Type,
        ofKind kind: String,
        for indexPath: IndexPath
    ) -> T {
        let identifier = String(describing: viewType)
        guard let view = dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: identifier,
            for: indexPath
        ) as? T else {
            return T(frame: .zero)
        }
        return view
    }

    /// 滚动到顶部
    func ls_scrollToTop(animated: Bool = true) {
        guard numberOfItems(inSection: 0) > 0 else { return }
        let indexPath = IndexPath(item: 0, section: 0)
        scrollToItem(at: indexPath, at: .top, animated: animated)
    }

    /// 滚动到底部
    func ls_scrollToBottom(animated: Bool = true) {
        let lastSection = numberOfSections - 1
        guard lastSection >= 0 else { return }
        let lastItem = numberOfItems(inSection: lastSection) - 1
        guard lastItem >= 0 else { return }

        let indexPath = IndexPath(item: lastItem, section: lastSection)
        scrollToItem(at: indexPath, at: .bottom, animated: animated)
    }

    /// 获取可见的 indexPaths
    var ls_visibleIndexPaths: [IndexPath] {
        return indexPathsForVisibleItems
    }

    /// 获取第一个可见的 indexPath
    var ls_firstVisibleIndexPath: IndexPath? {
        return ls_visibleIndexPaths.first
    }

    /// 获取最后一个可见的 indexPath
    var ls_lastVisibleIndexPath: IndexPath? {
        return ls_visibleIndexPaths.last
    }

    /// 是否有更多内容
    func ls_hasMoreContent(below: IndexPath) -> Bool {
        let lastSection = numberOfSections - 1
        guard lastSection >= 0 else { return false }

        if below.section < lastSection {
            return true
        }

        let lastItem = numberOfItems(inSection: lastSection) - 1
        return below.item < lastItem
    }

    /// 添加下拉刷新
    @discardableResult
    func ls_addRefresh(handler: @escaping () -> Void) -> LSRefreshControl {
        let refresh = ls_addRefreshControl(handler: handler)
        return refresh
    }

    /// 添加无限滚动
    @discardableResult
    func ls_addInfiniteScroll(threshold: CGFloat = 60, handler: @escaping () -> Void) -> LSInfiniteScrollControl {
        let infinite = ls_addInfiniteScroll(threshold: threshold, handler: handler)
        return infinite
    }

    /// 选择项时执行回调
    func ls_onSelect(_ callback: @escaping (IndexPath) -> Void) {
        ls_removeAllActions()

        ls_addAction(for: .valueChanged) { [weak self] _ in
            guard let self = self,
                  let indexPath = self.indexPathsForSelectedItems?.first else { return }
            self.deselectItem(at: indexPath, animated: true)
            callback(indexPath)
        }
    }

    /// 批量更新
    func ls_performBatchUpdates(
        updates: (() -> Void),
        completion: ((Bool) -> Void)? = nil
    ) {
        performBatchUpdates(updates, completion: completion)
    }
}

// MARK: - UICollectionViewCell Extension

public extension UICollectionViewCell {

    /// 关联的数据
    private static var dataKey: UInt8 = 0

    var ls_data: Any? {
        get {
            return objc_getAssociatedObject(self, &UICollectionViewCell.dataKey)
        }
        set {
            objc_setAssociatedObject(
                self,
                &UICollectionViewCell.dataKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// 关联的 indexPath
    private static var indexPathKey: UInt8 = 0

    var ls_indexPath: IndexPath? {
        get {
            return objc_getAssociatedObject(self, &UICollectionViewCell.indexPathKey) as? IndexPath
        }
        set {
            objc_setAssociatedObject(
                self,
                &UICollectionViewCell.indexPathKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}

// MARK: - UICollectionReusableView Extension

public extension UICollectionReusableView {

    /// 关联的数据
    private static var dataKey: UInt8 = 0

    var ls_data: Any? {
        get {
            return objc_getAssociatedObject(self, &UICollectionReusableView.dataKey)
        }
        set {
            objc_setAssociatedObject(
                self,
                &UICollectionReusableView.dataKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// 关联的 indexPath
    private static var indexPathKey: UInt8 = 0

    var ls_indexPath: IndexPath? {
        get {
            return objc_getAssociatedObject(self, &UICollectionReusableView.indexPathKey) as? IndexPath
        }
        set {
            objc_setAssociatedObject(
                self,
                &UICollectionReusableView.indexPathKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}

// MARK: - UICollectionViewLayout Extension

public extension UICollectionViewLayout {

    /// 获取指定位置的所有布局属性
    func ls_layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes] {
        return super.layoutAttributesForElements(in: rect) ?? []
    }

    /// 获取指定位置的布局属性
    func ls_layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return super.layoutAttributesForItem(at: indexPath)
    }
}

// MARK: - Flow Layout Extension

public extension UICollectionViewFlowLayout {

    /// 创建流式布局
    static func ls_create(
        scrollDirection: UICollectionView.ScrollDirection = .vertical,
        minimumLineSpacing: CGFloat = 0,
        minimumInteritemSpacing: CGFloat = 0,
        itemSize: CGSize = CGSize(width: 50, height: 50),
        estimatedItemSize: CGSize = .zero,
        headerReferenceSize: CGSize = .zero,
        footerReferenceSize: CGSize = .zero,
        sectionInset: UIEdgeInsets = .zero
    ) -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = scrollDirection
        layout.minimumLineSpacing = minimumLineSpacing
        layout.minimumInteritemSpacing = minimumInteritemSpacing
        layout.itemSize = itemSize
        layout.estimatedItemSize = estimatedItemSize
        layout.headerReferenceSize = headerReferenceSize
        layout.footerReferenceSize = footerReferenceSize
        layout.sectionInset = sectionInset
        return layout
    }

    /// 设置为自适应大小
    func ls_setEstimatedSize(_ size: CGSize) {
        estimatedItemSize = size
    }

    /// 设置为完全自适应
    func ls_setAutomaticSize() {
        estimatedItemSize = UICollectionViewFlowLayoutAutomaticSize
    }
}

#endif

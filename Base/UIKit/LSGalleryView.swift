//
//  LSGalleryView.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  画廊视图 - 图片/视频画廊组件
//

#if canImport(UIKit)
import UIKit

// MARK: - LSGalleryView

/// 画廊视图
public class LSGalleryView: UIView {

    // MARK: - 类型定义

    /// 画廊项
    public struct GalleryItem {
        let type: ItemType
        let url: URL?
        let image: UIImage?
        let placeholder: UIImage?
        let title: String?
        let description: String?

        public enum ItemType {
            case image
            case video
        }

        public init(
            type: ItemType = .image,
            url: URL? = nil,
            image: UIImage? = nil,
            placeholder: UIImage? = nil,
            title: String? = nil,
            description: String? = nil
        ) {
            self.type = type
            self.url = url
            self.image = image
            self.placeholder = placeholder
            self.title = title
            self.description = description
        }

        /// 创建图片项
        public static func image(
            _ image: UIImage?,
            url: URL? = nil,
            placeholder: UIImage? = nil
        ) -> GalleryItem {
            return GalleryItem(type: .image, url: url, image: image, placeholder: placeholder)
        }

        /// 创建视频项
        public static func video(
            url: URL,
            placeholder: UIImage? = nil
        ) -> GalleryItem {
            return GalleryItem(type: .video, url: url, placeholder: placeholder)
        }
    }

    /// 选择回调
    public typealias SelectionHandler = (Int, GalleryItem) -> Void

    // MARK: - 属性

    /// 画廊项
    public var items: [GalleryItem] = [] {
        didSet {
            updateGallery()
        }
    }

    /// 当前索引
    public private(set) var currentIndex: Int = 0 {
        didSet {
            updateCurrentPage()
        }
    }

    /// 每页显示的项数
    public var itemsPerPage: Int = 3 {
        didSet {
            updateGallery()
        }
    }

    /// 项间距
    public var itemSpacing: CGFloat = 8 {
        didSet {
            collectionView?.invalidateIntrinsicContentSize()
        }
    }

    /// 边缘内边距
    public var edgeInsets: UIEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16) {
        didSet {
            collectionView?.invalidateIntrinsicContentSize()
        }
    }

    /// 是否显示分页指示器
    public var showsPageControl: Bool = true {
        didSet {
            pageControl.isHidden = !showsPageControl
        }
    }

    /// 分页指示器颜色
    public var pageIndicatorColor: UIColor = .systemGray {
        didSet {
            pageControl.pageIndicatorTintColor = pageIndicatorColor
        }
    }

    /// 当前页指示器颜色
    public var currentPageIndicatorColor: UIColor = .systemBlue {
        didSet {
            pageControl.currentPageIndicatorTintColor = currentPageIndicatorColor
        }
    }

    /// 选择回调
    public var onItemSelected: SelectionHandler?

    /// 滚动回调
    public var onScroll: ((Int) -> Void)?

    /// 是否缩放选中项
    public var scalesSelected: Bool = true

    // MARK: - UI 组件

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.isPagingEnabled = true
        cv.delegate = self
        cv.dataSource = self
        cv.translatesAutoresizingMaskIntoConstraints = false

        // 注册 cell
        cv.register(LSGalleryCell.self, forCellWithReuseIdentifier: "GalleryCell")

        return cv
    }()

    private let pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.translatesAutoresizingMaskIntoConstraints = false
        pc.hidesForSinglePage = true
        return pc
    }()

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupGallery()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGallery()
    }

    public convenience init(items: [GalleryItem] = []) {
        self.init(frame: .zero)
        self.items = items
    }

    // MARK: - 设置

    private func setupGallery() {
        addSubview(collectionView)
        addSubview(pageControl)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor, constant: edgeInsets.top),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.heightAnchor.constraint(equalTo: heightAnchor, constant: -(edgeInsets.top + edgeInsets.bottom)),

            pageControl.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -edgeInsets.bottom),
            pageControl.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }

    // MARK: - 更新方法

    private func updateGallery() {
        collectionView.reloadData()
        updatePageControl()
    }

    private func updateCurrentPage() {
        guard currentIndex < items.count else { return }

        let indexPath = IndexPath(item: currentIndex, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        pageControl.currentPage = currentIndex

        onScroll?(currentIndex)
    }

    private func updatePageControl() {
        let pages = Int(ceil(Double(items.count) / Double(itemsPerPage)))
        pageControl.numberOfPages = pages
        pageControl.currentPage = currentIndex / itemsPerPage
    }

    // MARK: - 公共方法

    /// 选择项
    public func selectItem(at index: Int) {
        guard index < items.count else { return }

        currentIndex = index
        updateCurrentPage()

        let item = items[index]
        onItemSelected?(index, item)
    }

    /// 下一页
    public func nextPage() {
        let nextIndex = min(currentIndex + itemsPerPage, items.count - 1)
        selectItem(at: nextIndex)
    }

    /// 上一页
    public func previousPage() {
        let previousIndex = max(0, currentIndex - itemsPerPage)
        selectItem(at: previousIndex)
    }

    /// 重新加载
    public func reload() {
        collectionView.reloadData()
        updatePageControl()
    }
}

// MARK: - UICollectionViewDataSource

extension LSGalleryView: UICollectionViewDataSource {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GalleryCell", for: indexPath) as! LSGalleryCell

        guard indexPath.item < items.count else { return cell }

        let item = items[indexPath.item]
        let isSelected = (indexPath.item == currentIndex)

        cell.configure(with: item, isSelected: isSelected, scales: scalesSelected)

        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension LSGalleryView: UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalSpacing = CGFloat(itemsPerPage - 1) * itemSpacing
        let totalPadding = edgeInsets.left + edgeInsets.right
        let availableWidth = collectionView.bounds.width - totalSpacing - totalPadding

        // 计算项大小（考虑选中项）
        if indexPath.item == currentIndex && scalesSelected {
            let selectedWidth = (availableWidth - totalSpacing) / 2
            return CGSize(width: selectedWidth, height: collectionView.bounds.height)
        } else {
            let normalWidth = (availableWidth - totalSpacing) / CGFloat(itemsPerPage)
            return CGSize(width: normalWidth, height: collectionView.bounds.height)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: edgeInsets.left, bottom: 0, right: edgeInsets.right)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return itemSpacing
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectItem(at: indexPath.item)
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageWidth = scrollView.bounds.width
        let currentPage = Int(scrollView.contentOffset.x / pageWidth)
        currentIndex = currentPage
    }
}

// MARK: - LSGalleryCell

/// 画廊单元格
private class LSGalleryCell: UICollectionViewCell {

    // MARK: - UI 组件

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let playButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        button.isUserInteractionEnabled = false
        return button
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    private let gradientView: UIView = {
        let view = UIView()
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.black.withAlphaComponent(0).cgColor,
            UIColor.black.withAlphaComponent(0.6).cgColor
        ]
        gradient.locations = [0, 1]
        view.layer.addSublayer(gradient)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    // MARK: - 初始化

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCell()
    }

    // MARK: - 设置

    private func setupCell() {
        contentView.addSubview(imageView)
        contentView.addSubview(playButton)
        contentView.addSubview(gradientView)
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            playButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 44),
            playButton.heightAnchor.constraint(equalToConstant: 44),

            gradientView.leadingAnchor.constraint(equalTo: leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: bottomAnchor),
            gradientView.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])

        layer.cornerRadius = 8
        clipsToBounds = true
    }

    // MARK: - 配置

    func configure(with item: LSGalleryView.GalleryItem, isSelected: Bool, scales: Bool) {
        // 设置图片
        if let image = item.image {
            imageView.image = image
        } else if let url = item.url {
            // 加载网络图片
            imageView.sd_setImage(with: url, placeholderImage: item.placeholder)
        } else if let placeholder = item.placeholder {
            imageView.image = placeholder
        }

        // 视频类型
        if item.type == .video {
            playButton.isHidden = false
        } else {
            playButton.isHidden = true
        }

        // 标题
        if let title = item.title {
            titleLabel.text = title
            titleLabel.isHidden = false
            gradientView.isHidden = false
        } else {
            titleLabel.isHidden = true
            gradientView.isHidden = true
        }

        // 选中效果
        if isSelected && scales {
            transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            layer.borderWidth = 2
            layer.borderColor = UIColor.systemBlue.cgColor
        } else {
            transform = .identity
            layer.borderWidth = 0
        }
    }
}

// MARK: - UIImage Extension (SDWebImage)

private extension UIImageView {

    /// 从 URL 加载图片（SDWebImage 简化版）
    func sd_setImage(with url: URL?, placeholderImage: UIImage? = nil) {
        if let url = url {
            // 这里应该使用 SDWebImage
            // 暂时使用系统方法
            if let data = try? Data(contentsOf: url) {
                image = UIImage(data: data)
            }
        }

        if image == nil, let placeholder = placeholderImage {
            image = placeholder
        }
    }
}

// MARK: - LSGridGalleryView

/// 网格画廊视图
public class LSGridGalleryView: UIView {

    // MARK: - 类型定义

    /// 选择回调
    public typealias SelectionHandler = (Int, LSGalleryView.GalleryItem) -> Void

    // MARK: - 属性

    /// 画廊项
    public var items: [LSGalleryView.GalleryItem] = [] {
        didSet {
            updateGallery()
        }
    }

    /// 每行列数
    public var columns: Int = 3 {
        didSet {
            updateGallery()
        }
    }

    /// 项间距
    public var itemSpacing: CGFloat = 8 {
        didSet {
            updateGallery()
        }
    }

    /// 行间距
    public var lineSpacing: CGFloat = 8 {
        didSet {
            updateGallery()
        }
    }

    /// 边缘内边距
    public var sectionInsets: UIEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16) {
        didSet {
            updateGallery()
        }
    }

    /// 选择回调
    public var onItemSelected: SelectionHandler?

    /// 是否支持多选
    public var allowsMultipleSelection: Bool = false {
        didSet {
            collectionView.allowsMultipleSelection = allowsMultipleSelection
        }
    }

    /// 选中的索引
    public private(set) var selectedIndices: Set<Int> = []

    /// 选择变化回调
    public var onSelectionChanged: ((Set<Int>) -> Void)?

    // MARK: - UI 组件

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.delegate = self
        cv.dataSource = self
        cv.translatesAutoresizingMaskIntoConstraints = false

        // 注册 cell
        cv.register(LSGridGalleryCell.self, forCellWithReuseIdentifier: "GridGalleryCell")

        return cv
    }()

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupGridGallery()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGridGallery()
    }

    public convenience init(items: [LSGalleryView.GalleryItem] = []) {
        self.init(frame: .zero)
        self.items = items
    }

    // MARK: - 设置

    private func setupGridGallery() {
        addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - 更新方法

    private func updateGallery() {
        collectionView.reloadData()
    }

    // MARK: - 公共方法

    /// 选择项
    public func selectItem(at index: Int) {
        guard index < items.count else { return }

        if allowsMultipleSelection {
            if selectedIndices.contains(index) {
                selectedIndices.remove(index)
            } else {
                selectedIndices.insert(index)
            }
            collectionView.selectItem(at: IndexPath(item: index, section: 0), animated: true)
        } else {
            selectedIndices.removeAll()
            selectedIndices.insert(index)
            collectionView.selectItem(at: IndexPath(item: index, section: 0), animated: true)
        }

        onSelectionChanged?(selectedIndices)
    }

    /// 获取选中的项
    public var selectedItems: [LSGalleryView.GalleryItem] {
        return selectedIndices.compactMap { index in
            guard index < items.count else { return nil }
            return items[index]
        }
    }

    /// 清除选择
    public func clearSelection() {
        selectedIndices.removeAll()
        collectionView.reloadData()
        onSelectionChanged?(selectedIndices)
    }

    /// 重新加载
    public func reload() {
        collectionView.reloadData()
    }
}

// MARK: - UICollectionViewDataSource

extension LSGridGalleryView: UICollectionViewDataSource {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GridGalleryCell", for: indexPath) as! LSGridGalleryCell

        guard indexPath.item < items.count else { return cell }

        let item = items[indexPath.item]
        let isSelected = selectedIndices.contains(indexPath.item)

        cell.configure(with: item, isSelected: isSelected)

        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension LSGridGalleryView: UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalSpacing = CGFloat(columns - 1) * itemSpacing
        let totalPadding = sectionInsets.left + sectionInsets.right
        let availableWidth = collectionView.bounds.width - totalSpacing - totalPadding
        let itemWidth = (availableWidth - totalSpacing) / CGFloat(columns)

        return CGSize(width: itemWidth, height: itemWidth)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return lineSpacing
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return itemSpacing
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectItem(at: indexPath.item)

        if !allowsMultipleSelection, indexPath.item < items.count {
            let item = items[indexPath.item]
            onItemSelected?(indexPath.item, item)
        }
    }
}

// MARK: - LSGridGalleryCell

/// 网格画廊单元格
private class LSGridGalleryCell: UICollectionViewCell {

    // MARK: - UI 组件

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let selectionOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    private let checkmarkView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "checkmark.circle.fill")
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isHidden = true
        return iv
    }()

    // MARK: - 初始化

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCell()
    }

    // MARK: - 设置

    private func setupCell() {
        contentView.addSubview(imageView)
        contentView.addSubview(selectionOverlay)
        contentView.addSubview(checkmarkView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            selectionOverlay.topAnchor.constraint(equalTo: contentView.topAnchor),
            selectionOverlay.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            selectionOverlay.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            selectionOverlay.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            checkmarkView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            checkmarkView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            checkmarkView.widthAnchor.constraint(equalToConstant: 24),
            checkmarkView.heightAnchor.constraint(equalToConstant: 24)
        ])

        layer.cornerRadius = 8
        clipsToBounds = true
    }

    // MARK: - 配置

    func configure(with item: LSGalleryView.GalleryItem, isSelected: Bool) {
        // 设置图片
        if let image = item.image {
            imageView.image = image
        } else if let url = item.url {
            imageView.sd_setImage(with: url, placeholderImage: item.placeholder)
        } else if let placeholder = item.placeholder {
            imageView.image = placeholder
        }

        // 选中状态
        if isSelected {
            selectionOverlay.isHidden = false
            checkmarkView.isHidden = false
        } else {
            selectionOverlay.isHidden = true
            checkmarkView.isHidden = true
        }
    }
}

// MARK: - UIView Extension (Gallery)

public extension UIView {

    /// 添加画廊视图
    @discardableResult
    func ls_addGallery(
        items: [LSGalleryView.GalleryItem],
        height: CGFloat = 120
    ) -> LSGalleryView {
        let gallery = LSGalleryView(items: items)
        gallery.translatesAutoresizingMaskIntoConstraints = false

        addSubview(gallery)

        NSLayoutConstraint.activate([
            gallery.topAnchor.constraint(equalTo: topAnchor),
            gallery.leadingAnchor.constraint(equalTo: leadingAnchor),
            gallery.trailingAnchor.constraint(equalTo: trailingAnchor),
            gallery.heightAnchor.constraint(equalToConstant: height)
        ])

        return gallery
    }

    /// 添加网格画廊视图
    @discardableResult
    func ls_addGridGallery(
        items: [LSGalleryView.GalleryItem],
        columns: Int = 3
    ) -> LSGridGalleryView {
        let gallery = LSGridGalleryView(items: items)
        gallery.columns = columns
        gallery.translatesAutoresizingMaskIntoConstraints = false

        addSubview(gallery)

        NSLayoutConstraint.activate([
            gallery.topAnchor.constraint(equalTo: topAnchor),
            gallery.leadingAnchor.constraint(equalTo: leadingAnchor),
            gallery.trailingAnchor.constraint(equalTo: trailingAnchor),
            gallery.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        return gallery
    }
}

#endif

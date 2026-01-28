//
//  LSBannerView.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  横幅视图 - 轮播图组件
//

#if canImport(UIKit)
import UIKit

// MARK: - LSBannerView

/// 横幅视图
@MainActor
public class LSBannerView: UIView {

    // MARK: - 类型定义

    /// 轮播项
    public struct BannerItem {
        let image: UIImage?
        let imageUrl: URL?
        let title: String?
        let action: (() -> Void)?

        public init(
            image: UIImage? = nil,
            imageUrl: URL? = nil,
            title: String? = nil,
            action: (() -> Void)? = nil
        ) {
            self.image = image
            self.imageUrl = imageUrl
            self.title = title
            self.action = action
        }
    }

    /// 页面回调
    public typealias PageHandler = (Int) -> Void

    // MARK: - 属性

    /// 轮播项
    public var items: [BannerItem] = [] {
        didSet {
            updateItems()
        }
    }

    /// 自动滚动间隔
    public var autoScrollInterval: TimeInterval = 3.0 {
        didSet {
            if isAutoScrolling {
                restartAutoScroll()
            }
        }
    }

    /// 是否自动滚动
    public var isAutoScrolling: Bool = true {
        didSet {
            if isAutoScrolling {
                startAutoScroll()
            } else {
                stopAutoScroll()
            }
        }
    }

    /// 是否无限循环
    public var isInfinite: Bool = true

    /// 是否显示页面指示器
    public var showsPageControl: Bool = true {
        didSet {
            pageControl.isHidden = !showsPageControl
        }
    }

    /// 页面指示器位置
    public var pageControlPosition: PageControlPosition = .bottomCenter {
        didSet {
            updatePageControlPosition()
        }
    }

    /// 页面变化回调
    public var onPageChanged: PageHandler?

    /// 占位图
    public var placeholderImage: UIImage?

    // MARK: - UI 组件

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.isPagingEnabled = true
        sv.showsHorizontalScrollIndicator = false
        sv.bounces = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.delegate = ProxyDelegate()
        return sv
    }()

    private let pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.currentPage = 0
        pc.translatesAutoresizingMaskIntoConstraints = false
        pc.hidesForSinglePage = true
        return pc
    }()

    private var pageViews: [UIView] = []

    private var autoScrollTimer: Timer?

    // MARK: - 代理类

    private class ProxyDelegate: NSObject, UIScrollViewDelegate {
        var onScroll: ((UIScrollView) -> Void)?
        var onEndDecelerating: (() -> Void)?

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            onScroll?(scrollView)
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            onEndDecelerating?()
        }
    }

    // MARK: - 页面指示器位置

    public enum PageControlPosition {
        case topLeft
        case topCenter
        case topRight
        case bottomLeft
        case bottomCenter
        case bottomRight
    }

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupBanner()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupBanner()
    }

    public init(items: [BannerItem] = []) {
        self.items = items
        super.init(frame: .zero)
        setupBanner()
    }

    // MARK: - 设置

    private func setupBanner() {
        addSubview(scrollView)
        addSubview(pageControl)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        updatePageControlPosition()

        // 设置代理
        if let delegate = scrollView.delegate as? ProxyDelegate {
            delegate.onScroll = { [weak self] scrollView in
                self?.handleScroll(scrollView)
            }

            delegate.onEndDecelerating = { [weak self] in
                self?.restartAutoScroll()
            }
        }

        clipsToBounds = true
        layer.cornerRadius = 12
    }

    // MARK: - 更新

    private func updateItems() {
        // 移除旧的页面视图
        pageViews.forEach { $0.removeFromSuperview() }
        pageViews.removeAll()

        for item in items {
            let pageView = UIView()
            pageView.translatesAutoresizingMaskIntoConstraints = false

            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.translatesAutoresizingMaskIntoConstraints = false

            pageView.addSubview(imageView)

            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: pageView.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: pageView.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: pageView.trailingAnchor),
                imageView.bottomAnchor.constraint(equalTo: pageView.bottomAnchor)
            ])

            // 加载图片
            if let image = item.image {
                imageView.image = image
            } else if let imageUrl = item.imageUrl {
                // 加载网络图片（这里简化处理，实际应使用 SDWebImage 等）
                imageView.sd_setImage(with: imageUrl, placeholderImage: placeholderImage)
            }

            // 添加标题标签
            if let title = item.title {
                let titleLabel = UILabel()
                titleLabel.text = title
                titleLabel.font = .boldSystemFont(ofSize: 18)
                titleLabel.textColor = .white
                titleLabel.backgroundColor = UIColor.black.withAlphaComponent(0.3)
                titleLabel.textAlignment = .left
                titleLabel.translatesAutoresizingMaskIntoConstraints = false

                pageView.addSubview(titleLabel)

                NSLayoutConstraint.activate([
                    titleLabel.leadingAnchor.constraint(equalTo: pageView.leadingAnchor, constant: 16),
                    titleLabel.trailingAnchor.constraint(equalTo: pageView.trailingAnchor, constant: -16),
                    titleLabel.bottomAnchor.constraint(equalTo: pageView.bottomAnchor, constant: -16)
                ])
            }

            // 添加点击手势
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handlePageTap(_:)))
            pageView.addGestureRecognizer(tapGesture)
            pageView.tag = pageViews.count

            scrollView.addSubview(pageView)
            pageViews.append(pageView)
        }

        pageControl.numberOfPages = items.count

        setNeedsLayout()
    }

    private func updatePageControlPosition() {
        pageControl.constraints.forEach { pageControl.removeConstraint($0) }

        switch pageControlPosition {
        case .topLeft:
            NSLayoutConstraint.activate([
                pageControl.topAnchor.constraint(equalTo: topAnchor, constant: 8),
                pageControl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8)
            ])

        case .topCenter:
            NSLayoutConstraint.activate([
                pageControl.topAnchor.constraint(equalTo: topAnchor, constant: 8),
                pageControl.centerXAnchor.constraint(equalTo: centerXAnchor)
            ])

        case .topRight:
            NSLayoutConstraint.activate([
                pageControl.topAnchor.constraint(equalTo: topAnchor, constant: 8),
                pageControl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
            ])

        case .bottomLeft:
            NSLayoutConstraint.activate([
                pageControl.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
                pageControl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8)
            ])

        case .bottomCenter:
            NSLayoutConstraint.activate([
                pageControl.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
                pageControl.centerXAnchor.constraint(equalTo: centerXAnchor)
            ])

        case .bottomRight:
            NSLayoutConstraint.activate([
                pageControl.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
                pageControl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
            ])
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        let pageSize = bounds.size
        let contentWidth = pageSize.width * CGFloat(pageViews.count)

        for (index, pageView) in pageViews.enumerated() {
            pageView.frame = CGRect(x: pageSize.width * CGFloat(index), y: 0, width: pageSize.width, height: pageSize.height)
        }

        scrollView.contentSize = CGSize(width: contentWidth, height: pageSize.height)
    }

    // MARK: - 滚动处理

    private func handleScroll(_ scrollView: UIScrollView) {
        let pageIndex = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))

        if isInfinite && pageViews.count > 1 {
            // 处理无限循环
            if pageIndex == 0 && scrollView.contentOffset.x < scrollView.bounds.width / 2 {
                scrollView.contentOffset.x = scrollView.bounds.width * CGFloat(pageViews.count - 1)
            } else if pageIndex == pageViews.count - 1 && scrollView.contentOffset.x > scrollView.bounds.width * CGFloat(pageViews.count - 1) + scrollView.bounds.width / 2 {
                scrollView.contentOffset.x = 0
            }
        }

        pageControl.currentPage = pageIndex

        if let currentPage = pageControl.currentPage, currentPage != currentPage {
            onPageChanged?(currentPage)
        }
    }

    @objc private func handlePageTap(_ gesture: UITapGestureRecognizer) {
        guard let pageView = gesture.view else { return }

        let index = pageView.tag

        if index < items.count {
            items[index].action?()
        }
    }

    // MARK: - 自动滚动

    private func startAutoScroll() {
        stopAutoScroll()

        guard isAutoScrolling && pageViews.count > 1 else { return }

        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: autoScrollInterval, repeats: true) { [weak self] _ in
            self?.scrollToNextPage()
        }
    }

    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }

    private func restartAutoScroll() {
        if isAutoScrolling {
            startAutoScroll()
        }
    }

    // MARK: - 公共方法

    /// 滚动到指定页面
    public func scrollToPage(_ index: Int, animated: Bool = true) {
        guard index >= 0 && index < pageViews.count else { return }

        let offset = CGPoint(x: scrollView.bounds.width * CGFloat(index), y: 0)
        scrollView.setContentOffset(offset, animated: animated)
    }

    /// 滚动到下一页
    public func scrollToNextPage(animated: Bool = true) {
        let nextPage = (pageControl.currentPage + 1) % pageViews.count
        scrollToPage(nextPage, animated: animated)
    }

    /// 滚动到上一页
    public func scrollToPreviousPage(animated: Bool = true) {
        let prevPage = (pageControl.currentPage - 1 + pageViews.count) % pageViews.count
        scrollToPage(prevPage, animated: animated)
    }

    deinit {
        stopAutoScroll()
    }
}

// MARK: - 便捷创建

public extension LSBannerView {

    /// 从图片创建轮播
    static func create(
        images: [UIImage],
        autoScrollInterval: TimeInterval = 3.0,
        isInfinite: Bool = true
    ) -> LSBannerView {
        let items: [BannerItem] = images.map { image in
            BannerItem(image: image)
        }

        let banner = LSBannerView(items: items)
        banner.autoScrollInterval = autoScrollInterval
        banner.isInfinite = isInfinite

        return banner
    }

    /// 从 URL 创建轮播
    static func create(
        imageUrls: [URL],
        placeholderImage: UIImage? = nil,
        autoScrollInterval: TimeInterval = 3.0
    ) -> LSBannerView {
        let items: [BannerItem] = imageUrls.map { url in
            BannerItem(imageUrl: url)
        }

        let banner = LSBannerView(items: items)
        banner.placeholderImage = placeholderImage
        banner.autoScrollInterval = autoScrollInterval

        return banner
    }
}

// MARK: - Image URL Extension (SDWebImage)

private extension UIImageView {

    /// 从 URL 加载图片
    func sd_setImage(with url: URL?, placeholderImage: UIImage? = nil) {
        // 这里应该是 SDWebImage 的实现
        // 暂时使用系统方法
        if let url = url {
            // 实际项目中应使用 SDWebImage
            // imageView.sd_setImage(with: url, placeholderImage: placeholderImage)
        }
    }
}

// MARK: - Banner Cell

/// 轮播 Cell（用于 CollectionView）
public class LSBannerCell: UICollectionViewCell {

    /// 轮播视图
    public let bannerView: LSBannerView = {
        let banner = LSBannerView()
        banner.translatesAutoresizingMaskIntoConstraints = false
        return banner
    }()

    /// 重用标识符
    static let reuseIdentifier = "LSBannerCell"

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCell()
    }

    // MARK: - 设置

    private func setupCell() {
        contentView.addSubview(bannerView)

        NSLayoutConstraint.activate([
            bannerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            bannerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bannerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bannerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            bannerView.heightAnchor.constraint(equalToConstant: 180)
        ])

        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
    }

    /// 配置轮播
    func configure(items: [LSBannerView.BannerItem]) {
        bannerView.items = items
        bannerView.setNeedsLayout()
    }
}

// MARK: - Banner Config

/// 轮播配置
public struct LSBannerConfig {

    /// 自动滚动间隔
    public var autoScrollInterval: TimeInterval = 3.0

    /// 是否无限循环
    public var isInfinite: Bool = true

    /// 是否显示页面指示器
    public var showsPageControl: Bool = true

    /// 页面指示器位置
    public var pageControlPosition: LSBannerView.PageControlPosition = .bottomCenter

    /// 占位图
    public var placeholderImage: UIImage?

    /// 页面指示器颜色
    public var pageIndicatorTintColor: UIColor = .systemGray
    public var currentPageIndicatorTintColor: UIColor = .systemBlue

    public init() {}
}

// MARK: - UIViewController Extension (Banner)

public extension UIViewController {

    /// 关联的轮播视图
    private static var bannerViewKey: UInt8 = 0

    var ls_bannerView: LSBannerView? {
        get {
            return objc_getAssociatedObject(self, &UIViewController.bannerViewKey) as? LSBannerView
        }
        set {
            objc_setAssociatedObject(
                self,
                &UIViewController.bannerViewKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    /// 添加轮播视图
    @discardableResult
    func ls_addBannerView(
        images: [UIImage],
        height: CGFloat = 180,
        autoScrollInterval: TimeInterval = 3.0,
        isInfinite: Bool = true,
        position: BannerPosition = .top
    ) -> LSBannerView {
        let banner = LSBannerView.create(images: images, autoScrollInterval: autoScrollInterval, isInfinite: isInfinite)

        view.addSubview(banner)
        banner.translatesAutoresizingMaskIntoConstraints = false

        switch position {
        case .top:
            NSLayoutConstraint.activate([
                banner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                banner.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                banner.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                banner.heightAnchor.constraint(equalToConstant: height)
            ])

        case .aboveNavigationBar:
            NSLayoutConstraint.activate([
                banner.topAnchor.constraint(equalTo: view.topAnchor),
                banner.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                banner.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                banner.heightAnchor.constraint(equalToConstant: height)
            ])
        }

        ls_bannerView = banner
        return banner
    }

    /// 轮播位置
    enum BannerPosition {
        case top
        case aboveNavigationBar
    }

    /// 移除轮播视图
    func ls_removeBannerView() {
        ls_bannerView?.removeFromSuperview()
        ls_bannerView = nil
    }
}

#endif

//
//  LSImageScrollView.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  图片滚动视图 - 支持缩放的图片查看器
//

#if canImport(UIKit)
import UIKit

// MARK: - LSImageScrollView

/// 图片滚动视图
public class LSImageScrollView: UIScrollView {

    // MARK: - 类型定义

    /// 缩放变化回调
    public typealias ZoomHandler = (CGFloat) -> Void

    /// 双击回调
    public typealias DoubleTapHandler = (CGPoint) -> Void

    // MARK: - 属性

    /// 图片视图
    public let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    /// 最小缩放比例
    public var minimumZoomScale: CGFloat = 1.0 {
        didSet {
            updateMinMaxZoomScale()
        }
    }

    /// 最大缩放比例
    public var maximumZoomScale: CGFloat = 3.0 {
        didSet {
            updateMinMaxZoomScale()
        }
    }

    /// 缩放变化回调
    public var onZoomChanged: ZoomHandler?

    /// 双击回调
    public var onDoubleTap: DoubleTapHandler?

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupImageScrollView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupImageScrollView()
    }

    public init(image: UIImage? = nil) {
        super.init(frame: .zero)
        setupImageScrollView()

        if let image = image {
            setImage(image)
        }
    }

    // MARK: - 设置

    private func setupImageScrollView() {
        delegate = self
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        bounces = false
        bouncesZoom = false
        minimumZoomScale = 1.0
        maximumZoomScale = 3.0

        addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: widthAnchor),
            imageView.heightAnchor.constraint(equalTo: heightAnchor)
        ])

        // 双击手势
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapGesture)

        // 双指手势
        let doubleTapGesture2 = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture2.numberOfTapsRequired = 2
        doubleTapGesture2.numberOfTouchesRequired = 2
        addGestureRecognizer(doubleTapGesture2)

        // 单击手势（用于取消双击）
        let singleTapGesture = UITapGestureRecognizer(target: self, action: nil)
        singleTapGesture.require(toFail: doubleTapGesture)
        addGestureRecognizer(singleTapGesture)
        singleTapGesture.require(toFail: doubleTapGesture2)
    }

    // MARK: - 图片设置

    /// 设置图片
    public func setImage(_ image: UIImage?) {
        imageView.image = image
        updateContentSize()
    }

    /// 更新内容大小
    private func updateContentSize() {
        guard let image = imageView.image else { return }

        let imageSize = image.size
        let scrollViewSize = bounds.size

        // 计算适合的缩放比例
        let scaleWidth = scrollViewSize.width / imageSize.width
        let scaleHeight = scrollViewSize.height / imageSize.height
        let minScale = min(scaleWidth, scaleHeight)

        // 设置缩放比例
        zoomScale = minScale
        minimumZoomScale = minScale
        maximumZoomScale = minScale * 3

        // 更新内容大小
        contentSize = imageSize
    }

    // MARK: - 缩放

    private func updateMinMaxZoomScale() {
        zoomScale = min(max(zoomScale, minimumZoomScale), maximumZoomScale)
    }

    /// 缩放到指定位置
    public func zoom(to point: CGPoint, scale: CGFloat, animated: Bool = true) {
        let targetScale = min(max(scale, minimumZoomScale), maximumZoomScale)

        let width = bounds.width / targetScale
        let height = bounds.height / targetScale

        var targetOffset = CGPoint(
            x: point.x - width / 2,
            y: point.y - height / 2
        )

        targetOffset = max(
            CGPoint(x: 0, y: 0),
            min(
                targetOffset,
                CGPoint(
                    x: contentSize.width - width,
                    y: contentSize.height - height
                )
            )
        )

        if animated {
            UIView.animate(withDuration: 0.3) {
                self.zoomScale = targetScale
                self.contentOffset = targetOffset
            }
        } else {
            zoomScale = targetScale
            contentOffset = targetOffset
        }
    }

    // MARK: - 手势处理

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard imageView.image != nil else { return }

        let point = gesture.location(in: imageView)

        // 计算缩放比例
        var scale: CGFloat
        if abs(zoomScale - minimumZoomScale) < 0.01 {
            scale = maximumZoomScale
        } else {
            scale = minimumZoomScale
        }

        zoom(to: point, scale: scale, animated: true)

        onDoubleTap?(point)
    }

    // MARK: - 重置

    /// 重置缩放
    public func resetZoom(animated: Bool = true) {
        zoomScale = minimumZoomScale
        contentOffset = .zero
    }
}

// MARK: - UIScrollViewDelegate

extension LSImageScrollView: UIScrollViewDelegate {

    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    public func scrollViewDidZoom(_ scrollView: UIScrollView, withScale scale: CGFloat, view: UIView? {
        onZoomChanged?(scale)

        // 居中图片
        if let imageView = view as? UIImageView {
            let offsetX = max(0, (scrollView.bounds.width - imageView.bounds.width) / 2)
            let offsetY = max(0, (scrollView.bounds.height - imageView.bounds.height) / 2)
            contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: 0, right: 0)
        }
    }
}

// MARK: - Image Viewer Controller

/// 图片查看器控制器
public class LSImageViewController: UIViewController {

    // MARK: - 属性

    /// 图片滚动视图
    public let imageScrollView: LSImageScrollView = {
        let scrollView = LSImageScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    /// 图片数组
    public var images: [UIImage] = [] {
        didSet {
            updateCurrentImage()
        }
    }

    /// 当前索引
    public private(set) var currentIndex: Int = 0

    /// 是否显示页面指示器
    public var showsPageControl: Bool = true

    /// 是否显示工具栏
    public var showsToolbar: Bool = true

    /// 工具栏
    private let toolbar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let pageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - 初始化

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setupViewer()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViewer()
    }

    public init(images: [UIImage] = [], startIndex: Int = 0) {
        self.images = images
        self.currentIndex = startIndex
        super.init(nibName: nil, bundle: nil)
        setupViewer()
    }

    // MARK: - 设置

    private func setupViewer() {
        view.backgroundColor = .black
        view.addSubview(imageScrollView)
        view.addSubview(toolbar)

        NSLayoutConstraint.activate([
            imageScrollView.topAnchor.constraint(equalTo: view.topAnchor),
            imageScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 44)
        ])

        if showsToolbar {
            setupToolbar()
        }

        updateCurrentImage()
    }

    private func setupToolbar() {
        toolbar.isHidden = false
        toolbar.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -34).isActive = true

        // 添加关闭按钮
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("关闭", for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 16)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        closeButton.ls_addAction(for: .touchUpInside) { [weak self] in
            self?.dismiss(animated: true)
        }

        toolbar.addSubview(closeButton)
        toolbar.addSubview(pageLabel)

        NSLayoutConstraint.activate([
            closeButton.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor, constant: 16),
            closeButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),

            pageLabel.centerXAnchor.constraint(equalTo: toolbar.centerXAnchor),
            pageLabel.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor)
        ])
    }

    private func updateCurrentImage() {
        guard currentIndex < images.count else { return }

        let image = images[currentIndex]
        imageScrollView.setImage(image)

        if showsToolbar {
            pageLabel.text = "\(currentIndex + 1) / \(images.count)"
        }
    }

    // MARK: - 公共方法

    /// 显示下一张
    public func showNext() {
        guard currentIndex < images.count - 1 else { return }
        currentIndex += 1
        updateCurrentImage()
    }

    /// 显示上一张
    public func showPrevious() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        updateCurrentImage()
    }

    /// 添加左滑/右滑手势
    public func enableSwipeGestures() {
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        leftSwipe.direction = .left

        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        rightSwipe.direction = .right

        view.addGestureRecognizer(leftSwipe)
        view.addGestureRecognizer(rightSwipe)
    }

    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        if gesture.direction == .left {
            showNext()
        } else if gesture.direction == .right {
            showPrevious()
        }
    }
}

// MARK: - Simple Image Viewer

/// 简单的图片查看器
public class LSSimpleImageViewer: UIViewController {

    /// 图片
    public var image: UIImage? {
        didSet {
            updateImage()
        }
    }

    /// 图片视图
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    /// 是否支持缩放
    public var supportsZoom: Bool = true

    // MARK: - 初始化

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setupViewer()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViewer()
    }

    public init(image: UIImage? = nil) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
        setupViewer()
    }

    // MARK: - 设置

    private func setupViewer() {
        view.backgroundColor = .black
        view.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            imageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.8)
        ])

        updateImage()

        // 点击关闭
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tapGesture)
    }

    private func updateImage() {
        imageView.image = image
    }

    @objc private func handleTap() {
        dismiss(animated: true)
    }
}

// MARK: - Image Gallery

/// 图片画廊
public class LSImageGallery: UIView {

    // MARK: - 类型定义

    /// 选择回调
    public typealias SelectionHandler = (Int, UIImage) -> Void

    // MARK: - 属性

    /// 图片数组
    public var images: [UIImage] = [] {
        didSet {
            updateGallery()
        }
    }

    /// 当前索引
    public private(set) var selectedIndex: Int = 0 {
        didSet {
            updateSelection()
        }
    }

    /// 缩略图大小
    public var thumbnailSize: CGSize = CGSize(width: 60, height: 60) {
        didSet {
            updateThumbnailSize()
        }
    }

    /// 缩略图间距
    public var thumbnailSpacing: CGFloat = 8 {
        didSet {
            updateSpacing()
        }
    }

    /// 选择回调
    public var onSelection: SelectionHandler?

    // MARK: - UI 组件

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let previewView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private var thumbnailViews: [UIImageView] = []

    // MARK: - 初始化

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupGallery()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGallery()
    }

    // MARK: - 设置

    private func setupGallery() {
        addSubview(scrollView)
        scrollView.addSubview(stackView)
        addSubview(previewView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: thumbnailSize.height + 16),

            previewView.topAnchor.constraint(equalTo: topAnchor),
            previewView.leadingAnchor.constraint(equalTo: leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: trailingAnchor),
            previewView.heightAnchor.constraint(equalTo: scrollView.topAnchor, constant: -16),

            stackView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.heightAnchor.constraint(equalToConstant: thumbnailSize.height)
        ])
    }

    // MARK: - 更新

    private func updateGallery() {
        // 移除旧的缩略图
        thumbnailViews.forEach { $0.removeFromSuperview() }
        thumbnailViews.removeAll()

        for image in images {
            let imageView = UIImageView()
            imageView.image = image
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 8
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.isUserInteractionEnabled = true

            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalToConstant: thumbnailSize.width),
                imageView.heightAnchor.constraint(equalToConstant: thumbnailSize.height)
            ])

            // 添加点击手势
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleThumbnailTap(_:)))
            imageView.addGestureRecognizer(tapGesture)

            stackView.addArrangedSubview(imageView)
            thumbnailViews.append(imageView)
        }

        // 更新预览图
        if !images.isEmpty {
            previewView.image = images[0]
            selectedIndex = 0
        }
    }

    private func updateSelection() {
        guard selectedIndex < images.count else { return }

        // 更新预览图
        previewView.image = images[selectedIndex]

        // 更新缩略图选中状态
        for (index, thumbnailView) in thumbnailViews.enumerated() {
            if index == selectedIndex {
                thumbnailView.layer.borderWidth = 2
                thumbnailView.layer.borderColor = UIColor.systemBlue.cgColor
            } else {
                thumbnailView.layer.borderWidth = 0
            }
        }
    }

    private func updateThumbnailSize() {
        for thumbnailView in thumbnailViews {
            thumbnailView.constraints.forEach { constraint in
                if constraint.firstAttribute == .width {
                    constraint.constant = thumbnailSize.width
                } else if constraint.firstAttribute == .height {
                    constraint.constant = thumbnailSize.height
                }
            }
        }

        scrollView.constraints.forEach { constraint in
            if constraint.firstAttribute == .height {
                constraint.constant = thumbnailSize.height + 16
            }
        }
    }

    private func updateSpacing() {
        stackView.spacing = thumbnailSpacing
    }

    // MARK: - 手势处理

    @objc private func handleThumbnailTap(_ gesture: UITapGestureRecognizer) {
        guard let index = thumbnailViews.firstIndex(where: { $0 === gesture.view }) else { return }

        selectedIndex = index
        onSelection?(index, images[index])
    }
}

#endif

//
//  LSPopoverView.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  弹出视图 - 类似 UIPopoverController 的弹出菜单
//

#if canImport(UIKit)
import UIKit

// MARK: - LSPopoverView

/// 弹出视图
@MainActor
public class LSPopoverView: UIView {

    // MARK: - 类型定义

    /// 选中项回调
    public typealias SelectionHandler = (LSPopoverItem) -> Void

    /// 取消回调
    public typealias CancelHandler = () -> Void

    // MARK: - 属性

    /// 弹出项
    public var items: [LSPopoverItem] = [] {
        didSet {
            updateItems()
        }
    }

    /// 选中回调
    public var onItemSelected: SelectionHandler?

    /// 取消回调
    public var onCancel: CancelHandler?

    /// 背景样式
    public var backgroundStyle: BackgroundStyle = .dimmed {
        didSet {
            updateBackground()
        }
    }

    /// 箭头方向
    public var arrowDirection: ArrowDirection = .auto {
        didSet {
            setNeedsLayout()
        }
    }

    /// 目标视图
    private weak var targetView: UIView?

    /// 目标区域
    private var targetRect: CGRect?

    /// 背景视图
    private let backgroundView: UIView = {
        let bv = UIView()
        bv.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        return bv
    }()

    /// 内容视图
    private let contentView: UIView = {
        let cv = UIView()
        cv.backgroundColor = .systemBackground
        cv.layer.cornerRadius = 8
        cv.layer.shadowColor = UIColor.black.cgColor
        cv.layer.shadowOffset = CGSize(width: 0, height: 2)
        cv.layer.shadowRadius = 8
        cv.layer.shadowOpacity = 0.2
        return cv
    }()

    /// 表格视图
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.separatorStyle = .singleLine
        tv.isScrollEnabled = false
        return tv
    }()

    /// 箭头视图
    private let arrowView: UIView = {
        let av = UIView()
        av.backgroundColor = .systemBackground
        return av
    }()

    // MARK: - 枚举

    /// 背景样式
    public enum BackgroundStyle {
        case dimmed            // 变暗
        case blurred          // 模糊
        case none             // 无
    }

    /// 箭头方向
    public enum ArrowDirection {
        case up
        case down
        case left
        case right
        case auto
    }

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

        contentView.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self

        contentView.addSubview(arrowView)
        arrowView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: contentView.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        // 注册 Cell
        tableView.register(
            LSPopoverCell.self,
            forCellReuseIdentifier: LSPopoverCell.reuseIdentifier
        )
    }

    private func updateBackground() {
        switch backgroundStyle {
        case .dimmed:
            backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            backgroundView.alpha = 1
        case .blurred:
            backgroundView.backgroundColor = .clear
            let blurEffect = UIBlurEffect(style: .light)
            let blurView = UIVisualEffectView(effect: blurEffect)
            backgroundView.addSubview(blurView)
            blurView.frame = backgroundView.bounds
        case .none:
            backgroundView.alpha = 0
        }
    }

    // MARK: - 显示

    /// 显示弹出视图
    ///
    /// - Parameters:
    ///   - items: 弹出项
    ///   - from: 目标视图
    ///   - in: 容器视图
    public func show(
        items: [LSPopoverItem],
        from view: UIView,
        in containerView: UIView
    ) {
        self.items = items
        self.targetView = view
        self.targetRect = view.superview?.convert(view.frame, to: nil)

        // 添加背景
        containerView.addSubview(backgroundView)
        backgroundView.frame = containerView.bounds
        backgroundView.alpha = 0

        // 添加内容
        containerView.addSubview(self)
        addSubview(contentView)

        // 添加手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        backgroundView.addGestureRecognizer(tapGesture)

        // 动画显示
        contentView.alpha = 0
        contentView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.backgroundView.alpha = 1
            self.contentView.alpha = 1
            self.contentView.transform = .identity
        }

        updateItems()
        layoutContent()
    }

    /// 显示弹出视图（从矩形区域）
    ///
    /// - Parameters:
    ///   - items: 弹出项
    ///   - rect: 目标区域
    ///   - in: 容器视图
    public func show(
        items: [LSPopoverItem],
        from rect: CGRect,
        in containerView: UIView
    ) {
        self.items = items
        self.targetRect = rect
        self.targetView = nil

        // 添加背景
        containerView.addSubview(backgroundView)
        backgroundView.frame = containerView.bounds
        backgroundView.alpha = 0

        // 添加内容
        containerView.addSubview(self)
        addSubview(contentView)

        // 添加手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        backgroundView.addGestureRecognizer(tapGesture)

        // 动画显示
        contentView.alpha = 0
        contentView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.backgroundView.alpha = 1
            self.contentView.alpha = 1
            self.contentView.transform = .identity
        }

        updateItems()
        layoutContent()
    }

    /// 隐藏弹出视图
    ///
    /// - Parameter animated: 是否动画
    public func dismiss(animated: Bool = true) {
        let dismissBlock = {
            self.removeFromSuperview()
            self.backgroundView.removeFromSuperview()
            self.onCancel?()
        }

        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                self.contentView.alpha = 0
                self.contentView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                self.backgroundView.alpha = 0
            }, completion: { _ in
                dismissBlock()
            })
        } else {
            dismissBlock()
        }
    }

    // MARK: - 布局

    private func layoutContent() {
        guard let container = superview,
              let targetRect = targetRect else { return }

        // 计算内容大小
        let itemHeight: CGFloat = 44
        let contentHeight = CGFloat(items.count) * itemHeight
        let maxContentWidth: CGFloat = 200
        var contentWidth = maxContentWidth

        // 根据文本计算宽度
        for item in items {
            let textWidth = item.title.size(withAttributes: [
                .font: UIFont.systemFont(ofSize: 16)
            ]).width + 40 // 图标 + 边距

            if item.image != nil {
                contentWidth = max(contentWidth, textWidth + 30)
            } else {
                contentWidth = max(contentWidth, textWidth)
            }
        }

        contentWidth = min(contentWidth, maxContentWidth)

        // 计算位置
        var contentFrame: CGRect
        var arrowFrame: CGRect

        // 计算箭头方向
        let calculatedDirection: ArrowDirection
        if arrowDirection == .auto {
            // 自动判断
            let spaceAbove = targetRect.minY
            let spaceBelow = container.bounds.height - targetRect.maxY

            if spaceAbove >= contentHeight + 10 {
                calculatedDirection = .up
            } else if spaceBelow >= contentHeight + 10 {
                calculatedDirection = .down
            } else {
                calculatedDirection = spaceAbove > spaceBelow ? .up : .down
            }
        } else {
            calculatedDirection = arrowDirection
        }

        let arrowSize: CGFloat = 12

        switch calculatedDirection {
        case .up:
            contentFrame = CGRect(
                x: targetRect.midX - contentWidth / 2,
                y: targetRect.minY - contentHeight - arrowSize,
                width: contentWidth,
                height: contentHeight
            )
            arrowFrame = CGRect(
                x: targetRect.midX - arrowSize / 2,
                y: targetRect.minY - arrowSize,
                width: arrowSize,
                height: arrowSize
            )

        case .down:
            contentFrame = CGRect(
                x: targetRect.midX - contentWidth / 2,
                y: targetRect.maxY + arrowSize,
                width: contentWidth,
                height: contentHeight
            )
            arrowFrame = CGRect(
                x: targetRect.midX - arrowSize / 2,
                y: targetRect.maxY,
                width: arrowSize,
                height: arrowSize
            )

        case .left:
            contentFrame = CGRect(
                x: targetRect.minX - contentWidth - arrowSize,
                y: targetRect.midY - contentHeight / 2,
                width: contentWidth,
                height: contentHeight
            )
            arrowFrame = CGRect(
                x: targetRect.minX - arrowSize,
                y: targetRect.midY - arrowSize / 2,
                width: arrowSize,
                height: arrowSize
            )

        case .right:
            contentFrame = CGRect(
                x: targetRect.maxX + arrowSize,
                y: targetRect.midY - contentHeight / 2,
                width: contentWidth,
                height: contentHeight
            )
            arrowFrame = CGRect(
                x: targetRect.maxX,
                y: targetRect.midY - arrowSize / 2,
                width: arrowSize,
                height: arrowSize
            )

        case .auto:
            contentFrame = .zero
            arrowFrame = .zero
        }

        // 边界检查
        if contentFrame.minX < 10 {
            contentFrame.origin.x = 10
        } else if contentFrame.maxX > container.bounds.width - 10 {
            contentFrame.origin.x = container.bounds.width - contentWidth - 10
        }

        if contentFrame.minY < 10 {
            contentFrame.origin.y = 10
        } else if contentFrame.maxY > container.bounds.height - 10 {
            contentFrame.origin.y = container.bounds.height - contentHeight - 10
        }

        contentView.frame = contentFrame
        arrowView.frame = arrowFrame

        // 更新表格高度
        tableView.isScrollEnabled = contentHeight > container.bounds.height * 0.6
    }

    // MARK: - 更新

    private func updateItems() {
        tableView.reloadData()
    }

    // MARK: - 事件

    @objc private func backgroundTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource

extension LSPopoverView: UITableViewDataSource {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: LSPopoverCell.reuseIdentifier,
            for: indexPath
        ) as! LSPopoverCell
        cell.configure(with: items[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate

extension LSPopoverView: UITableViewDelegate {

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]

        UIView.animate(withDuration: 0.2, animations: {
            self.contentView.alpha = 0
            self.backgroundView.alpha = 0
        }, completion: { _ in
            self.removeFromSuperview()
            self.backgroundView.removeFromSuperview()
            self.onItemSelected?(item)
        })
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}

// MARK: - LSPopoverItem

/// 弹出项
public struct LSPopoverItem {
    /// 标题
    public let title: String

    /// 图标
    public let image: UIImage?

    /// 是否启用
    public let isEnabled: Bool

    /// 用户信息
    public let userInfo: [String: Any]?

    /// 初始化
    public init(
        title: String,
        image: UIImage? = nil,
        isEnabled: Bool = true,
        userInfo: [String: Any]? = nil
    ) {
        self.title = title
        self.image = image
        self.isEnabled = isEnabled
        self.userInfo = userInfo
    }
}

// MARK: - LSPopoverCell

/// 弹出表格 Cell
private class LSPopoverCell: UITableViewCell {

    static let reuseIdentifier = "LSPopoverCell"

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .label
        return iv
    }()

    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 16)
        return lbl
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)

        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func configure(with item: LSPopoverItem) {
        titleLabel.text = item.title
        iconImageView.image = item.image
        iconImageView.isHidden = item.image == nil
        contentView.alpha = item.isEnabled ? 1 : 0.5
       .isUserInteractionEnabled = item.isEnabled
    }
}

// MARK: - UIViewController Extension

public extension UIViewController {

    /// 显示弹出菜单
    ///
    /// - Parameters:
    ///   - items: 菜单项
    ///   - from: 来源视图
    ///   - completion: 选中回调
    func ls_showPopover(
        items: [LSPopoverItem],
        from view: UIView,
        completion: LSPopoverView.SelectionHandler? = nil
    ) {
        let popover = LSPopoverView()
        popover.onItemSelected = completion
        let _tempVar0
        if let t = view.window {
            _tempVar0 = t
        } else {
            _tempVar0 = view
        }
        popover.show(items: items, from: view, in: _tempVar0)
    }
}

#endif

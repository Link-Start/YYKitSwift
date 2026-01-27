//
//  LSTextContainer.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  文本容器 - 定义文本布局区域
//

#if canImport(UIKit)
import UIKit
import CoreText

// MARK: - 常量

/// 最大文本容器尺寸
public let LSTextContainerMaxSize = CGSize(width: 100000, height: 100000)

// MARK: - LSTextLinePositionModifier Protocol

/// 文本行位置修饰器协议
///
/// 在布局完成前应用，提供修改行位置的机会
public protocol LSTextLinePositionModifier: NSObjectProtocol, NSCopying {
    /// 修改文本行的位置
    ///
    /// - Parameters:
    ///   - lines: 文本行数组
    ///   - text: 完整文本
    ///   - container: 布局容器
    /// - Note: 此方法应该是线程安全的
    func modifyLines(_ lines: [LSTextLine], fromText text: NSAttributedString, inContainer container: LSTextContainer)
}

// MARK: - LSTextLinePositionSimpleModifier

/// 简单的行位置修饰器实现
///
/// 将每行的位置固定为指定值，使每行具有相同的高度
public class LSTextLinePositionSimpleModifier: NSObject, LSTextLinePositionModifier {

    /// 固定行高（两条基线之间的距离）
    public var fixedLineHeight: CGFloat = 0

    // MARK: - 初始化

    public override init() {
        super.init()
    }

    public init(fixedLineHeight: CGFloat) {
        self.fixedLineHeight = fixedLineHeight
        super.init()
    }

    // MARK: - LSTextLinePositionModifier

    public func modifyLines(_ lines: [LSTextLine], fromText text: NSAttributedString, inContainer container: LSTextContainer) {
        guard fixedLineHeight > 0 else { return }

        let isVertical = container.isVerticalForm

        for (index, line) in lines.enumerated() {
            if isVertical {
                line.position = CGPoint(x: line.position.x, y: CGFloat(index) * fixedLineHeight)
            } else {
                line.position = CGPoint(x: line.position.x, y: CGFloat(index) * fixedLineHeight)
            }
        }
    }

    // MARK: - NSCopying

    public func copy(with zone: NSZone? = nil) -> Any {
        let modifier = LSTextLinePositionSimpleModifier(fixedLineHeight: fixedLineHeight)
        return modifier
    }
}

// MARK: - LSTextContainer

/// LSTextContainer 定义文本布局的区域
///
/// LSTextLayout 类使用一个或多个 LSTextContainer 对象来生成布局。
///
/// 容器可以定义矩形区域（`size` 和 `insets`）或非矩形形状（`path`），
/// 并且可以定义排除路径使文本环绕排除路径布局。
///
/// 示例：
/// ```
///     ┌─────────────────────────────┐  <------- container
///     │                             │
///     │    asdfasdfasdfasdfasdfa   <------------ container insets
///     │    asdfasdfa   asdfasdfa    │
///     │    asdfas         asdasd    │
///     │    asdfa        <----------------------- container exclusion path
///     │    asdfas         adfasd    │
///     │    asdfasdfa   asdfasdfa    │
///     │    asdfasdfasdfasdfasdfa    │
///     │                             │
///     └─────────────────────────────┘
/// ```
public class LSTextContainer: NSObject, NSCoding, NSCopying {

    // MARK: - 属性

    /// 约束尺寸（如果尺寸大于 LSTextContainerMaxSize，将被裁剪）
    public var size: CGSize = .zero {
        didSet { _updatePathIfNecessary() }
    }

    /// 约束尺寸的内边距（内边距值不应为负数）
    public var insets: UIEdgeInsets = .zero {
        didSet { _updatePathIfNecessary() }
    }

    /// 自定义约束路径（设置此属性将忽略 `size` 和 `insets`）
    public var path: UIBezierPath? {
        didSet { _updatePathIfNecessary() }
    }

    /// 路径排除数组（用于文本环绕效果）
    public var exclusionPaths: [UIBezierPath]?

    /// 路径线宽
    public var pathLineWidth: CGFloat = 0

    /// 路径填充规则
    /// - true: 文本填充在路径区域内（使用 EOFill 规则）
    /// - false: 文本填充在路径区域内（使用 Fill 规则）
    public var pathFillEvenOdd: Bool = true

    /// 是否为垂直排版（用于 CJK 文本布局）
    public var isVerticalForm: Bool = false

    /// 最大行数（0 表示无限制）
    public var maximumNumberOfRows: UInt = 0

    /// 截断类型
    public var truncationType: LSTextTruncationType = .none

    /// 截断标记（nil 时使用 "…" 代替）
    public var truncationToken: NSAttributedString?

    /// 行位置修饰器（在布局完成前应用）
    public var linePositionModifier: LSTextLinePositionModifier?

    // MARK: - 私有属性

    private var _cgPath: CGPath?
    private var _exclusionCGPaths: [CGPath]?
    private var _isPathDirty: Bool = true

    // MARK: - 初始化

    /// 使用指定尺寸创建容器
    ///
    /// - Parameter size: 容器尺寸
    /// - Returns: 新的文本容器
    public static func container(withSize size: CGSize) -> LSTextContainer {
        let container = LSTextContainer()
        container.size = size
        return container
    }

    /// 使用指定尺寸和内边距创建容器
    ///
    /// - Parameters:
    ///   - size: 容器尺寸
    ///   - insets: 文本内边距
    /// - Returns: 新的文本容器
    public static func container(withSize size: CGSize, insets: UIEdgeInsets) -> LSTextContainer {
        let container = LSTextContainer()
        container.size = size
        container.insets = insets
        return container
    }

    /// 使用指定路径创建容器
    ///
    /// - Parameter path: 容器路径
    /// - Returns: 新的文本容器
    public static func container(withPath path: UIBezierPath?) -> LSTextContainer {
        let container = LSTextContainer()
        container.path = path
        return container
    }

    public override init() {
        super.init()
    }

    // MARK: - NSCoding

    required public init?(coder: NSCoder) {
        size = coder.decodeCGSize(forKey: "size")
        insets = coder.decodeUIEdgeInsets(forKey: "insets")
        if let pathData = coder.decodeObject(forKey: "path") as? Data {
            path = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIBezierPath.self, from: pathData)
        }
        if let exclusionPathsData = coder.decodeObject(forKey: "exclusionPaths") as? [Data] {
            exclusionPaths = exclusionPathsData.compactMap {
                try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIBezierPath.self, from: $0)
            }
        }
        pathLineWidth = coder.decodeCGFloat(forKey: "pathLineWidth")
        pathFillEvenOdd = coder.decodeBool(forKey: "pathFillEvenOdd")
        isVerticalForm = coder.decodeBool(forKey: "isVerticalForm")
        maximumNumberOfRows = coder.decodeInteger(forKey: "maximumNumberOfRows").asUInt()
        truncationType = LSTextTruncationType(rawValue: coder.decodeInteger(forKey: "truncationType")) ?? .none
        if let tokenData = coder.decodeObject(forKey: "truncationToken") as? Data {
            truncationToken = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: tokenData)
        }
        linePositionModifier = coder.decodeObject(forKey: "linePositionModifier") as? LSTextLinePositionModifier
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(size, forKey: "size")
        coder.encode(insets, forKey: "insets")
        if let path = path {
            if let pathData = try? NSKeyedArchiver.archivedData(withRootObject: path, requiringSecureCoding: false) {
                coder.encode(pathData, forKey: "path")
            }
        }
        if let exclusionPaths = exclusionPaths {
            let pathsData = exclusionPaths.compactMap {
                try? NSKeyedArchiver.archivedData(withRootObject: $0, requiringSecureCoding: false)
            }
            coder.encode(pathsData, forKey: "exclusionPaths")
        }
        coder.encodeCGFloat(pathLineWidth, forKey: "pathLineWidth")
        coder.encode(pathFillEvenOdd, forKey: "pathFillEvenOdd")
        coder.encode(isVerticalForm, forKey: "isVerticalForm")
        coder.encodeInteger(maximumNumberOfRows.asInt(), forKey: "maximumNumberOfRows")
        coder.encodeInteger(truncationType.rawValue, forKey: "truncationType")
        if let token = truncationToken {
            if let tokenData = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: false) {
                coder.encode(tokenData, forKey: "truncationToken")
            }
        }
        if let modifier = linePositionModifier {
            coder.encode(modifier, forKey: "linePositionModifier")
        }
    }

    // MARK: - NSCopying

    public func copy(with zone: NSZone? = nil) -> Any {
        let container = LSTextContainer()
        container.size = size
        container.insets = insets
        container.path = path?.copy() as? UIBezierPath
        container.exclusionPaths = exclusionPaths?.map { $0.copy() as! UIBezierPath }
        container.pathLineWidth = pathLineWidth
        container.pathFillEvenOdd = pathFillEvenOdd
        container.isVerticalForm = isVerticalForm
        container.maximumNumberOfRows = maximumNumberOfRows
        container.truncationType = truncationType
        container.truncationToken = truncationToken?.copy() as? NSAttributedString
        container.linePositionModifier = linePositionModifier?.copy(with: nil) as? LSTextLinePositionModifier
        return container
    }

    // MARK: - 公共方法

    /// 获取 CoreGraphics 路径
    public var cgPath: CGPath? {
        if _isPathDirty {
            _updatePathIfNecessary()
        }
        return _cgPath
    }

    /// 获取排除路径数组（CoreGraphics）
    public var exclusionCGPaths: [CGPath]? {
        if _isPathDirty {
            _updatePathIfNecessary()
        }
        return _exclusionCGPaths
    }

    // MARK: - 私有方法

    private func _updatePathIfNecessary() {
        _isPathDirty = false

        if let customPath = path {
            // 使用自定义路径
            _cgPath = customPath.cgPath
        } else {
            // 从 size 和 insets 创建矩形路径
            let rect = CGRect(
                x: insets.left,
                y: insets.top,
                width: max(0, size.width - insets.left - insets.right),
                height: max(0, size.height - insets.top - insets.bottom)
            )

            if pathLineWidth > 0 {
                let lineWidth = pathLineWidth
                let path = CGMutablePath()
                path.addRect(rect)
                _cgPath = path.copy(strokingWithWidth: lineWidth, lineCap: .butt, lineJoin: .miter, miterLimit: 0)
            } else {
                _cgPath = CGPath(rect: rect, transform: nil)
            }
        }

        // 更新排除路径
        if let exclusionPaths = exclusionPaths, !exclusionPaths.isEmpty {
            _exclusionCGPaths = exclusionPaths.map { $0.cgPath }
        } else {
            _exclusionCGPaths = nil
        }
    }
}

// MARK: - NSCoder Extensions

private extension NSCoder {
    func decodeUIEdgeInsets(forKey key: String) -> UIEdgeInsets {
        let top = decodeCGFloat(forKey: "\(key}.top")
        let left = decodeCGFloat(forKey: "\(key}.left")
        let bottom = decodeCGFloat(forKey: "\(key}.bottom")
        let right = decodeCGFloat(forKey: "\(key}.right")
        return UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
    }

    func encode(_ insets: UIEdgeInsets, forKey key: String) {
        encodeCGFloat(insets.top, forKey: "\(key}.top")
        encodeCGFloat(insets.left, forKey: "\(key}.left")
        encodeCGFloat(insets.bottom, forKey: "\(key}.bottom")
        encodeCGFloat(insets.right, forKey: "\(key}.right")
    }

    func decodeCGFloat(forKey key: String) -> CGFloat {
        let value = decodeDouble(forKey: key)
        return CGFloat(value)
    }

    func encodeCGFloat(_ value: CGFloat, forKey key: String) {
        encode(Double(value), forKey: key)
    }
}

// MARK: - Integer Extensions

private extension UInt {
    func asInt() -> Int {
        return Int(min(self, Int.max.asUInt()))
    }
}

private extension Int {
    func asUInt() -> UInt {
        return UInt(max(0, self))
    }
}

#endif

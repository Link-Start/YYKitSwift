//
//  UIImageView+YYKitSwift.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  UIImageView 图片加载扩展
//

#if canImport(UIKit)
import UIKit
import ObjectiveC

// MARK: - 关联对象键

private var kCurrentImageURLKey: UInt8 = 0
private var kCurrentImageOperationKey: UInt8 = 0

// MARK: - UIImageView 扩展

@MainActor
public extension YYKitSwift where Base: UIImageView {

    // MARK: - 属性

    /// 当前图像 URL
    var currentImageURL: URL? {
        get {
            return objc_getAssociatedObject(base, &kCurrentImageURLKey) as? URL
        }
        set {
            objc_setAssociatedObject(base, &kCurrentImageURLKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// 当前图像操作
    private var currentImageOperation: LSWebImageOperation? {
        get {
            return objc_getAssociatedObject(base, &kCurrentImageOperationKey) as? LSWebImageOperation
        }
        set {
            objc_setAssociatedObject(base, &kCurrentImageOperationKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // MARK: - 设置图像

    /// 设置指定 URL 的图像
    ///
    /// - Parameter url: 图像 URL
    func ls_setImage(with url: URL?) {
        ls_setImage(with: url, placeholder: nil)
    }

    /// 设置指定 URL 的图像
    ///
    /// - Parameters:
    ///   - url: 图像 URL
    ///   - placeholder: 占位图像
    func ls_setImage(with url: URL?, placeholder: UIImage?) {
        ls_setImage(with: url, placeholder: placeholder, options: [])
    }

    /// 设置指定 URL 的图像
    ///
    /// - Parameters:
    ///   - url: 图像 URL
    ///   - placeholder: 占位图像
    ///   - options: 选项
    func ls_setImage(with url: URL?, placeholder: UIImage?, options: LSWebImageOptions) {
        ls_setImage(with: url, placeholder: placeholder, options: options, progress: nil, transform: nil, completion: nil)
    }

    /// 设置指定 URL 的图像
    ///
    /// - Parameters:
    ///   - url: 图像 URL
    ///   - placeholder: 占位图像
    ///   - options: 选项
    ///   - progress: 进度回调
    ///   - transform: 转换回调
    ///   - completion: 完成回调
    func ls_setImage(
        with url: URL?,
        placeholder: UIImage?,
        options: LSWebImageOptions = [],
        progress: LSWebImageProgressBlock? = nil,
        transform: LSWebImageTransformBlock? = nil,
        completion: LSWebImageCompletionBlock? = nil
    ) {
        // 取消当前操作
        ls_cancelCurrentImageRequest()

        // 设置占位图像
        if !options.contains(.ignorePlaceHolder) {
            base.image = placeholder
        }

        // 保存 URL
        currentImageURL = url

        guard let url = url else {
            completion?(nil, URL(fileURLWithPath: ""), .none, .finished, nil)
            return
        }

        // 请求图像
        let operation = LSWebImageManager.sharedManager.requestImage(
            with: url,
            options: options,
            progress: progress,
            transform: transform
        ) { [weak self] image, url, from, stage, error in
            guard let self = self else { return }

            // 检查是否被取消
            if url != self.currentImageURL {
                return
            }

            if let error = error {
                completion?(nil, url, from, stage, error)
                return
            }

            // 设置图像
            if !options.contains(.avoidSetImage) {
                // 淡入动画
                if options.contains(.setImageWithFadeAnimation) && from != .memoryCacheFast {
                    UIView.transition(with: self.base, duration: 0.3, options: .transitionCrossDissolve) {
                        self.base.image = image
                    }
                } else {
                    self.base.image = image
                }
            }

            completion?(image, url, from, stage, nil)
        }

        currentImageOperation = operation
    }

    /// 取消当前图像请求
    func ls_cancelCurrentImageRequest() {
        currentImageOperation?.cancel()
        currentImageOperation = nil
        currentImageURL = nil
    }
}

// MARK: - UIView 扩展 (支持不同视图类型)

public extension YYKitSwift where Base: UIButton {

    // MARK: - 关联对象键

    private enum AssociatedKeys {
        static var stateOperationsKey: UInt8 = 0
    }// MARK: - 私有辅助属性

    /// 获取指定状态的操作
    private var stateOperations: [UInt: LSWebImageOperation] {
        get {
            if let dict = objc_getAssociatedObject(base, &AssociatedKeys.stateOperationsKey) as? [UInt: LSWebImageOperation] {
                return dict
            }
            return [:]
        }
        set {
            objc_setAssociatedObject(base, &AssociatedKeys.stateOperationsKey, newValue as AnyObject?, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // MARK: - 设置图像

    /// 为指定状态设置指定 URL 的图像
    ///
    /// - Parameters:
    ///   - url: 图像 URL
    ///   - state: 控制状态
    ///   - placeholder: 占位图像
    func ls_setImage(with url: URL?, for state: UIControl.State, placeholder: UIImage? = nil) {
        ls_setImage(with: url, for: state, placeholder: placeholder, options: [])
    }

    /// 为指定状态设置指定 URL 的图像
    ///
    /// - Parameters:
    ///   - url: 图像 URL
    ///   - state: 控制状态
    ///   - placeholder: 占位图像
    ///   - options: 选项
    func ls_setImage(with url: URL?, for state: UIControl.State, placeholder: UIImage?, options: LSWebImageOptions) {
        // 取消该状态之前的操作
        ls_cancelImageLoad(for: state)

        guard let url = url else {
            base.setImage(placeholder, for: state)
            return
        }

        // 设置占位图像
        if !options.contains(.ignorePlaceHolder) {
            base.setImage(placeholder, for: state)
        }

        // 请求图像
        let operation = LSWebImageManager.sharedManager.requestImage(with: url, options: options) { [weak base] image, _, _, _, error in
            guard let base = base else { return }

            if let image = image, error == nil {
                base.setImage(image, for: state)
            }
        }

        // 保存操作
        var operations = stateOperations
        operations[state.rawValue] = operation
        stateOperations = operations
    }

    /// 为指定状态设置指定 URL 的背景图像
    ///
    /// - Parameters:
    ///   - url: 图像 URL
    ///   - state: 控制状态
    ///   - placeholder: 占位图像
    func ls_setBackgroundImage(with url: URL?, for state: UIControl.State, placeholder: UIImage? = nil) {
        ls_setBackgroundImage(with: url, for: state, placeholder: placeholder, options: [])
    }

    /// 为指定状态设置指定 URL 的背景图像
    ///
    /// - Parameters:
    ///   - url: 图像 URL
    ///   - state: 控制状态
    ///   - placeholder: 占位图像
    ///   - options: 选项
    func ls_setBackgroundImage(with url: URL?, for state: UIControl.State, placeholder: UIImage?, options: LSWebImageOptions) {
        // 取消该状态之前的操作
        ls_cancelImageLoad(for: state)

        guard let url = url else {
            base.setBackgroundImage(placeholder, for: state)
            return
        }

        // 设置占位图像
        if !options.contains(.ignorePlaceHolder) {
            base.setBackgroundImage(placeholder, for: state)
        }

        // 请求图像
        let operation = LSWebImageManager.sharedManager.requestImage(with: url, options: options) { [weak base] image, _, _, _, error in
            guard let base = base else { return }

            if let image = image, error == nil {
                base.setBackgroundImage(image, for: state)
            }
        }

        // 保存操作
        var operations = stateOperations
        operations[state.rawValue] = operation
        stateOperations = operations
    }

    /// 取消指定状态的图像加载
    ///
    /// - Parameter state: 控制状态
    func ls_cancelImageLoad(for state: UIControl.State) {
        var operations = stateOperations

        if let operation = operations[state.rawValue] {
            operation.cancel()
            operations.removeValue(forKey: state.rawValue)
            stateOperations = operations
        }
    }

    /// 取消所有状态的图像加载
    func ls_cancelAllImageLoads() {
        var operations = stateOperations

        for (_, operation) in operations {
            operation.cancel()
        }

        stateOperations = [:]
    }
}

// MARK: - CALayer 扩展

public extension YYKitSwift where Base: CALayer {

    // MARK: - 关联对象键

    private enum AssociatedKeys {
        static var currentImageURLKey: UInt8 = 0
    }private enum AssociatedKeys {
    static var currentImageOperationKey: UInt8 = 0
}// MARK: - 属性

    /// 当前图像 URL
    var ls_currentImageURL: URL? {
        get {
            return objc_getAssociatedObject(base, &AssociatedKeys.currentImageURLKey) as? URL
        }
        set {
            objc_setAssociatedObject(base, &AssociatedKeys.currentImageURLKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// 当前图像操作
    private var ls_currentImageOperation: LSWebImageOperation? {
        get {
            return objc_getAssociatedObject(base, &AssociatedKeys.currentImageOperationKey) as? LSWebImageOperation
        }
        set {
            objc_setAssociatedObject(base, &AssociatedKeys.currentImageOperationKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // MARK: - 设置图像

    /// 设置指定 URL 的图像
    ///
    /// - Parameter url: 图像 URL
    func ls_setImage(with url: URL?) {
        ls_setImage(with: url, placeholder: nil)
    }

    /// 设置指定 URL 的图像
    ///
    /// - Parameters:
    ///   - url: 图像 URL
    ///   - placeholder: 占位图像
    func ls_setImage(with url: URL?, placeholder: UIImage?) {
        ls_setImage(with: url, placeholder: placeholder, options: [])
    }

    /// 设置指定 URL 的图像
    ///
    /// - Parameters:
    ///   - url: 图像 URL
    ///   - placeholder: 占位图像
    ///   - options: 选项
    func ls_setImage(with url: URL?, placeholder: UIImage?, options: LSWebImageOptions) {
        // 取消当前操作
        ls_cancelCurrentImageRequest()

        // 设置占位图像
        if !options.contains(.ignorePlaceHolder), let placeholder = placeholder {
            base.contents = placeholder.cgImage
        }

        // 保存 URL
        ls_currentImageURL = url

        guard let url = url else { return }

        // 请求图像
        let operation = LSWebImageManager.sharedManager.requestImage(with: url, options: options) { [weak base] image, _, from, stage, error in
            guard let base = base else { return }

            if let image = image, error == nil {
                // 淡入动画
                if options.contains(.setImageWithFadeAnimation) && from != .memoryCacheFast {
                    CATransaction.begin()
                    CATransaction.setAnimationDuration(0.3)
                    base.contents = image.cgImage
                    CATransaction.commit()
                } else {
                    base.contents = image.cgImage
                }
            }
        }

        ls_currentImageOperation = operation
    }

    /// 取消当前图像请求
    func ls_cancelCurrentImageRequest() {
        ls_currentImageOperation?.cancel()
        ls_currentImageOperation = nil
        ls_currentImageURL = nil
    }
}

// MARK: - MKAnnotationView 扩展

#if canImport(MapKit)
import MapKit

public extension YYKitSwift where Base: MKAnnotationView {

    // MARK: - 关联对象键

    private enum AssociatedKeys {
        static var currentImageURLKey: UInt8 = 0
    }private enum AssociatedKeys {
    static var currentImageOperationKey: UInt8 = 0
}// MARK: - 属性

    /// 当前图像 URL
    var ls_currentImageURL: URL? {
        get {
            return objc_getAssociatedObject(base, &AssociatedKeys.currentImageURLKey) as? URL
        }
        set {
            objc_setAssociatedObject(base, &AssociatedKeys.currentImageURLKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// 当前图像操作
    private var ls_currentImageOperation: LSWebImageOperation? {
        get {
            return objc_getAssociatedObject(base, &AssociatedKeys.currentImageOperationKey) as? LSWebImageOperation
        }
        set {
            objc_setAssociatedObject(base, &AssociatedKeys.currentImageOperationKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // MARK: - 设置图像

    /// 设置指定 URL 的图像
    ///
    /// - Parameter url: 图像 URL
    func ls_setImage(with url: URL?) {
        ls_setImage(with: url, placeholder: nil)
    }

    /// 设置指定 URL 的图像
    ///
    /// - Parameters:
    ///   - url: 图像 URL
    ///   - placeholder: 占位图像
    func ls_setImage(with url: URL?, placeholder: UIImage?) {
        ls_setImage(with: url, placeholder: placeholder, options: [])
    }

    /// 设置指定 URL 的图像
    ///
    /// - Parameters:
    ///   - url: 图像 URL
    ///   - placeholder: 占位图像
    ///   - options: 选项
    func ls_setImage(with url: URL?, placeholder: UIImage?, options: LSWebImageOptions) {
        // 取消当前操作
        ls_cancelCurrentImageRequest()

        // 设置占位图像
        if !options.contains(.ignorePlaceHolder) {
            base.image = placeholder
        }

        // 保存 URL
        ls_currentImageURL = url

        guard let url = url else { return }

        // 请求图像
        let operation = LSWebImageManager.sharedManager.requestImage(with: url, options: options) { [weak base] image, _, from, stage, error in
            guard let base = base else { return }

            if let image = image, error == nil {
                // 淡入动画
                if options.contains(.setImageWithFadeAnimation) && from != .memoryCacheFast {
                    UIView.transition(with: base, duration: 0.3, options: .transitionCrossDissolve) {
                        base.image = image
                    }
                } else {
                    base.image = image
                }
            }
        }

        ls_currentImageOperation = operation
    }

    /// 取消当前图像请求
    func ls_cancelCurrentImageRequest() {
        ls_currentImageOperation?.cancel()
        ls_currentImageOperation = nil
        ls_currentImageURL = nil
    }
}
#endif
#endif

//
//  LSImagePicker.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  图片选择工具 - 简化图片选择流程
//

#if canImport(UIKit)
import UIKit
import Photos

// MARK: - LSImagePicker

/// 图片选择工具
@MainActor
public class LSImagePicker: NSObject {

    // MARK: - 类型定义

    /// 图片选择完成回调
    public typealias PickerCompletion = (UIImage?) -> Void

    /// 多图片选择完成回调
    public typealias MultiplePickerCompletion = ([UIImage]?) -> Void

    // MARK: - 属性

    /// 当前视图控制器
    private weak var presentingViewController: UIViewController?

    /// 完成回调
    private var completion: PickerCompletion?

    /// 多图片完成回调
    private var multipleCompletion: MultiplePickerCompletion?

    /// 最大选择数量
    public var maximumSelection: Int = 1

    /// 是否允许编辑
    public var allowsEditing: Bool = false

    /// 照片源类型
    public var sourceType: UIImagePickerController.SourceType = .photoLibrary

    // MARK: - 单例

    /// 默认实例
    public static let shared = LSImagePicker()

    // MARK: - 初始化

    /// 创建图片选择器
    ///
    /// - Parameters:
    ///   - viewController: 展示的视图控制器
    ///   - sourceType: 照片源类型
    ///   - allowsEditing: 是否允许编辑
    public init(
        viewController: UIViewController? = nil,
        sourceType: UIImagePickerController.SourceType = .photoLibrary,
        allowsEditing: Bool = false
    ) {
        self.presentingViewController = viewController
        self.sourceType = sourceType
        self.allowsEditing = allowsEditing
        super.init()
    }

    // MARK: - 单图片选择

    /// 选择单张图片
    ///
    /// - Parameters:
    ///   - viewController: 展示的视图控制器
    ///   - sourceType: 照片源类型
    ///   - allowsEditing: 是否允许编辑
    ///   - completion: 完成回调
    public static func pickImage(
        from viewController: UIViewController? = nil,
        sourceType: UIImagePickerController.SourceType = .photoLibrary,
        allowsEditing: Bool = false,
        completion: @escaping PickerCompletion
    ) {
        let picker = LSImagePicker(
            viewController: viewController,
            sourceType: sourceType,
            allowsEditing: allowsEditing
        )
        picker.pick(completion: completion)
    }

    /// 从相册选择图片
    ///
    /// - Parameters:
    ///   - viewController: 展示的视图控制器
    ///   - allowsEditing: 是否允许编辑
    ///   - completion: 完成回调
    public static func pickFromPhotoLibrary(
        from viewController: UIViewController? = nil,
        allowsEditing: Bool = false,
        completion: @escaping PickerCompletion
    ) {
        pickImage(from: viewController, sourceType: .photoLibrary, allowsEditing: allowsEditing, completion: completion)
    }

    /// 从相机拍照
    ///
    /// - Parameters:
    ///   - viewController: 展示的视图控制器
    ///   - allowsEditing: 是否允许编辑
    ///   - completion: 完成回调
    public static func pickFromCamera(
        from viewController: UIViewController? = nil,
        allowsEditing: Bool = false,
        completion: @escaping PickerCompletion
    ) {
        pickImage(from: viewController, sourceType: .camera, allowsEditing: allowsEditing, completion: completion)
    }

    /// 选择图片（实例方法）
    ///
    /// - Parameter completion: 完成回调
    public func pick(completion: @escaping PickerCompletion) {
        self.completion = completion
        showPickerController()
    }

    // MARK: - 多图片选择

    /// 选择多张图片（使用 PHPickerViewController，iOS 14+）
    ///
    /// - Parameters:
    ///   - viewController: 展示的视图控制器
    ///   - maximum: 最大选择数量
    ///   - completion: 完成回调
    @available(iOS 14.0, *)
    public static func pickMultipleImages(
        from viewController: UIViewController? = nil,
        maximum: Int = 9,
        completion: @escaping MultiplePickerCompletion
    ) {
        let picker = LSImagePicker(viewController: viewController)
        picker.maximumSelection = maximum
        picker.pickMultiple(completion: completion)
    }

    /// 选择多张图片（实例方法，iOS 14+）
    ///
    /// - Parameter completion: 完成回调
    @available(iOS 14.0, *)
    public func pickMultiple(completion: @escaping MultiplePickerCompletion) {
        self.multipleCompletion = completion
        showMultiPickerController()
    }

    // MARK: - 显示控制器

    private func showPickerController() {
        guard let viewController = getPresentingViewController() else {
            completion?(nil)
            return
        }

        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
            completion?(nil)
            return
        }

        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        picker.allowsEditing = allowsEditing

        // 检查相机权限
        if sourceType == .camera {
            checkCameraPermission { [weak self] granted in
                if granted {
                    viewController.present(picker, animated: true)
                } else {
                    self?.showPermissionAlert(for: "相机", from: viewController)
                    self?.completion?(nil)
                }
            }
        } else {
            // 检查相册权限
            checkPhotoLibraryPermission { [weak self] granted in
                if granted {
                    viewController.present(picker, animated: true)
                } else {
                    self?.showPermissionAlert(for: "相册", from: viewController)
                    self?.completion?(nil)
                }
            }
        }
    }

    @available(iOS 14.0, *)
    private func showMultiPickerController() {
        guard let viewController = getPresentingViewController() else {
            multipleCompletion?(nil)
            return
        }

        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = maximumSelection
        configuration.filter = .images

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self

        // 检查相册权限
        checkPhotoLibraryPermission { [weak self] granted in
            if granted {
                viewController.present(picker, animated: true)
            } else {
                self?.showPermissionAlert(for: "相册", from: viewController)
                self?.multipleCompletion?(nil)
            }
        }
    }

    // MARK: - 权限检查

    private func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        if #available(iOS 14.0, *) {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            switch status {
            case .authorized:
                completion(true)
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    DispatchQueue.main.async {
                        completion(granted)
                    }
                }
            default:
                completion(false)
            }
        } else {
            completion(true) // iOS 14 以下假设已有权限
        }
    }

    private func checkPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        if #available(iOS 14.0, *) {
            let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            switch status {
            case .authorized, .limited:
                completion(true)
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                    DispatchQueue.main.async {
                        completion(status == .authorized || status == .limited)
                    }
                }
            default:
                completion(false)
            }
        } else {
            let status = PHPhotoLibrary.authorizationStatus()
            switch status {
            case .authorized:
                completion(true)
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization { status in
                    DispatchQueue.main.async {
                        completion(status == .authorized)
                    }
                }
            default:
                completion(false)
            }
        }
    }

    private func showPermissionAlert(for resource: String, from viewController: UIViewController) {
        let alert = UIAlertController(
            title: "无法访问\(resource)",
            message: "请在设置中开启\(resource)访问权限",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "去设置", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        viewController.present(alert, animated: true)
    }

    // MARK: - 辅助方法

    private func getPresentingViewController() -> UIViewController? {
        if let viewController = presentingViewController {
            return viewController
        }

        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
              let rootVC = window.rootViewController else {
            return nil
        }

        var topVC = rootVC
        while let presentedVC = topVC.presentedViewController {
            topVC = presentedVC
        }

        return topVC
    }
}

// MARK: - UIImagePickerControllerDelegate

extension LSImagePicker: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }

            var image: UIImage?

            if self.allowsEditing, let editedImage = info[.editedImage] as? UIImage {
                image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                image = originalImage
            }

            self.completion?(image)
            self.completion = nil
        }
    }

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) { [weak self] in
            self?.completion?(nil)
            self?.completion = nil
        }
    }
}

// MARK: - PHPickerViewControllerDelegate (iOS 14+)

@available(iOS 14.0, *)
extension LSImagePicker: PHPickerViewControllerDelegate {

    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }

            guard !results.isEmpty else {
                self.multipleCompletion?(nil)
                self.multipleCompletion = nil
                return
            }

            let group = DispatchGroup()
            var images: [UIImage] = []

            for result in results {
                group.enter()
                result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                    defer { group.leave() }
                    if let image = object as? UIImage {
                        DispatchQueue.main.async {
                            images.append(image)
                        }
                    }
                }
            }

            group.notify(queue: .main) {
                self.multipleCompletion?(images.isEmpty ? nil : images)
                self.multipleCompletion = nil
            }
        }
    }
}

// MARK: - UIImagePickerController Extension (便捷方法)

public extension UIImagePickerController {

    /// 快速创建图片选择器
    ///
    /// - Parameters:
    ///   - sourceType: 照片源类型
    ///   - allowsEditing: 是否允许编辑
    ///   - delegate: 代理
    /// - Returns: UIImagePickerController 实例
    static func ls_picker(
        sourceType: UIImagePickerController.SourceType = .photoLibrary,
        allowsEditing: Bool = false,
        delegate: UIImagePickerControllerDelegate & UINavigationControllerDelegate? = nil
    ) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.allowsEditing = allowsEditing
        picker.delegate = delegate
        return picker
    }

    /// 是否可用指定源类型
    ///
    /// - Parameter sourceType: 源类型
    /// - Returns: 是否可用
    static func ls_isAvailable(sourceType: UIImagePickerController.SourceType) -> Bool {
        return isSourceTypeAvailable(sourceType)
    }
}

// MARK: - 图片压缩工具

public extension LSImagePicker {

    /// 压缩图片到指定大小
    ///
    /// - Parameters:
    ///   - image: 原始图片
    ///   - maxSize: 最大文件大小（字节）
    ///   - maxWidth: 最大宽度
    /// - Returns: 压缩后的图片数据
    static func compress(
        image: UIImage,
        toMaxSize maxSize: Int = 1024 * 1024,
        maxWidth: CGFloat = 1080
    ) -> Data? {
        // 调整尺寸
        let resizedImage = resize(image: image, maxWidth: maxWidth)

        // 压缩质量
        var compression: CGFloat = 1.0
        guard var data = resizedImage.jpegData(compressionQuality: compression) else {
            return resizedImage.jpegData(compressionQuality: 1)
        }

        while data.count > maxSize && compression > 0.1 {
            compression -= 0.1
            guard let compressedData = resizedImage.jpegData(compressionQuality: compression) else {
                break
            }
            data = compressedData
        }

        return data
    }

    /// 调整图片尺寸
    ///
    /// - Parameters:
    ///   - image: 原始图片
    ///   - maxWidth: 最大宽度
    /// - Returns: 调整后的图片
    private static func resize(image: UIImage, maxWidth: CGFloat) -> UIImage {
        let size = image.size

        if size.width <= maxWidth {
            return image
        }

        let ratio = maxWidth / size.width
        let newSize = CGSize(width: maxWidth, height: size.height * ratio)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1)
        defer { UIGraphicsEndImageContext() }

        image.draw(in: CGRect(origin: .zero, size: newSize))
        if let tempValue = UIGraphicsGetImageFromCurrentImageContext() {
            return tempValue
        }
        return image
    }

    /// 获取图片的方向修正后的版本
    ///
    /// - Parameter image: 原始图片
    /// - Returns: 修正后的图片
    static func fixOrientation(image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else {
            return image
        }

        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }

        image.draw(in: CGRect(origin: .zero, size: image.size))
        if let tempValue = UIGraphicsGetImageFromCurrentImageContext() {
            return tempValue
        }
        return image
    }
}

// MARK: - AVCaptureDevice (用于相机权限检查)

import AVFoundation

private extension AVCaptureDevice {
    @available(iOS 14.0, *)
    static func authorizationStatus(for mediaType: AVMediaType) -> AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: mediaType)
    }

    @available(iOS 14.0, *)
    static func requestAccess(for mediaType: AVMediaType, completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: mediaType, completionHandler: completion)
    }
}

#endif

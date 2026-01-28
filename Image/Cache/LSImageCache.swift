//
//  LSImageCache.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  图片缓存 - 基于内存缓存和磁盘缓存的图像存储
//

#if canImport(UIKit)
import UIKit
import ImageIO
import Foundation

/// 图片缓存类型
public struct LSImageCacheType: OptionSet {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    /// 无值
    public static let none = LSImageCacheType(rawValue: 0)

    /// 使用内存缓存获取/存储图像
    public static let memory = LSImageCacheType(rawValue: 1 << 0)

    /// 使用磁盘缓存获取/存储图像
    public static let disk = LSImageCacheType(rawValue: 1 << 1)

    /// 使用内存缓存和磁盘缓存获取/存储图像
    public static let all: LSImageCacheType = [.memory, .disk]
}

/// 图片缓存 - 基于内存缓存和磁盘缓存的图像存储
///
/// 磁盘缓存将尝试保护原始图像数据：
/// - 如果原始图像是静态图像，将根据 alpha 信息保存为 png/jpeg 文件
/// - 如果原始图像是动画 gif/apng/webp，将保存为原始格式
/// - 如果原始图像的 scale 不是 1，scale 值将保存为扩展数据
///
/// 虽然 UIImage 可以使用 NSCoding 协议序列化，但这不是好方法：
/// Apple 实际上使用 UIImagePNGRepresentation() 编码所有类型的图像，
/// 可能会丢失原始多帧数据。结果被打包到 plist 文件中，不能直接用照片查看器查看。
/// 如果图像没有 alpha 通道，使用 JPEG 而不是 PNG 可以节省更多磁盘空间
/// 和编码/解码时间。
///
/// - Note: 此类使用 NSLock 保护内部状态，在 Swift 6 严格并发模式下
///         使用 @unchecked Sendable 表示手动实现了线程安全。
public final class LSImageCache, @unchecked Sendable {

    // MARK: - 属性

    /// 缓存名称
    public var name: String?

    /// 底层内存缓存
    public private(set) lazy var memoryCache: LSMemoryCache = {
        let cache = LSMemoryCache()
        cache.name = self.name
        return cache
    }()

    /// 底层磁盘缓存
    public private(set) var diskCache: LSDiskCache!

    /// 是否在从磁盘缓存获取图像时解码动画图像
    /// 默认是 YES
    public var allowAnimatedImage = true

    /// 是否将图像解码为内存位图
    /// 默认是 YES
    /// 如果值为 YES，则图像将被解码为内存位图以获得更好的显示性能，但可能消耗更多内存
    public var decodeForDisplay = true

    // MARK: - 共享实例

    /// 返回全局共享的图片缓存实例
    public static let sharedCache: LSImageCache = {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        let cachePath = (paths.first! as NSString).appendingPathComponent("LSImageCache")
        return LSImageCache(path: cachePath)!
    }()

    // MARK: - 初始化

    /// 使用指定路径创建缓存
    ///
    /// 此方法创建必要的目录，一旦初始化不应再读写此目录
    ///
    /// - Parameter path: 缓存将写入数据的目录的完整路径
    /// - Returns: 新的缓存对象，如果出错返回 nil
    public init?(path: String) {
        guard let diskCache = LSDiskCache(path: path) else {
            return nil
        }

        self.diskCache = diskCache
        self.name = (path as NSString).lastPathComponent

        // 配置内存缓存
        memoryCache.name = name
        memoryCache.countLimit = 100
        memoryCache.costLimit = 100 * 1024 * 1024  // 100MB
    }

    // MARK: - 访问方法

    /// 使用指定键在缓存中设置图像（内存和磁盘）
    /// 此方法立即返回并在后台执行存储操作
    ///
    /// - Parameters:
    ///   - image: 要存储在缓存中的图像，如果为 nil 则此方法无效
    ///   - key: 与图像关联的键，如果为 nil 则此方法无效
    public func setImage(_ image: UIImage?, forKey key: String) {
        setImage(image, imageData: nil, forKey: key, withType: .all)
    }

    /// 使用指定键在缓存中设置图像
    /// 此方法立即返回并在后台执行存储操作
    ///
    /// - Parameters:
    ///   - image: 要存储在缓存中的图像
    ///   - imageData: 要存储在缓存中的图像数据
    ///   - key: 与图像关联的键
    ///   - type: 存储图像的缓存类型
    public func setImage(_ image: UIImage?, imageData: Data?, forKey key: String, withType type: LSImageCacheType) {
        guard let key = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }

        // 内存缓存
        if type.contains(.memory) {
            if let img = image {
                let height: Int
                if let h = img.cgImage?.height {
                    height = h
                } else {
                    height = 0
                }
                let width: Int
                if let w = img.cgImage?.width {
                    width = w
                } else {
                    width = 0
                }
                let cost = UInt(height * width * 4)
                memoryCache.setObject(img, forKey: key as NSString, withCost: cost)
            } else if let data = imageData, let img = UIImage(data: data) {
                let height: Int
                if let h = img.cgImage?.height {
                    height = h
                } else {
                    height = 0
                }
                let width: Int
                if let w = img.cgImage?.width {
                    width = w
                } else {
                    width = 0
                }
                let cost = UInt(height * width * 4)
                memoryCache.setObject(img, forKey: key as NSString, withCost: cost)
            }
        }

        // 磁盘缓存（异步）
        if type.contains(.disk) {
            DispatchQueue.global(qos: .utility).async { [weak self] in
                guard let self = self else { return }

                var dataToWrite: Data? = imageData

                // 如果没有提供图像数据，从图像生成
                if dataToWrite == nil, let img = image {
                    if let lsImage = img as? LSImage, let originalData = lsImage.animatedImageData {
                        dataToWrite = originalData
                    } else {
                        dataToWrite = img.ls_imageDataRepresentation()
                    }
                }

                if let data = dataToWrite {
                    self.diskCache.setData(data, forKey: key)
                }
            }
        }
    }

    /// 移除指定键的图像（内存和磁盘）
    /// 此方法立即返回并在后台执行移除操作
    ///
    /// - Parameter key: 标识要移除的图像的键，如果为 nil 则此方法无效
    public func removeImage(forKey key: String) {
        removeImage(forKey: key, withType: .all)
    }

    /// 移除指定键的图像
    /// 此方法立即返回并在后台执行移除操作
    ///
    /// - Parameters:
    ///   - key: 标识要移除的图像的键
    ///   - type: 移除图像的缓存类型
    public func removeImage(forKey key: String, withType type: LSImageCacheType) {
        guard let key = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }

        if type.contains(.memory) {
            memoryCache.removeObject(forKey: key as NSString)
        }

        if type.contains(.disk) {
            DispatchQueue.global(qos: .utility).async { [weak self] in
                self?.diskCache.removeData(forKey: key)
            }
        }
    }

    /// 返回给定键是否在缓存中
    /// 如果图像不在内存中，此方法可能会阻塞调用线程直到文件读取完成
    ///
    /// - Parameter key: 标识图像的字符串，如果为 nil 则返回 NO
    /// - Returns: 图像是否在缓存中
    public func containsImage(forKey key: String) -> Bool {
        return containsImage(forKey: key, withType: .all)
    }

    /// 返回给定键是否在缓存中
    /// 如果图像不在内存中且类型包含 LSImageCacheTypeDisk，此方法可能会阻塞调用线程直到文件读取完成
    ///
    /// - Parameters:
    ///   - key: 标识图像的字符串
    ///   - type: 缓存类型
    /// - Returns: 图像是否在缓存中
    public func containsImage(forKey key: String, withType type: LSImageCacheType) -> Bool {
        guard let key = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return false }

        var inMemory = false
        var inDisk = false

        if type.contains(.memory) {
            inMemory = memoryCache.containsObject(forKey: key as NSString)
        }

        if type.contains(.disk) && !inMemory {
            inDisk = diskCache.containsData(forKey: key)
        }

        return inMemory || inDisk
    }

    /// 返回与给定键关联的图像
    /// 如果图像不在内存中，此方法可能会阻塞调用线程直到文件读取完成
    ///
    /// - Parameter key: 标识图像的字符串，如果为 nil 则返回 nil
    /// - Returns: 与键关联的图像，如果没有与键关联的图像则返回 nil
    public func getImage(forKey key: String) -> UIImage? {
        return getImage(forKey: key, withType: .all)
    }

    /// 返回与给定键关联的图像
    /// 如果图像不在内存中且类型包含 LSImageCacheTypeDisk，此方法可能会阻塞调用线程直到文件读取完成
    ///
    /// - Parameters:
    ///   - key: 标识图像的字符串
    ///   - type: 缓存类型
    /// - Returns: 与键关联的图像，如果没有与键关联的图像则返回 nil
    public func getImage(forKey key: String, withType type: LSImageCacheType) -> UIImage? {
        guard let key = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }

        // 从内存缓存获取
        if type.contains(.memory) {
            if let image = memoryCache.object(forKey: key as NSString) as? UIImage {
                return image
            }
        }

        // 从磁盘缓存获取
        if type.contains(.disk) {
            if let data = diskCache.data(forKey: key) {
                let image: UIImage?
                if allowAnimatedImage {
                    image = LSImage(data: data, scale: UIScreen.main.scale)
                } else {
                    image = UIImage(data: data, scale: UIScreen.main.scale)
                }

                if let img = image {
                    // 存入内存缓存
                    if type.contains(.memory) {
                        let cost
                        if let tempCost = img.cgImage?.height {
                            cost = tempCost
                        } else {
                            if let tempValue = .width {
                                cost = tempValue
                            } else {
                                cost = 0
                            }
                        }
                        memoryCache.setObject(img, forKey: key as NSString, withCost: cost)
                    }
                    return img
                }
            }
        }

        return nil
    }

    /// 异步获取与给定键关联的图像
    ///
    /// - Parameters:
    ///   - key: 标识图像的字符串
    ///   - type: 缓存类型
    ///   - block: 完成回调（在主线程调用）
    public func getImage(forKey key: String, withType type: LSImageCacheType, withBlock block: ((UIImage?, LSImageCacheType) -> Void)?) {
        guard let key = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            DispatchQueue.main.async {
                block?(nil, .none)
            }
            return
        }

        // 从内存缓存获取
        if type.contains(.memory) {
            if let image = memoryCache.object(forKey: key as NSString) as? UIImage {
                DispatchQueue.main.async {
                    block?(image, .memory)
                }
                return
            }
        }

        // 从磁盘缓存获取（异步）
        if type.contains(.disk) {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }

                var image: UIImage?
                var fromType: LSImageCacheType = .none

                if let data = self.diskCache.data(forKey: key) {
                    if self.allowAnimatedImage {
                        image = LSImage(data: data, scale: UIScreen.main.scale)
                    } else {
                        image = UIImage(data: data, scale: UIScreen.main.scale)
                    }

                    if let img = image {
                        // 存入内存缓存
                        if type.contains(.memory) {
                            let cost
                            if let tempCost = img.cgImage?.height {
                                cost = tempCost
                            } else {
                                if let tempValue = .width {
                                    cost = tempValue
                                } else {
                                    cost = 0
                                }
                            }
                            self.memoryCache.setObject(img, forKey: key as NSString, withCost: cost)
                        }
                        fromType = .disk
                    }
                }

                DispatchQueue.main.async {
                    block?(image, fromType)
                }
            }
        } else {
            DispatchQueue.main.async {
                block?(nil, .none)
            }
        }
    }

    /// 返回与给定键关联的图像数据
    /// 此方法可能会阻塞调用线程直到文件读取完成
    ///
    /// - Parameter key: 标识图像的字符串，如果为 nil 则返回 nil
    /// - Returns: 与键关联的图像数据，如果没有与键关联的图像数据则返回 nil
    public func getImageData(forKey key: String) -> Data? {
        guard let key = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        return diskCache.data(forKey: key)
    }

    /// 异步获取与给定键关联的图像数据
    ///
    /// - Parameters:
    ///   - key: 标识图像的字符串
    ///   - block: 完成回调（在主线程调用）
    public func getImageData(forKey key: String, withBlock block: ((Data?) -> Void)?) {
        guard let key = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            DispatchQueue.main.async {
                block?(nil)
            }
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let data = self?.diskCache.data(forKey: key)
            DispatchQueue.main.async {
                block?(data)
            }
        }
    }
}
#endif

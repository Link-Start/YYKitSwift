//
//  LSFileHash.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  文件哈希计算工具 - 高性能、低内存占用的文件哈希计算
//

#if canImport(UIKit)
import UIKit
import Foundation
import CommonCrypto
import zlib

// MARK: - LSFileHashType

/// 文件哈希算法类型
public struct LSFileHashType: OptionSet {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    /// MD2 哈希
    public static let md2 = LSFileHashType(rawValue: 1 << 0)

    /// MD4 哈希
    public static let md4 = LSFileHashType(rawValue: 1 << 1)

    /// MD5 哈希
    public static let md5 = LSFileHashType(rawValue: 1 << 2)

    /// SHA1 哈希
    public static let sha1 = LSFileHashType(rawValue: 1 << 3)

    /// SHA224 哈希
    public static let sha224 = LSFileHashType(rawValue: 1 << 4)

    /// SHA256 哈希
    public static let sha256 = LSFileHashType(rawValue: 1 << 5)

    /// SHA384 哈希
    public static let sha384 = LSFileHashType(rawValue: 1 << 6)

    /// SHA512 哈希
    public static let sha512 = LSFileHashType(rawValue: 1 << 7)

    /// CRC32 校验和
    public static let crc32 = LSFileHashType(rawValue: 1 << 8)

    /// Adler32 校验和
    public static let adler32 = LSFileHashType(rawValue: 1 << 9)
}

// MARK: - LSFileHash

/// LSFileHash 用于高性能、低内存占用的文件哈希计算
///
/// 示例代码:
/// ```swift
/// let hash = LSFileHash.hash(forFile: "/tmp/file.dmg", types: [.md5, .sha1])
/// print("md5: \(hash?.md5String ?? "") sha1: \(hash?.sha1String ?? "")")
/// ```
public class LSFileHash: NSObject {

    // MARK: - 属性

    /// 哈希类型
    public private(set) var types: LSFileHashType = []

    // MARK: - MD 哈希

    /// MD2 哈希数据
    public private(set) var md2Data: Data?

    /// MD2 哈希字符串（小写）
    public var md2String: String? {
        guard let data = md2Data else { return nil }
        return data.hexString
    }

    /// MD4 哈希数据
    public private(set) var md4Data: Data?

    /// MD4 哈希字符串（小写）
    public var md4String: String? {
        guard let data = md4Data else { return nil }
        return data.hexString
    }

    /// MD5 哈希数据
    public private(set) var md5Data: Data?

    /// MD5 哈希字符串（小写）
    public var md5String: String? {
        guard let data = md5Data else { return nil }
        return data.hexString
    }

    // MARK: - SHA 哈希

    /// SHA1 哈希数据
    public private(set) var sha1Data: Data?

    /// SHA1 哈希字符串（小写）
    public var sha1String: String? {
        guard let data = sha1Data else { return nil }
        return data.hexString
    }

    /// SHA224 哈希数据
    public private(set) var sha224Data: Data?

    /// SHA224 哈希字符串（小写）
    public var sha224String: String? {
        guard let data = sha224Data else { return nil }
        return data.hexString
    }

    /// SHA256 哈希数据
    public private(set) var sha256Data: Data?

    /// SHA256 哈希字符串（小写）
    public var sha256String: String? {
        guard let data = sha256Data else { return nil }
        return data.hexString
    }

    /// SHA384 哈希数据
    public private(set) var sha384Data: Data?

    /// SHA384 哈希字符串（小写）
    public var sha384String: String? {
        guard let data = sha384Data else { return nil }
        return data.hexString
    }

    /// SHA512 哈希数据
    public private(set) var sha512Data: Data?

    /// SHA512 哈希字符串（小写）
    public var sha512String: String? {
        guard let data = sha512Data else { return nil }
        return data.hexString
    }

    // MARK: - 校验和

    /// CRC32 校验和
    public private(set) var crc32Value: UInt32 = 0

    /// CRC32 校验和字符串（小写）
    public var crc32String: String? {
        return String(format: "%08x", crc32Value)
    }

    /// Adler32 校验和
    public private(set) var adler32Value: UInt32 = 0

    /// Adler32 校验和字符串（小写）
    public var adler32String: String? {
        return String(format: "%08x", adler32Value)
    }

    // MARK: - 公共方法

    /// 开始计算文件哈希并返回结果
    ///
    /// - Discussion: 调用线程被阻塞，直到异步哈希处理完成
    ///
    /// - Parameters:
    ///   - filePath: 要访问的文件路径
    ///   - types: 文件哈希算法类型
    /// - Returns: 文件哈希结果，出错返回 nil
    public static func hash(forFile filePath: String, types: LSFileHashType) -> LSFileHash? {
        return hash(forFile: filePath, types: types, usingBlock: nil)
    }

    /// 开始计算文件哈希并返回结果
    ///
    /// - Discussion: 调用线程被阻塞，直到异步哈希处理完成或取消
    ///
    /// - Parameters:
    ///   - filePath: 要访问的文件路径
    ///   - types: 文件哈希算法类型
    ///   - block: 处理期间调用的块，包含 3 个参数：
    ///     - totalSize: 文件总大小（字节）
    ///     - processedSize: 已处理的文件大小（字节）
    ///     - stop: 布尔值引用，设置为 YES 可停止进一步处理
    /// - Returns: 文件哈希结果，出错返回 nil
    public static func hash(
        forFile filePath: String,
        types: LSFileHashType,
        usingBlock block: ((UInt64, UInt64, UnsafeMutablePointer<Bool>) -> Void)?
    ) -> LSFileHash? {
        guard !filePath.isEmpty else { return nil }
        guard types.rawValue != 0 else { return nil }

        // 常量定义
        #if os(iOS) || os(tvOS) || os(watchOS)
        let bufSize = 1024 * 512 // 512KB per read
        let blockLoopFactor = 16 // 8MB per block callback
        #else
        let bufSize = 1024 * 1024 * 16 // 16MB per read
        let blockLoopFactor = 16 // 64MB per block callback
        #endif

        let adjustedBufSize = block != nil ? bufSize : (bufSize * 2)

        var contexts: [HashContext] = []
        var hasValidType = false

        // 初始化哈希上下文
        if types.contains(.md2) {
            contexts.append(HashContext(type: .md2))
            hasValidType = true
        }
        if types.contains(.md4) {
            contexts.append(HashContext(type: .md4))
            hasValidType = true
        }
        if types.contains(.md5) {
            contexts.append(HashContext(type: .md5))
            hasValidType = true
        }
        if types.contains(.sha1) {
            contexts.append(HashContext(type: .sha1))
            hasValidType = true
        }
        if types.contains(.sha224) {
            contexts.append(HashContext(type: .sha224))
            hasValidType = true
        }
        if types.contains(.sha256) {
            contexts.append(HashContext(type: .sha256))
            hasValidType = true
        }
        if types.contains(.sha384) {
            contexts.append(HashContext(type: .sha384))
            hasValidType = true
        }
        if types.contains(.sha512) {
            contexts.append(HashContext(type: .sha512))
            hasValidType = true
        }
        if types.contains(.crc32) {
            contexts.append(HashContext(type: .crc32))
            hasValidType = true
        }
        if types.contains(.adler32) {
            contexts.append(HashContext(type: .adler32))
            hasValidType = true
        }

        guard hasValidType else { return nil }

        // 打开文件
        guard let file = fopen(filePath, "rb") else { return nil }

        defer { fclose(file) }

        // 获取文件大小
        fseeko(file, 0, SEEK_END)
        let fileSize = ftell(file)
        fseeko(file, 0, SEEK_SET)

        guard fileSize >= 0 else { return nil }

        // 初始化所有哈希上下文
        for context in contexts {
            context.init?()
        }

        // 分配缓冲区
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: adjustedBufSize)
        defer { buffer.deallocate() }

        var readed: Int64 = 0
        var done = false
        var stopped = false
        var loop = 0
        let stopPtr = UnsafeMutablePointer<Bool>.allocate(capacity: 1)
        defer { stopPtr.deallocate() }

        // 读取并计算哈希
        while !done && !stopped {
            let size = fread(buffer, 1, adjustedBufSize, file)

            if size < adjustedBufSize {
                if feof(file) != 0 {
                    done = true
                } else {
                    stopped = true
                    break
                }
            }

            // 更新所有哈希
            for context in contexts {
                context.update?(buffer, CC_LONG(size))
            }

            readed += Int64(size)

            // 调用进度回调
            if !done && block != nil {
                loop += 1
                if loop % blockLoopFactor == 0 {
                    stopPtr.pointee = false
                    block?(UInt64(fileSize), UInt64(readed), stopPtr)
                    if stopPtr.pointee {
                        stopped = true
                    }
                }
            }
        }

        // 收集结果
        var result: LSFileHash?
        if done && !stopped {
            result = LSFileHash()
            result?.types = types

            for context in contexts {
                if let data = context.final() {
                    switch context.type {
                    case .md2:
                        result?.md2Data = data
                    case .md4:
                        result?.md4Data = data
                    case .md5:
                        result?.md5Data = data
                    case .sha1:
                        result?.sha1Data = data
                    case .sha224:
                        result?.sha224Data = data
                    case .sha256:
                        result?.sha256Data = data
                    case .sha384:
                        result?.sha384Data = data
                    case .sha512:
                        result?.sha512Data = data
                    case .crc32:
                        result?.crc32Value = data.withUnsafeBytes { $0.load(as: UInt32.self) }
                    case .adler32:
                        result?.adler32Value = data.withUnsafeBytes { $0.load(as: UInt32.self) }
                    }
                }
            }
        }

        return result
    }

    // MARK: - 初始化

    private override init() {
        super.init()
    }
}

// MARK: - HashContext

private class HashContext {
    enum HashType {
        case md2, md4, md5, sha1, sha224, sha256, sha384, sha512, crc32, adler32
    }

    let type: HashType
    var context: UnsafeMutableRawPointer?
    var digestLength: Int = 0
    var initFn: (() -> Void)?
    var updateFn: ((UnsafePointer<UInt8>, CC_LONG) -> Void)?
    var finalFn: (() -> Data?)?

    init(type: HashType) {
        self.type = type

        switch type {
        case .md2:
            digestLength = Int(CC_MD2_DIGEST_LENGTH)
            let ctx = UnsafeMutablePointer<CC_MD2_CTX>.allocate(capacity: 1)
            context = ctx

            initFn = {
                CC_MD2_Init(ctx)
            }

            updateFn = { data, length in
                CC_MD2_Update(ctx, data, length)
            }

            finalFn = {
                var digest = [UInt8](repeating: 0, count: Int(CC_MD2_DIGEST_LENGTH))
                CC_MD2_Final(&digest, ctx)
                return Data(digest)
            }

        case .md4:
            digestLength = Int(CC_MD4_DIGEST_LENGTH)
            let ctx = UnsafeMutablePointer<CC_MD4_CTX>.allocate(capacity: 1)
            context = ctx

            initFn = {
                CC_MD4_Init(ctx)
            }

            updateFn = { data, length in
                CC_MD4_Update(ctx, data, length)
            }

            finalFn = {
                var digest = [UInt8](repeating: 0, count: Int(CC_MD4_DIGEST_LENGTH))
                CC_MD4_Final(&digest, ctx)
                return Data(digest)
            }

        case .md5:
            digestLength = Int(CC_MD5_DIGEST_LENGTH)
            let ctx = UnsafeMutablePointer<CC_MD5_CTX>.allocate(capacity: 1)
            context = ctx

            initFn = {
                CC_MD5_Init(ctx)
            }

            updateFn = { data, length in
                CC_MD5_Update(ctx, data, length)
            }

            finalFn = {
                var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
                CC_MD5_Final(&digest, ctx)
                return Data(digest)
            }

        case .sha1:
            digestLength = Int(CC_SHA1_DIGEST_LENGTH)
            let ctx = UnsafeMutablePointer<CC_SHA1_CTX>.allocate(capacity: 1)
            context = ctx

            initFn = {
                CC_SHA1_Init(ctx)
            }

            updateFn = { data, length in
                CC_SHA1_Update(ctx, data, length)
            }

            finalFn = {
                var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
                CC_SHA1_Final(&digest, ctx)
                return Data(digest)
            }

        case .sha224:
            digestLength = Int(CC_SHA224_DIGEST_LENGTH)
            let ctx = UnsafeMutablePointer<CC_SHA256_CTX>.allocate(capacity: 1)
            context = ctx

            initFn = {
                CC_SHA224_Init(ctx)
            }

            updateFn = { data, length in
                CC_SHA224_Update(ctx, data, length)
            }

            finalFn = {
                var digest = [UInt8](repeating: 0, count: Int(CC_SHA224_DIGEST_LENGTH))
                CC_SHA224_Final(&digest, ctx)
                return Data(digest)
            }

        case .sha256:
            digestLength = Int(CC_SHA256_DIGEST_LENGTH)
            let ctx = UnsafeMutablePointer<CC_SHA256_CTX>.allocate(capacity: 1)
            context = ctx

            initFn = {
                CC_SHA256_Init(ctx)
            }

            updateFn = { data, length in
                CC_SHA256_Update(ctx, data, length)
            }

            finalFn = {
                var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
                CC_SHA256_Final(&digest, ctx)
                return Data(digest)
            }

        case .sha384:
            digestLength = Int(CC_SHA384_DIGEST_LENGTH)
            let ctx = UnsafeMutablePointer<CC_SHA512_CTX>.allocate(capacity: 1)
            context = ctx

            initFn = {
                CC_SHA384_Init(ctx)
            }

            updateFn = { data, length in
                CC_SHA384_Update(ctx, data, length)
            }

            finalFn = {
                var digest = [UInt8](repeating: 0, count: Int(CC_SHA384_DIGEST_LENGTH))
                CC_SHA384_Final(&digest, ctx)
                return Data(digest)
            }

        case .sha512:
            digestLength = Int(CC_SHA512_DIGEST_LENGTH)
            let ctx = UnsafeMutablePointer<CC_SHA512_CTX>.allocate(capacity: 1)
            context = ctx

            initFn = {
                CC_SHA512_Init(ctx)
            }

            updateFn = { data, length in
                CC_SHA512_Update(ctx, data, length)
            }

            finalFn = {
                var digest = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
                CC_SHA512_Final(&digest, ctx)
                return Data(digest)
            }

        case .crc32:
            digestLength = MemoryLayout<UInt32>.size
            let ctx = UnsafeMutablePointer<UInt32>.allocate(capacity: 1)
            context = ctx

            initFn = {
                ctx.pointee = crc32(0, nil, 0)
            }

            updateFn = { data, length in
                ctx.pointee = crc32(ctx.pointee, data, uInt(length))
            }

            finalFn = {
                return Data(bytes: ctx, count: MemoryLayout<UInt32>.size)
            }

        case .adler32:
            digestLength = MemoryLayout<UInt32>.size
            let ctx = UnsafeMutablePointer<UInt32>.allocate(capacity: 1)
            context = ctx

            initFn = {
                ctx.pointee = adler32(0, nil, 0)
            }

            updateFn = { data, length in
                ctx.pointee = adler32(ctx.pointee, data, uInt(length))
            }

            finalFn = {
                return Data(bytes: ctx, count: MemoryLayout<UInt32>.size)
            }
        }
    }

    var `init`: (() -> Void)? {
        return initFn
    }

    var update: ((UnsafePointer<UInt8>, CC_LONG) -> Void)? {
        return updateFn
    }

    var `final`: (() -> Data?)? {
        return finalFn
    }

    deinit {
        context?.deallocate()
    }
}

// MARK: - Data Extension

private extension Data {
    var hexString: String {
        return map { String(format: "%02x", $0) }.joined()
    }
}
#endif

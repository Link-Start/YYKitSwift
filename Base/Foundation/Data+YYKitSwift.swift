//
//  Data+YYKitSwift.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  Data 扩展，提供 Hash、加密、编码和压缩方法
//

import Foundation
import CommonCrypto
import zlib

// MARK: - Data 扩展

public extension Data {

    // MARK: - Hash (String)

    /// MD5 哈希字符串（小写）
    func ls_md5String() -> String {
        return ls_hashString(CC_MD5, length: CC_MD5_DIGEST_LENGTH)
    }

    /// SHA1 哈希字符串（小写）
    func ls_sha1String() -> String {
        return ls_hashString(CC_SHA1, length: CC_SHA1_DIGEST_LENGTH)
    }

    /// SHA224 哈希字符串（小写）
    func ls_sha224String() -> String {
        return ls_hashString(CC_SHA224, length: CC_SHA224_DIGEST_LENGTH)
    }

    /// SHA256 哈希字符串（小写）
    func ls_sha256String() -> String {
        return ls_hashString(CC_SHA256, length: CC_SHA256_DIGEST_LENGTH)
    }

    /// SHA384 哈希字符串（小写）
    func ls_sha384String() -> String {
        return ls_hashString(CC_SHA384, length: CC_SHA384_DIGEST_LENGTH)
    }

    /// SHA512 哈希字符串（小写）
    func ls_sha512String() -> String {
        return ls_hashString(CC_SHA512, length: CC_SHA512_DIGEST_LENGTH)
    }

    /// CRC32 哈希字符串
    func ls_crc32String() -> String {
        return String(format: "%08x", ls_crc32())
    }

    // MARK: - Hash (Data)

    /// MD5 哈希数据
    func ls_md5Data() -> Data {
        return ls_hashData(CC_MD5, length: CC_MD5_DIGEST_LENGTH)
    }

    /// SHA1 哈希数据
    func ls_sha1Data() -> Data {
        return ls_hashData(CC_SHA1, length: CC_SHA1_DIGEST_LENGTH)
    }

    /// SHA224 哈希数据
    func ls_sha224Data() -> Data {
        return ls_hashData(CC_SHA224, length: CC_SHA224_DIGEST_LENGTH)
    }

    /// SHA256 哈希数据
    func ls_sha256Data() -> Data {
        return ls_hashData(CC_SHA256, length: CC_SHA256_DIGEST_LENGTH)
    }

    /// SHA384 哈希数据
    func ls_sha384Data() -> Data {
        return ls_hashData(CC_SHA384, length: CC_SHA384_DIGEST_LENGTH)
    }

    /// SHA512 哈希数据
    func ls_sha512Data() -> Data {
        return ls_hashData(CC_SHA512, length: CC_SHA512_DIGEST_LENGTH)
    }

    /// CRC32 哈希值
    func ls_crc32() -> UInt32 {
        var crc: UInt32 = 0
        withUnsafeBytes { bytes in
            if let baseAddress = bytes.baseAddress {
                crc = crc32(0, baseAddress.assumingMemoryBound(to: Bytef.self), uInt(count))
            }
        }
        return crc
    }

    // MARK: - HMAC (String)

    /// HMAC MD5 字符串
    func ls_hmacMD5String(key: String) -> String {
        return ls_hmacString(key: key, algorithm: kCCHmacAlgMD5, length: CC_MD5_DIGEST_LENGTH)
    }

    /// HMAC SHA1 字符串
    func ls_hmacSHA1String(key: String) -> String {
        return ls_hmacString(key: key, algorithm: kCCHmacAlgSHA1, length: CC_SHA1_DIGEST_LENGTH)
    }

    /// HMAC SHA224 字符串
    func ls_hmacSHA224String(key: String) -> String {
        return ls_hmacString(key: key, algorithm: kCCHmacAlgSHA224, length: CC_SHA224_DIGEST_LENGTH)
    }

    /// HMAC SHA256 字符串
    func ls_hmacSHA256String(key: String) -> String {
        return ls_hmacString(key: key, algorithm: kCCHmacAlgSHA256, length: CC_SHA256_DIGEST_LENGTH)
    }

    /// HMAC SHA384 字符串
    func ls_hmacSHA384String(key: String) -> String {
        return ls_hmacString(key: key, algorithm: kCCHmacAlgSHA384, length: CC_SHA384_DIGEST_LENGTH)
    }

    /// HMAC SHA512 字符串
    func ls_hmacSHA512String(key: String) -> String {
        return ls_hmacString(key: key, algorithm: kCCHmacAlgSHA512, length: CC_SHA512_DIGEST_LENGTH)
    }

    // MARK: - HMAC (Data)

    /// HMAC MD5 数据
    func ls_hmacMD5Data(key: Data) -> Data {
        return ls_hmacData(key: key, algorithm: kCCHmacAlgMD5, length: CC_MD5_DIGEST_LENGTH)
    }

    /// HMAC SHA1 数据
    func ls_hmacSHA1Data(key: Data) -> Data {
        return ls_hmacData(key: key, algorithm: kCCHmacAlgSHA1, length: CC_SHA1_DIGEST_LENGTH)
    }

    /// HMAC SHA224 数据
    func ls_hmacSHA224Data(key: Data) -> Data {
        return ls_hmacData(key: key, algorithm: kCCHmacAlgSHA224, length: CC_SHA224_DIGEST_LENGTH)
    }

    /// HMAC SHA256 数据
    func ls_hmacSHA256Data(key: Data) -> Data {
        return ls_hmacData(key: key, algorithm: kCCHmacAlgSHA256, length: CC_SHA256_DIGEST_LENGTH)
    }

    /// HMAC SHA384 数据
    func ls_hmacSHA384Data(key: Data) -> Data {
        return ls_hmacData(key: key, algorithm: kCCHmacAlgSHA384, length: CC_SHA384_DIGEST_LENGTH)
    }

    /// HMAC SHA512 数据
    func ls_hmacSHA512Data(key: Data) -> Data {
        return ls_hmacData(key: key, algorithm: kCCHmacAlgSHA512, length: CC_SHA512_DIGEST_LENGTH)
    }

    // MARK: - AES 加密解密

    /// AES256 加密
    /// - Parameters:
    ///   - key: 密钥，长度为 16、24 或 32 (128、192 或 256 bits)
    ///   - iv: 初始化向量，长度为 16 (128 bits)，传 nil 不使用 iv
    /// - Returns: 加密后的数据，失败返回 nil
    func ls_aes256Encrypt(key: Data, iv: Data?) -> Data? {
        // 验证 key 长度
        guard key.count == 16 || key.count == 24 || key.count == 32 else { return nil }
        // 验证 iv 长度
        guard let iv = iv, (iv.count == 16 || iv.isEmpty) else { return nil }

        let bufferSize = count + kCCBlockSizeAES128
        var buffer = Data(count: bufferSize)
        var encryptedSize = 0

        let status = key.withUnsafeBytes { keyBytes in
            iv.withUnsafeBytes { ivBytes in
                self.withUnsafeBytes { dataBytes in
                    buffer.withUnsafeMutableBytes { bufferBytes in
                        CCCrypt(
                            CCOperation(kCCEncrypt),
                            CCAlgorithm(kCCAlgorithmAES128),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyBytes.baseAddress, key.count,
                            iv.isEmpty ? nil : ivBytes.baseAddress,
                            dataBytes.baseAddress, count,
                            bufferBytes.baseAddress, bufferSize,
                            &encryptedSize
                        )
                    }
                }
            }
        }

        guard status == kCCSuccess else { return nil }
        buffer.count = encryptedSize
        return buffer
    }

    /// AES256 解密
    /// - Parameters:
    ///   - key: 密钥，长度为 16、24 或 32 (128、192 或 256 bits)
    ///   - iv: 初始化向量，长度为 16 (128 bits)，传 nil 不使用 iv
    /// - Returns: 解密后的数据，失败返回 nil
    func ls_aes256Decrypt(key: Data, iv: Data?) -> Data? {
        // 验证 key 长度
        guard key.count == 16 || key.count == 24 || key.count == 32 else { return nil }
        // 验证 iv 长度
        guard let iv = iv, (iv.count == 16 || iv.isEmpty) else { return nil }

        let bufferSize = count + kCCBlockSizeAES128
        var buffer = Data(count: bufferSize)
        var decryptedSize = 0

        let status = key.withUnsafeBytes { keyBytes in
            iv.withUnsafeBytes { ivBytes in
                self.withUnsafeBytes { dataBytes in
                    buffer.withUnsafeMutableBytes { bufferBytes in
                        CCCrypt(
                            CCOperation(kCCDecrypt),
                            CCAlgorithm(kCCAlgorithmAES128),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyBytes.baseAddress, key.count,
                            iv.isEmpty ? nil : ivBytes.baseAddress,
                            dataBytes.baseAddress, count,
                            bufferBytes.baseAddress, bufferSize,
                            &decryptedSize
                        )
                    }
                }
            }
        }

        guard status == kCCSuccess else { return nil }
        buffer.count = decryptedSize
        return buffer
    }

    // MARK: - 编解码

    /// UTF8 字符串
    func ls_utf8String() -> String? {
        return String(data: self, encoding: .utf8)
    }

    /// 十六进制字符串（大写）
    func ls_hexString() -> String {
        return map { String(format: "%02X", $0) }.joined()
    }

    /// Base64 编码字符串
    func ls_base64EncodedString() -> String {
        return base64EncodedString()
    }

    /// JSON 解码
    func ls_jsonValue() -> Any? {
        return try? JSONSerialization.jsonObject(with: self, options: [.allowFragments])
    }

    // MARK: - GZIP 压缩/解压

    /// GZIP 解压
    func ls_gzipInflate() -> Data? {
        guard count > 0 else { return self }

        let bufferSize = count + count / 2
        var buffer = Data(count: bufferSize)

        var stream = z_stream()
        stream.zalloc = Z_NULL
        stream.zfree = Z_NULL
        stream.opaque = Z_NULL

        var status: Int32

        status = inflateInit2(&stream, 15 + 16)
        guard status == Z_OK else { return nil }

        var totalOut = 0

        repeat {
            if totalOut >= buffer.count {
                buffer.count += bufferSize / 2
            }

            withUnsafeBytes { (dataPtr: UnsafeRawBufferPointer) in
                buffer.withUnsafeMutableBytes { (bufferPtr: UnsafeMutableRawBufferPointer) in
                    stream.next_in = UnsafeMutablePointer<Bytef>(mutating: dataPtr.baseAddress?.advanced(by: totalOut).assumingMemoryBound(to: Bytef.self))
                    stream.avail_in = uInt(count - totalOut)
                    stream.next_out = bufferPtr.baseAddress?.advanced(by: stream.total_out).assumingMemoryBound(to: Bytef.self)
                    stream.avail_out = uInt(buffer.count - stream.total_out)

                    status = inflate(&stream, Z_SYNC_FLUSH)
                }
            }

            totalOut = Int(stream.total_out)

        } while status == Z_OK

        inflateEnd(&stream)

        guard status == Z_STREAM_END else { return nil }

        buffer.count = totalOut
        return buffer
    }

    /// GZIP 压缩
    func ls_gzipDeflate() -> Data? {
        guard count > 0 else { return self }

        var stream = z_stream()
        stream.zalloc = Z_NULL
        stream.zfree = Z_NULL
        stream.opaque = Z_NULL

        var status = deflateInit2(&stream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, 15 + 16, 8, Z_DEFAULT_STRATEGY)
        guard status == Z_OK else { return nil }

        var buffer = Data(count: 16384)

        repeat {
            if stream.total_out >= buffer.count {
                buffer.count += 16384
            }

            withUnsafeBytes { dataPtr in
                buffer.withUnsafeMutableBytes { bufferPtr in
                    stream.next_in = UnsafeMutablePointer<Bytef>(mutating: dataPtr.baseAddress?.assumingMemoryBound(to: Bytef.self))
                    stream.avail_in = uInt(count)
                    stream.next_out = bufferPtr.baseAddress?.advanced(by: stream.total_out).assumingMemoryBound(to: Bytef.self)
                    stream.avail_out = uInt(buffer.count - stream.total_out)

                    status = deflate(&stream, Z_FINISH)
                }
            }

        } while stream.avail_out == 0

        deflateEnd(&stream)

        buffer.count = Int(stream.total_out)
        return buffer
    }

    // MARK: - ZLIB 压缩/解压

    /// ZLIB 解压
    func ls_zlibInflate() -> Data? {
        guard count > 0 else { return self }

        let bufferSize = count + count / 2
        var buffer = Data(count: bufferSize)

        var stream = z_stream()
        stream.zalloc = Z_NULL
        stream.zfree = Z_NULL
        stream.opaque = Z_NULL

        var status: Int32

        status = inflateInit(&stream)
        guard status == Z_OK else { return nil }

        var totalOut = 0

        repeat {
            if totalOut >= buffer.count {
                buffer.count += bufferSize / 2
            }

            withUnsafeBytes { (dataPtr: UnsafeRawBufferPointer) in
                buffer.withUnsafeMutableBytes { (bufferPtr: UnsafeMutableRawBufferPointer) in
                    stream.next_in = UnsafeMutablePointer<Bytef>(mutating: dataPtr.baseAddress?.advanced(by: totalOut).assumingMemoryBound(to: Bytef.self))
                    stream.avail_in = uInt(count - totalOut)
                    stream.next_out = bufferPtr.baseAddress?.advanced(by: stream.total_out).assumingMemoryBound(to: Bytef.self)
                    stream.avail_out = uInt(buffer.count - stream.total_out)

                    status = inflate(&stream, Z_SYNC_FLUSH)
                }
            }

            totalOut = Int(stream.total_out)

        } while status == Z_OK

        inflateEnd(&stream)

        guard status == Z_STREAM_END else { return nil }

        buffer.count = totalOut
        return buffer
    }

    /// ZLIB 压缩
    func ls_zlibDeflate() -> Data? {
        guard count > 0 else { return self }

        var stream = z_stream()
        stream.zalloc = Z_NULL
        stream.zfree = Z_NULL
        stream.opaque = Z_NULL

        var status = deflateInit(&stream, Z_DEFAULT_COMPRESSION)
        guard status == Z_OK else { return nil }

        var buffer = Data(count: 16384)

        repeat {
            if stream.total_out >= buffer.count {
                buffer.count += 16384
            }

            withUnsafeBytes { dataPtr in
                buffer.withUnsafeMutableBytes { bufferPtr in
                    stream.next_in = UnsafeMutablePointer<Bytef>(mutating: dataPtr.baseAddress?.assumingMemoryBound(to: Bytef.self))
                    stream.avail_in = uInt(count)
                    stream.next_out = bufferPtr.baseAddress?.advanced(by: stream.total_out).assumingMemoryBound(to: Bytef.self)
                    stream.avail_out = uInt(buffer.count - stream.total_out)

                    status = deflate(&stream, Z_FINISH)
                }
            }

        } while stream.avail_out == 0

        deflateEnd(&stream)

        buffer.count = Int(stream.total_out)
        return buffer
    }

    // MARK: - 私有辅助方法

    private func ls_hashString(_ function: (UnsafeRawPointer?, CC_LONG, UnsafeMutablePointer<UInt8>?) -> Void, length: Int32) -> String {
        var hash = [UInt8](repeating: 0, count: Int(length))
        withUnsafeBytes { bytes in
            function(bytes.baseAddress, CC_LONG(count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    private func ls_hashData(_ function: (UnsafeRawPointer?, CC_LONG, UnsafeMutablePointer<UInt8>?) -> Void, length: Int32) -> Data {
        var hash = [UInt8](repeating: 0, count: Int(length))
        withUnsafeBytes { bytes in
            function(bytes.baseAddress, CC_LONG(count), &hash)
        }
        return Data(hash)
    }

    private func ls_hmacString(key: String, algorithm: CCHmacAlgorithm, length: Int32) -> String {
        var hmac = [UInt8](repeating: 0, count: Int(length))
        key.withCString { keyPtr in
            withUnsafeBytes { bytes in
                CCHmac(algorithm, keyPtr, key.length, bytes.baseAddress, count, &hmac)
            }
        }
        return hmac.map { String(format: "%02x", $0) }.joined()
    }

    private func ls_hmacData(key: Data, algorithm: CCHmacAlgorithm, length: Int32) -> Data {
        var hmac = [UInt8](repeating: 0, count: Int(length))
        key.withUnsafeBytes { keyBytes in
            withUnsafeBytes { dataBytes in
                CCHmac(algorithm, keyBytes.baseAddress, key.count, dataBytes.baseAddress, count, &hmac)
            }
        }
        return Data(hmac)
    }
}

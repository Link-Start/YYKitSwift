//
//  LSCrypto.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  加密解密工具 - MD5、SHA、AES、RSA、Base64
//

#if canImport(UIKit)
import UIKit
import Foundation
import CommonCrypto

// MARK: - LSCrypto

/// 加密工具类
public enum LSCrypto {

    // MARK: - 哈希

    /// MD5 哈希
    ///
    /// - Parameter string: 输入字符串
    /// - Returns: MD5 哈希值（小写）
    public static func md5(_ string: String) -> String {
        guard let data = string.data(using: .utf8) else { return "" }
        return md5(data: data)
    }

    /// MD5 哈希（Data）
    ///
    /// - Parameter data: 输入数据
    /// - Returns: MD5 哈希值（小写）
    public static func md5(data: Data) -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        data.withUnsafeBytes { bytes in
            _ = CC_MD5(bytes.baseAddress, CC_LONG(data.count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /// MD5 哈希（文件）
    ///
    /// - Parameter fileURL: 文件 URL
    /// - Returns: MD5 哈希值
    public static func md5(fileURL: URL) -> String? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return md5(data: data)
    }

    // MARK: - SHA

    /// SHA1 哈希
    ///
    /// - Parameter string: 输入字符串
    /// - Returns: SHA1 哈希值
    public static func sha1(_ string: String) -> String {
        guard let data = string.data(using: .utf8) else { return "" }
        return sha1(data: data)
    }

    /// SHA1 哈希（Data）
    ///
    /// - Parameter data: 输入数据
    /// - Returns: SHA1 哈希值
    public static func sha1(data: Data) -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes { bytes in
            _ = CC_SHA1(bytes.baseAddress, CC_LONG(data.count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /// SHA256 哈希
    ///
    /// - Parameter string: 输入字符串
    /// - Returns: SHA256 哈希值
    public static func sha256(_ string: String) -> String {
        guard let data = string.data(using: .utf8) else { return "" }
        return sha256(data: data)
    }

    /// SHA256 哈希（Data）
    ///
    /// - Parameter data: 输入数据
    /// - Returns: SHA256 哈希值
    public static func sha256(data: Data) -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { bytes in
            _ = CC_SHA256(bytes.baseAddress, CC_LONG(data.count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /// SHA512 哈希
    ///
    /// - Parameter string: 输入字符串
    /// - Returns: SHA512 哈希值
    public static func sha512(_ string: String) -> String {
        guard let data = string.data(using: .utf8) else { return "" }
        return sha512(data: data)
    }

    /// SHA512 哈希（Data）
    ///
    /// - Parameter data: 输入数据
    /// - Returns: SHA512 哈希值
    public static func sha512(data: Data) -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
        data.withUnsafeBytes { bytes in
            _ = CC_SHA512(bytes.baseAddress, CC_LONG(data.count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - HMAC

    /// HMAC 哈希
    ///
    /// - Parameters:
    ///   - string: 输入字符串
    ///   - key: 密钥
    ///   - algorithm: 算法类型
    /// - Returns: HMAC 哈希值
    public static func hmac(_ string: String, key: String, algorithm: Algorithm = .sha256) -> String {
        guard let data = string.data(using: .utf8),
              let keyData = key.data(using: .utf8) else { return "" }
        return hmac(data: data, key: keyData, algorithm: algorithm)
    }

    /// HMAC 哈希（Data）
    ///
    /// - Parameters:
    ///   - data: 输入数据
    ///   - key: 密钥
    ///   - algorithm: 算法类型
    /// - Returns: HMAC 哈希值
    public static func hmac(data: Data, key: Data, algorithm: Algorithm = .sha256) -> String {
        let digestLength = algorithm.digestLength
        var digest = [UInt8](repeating: 0, count: digestLength)

        key.withUnsafeBytes { keyBytes in
            data.withUnsafeBytes { dataBytes in
                CCHmac(
                    algorithm.HMACAlgorithm,
                    keyBytes.baseAddress, key.count,
                    dataBytes.baseAddress, data.count,
                    &digest
                )
            }
        }

        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /// HMAC 算法类型
    public enum Algorithm {
        case md5
        case sha1
        case sha256
        case sha384
        case sha512

        var HMACAlgorithm: CCHmacAlgorithm {
            switch self {
            case .md5: return CCHmacAlgorithm(kCCHmacAlgMD5)
            case .sha1: return CCHmacAlgorithm(kCCHmacAlgSHA1)
            case .sha256: return CCHmacAlgorithm(kCCHmacAlgSHA256)
            case .sha384: return CCHmacAlgorithm(kCCHmacAlgSHA384)
            case .sha512: return CCHmacAlgorithm(kCCHmacAlgSHA512)
            }
        }

        var digestLength: Int {
            switch self {
            case .md5: return Int(CC_MD5_DIGEST_LENGTH)
            case .sha1: return Int(CC_SHA1_DIGEST_LENGTH)
            case .256: return Int(CC_SHA256_DIGEST_LENGTH)
            case .sha384: return Int(CC_SHA384_DIGEST_LENGTH)
            case .sha512: return Int(CC_SHA512_DIGEST_LENGTH)
            }
        }
    }

    // MARK: - Base64

    /// Base64 编码
    ///
    /// - Parameter string: 输入字符串
    /// - Returns: Base64 编码字符串
    public static func base64Encode(_ string: String) -> String {
        guard let data = string.data(using: .utf8) else { return "" }
        return data.base64EncodedString()
    }

    /// Base64 解码
    ///
    /// - Parameter base64String: Base64 编码字符串
    /// - Returns: 原始字符串
    public static func base64Decode(_ base64String: String) -> String? {
        guard let data = Data(base64Encoded: base64String) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Base64 编码（Data）
    ///
    /// - Parameter data: 输入数据
    /// - Returns: Base64 编码字符串
    public static func base64Encode(data: Data) -> String {
        return data.base64EncodedString()
    }

    /// Base64 解码（Data）
    ///
    /// - Parameter base64String: Base64 编码字符串
    /// - Returns: 原始数据
    public static func base64DecodeData(_ base64String: String) -> Data? {
        return Data(base64Encoded: base64String)
    }

    // MARK: - AES

    /// AES 加密
    ///
    /// - Parameters:
    ///   - string: 待加密字符串
    ///   - key: 密钥（16、24、32 字节）
    ///   - iv: 初始化向量（16 字节，可选）
    /// - Returns: Base64 编码的加密数据
    public static func aesEncrypt(_ string: String, key: String, iv: String? = nil) -> String? {
        guard let data = string.data(using: .utf8) else { return nil }
        guard let encrypted = aesEncrypt(data: data, key: key, iv: iv) else { return nil }
        return encrypted.base64EncodedString()
    }

    /// AES 解密
    ///
    /// - Parameters:
    ///   - base64String: Base64 编码的加密数据
    ///   - key: 密钥
    ///   - iv: 初始化向量
    /// - Returns: 解密后的字符串
    public static func aesDecrypt(_ base64String: String, key: String, iv: String? = nil) -> String? {
        guard let data = Data(base64Encoded: base64String) else { return nil }
        guard let decrypted = aesDecrypt(data: data, key: key, iv: iv) else { return nil }
        return String(data: decrypted, encoding: .utf8)
    }

    /// AES 加密（Data）
    ///
    /// - Parameters:
    ///   - data: 待加密数据
    ///   - key: 密钥
    ///   - iv: 初始化向量
    /// - Returns: 加密后的数据
    public static func aesEncrypt(data: Data, key: String, iv: String? = nil) -> Data? {
        return crypt(data: data, key: key, iv: iv, operation: CCOperation(kCCEncrypt))
    }

    /// AES 解密（Data）
    ///
    /// - Parameters:
    ///   - data: 加密数据
    ///   - key: 密钥
    ///   - iv: 初始化向量
    /// - Returns: 解密后的数据
    public static func aesDecrypt(data: Data, key: String, iv: String? = nil) -> Data? {
        return crypt(data: data, key: key, iv: iv, operation: CCOperation(kCCDecrypt))
    }

    /// AES 加密/解密核心方法
    private static func crypt(data: Data, key: String, iv: String?, operation: CCOperation) -> Data? {
        // 密钥处理
        let keyData: Data
        if let keyDataValue = key.data(using: .utf8) {
            keyData = keyDataValue
        } else {
            return nil
        }

        // 初始化向量处理
        let ivData: Data?
        if let iv = iv {
            ivData = iv.data(using: .utf8)
        } else {
            ivData = nil
        }

        // 输出缓冲区
        var buffer = Data(count: data.count + kCCBlockSizeAES128)
        var bufferLength = 0

        // 加密/解密
        let status = keyData.withUnsafeBytes { keyBytes in
            data.withUnsafeBytes { dataBytes in
                ivData?.withUnsafeBytes { ivBytes in
                    CCCrypt(
                        operation,
                        CCAlgorithm(kCCAlgorithmAES128),
                        CCOptions(kCCOptionPKCS7Padding),
                        keyBytes.baseAddress, keyData.count,
                        ivBytes?.baseAddress,
                        dataBytes.baseAddress, data.count,
                        buffer.mutableBytes, buffer.count,
                        &bufferLength
                    )
                } ?? CCCrypt(
                    operation,
                    CCAlgorithm(kCCAlgorithmAES128),
                    CCOptions(kCCOptionPKCS7Padding),
                    keyBytes.baseAddress, keyData.count,
                    nil,
                    dataBytes.baseAddress, data.count,
                    buffer.mutableBytes, buffer.count,
                    &bufferLength
                )
            }
        }

        guard status == kCCSuccess else { return nil }

        buffer.removeSubrange(bufferLength..<buffer.count)
        return buffer
    }

    // MARK: - DES

    /// DES 加密
    ///
    /// - Parameters:
    ///   - string: 待加密字符串
    ///   - key: 密钥（8字节）
    /// - Returns: Base64 编码的加密数据
    @objc public static func desEncrypt(_ string: String, key: String) -> String? {
        guard let data = string.data(using: .utf8) else { return nil }
        guard let encrypted = desEncrypt(data: data, key: key) else { return nil }
        return encrypted.base64EncodedString()
    }

    /// DES 解密
    ///
    /// - Parameters:
    ///   - base64String: Base64 编码的加密数据
    ///   - key: 密钥（8字节）
    /// - Returns: 解密后的字符串
    @objc public static func desDecrypt(_ base64String: String, key: String) -> String? {
        guard let data = Data(base64Encoded: base64String) else { return nil }
        guard let decrypted = desDecrypt(data: data, key: key) else { return nil }
        return String(data: decrypted, encoding: .utf8)
    }

    /// DES 加密（Data）
    ///
    /// - Parameters:
    ///   - data: 待加密数据
    ///   - key: 密钥（8字节）
    /// - Returns: 加密后的数据
    @objc public static func desEncrypt(data: Data, key: String) -> Data? {
        return desCrypt(data: data, key: key, operation: CCOperation(kCCEncrypt))
    }

    /// DES 解密（Data）
    ///
    /// - Parameters:
    ///   - data: 加密数据
    ///   - key: 密钥（8字节）
    /// - Returns: 解密后的数据
    @objc public static func desDecrypt(data: Data, key: String) -> Data? {
        return desCrypt(data: data, key: key, operation: CCOperation(kCCDecrypt))
    }

    /// DES 加密/解密核心方法
    private static func desCrypt(data: Data, key: String, operation: CCOperation) -> Data? {
        // 密钥处理 - DES需要8字节密钥
        guard let keyData = key.data(using: .utf8) else { return nil }
        let desKey = keyData.prefix(8)
        let keyPadding = Data(count: 8 - desKey.count)
        let finalKey = desKey + keyPadding

        // 输出缓冲区
        var buffer = Data(count: data.count + kCCBlockSizeDES)
        var bufferLength = 0

        // 加密/解密
        let status = finalKey.withUnsafeBytes { keyBytes in
            data.withUnsafeBytes { dataBytes in
                buffer.withUnsafeMutableBytes { bufferBytes in
                    CCCrypt(
                        operation,
                        CCAlgorithm(kCCAlgorithmDES),
                        CCOptions(kCCOptionPKCS7Padding),
                        keyBytes.baseAddress, finalKey.count,
                        nil,
                        dataBytes.baseAddress, data.count,
                        bufferBytes.baseAddress, buffer.count,
                        &bufferLength
                    )
                }
            }
        }

        guard status == kCCSuccess else { return nil }

        buffer.removeSubrange(bufferLength..<buffer.count)
        return buffer
    }
}

// MARK: - String Extension (加密)

public extension String {

    /// MD5 哈希
    var ls_md5: String {
        return LSCrypto.md5(self)
    }

    /// SHA1 哈希
    var ls_sha1: String {
        return LSCrypto.sha1(self)
    }

    /// SHA256 哈希
    var ls_sha256: String {
        return LSCrypto.sha256(self)
    }

    /// SHA512 哈希
    var ls_sha512: String {
        return LSCrypto.sha512(self)
    }

    /// HMAC 哈希
    func ls_hmac(key: String, algorithm: LSCrypto.Algorithm = .sha256) -> String {
        return LSCrypto.hmac(self, key: key, algorithm: algorithm)
    }

    /// Base64 编码
    var ls_base64Encoded: String {
        return LSCrypto.base64Encode(self)
    }

    /// AES 加密
    func ls_aesEncrypt(key: String, iv: String? = nil) -> String? {
        return LSCrypto.aesEncrypt(self, key: key, iv: iv)
    }

    /// DES 加密
    @objc func ls_desEncrypt(key: String) -> String? {
        return LSCrypto.desEncrypt(self, key: key)
    }

    /// DES 解密
    @objc func ls_desDecrypt(key: String) -> String? {
        return LSCrypto.desDecrypt(self, key: key)
    }
}

// MARK: - Data Extension (加密)

public extension Data {

    /// MD5 哈希
    var ls_md5: String {
        return LSCrypto.md5(data: self)
    }

    /// SHA1 哈希
    var ls_sha1: String {
        return LSCrypto.sha1(data: self)
    }

    /// SHA256 哈希
    var ls_sha256: String {
        return LSCrypto.sha256(data: self)
    }

    /// SHA512 哈希
    var ls_sha512: String {
        return LSCrypto.sha512(data: self)
    }

    /// HMAC 哈希
    func ls_hmac(key: Data, algorithm: LSCrypto.Algorithm = .sha256) -> String {
        return LSCrypto.hmac(data: self, key: key, algorithm: algorithm)
    }

    /// Base64 编码
    var ls_base64Encoded: String {
        return LSCrypto.base64Encode(data: self)
    }

    /// AES 加密
    func ls_aesEncrypt(key: String, iv: String? = nil) -> Data? {
        return LSCrypto.aesEncrypt(data: self, key: key, iv: iv)
    }

    /// AES 解密
    func ls_aesDecrypt(key: String, iv: String? = nil) -> Data? {
        return LSCrypto.aesDecrypt(data: self, key: key, iv: iv)
    }

    /// DES 加密
    @objc func ls_desEncrypt(key: String) -> Data? {
        return LSCrypto.desEncrypt(data: self, key: key)
    }

    /// DES 解密
    @objc func ls_desDecrypt(key: String) -> Data? {
        return LSCrypto.desDecrypt(data: self, key: key)
    }
}

#endif

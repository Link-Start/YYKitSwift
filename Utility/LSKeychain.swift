//
//  LSKeychain.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  钥匙串访问封装 - 基于 Security 框架
//

#if canImport(UIKit)
import UIKit
import Foundation
import Security

// MARK: - 错误码枚举

/// 钥匙串错误码
public enum LSKeychainErrorCode: UInt {
    case unimplemented = 1       // 功能或操作未实现
    case io                       // I/O 错误
    case opWr                     // 文件已以写入权限打开
    case param                    // 传递给函数的参数无效
    case allocate                 // 内存分配失败
    case userCancelled            // 用户取消操作
    case badReq                   // 参数无效或状态无效
    case internalComponent        // 内部组件错误
    case notAvailable             // 没有可用的钥匙串
    case duplicateItem            // 指定项已存在于钥匙串中
    case itemNotFound             // 指定项在钥匙串中未找到
    case interactionNotAllowed    // 不允许用户交互
    case decode                   // 无法解码提供的数据
    case authFailed               // 用户名或密码错误
}

/// 钥匙串可访问性枚举
public enum LSKeychainAccessible: UInt {
    case none = 0

    /// 仅当设备解锁时可以访问数据
    /// 推荐用于仅需要在前台应用访问的项目
    /// 使用加密备份时，这些项目将迁移到新设备
    case whenUnlocked

    /// 仅在设备重启后首次解锁后可以访问数据
    /// 推荐用于需要后台应用程序访问的项目
    /// 使用加密备份时，这些项目将迁移到新设备
    case afterFirstUnlock

    /// 无论设备锁定状态如何，始终可以访问数据
    /// 不推荐用于除系统用途外的任何用途
    /// 使用加密备份时，这些项目将迁移到新设备
    case always

    /// 仅当设备设置了密码时可以访问数据
    /// 推荐用于仅需要在前台应用访问的项目
    /// 这些项目永远不会迁移到新设备
    case whenPasscodeSetThisDeviceOnly

    /// 仅当设备解锁时可以访问数据
    /// 推荐用于仅需要在前台应用访问的项目
    /// 这些项目永远不会迁移到新设备
    case whenUnlockedThisDeviceOnly

    /// 仅在设备重启后首次解锁后可以访问数据
    /// 推荐用于需要后台应用程序访问的项目
    /// 这些项目永远不会迁移到新设备
    case afterFirstUnlockThisDeviceOnly

    /// 无论设备锁定状态如何，始终可以访问数据
    /// 不推荐用于除系统用途外的任何用途
    /// 这些项目永远不会迁移到新设备
    case alwaysThisDeviceOnly
}

/// 同步模式枚举 (iOS 7+)
public enum LSKeychainSynchronizationMode: UInt {
    case any = 0    // 默认，不关心同步
    case no         // 不同步
    case yes        // 可同步到其他设备
}

// MARK: - LSKeychainItem

/// 钥匙串项/查询的包装类
public class LSKeychainItem: NSObject, NSCopying {

    // MARK: - 属性

    /// kSecAttrService
    public var service: String?

    /// kSecAttrAccount
    public var account: String?

    /// kSecValueData
    public var passwordData: Data?

    /// kSecValueData 的快捷方式 (NSString)
    public var password: String? {
        get {
            guard let data = passwordData else { return nil }
            return String(data: data, encoding: .utf8)
        }
        set {
            passwordData = newValue?.data(using: .utf8)
        }
    }

    /// kSecValueData 的快捷方式 (NSCoding 对象)
    public var passwordObject: Any? {
        get {
            guard let data = passwordData else { return nil }
            return try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data)
        }
        set {
            if let object = newValue {
                passwordData = try? NSKeyedArchiver.archivedData(withRootObject: object)
            } else {
                passwordData = nil
            }
        }
    }

    /// kSecAttrLabel
    public var label: String?

    /// kSecAttrType (FourCC)
    public var type: NSNumber?

    /// kSecAttrCreator (FourCC)
    public var creator: NSNumber?

    /// kSecAttrComment
    public var comment: String?

    /// kSecAttrDescription
    public var descr: String?

    /// kSecAttrModificationDate (只读)
    public private(set) var modificationDate: Date?

    /// kSecAttrCreationDate (只读)
    public private(set) var creationDate: Date?

    /// kSecAttrAccessGroup
    public var accessGroup: String?

    /// kSecAttrAccessible
    public var accessible: LSKeychainAccessible = .whenUnlocked

    /// kSecAttrSynchronizable (iOS 7+)
    public var synchronizable: LSKeychainSynchronizationMode = .any

    // MARK: - NSCopying

    public func copy(with zone: NSZone? = nil) -> Any {
        let item = LSKeychainItem()
        item.service = service
        item.account = account
        item.passwordData = passwordData
        item.label = label
        item.type = type
        item.creator = creator
        item.comment = comment
        item.descr = descr
        item.modificationDate = modificationDate
        item.creationDate = creationDate
        item.accessGroup = accessGroup
        item.accessible = accessible
        item.synchronizable = synchronizable
        return item
    }

    // MARK: - Description

    public override var description: String {
        var str = "LSKeychainItem:{\n"
        if let s = service { str += "  service: \(s),\n" }
        if let a = account { str += "  account: \(a),\n" }
        if let p = password { str += "  password: ***,\n" }
        if let l = label { str += "  label: \(l),\n" }
        if let t = type { str += "  type: \(t),\n" }
        if let c = creator { str += "  creator: \(c),\n" }
        if let c = comment { str += "  comment: \(c),\n" }
        if let d = descr { str += "  description: \(d),\n" }
        if let m = modificationDate { str += "  modificationDate: \(m),\n" }
        if let c = creationDate { str += "  creationDate: \(c),\n" }
        if let ag = accessGroup { str += "  accessGroup: \(ag),\n" }
        str += "}"
        return str
    }

    // MARK: - 内部方法

    /// 构建查询字典（用于查询、更新、删除）
    internal func queryDictionary() -> CFDictionary {
        var dict: [CFString: Any] = [:]

        dict[kSecClass] = kSecClassGenericPassword

        if let acc = account {
            dict[kSecAttrAccount] = acc
        }
        if let svc = service {
            dict[kSecAttrService] = svc
        }

        // 在模拟器上移除 access_group
        #if !targetEnvironment(simulator)
        if let ag = accessGroup {
            dict[kSecAttrAccessGroup] = ag
        }
        #endif

        // iOS 7+ 支持同步
        if #available(iOS 7.0, *) {
            dict[kSecAttrSynchronizable] = synchronizable.cfValue
        }

        return dict as CFDictionary
    }

    /// 构建完整字典（用于插入、更新）
    internal func dictionary() -> CFDictionary {
        var dict: [CFString: Any] = [:]

        dict[kSecClass] = kSecClassGenericPassword

        if let acc = account {
            dict[kSecAttrAccount] = acc
        }
        if let svc = service {
            dict[kSecAttrService] = svc
        }
        if let lbl = label {
            dict[kSecAttrLabel] = lbl
        }

        // 在模拟器上移除 access_group
        #if !targetEnvironment(simulator)
        if let ag = accessGroup {
            dict[kSecAttrAccessGroup] = ag
        }
        #endif

        // iOS 7+ 支持同步
        if #available(iOS 7.0, *) {
            dict[kSecAttrSynchronizable] = synchronizable.cfValue
        }

        if let access = accessible.cfValue {
            dict[kSecAttrAccessible] = access
        }
        if let pwd = passwordData {
            dict[kSecValueData] = pwd
        }
        if let t = type {
            dict[kSecAttrType] = t
        }
        if let c = creator {
            dict[kSecAttrCreator] = c
        }
        if let c = comment {
            dict[kSecAttrComment] = c
        }
        if let d = descr {
            dict[kSecAttrDescription] = d
        }

        return dict as CFDictionary
    }

    /// 从字典初始化
    internal init?(dictionary: [CFString: Any]) {
        super.init()
        service = dictionary[kSecAttrService] as? String
        account = dictionary[kSecAttrAccount] as? String
        passwordData = dictionary[kSecValueData] as? Data
        label = dictionary[kSecAttrLabel] as? String
        type = dictionary[kSecAttrType] as? NSNumber
        creator = dictionary[kSecAttrCreator] as? NSNumber
        comment = dictionary[kSecAttrComment] as? String
        descr = dictionary[kSecAttrDescription] as? String
        modificationDate = dictionary[kSecAttrModificationDate] as? Date
        creationDate = dictionary[kSecAttrCreationDate] as? Date
        accessGroup = dictionary[kSecAttrAccessGroup] as? String

        if let accessValue = dictionary[kSecAttrAccessible] as? String {
            accessible = LSKeychainAccessible.from(cfValue: accessValue)
        }

        if #available(iOS 7.0, *), let syncValue = dictionary[kSecAttrSynchronizable] as? NSNumber {
            synchronizable = LSKeychainSynchronizationMode.from(cfValue: syncValue)
        }
    }

    public override init() {
        super.init()
    }
}

// MARK: - LSKeychainAccessible Extension

private extension LSKeychainAccessible {
    var cfValue: CFString? {
        switch self {
        case .none:
            return nil
        case .whenUnlocked:
            return kSecAttrAccessibleWhenUnlocked
        case .afterFirstUnlock:
            return kSecAttrAccessibleAfterFirstUnlock
        case .always:
            return kSecAttrAccessibleAlways
        case .whenPasscodeSetThisDeviceOnly:
            return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        case .whenUnlockedThisDeviceOnly:
            return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case .afterFirstUnlockThisDeviceOnly:
            return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        case .alwaysThisDeviceOnly:
            return kSecAttrAccessibleAlwaysThisDeviceOnly
        }
    }

    static func from(cfValue: CFString) -> LSKeychainAccessible {
        switch cfValue as String {
        case String(kSecAttrAccessibleWhenUnlocked):
            return .whenUnlocked
        case String(kSecAttrAccessibleAfterFirstUnlock):
            return .afterFirstUnlock
        case String(kSecAttrAccessibleAlways):
            return .always
        case String(kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly):
            return .whenPasscodeSetThisDeviceOnly
        case String(kSecAttrAccessibleWhenUnlockedThisDeviceOnly):
            return .whenUnlockedThisDeviceOnly
        case String(kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly):
            return .afterFirstUnlockThisDeviceOnly
        case String(kSecAttrAccessibleAlwaysThisDeviceOnly):
            return .alwaysThisDeviceOnly
        default:
            return .none
        }
    }
}

// MARK: - LSKeychainSynchronizationMode Extension

private extension LSKeychainSynchronizationMode {
    var cfValue: CFTypeRef {
        switch self {
        case .any:
            return kSecAttrSynchronizableAny
        case .no:
            return kCFBooleanFalse
        case .yes:
            return kCFBooleanTrue
        }
    }

    static func from(cfValue: NSNumber) -> LSKeychainSynchronizationMode {
        if cfValue == kCFBooleanFalse {
            return .no
        } else if cfValue == kCFBooleanTrue {
            return .yes
        }
        return .any
    }
}

// MARK: - LSKeychain

/// 钥匙串访问包装类
public class LSKeychain: NSObject {

    // MARK: - 便利方法（密码操作）

    /// 获取指定服务和账户的密码
    ///
    /// - Parameters:
    ///   - serviceName: 服务名，不能为 nil
    ///   - account: 账户名，不能为 nil
    ///   - error: 错误信息
    /// - Returns: 密码字符串，未找到或出错返回 nil
    public static func getPassword(forService serviceName: String, account: String, error: NSErrorPointer) -> String? {
        guard !serviceName.isEmpty && !account.isEmpty else {
            if let error = error {
                error.pointee = LSKeychain.error(with: errSecParam)
            }
            return nil
        }

        let item = LSKeychainItem()
        item.service = serviceName
        item.account = account

        guard let result = selectOneItem(item, error: error) else {
            return nil
        }

        return result.password
    }

    /// 获取指定服务和账户的密码（无错误信息）
    public static func getPassword(forService serviceName: String, account: String) -> String? {
        return getPassword(forService: serviceName, account: account, error: nil)
    }

    /// 删除指定服务和账户的密码
    ///
    /// - Parameters:
    ///   - serviceName: 服务名，不能为 nil
    ///   - account: 账户名，不能为 nil
    ///   - error: 错误信息
    /// - Returns: 是否成功
    @discardableResult
    public static func deletePassword(forService serviceName: String, account: String, error: NSErrorPointer) -> Bool {
        guard !serviceName.isEmpty && !account.isEmpty else {
            if let error = error {
                error.pointee = LSKeychain.error(with: errSecParam)
            }
            return false
        }

        let item = LSKeychainItem()
        item.service = serviceName
        item.account = account

        return deleteItem(item, error: error)
    }

    /// 删除指定服务和账户的密码（无错误信息）
    @discardableResult
    public static func deletePassword(forService serviceName: String, account: String) -> Bool {
        return deletePassword(forService: serviceName, account: account, error: nil)
    }

    /// 设置指定服务和账户的密码
    ///
    /// - Parameters:
    ///   - password: 密码
    ///   - serviceName: 服务名，不能为 nil
    ///   - account: 账户名，不能为 nil
    ///   - error: 错误信息
    /// - Returns: 是否成功
    @discardableResult
    public static func setPassword(_ password: String, forService serviceName: String, account: String, error: NSErrorPointer) -> Bool {
        guard !password.isEmpty && !serviceName.isEmpty && !account.isEmpty else {
            if let error = error {
                error.pointee = LSKeychain.error(with: errSecParam)
            }
            return false
        }

        let item = LSKeychainItem()
        item.service = serviceName
        item.account = account

        if let result = selectOneItem(item, error: nil) {
            result.password = password
            return updateItem(result, error: error)
        } else {
            item.password = password
            return insertItem(item, error: error)
        }
    }

    /// 设置指定服务和账户的密码（无错误信息）
    @discardableResult
    public static func setPassword(_ password: String, forService serviceName: String, account: String) -> Bool {
        return setPassword(password, forService: serviceName, account: account, error: nil)
    }

    // MARK: - 完整查询方法（SQL 风格）

    /// 插入钥匙串项
    ///
    /// - Parameters:
    ///   - item: 要插入的项（service、account、passwordData 是必需的）
    ///   - error: 错误信息
    /// - Returns: 是否成功
    @discardableResult
    public static func insertItem(_ item: LSKeychainItem, error: NSErrorPointer) -> Bool {
        guard let svc = item.service, let acc = item.account, let pwd = item.passwordData else {
            if let error = error {
                error.pointee = LSKeychain.error(with: errSecParam)
            }
            return false
        }

        let dict = item.dictionary()
        let status = SecItemAdd(dict, nil)

        if status != errSecSuccess {
            if let error = error {
                error.pointee = LSKeychain.error(with: status)
            }
            return false
        }

        return true
    }

    /// 插入钥匙串项（无错误信息）
    @discardableResult
    public static func insertItem(_ item: LSKeychainItem) -> Bool {
        return insertItem(item, error: nil)
    }

    /// 更新钥匙串项
    ///
    /// - Parameters:
    ///   - item: 要更新的项（service、account、passwordData 是必需的）
    ///   - error: 错误信息
    /// - Returns: 是否成功
    @discardableResult
    public static func updateItem(_ item: LSKeychainItem, error: NSErrorPointer) -> Bool {
        guard let svc = item.service, let acc = item.account, let pwd = item.passwordData else {
            if let error = error {
                error.pointee = LSKeychain.error(with: errSecParam)
            }
            return false
        }

        let query = item.queryDictionary()
        var update = item.dictionary() as [AnyHashable: Any]

        // 移除 kSecClass，不能在更新中指定
        let key = kSecClass as String
        update.removeValue(forKey: key)

        let status = SecItemUpdate(query, update as CFDictionary)

        if status != errSecSuccess {
            if let error = error {
                error.pointee = LSKeychain.error(with: status)
            }
            return false
        }

        return true
    }

    /// 更新钥匙串项（无错误信息）
    @discardableResult
    public static func updateItem(_ item: LSKeychainItem) -> Bool {
        return updateItem(item, error: nil)
    }

    /// 删除钥匙串项
    ///
    /// - Parameters:
    ///   - item: 要删除的项（service、account 是必需的）
    ///   - error: 错误信息
    /// - Returns: 是否成功
    @discardableResult
    public static func deleteItem(_ item: LSKeychainItem, error: NSErrorPointer) -> Bool {
        guard let svc = item.service, let acc = item.account else {
            if let error = error {
                error.pointee = LSKeychain.error(with: errSecParam)
            }
            return false
        }

        let query = item.dictionary()
        let status = SecItemDelete(query)

        if status != errSecSuccess {
            if let error = error {
                error.pointee = LSKeychain.error(with: status)
            }
            return false
        }

        return true
    }

    /// 删除钥匙串项（无错误信息）
    @discardableResult
    public static func deleteItem(_ item: LSKeychainItem) -> Bool {
        return deleteItem(item, error: nil)
    }

    /// 查询单个钥匙串项
    ///
    /// - Parameters:
    ///   - item: 查询条件（service、account 是可选的）
    ///   - error: 错误信息
    /// - Returns: 查询到的项，如果多个匹配只返回一个
    public static func selectOneItem(_ item: LSKeychainItem, error: NSErrorPointer) -> LSKeychainItem? {
        guard let svc = item.service, let acc = item.account else {
            if let error = error {
                error.pointee = LSKeychain.error(with: errSecParam)
            }
            return nil
        }

        var query = item.queryDictionary() as [AnyHashable: Any]
        query[kSecMatchLimit] = kSecMatchLimitOne
        query[kSecReturnAttributes] = kCFBooleanTrue
        query[kSecReturnData] = kCFBooleanTrue

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status != errSecSuccess {
            if let error = error {
                error.pointee = LSKeychain.error(with: status)
            }
            return nil
        }

        guard let result = result else { return nil }

        var dict: [CFString: Any]?

        if CFGetTypeID(result) == CFDictionaryGetTypeID() {
            dict = result as? [CFString: Any]
        } else if CFGetTypeID(result) == CFArrayGetTypeID() {
            if let array = result as? [[CFString: Any]], let first = array.first {
                dict = first
            }
        }

        guard let dict = dict, !dict.isEmpty else { return nil }

        return LSKeychainItem(dictionary: dict)
    }

    /// 查询单个钥匙串项（无错误信息）
    public static func selectOneItem(_ item: LSKeychainItem) -> LSKeychainItem? {
        return selectOneItem(item, error: nil)
    }

    /// 查询所有匹配的钥匙串项
    ///
    /// - Parameters:
    ///   - item: 查询条件（service、account 是可选的）
    ///   - error: 错误信息
    /// - Returns: 查询到的项数组
    public static func selectItems(_ item: LSKeychainItem, error: NSErrorPointer) -> [LSKeychainItem] {
        var query = item.queryDictionary() as [AnyHashable: Any]
        query[kSecMatchLimit] = kSecMatchLimitAll
        query[kSecReturnAttributes] = kCFBooleanTrue
        query[kSecReturnData] = kCFBooleanTrue

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status != errSecSuccess && status != errSecItemNotFound {
            if let error = error {
                error.pointee = LSKeychain.error(with: status)
            }
            return []
        }

        var items: [LSKeychainItem] = []

        if let dict = result as? [CFString: Any] {
            if let item = LSKeychainItem(dictionary: dict) {
                items.append(item)
            }
        } else if let array = result as? [[CFString: Any]] {
            for dict in array {
                if let item = LSKeychainItem(dictionary: dict) {
                    items.append(item)
                }
            }
        }

        return items
    }

    /// 查询所有匹配的钥匙串项（无错误信息）
    public static func selectItems(_ item: LSKeychainItem) -> [LSKeychainItem] {
        return selectItems(item, error: nil)
    }

    // MARK: - 私有方法

    /// 从 OSStatus 创建错误
    private static func error(with osStatus: OSStatus) -> NSError {
        let code = LSKeychain.errorCode(from: osStatus)
        let description = LSKeychain.errorDescription(from: code)

        var userInfo: [String: Any]?
        if let desc = description {
            userInfo = [NSLocalizedDescriptionKey: desc]
        }

        return NSError(domain: "com.xiaoyueyun.yykitswift.keychain", code: Int(rawValue), userInfo: userInfo)
    }

    /// 将 OSStatus 转换为 LSKeychainErrorCode
    private static func errorCode(from osStatus: OSStatus) -> LSKeychainErrorCode {
        switch osStatus {
        case errSecUnimplemented:
            return .unimplemented
        case errSecIO:
            return .io
        case errSecOpWr:
            return .opWr
        case errSecParam:
            return .param
        case errSecAllocate:
            return .allocate
        case errSecUserCanceled:
            return .userCancelled
        case errSecBadReq:
            return .badReq
        case errSecInternalComponent:
            return .internalComponent
        case errSecNotAvailable:
            return .notAvailable
        case errSecDuplicateItem:
            return .duplicateItem
        case errSecItemNotFound:
            return .itemNotFound
        case errSecInteractionNotAllowed:
            return .interactionNotAllowed
        case errSecDecode:
            return .decode
        case errSecAuthFailed:
            return .authFailed
        default:
            return .io
        }
    }

    /// 获取错误描述
    private static func errorDescription(from code: LSKeychainErrorCode) -> String? {
        switch code {
        case .unimplemented:
            return "Function or operation not implemented."
        case .io:
            return "I/O error."
        case .opWr:
            return "File already open with write permission."
        case .param:
            return "One or more parameters passed to a function were not valid."
        case .allocate:
            return "Failed to allocate memory."
        case .userCancelled:
            return "User canceled the operation."
        case .badReq:
            return "Bad parameter or invalid state for operation."
        case .internalComponent:
            return "Internal component error."
        case .notAvailable:
            return "No keychain is available. You may need to restart your computer."
        case .duplicateItem:
            return "The specified item already exists in the keychain."
        case .itemNotFound:
            return "The specified item could not be found in the keychain."
        case .interactionNotAllowed:
            return "User interaction is not allowed."
        case .decode:
            return "Unable to decode the provided data."
        case .authFailed:
            return "The user name or passphrase you entered is not correct."
        }
    }
}
#endif

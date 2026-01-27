//
//  LSNetworkUtilities.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  网络工具类 - 网络状态检测和处理
//

#if canImport(UIKit)
import UIKit
import Foundation
import SystemConfiguration
import CoreTelephony

// MARK: - LSNetworkUtilities

/// LSNetworkUtilities 提供网络相关的实用方法
public enum LSNetworkUtilities {

    // MARK: - 网络状态

    /// 当前网络状态
    public static var networkStatus: LSReachabilityStatus {
        return LSReachability.currentStatus()
    }

    /// 是否有网络连接
    public static var isNetworkAvailable: Bool {
        return networkStatus != .none
    }

    /// 是否为 WiFi
    public static var isWiFi: Bool {
        return networkStatus == .wifi
    }

    /// 是否为蜂窝网络
    public static var isWWAN: Bool {
        return networkStatus == .wwan
    }

    // MARK: - 网络类型

    /// 获取网络运营商信息
    public static var carrierName: String? {
        let networkInfo = CTTelephonyNetworkInfo()
        let carrier = networkInfo.subscriberCellularProvider
        return carrier?.carrierName
    }

    /// 获取网络类型
    public static var networkType: String? {
        let networkInfo = CTTelephonyNetworkInfo()
        let radioType = networkInfo.currentRadioAccessTechnology

        switch radioType {
        case CTRadioAccessTechnologyGPRS, CTRadioAccessTechnologyEdge, CTRadioAccessTechnologyCDMA1x:
            return "2G"
        case CTRadioAccessTechnologyWCDMA, CTRadioAccessTechnologyHSDPA, CTRadioAccessTechnologyHSUPA, CTRadioAccessTechnologyHSUPAPlus:
            return "3G"
        case CTRadioAccessTechnologyLTE:
            return "4G"
        case CTRadioAccessTechnologyNR:
            if #available(iOS 14.1, *) {
                return "5G"
            }
            return "4G"
        default:
            return "未知"
        }
    }

    /// 是否支持 5G
    public static var is5GSupported: Bool {
        if #available(iOS 14.1, *) {
            let networkInfo = CTTelephonyNetworkInfo()
            return networkInfo.currentRadioAccessTechnology == CTRadioAccessTechnologyNR
        }
        return false
    }

    // MARK: - URL 处理

    /// 从 URL 中提取参数
    ///
    /// - Parameter url: URL
    /// - Returns: 参数字典
    public static func urlParameters(from url: URL) -> [String: String] {
        var parameters = [String: String]()

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return parameters
        }

        for item in queryItems {
            parameters[item.name] = item.value ?? ""
        }

        return parameters
    }

    /// 将参数添加到 URL
    ///
    /// - Parameters:
    ///   - url: 原始 URL
    ///   - parameters: 参数字典
    /// - Returns: 新的 URL
    public static func url(byAddingParameters parameters: [String: Any], to url: URL) -> URL? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }

        var queryItems: [URLQueryItem] = []

        for (key, value) in parameters {
            if let stringValue = value as? String {
                queryItems.append(URLQueryItem(name: key, value: stringValue))
            } else if let numberValue = value as? NSNumber {
                queryItems.append(URLQueryItem(name: key, value: numberValue.stringValue))
            } else if let boolValue = value as? Bool {
                queryItems.append(URLQueryItem(name: key, value: boolValue ? "true" : "false"))
            }
        }

        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        return components.url
    }

    /// 编码 URL 参数
    ///
    /// - Parameter string: 原始字符串
    /// - Returns: 编码后的字符串
    public static func encodeURLParameter(_ string: String) -> String {
        var allowedCharacters = CharacterSet.urlQueryAllowed
        allowedCharacters.insert(charactersIn: "[]") // 允许方括号
        return string.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? string
    }

    /// 解码 URL 参数
    ///
    /// - Parameter string: 编码后的字符串
    /// - Returns: 解码后的字符串
    public static func decodeURLParameter(_ string: String) -> String {
        return string.removingPercentEncoding ?? string
    }

    // MARK: - HTTP 方法

    /// HTTP 方法
    public enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
        case head = "HEAD"
        case patch = "PATCH"
        case options = "OPTIONS"
        case trace = "TRACE"
        case connect = "CONNECT"
    }

    /// 构建 URL 请求
    ///
    /// - Parameters:
    ///   - url: URL
    ///   - method: HTTP 方法
    ///   - parameters: 参数
    ///   - headers: 请求头
    /// - Returns: URLRequest
    public static func urlRequest(
        with url: URL,
        method: HTTPMethod = .get,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil
    ) -> URLRequest? {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        // 添加参数
        if let parameters = parameters, method == .get || method == .head || method == .delete {
            if let urlWithParams = url(byAddingParameters: parameters, to: url) {
                request.url = urlWithParams
            }
        }

        // 添加请求头
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        // 添加参数到 Body（POST/PUT 等）
        if let parameters = parameters, method == .post || method == .put || method == .patch {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            } catch {
                return nil
            }
        }

        return request
    }

    // MARK: - 网络状态检测

    /// 开始监听网络状态变化
    ///
    /// - Parameter handler: 状态变化回调
    /// - Returns: LSReachability 实例
    @discardableResult
    public static func startMonitoringNetworkStatus(handler: @escaping (LSReachabilityStatus) -> Void) -> LSReachability {
        let reachability = LSReachability()
        reachability.statusHandler = handler
        reachability.startMonitoring()
        return reachability
    }

    /// 停止监听网络状态
    ///
    /// - Parameter reachability: LSReachability 实例
    public static func stopMonitoringNetworkStatus(reachability: LSReachability) {
        reachability.stopMonitoring()
    }
}

// MARK: - URLRequest Extension

public extension URLRequest {

    /// 获取请求的描述信息
    var ls_description: String {
        var desc = "\(httpMethod ?? "GET") \(url?.absoluteString ?? "")"

        if let headers = allHTTPHeaderFields {
            desc += "\nHeaders: \(headers)"
        }

        if let body = httpBody, let bodyString = String(data: body, encoding: .utf8) {
            desc += "\nBody: \(bodyString)"
        }

        return desc
    }
}

// MARK: - URL Extension

public extension URL {

    /// 获取域名
    var ls_domain: String? {
        host
    }

    /// 获取路径
    var ls_path: String {
        path
    }

    /// 获取查询参数字典
    var ls_queryParameters: [String: String] {
        LSNetworkUtilities.urlParameters(from: self)
    }

    /// 添加参数
    ///
    /// - Parameter parameters: 参数字典
    /// - Returns: 新的 URL
    func ls_addingParameters(_ parameters: [String: Any]) -> URL? {
        LSNetworkUtilities.url(byAddingParameters: parameters, to: self)
    }

    /// 删除参数
    ///
    /// - Parameter parameterNames: 要删除的参数名
    /// - Returns: 新的 URL
    func ls_removingParameters(_ parameterNames: [String]) -> URL? {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }

        components.queryItems = components.queryItems?.filter { !parameterNames.contains($0.name) }

        return components.url
    }
}

#endif

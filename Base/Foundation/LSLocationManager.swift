//
//  LSLocationManager.swift
//  Link-Start
//
//  Created by YYKitSwift Rewrite on 2026-01-24.
//  Copyright © 2026 Link-Start. All rights reserved.
//
//  定位工具 - 简化位置获取
//

#if canImport(UIKit)
import UIKit
import Foundation
import CoreLocation

// MARK: - LSLocationManager

/// 定位管理器
public class LSLocationManager: NSObject {

    // MARK: - 类型定义

    /// 位置更新回调
    public typealias LocationUpdateHandler = (CLLocation) -> Void

    /// 位置错误回调
    public typealias LocationErrorHandler = (Error) -> Void

    /// 地址回调
    public typealias AddressHandler = (CLPlacemark?) -> Void

    // MARK: - 单例

    /// 默认实例
    public static let shared = LSLocationManager()

    // MARK: - 属性

    /// CLLocationManager 实例
    private let locationManager = CLLocationManager()

    /// 当前位置
    public private(set) var currentLocation: CLLocation?

    /// 是否正在定位
    public private(set) var isUpdatingLocation = false

    /// 位置更新回调
    public var onLocationUpdate: LocationUpdateHandler?

    /// 位置错误回调
    public var onLocationError: LocationErrorHandler?

    /// 定位精度
    public var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyHundredMeters {
        didSet {
            locationManager.desiredAccuracy = desiredAccuracy
        }
    }

    /// 最小距离更新
    public var distanceFilter: CLLocationDistance = 10 {
        didSet {
            locationManager.distanceFilter = distanceFilter
        }
    }

    /// 超时时间（秒）
    public var timeout: TimeInterval = 10

    /// 超时计时器
    private var timeoutTimer: Timer?

    // MARK: - 初始化

    public override init() {
        super.init()
        setupLocationManager()
    }

    // MARK: - 设置

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = desiredAccuracy
        locationManager.distanceFilter = distanceFilter

        // iOS 14+ 需要请求精确授权
        if #available(iOS 14.0, *) {
            // 暂时使用降低精度模式
            locationManager.desiredAccuracy = kCLLocationAccuracyReduced
        }
    }

    // MARK: - 权限

    /// 定位权限状态
    public var authorizationStatus: CLAuthorizationStatus {
        return CLLocationManager.authorizationStatus()
    }

    /// 是否有定位权限
    public var isAuthorized: Bool {
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return true
        default:
            return false
        }
    }

    /// 请求定位权限
    ///
    /// - Parameter completion: 完成回调
    public func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        if #available(iOS 14.0, *) {
            // 先请求降级定位权限
            if authorizationStatus == .notDetermined {
                locationManager.requestWhenInUseAuthorization()
            }
        } else {
            if authorizationStatus == .notDetermined {
                locationManager.requestWhenInUseAuthorization()
            }
        }

        // 延迟检查权限状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion?(self.isAuthorized)
        }
    }

    /// 请求完整定位权限（iOS 14+）
    ///
    /// - Parameter completion: 完成回调
    @available(iOS 14.0, *)
    public func requestFullAccuracy(completion: ((Bool) -> Void)? = nil) {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            completion?(false)
            return
        }

        let accuracyKey = locationManager.accuracyAuthorization

        if accuracyKey == .reducedAccuracy {
            locationManager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: "FullAccuracyUsage") { granted in
                completion?(granted)
            }
        } else {
            completion?(true)
        }
    }

    // MARK: - 位置获取

    /// 获取当前位置（一次性）
    ///
    /// - Parameters:
    ///   - accuracy: 精度
    ///   - timeout: 超时时间
    ///   - completion: 完成回调
    public func getCurrentLocation(
        accuracy: CLLocationAccuracy = kCLLocationAccuracyBest,
        timeout: TimeInterval = 10,
        completion: @escaping (Result<CLLocation, Error>) -> Void
    ) {
        // 如果已有有效位置，直接返回
        if let location = currentLocation,
           Date().timeIntervalSince(location.timestamp) < 10 {
            completion(.success(location))
            return
        }

        // 开始定位
        let originalAccuracy = desiredAccuracy
        desiredAccuracy = accuracy

        let timeoutWorkItem = DispatchWorkItem {
            self.stopUpdatingLocation()
            completion(.failure(LocationError.timeout))
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: timeoutWorkItem)

        onLocationUpdate = { [weak self] location in
            guard let self = self else { return }
            timeoutWorkItem.cancel()
            self.stopUpdatingLocation()
            self.desiredAccuracy = originalAccuracy
            completion(.success(location))
        }

        onLocationError = { [weak self] error in
            guard let self = self else { return }
            timeoutWorkItem.cancel()
            self.stopUpdatingLocation()
            self.desiredAccuracy = originalAccuracy
            completion(.failure(error))
        }

        startUpdatingLocation()
    }

    /// 开始持续定位
    public func startUpdatingLocation() {
        guard isAuthorized else {
            onLocationError?(LocationError.notAuthorized)
            return
        }

        locationManager.startUpdatingLocation()
        isUpdatingLocation = true
    }

    /// 停止定位
    public func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        isUpdatingLocation = false
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }

    /// 获取地址（反向地理编码）
    ///
    /// - Parameters:
    ///   - location: 位置
    ///   - completion: 完成回调
    public func getAddress(from location: CLLocation, completion: @escaping AddressHandler) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                NSLog("反向地理编码失败: \(error.localizedDescription)")
                completion(nil)
            } else {
                completion(placemarks?.first)
            }
        }
    }

    /// 获取当前位置的地址
    ///
    /// - Parameter completion: 完成回调
    public func getCurrentAddress(completion: @escaping AddressHandler) {
        getCurrentLocation { [weak self] result in
            switch result {
            case .success(let location):
                self?.getAddress(from: location, completion: completion)
            case .failure:
                completion(nil)
            }
        }
    }

    /// 根据地址获取位置（正向地理编码）
    ///
    /// - Parameters:
    ///   - address: 地址字符串
    ///   - completion: 完成回调
    public func getLocation(from address: String, completion: @escaping (Result<CLLocation, Error>) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            if let error = error {
                completion(.failure(error))
            } else if let placemark = placemarks?.first, let location = placemark.location {
                completion(.success(location))
            } else {
                completion(.failure(LocationError.addressNotFound))
            }
        }
    }

    // MARK: - 距离计算

    /// 计算两点间距离
    ///
    /// - Parameters:
    ///   - from: 起始位置
    ///   - to: 目标位置
    /// - Returns: 距离（米）
    public func distance(from: CLLocation, to: CLLocation) -> CLLocationDistance {
        return from.distance(from: to)
    }

    /// 计算当前位置到目标位置的距离
    ///
    /// - Parameter location: 目标位置
    /// - Returns: 距离（米），nil 表示当前位置未知
    public func distance(to location: CLLocation) -> CLLocationDistance? {
        guard let current = currentLocation else { return nil }
        return current.distance(from: location)
    }
}

// MARK: - CLLocationManagerDelegate

extension LSLocationManager: CLLocationManagerDelegate {

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        currentLocation = location
        onLocationUpdate?(location)
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let clError = error as? CLError ?? LocationError.unknown(error)
        onLocationError?(clError)
    }

    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // 权限变化时的处理
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            // 可以开始定位
            break
        case .denied, .restricted:
            stopUpdatingLocation()
            onLocationError?(LocationError.notAuthorized)
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
}

// MARK: - LocationError

/// 定位错误
public enum LocationError: Error {
    case notAuthorized
    case timeout
    case addressNotFound
    case unknown(Error)

    public var localizedDescription: String {
        switch self {
        case .notAuthorized:
            return "没有定位权限"
        case .timeout:
            return "定位超时"
        case .addressNotFound:
            return "未找到地址"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - CLLocation Extension

public extension CLLocation {

    /// 是否有效
    var isValid: Bool {
        return horizontalAccuracy < 0 && horizontalAccuracy >= 0
    }

    /// 精度描述
    var accuracyDescription: String {
        if horizontalAccuracy < 0 {
            return "无效"
        } else if horizontalAccuracy < 5 {
            return "极高精度"
        } else if horizontalAccuracy < 15 {
            return "高精度"
        } else if horizontalAccuracy < 50 {
            return "中等精度"
        } else if horizontalAccuracy < 100 {
            return "低精度"
        } else {
            return "极低精度"
        }
    }

    /// 格式化的坐标
    var formattedCoordinate: String {
        return String(format: "%.6f, %.6f", coordinate.latitude, coordinate.longitude)
    }

    /// 转换为位置字符串
    func toString() -> String {
        return String(
            format: "纬度: %.6f, 经度: %.6f, 精度: %.1fm",
            coordinate.latitude,
            coordinate.longitude,
            horizontalAccuracy
        )
    }
}

// MARK: - CLPlacemark Extension

public extension CLPlacemark {

    /// 格式化的地址
    var formattedAddress: String {
        var components: [String] = []

        if let name = name {
            components.append(name)
        }

        if let thoroughfare = thoroughfare {
            components.append(thoroughfare)
        }

        if let locality = locality {
            components.append(locality)
        }

        if let administrativeArea = administrativeArea {
            components.append(administrativeArea)
        }

        if let postalCode = postalCode {
            components.append(postalCode)
        }

        if let country = country {
            components.append(country)
        }

        return components.joined(separator: ", ")
    }

    /// 简化的城市名称
    var simplifiedCity: String? {
        if let locality = locality {
            return locality
        }
        if let administrativeArea = administrativeArea {
            return administrativeArea
        }
        if let name = name {
            return name
        }
        return nil
    }
}

// MARK: - 便捷方法

public extension LSLocationManager {

    /// 请求权限并获取位置
    ///
    /// - Parameters:
    ///   - accuracy: 精度
    ///   - timeout: 超时时间
    ///   - completion: 完成回调
    static func requestLocation(
        accuracy: CLLocationAccuracy = kCLLocationAccuracyBest,
        timeout: TimeInterval = 10,
        completion: @escaping (Result<CLLocation, Error>) -> Void
    ) {
        let manager = LSLocationManager()

        func start() {
            manager.getCurrentLocation(accuracy: accuracy, timeout: timeout, completion: completion)
        }

        if manager.isAuthorized {
            start()
        } else {
            manager.requestAuthorization { granted in
                if granted {
                    start()
                } else {
                    completion(.failure(LocationError.notAuthorized))
                }
            }
        }
    }
}

#endif

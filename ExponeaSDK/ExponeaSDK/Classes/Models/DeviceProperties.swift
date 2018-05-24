//
//  DeviceProperties.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 12/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// Basic information about the device
struct DeviceProperties {
    /// Operational system name
    public var osName: String = Constants.DeviceInfo.osName
    
    /// OS version
    public var osVersion: String = UIDevice.current.systemVersion
    
    /// SDK Name
    public var sdk: String = Constants.DeviceInfo.sdk
    
    /// SDK Versioning
    public var sdkVersion: String = Constants.DeviceInfo.sdkVersion
    
    /// Device model
    public var deviceModel: String = UIDevice.current.model
    
    /// Device type
    public var deviceType: String {
        if UIDevice.current.model.hasPrefix("iPad") { return "tablet" } else { return "mobile" }
    }
    
    /// App version number, eg. "1.0".
    public var appVersion: String {
        return Bundle.main.infoDictionary?[Constants.Keys.appVersion] as? String ?? "N/A"
    }
    
    /// Returns an array with all device properties.
    var properties: [String: JSONConvertible] {
        var data = [String: JSONConvertible]()

        data["os_name"] = osName
        data["os_version"] = osVersion
        data["sdk"] = sdk
        data["sdk_version"] = sdkVersion
        data["device_model"] = deviceModel
        data["device_type"] = deviceType
        data["app_version"] = appVersion

        return data
    }
}

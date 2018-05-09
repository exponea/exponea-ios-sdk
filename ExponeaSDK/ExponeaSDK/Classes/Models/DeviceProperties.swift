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
        return Bundle.main.value(forKey: Constants.Keys.appVersion) as? String ?? "N/A"
    }
    
    /// Returns an array with all device properties.
    var properties: [KeyValueItem] {
        var data = [KeyValueItem]()

        data.append(KeyValueItem(key: "os_name", value: osName))
        data.append(KeyValueItem(key: "os_version", value: osVersion))
        data.append(KeyValueItem(key: "sdk", value: sdk))
        data.append(KeyValueItem(key: "sdk_version", value: sdkVersion))
        data.append(KeyValueItem(key: "device_model", value: deviceModel))
        data.append(KeyValueItem(key: "device_type", value: deviceType))
        data.append(KeyValueItem(key: "app_version", value: deviceType))

        return data
    }
}

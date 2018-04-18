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
    /// Returns an array with all device properties.
    var properties: [KeyValueModel] {
        var data = [KeyValueModel]()

        data.append(KeyValueModel(key: "os_name", value: osName))
        data.append(KeyValueModel(key: "os_version", value: osVersion))
        data.append(KeyValueModel(key: "sdk", value: sdk))
        data.append(KeyValueModel(key: "sdk_version", value: sdkVersion))
        data.append(KeyValueModel(key: "device_model", value: deviceModel))
        data.append(KeyValueModel(key: "device_type", value: deviceType))

        return data
    }
}

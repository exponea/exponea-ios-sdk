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
    internal let bundle: Bundle
    
    /// Operational system name
    public var osName: String = Constants.DeviceInfo.osName
    
    /// OS version
    public var osVersion: String = UIDevice.current.systemVersion
    
    /// SDK Name
    public var sdk: String = Constants.DeviceInfo.sdk
    
    /// SDK Versioning
    public var sdkVersion: String = {
        let bundle = Bundle(for: ExponeaSDK.Exponea.self)
        let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String
        return version ?? "Unknown version"
    }()
    
    /// Device model
    public var deviceModel: String = UIDevice.current.model
    
    /// Device type
    public var deviceType: String {
        if UIDevice.current.model.hasPrefix("iPad") { return "tablet" } else { return "mobile" }
    }
    
    /// App version number, eg. "1.0".
    public var appVersion: String {
        return bundle.infoDictionary?[Constants.Keys.appVersion] as? String ?? "N/A"
    }
    
    /// Returns an array with all device properties.
    internal var properties: [String: JSONValue] {
        var data = [String: JSONValue]()

        data["os_name"] = .string(osName)
        data["platform"] = .string(osName)
        data["os_version"] = .string(osVersion)
        data["sdk"] = .string(sdk)
        data["sdk_version"] = .string(sdkVersion)
        data["device_model"] = .string(deviceModel)
        data["device_type"] = .string(deviceType)
        data["app_version"] = .string(appVersion)

        return data
    }
    
    internal init(bundle: Bundle = Bundle.main) {
        self.bundle = bundle
    }
}

//
//  Install.swift
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
    public var deviceType: String = ""

    init() {
        deviceType = getDeviceType()
    }

    func asKeyValueModel() -> [KeyValueModel] {
        var dict = [KeyValueModel]()

        dict.append(KeyValueModel(key: "os_name", value: osName))
        dict.append(KeyValueModel(key: "os_version", value: osVersion))
        dict.append(KeyValueModel(key: "sdk", value: sdk))
        dict.append(KeyValueModel(key: "sdk_version", value: sdkVersion))
        dict.append(KeyValueModel(key: "device_model", value: deviceModel))
        dict.append(KeyValueModel(key: "device_type", value: getDeviceType()))

        return dict
    }
}

/// Information about the Campaign
public struct CampaignProperties {
    /// Campaign name
    public var campaign: String?
    /// Campaign identification
    public var campaignId: String?
    /// Source of installation link
    public var link: String?
    /// IP address
    public var ipAddress: String?

    init(campaign: String?, campaignId: String?, link: String?, ipAddress: String?) {
        self.campaign = campaign
        self.campaignId = campaignId
        self.link = link
        self.ipAddress = ipAddress
    }
}

extension DeviceProperties {
    func getDeviceType() -> String {
        if (UIDevice.current.model).hasPrefix("iPad") { return "tablet" } else { return "mobile" }
    }
}

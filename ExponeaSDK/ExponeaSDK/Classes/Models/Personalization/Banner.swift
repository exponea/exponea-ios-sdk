//
//  Banner.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 08/06/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

public struct Banner: Codable {
    public let id: String
    public let dateFilter: DateFilter
    public let deviceTarget: DeviceTarget
    public let frequency: BannerFrequency
    public let trigger: BannerTrigger
    
    enum CodingKeys: String, CodingKey {
        case id = "_id", dateFilter = "date_filter", deviceTarget = "device_target", frequency, trigger
    }
}

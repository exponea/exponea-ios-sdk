//
//  CampaignData.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 08/06/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

public struct CampaignData: Codable {
    let url: URL
    let timestamp: Double

    init(url: URL) {
        self.url = url
        self.timestamp = Date().timeIntervalSince1970
    }
}

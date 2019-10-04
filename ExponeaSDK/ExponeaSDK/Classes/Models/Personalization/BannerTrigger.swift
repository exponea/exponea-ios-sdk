//
//  BannerTrigger.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 08/06/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

public struct BannerTrigger: Codable {
    public let includePages: [[String: String]]
    public let excludePages: [[String: String]]

    enum CodingKeys: String, CodingKey {
        case includePages = "include_pages", excludePages = "exclude_pages"
    }

}

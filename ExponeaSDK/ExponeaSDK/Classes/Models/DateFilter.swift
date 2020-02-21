//
//  DateFilter.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 08/06/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

public struct DateFilter: Codable, Equatable {
    public let enabled: Bool
    public let startDate: Date?
    public let endDate: Date?

    enum CodingKeys: String, CodingKey {
        case enabled, startDate = "from_date", endDate = "to_date"
    }
}

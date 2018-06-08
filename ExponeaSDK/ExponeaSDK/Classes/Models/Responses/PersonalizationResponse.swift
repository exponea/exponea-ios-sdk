//
//  PersonalizationResponse.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 08/06/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

public struct PersonalizationResponse: Codable {
    public let success: Bool
    public let data: [Personalization]
}

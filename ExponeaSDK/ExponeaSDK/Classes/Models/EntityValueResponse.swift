//
//  EntityValueResponse.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 02/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

public struct EntityValueResponse: Codable {
    let success: Bool
    let value: Double
    let entityName: String
}

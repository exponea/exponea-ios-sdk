//
//  Events.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 20/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

public struct Events: Codable {
    let success: Bool?
    let data: [ExportedEventType]?
}

//
//  InAppMessageDisplayStatus.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 18/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

struct InAppMessageDisplayStatus: Codable, Equatable {
    let displayed: Date?
    let interacted: Date?
}

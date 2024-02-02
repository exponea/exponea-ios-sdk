//
//  QueueData.swift
//  ExponeaSDK
//
//  Created by Ankmara on 10.07.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation

struct QueueData {
    let inAppContentBlocks: InAppContentBlockResponse
    let newValue: UsedInAppContentBlocks
}

struct QueueLoadData {
    let placeholder: String
    let indexPath: IndexPath
    let expired: [InAppContentBlockResponse]
}

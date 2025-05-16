//
//  CampaignRepositoryType.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 09/12/2024.
//  Copyright © 2024 Exponea. All rights reserved.
//

import Foundation

protocol CampaignRepositoryType {
    func popValid() -> CampaignData?
    func set(_ data: CampaignData)
    func clear()
}

//
//  CampaignProperties.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 12/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// Information about the Campaign.
public struct CampaignProperties {
    /// Campaign name
    public var campaign: String?
    
    /// Campaign identification
    public var campaignId: String?
    
    /// Source of installation link
    public var link: String?
    
    /// IP address
    public var ipAddress: String?
}

//
//  CampaignData+Properties.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 16/05/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

extension CampaignData {
    var utmData: DataType {
        get {
            var data: [String: JSONValue] = [:]
            guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
                let params = components.queryItems else { return .properties(data) }
            params.forEach {
                if $0.name.starts(with: "utm") {
                    data[$0.name] = .string($0.value ?? "")
                }
            }
            return .properties(data)
        }
    }

    var campaignData: [String: JSONValue] {
        get {
            var data: [String: JSONValue] = [:]
            data["url"] = .string(url.absoluteString)
            data["properties"] = .dictionary(["platform": .string("iOS")])
            return data
        }
    }

    var campaignDataProperties: DataType {
        get {
            return .properties(campaignData)
        }
    }
}

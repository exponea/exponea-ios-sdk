//
//  PersonalizationRequest.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 08/06/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

public struct PersonalizationRequest: Codable {
    public let ids: [String]
    public let timeout: Int
    public let timezone: String
    public let customParameters: [String: JSONValue]?
    
    enum CodingKeys: String, CodingKey {
        case ids = "personalisation_ids", timeout, timezone, customParameters = "params"
    }
    
    public init(ids: [String],
                timeout: Int = 30,
                timezone: String = Calendar.current.timeZone.identifier,
                customParameters: [String: JSONConvertible]? = nil) {
        self.ids = ids
        self.timeout = timeout
        self.timezone = timezone
        self.customParameters = customParameters?.mapValues({ $0.jsonValue })
    }
}

extension PersonalizationRequest: RequestParametersType {
    var parameters: [String : JSONValue] {
        var params: [String : JSONValue] = [
            CodingKeys.ids.rawValue : .array(ids.map({ $0.jsonValue })),
            CodingKeys.timeout.rawValue : timeout.jsonValue,
            CodingKeys.timezone.rawValue : timezone.jsonValue,
            ]
        
        if let customParameters = customParameters {
            params[CodingKeys.customParameters.rawValue] = .dictionary(customParameters)
        }
        
        return params
    }
}

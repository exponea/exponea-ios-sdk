//
//  ExponeaIntegration.swift
//  ExponeaSDKShared
//
//  Created by Bloomreach on 09/01/2026.
//  Copyright © 2026 Exponea. All rights reserved.
//

import Foundation

public struct ExponeaIntegration: ExponeaIntegrationType {
    public let baseUrl: String
    public let streamId: String
    public var type: IntegrationSourceType {
        .stream(streamId: streamId)
    }

    public init(
        baseUrl: String = Constants.Repository.baseUrl,
        streamId: String
    ) {
        self.baseUrl = baseUrl
        self.streamId = streamId
    }

    public init(from decoder: Decoder) throws {
        let data = try decoder.container(keyedBy: CodingKeys.self)
        baseUrl = (try? data.decode(String.self, forKey: .baseUrl)) ?? Constants.Repository.baseUrl
        streamId = try data.decode(String.self, forKey: .streamId)
    }
}

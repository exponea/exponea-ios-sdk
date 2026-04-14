//
//  ExponeaIntegrationType.swift
//  ExponeaSDKShared
//
//  Created by Bloomreach on 09/01/2026.
//  Copyright © 2026 Exponea. All rights reserved.
//

import Foundation

public protocol ExponeaIntegrationType: Equatable, Codable {
    var baseUrl: String { get }
    var type: IntegrationSourceType { get }
}

public extension ExponeaIntegrationType {
    var integrationId: String {
        switch type {
        case .project(let projectToken): return projectToken
        case .stream(let streamId): return streamId
        }
    }
}

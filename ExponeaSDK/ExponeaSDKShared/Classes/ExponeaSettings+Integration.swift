//
//  Exponea+Integration.swift
//  ExponeaSDK
//
//  Created by Bloomreach on 02/01/2026.
//  Copyright © 2026 Exponea. All rights reserved.
//

import Foundation

public protocol IntegrationType: Equatable {
    var baseUrl: String { get }
    var type: IntegrationSourceType { get }
}

public extension Exponea {
    struct StreamSettings: IntegrationType {
        public let streamId: String
        public let baseUrl: String
        public var type: IntegrationSourceType {
            .stream(streamId: streamId)
        }
        
        public init(
            streamId: String,
            baseUrl: String? = nil
        ) {
            self.streamId = streamId
            self.baseUrl = baseUrl ?? Constants.Repository.baseUrl
        }
        
        public static func == (lhs: StreamSettings, rhs: StreamSettings) -> Bool {
            return lhs.baseUrl == rhs.baseUrl &&
                    lhs.streamId == rhs.streamId &&
                    lhs.type == rhs.type
        }
    }
    
    struct ProjectSettings: IntegrationType {
        public let projectToken: String
        public let authorization: Authorization
        public let baseUrl: String
        public let projectMapping: [EventType: [ExponeaProject]]?
        
        public var type: IntegrationSourceType {
            .project(projectToken: projectToken)
        }
        
        public init(
            projectToken: String,
            authorization: Authorization,
            baseUrl: String? = nil,
            projectMapping: [EventType: [ExponeaProject]]? = nil
        ) {
            self.projectToken = projectToken
            self.authorization = authorization
            self.baseUrl = baseUrl ?? Constants.Repository.baseUrl
            self.projectMapping = projectMapping
        }
        
        public static func == (lhs: ProjectSettings, rhs: ProjectSettings) -> Bool {
            return lhs.authorization == rhs.authorization &&
            lhs.baseUrl == rhs.baseUrl &&
            lhs.projectToken == rhs.projectToken &&
            lhs.type == rhs.type &&
            lhs.projectMapping == rhs.projectMapping
        }
    }
}

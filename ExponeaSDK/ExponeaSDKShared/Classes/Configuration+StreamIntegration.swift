//
//  Configuration+StreamIntegration.swift
//  ExponeaSDK
//
//  Created by Bloomreach on 29/01/2026.
//  Copyright © 2026 Exponea. All rights reserved.
//

import Foundation

// MARK: - Stream Integration Detection

public extension Configuration {
    
    /// Returns true if SDK is configured with Stream/Data Hub integration; false for Project/Engagement.
    /// Mirrors `integrationConfig.type.isStream`; single canonical flag. Prefer explicit `switch integrationConfig.type` at call sites.
    var usesStreamIntegration: Bool {
        integrationConfig.type.isStream
    }

    /// Returns the stream ID if configured for Stream integration, nil otherwise.
    var streamId: String? {
        switch integrationConfig.type {
        case .stream(let streamId):
            return streamId
        case .project:
            return nil
        }
    }
    
    /// Stable identifier for Stream JWT storage.
    /// Returns the stream ID for Stream integration, or a default value for Project integration.
    var streamIdentifierForJwt: String {
        switch integrationConfig.type {
        case .stream(let streamId):
            return streamId
        case .project:
            return "engagement-only"
        }
    }
    
    /// App Inbox URL for Stream integration.
    var streamAppInboxUrl: String {
        let baseUrl = integrationConfig.baseUrl.last == "/" 
            ? String(integrationConfig.baseUrl.dropLast()) 
            : integrationConfig.baseUrl
        switch integrationConfig.type {
        case .stream(let streamId):
            return "\(baseUrl)/webxp/streams/\(streamId)/appinbox/fetch"
        case .project:
            return ""
        }
    }
    
    /// App Inbox URL for Project/Engagement integration.
    var projectAppInboxUrl: String {
        let baseUrl = integrationConfig.baseUrl.last == "/" 
            ? String(integrationConfig.baseUrl.dropLast()) 
            : integrationConfig.baseUrl
        switch integrationConfig.type {
        case .project(let projectToken):
            return "\(baseUrl)/webxp/projects/\(projectToken)/appinbox/fetch"
        case .stream:
            return ""
        }
    }
    
    /// Returns the appropriate App Inbox URL based on integration type.
    var appInboxUrl: String {
        switch integrationConfig.type {
        case .stream: return streamAppInboxUrl
        case .project: return projectAppInboxUrl
        }
    }

    /// Returns true if the configuration has sufficient authorization for API requests.
    /// - Stream mode: JWT from provider (always sufficient when configured).
    /// - Project mode: ProjectSettings.authorization != Authorization.none OR customAuthProvider != nil
    var hasSufficientAuth: Bool {
        switch integrationConfig.type {
        case .stream:
            return true
        case .project:
            if customAuthProvider != nil { return true }
            return (integrationConfig as? Exponea.ProjectSettings)?.authorization != Authorization.none
        }
    }
}

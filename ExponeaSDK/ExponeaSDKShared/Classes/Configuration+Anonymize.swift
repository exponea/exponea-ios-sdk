//
//  Configuration+Anonymize.swift
//  ExponeaSDKShared
//
//  Created by Panaxeo on 12/01/2021.
//  Copyright © 2021 Exponea. All rights reserved.
//

import Foundation

public extension Configuration {
    mutating func switchProjects(
        exponeaIntegrationType: any ExponeaIntegrationType,
        exponeaIntegrationMapping: [EventType: [any ExponeaIntegrationType]]?
    ) {
        switch exponeaIntegrationType.type {
        case .project(let projectToken):
            let projectAuth = (exponeaIntegrationType as? ExponeaProject)?.authorization ?? Authorization.none
            self.projectToken = projectToken
            self.baseUrl = exponeaIntegrationType.baseUrl
            self.authorization = projectAuth
            self.projectMapping = exponeaIntegrationMapping as? [EventType: [ExponeaProject]]
            
            self.integrationConfig = Exponea.ProjectSettings(
                projectToken: projectToken,
                authorization: projectAuth,
                baseUrl: exponeaIntegrationType.baseUrl,
                projectMapping: projectMapping
            )
        case .stream(let streamId):
            self.integrationConfig = Exponea.StreamSettings(
                streamId: streamId,
                baseUrl: exponeaIntegrationType.baseUrl
            )
        }
    }
}

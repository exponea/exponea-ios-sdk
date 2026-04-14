//
//  Configuration+Validation.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 02/10/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

extension Configuration {
    enum ConfigurationValidationError: LocalizedError {
        case baseUrlInvalid
        case integrationIdInvalid(String)
        case projectMappingInvalid(EventType, Error)
        case advancedAuthInvalid(String)
        case applicationIDInvalid(String)

        public var errorDescription: String? {
            switch self {
            case .baseUrlInvalid:
                return "Base url provided is not a valid url."
            case .integrationIdInvalid(let details):
                return "Integration ID provided is not valid. \(details)"
            case .projectMappingInvalid(let eventType, let error):
                return "Project mapping for event type \(eventType) is not valid. \(error.localizedDescription)"
            case .advancedAuthInvalid(let message):
                return message
            case .applicationIDInvalid(let message):
                return message
            }
        }
    }

    func validate() throws {
        if URL(sharedSafeString: integrationConfig.baseUrl) == nil {
            throw ConfigurationValidationError.baseUrlInvalid
        }
        try validateIntegrationId(integrationId: integrationId)
        if let mapping = (integrationConfig as? Exponea.ProjectSettings)?.projectMapping {
            try mapping.forEach { entry in
                try entry.value.forEach {
                    do {
                        try validateIntegrationId(integrationId: $0.integrationId)
                    } catch {
                        throw ConfigurationValidationError.projectMappingInvalid(entry.key, error)
                    }
                }
            }
        }

        if applicationID != Constants.General.applicationID,
           !applicationID.isEmpty {
            if applicationID.count > 50 {
                throw ConfigurationValidationError.applicationIDInvalid("Application ID longer than allowed number of characters (50).")
            }
            // Fallback code for earlier iOS versions using NSRegularExpression
            let pattern = "^[a-z0-9]+(?:[-.][a-z0-9]+)*$"
            let regex = try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let range = NSRange(location: 0, length: applicationID.utf16.count)
            let isInvalid = regex.firstMatch(
                in: applicationID,
                options: [],
                range: range
            ) == nil
            if isInvalid {
                throw ConfigurationValidationError.applicationIDInvalid("Application ID doesn't match required set of characters.")
            }
        }
        // Advanced auth validation
        switch integrationConfig.type {
        case .stream:
            // Advanced auth is not supported with Stream integration
            if advancedAuthEnabled {
                Exponea.logger.log(
                    .warning,
                    message: "Advanced authorization (advancedAuthEnabled) is not supported with Stream integration. " +
                             "Use setSdkAuthToken() to set the Stream JWT instead. The advancedAuthEnabled flag will be ignored."
                )
            }
        case .project:
            // For Project mode, validate that provider exists if enabled
            if advancedAuthEnabled && customAuthProvider == nil {
                throw ConfigurationValidationError.advancedAuthInvalid(
                    "Advanced authorization flag has been enabled without provider"
                )
            }
        }
    }
    
    private func validateIntegrationId(integrationId: String) throws {
        guard !integrationId.isEmpty else {
            throw ConfigurationValidationError.integrationIdInvalid("Integration ID cannot be empty string.")
        }
        var allowed = CharacterSet.alphanumerics
        allowed.insert("-")

        if integrationId.rangeOfCharacter(from: allowed.inverted) != nil {
            throw ConfigurationValidationError.integrationIdInvalid(
                "Only alphanumeric symbols and dashes are allowed in integration ID."
            )
        }
    }
}

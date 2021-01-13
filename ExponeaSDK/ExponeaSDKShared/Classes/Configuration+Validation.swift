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
        case projectTokenInvalid(String)
        case projectMappingInvalid(EventType, Error)

        public var errorDescription: String? {
            switch self {
            case .baseUrlInvalid:
                return "Base url provided is not a valid url."

            case .projectTokenInvalid(let details):
                return "Project token provided is not valid. \(details)"

            case .projectMappingInvalid(let eventType, let error):
                return "Project mapping for event type \(eventType) is not valid. \(error.localizedDescription)"
            }
        }
    }

    func validate() throws {
        if URL(string: self.baseUrl) == nil {
            throw ConfigurationValidationError.baseUrlInvalid
        }
        try validateProjectToken(projectToken: projectToken)
        try self.projectMapping?.forEach { entry in
            try entry.value.forEach {
                do {
                    try validateProjectToken(projectToken: $0.projectToken)
                } catch {
                    throw ConfigurationValidationError.projectMappingInvalid(entry.key, error)
                }
            }
        }
    }

    func validateProjectToken(projectToken: String) throws {
        guard !projectToken.isEmpty else {
            throw ConfigurationValidationError.projectTokenInvalid("Project token cannot be empty string.")
        }
        var allowed = CharacterSet.alphanumerics
        allowed.insert("-")

        if projectToken.rangeOfCharacter(from: allowed.inverted) != nil {
            throw ConfigurationValidationError.projectTokenInvalid(
                "Only alphanumeric symbols and dashes are allowed in project token."
            )
        }
    }
}

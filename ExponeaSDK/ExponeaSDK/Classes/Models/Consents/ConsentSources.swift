//
//  ConsentSources.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 11/06/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

/// Used for identifying the sources of the consent.
public struct ConsentSources: Codable {
    /// Manually created from the web application.
    public let isCreatedFromCRM: Bool
    /// Imported from the importing wizard.
    public let isImported: Bool
    /// Tracked from the consent page.
    public let isFromConsentPage: Bool
    /// API which uses basic authentication.
    public let privateAPI: Bool
    /// API which only uses public token for authentication.
    public let publicAPI: Bool
    /// Tracked from the scenario from event node.
    public let isTrackedFromScenario: Bool
}

private extension ConsentSources {
    enum CodingKeys: String, CodingKey {
        case isCreatedFromCRM = "crm"
        case isImported = "import"
        case isFromConsentPage = "page"
        case privateAPI = "private_api"
        case publicAPI = "public_api"
        case isTrackedFromScenario = "scenario"
    }
}

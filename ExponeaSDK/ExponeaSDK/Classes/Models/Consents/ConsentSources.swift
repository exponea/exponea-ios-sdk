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
    let isCreatedFromCRM: Bool
    /// Imported from the importing wizard.
    let isImported: Bool
    /// Tracked from the consent page.
    let isFromConsentPage: Bool
    /// API which uses basic authentication.
    let privateAPI: Bool
    /// API which only uses public token for authentication.
    let publicAPI: Bool
    /// Tracked from the scenario from event node.
    let isTrackedFromScenario: Bool
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

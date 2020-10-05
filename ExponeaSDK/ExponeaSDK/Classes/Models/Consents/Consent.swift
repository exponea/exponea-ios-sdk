//
//  Consent.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 11/06/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

public struct Consent: Codable {
    /// Name of the consent category.
    public let id: String
    /// If the user has legitimate interest.
    public let legitimateInterest: Bool
    /// The sources of this consent.
    public let sources: ConsentSources
    /// Contains the translations for the consent.
    ///
    /// Keys of this dictionary are the short ISO language codes (eg. "en", "cz", "sk"...) and
    /// the values are dictionaries containing the translation key as the dictionary key
    /// and translation value as the dictionary value.
    public let translations: [String: [String: String?]]
}

private extension Consent {
    enum CodingKeys: String, CodingKey {
        case id, sources, translations
        case legitimateInterest = "legitimate_interest"
    }
}

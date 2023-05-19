//
//  NSDictionary+getSafely.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 19/05/2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation

extension NSDictionary {
    func getOptionalSafely<T>(property: String) throws -> T? {
        if let value = self[property] {
            guard let value = value as? T else {
                throw ExponeaError.invalidType(for: property)
            }
            return value
        }
        return nil
    }

    func getRequiredSafely<T>(property: String) throws -> T {
        guard let anyValue = self[property] else {
            throw ExponeaError.missingProperty(property: property)
        }
        guard let value = anyValue as? T else {
            throw ExponeaError.invalidType(for: property)
        }
        return value
    }
}

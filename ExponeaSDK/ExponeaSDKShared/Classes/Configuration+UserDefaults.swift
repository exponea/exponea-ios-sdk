//
//  Configuration+UserDefaults.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 06/03/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation

extension Configuration {
    public static func loadFromUserDefaults(appGroup: String) -> Configuration? {
        guard let userDefaults = UserDefaults(suiteName: appGroup),
              let data = userDefaults.data(forKey: Constants.General.lastKnownConfiguration) else {
            return nil
        }
        return try? JSONDecoder().decode(Configuration.self, from: data)
    }

    public static func deleteLastKnownConfig(appGroup: String) {
        guard let userDefaults = UserDefaults(suiteName: appGroup) else {
            UserDefaults(suiteName: Constants.General.userDefaultsSuite)?.removeObject(forKey: Constants.General.lastKnownConfiguration)
            return
        }
        userDefaults.removeObject(forKey: Constants.General.lastKnownConfiguration)
    }

    public func saveToUserDefaults() {
        guard let userDefaults = UserDefaults(suiteName: appGroup ?? Constants.General.userDefaultsSuite),
              let data = try? JSONEncoder().encode(self) else {
            return
        }
        userDefaults.set(data, forKey: Constants.General.lastKnownConfiguration)
    }
}

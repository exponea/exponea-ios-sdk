//
//  InAppMessageDisplayStatusStore.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 18/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

final class InAppMessageDisplayStatusStore {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
        self.deleteOldDisplayStates()
    }

    func status(for message: InAppMessage) -> InAppMessageDisplayStatus {
        let displayStates = getDisplayStates()
        return displayStates[message.id] ?? InAppMessageDisplayStatus(displayed: nil, interacted: nil)
    }

    func didDisplay(_ message: InAppMessage, at date: Date) {
        var displayStates = getDisplayStates()
        displayStates[message.id] = InAppMessageDisplayStatus(
            displayed: date,
            interacted: status(for: message).interacted
        )
        saveDisplayStates(displayStates)
    }

    func didInteract(with message: InAppMessage, at date: Date) {
        var displayStates = getDisplayStates()
        displayStates[message.id] = InAppMessageDisplayStatus(
            displayed: status(for: message).displayed,
            interacted: date
        )
        saveDisplayStates(displayStates)
    }

    func clear() {
        userDefaults.removeObject(forKey: Constants.General.inAppMessageDisplayStatusUserDefaultsKey)
    }

    private func getDisplayStates() -> [String: InAppMessageDisplayStatus] {
        guard let data = userDefaults.data(
                forKey: Constants.General.inAppMessageDisplayStatusUserDefaultsKey
              ) else {
            return [:]
        }
        do {
            return try JSONDecoder().decode([String: InAppMessageDisplayStatus].self, from: data)
        } catch {
            Exponea.logger.log(.error, message: "Unable to deserialize in-app message display states. \(error)")
            return [:]
        }
    }

    private func saveDisplayStates(_ displayStates: [String: InAppMessageDisplayStatus]) {
        do {
            userDefaults.set(
                try JSONEncoder().encode(displayStates),
                forKey: Constants.General.inAppMessageDisplayStatusUserDefaultsKey
            )
        } catch {
            Exponea.logger.log(.error, message: "Unable to save in-app message display states. \(error)")
        }
    }

    // If the message was displayed or interacted with in last 30 days, keep it, otherwise remove
    private func deleteOldDisplayStates() {
        let displayStates = getDisplayStates()
        guard let cutOffDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) else {
            return
        }
        let filteredDisplayStates = displayStates.filter {
            if let displayed = $0.value.displayed, displayed > cutOffDate {
                return true
            }
            if let interacted = $0.value.interacted, interacted > cutOffDate {
                return true
            }
            return false
        }
        saveDisplayStates(filteredDisplayStates)
    }
}

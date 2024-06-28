//
//  InAppContentBlockUsageStore.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 11/04/2024.
//  Copyright © 2024 Exponea. All rights reserved.
//

import Foundation

final class InAppContentBlockDisplayStatusStore {
    private let userDefaults: UserDefaults
    private var displayStates: [String: InAppContentBlocksDisplayStatus] {
        get {
            guard let data = userDefaults.data(
                    forKey: Constants.General.inAppContentBlockDisplayStatusUserDefaultsKey
                  ) else {
                return [:]
            }
            do {
                return try JSONDecoder().decode([String: InAppContentBlocksDisplayStatus].self, from: data)
            } catch {
                Exponea.logger.log(.error, message: "Unable to deserialize in-app content block display states. \(error)")
                return [:]
            }
        }
        set {
            do {
                userDefaults.set(
                    try JSONEncoder().encode(newValue),
                    forKey: Constants.General.inAppContentBlockDisplayStatusUserDefaultsKey
                )
            } catch {
                Exponea.logger.log(.error, message: "Unable to save in-app content block display states. \(error)")
            }
        }
    }

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
        self.deleteOldDisplayStates()
    }

    func status(for messageId: String) -> InAppContentBlocksDisplayStatus {
        return displayStates[messageId] ?? InAppContentBlocksDisplayStatus(displayed: nil, interacted: nil)
    }

    func didDisplay(of messageId: String, at date: Date) {
        displayStates[messageId] = InAppContentBlocksDisplayStatus(
            displayed: date,
            interacted: status(for: messageId).interacted
        )
    }

    func didInteract(with messageId: String, at date: Date) {
        displayStates[messageId] = InAppContentBlocksDisplayStatus(
            displayed: status(for: messageId).displayed,
            interacted: date
        )
    }

    func clear() {
        userDefaults.removeObject(forKey: Constants.General.inAppContentBlockDisplayStatusUserDefaultsKey)
    }

    // If the message was displayed or interacted with in last 30 days, keep it, otherwise remove
    private func deleteOldDisplayStates() {
        guard let cutOffDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) else {
            return
        }
        displayStates = displayStates.filter {
            if let displayed = $0.value.displayed, displayed > cutOffDate {
                return true
            }
            if let interacted = $0.value.interacted, interacted > cutOffDate {
                return true
            }
            return false
        }
    }
}

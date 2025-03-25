//
//  CampaignRepository.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 09/12/2024.
//  Copyright © 2024 Exponea. All rights reserved.
//

import Foundation

// Stores CampaignData record for upcoming session_start tracking
class CampaignRepository: CampaignRepositoryType {
    private let userDefaults: UserDefaults
    private static let accessQueue = DispatchQueue(label: "CampaignRepositoryQueue")
    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
        migrateRepositoryIfNeeded()
    }
    // Array of campaign events has been stored previously.
    // Only last one has been used for session_start amend, so only last one is kept
    private func migrateRepositoryIfNeeded() {
        guard let campaignDataRawArray = userDefaults.array(forKey: Constants.General.savedCampaignClickEvent) else {
            return
        }
        let campaignDataArray = campaignDataRawArray as? [Data]
        clearWithoutLock()
        if let lastCampaignData = campaignDataArray?.last {
            storeCampaignData(lastCampaignData)
        }
    }
    func popValid() -> CampaignData? {
        return CampaignRepository.accessQueue.sync {
            guard let lastCampaignData = userDefaults.data(forKey: Constants.General.savedCampaignClickEvent),
                  let lastCampaign = parseCampaingData(lastCampaignData) else {
                return nil
            }
            clearWithoutLock()
            if lastCampaign.timestamp + Constants.Session.sessionUpdateThreshold < Date().timeIntervalSince1970 {
                Exponea.logger.log(.verbose, message: "Campaing data found but expired")
                return nil
            }
            return lastCampaign
        }
    }
    func set(_ data: CampaignData) {
        CampaignRepository.accessQueue.sync {
            do {
                storeCampaignData(try JSONEncoder().encode(data))
            } catch {
                Exponea.logger.log(.error, message: "Unable to store campaign data due to error: \(error)")
            }
        }
    }
    func clear() {
        CampaignRepository.accessQueue.sync {
            clearWithoutLock()
        }
    }
    private func parseCampaingData(_ data: Data) -> CampaignData? {
        do {
            return try JSONDecoder().decode(CampaignData.self, from: data)
        } catch {
            Exponea.logger.log(.error, message: "Unable to load campaign data due to error: \(error)")
            return nil
        }
    }
    private func storeCampaignData(_ data: Data) {
        userDefaults.setValue(data, forKey: Constants.General.savedCampaignClickEvent)
        if !userDefaults.synchronize() {
            Exponea.logger.log(.warning, message: "Campaign data not stored properly")
            // but nothing to do about it
        }
    }
    private func clearWithoutLock() {
        userDefaults.removeObject(forKey: Constants.General.savedCampaignClickEvent)
        if !userDefaults.synchronize() {
            Exponea.logger.log(.warning, message: "Campaign data not removed properly")
            // but nothing to do about it
        }
    }
}

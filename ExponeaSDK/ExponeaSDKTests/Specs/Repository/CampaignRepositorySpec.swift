//
//  CampaignRepositorySpec.swift
//  ExponeaSDKTests
//
//  Created by Adam Mihalik on 10/12/2024.
//  Copyright © 2024 Exponea. All rights reserved.
//

import Nimble
import Quick

@testable import ExponeaSDK
@testable import ExponeaSDKNotifications

final class CampaignRepositorySpec: QuickSpec {
    override func spec() {
        let userDefaultsSuiteName = "mock-app-group"
        func moveToTime(_ campaign: CampaignData, _ time: TimeInterval) -> CampaignData {
            var mutableCampaign = campaign
            withUnsafeMutableBytes(of: &mutableCampaign) { bytes in
                let offset = MemoryLayout.offset(of: \CampaignData.timestamp)!
                let rawPointerToValue = bytes.baseAddress! + offset
                let pointerToValue = rawPointerToValue.assumingMemoryBound(to: TimeInterval.self)
                pointerToValue.pointee = time
            }
            return mutableCampaign
        }
        beforeEach {
            IntegrationManager.shared.isStopped = false
            UserDefaults.standard.removePersistentDomain(forName: userDefaultsSuiteName)
        }
        it("should migrate old campaign data filled array") {
            let userDefaults = UserDefaults(suiteName: userDefaultsSuiteName)!
            // store campaigns array
            let encoder = JSONEncoder()
            userDefaults.set(
                [
                    CampaignData(url: URL(safeString: "https://example.com?utm_source=123_1&xnpe_cmp=123")!),
                    CampaignData(url: URL(safeString: "https://example.com?utm_source=123_2&xnpe_cmp=123")!),
                    CampaignData(url: URL(safeString: "https://example.com?utm_source=123_3&xnpe_cmp=123")!),
                    CampaignData(url: URL(safeString: "https://example.com?utm_source=123_4&xnpe_cmp=123")!),
                    CampaignData(url: URL(safeString: "https://example.com?utm_source=123_5&xnpe_cmp=123")!)
                ].map({ each in
                    try! encoder.encode(each)
                }),
                forKey: Constants.General.savedCampaignClickEvent
            )
            // init repository with auto-migration
            let repository = CampaignRepository(userDefaults: userDefaults)
            guard let keptCampaign = repository.popValid() else {
                fail("Campaign not found")
                return
            }
            expect(keptCampaign.source).to(equal("123_5"))
        }
        it("should migrate old campaign data empty array") {
            let userDefaults = UserDefaults(suiteName: userDefaultsSuiteName)!
            // store campaigns array
            userDefaults.set(
                [],
                forKey: Constants.General.savedCampaignClickEvent
            )
            // init repository with auto-migration
            let repository = CampaignRepository(userDefaults: userDefaults)
            let keptCampaign = repository.popValid()
            expect(keptCampaign).to(beNil())
        }
        it("should not migrate nil") {
            let userDefaults = UserDefaults(suiteName: userDefaultsSuiteName)!
            // no campaigns array
            userDefaults.removeObject(forKey: Constants.General.savedCampaignClickEvent)
            // init repository with auto-migration
            let repository = CampaignRepository(userDefaults: userDefaults)
            let keptCampaign = repository.popValid()
            expect(keptCampaign).to(beNil())
        }
        it("should keep new campaign data - no migration") {
            let userDefaults = UserDefaults(suiteName: userDefaultsSuiteName)!
            // store campaigns array
            let encoder = JSONEncoder()
            userDefaults.set(
                try! encoder.encode(CampaignData(url: URL(safeString: "https://example.com?utm_source=123_1&xnpe_cmp=123")!)),
                forKey: Constants.General.savedCampaignClickEvent
            )
            // init repository with auto-migration
            let repository = CampaignRepository(userDefaults: userDefaults)
            guard let keptCampaign = repository.popValid() else {
                fail("Campaign not found")
                return
            }
            expect(keptCampaign.source).to(equal("123_1"))
        }
        it("should add campaign data") {
            let userDefaults = UserDefaults(suiteName: userDefaultsSuiteName)!
            let repository = CampaignRepository(userDefaults: userDefaults)
            repository.set(CampaignData(url: URL(safeString: "https://example.com?utm_source=123_1&xnpe_cmp=123")!))
            guard let keptCampaign = repository.popValid() else {
                fail("Campaign not found")
                return
            }
            expect(keptCampaign.source).to(equal("123_1"))
        }
        it("should replace campaign data") {
            let userDefaults = UserDefaults(suiteName: userDefaultsSuiteName)!
            let repository = CampaignRepository(userDefaults: userDefaults)
            repository.set(CampaignData(url: URL(safeString: "https://example.com?utm_source=123_1&xnpe_cmp=123")!))
            repository.set(CampaignData(url: URL(safeString: "https://example.com?utm_source=123_2&xnpe_cmp=123")!))
            guard let keptCampaign = repository.popValid() else {
                fail("Campaign not found")
                return
            }
            expect(keptCampaign.source).to(equal("123_2"))
        }
        it("should remove campaign data") {
            let userDefaults = UserDefaults(suiteName: userDefaultsSuiteName)!
            let repository = CampaignRepository(userDefaults: userDefaults)
            repository.set(CampaignData(url: URL(safeString: "https://example.com?utm_source=123_1&xnpe_cmp=123")!))
            repository.clear()
            let keptCampaign = repository.popValid()
            expect(keptCampaign).to(beNil())
        }
        it("should pop expired campaign data") {
            let userDefaults = UserDefaults(suiteName: userDefaultsSuiteName)!
            let repository = CampaignRepository(userDefaults: userDefaults)
            let expiredCampaignData = moveToTime(
                CampaignData(url: URL(safeString: "https://example.com?utm_source=123_1&xnpe_cmp=123")!),
                Date().addingTimeInterval(-(Constants.Session.sessionUpdateThreshold+1)).timeIntervalSince1970
            )
            repository.set(expiredCampaignData)
            let keptCampaign = repository.popValid()
            expect(keptCampaign).to(beNil())
            // truly removed
            expect(userDefaults.data(forKey: Constants.General.savedCampaignClickEvent)).to(beNil())
        }
        it("should pop valid campaign data") {
            let userDefaults = UserDefaults(suiteName: userDefaultsSuiteName)!
            let repository = CampaignRepository(userDefaults: userDefaults)
            repository.set(CampaignData(url: URL(safeString: "https://example.com?utm_source=123_1&xnpe_cmp=123")!))
            guard let keptCampaign = repository.popValid() else {
                fail("Campaign not found")
                return
            }
            expect(keptCampaign.source).to(equal("123_1"))
            expect(userDefaults.data(forKey: Constants.General.savedCampaignClickEvent)).to(beNil())
        }
    }
}

//
//  ExponeaNotificationServiceSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 31/10/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Quick
import Nimble

@testable import ExponeaSDK
@testable import ExponeaSDKNotifications

final class ExponeaNotificationServiceSpec: QuickSpec {
    private func getRecordedNotifications() -> [Data]? {
        let userDefaults = UserDefaults(suiteName: "mock-app-group")!
        if let delivered = userDefaults.array(forKey: ExponeaSDK.Constants.General.deliveredPushUserDefaultsKey)
           as? [Data] {
            return delivered
        }
        return nil
    }

    override func spec() {
        beforeEach {
            UserDefaults.standard.removePersistentDomain(forName: "mock-app-group")
        }

        it("should record notification into user defaults") {
            let service = ExponeaNotificationService(appGroup: "mock-app-group")
            service.saveNotificationForLaterTracking(userInfo: ["attributes": ["campaign_name": "mock campaign name"]])

            let delivered = self.getRecordedNotifications()!
            expect(delivered.count).to(equal(1))
            let savedNotificationData = ExponeaSDK.NotificationData.deserialize(from: delivered[0])
            expect(savedNotificationData?.campaignName).to(equal("mock campaign name"))
        }

        it("should record notification without tracking info into user defaults") {
            let service = ExponeaNotificationService(appGroup: "mock-app-group")
            service.saveNotificationForLaterTracking(userInfo: ["something": "some value"])
            let delivered = self.getRecordedNotifications()!
            expect(delivered.count).to(equal(1))
        }

        it("should record multiple notifications into user defaults") {
            let service = ExponeaNotificationService(appGroup: "mock-app-group")
            service.saveNotificationForLaterTracking(
                userInfo: ["attributes": ["campaign_name": "mock campaign name"]]
            )
            service.saveNotificationForLaterTracking(
                userInfo: ["attributes": ["campaign_name": "second mock campaign name"]]
            )
            service.saveNotificationForLaterTracking(
                userInfo: ["attributes": ["campaign_name": "third mock campaign name"]]
            )

            let delivered = self.getRecordedNotifications()!
            expect(delivered.count).to(equal(3))
            expect(ExponeaSDK.NotificationData.deserialize(from: delivered[0])?.campaignName).to(
                equal("mock campaign name")
            )
            expect(ExponeaSDK.NotificationData.deserialize(from: delivered[1])?.campaignName).to(
                equal("second mock campaign name")
            )
            expect(ExponeaSDK.NotificationData.deserialize(from: delivered[2])?.campaignName).to(
                equal("third mock campaign name")
            )
        }
    }
}

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
        describe("saving notifications for later") {
            it("should record notification into user defaults") {
                let service = ExponeaNotificationService(appGroup: "mock-app-group")
                service.saveNotificationForLaterTracking(
                    notification: NotificationData( attributes: ["campaign_name": .string("mock campaign name")])
                )

                let delivered = self.getRecordedNotifications()!
                expect(delivered.count).to(equal(1))
                let savedNotificationData = NotificationData.deserialize(from: delivered[0])
                expect(savedNotificationData?.campaignName).to(equal("mock campaign name"))
            }

            it("should record notification without tracking info into user defaults") {
                let service = ExponeaNotificationService(appGroup: "mock-app-group")
                service.saveNotificationForLaterTracking(
                    notification: NotificationData()
                )
                let delivered = self.getRecordedNotifications()!
                expect(delivered.count).to(equal(1))
            }

            it("should record multiple notifications into user defaults") {
                let service = ExponeaNotificationService(appGroup: "mock-app-group")
                service.saveNotificationForLaterTracking(
                    notification: NotificationData( attributes: ["campaign_name": .string("mock campaign name")])
                )
                service.saveNotificationForLaterTracking(
                    notification: NotificationData( attributes: ["campaign_name": .string("second mock campaign name")])
                )
                service.saveNotificationForLaterTracking(
                    notification: NotificationData( attributes: ["campaign_name": .string("third mock campaign name")])
                )

                let delivered = self.getRecordedNotifications()!
                expect(delivered.count).to(equal(3))
                expect(NotificationData.deserialize(from: delivered[0])?.campaignName).to(
                    equal("mock campaign name")
                )
                expect(NotificationData.deserialize(from: delivered[1])?.campaignName).to(
                    equal("second mock campaign name")
                )
                expect(NotificationData.deserialize(from: delivered[2])?.campaignName).to(
                    equal("third mock campaign name")
                )
            }
        }

        describe("processing") {
            let userInfo = try! JSONSerialization.jsonObject(
                with: PushNotificationsTestData().deliveredCustomActionsNotification.data(using: .utf8)!, options: []
            ) as? [AnyHashable: Any]
            let request = mock_notification_request(userInfo)

            it("should create content") {
                let service = ExponeaNotificationService(appGroup: "mock-app-group")
                waitUntil { done in
                    service.process(request: request!) { content in
                        expect(content.title).to(equal("Test push notification title"))
                        expect(content.body).to(equal("test push notification message"))
                        done()
                    }
                }
            }

            it("should save notification for later when unable to track") {
                let service = ExponeaNotificationService(appGroup: "mock-app-group")
                waitUntil { done in
                    service.process(request: request!) { _ in
                        let delivered = self.getRecordedNotifications()!
                        expect(delivered.count).to(equal(1))
                        done()
                    }
                }
            }

            it("should not save notification for later when tracking succeeds") {
                try! Configuration(
                    projectToken: "mock-project-token",
                    projectMapping: nil,
                    authorization: ExponeaSDK.Authorization.token("mock-token"),
                    baseUrl: nil,
                    appGroup: "mock-app-group",
                    defaultProperties: nil
                ).saveToUserDefaults()
                guard let userDefaults = UserDefaults(suiteName: "mock-app-group"),
                    let data = try? JSONEncoder().encode(["uuid": ExponeaSDK.JSONValue.string("mock-uuid")]) else {
                    return
                }
                userDefaults.set(data, forKey: Constants.General.lastKnownCustomerIds)
                NetworkStubbing.stubNetwork(forProjectToken: "mock-project-token", withStatusCode: 200)
                let service = ExponeaNotificationService(appGroup: "mock-app-group")
                waitUntil { done in
                    service.process(request: request!) { _ in
                        expect(self.getRecordedNotifications()).to(beNil())
                        done()
                    }
                }
            }

        }
    }
}

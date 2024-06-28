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

    private func getRecordedNotificationEvents() -> [Data]? {
        let userDefaults = UserDefaults(suiteName: "mock-app-group")!
        if let delivered = userDefaults.array(forKey: ExponeaSDK.Constants.General.deliveredPushEventUserDefaultsKey)
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
            
            it("should record notification event into user defaults") {
                let service = ExponeaNotificationService(appGroup: "mock-app-group")
                let notification = NotificationData( attributes: ["campaign_name": .string("mock campaign name")])
                let configuration = try! Configuration(
                    projectToken: "mock-project-token",
                    projectMapping: nil,
                    authorization: .token("mock-token"),
                    baseUrl: nil,
                    appGroup: "mock-app-group",
                    defaultProperties: nil
                )
                let events = DeliveredNotificationTracker.generateTrackingObjects(
                    configuration: configuration,
                    customerIds: ["cookie": "12345"],
                    notification: notification
                )
                service.saveNotificationEventsForLaterTracking(events)
                let delivered = self.getRecordedNotifications()
                expect(delivered).to(beNil())
                let deliveredEvents = self.getRecordedNotificationEvents()!
                expect(deliveredEvents.count).to(equal(1))
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

            it("should record multiple notification events into user defaults") {
                let service = ExponeaNotificationService(appGroup: "mock-app-group")
                let configuration = try! Configuration(
                    projectToken: "mock-project-token",
                    projectMapping: nil,
                    authorization: .token("mock-token"),
                    baseUrl: nil,
                    appGroup: "mock-app-group",
                    defaultProperties: nil
                )
                let customerIds = ["cookie": "1234"]
                service.saveNotificationEventsForLaterTracking(DeliveredNotificationTracker.generateTrackingObjects(
                    configuration: configuration,
                    customerIds: customerIds,
                    notification: NotificationData( attributes: ["campaign_name": .string("first mock campaign name")])
                ))
                service.saveNotificationEventsForLaterTracking(DeliveredNotificationTracker.generateTrackingObjects(
                    configuration: configuration,
                    customerIds: customerIds,
                    notification: NotificationData( attributes: ["campaign_name": .string("second mock campaign name")])
                ))
                service.saveNotificationEventsForLaterTracking(DeliveredNotificationTracker.generateTrackingObjects(
                    configuration: configuration,
                    customerIds: customerIds,
                    notification: NotificationData( attributes: ["campaign_name": .string("third mock campaign name")])
                ))
                let deliveredEvents = self.getRecordedNotificationEvents()!
                expect(deliveredEvents.count).to(equal(3))
                let event1 = EventTrackingObject.deserialize(from: deliveredEvents[0])
                expect(event1?.customerIds["cookie"]).to(equal("1234"))
                let campaignName1: String = event1?.dataTypes.properties["campaign_name"]?.unsafelyUnwrapped.jsonValue.rawValue as! String
                expect(campaignName1).to(equal("first mock campaign name"))
                let event2 = EventTrackingObject.deserialize(from: deliveredEvents[1])
                expect(event2?.customerIds["cookie"]).to(equal("1234"))
                let campaignName2: String = event2?.dataTypes.properties["campaign_name"]?.unsafelyUnwrapped.jsonValue.rawValue as! String
                expect(campaignName2).to(equal("second mock campaign name"))
                let event3 = EventTrackingObject.deserialize(from: deliveredEvents[2])
                expect(event3?.customerIds["cookie"]).to(equal("1234"))
                let campaignName3: String = event3?.dataTypes.properties["campaign_name"]?.unsafelyUnwrapped.jsonValue.rawValue as! String
                expect(campaignName3).to(equal("third mock campaign name"))
            }
        }

        describe("processing") {
            let userInfo = try! JSONSerialization.jsonObject(
                with: PushNotificationsTestData().deliveredCustomActionsNotification.data(using: .utf8)!, options: []
            ) as? [AnyHashable: Any]
            let request = mock_notification_request(userInfo)

            it("should create content") {
                let service = ExponeaNotificationService(appGroup: "mock-app-group")
                waitUntil(timeout: .seconds(5)) { done in
                    service.process(request: request!) { content in
                        expect(content.title).to(equal("Test push notification title"))
                        expect(content.body).to(equal("test push notification message"))
                        done()
                    }
                }
            }

            it("should save notification for later when unable to track") {
                let service = ExponeaNotificationService(appGroup: "mock-app-group")
                waitUntil(timeout: .seconds(5)) { done in
                    service.process(request: request!) { _ in
                        // for missing SDK conf, only raw NotifPayload should be stored
                        let delivered = self.getRecordedNotifications()!
                        expect(delivered.count).to(equal(1))
                        // for missing SDK conf, delivered events could not be created
                        let deliveredEvents = self.getRecordedNotificationEvents()
                        expect(deliveredEvents).to(beNil())
                        done()
                    }
                }
            }
            
            it("should not save notification events for later when tracking failed by network") {
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
                NetworkStubbing.stubNetwork(forProjectToken: "mock-project-token", withStatusCode: 500)
                let service = ExponeaNotificationService(appGroup: "mock-app-group")
                waitUntil(timeout: .seconds(5)) { done in
                    service.process(request: request!) { _ in
                        // for existing SDK conf, raw NotifPayloads are meaningless to be stored
                        expect(self.getRecordedNotifications()).to(beNil())
                        // for existing SDK conf, delivered events has to be created and stored
                        let deliveredEvents = self.getRecordedNotificationEvents()!
                        expect(deliveredEvents.count).to(equal(1))
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
                waitUntil(timeout: .seconds(5)) { done in
                    service.process(request: request!) { _ in
                        expect(self.getRecordedNotifications()).to(beNil())
                        expect(self.getRecordedNotificationEvents()).to(beNil())
                        done()
                    }
                }
            }

        }
    }
}

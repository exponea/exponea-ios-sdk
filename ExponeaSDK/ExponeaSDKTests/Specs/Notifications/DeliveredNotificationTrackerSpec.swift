//
//  DeliveredNotificationTrackerSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 10/03/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//
import Nimble
import Quick

@testable import ExponeaSDKNotifications
@testable import ExponeaSDKShared

final class DeliveredNotificationTrackerSpec: QuickSpec {
    override func spec() {
        describe("generating traking events") {
            it("should add notification data") {
                let configuration = try! Configuration(
                    projectToken: "mock-project-token",
                    projectMapping: nil,
                    authorization: .token("mock-token"),
                    baseUrl: nil,
                    appGroup: nil,
                    defaultProperties: nil
                )
                let notificationData = NotificationData(
                    attributes: ["campaign_id": .string("mock campaign id"),
                    "campaign_name": .string("mock campaign name"),
                    "action_id": .int(1234),
                    "action_name": .string("mock action name"),
                    "action_type": .string("mock action type"),
                    "campaign_policy": .string("mock campaign policy"),
                    "platform": .string("mock platform"),
                    "language": .string("mock language"),
                    "recipient": .string("mock recipient"),
                    "subject": .string("mock title")],
                    campaignData: CampaignData(source: "mock source", campaign: "mock campaign")
                )
                expect(
                    DeliveredNotificationTracker.generateTrackingObjects(
                        configuration: configuration,
                        customerIds: ["cookie": "mock-cookie"],
                        notification: notificationData
                    )
                ).to(equal([
                    EventTrackingObject(
                        exponeaProject: configuration.mainProject,
                        customerIds: ["cookie": "mock-cookie"],
                        eventType: "campaign",
                        timestamp: notificationData.timestamp,
                        dataTypes: [
                            .properties([
                                "action_id": .int(1234),
                                "recipient": .string("mock recipient"),
                                "subject": .string("mock title"),
                                "platform": .string("mock platform"),
                                "campaign_name": .string("mock campaign name"),
                                "status": .string("delivered"),
                                "language": .string("mock language"),
                                "campaign_id": .string("mock campaign id"),
                                "action_type": .string("mock action type"),
                                "campaign_policy": .string("mock campaign policy"),
                                "action_name": .string("mock action name"),
                                "utm_source": .string("mock source"),
                                "utm_campaign": .string("mock campaign")
                            ])
                        ]
                    )
                ]))
            }

            it("should add default properties from configuration") {
                let configuration = try! Configuration(
                    projectToken: "mock-project-token",
                    projectMapping: nil,
                    authorization: .token("mock-token"),
                    baseUrl: nil,
                    appGroup: nil,
                    defaultProperties: ["default-prop": "default-value"]
                )
                let notificationData = NotificationData()
                expect(
                    DeliveredNotificationTracker.generateTrackingObjects(
                        configuration: configuration,
                        customerIds: ["cookie": "mock-cookie"],
                        notification: notificationData
                    )
                ).to(equal([
                    EventTrackingObject(
                        exponeaProject: configuration.mainProject,
                        customerIds: ["cookie": "mock-cookie"],
                        eventType: "campaign",
                        timestamp: notificationData.timestamp,
                        dataTypes: [
                            .properties([
                                "status": .string("delivered"),
                                "default-prop": .string("default-value"),
                                "platform": .string("ios")
                            ])
                        ]
                    )
                ]))
            }

            it("should set event type based on notification data") {
                let configuration = try! Configuration(
                    projectToken: "mock-project-token",
                    projectMapping: nil,
                    authorization: .token("mock-token"),
                    baseUrl: nil,
                    appGroup: nil,
                    defaultProperties: nil
                )
                let notificationData = NotificationData(
                    attributes: ["event_type": .string("custom-event-type")]
                )
                expect(
                    DeliveredNotificationTracker.generateTrackingObjects(
                        configuration: configuration,
                        customerIds: ["cookie": "mock-cookie"],
                        notification: notificationData
                    )
                ).to(equal([
                    EventTrackingObject(
                        exponeaProject: configuration.mainProject,
                        customerIds: ["cookie": "mock-cookie"],
                        eventType: "custom-event-type",
                        timestamp: notificationData.timestamp,
                        dataTypes: [
                            .properties([
                                "status": .string("delivered"),
                                "platform": .string("ios")
                            ])
                        ]
                    )
                ]))
            }

            it("should generate events for project token mapping") {
                let configuration = try! Configuration(
                    projectToken: "mock-project-token",
                    projectMapping: [
                        .pushDelivered: [
                            ExponeaProject(
                                baseUrl: "https://other-mock-base-url.com",
                                projectToken: "other-mock-project-token",
                                authorization: .token("other-mock-token")
                            )
                        ]
                    ],
                    authorization: .token("mock-token"),
                    baseUrl: "https://mock-base-url.com",
                    appGroup: nil,
                    defaultProperties: nil
                )
                let notificationData = NotificationData()

                expect(
                    DeliveredNotificationTracker.generateTrackingObjects(
                        configuration: configuration,
                        customerIds: ["cookie": "mock-cookie"],
                        notification: notificationData
                    )
                ).to(equal([
                    EventTrackingObject(
                        exponeaProject: configuration.mainProject,
                        customerIds: ["cookie": "mock-cookie"],
                        eventType: "campaign",
                        timestamp: notificationData.timestamp,
                        dataTypes: [
                            .properties([
                                "status": .string("delivered"),
                                "platform": .string("ios")
                            ])
                        ]
                    ),
                    EventTrackingObject(
                        exponeaProject: ExponeaProject(
                            baseUrl: "https://other-mock-base-url.com",
                            projectToken: "other-mock-project-token",
                            authorization: .token("other-mock-token")
                        ),
                        customerIds: ["cookie": "mock-cookie"],
                        eventType: "campaign",
                        timestamp: notificationData.timestamp,
                        dataTypes: [
                            .properties([
                                "status": .string("delivered"),
                                "platform": .string("ios")
                            ])
                        ]
                    )
                ]))
            }
        }

        describe("initialization") {

            beforeEach {
                let defaults = UserDefaults(suiteName: "mock-app-group")!
                defaults.removeObject(forKey: Constants.General.lastKnownConfiguration)
                defaults.removeObject(forKey: Constants.General.lastKnownCustomerIds)
            }

            it("should throw without configuration in UserDefaults") {
                expect {
                    try DeliveredNotificationTracker(
                        appGroup: "mock-app-group",
                        notificationData: NotificationData()
                    )
                }.to(throwError(DeliveredNotificationTrackerError.configurationNotFound))
            }

            it("should throw without user ids in UserDefaults") {
                self.saveConfiguration()
                expect {
                    try DeliveredNotificationTracker(
                        appGroup: "mock-app-group",
                        notificationData: NotificationData()
                    )
                }.to(throwError(DeliveredNotificationTrackerError.customerIdsNotFound))
            }

            it("should initialize with both configuration and customer ids") {
                self.saveConfiguration()
                self.saveCustomerIds()
                do {
                    _ = try DeliveredNotificationTracker(
                        appGroup: "mock-app-group",
                        notificationData: NotificationData()
                    )
                } catch {
                    XCTFail("init should not throw error")
                }
            }
        }

        describe("tracking") {
            it("should track events and call success") {
                self.saveConfiguration()
                self.saveCustomerIds()
                let tracker = try! DeliveredNotificationTracker(
                    appGroup: "mock-app-group",
                    notificationData: NotificationData()
                )
                NetworkStubbing.stubNetwork(forProjectToken: "mock-project-token", withStatusCode: 200)
                waitUntil { done in
                    tracker.track(
                        onSuccess: {
                            done()
                        },
                        onFailure: {
                            XCTFail("Tracking should succeed")
                            done()
                        }
                    )
                }
            }

            it("should track events and call failure if any of requests fails") {
                self.saveConfiguration()
                self.saveCustomerIds()
                let tracker = try! DeliveredNotificationTracker(
                    appGroup: "mock-app-group",
                    notificationData: NotificationData()
                )
                NetworkStubbing.stubNetwork(forProjectToken: "mock-project-token", withStatusCode: 400)
                waitUntil { done in
                    tracker.track(
                        onSuccess: {
                            XCTFail("Tracking should fail")
                            done()
                        },
                        onFailure: {
                            done()
                        }
                    )
                }
            }
        }
    }

    func saveConfiguration() {
        try! Configuration(
            projectToken: "mock-project-token",
            projectMapping: nil,
            authorization: .token("mock-token"),
            baseUrl: nil,
            appGroup: "mock-app-group",
            defaultProperties: nil
        ).saveToUserDefaults()
    }

    func saveCustomerIds() {
        guard let userDefaults = UserDefaults(suiteName: "mock-app-group"),
            let data = try? JSONEncoder().encode(["uuid": JSONValue.string("mock-uuid")]) else {
            return
        }
        userDefaults.set(data, forKey: Constants.General.lastKnownCustomerIds)
    }
}

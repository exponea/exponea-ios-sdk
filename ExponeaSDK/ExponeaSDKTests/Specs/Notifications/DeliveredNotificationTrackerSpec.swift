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
@testable import ExponeaSDK

final class DeliveredNotificationTrackerSpec: QuickSpec {
    override func spec() {
        describe("generating traking events") {
            context("should add notification data") {
                let configurations = getTestConfigurations()
                for configuration in configurations {
                    it(configuration.integrationConfig.type.rawValue) {
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
                                        "state": .string("shown"),
                                        "language": .string("mock language"),
                                        "campaign_id": .string("mock campaign id"),
                                        "action_type": .string("mock action type"),
                                        "campaign_policy": .string("mock campaign policy"),
                                        "action_name": .string("mock action name"),
                                        "utm_source": .string("mock source"),
                                        "utm_campaign": .string("mock campaign"),
                                        "application_id": .string("default-application"),
                                        "device_id": .string(TelemetryUtility.getInstallId(userDefaults: Exponea.shared.userDefaults))
                                    ])
                                ]
                            )
                        ]))
                    }
                }
            }

            context("should add default properties from configuration") {
                let configurations = getTestConfigurations(defaultProperties: ["default-prop": "default-value"])
                for configuration in configurations {
                    it(configuration.integrationConfig.type.rawValue) {
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
                                        "state": .string("shown"),
                                        "default-prop": .string("default-value"),
                                        "platform": .string("ios"),
                                        "application_id": .string("default-application"),
                                        "device_id": .string(TelemetryUtility.getInstallId(userDefaults: Exponea.shared.userDefaults))
                                    ])
                                ]
                            )
                        ]))
                    }
                }
            }

            context("should set event type based on notification data") {
                let configurations = getTestConfigurations()
                for configuration in configurations {
                    it(configuration.integrationConfig.type.rawValue) {
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
                                        "state": .string("shown"),
                                        "platform": .string("ios"),
                                        "application_id": .string("default-application"),
                                        "device_id": .string(TelemetryUtility.getInstallId(userDefaults: Exponea.shared.userDefaults))
                                    ])
                                ]
                            )
                        ]))
                    }
                }
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
                                "state": .string("shown"),
                                "platform": .string("ios"),
                                "application_id": .string("default-application"),
                                "device_id": .string(TelemetryUtility.getInstallId(userDefaults: Exponea.shared.userDefaults))
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
                                "state": .string("shown"),
                                "platform": .string("ios"),
                                "application_id": .string("default-application"),
                                "device_id": .string(TelemetryUtility.getInstallId(userDefaults: Exponea.shared.userDefaults))
                            ])
                        ]
                    )
                ]))
            }
            
            it("should generate events for stream ID mapping") {
                let configuration = try! Configuration(
                    integrationConfig: Exponea.StreamSettings(
                        streamId: "mock-project-token",
                        baseUrl: "https://mock-base-url.com"
                    ),
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
                                "state": .string("shown"),
                                "platform": .string("ios"),
                                "application_id": .string("default-application"),
                                "device_id": .string(TelemetryUtility.getInstallId(userDefaults: Exponea.shared.userDefaults))
                            ])
                        ]
                    )
                ]))
            }
        }

        describe("initialization") {

            beforeEach {
                self.deleteConfigurationAndCustomerIds()
            }

            it("should throw without configuration in UserDefaults") {
                expect {
                    try DeliveredNotificationTracker(
                        appGroup: "mock-app-group",
                        notificationData: NotificationData()
                    )
                }.to(throwError(DeliveredNotificationTrackerError.configurationNotFound))
            }

            context("should throw without user ids in UserDefaults") {
                let configurations = getTestConfigurations(appGroup: "mock-app-group")
                for configuration in configurations {
                    it(configuration.integrationConfig.type.rawValue) {
                        configuration.saveToUserDefaults()
                        expect {
                            try DeliveredNotificationTracker(
                                appGroup: "mock-app-group",
                                notificationData: NotificationData()
                            )
                        }.to(throwError(DeliveredNotificationTrackerError.customerIdsNotFound))
                    }
                }
            }

            context("should initialize with both configuration and customer ids") {
                let configurations = getTestConfigurations(appGroup: "mock-app-group")
                for configuration in configurations {
                    it(configuration.integrationConfig.type.rawValue) {
                        configuration.saveToUserDefaults()
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
            }
        }

        describe("tracking") {
            beforeEach {
                self.deleteConfigurationAndCustomerIds()
            }
            
            afterEach {
                NetworkStubbing.unstubNetwork()
            }
            
            context("should track events and call success") {
                let configurations = getTestConfigurations(appGroup: "mock-app-group")
                for configuration in configurations {
                    it(configuration.integrationConfig.type.rawValue) {
                        configuration.saveToUserDefaults()
                        self.saveCustomerIds()
                        let tracker = try! DeliveredNotificationTracker(
                            appGroup: "mock-app-group",
                            notificationData: NotificationData()
                        )
                        NetworkStubbing.stubNetwork(forIntegrationType: configuration.integrationConfig.type, withStatusCode: 200)
                        waitUntil(timeout: .seconds(5)) { done in
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
                }
            }

            context("should track events and call failure if any of requests fails") {
                let configurations = getTestConfigurations(appGroup: "mock-app-group")
                for configuration in configurations {
                    it(configuration.integrationConfig.type.rawValue) {
                        configuration.saveToUserDefaults()
                        self.saveCustomerIds()
                        let tracker = try! DeliveredNotificationTracker(
                            appGroup: "mock-app-group",
                            notificationData: NotificationData()
                        )
                        NetworkStubbing.stubNetwork(forIntegrationType: configuration.integrationConfig.type, withStatusCode: 400)
                        waitUntil(timeout: .seconds(5)) { done in
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
        }
    }

    func getTestConfigurations(
        appGroup: String? = nil,
        defaultProperties: [String: JSONConvertible]? = nil
    ) -> [Configuration] {
        return [
            try! Configuration(
                projectToken: "mock-project-token",
                projectMapping: nil,
                authorization: .token("mock-token"),
                baseUrl: nil,
                appGroup: appGroup,
                defaultProperties: defaultProperties
            ),
            try! Configuration(
                integrationConfig: Exponea.ProjectSettings(
                    projectToken: "mock-project-token",
                    authorization: .token("mock-token"),
                    baseUrl: nil,
                    projectMapping: nil
                ),
                appGroup: appGroup,
                defaultProperties: defaultProperties
            ),
            try! Configuration(
                integrationConfig: Exponea.StreamSettings(
                    streamId: "mock-project-token",
                    baseUrl: nil
                ),
                appGroup: appGroup,
                defaultProperties: defaultProperties
            )
        ]
    }
    
    func deleteConfigurationAndCustomerIds() {
        let defaults = UserDefaults(suiteName: "mock-app-group")!
        defaults.removeObject(forKey: Constants.General.lastKnownConfiguration)
        defaults.removeObject(forKey: Constants.General.lastKnownCustomerIds)
    }

    func saveCustomerIds() {
        guard let userDefaults = UserDefaults(suiteName: "mock-app-group"),
            let data = try? JSONEncoder().encode(["uuid": JSONValue.string("mock-uuid")]) else {
            return
        }
        userDefaults.set(data, forKey: Constants.General.lastKnownCustomerIds)
    }
}

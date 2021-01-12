//
//  TelemetryUtilitySpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 18/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Quick
import Nimble

@testable import ExponeaSDK

final class TelemetryUtilitySpec: QuickSpec {
    override func spec() {
        describe("checking if exception stack trace is SDK related") {
            it("should return true for sdk related exception") {
                expect(
                    TelemetryUtility.isSDKRelated(
                        stackTrace: ["something", "something", "something Exponea something", "something"]
                    )
                ).to(beTrue())
                expect(
                    TelemetryUtility.isSDKRelated(
                        stackTrace: ["something", "something", "xxxexponeaxxx", "something"]
                    )
                ).to(beTrue())
            }
            it("should return true for sdk related exception") {
                expect(TelemetryUtility.isSDKRelated(stackTrace: ["something", "anything", "whatever"])).to(beFalse())
            }
        }
        describe("getting install id") {
            it("should generate install id") {
                let userDefaults = MockUserDefaults()
                expect(UUID(uuidString: TelemetryUtility.getInstallId(userDefaults: userDefaults))).notTo(beNil())
            }
            it("should store install id in user defaults") {
                let userDefaults = MockUserDefaults()
                let installId = TelemetryUtility.getInstallId(userDefaults: userDefaults)
                expect(TelemetryUtility.getInstallId(userDefaults: userDefaults)).to(equal(installId))
            }
        }
        describe("formatting configuration for tracking") {
            it("should format default configuration") {
                expect(
                    TelemetryUtility.formatConfigurationForTracking(
                        try! Configuration(
                            projectToken: "token",
                            authorization: .none,
                            baseUrl: Constants.Repository.baseUrl
                        )
                    )
                ).to(
                    equal([
                        "defaultProperties": "",
                        "automaticPushNotificationTracking": "true",
                        "baseUrl": "https://api.exponea.com [default]",
                        "appGroup": "nil",
                        "automaticSessionTracking": "true",
                        "tokenTrackFrequency": "onTokenChange [default]",
                        "flushEventMaxRetries": "5 [default]",
                        "projectMapping": "",
                        "projectToken": "[REDACTED]",
                        "sessionTimeout": "6.0 [default]"
                    ])
                )
            }
            it("should format non-default configuration") {
                let configuration = try! Configuration(
                    projectToken: "mock-project-token",
                    projectMapping: [EventType.banner: [
                        ExponeaProject(projectToken: "other-mock-project-token", authorization: .none)
                    ]],
                    authorization: .token("mock-authorization"),
                    baseUrl: "http://mock-base-url.com",
                    defaultProperties: ["default-property": "default-property-value"],
                    sessionTimeout: 12345,
                    automaticSessionTracking: false,
                    automaticPushNotificationTracking: false,
                    tokenTrackFrequency: TokenTrackFrequency.daily,
                    appGroup: "mock-app-group",
                    flushEventMaxRetries: 123
                )
                expect(TelemetryUtility.formatConfigurationForTracking(configuration)).to(
                    equal([
                        "tokenTrackFrequency": "daily",
                        "projectToken": "[REDACTED]",
                        "appGroup": "Optional(\"mock-app-group\")",
                        "flushEventMaxRetries": "123",
                        "defaultProperties": "[REDACTED]",
                        "baseUrl": "http://mock-base-url.com",
                        "sessionTimeout": "12345.0",
                        "automaticSessionTracking": "false",
                        "automaticPushNotificationTracking": "false",
                        "projectMapping": "[REDACTED]"
                    ])
                )

            }
        }
    }
}

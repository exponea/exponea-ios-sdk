//
//  TelemetryManagerSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 21/01/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Quick
import Nimble

@testable import ExponeaSDK

final class TelemetryManagerSpec: QuickSpec {
    var storage: MockTelemetryStorage!
    var upload: MockTelemetryUpload!
    var manager: TelemetryManager!
    override func spec() {
        beforeEach {
            IntegrationManager.shared.isStopped = false
            self.storage = MockTelemetryStorage()
            self.upload = MockTelemetryUpload()
            self.manager = TelemetryManager(
                userDefaults: MockUserDefaults(),
                userId: nil,
                storage: self.storage,
                upload: self.upload
            )
        }

        it("should report exception") {
            self.manager.report(
                exception: NSException(
                    name: NSExceptionName(rawValue: "name of test exception"),
                    reason: "reason for test exception",
                    userInfo: nil
                )
            )
            expect(self.upload.uploadedCrashLogs.count).to(equal(1))
            expect(self.upload.uploadedCrashLogs[0].isFatal).to(equal(false))
            expect(self.upload.uploadedCrashLogs[0].errorData.type).to(equal("name of test exception"))
            expect(self.upload.uploadedCrashLogs[0].errorData.message).to(equal("reason for test exception"))
        }

        it("should report sdk/swift error") {
            self.manager.report(
                error: DatabaseManagerError.objectDoesNotExist,
                stackTrace: ["something", "something else"]
            )
            expect(self.upload.uploadedCrashLogs.count).to(equal(1))
            expect(self.upload.uploadedCrashLogs[0].isFatal).to(equal(false))
            expect(self.upload.uploadedCrashLogs[0].errorData.type).to(equal("DatabaseManagerError"))
            expect(self.upload.uploadedCrashLogs[0].errorData.message)
                .to(equal("ExponeaSDK.DatabaseManagerError:5 Object does not exist."))
            expect(self.upload.uploadedCrashLogs[0].errorData.stackTrace).to(equal(["something", "something else"]))
        }

        it("should report NSError") {
            self.manager.report(
                error: NSError(
                    domain: "custom domain",
                    code: 123,
                    userInfo: [NSLocalizedDescriptionKey: "localized error"]
                ),
                stackTrace: ["something", "something else"]
            )
            expect(self.upload.uploadedCrashLogs.count).to(equal(1))
            expect(self.upload.uploadedCrashLogs[0].isFatal).to(equal(false))
            expect(self.upload.uploadedCrashLogs[0].errorData.type).to(equal("NSError"))
            expect(self.upload.uploadedCrashLogs[0].errorData.message)
                .to(equal("custom domain:123 localized error"))
            expect(self.upload.uploadedCrashLogs[0].errorData.stackTrace).to(equal(["something", "something else"]))
        }

        it("should report event") {
            self.manager.report(
                eventWithType: .fetchRecommendation,
                properties: ["property": "value", "other_property": "other_value"]
            )
            expect(self.upload.uploadedEvents.count).to(equal(1))
            expect(self.upload.uploadedEvents[0].name).to(equal("fetchRecommendation"))
            let appVersion = self.upload.uploadedEvents[0].properties["appVersion"] ?? ""
            expect(appVersion).notTo(beNil())
            expect(self.upload.uploadedEvents[0].properties["appName"]).to(equal("com.apple.dt.xctest.tool"))
            expect(self.upload.uploadedEvents[0].properties["sdkVersion"]).to(equal(Exponea.version))
            expect(self.upload.uploadedEvents[0].properties["appNameVersionSdkVersion"])
                .to(equal("com.apple.dt.xctest.tool - \(appVersion) - SDK \(Exponea.version)"))
            expect(self.upload.uploadedEvents[0].properties["appNameVersion"])
                .to(equal("com.apple.dt.xctest.tool - \(appVersion)"))
            expect(self.upload.uploadedEvents[0].properties["property"]).to(equal("value"))
            expect(self.upload.uploadedEvents[0].properties["other_property"]).to(equal("other_value"))
            expect(self.upload.uploadedEvents[0].properties.count).to(equal(7))
            Exponea.shared.stopIntegration()
            self.manager.report(
                eventWithType: .fetchRecommendation,
                properties: ["property": "value", "other_property": "other_value"]
            )
            expect(self.upload.uploadedEvents.isEmpty).to(beTrue())
            IntegrationManager.shared.isStopped = false
        }

        it("should report init event") {
            self.manager.report(
                initEventWithConfiguration: try! Configuration(
                    projectToken: "token",
                    authorization: .none,
                    baseUrl: Constants.Repository.baseUrl
                )
            )
            expect(self.upload.uploadedEvents.count).to(equal(1))
            expect(self.upload.uploadedEvents[0].name).to(equal("init"))
        }
    }
}

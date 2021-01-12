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
            expect(self.upload.uploadedEvents[0].properties)
                .to(equal([
                    "appVersion": "",
                    "appName": "com.apple.dt.xctest.tool",
                    "sdkVersion": Exponea.version,
                    "appNameVersionSdkVersion": "com.apple.dt.xctest.tool -  - SDK \(Exponea.version)",
                    "appNameVersion": "com.apple.dt.xctest.tool - ",
                    "property": "value",
                    "other_property": "other_value"
                ]))
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

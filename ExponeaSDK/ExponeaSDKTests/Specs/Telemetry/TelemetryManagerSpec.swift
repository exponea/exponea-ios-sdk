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
@testable import ExponeaSDKShared

final class TelemetryManagerSpec: QuickSpec {
    var storage: MockTelemetryStorage!
    var upload: MockTelemetryUpload!
    var manager: TelemetryManager!
    override func spec() {
        beforeEach {
            IntegrationManager.shared.isStopped = false
            let userDefaults = TelemetryUtility.getUserDefaults(appGroup: nil)
            let installId = TelemetryUtility.getInstallId(userDefaults: userDefaults)
            self.storage = MockTelemetryStorage()
            self.upload = MockTelemetryUpload(
                installId: installId, configGetter: {
                    Exponea.shared.configuration
                }
            )
            self.manager = TelemetryManager(
                appGroup: nil,
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
                ),
                thread: TelemetryUtility.getCurrentThreadInfo()
            )
            expect(self.upload.uploadedCrashLogs.count).to(equal(1))
            expect(self.upload.uploadedCrashLogs[0].isFatal).to(equal(false))
            expect(self.upload.uploadedCrashLogs[0].errorData.type).to(equal("name of test exception"))
            expect(self.upload.uploadedCrashLogs[0].errorData.message).to(equal("reason for test exception"))
        }

        it("should report sdk/swift error") {
            self.manager.report(
                error: DatabaseManagerError.objectDoesNotExist,
                stackTrace: [
                    "0   MyAppName                     0x0000000100b3d184 MyClass.myMethod() + 44",
                    "5   libdispatch.dylib             0x00000001b69af7f4 _dispatch_call_block_and_release + 24"
                ],
                thread: TelemetryUtility.getCurrentThreadInfo()
            )
            expect(self.upload.uploadedCrashLogs.count).to(equal(1))
            expect(self.upload.uploadedCrashLogs[0].isFatal).to(equal(false))
            expect(self.upload.uploadedCrashLogs[0].errorData.type).to(equal("DatabaseManagerError"))
            expect(self.upload.uploadedCrashLogs[0].errorData.message)
                .to(equal("ExponeaSDK.DatabaseManagerError:5 Object does not exist."))
            expect(self.upload.uploadedCrashLogs[0].errorData.stackTrace.count).to(equal(2))
        }

        it("should report NSError") {
            self.manager.report(
                error: NSError(
                    domain: "custom domain",
                    code: 123,
                    userInfo: [NSLocalizedDescriptionKey: "localized error"]
                ),
                stackTrace: [
                    "0   MyAppName                     0x0000000100b3d184 MyClass.myMethod() + 44",
                    "5   libdispatch.dylib             0x00000001b69af7f4 _dispatch_call_block_and_release + 24"
                ],
                thread: TelemetryUtility.getCurrentThreadInfo()
            )
            expect(self.upload.uploadedCrashLogs.count).to(equal(1))
            expect(self.upload.uploadedCrashLogs[0].isFatal).to(equal(false))
            expect(self.upload.uploadedCrashLogs[0].errorData.type).to(equal("NSError"))
            expect(self.upload.uploadedCrashLogs[0].errorData.message)
                .to(equal("custom domain:123 localized error"))
            expect(self.upload.uploadedCrashLogs[0].errorData.stackTrace.count).to(equal(2))
        }

        it("should report event") {
            self.manager.report(
                eventWithType: .recommendationsFetched,
                properties: ["property": "value", "other_property": "other_value"]
            )
            // basic properties from arguments
            expect(self.upload.uploadedEvents.count).to(equal(1))
            guard let uploadedEvent = self.upload.uploadedEvents.first else {
                XCTFail("Telemetry event has not been tracked")
                return
            }
            expect(uploadedEvent.name).to(equal("recommendationsFetched"))
            expect(uploadedEvent.properties["property"]).to(equal("value"))
            expect(uploadedEvent.properties["other_property"]).to(equal("other_value"))
            // environment properties added while uploading
            expect(self.upload.uploadedEnvelopes.count).to(equal(1))
            guard let uploadedEnvelope = self.upload.uploadedEnvelopes.first as? ExponeaSentryEnvelope<ExponeaSentryMessage> else {
                XCTFail("Telemetry event has not been transformed to envelop")
                return
            }
            let envelopeProperties = uploadedEnvelope.item.body.extra
            guard let appVersion = envelopeProperties["appVersion"] else {
                XCTFail("App version is missing from telemetry props")
                return
            }
            expect(envelopeProperties["appName"]).to(equal("com.apple.dt.xctest.tool"))
            expect(envelopeProperties["sdkVersion"]).to(equal(Exponea.version))
            expect(envelopeProperties["appNameVersionSdkVersion"])
                .to(equal("com.apple.dt.xctest.tool - \(appVersion) - SDK \(Exponea.version)"))
            expect(envelopeProperties["appNameVersion"])
                .to(equal("com.apple.dt.xctest.tool - \(appVersion)"))
            // envelope has to contain additional properties
            expect(envelopeProperties["property"]).to(equal("value"))
            expect(envelopeProperties["other_property"]).to(equal("other_value"))
        }
        
        it("should not report event for stopped SDK") {
            Exponea.shared.stopIntegration()
            self.manager.report(
                eventWithType: .recommendationsFetched,
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
            expect(self.upload.uploadedEvents[0].name).to(equal("sdkConfigure"))
        }
    }
}

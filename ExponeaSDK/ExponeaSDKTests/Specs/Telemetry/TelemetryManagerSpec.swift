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
    }
}

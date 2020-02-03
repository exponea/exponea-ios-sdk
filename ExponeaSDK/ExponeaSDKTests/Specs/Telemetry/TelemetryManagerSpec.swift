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

        it("should report error") {
            self.manager.report(
                error: DatabaseManagerError.objectDoesNotExist,
                stackTrace: ["something", "something else"]
            )
            expect(self.upload.uploadedCrashLogs.count).to(equal(1))
            expect(self.upload.uploadedCrashLogs[0].isFatal).to(equal(false))
            expect(self.upload.uploadedCrashLogs[0].errorData.type).to(equal("DatabaseManagerError"))
            expect(self.upload.uploadedCrashLogs[0].errorData.message).to(equal("Object does not exist."))
            expect(self.upload.uploadedCrashLogs[0].errorData.stackTrace).to(equal(["something", "something else"]))
        }
    }
}

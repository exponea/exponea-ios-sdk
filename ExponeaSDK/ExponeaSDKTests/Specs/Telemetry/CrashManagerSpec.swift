//
//  CrashManagerSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 18/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//
import Quick
import Nimble

@testable import ExponeaSDK

final class CrashManagerSpec: QuickSpec {
    class MockExceptionHandler {
        static var called = false

        static func handleException(_ exception: NSException) {
            called = true
        }
    }

    func getRaisedException() -> NSException {
        return objc_tryCatch {
            NSException(
                name: NSExceptionName(rawValue: "mock exception name"),
                reason: "mock reason",
                userInfo: nil
            ).raise()
        }!
    }

    func getMockCrashLog() -> CrashLog {
        return CrashLog(exception: getRaisedException(), fatal: true, launchDate: Date(), runId: "mock_run_id")
    }

    override func spec() {
        var storage: MockTelemetryStorage!
        var upload: MockTelemetryUpload!

        beforeEach {
            storage = MockTelemetryStorage()
            upload = MockTelemetryUpload()
            MockExceptionHandler.called = false
            NSSetUncaughtExceptionHandler(nil)
        }

        it("should listen to uncaught exceptions") {
            let crashManager = CrashManager(storage: storage, upload: upload, launchDate: Date(), runId: "mock_run_id")
            crashManager.start()
            expect(NSGetUncaughtExceptionHandler()).notTo(beNil())
        }

        it("should call original uncaught exceptions handler") {
            NSSetUncaughtExceptionHandler({ MockExceptionHandler.handleException($0) })
            let crashManager = CrashManager(storage: storage, upload: upload, launchDate: Date(), runId: "mock_run_id")
            crashManager.start()
            NSGetUncaughtExceptionHandler()?(self.getRaisedException())
            expect(MockExceptionHandler.called).to(beTrue())
        }

        it("should save uncaught exception") {
            let crashManager = CrashManager(storage: storage, upload: upload, launchDate: Date(), runId: "mock_run_id")
            crashManager.start()
            NSGetUncaughtExceptionHandler()?(self.getRaisedException())
            expect(storage.getAllCrashLogs().count).to(equal(1))
            expect(storage.getAllCrashLogs()[0].errorData.type).to(equal("mock exception name"))
            expect(storage.getAllCrashLogs()[0].errorData.message).to(equal("mock reason"))
        }

        it("should upload crash logs") {
            let crashLog = self.getMockCrashLog()
            storage.saveCrashLog(crashLog)
            let crashManager = CrashManager(storage: storage, upload: upload, launchDate: Date(), runId: "mock_run_id")
            crashManager.start()
            expect(upload.uploadedCrashLogs.count).to(equal(1))
        }

        it("should delete crash log once uploaded") {
            let crashLog = self.getMockCrashLog()
            storage.saveCrashLog(crashLog)
            let crashManager = CrashManager(storage: storage, upload: upload, launchDate: Date(), runId: "mock_run_id")
            crashManager.start()
            expect(storage.getAllCrashLogs().count).to(equal(0))
        }

        it("should not delete crash log when upload fails") {
            let crashLog = self.getMockCrashLog()
            storage.saveCrashLog(crashLog)
            let crashManager = CrashManager(storage: storage, upload: upload, launchDate: Date(), runId: "mock_run_id")
            upload.result = false
            crashManager.start()
            expect(storage.getAllCrashLogs().count).to(equal(1))
        }
    }
}

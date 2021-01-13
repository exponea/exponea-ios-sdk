//
//  CrashManagerSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 18/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//
import Quick
import Nimble
import ExponeaSDKObjC

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

    func getMockCrashLog(date: Date? = nil) -> CrashLog {
        return CrashLog(
            exception: getRaisedException(),
            fatal: true,
            date: date ?? Date(),
            launchDate: Date(),
            runId: "mock_run_id"
        )
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

        it("should upload caught exception") {
            let crashManager = CrashManager(storage: storage, upload: upload, launchDate: Date(), runId: "mock_run_id")
            upload.result = true
            crashManager.caughtErrorHandler(ExponeaError.unknownError("error"), stackTrace: [])
            expect(storage.getAllCrashLogs().count).to(equal(0))
            expect(upload.uploadedCrashLogs.count).to(equal(1))
        }

        it("should save caught exception if upload fails") {
            let crashManager = CrashManager(storage: storage, upload: upload, launchDate: Date(), runId: "mock_run_id")
            upload.result = false
            crashManager.caughtErrorHandler(ExponeaError.unknownError("error"), stackTrace: [])
            expect(storage.getAllCrashLogs().count).to(equal(1))
            expect(upload.uploadedCrashLogs.count).to(equal(1))
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

        it("should delete old crash logs instead of uploading") {
            var crashLog = self.getMockCrashLog(date: Date())
            storage.saveCrashLog(crashLog)
            crashLog = self.getMockCrashLog(date: Date().addingTimeInterval(-60 * 60 * 24 * 16)) // 16 days ago
            storage.saveCrashLog(crashLog)
            crashLog = self.getMockCrashLog(date: Date().addingTimeInterval(-60 * 60 * 24 * 10)) // 10 days ago
            storage.saveCrashLog(crashLog)
            let crashManager = CrashManager(storage: storage, upload: upload, launchDate: Date(), runId: "mock_run_id")
            crashManager.start()
            expect(storage.getAllCrashLogs().count).to(equal(0))
            expect(upload.uploadedCrashLogs.count).to(equal(2))
        }

        it("should get empty logs") {
            let crashManager = CrashManager(storage: storage, upload: upload, launchDate: Date(), runId: "mock_run_id")
            expect(crashManager.getLogs()).to(beEmpty())
        }

        it("should save and get logs") {
            let crashManager = CrashManager(storage: storage, upload: upload, launchDate: Date(), runId: "mock_run_id")
            crashManager.reportLog("log1")
            crashManager.reportLog("log2")
            crashManager.reportLog("log3")
            expect(crashManager.getLogs()).to(equal(["log1", "log2", "log3"]))
        }

        it("should append logs to crashlogs") {
            let crashManager = CrashManager(storage: storage, upload: upload, launchDate: Date(), runId: "mock_run_id")
            crashManager.reportLog("log1")
            crashManager.reportLog("log2")
            crashManager.reportLog("log3")
            crashManager.caughtErrorHandler(ExponeaError.notConfigured, stackTrace: ["stack trace element"])
            expect(upload.uploadedCrashLogs.count).to(equal(1))
            expect(upload.uploadedCrashLogs[0].logs).to(equal(["log1", "log2", "log3"]))
        }

        it("should hook to logger logs") {
            let crashManager = CrashManager(storage: storage, upload: upload, launchDate: Date(), runId: "mock_run_id")
            crashManager.start()
            expect(crashManager.getLogs()).to(beEmpty())
            Exponea.logger.log(.error, message: "Logging test message")
            expect(crashManager.getLogs()).notTo(beEmpty())
        }

        it("should report logs from multiple threads") {
            let crashManager = CrashManager(storage: storage, upload: upload, launchDate: Date(), runId: "mock_run_id")
            waitUntil { done in
                let group = DispatchGroup()
                for _ in 0..<100 {
                    group.enter()
                    DispatchQueue.global(qos: .background).async {
                        crashManager.reportLog("mock-message")
                        group.leave()
                    }
                }
                group.notify(queue: .main, execute: done)
            }
        }
    }
}

//
//  FileTelemetryStorageSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 15/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//
import Quick
import Nimble

@testable import ExponeaSDK

final class FileTelemetryStorageSpec: QuickSpec {
    let mockException = NSException()

    func getMockCrashLog() -> CrashLog {
        return CrashLog(
            exception: self.mockException,
            fatal: true,
            date: Date(),
            launchDate: Date(),
            runId: "mock_run_id"
        )
    }

    override func spec() {
        beforeEach {
            let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            let directoryContents = try? FileManager.default.contentsOfDirectory(
                at: cacheURL,
                includingPropertiesForKeys: nil,
                options: []
            )
            directoryContents?.forEach { url in
                try? FileManager.default.removeItem(at: url)
            }
        }

        it("should return empty result when no logs are stored") {
            let storage = FileTelemetryStorage()
            expect(storage.getAllCrashLogs()).to(equal([]))
        }

        it("should not fail deleting crashlog that's not saved") {
            let storage = FileTelemetryStorage()
            storage.deleteCrashLog(self.getMockCrashLog())
        }

        it("should save-get-delete crashlog") {
            let storage = FileTelemetryStorage()
            let crashLog = self.getMockCrashLog()
            storage.saveCrashLog(crashLog)
            let crashLogs = storage.getAllCrashLogs()
            expect(crashLogs.count).to(equal(1))
            expect(crashLogs[0]).to(equal(crashLog))
            storage.deleteCrashLog(crashLogs[0])
            expect(storage.getAllCrashLogs()).to(equal([]))
        }

        it("should sort crashlogs") {
            let storage = FileTelemetryStorage()
            let crashLog1 = self.getMockCrashLog()
            usleep(5 * 1000)
            let crashLog2 = self.getMockCrashLog()
            usleep(5 * 1000)
            let crashLog3 = self.getMockCrashLog()
            storage.saveCrashLog(crashLog2)
            storage.saveCrashLog(crashLog3)
            storage.saveCrashLog(crashLog1)
            let crashLogs = storage.getAllCrashLogs()
            expect(crashLogs.count).to(equal(3))
            expect(crashLogs[0].timestamp).to(beLessThan(crashLogs[1].timestamp))
            expect(crashLogs[1].timestamp).to(beLessThan(crashLogs[2].timestamp))
        }

        it("should filter crash logs when loading files") {
            let storage = FileTelemetryStorage()
            let crashLog = self.getMockCrashLog()
            storage.saveCrashLog(crashLog)
            let dir = storage.makeCacheDirectory()!
            try! "test".write(to: dir.appendingPathComponent("some_other_file"), atomically: false, encoding: .utf8)
            expect(storage.getAllCrashLogs()).to(equal([crashLog]))
        }

        it("should skip and delete files with corrupt data when loading files") {
            let storage = FileTelemetryStorage()
            let crashLog = self.getMockCrashLog()
            storage.saveCrashLog(crashLog)
            try! "{ \"corruptData\": ".write(to: storage.getFileURL(crashLog)!, atomically: false, encoding: .utf8)
            expect(storage.getAllCrashLogs()).to(equal([]))
            expect(FileManager.default.fileExists(atPath: storage.getFileURL(crashLog)!.absoluteString)).to(beFalse())
        }
    }
}

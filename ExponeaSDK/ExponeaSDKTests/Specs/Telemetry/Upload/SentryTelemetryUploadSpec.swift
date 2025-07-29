//
//  SentryTelemetryUploadSpec.swift
//  ExponeaSDKTests
//
//  Created by Adam Mihalik on 10/07/2025.
//  Copyright © 2025 Exponea. All rights reserved.
//

import Quick
import Nimble
import Mockingjay
import ExponeaSDKObjC

@testable import ExponeaSDK
@testable import ExponeaSDKShared

final class SentryTelemetryUploadSpec: QuickSpec {
    var networkRequests: [URLRequest] = []

    func getRaisedException() -> NSException {
        return objc_tryCatch {
            NSException(
                name: NSExceptionName(rawValue: "name of test exception"),
                reason: "reason for test exception",
                userInfo: nil
            ).raise()
        }!
    }

    func stubNetwork(statusCode: Int) {
        MockingjayProtocol.addStub(
            matcher: { _ in return true },
            builder: { urlRequest in
                self.networkRequests.append(urlRequest)
                let stubResponse = HTTPURLResponse(
                    url: URL(safeString: "mock-url")!,
                    statusCode: statusCode,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return Response.success(stubResponse, .content("mock-response".data(using: String.Encoding.utf8)!))
            }
        )
    }

    func unstubNetwork() {
        MockingjayProtocol.removeAllStubs()
    }

    override func spec() {
        var upload: SentryTelemetryUpload!
        beforeEach {
            IntegrationManager.shared.isStopped = false
            upload = SentryTelemetryUpload(installId: UUID().uuidString) {
                try? Configuration(projectToken: "mock-token")
            }
            self.stubNetwork(statusCode: 200)
        }
        afterEach {
            self.unstubNetwork()
            self.networkRequests = []
        }
        context("processing error logs") {
            it("should format fatal crashlog") {
                let crashLog = CrashLog(
                    exception: self.getRaisedException(),
                    fatal: true,
                    date: Date(),
                    launchDate: Date(),
                    runId: "mock-run-id",
                    thread: TelemetryUtility.getCurrentThreadInfo()
                )
                let errorReport = upload.buildEnvelope(crashLog: crashLog)
                expect(errorReport.item.body.level).to(equal("fatal"))
                expect(errorReport.item.body.exception.values.first!.type).to(equal("name of test exception"))
                expect(errorReport.item.body.exception.values.first!.value).to(equal("reason for test exception"))
            }
            it("should format non-fatal crashlog") {
                let crashLog = CrashLog(
                    exception: self.getRaisedException(),
                    fatal: false,
                    date: Date(),
                    launchDate: Date(),
                    runId: "mock-run-id",
                    thread: TelemetryUtility.getCurrentThreadInfo()
                )
                let errorReport = upload.buildEnvelope(crashLog: crashLog)
                expect(errorReport.item.body.level).to(equal("error"))
                expect(errorReport.item.body.exception.values.first!.type).to(equal("name of test exception"))
                expect(errorReport.item.body.exception.values.first!.value).to(equal("reason for test exception"))
            }

            it("should format error attachment") {
                let crashLog = CrashLog(
                    exception: self.getRaisedException(),
                    fatal: false,
                    date: Date(),
                    launchDate: Date(),
                    runId: "mock-run-id",
                    logs: ["log1", "log2", "log3"],
                    thread: TelemetryUtility.getCurrentThreadInfo()
                )
                let errorReport = upload.buildEnvelope(crashLog: crashLog)
                expect(errorReport.item.body.exception.values.first!.type).to(equal("name of test exception"))
                expect(errorReport.item.body.exception.values.first!.value).to(equal("reason for test exception"))
            }

            it("should successfully upload error log") {
                self.stubNetwork(statusCode: 200)
                let crashLog = CrashLog(
                    exception: self.getRaisedException(),
                    fatal: true,
                    date: Date(),
                    launchDate: Date(),
                    runId: "mock-run-id",
                    thread: TelemetryUtility.getCurrentThreadInfo()
                )
                waitUntil(timeout: .seconds(5)) { done in
                    upload.upload(crashLog: crashLog) { result in
                        expect(result).to(beTrue())
                        done()
                    }
                }
            }

            it("should fail to upload error log on non-200 status code") {
                self.stubNetwork(statusCode: 404)
                let crashLog = CrashLog(
                    exception: self.getRaisedException(),
                    fatal: true,
                    date: Date(),
                    launchDate: Date(),
                    runId: "mock-run-id",
                    thread: TelemetryUtility.getCurrentThreadInfo()
                )
                waitUntil(timeout: .seconds(5)) { done in
                    upload.upload(crashLog: crashLog) { result in
                        expect(result).to(beFalse())
                        done()
                    }
                }
            }

            it("should successfully upload event log") {
                self.stubNetwork(statusCode: 200)
                waitUntil(timeout: .seconds(5)) { done in
                    upload.upload(eventLog: EventLog(
                        name: "mock-event-name",
                        runId: "mock-run-id",
                        properties: ["mock-property": "value"]
                    )) { result in
                        expect(result).to(beTrue())
                        done()
                    }
                }
            }

            it("should fail to upload event log on non-200 status code") {
                self.stubNetwork(statusCode: 404)
                waitUntil(timeout: .seconds(5)) { done in
                    upload.upload(eventLog: EventLog(
                        name: "mock-event-name",
                        runId: "mock-run-id",
                        properties: ["mock-property": "value"]
                    )) { result in
                        expect(result).to(beFalse())
                        done()
                    }
                }
            }
        }
    }
}

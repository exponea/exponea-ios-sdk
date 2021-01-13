//
//  VSAppCenterTelemetryUploadSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 17/01/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//
import Quick
import Nimble
import Mockingjay
import ExponeaSDKObjC

@testable import ExponeaSDK

final class VSAppCenterTelemetryUploadSpec: QuickSpec {
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
                    url: URL(string: "mock-url")!,
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
        var upload: VSAppCenterTelemetryUpload!
        beforeEach {
            upload = VSAppCenterTelemetryUpload(
                installId: UUID().uuidString,
                userId: "mock_user_id",
                runId: "mock_run_id"
            )
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
                    runId: "mock-run-id"
                )
                if case .fatalError(let errorReport) = upload.getVSAppCenterAPIErrorReport(crashLog) {
                    expect(errorReport.fatal).to(equal(true))
                    expect(errorReport.exception.type).to(equal("name of test exception"))
                    expect(errorReport.exception.message).to(equal("reason for test exception"))
                } else {
                    XCTFail("expected fatal error")
                }
            }
            it("should format non-fatal crashlog") {
                let crashLog = CrashLog(
                    exception: self.getRaisedException(),
                    fatal: false,
                    date: Date(),
                    launchDate: Date(),
                    runId: "mock-run-id"
                )
                if case .nonFatalError(let errorReport) = upload.getVSAppCenterAPIErrorReport(crashLog) {
                    expect(errorReport.fatal).to(equal(false))
                    expect(errorReport.exception.type).to(equal("name of test exception"))
                    expect(errorReport.exception.message).to(equal("reason for test exception"))
                } else {
                    XCTFail("expected non-fatal error")
                }
            }

            it("should format error attachment") {
                let crashLog = CrashLog(
                    exception: self.getRaisedException(),
                    fatal: false,
                    date: Date(),
                    launchDate: Date(),
                    runId: "mock-run-id",
                    logs: ["log1", "log2", "log3"]
                )
                if case .errorAttachment(let errorAttachment) = upload.getVSAppCenterAPIErrorAttachment(crashLog) {
                    expect(errorAttachment.errorId).to(equal(crashLog.id))
                    expect(errorAttachment.data).to(equal("bG9nMQpsb2cyCmxvZzM="))
                } else {
                    XCTFail("expected error attachment")
                }

            }

            it("should successfully upload error log") {
                self.stubNetwork(statusCode: 200)
                let crashLog = CrashLog(
                    exception: self.getRaisedException(),
                    fatal: true,
                    date: Date(),
                    launchDate: Date(),
                    runId: "mock-run-id"
                )
                waitUntil { done in
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
                    runId: "mock-run-id"
                )
                waitUntil { done in
                    upload.upload(crashLog: crashLog) { result in
                        expect(result).to(beFalse())
                        done()
                    }
                }
            }

            it("should successfully upload event log") {
                self.stubNetwork(statusCode: 200)
                waitUntil { done in
                    upload.upload(eventWithName: "mock-event-name", properties: ["mock-property": "value"]) { result in
                        expect(result).to(beTrue())
                        done()
                    }
                }
            }

            it("should fail to upload event log on non-200 status code") {
                self.stubNetwork(statusCode: 404)
                waitUntil { done in
                    upload.upload(eventWithName: "mock-event-name", properties: ["mock-property": "value"]) { result in
                        expect(result).to(beFalse())
                        done()
                    }
                }
            }
        }
    }
}

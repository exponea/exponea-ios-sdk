//
//  LoggerSpec.swift
//  ExponeaSDKTests
//
//  Created by Dominik Hádl on 11/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import XCTest
import Quick
import Nimble

@testable import ExponeaSDK

class LoggerSpec: QuickSpec {

    override func spec() {
        describe("A Logger") {

            context("after being initialized", {
                let logger = Logger()

                it("should have default log level", closure: {
                    expect(logger.logLevel).to(equal(LogLevel.warning))
                })

                it("should print errors", closure: {
                    expect(logger.log(.error, message: "test")).to(beTrue())
                })

                it("should not print verbose info", closure: {
                    expect(logger.log(.verbose, message: "test")).toNot(beTrue())
                })

                it("should be able to extract valid source file from path", closure: {
                    let filePath = "file://path/to/a/testFile"
                    expect(logger.sourceFile(from: filePath)).to(match("testFile"))
                })

                it("should be able to extract source file from already extracted file path", closure: {
                    let filePath = "testFile"
                    expect(logger.sourceFile(from: filePath)).to(match(filePath))
                })
            })

            context("after changing the log level", {
                let logger = Logger()
                logger.logLevel = .error

                it("should update the log level", closure: {
                    expect(logger.logLevel).to(equal(LogLevel.error))
                })

                it("should not log message with ignored level", closure: {
                    expect(logger.log(.warning, message: "test")).toNot(beTrue())
                })
            })

            describe("log hooks") {
                it("should add and call log hooks") {
                    let logger = Logger()
                    var hookCalled = false
                    let hook = { (_ : String) in
                        hookCalled = true
                    }
                    _ = logger.addLogHook(hook)
                    logger.log(.warning, message: "test message")
                    expect(hookCalled).to(beTrue())
                }

                it("should remove log hooks") {
                    let logger = Logger()
                    var hookCalled = false
                    let hook = { (_ : String) in
                        hookCalled = true
                    }
                    let hookId = logger.addLogHook(hook)
                    logger.removeLogHook(with: hookId)
                    logger.log(.warning, message: "test message")
                    expect(hookCalled).to(beFalse())
                }

                it("should handle concurrent log() calls without crashing") {
                    let logger = Logger()
                    logger.logLevel = .verbose
                    let iterations = 500
                    let queueCount = 4
                    let expectation = QuickSpec.current.expectation(
                        description: "concurrent log() operations"
                    )
                    expectation.expectedFulfillmentCount = queueCount

                    for q in 0..<queueCount {
                        DispatchQueue.global().async {
                            for i in 0..<iterations {
                                logger.log(.verbose, message: "thread \(q) message \(i)")
                            }
                            expectation.fulfill()
                        }
                    }

                    QuickSpec.current.waitForExpectations(timeout: 10)
                }

                it("should handle concurrent hook add/remove and logMessage without crashing") {
                    let logger = Logger()
                    logger.logLevel = .verbose
                    let iterations = 1000
                    let expectation = QuickSpec.current.expectation(
                        description: "concurrent logger operations"
                    )
                    expectation.expectedFulfillmentCount = 3

                    DispatchQueue.global(qos: .userInitiated).async {
                        for i in 0..<iterations {
                            logger.log(.verbose, message: "concurrent message \(i)")
                        }
                        expectation.fulfill()
                    }

                    DispatchQueue.global(qos: .utility).async {
                        var hookIds: [String] = []
                        for _ in 0..<iterations {
                            let hookId = logger.addLogHook { _ in }
                            hookIds.append(hookId)
                        }
                        for hookId in hookIds {
                            logger.removeLogHook(with: hookId)
                        }
                        expectation.fulfill()
                    }

                    DispatchQueue.global(qos: .background).async {
                        for _ in 0..<iterations {
                            logger.logLevel = .verbose
                            _ = logger.logLevel
                            logger.logLevel = .warning
                        }
                        expectation.fulfill()
                    }

                    QuickSpec.current.waitForExpectations(timeout: 10)
                    expect(logger.logLevel).to(equal(.warning))
                }
            }
        }
    }
}

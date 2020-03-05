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
            }
        }
    }
}

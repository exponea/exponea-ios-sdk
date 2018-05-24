//
//  LogLevelSpec.swift
//  ExponeaSDKTests
//
//  Created by Dominik Hádl on 11/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import XCTest
import Quick
import Nimble

@testable import ExponeaSDK

class LogLevelSpec: QuickSpec {

    override func spec() {
        describe("A error log level") {
            let level = LogLevel.error

            it("should not be less important than warning", closure: {
                expect(level.rawValue).toNot(beGreaterThan(LogLevel.warning.rawValue))
            })

            it("should not be less important than verbose", closure: {
                expect(level.rawValue).toNot(beGreaterThan(LogLevel.verbose.rawValue))
            })

            it("should have a name", closure: {
                expect(level.name).to(equal("❗️ ERROR"))
            })
        }

        describe("A warning log level") {
            let level = LogLevel.warning
            it("should be less important than error", closure: {
                expect(level.rawValue).to(beGreaterThan(LogLevel.error.rawValue))
            })

            it("should not be less important than verbose", closure: {
                expect(level.rawValue).toNot(beGreaterThan(LogLevel.verbose.rawValue))
            })

            it("should have a name", closure: {
                expect(level.name).to(equal("⚠️ WARNING"))
            })
        }

        describe("A verbose log level") {
            let level = LogLevel.verbose

            it("should be less important than error", closure: {
                expect(level.rawValue).to(beGreaterThan(LogLevel.error.rawValue))
            })

            it("should not be less important than verbose", closure: {
                expect(level.rawValue).toNot(beGreaterThan(LogLevel.verbose.rawValue))
            })

            it("should have a name", closure: {
                expect(level.name).to(equal("ℹ️ VERBOSE"))
            })
        }

        describe("A none log level") {
            let level = LogLevel.none

            it("should be less important than error", closure: {
                expect(level.rawValue).toNot(beGreaterThan(LogLevel.error.rawValue))
            })

            it("should be less important than warning", closure: {
                expect(level.rawValue).toNot(beGreaterThan(LogLevel.warning.rawValue))
            })

            it("should be less important than verbose", closure: {
                expect(level.rawValue).toNot(beGreaterThan(LogLevel.verbose.rawValue))
            })

            it("should have empty name", closure: {
                expect(level.name).to(beEmpty())
            })
        }
    }

}

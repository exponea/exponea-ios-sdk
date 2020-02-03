//
//  TelemetryUtilitySpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 18/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Quick
import Nimble

@testable import ExponeaSDK

final class TelemetryUtilitySpec: QuickSpec {
    override func spec() {
        describe("checking if exception stack trace is SDK related") {
            it("should return true for sdk related exception") {
                expect(
                    TelemetryUtility.isSDKRelated(
                        stackTrace: ["something", "something", "something Exponea something", "something"]
                    )
                ).to(beTrue())
                expect(
                    TelemetryUtility.isSDKRelated(
                        stackTrace: ["something", "something", "xxxexponeaxxx", "something"]
                    )
                ).to(beTrue())
            }
            it("should return true for sdk related exception") {
                expect(TelemetryUtility.isSDKRelated(stackTrace: ["something", "anything", "whatever"])).to(beFalse())
            }
        }
        describe("getting install id") {
            it("should generate install id") {
                let userDefaults = MockUserDefaults()
                expect(UUID(uuidString: TelemetryUtility.getInstallId(userDefaults: userDefaults))).notTo(beNil())
            }
            it("should store install id in user defaults") {
                let userDefaults = MockUserDefaults()
                let installId = TelemetryUtility.getInstallId(userDefaults: userDefaults)
                expect(TelemetryUtility.getInstallId(userDefaults: userDefaults)).to(equal(installId))
            }
        }
    }
}

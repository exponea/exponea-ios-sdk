//
//  ConfigurationSpec.swift
//  ExponeaSDKTests
//
//  Created by Dominik Hádl on 18/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class ConfigurationSpec: QuickSpec {
    override func spec() {
        describe("A Configuration") {
            context("that is parsed from valid plist", {
                it("should get created correctly with project token", closure: {
                    do {
                        let bundle = Bundle(for: ConfigurationSpec.self)
                        let filePath = bundle.path(forResource: "config_valid", ofType: "plist")
                        let fileUrl = URL(fileURLWithPath: filePath ?? "")
                        let data = try Data(contentsOf: fileUrl)
                        let config = try PropertyListDecoder().decode(Configuration.self, from: data)

                        expect(config.projectToken).to(equal("testToken"))
                        expect(config.projectMapping).to(beNil())
                    } catch {
                        XCTFail("Failed to load test data - \(error)")
                    }
                })

                it("should get created correctly with project mapping", closure: {
                    do {
                        let bundle = Bundle(for: ConfigurationSpec.self)
                        let filePath = bundle.path(forResource: "config_valid2", ofType: "plist")
                        let fileUrl = URL(fileURLWithPath: filePath ?? "")
                        let data = try Data(contentsOf: fileUrl)
                        let config = try PropertyListDecoder().decode(Configuration.self, from: data)

                        let mapping: [EventType: [String]] = [
                            .install: ["testToken1"],
                            .trackEvent: ["testToken2", "testToken3"],
                            .payment: ["paymentToken"]
                            ]

                        expect(config.projectMapping).to(equal(mapping))
                        expect(config.projectToken).to(beNil())
                    } catch {
                        XCTFail("Failed to load test data - \(error)")
                    }
                })
            })

            context("that is parsed from an invalid plist", {
                it("should fail to get created", closure: {

                })
            })

        }
    }
}

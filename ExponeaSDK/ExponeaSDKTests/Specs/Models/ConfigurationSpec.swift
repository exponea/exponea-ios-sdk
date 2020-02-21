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
            context("validation") {
                it("should pass valid configuration") {
                    expect {
                        try Configuration(
                            projectToken: "token",
                            authorization: Authorization.none,
                            baseUrl: "baseUrl"
                        )
                    }.notTo(beNil())
                }
                it("should throw on invalid baseUrl") {
                    do {
                        _ = try Configuration(
                            projectToken: "token",
                            authorization: Authorization.none,
                            baseUrl: "string with spaces"
                        )
                        XCTFail("Error not thrown")
                    } catch {
                        expect(error.localizedDescription).to(equal("Base url provided is not a valid url."))
                    }
                }
                it("should throw on invalid project token") {
                    do {
                        _ = try Configuration(
                            projectToken: "something else than project token",
                            authorization: Authorization.none,
                            baseUrl: "baseUrl"
                        )
                        XCTFail("Error not thrown")
                    } catch {
                        let expectedErrorMessage = "Project token provided is not valid. "
                            + "Only alphanumeric symbols and dashes are allowed in project token."
                        expect(error.localizedDescription).to(equal(expectedErrorMessage))
                    }
                }
                it("should throw on invalid project token in project mapping") {
                    do {
                        _ = try Configuration(
                            projectToken: "token",
                            projectMapping: [
                                .sessionStart: ["token2", "token3"],
                                .sessionEnd: ["invalid token"]
                            ],
                            authorization: Authorization.none,
                            baseUrl: "baseUrl"
                        )
                        XCTFail("Error not thrown")
                    } catch {
                        let expectedErrorMessage = "Project mapping for event type sessionEnd is not valid. "
                            + "Project token provided is not valid. "
                            + "Only alphanumeric symbols and dashes are allowed in project token."
                        expect(error.localizedDescription).to(equal(expectedErrorMessage))
                    }
                }
            }
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
                            .customEvent: ["testToken2", "testToken3"],
                            .payment: ["paymentToken"]
                            ]

                        expect(config.projectMapping).to(equal(mapping))
                        expect(config.projectToken).to(beNil())
                    } catch {
                        XCTFail("Failed to load test data - \(error)")
                    }
                })
            })
            context("getting project tokens", {
                var logger: MockLogger!
                beforeEach {
                    logger = MockLogger()
                    Exponea.logger = logger
                }
                it("should return default project token") {
                    let configuration = try! Configuration(
                        projectToken: "token",
                        authorization: Authorization.none,
                        baseUrl: "baseUrl"
                    )
                    let tokens = configuration.tokens(for: .sessionStart)
                    expect { tokens.count }.to(equal(1))
                    expect { tokens.first }.to(equal("token"))
                    expect { logger.messages }.to(beEmpty())
                }

                it("should return project mapping tokens") {
                    let configuration = try! Configuration(
                        projectToken: "token",
                        projectMapping: [.sessionStart: ["token2", "token3"]],
                        authorization: Authorization.none,
                        baseUrl: "baseUrl"
                    )
                    let tokens = configuration.tokens(for: .sessionStart)
                    expect { tokens.count }.to(equal(2))
                    expect { tokens[0] }.to(equal("token2"))
                    expect { tokens[1] }.to(equal("token3"))
                    expect { logger.messages }.to(beEmpty())
                }

                it("should return default token for event not in project mapping") {
                    let configuration = try! Configuration(
                        projectToken: "token",
                        projectMapping: [.sessionStart: ["token2", "token3"]],
                        authorization: Authorization.none,
                        baseUrl: "baseUrl"
                    )
                    let tokens = configuration.tokens(for: .sessionEnd)
                    expect { tokens.count }.to(equal(1))
                    expect { tokens.first }.to(equal("token"))
                    expect { logger.messages }.to(beEmpty())
                }
            })
        }
    }
}

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
                                .sessionStart: [
                                    ExponeaProject(projectToken: "token2", authorization: .none),
                                    ExponeaProject(projectToken: "token3", authorization: .none)
                                ],
                                .sessionEnd: [
                                    ExponeaProject(projectToken: "invalid token", authorization: .none)
                                ]
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

                        let mapping: [EventType: [ExponeaProject]] = [
                            .install: [
                                ExponeaProject(projectToken: "testToken1", authorization: .token("authToken1"))
                            ],
                            .customEvent: [
                                ExponeaProject(projectToken: "testToken2", authorization: .token("authToken2")),
                                ExponeaProject(projectToken: "testToken3", authorization: .none)
                            ],
                            .payment: [
                                ExponeaProject(
                                    baseUrl: "https://mock-base-url.com",
                                    projectToken: "testToken4",
                                    authorization: .token("authToken4")
                                )
                            ]
                        ]

                        expect(config.projectMapping).to(equal(mapping))
                        expect(config.projectToken).to(equal("testToken"))
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
                    let projects = configuration.projects(for: .sessionStart)
                    expect { projects.count }.to(equal(1))
                    expect { projects.first?.projectToken }.to(equal("token"))
                    expect { logger.messages }.to(beEmpty())
                }

                it("should return project mapping tokens") {
                    let configuration = try! Configuration(
                        projectToken: "token",
                        projectMapping: [.sessionStart: [
                            ExponeaProject(projectToken: "token2", authorization: .none),
                            ExponeaProject(
                                baseUrl: "otherBaseUrl",
                                projectToken: "token3",
                                authorization: .token("some-token")
                            )
                        ]],
                        authorization: Authorization.none,
                        baseUrl: "baseUrl"
                    )
                    let projects = configuration.projects(for: .sessionStart)
                    expect { projects.count }.to(equal(3))
                    expect { projects[0] }.to(equal(
                        ExponeaProject(baseUrl: "baseUrl", projectToken: "token", authorization: .none)
                    ))
                    expect { projects[1] }.to(equal(
                        ExponeaProject(
                            baseUrl: Constants.Repository.baseUrl,
                            projectToken: "token2",
                            authorization: .none
                        )
                    ))
                    expect { projects[2] }.to(equal(
                        ExponeaProject(
                            baseUrl: "otherBaseUrl",
                            projectToken: "token3",
                            authorization: .token("some-token")
                        )
                    ))
                    expect { logger.messages }.to(beEmpty())
                }

                it("should return default token for event not in project mapping") {
                    let configuration = try! Configuration(
                        projectToken: "token",
                        projectMapping: [.sessionStart: [
                            ExponeaProject(projectToken: "token2", authorization: .none),
                            ExponeaProject(projectToken: "token3", authorization: .none)
                        ]],
                        authorization: Authorization.none,
                        baseUrl: "baseUrl"
                    )
                    let projects = configuration.projects(for: .sessionEnd)
                    expect { projects.count }.to(equal(1))
                    expect { projects.first }.to(equal(
                        ExponeaProject(baseUrl: "baseUrl", projectToken: "token", authorization: .none)
                    ))
                    expect { logger.messages }.to(beEmpty())
                }
            })
        }

        describe("saving to user defaults") {
            let appGroup = "appgroup"
            beforeEach {
                let defaults = UserDefaults(suiteName: appGroup)!
                defaults.removeObject(forKey: Constants.General.deliveredPushUserDefaultsKey)
                defaults.removeObject(forKey: Constants.General.lastKnownConfiguration)
            }

            it("load nil if there is no nothing stored in user defaults") {
                expect(Configuration.loadFromUserDefaults(appGroup: appGroup)).to(beNil())
            }

            it("load nil if stored configuration has incorrect format") {
                UserDefaults(suiteName: appGroup)?.set(
                    "some data".data(using: .utf8),
                    forKey: Constants.General.deliveredPushUserDefaultsKey
                )
                expect(Configuration.loadFromUserDefaults(appGroup: appGroup)).to(beNil())
            }

            it("should not save anything without app group") {
                let configuration = try! Configuration(
                    projectToken: "project-token",
                    projectMapping: nil,
                    authorization: .none,
                    baseUrl: nil
                )
                configuration.saveToUserDefaults()
                expect(UserDefaults(suiteName: appGroup)?.data(forKey: Constants.General.deliveredPushUserDefaultsKey))
                    .to(beNil())
            }

            it("save and load empty configuration") {
                let configuration = try! Configuration(
                    projectToken: "project-token",
                    projectMapping: nil,
                    authorization: .none,
                    baseUrl: nil,
                    appGroup: appGroup
                )
                configuration.saveToUserDefaults()
                expect(Configuration.loadFromUserDefaults(appGroup: appGroup)).to(equal(configuration))
            }

            it("save and load complete configuration") {
                let configuration = try! Configuration(
                    projectToken: "project-token",
                    projectMapping: [EventType.banner: [
                        ExponeaProject(
                            baseUrl: "https://other.base.url",
                            projectToken: "other-project-token",
                            authorization: .none
                        )
                    ]],
                    authorization: .token("test"),
                    baseUrl: "https://some.base.url",
                    defaultProperties: ["prop": "value", "other-prop": "other-value"],
                    sessionTimeout: 1234,
                    automaticSessionTracking: false,
                    automaticPushNotificationTracking: false,
                    tokenTrackFrequency: .daily,
                    appGroup: appGroup,
                    flushEventMaxRetries: 200
                )
                configuration.saveToUserDefaults()
                expect(Configuration.loadFromUserDefaults(appGroup: appGroup)).to(equal(configuration))
            }
        }
    }
}

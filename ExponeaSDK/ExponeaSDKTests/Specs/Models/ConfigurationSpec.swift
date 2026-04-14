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
                    let values: [TestableOptionalConfigErrorDesc] = [
                        (configuration: try? Configuration(
                            projectToken: "token",
                            authorization: Authorization.none,
                            baseUrl: "baseUrl"
                        ), errorDescription: "with projectToken"),
                        (configuration: try? Configuration(
                            integrationConfig: Exponea.ProjectSettings(
                                projectToken: "token",
                                authorization: Authorization.none,
                                baseUrl: "baseUrl",
                                projectMapping: nil
                            )
                        ), errorDescription: "with integrationConfig ProjectSettings"),
                        (configuration: try? Configuration(
                            integrationConfig: Exponea.StreamSettings(
                                streamId: "token",
                                baseUrl: "baseUrl"
                            )
                        ), errorDescription: "with integrationConfig StreamSettings")
                    ]
                        
                    for value in values {
                        expect {
                            value.configuration
                        }.notTo(beNil(), description: value.errorDescription)
                    }
                }
                it("should throw on invalid baseUrl") {
                    let throwableConfigurations: [ThrowableConfiguration] = [
                        ThrowableConfiguration(config: {
                            try Configuration(
                                projectToken: "token",
                                authorization: Authorization.none,
                                baseUrl: "string with spaces"
                            )
                        }),
                        ThrowableConfiguration(config: {
                            try Configuration(
                                integrationConfig: Exponea.ProjectSettings(
                                    projectToken: "token",
                                    authorization: Authorization.none,
                                    baseUrl: "string with spaces",
                                    projectMapping: nil
                                )
                            )
                        }),
                        ThrowableConfiguration(config: {
                            try Configuration(
                                integrationConfig: Exponea.StreamSettings(
                                    streamId: "token",
                                    baseUrl: "string with spaces"
                                )
                            )
                        })
                    ]
                    for value in throwableConfigurations {
                        do {
                            _ = try value.config()
                            XCTFail("Error not thrown")
                        } catch {
                            expect(error.localizedDescription).to(equal("Base url provided is not a valid url."))
                        }
                    }
                }
                it("should throw on invalid project token") {
                    let throwableConfigurations: [ThrowableConfiguration] = [
                        ThrowableConfiguration(config: {
                            try Configuration(
                                projectToken: "something else than project token",
                                authorization: Authorization.none,
                                baseUrl: "baseUrl"
                            )
                        }),
                        ThrowableConfiguration(config: {
                            try Configuration(
                                integrationConfig: Exponea.ProjectSettings(
                                    projectToken: "something else than project token",
                                    authorization: Authorization.none,
                                    baseUrl: "baseUrl",
                                    projectMapping: nil
                                )
                            )
                        }),
                        ThrowableConfiguration(config: {
                            try Configuration(
                                integrationConfig: Exponea.StreamSettings(
                                    streamId: "something else than project token",
                                    baseUrl: "baseUrl"
                                )
                            )
                        })
                    ]
                    for value in throwableConfigurations {
                        do {
                            _ = try value.config()
                            XCTFail("Error not thrown")
                        } catch {
                            let expectedErrorMessage = "Integration ID provided is not valid. "
                                + "Only alphanumeric symbols and dashes are allowed in integration ID."
                            expect(error.localizedDescription).to(equal(expectedErrorMessage))
                        }
                    }
                }
                it("should throw on invalid project token in project mapping") {
                    let throwableConfigurations: [ThrowableConfiguration] = [
                        ThrowableConfiguration(config: {
                            try Configuration(
                                projectToken: "token",
                                projectMapping: [
                                    .sessionStart: [
                                        ExponeaProject(projectToken: "token2", authorization: Authorization.none),
                                        ExponeaProject(projectToken: "token3", authorization: Authorization.none)
                                    ],
                                    .sessionEnd: [
                                        ExponeaProject(projectToken: "invalid token", authorization: Authorization.none)
                                    ]
                                ],
                                authorization: Authorization.none,
                                baseUrl: "baseUrl"
                            )
                        }),
                        ThrowableConfiguration(config: {
                            try Configuration(
                                integrationConfig: Exponea.ProjectSettings(
                                    projectToken: "token",
                                    authorization: Authorization.none,
                                    baseUrl: "baseUrl",
                                    projectMapping: [
                                        .sessionStart: [
                                            ExponeaProject(projectToken: "token2", authorization: Authorization.none),
                                            ExponeaProject(projectToken: "token3", authorization: Authorization.none)
                                        ],
                                        .sessionEnd: [
                                            ExponeaProject(projectToken: "invalid token", authorization: Authorization.none)
                                        ]
                                    ]
                                )
                            )
                        })
                    ]
                    for value in throwableConfigurations {
                        do {
                            _ = try value.config()
                            XCTFail("Error not thrown")
                        } catch {
                            let expectedErrorMessage = "Project mapping for event type sessionEnd is not valid. "
                                + "Integration ID provided is not valid. "
                                + "Only alphanumeric symbols and dashes are allowed in integration ID."
                            expect(error.localizedDescription).to(equal(expectedErrorMessage))
                        }
                    }
                }
            }
            context("that is parsed from valid plist", {
                it("should get created correctly with project token", closure: {
                    for fileName in ["config_valid", "config_valid_stream"] {
                        do {
                            let bundle = Bundle(for: ConfigurationSpec.self)
                            let filePath = bundle.path(forResource: fileName, ofType: "plist")
                            let fileUrl = URL(fileURLWithPath: filePath ?? "")
                            let data = try Data(contentsOf: fileUrl)
                            let config = try PropertyListDecoder().decode(Configuration.self, from: data)

                            if case .project = config.integrationConfig.type {
                                expect(config.projectToken).to(equal("testToken"), description: "File name: \(fileName)")
                                expect(config.projectMapping).to(beNil())
                            }
                            
                            expect(config.integrationId).to(equal("testToken"), description: "File name: \(fileName)")
                            expect((config.integrationConfig as? Exponea.ProjectSettings)?.projectMapping).to(beNil())
                        } catch {
                            XCTFail("Failed to load test data - \(error)")
                        }
                    }
                })

                it("should get created correctly with project mapping", closure: {
                    for fileName in ["config_valid2", "config_valid2_stream"] {
                        do {
                            let bundle = Bundle(for: ConfigurationSpec.self)
                            let filePath = bundle.path(forResource: fileName, ofType: "plist")
                            let fileUrl = URL(fileURLWithPath: filePath ?? "")
                            let data = try Data(contentsOf: fileUrl)
                            let config = try PropertyListDecoder().decode(Configuration.self, from: data)

                            switch config.integrationConfig.type {
                            case .project:
                                let mapping: [EventType: [ExponeaProject]] = [
                                    .install: [
                                        ExponeaProject(projectToken: "testToken1", authorization: .token("authToken1"))
                                    ],
                                    .customEvent: [
                                        ExponeaProject(projectToken: "testToken2", authorization: .token("authToken2")),
                                        ExponeaProject(projectToken: "testToken3", authorization: Authorization.none)
                                    ],
                                    .payment: [
                                        ExponeaProject(
                                            baseUrl: "https://mock-base-url.com",
                                            projectToken: "testToken4",
                                            authorization: .token("authToken4")
                                        )
                                    ]
                                ]

                                expect(config.projectMapping).to(equal(mapping), description: "File name: \(fileName)")
                                expect(config.projectToken).to(equal("testToken"), description: "File name: \(fileName)")
                                
                                if let configMapping = (config.integrationConfig as? Exponea.ProjectSettings)?.projectMapping {
                                    expect(configMapping).to(equal(mapping), description: "File name: \(fileName)")
                                } else {
                                    XCTFail("Incorrect type of integration mapping.")
                                }
                            case .stream:
                                continue
                            }
                            
                            expect(config.integrationId).to(equal("testToken"), description: "File name: \(fileName)")
                        } catch {
                            XCTFail("Failed to load test data - \(error)")
                        }
                    }
                })
            })
            context("getting project tokens", {
                var logger: MockLogger!
                beforeEach {
                    IntegrationManager.shared.isStopped = false
                    logger = MockLogger()
                    Exponea.logger = logger
                }
                it("should return default project token") {
                    let configurations: [Configuration] = [
                        try! Configuration(
                            projectToken: "token",
                            authorization: Authorization.none,
                            baseUrl: "baseUrl"
                        ),
                        try! Configuration(
                            integrationConfig: Exponea.ProjectSettings(
                                projectToken: "token",
                                authorization: Authorization.none,
                                baseUrl: "baseUrl",
                                projectMapping: nil
                            )
                        ),
                        try! Configuration(
                            integrationConfig: Exponea.StreamSettings(
                                streamId: "token",
                                baseUrl: "baseUrl"
                            )
                        )
                    ]
                    for configuration in configurations {
                        let projects = configuration.projects(for: .sessionStart)
                        expect { projects.count }.to(equal(1))
                        expect { projects.first?.integrationId }.to(equal("token"))
                        expect { logger.messages }.to(beEmpty())
                    }
                }

                it("should return project mapping tokens") {
                    let configurations: [Configuration] = [
                        try! Configuration(
                            projectToken: "token",
                            projectMapping: [.sessionStart: [
                                ExponeaProject(projectToken: "token2", authorization: Authorization.none),
                                ExponeaProject(
                                    baseUrl: "otherBaseUrl",
                                    projectToken: "token3",
                                    authorization: .token("some-token")
                                )
                            ]],
                            authorization: Authorization.none,
                            baseUrl: "baseUrl"
                        ),
                        try! Configuration(
                            integrationConfig: Exponea.ProjectSettings(
                                projectToken: "token",
                                authorization: Authorization.none,
                                baseUrl: "baseUrl",
                                projectMapping: [.sessionStart: [
                                    ExponeaProject(projectToken: "token2", authorization: Authorization.none),
                                    ExponeaProject(
                                        baseUrl: "otherBaseUrl",
                                        projectToken: "token3",
                                        authorization: .token("some-token")
                                    )
                                ]]
                            )
                        ),
                        try! Configuration(
                            integrationConfig: Exponea.StreamSettings(
                                streamId: "token",
                                baseUrl: "baseUrl"
                            )
                        )
                    ]
                    for configuration in configurations {
                        let projects = configuration.projects(for: .sessionStart)
                        
                        switch configuration.integrationConfig.type {
                        case .project:
                            expect { projects.count }.to(equal(3))
                            expect { projects[0] as? ExponeaProject }.to(equal(
                                ExponeaProject(baseUrl: "baseUrl", projectToken: "token", authorization: Authorization.none)
                            ))
                            expect { projects[1] as? ExponeaProject }.to(equal(
                                ExponeaProject(
                                    baseUrl: Constants.Repository.baseUrl,
                                    projectToken: "token2",
                                    authorization: Authorization.none
                                )
                            ))
                            expect { projects[2] as? ExponeaProject }.to(equal(
                                ExponeaProject(
                                    baseUrl: "otherBaseUrl",
                                    projectToken: "token3",
                                    authorization: .token("some-token")
                                )
                            ))
                        case .stream:
                            expect { projects.count }.to(equal(1))
                        }
                        
                        expect { logger.messages }.to(beEmpty())
                    }
                }

                it("should return default token for event not in project mapping") {
                    let configurations: [Configuration] = [
                        try! Configuration(
                            projectToken: "token",
                            projectMapping: [.sessionStart: [
                                ExponeaProject(projectToken: "token2", authorization: Authorization.none),
                                ExponeaProject(projectToken: "token3", authorization: Authorization.none)
                            ]],
                            authorization: Authorization.none,
                            baseUrl: "baseUrl"
                        ),
                        try! Configuration(
                            integrationConfig: Exponea.ProjectSettings(
                                projectToken: "token",
                                authorization: Authorization.none,
                                baseUrl: "baseUrl",
                                projectMapping: [.sessionStart: [
                                    ExponeaProject(projectToken: "token2", authorization: Authorization.none),
                                    ExponeaProject(projectToken: "token3", authorization: Authorization.none)
                                ]]
                            )
                        ),
                        try! Configuration(
                            integrationConfig: Exponea.StreamSettings(
                                streamId: "token",
                                baseUrl: "baseUrl"
                            )
                        )
                    ]
                    for configuration in configurations {
                        let projects = configuration.projects(for: .sessionEnd)
                        expect { projects.count }.to(equal(1))
                        
                        switch configuration.integrationConfig.type {
                        case .project:
                            expect { projects.first as? ExponeaProject }.to(equal(
                                ExponeaProject(baseUrl: "baseUrl", projectToken: "token", authorization: Authorization.none)
                            ))
                        case .stream:
                            expect { projects.first as? ExponeaIntegration }.to(equal(
                                ExponeaIntegration(baseUrl: "baseUrl", streamId: "token")
                            ))
                        }
                        
                        expect { logger.messages }.to(beEmpty())
                    }
                }
            })
        }

        describe("saving to user defaults") {
            let appGroup = "appgroup"
            beforeEach {
                IntegrationManager.shared.isStopped = false
                let defaults = UserDefaults(suiteName: appGroup)!
                defaults.removeObject(forKey: Constants.General.deliveredPushUserDefaultsKey)
                defaults.removeObject(forKey: Constants.General.deliveredPushEventUserDefaultsKey)
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

            context("should not save anything without app group") {
                let inputs: [TestableNonOptionalConfigErrorDesc] = [
                    (configuration: try! Configuration(
                        projectToken: "project-token",
                        projectMapping: nil,
                        authorization: Authorization.none,
                        baseUrl: nil
                    ), errorDescription: "Config type: projectToken"),
                    (configuration: try! Configuration(
                        integrationConfig: Exponea.ProjectSettings(
                            projectToken: "project-token",
                            authorization: Authorization.none,
                            baseUrl: nil,
                            projectMapping: nil
                        )
                    ), errorDescription: "Config type: integrationConfig - projectToken"),
                    (configuration: try! Configuration(
                        integrationConfig: Exponea.StreamSettings(
                            streamId: "project-token",
                            baseUrl: nil
                        )
                    ), errorDescription: "Config type: integrationConfig - streamId")
                ]
                for input in inputs {
                    it("Type \(input.configuration.integrationConfig.type.rawValue)") {
                        input.configuration.saveToUserDefaults()
                        expect(UserDefaults(suiteName: appGroup)?.data(forKey: Constants.General.deliveredPushUserDefaultsKey))
                            .to(beNil(), description: input.errorDescription)
                    }
                }
            }

            context("save and load empty configuration") {
                let inputs: [TestableNonOptionalConfigErrorDesc] = [
                    (configuration: try! Configuration(
                        projectToken: "project-token",
                        projectMapping: nil,
                        authorization: Authorization.none,
                        baseUrl: nil,
                        appGroup: appGroup
                    ), errorDescription: "Config type: projectToken"),
                    (configuration: try! Configuration(
                        integrationConfig: Exponea.ProjectSettings(
                            projectToken: "project-token",
                            authorization: Authorization.none,
                            baseUrl: nil,
                            projectMapping: nil
                        ),
                        appGroup: appGroup
                    ), errorDescription: "Config type: integrationConfig - projectToken"),
                    (configuration: try! Configuration(
                        integrationConfig: Exponea.StreamSettings(
                            streamId: "project-token",
                            baseUrl: nil
                        ),
                        appGroup: appGroup
                    ), errorDescription: "Config type: integrationConfig - streamId")
                ]
                for input in inputs {
                    it("Type \(input.configuration.integrationConfig.type.rawValue)") {
                        input.configuration.saveToUserDefaults()
                        expect(Configuration.loadFromUserDefaults(appGroup: appGroup)).to(equal(input.configuration), description: input.errorDescription)
                    }
                }
            }

            context("save and load complete configuration") {
                let inputs: [TestableNonOptionalConfigErrorDesc] = [
                    (configuration: try! Configuration(
                        projectToken: "project-token",
                        projectMapping: [EventType.banner: [
                            ExponeaProject(
                                baseUrl: "https://other.base.url",
                                projectToken: "other-project-token",
                                authorization: Authorization.none
                            )
                        ]],
                        authorization: .token("test"),
                        baseUrl: "https://some.base.url",
                        appGroup: appGroup,
                        defaultProperties: ["prop": "value", "other-prop": "other-value"],
                        sessionTimeout: 1234,
                        automaticSessionTracking: false,
                        automaticPushNotificationTracking: false,
                        tokenTrackFrequency: .daily,
                        flushEventMaxRetries: 200,
                        allowDefaultCustomerProperties: true,
                        advancedAuthEnabled: false
                    ), errorDescription: "Config type: projectToken"),
                    (configuration: try! Configuration(
                        integrationConfig: Exponea.ProjectSettings(
                            projectToken: "project-token",
                            authorization: .token("test"),
                            baseUrl: "https://some.base.url",
                            projectMapping: [EventType.banner: [
                                ExponeaProject(
                                    baseUrl: "https://other.base.url",
                                    projectToken: "other-project-token",
                                    authorization: Authorization.none
                                )
                            ]],
                        ),
                        appGroup: appGroup,
                        defaultProperties: ["prop": "value", "other-prop": "other-value"],
                        sessionTimeout: 1234,
                        automaticSessionTracking: false,
                        automaticPushNotificationTracking: false,
                        tokenTrackFrequency: .daily,
                        flushEventMaxRetries: 200,
                        allowDefaultCustomerProperties: true,
                        advancedAuthEnabled: false
                    ), errorDescription: "Config type: integrationConfig - projectToken"),
                    (configuration: try! Configuration(
                        integrationConfig: Exponea.StreamSettings(
                            streamId: "project-token",
                            baseUrl: "https://some.base.url"
                        ),
                        appGroup: appGroup,
                        defaultProperties: ["prop": "value", "other-prop": "other-value"],
                        sessionTimeout: 1234,
                        automaticSessionTracking: false,
                        automaticPushNotificationTracking: false,
                        tokenTrackFrequency: .daily,
                        flushEventMaxRetries: 200,
                        allowDefaultCustomerProperties: true,
                        advancedAuthEnabled: false
                    ), errorDescription: "Config type: integrationConfig - streamId")
                ]
                for input in inputs {
                    it("Type \(input.configuration.integrationConfig.type.rawValue)") {
                        input.configuration.saveToUserDefaults()
                        expect(Configuration.loadFromUserDefaults(appGroup: appGroup)).to(equal(input.configuration), description: input.errorDescription)
                    }
                }
            }
        }
    }
}

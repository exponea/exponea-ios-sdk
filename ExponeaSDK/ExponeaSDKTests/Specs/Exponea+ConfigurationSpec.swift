//
//  Exponea+ConfigurationSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 22/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Quick
import Nimble

@testable import ExponeaSDK

class ExponeaConfigurationSpec: QuickSpec, PushNotificationManagerDelegate {
    func pushNotificationOpened(
        with action: ExponeaNotificationActionType,
        value: String?,
        extraData: [AnyHashable: Any]?
    ) {}

    override func spec() {
        describe("Creating configuration") {
            it("should setup simplest configuration") {
                let exponea = ExponeaInternal()
                exponea.configure(
                    Exponea.ProjectSettings(
                        projectToken: "mock-project-token",
                        authorization: .none
                    ),
                    pushNotificationTracking: .disabled
                )
                guard let configuration = exponea.configuration else {
                    XCTFail("Nil configuration")
                    return
                }
                expect(configuration.projectMapping).to(beNil())
                expect(configuration.projectToken).to(equal("mock-project-token"))
                expect(configuration.baseUrl).to(equal(Constants.Repository.baseUrl))
                expect(configuration.defaultProperties).to(beNil())
                expect(configuration.sessionTimeout).to(equal(Constants.Session.defaultTimeout))
                expect(configuration.automaticSessionTracking).to(equal(true))
                expect(configuration.automaticPushNotificationTracking).to(equal(false))
                expect(configuration.tokenTrackFrequency).to(equal(.onTokenChange))
                expect(configuration.appGroup).to(beNil())
                expect(configuration.flushEventMaxRetries).to(equal(Constants.Session.maxRetries))
                expect(configuration.applicationID).to(equal(Constants.General.applicationID))
                guard case .immediate = exponea.flushingMode else {
                    XCTFail("Incorect flushing mode")
                    return
                }
                expect(exponea.pushNotificationsDelegate).to(beNil())
            }

            it("should setup complex configuration") {
                let exponea = ExponeaInternal()
                exponea.configure(
                    Exponea.ProjectSettings(
                        projectToken: "mock-project-token",
                        authorization: .none,
                        baseUrl: "mock-url",
                        projectMapping: [
                            .payment: [
                                ExponeaProject(
                                    baseUrl: "other-mock-url",
                                    projectToken: "other-project-id",
                                    authorization: .token("some-token")
                                )
                            ]
                        ]
                    ),
                    pushNotificationTracking: .enabled(
                        appGroup: "mock-app-group",
                        delegate: self,
                        requirePushAuthorization: false,
                        tokenTrackFrequency: .onTokenChange
                    ),
                    automaticSessionTracking: .enabled(timeout: 12345),
                    defaultProperties: ["mock-prop-1": "mock-value-1", "mock-prop-2": 123],
                    flushingSetup: Exponea.FlushingSetup(mode: .periodic(111), maxRetries: 123),
                    advancedAuthEnabled: false,
                    applicationID: "com.company.project"
                )
                guard let configuration = exponea.configuration else {
                    XCTFail("Nil configuration")
                    return
                }
                expect(configuration.projectMapping).to(
                    equal([.payment: [
                        ExponeaProject(
                            baseUrl: "other-mock-url",
                            projectToken: "other-project-id",
                            authorization: .token("some-token")
                        )
                    ]])
                )
                expect(configuration.projectToken).to(equal("mock-project-token"))
                expect(configuration.baseUrl).to(equal("mock-url"))
                expect(configuration.defaultProperties).notTo(beNil())
                expect(configuration.defaultProperties?["mock-prop-1"] as? String).to(equal("mock-value-1"))
                expect(configuration.defaultProperties?["mock-prop-2"] as? Int).to(equal(123))
                expect(configuration.sessionTimeout).to(equal(12345))
                expect(configuration.automaticSessionTracking).to(equal(true))
                expect(configuration.automaticPushNotificationTracking).to(equal(false))
                expect(configuration.requirePushAuthorization).to(equal(false))
                expect(configuration.tokenTrackFrequency).to(equal(.onTokenChange))
                expect(configuration.appGroup).to(equal("mock-app-group"))
                expect(configuration.flushEventMaxRetries).to(equal(123))
                expect(configuration.advancedAuthEnabled).to(equal(false))
                expect(configuration.applicationID).to(equal("com.company.project"))
                guard case .periodic(let period) = exponea.flushingMode else {
                    XCTFail("Incorect flushing mode")
                    return
                }
                expect(period).to(equal(111))
                expect(exponea.pushNotificationsDelegate).notTo(beNil())
            }

            it("should allow single initialisation") {
                for _ in 0..<200 {
                    Exponea.logger.logLevel = .verbose
                    var sdkInitMessageCount = 0
                    Exponea.logger.addLogHook { message in
                        if message.contains("SDK init starts synchronously") {
                            sdkInitMessageCount += 1
                        }
                    }
                    let exponea = ExponeaInternal()
                    var initsCount = 0
                    let maxInitsCount = 50
                    var tokenWinner = ""
                    let group = DispatchGroup()
                    waitUntil(timeout: .seconds(10)) { done in
                        for i in 0..<maxInitsCount {
                            DispatchQueue.global(qos: .background).async(group: group) {
                                exponea.configure(
                                    Exponea.ProjectSettings(
                                        projectToken: "mock-project-token-\(i)",
                                        authorization: .none
                                    ),
                                    pushNotificationTracking: .disabled
                                )
                                if let conf = exponea.configuration,
                                   conf.projectToken == "mock-project-token-\(i)",
                                   tokenWinner == "" {
                                    tokenWinner = conf.projectToken
                                }
                                initsCount += 1
                                if initsCount == maxInitsCount {
                                    done()
                                }
                            }
                        }
                    }
                    expect(exponea.configuration!.projectToken).to(equal(tokenWinner))
                    expect(sdkInitMessageCount).to(equal(1))
                    if sdkInitMessageCount != 1 {
                        break
                    }
                    if let conf = exponea.configuration {
                        expect(conf.projectToken).to(equal(tokenWinner))
                        expect(exponea.configuration!.projectToken).to(equal(tokenWinner))
                        expect(sdkInitMessageCount).to(equal(1))
                        if sdkInitMessageCount != 1 {
                            break
                        }
                        if let conf = exponea.configuration {
                            expect(conf.projectToken).to(equal(tokenWinner))
                        }
                        expect(conf.applicationID).to(equal(Constants.General.applicationID))
                    }
                }
            }
        }
    }
}

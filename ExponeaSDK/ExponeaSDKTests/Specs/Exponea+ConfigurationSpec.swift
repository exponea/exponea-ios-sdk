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
    func pushNotificationOpened(with action: ExponeaNotificationActionType, value: String?, extraData: [AnyHashable: Any]?) {
    }

    override func spec() {
        describe("Creating configuration") {
            it("should setup simplest configuration") {
                let exponea = Exponea()
                exponea.configure(
                    Exponea.ProjectSettings(
                        projectToken: "mock-project-token",
                        authorization: .none
                    ),
                    automaticPushNotificationTracking: .disabled
                )
                expect(exponea.configuration!.projectMapping).to(beNil())
                expect(exponea.configuration!.projectToken).to(equal("mock-project-token"))
                expect(exponea.configuration!.baseUrl).to(equal(Constants.Repository.baseUrl))
                expect(exponea.configuration!.defaultProperties).to(beNil())
                expect(exponea.configuration!.sessionTimeout).to(equal(Constants.Session.defaultTimeout))
                expect(exponea.configuration!.automaticSessionTracking).to(equal(true))
                expect(exponea.configuration!.automaticPushNotificationTracking).to(equal(false))
                expect(exponea.configuration!.tokenTrackFrequency).to(equal(.onTokenChange))
                expect(exponea.configuration!.appGroup).to(beNil())
                expect(exponea.configuration!.flushEventMaxRetries).to(equal(Constants.Session.maxRetries))
                guard case .immediate = exponea.flushingMode else {
                    XCTFail("Incorect flushing mode")
                    return
                }
                expect(exponea.pushNotificationsDelegate).to(beNil())
            }

            it("should setup complex configuration") {
                let exponea = Exponea()
                exponea.configure(
                    Exponea.ProjectSettings(
                        projectToken: "mock-project-token",
                        authorization: .none,
                        baseUrl: "mock-url",
                        projectMapping: [.payment: ["other-project-id"]]
                    ),
                    automaticPushNotificationTracking: .enabled(
                        appGroup: "mock-app-group",
                        delegate: self,
                        tokenTrackFrequency: .onTokenChange
                    ),
                    automaticSessionTracking: .enabled(timeout: 12345),
                    defaultProperties: ["mock-prop-1": "mock-value-1", "mock-prop-2": 123],
                    flushingSetup: Exponea.FlushingSetup(mode: .periodic(111), maxRetries: 123)
                )
                expect(exponea.configuration!.projectMapping).to(equal([.payment: ["other-project-id"]]))
                expect(exponea.configuration!.projectToken).to(equal("mock-project-token"))
                expect(exponea.configuration!.baseUrl).to(equal("mock-url"))
                expect(exponea.configuration!.defaultProperties).notTo(beNil())
                expect(exponea.configuration!.defaultProperties?["mock-prop-1"] as? String).to(equal("mock-value-1"))
                expect(exponea.configuration!.defaultProperties?["mock-prop-2"] as? Int).to(equal(123))
                expect(exponea.configuration!.sessionTimeout).to(equal(12345))
                expect(exponea.configuration!.automaticSessionTracking).to(equal(true))
                expect(exponea.configuration!.automaticPushNotificationTracking).to(equal(true))
                expect(exponea.configuration!.tokenTrackFrequency).to(equal(.onTokenChange))
                expect(exponea.configuration!.appGroup).to(equal("mock-app-group"))
                expect(exponea.configuration!.flushEventMaxRetries).to(equal(123))
                guard case .periodic(let period) = exponea.flushingMode else {
                    XCTFail("Incorect flushing mode")
                    return
                }
                expect(period).to(equal(111))
                expect(exponea.pushNotificationsDelegate).notTo(beNil())
            }
        }
    }
}

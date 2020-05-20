//
//  ExponeaAppDelegateSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 27/05/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//
import XCTest
import Quick
import Nimble

@testable import ExponeaSDK

final class ExponeaAppDelegateSpec: QuickSpec {
    func configureExponea(requirePushAuthorization: Bool) {
        let exponea = ExponeaInternal()
        Exponea.shared = exponea
        Exponea.shared.configure(
            Exponea.ProjectSettings(projectToken: "mock-token", authorization: .token("mock-token")),
            pushNotificationTracking: .enabled(
                appGroup: "mock-group",
                delegate: nil,
                requirePushAuthorization: requirePushAuthorization,
                tokenTrackFrequency: .onTokenChange
            )
        )
    }

    override func spec() {
        describe("Push token tracking") {
            context("when push notifications are not authorized") {
                beforeEach {
                    UNAuthorizationStatusProvider.current = MockUNAuthorizationStatusProviding(status: .notDetermined)
                }
                it("should not track token if authorization required") {
                    self.configureExponea(requirePushAuthorization: true)
                    ExponeaAppDelegate().application(
                        UIApplication.shared,
                        didRegisterForRemoteNotificationsWithDeviceToken: "mock-token".data(using: .utf8)!
                    )
                    Exponea.shared.executeSafelyWithDependencies { dependencies in
                        expect(dependencies.trackingManager.customerPushToken).to(beNil())
                    }
                }

                it("should track token if authorization not required") {
                    self.configureExponea(requirePushAuthorization: false)
                    ExponeaAppDelegate().application(
                        UIApplication.shared,
                        didRegisterForRemoteNotificationsWithDeviceToken: "mock-token".data(using: .utf8)!
                    )
                    Exponea.shared.executeSafelyWithDependencies { dependencies in
                        expect(dependencies.trackingManager.customerPushToken).to(equal("6D6F636B2D746F6B656E"))
                    }
                }
            }

            context("when push notifications are authorized") {
                beforeEach {
                    UNAuthorizationStatusProvider.current = MockUNAuthorizationStatusProviding(status: .authorized)
                }
                it("should track token if authorization required") {
                    self.configureExponea(requirePushAuthorization: true)
                    ExponeaAppDelegate().application(
                        UIApplication.shared,
                        didRegisterForRemoteNotificationsWithDeviceToken: "mock-token".data(using: .utf8)!
                    )
                    Exponea.shared.executeSafelyWithDependencies { dependencies in
                        expect(dependencies.trackingManager.customerPushToken).to(equal("6D6F636B2D746F6B656E"))
                    }
                }

                it("should track token if authorization not required") {
                    self.configureExponea(requirePushAuthorization: true)
                    ExponeaAppDelegate().application(
                        UIApplication.shared,
                        didRegisterForRemoteNotificationsWithDeviceToken: "mock-token".data(using: .utf8)!
                    )
                    Exponea.shared.executeSafelyWithDependencies { dependencies in
                        expect(dependencies.trackingManager.customerPushToken).to(equal("6D6F636B2D746F6B656E"))
                    }
                }
            }
        }
    }
}

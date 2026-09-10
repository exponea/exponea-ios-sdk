//
//  DeliveredNotificationStateResolverSpec.swift
//  ExponeaSDKTests
//
//  Created on 23/04/2026.
//  Copyright © 2026 Exponea. All rights reserved.
//
//  Exercises the pure resolver that backs the delivered-push `state`
//  property. The resolver lives in ExponeaSDKShared because both the main
//  SDK (TrackingConsentManager.trackDeliveredPush) and the NSE
//  (ExponeaNotificationService.trackDeliveredNotification) consume it.
//

import Nimble
import Quick
import UserNotifications

@testable import ExponeaSDKShared

/// Provider stub that holds its completion until the test fires it manually.
/// Used to verify that callers chaining work off
/// `DeliveryAuthorizationProvider.refresh(completion:)` see the post-refresh
/// snapshot, not the pre-refresh one.
private final class DeferredDeliveryAuthorizationProvider: DeliveryAuthorizationProviding {
    let snapshot: DeliveryAuthorizationSnapshot?
    private var pending: [(DeliveryAuthorizationSnapshot?) -> Void] = []

    init(snapshot: DeliveryAuthorizationSnapshot?) { self.snapshot = snapshot }

    func currentDeliveryAuthorization(
        completion: @escaping (DeliveryAuthorizationSnapshot?) -> Void
    ) {
        pending.append(completion)
    }

    func fireAll() {
        let captured = pending
        pending.removeAll()
        captured.forEach { $0(snapshot) }
    }

    var pendingCount: Int { pending.count }
}

final class DeliveredNotificationStateResolverSpec: QuickSpec {
    override func spec() {
        describe("DeliveredNotificationStateResolver.resolve") {

            context("silent pushes") {
                it("always returns not_shown when silent is true, regardless of authorization") {
                    let snapshotAuthorized = DeliveryAuthorizationSnapshot(
                        authorizationStatus: .authorized,
                        alertSetting: .enabled
                    )
                    expect(
                        DeliveredNotificationStateResolver.resolve(
                            authorization: snapshotAuthorized,
                            silent: true
                        )
                    ).to(equal(DeliveredNotificationStateResolver.notShownValue))

                    let snapshotDenied = DeliveryAuthorizationSnapshot(
                        authorizationStatus: .denied,
                        alertSetting: .disabled
                    )
                    expect(
                        DeliveredNotificationStateResolver.resolve(
                            authorization: snapshotDenied,
                            silent: true
                        )
                    ).to(equal(DeliveredNotificationStateResolver.notShownValue))

                    expect(
                        DeliveredNotificationStateResolver.resolve(
                            authorization: nil,
                            silent: true
                        )
                    ).to(equal(DeliveredNotificationStateResolver.notShownValue))
                }
            }

            context("visible pushes with a resolved authorization snapshot") {

                struct Case {
                    let status: UNAuthorizationStatus
                    let alert: UNNotificationSetting
                    let expected: String
                    let description: String
                }

                var cases: [Case] = [
                    Case(
                        status: .authorized,
                        alert: .enabled,
                        expected: DeliveredNotificationStateResolver.shownValue,
                        description: "authorized + alerts enabled"
                    ),
                    Case(
                        status: .provisional,
                        alert: .enabled,
                        expected: DeliveredNotificationStateResolver.shownValue,
                        description: "provisional + alerts enabled"
                    ),
                    Case(
                        status: .ephemeral,
                        alert: .enabled,
                        expected: DeliveredNotificationStateResolver.shownValue,
                        description: "ephemeral + alerts enabled"
                    )
                ]
                cases.append(contentsOf: [
                    Case(
                        status: .authorized,
                        alert: .disabled,
                        expected: DeliveredNotificationStateResolver.notShownValue,
                        description: "authorized but alerts disabled"
                    ),
                    Case(
                        status: .authorized,
                        alert: .notSupported,
                        expected: DeliveredNotificationStateResolver.notShownValue,
                        description: "authorized but alerts notSupported"
                    ),
                    Case(
                        status: .denied,
                        alert: .enabled,
                        expected: DeliveredNotificationStateResolver.notShownValue,
                        description: "denied even if alerts enabled"
                    ),
                    Case(
                        status: .denied,
                        alert: .disabled,
                        expected: DeliveredNotificationStateResolver.notShownValue,
                        description: "denied + alerts disabled"
                    ),
                    Case(
                        status: .notDetermined,
                        alert: .enabled,
                        expected: DeliveredNotificationStateResolver.notShownValue,
                        description: "notDetermined resolves as not_shown"
                    )
                ])

                for testCase in cases {
                    it("resolves \(testCase.description) to \(testCase.expected)") {
                        let snapshot = DeliveryAuthorizationSnapshot(
                            authorizationStatus: testCase.status,
                            alertSetting: testCase.alert
                        )
                        let state = DeliveredNotificationStateResolver.resolve(
                            authorization: snapshot,
                            silent: false
                        )
                        expect(state).to(equal(testCase.expected))
                    }
                }
            }

            context("visible pushes with no snapshot available") {
                it("falls back to \"shown\" to preserve legacy event shape") {
                    expect(
                        DeliveredNotificationStateResolver.resolve(
                            authorization: nil,
                            silent: false
                        )
                    ).to(equal(DeliveredNotificationStateResolver.shownValue))
                }
            }
        }

        describe("DeliveryAuthorizationProvider.refresh(completion:)") {
            // Contract pin: callers that need to consume `lastSnapshot`
            // synchronously after a refresh (PushNotificationManager's
            // delivered-push paths in particular) must be able to chain
            // their work off the completion. This block proves that
            // (a) the completion is invoked exactly once after the
            // underlying provider hands back a snapshot, and (b) the
            // snapshot is observable on `lastSnapshot` before the
            // completion fires — i.e. inside the completion, the chained
            // work sees the post-refresh value rather than the
            // pre-refresh one.
            var originalProvider: DeliveryAuthorizationProviding!
            var originalSnapshot: DeliveryAuthorizationSnapshot?

            beforeEach {
                originalProvider = DeliveryAuthorizationProvider.current
                originalSnapshot = DeliveryAuthorizationProvider.lastSnapshot
            }

            afterEach {
                DeliveryAuthorizationProvider.current = originalProvider
                DeliveryAuthorizationProvider.lastSnapshot = originalSnapshot
            }

            it("invokes the completion exactly once after the underlying provider responds") {
                let provider = DeferredDeliveryAuthorizationProvider(
                    snapshot: DeliveryAuthorizationSnapshot(
                        authorizationStatus: .denied,
                        alertSetting: .disabled
                    )
                )
                DeliveryAuthorizationProvider.current = provider

                var completionInvocations = 0
                DeliveryAuthorizationProvider.refresh {
                    completionInvocations += 1
                }
                expect(completionInvocations).to(equal(0))
                expect(provider.pendingCount).to(equal(1))

                provider.fireAll()

                expect(completionInvocations).to(equal(1))
                expect(provider.pendingCount).to(equal(0))
            }

            it("exposes the post-refresh snapshot on lastSnapshot before the completion runs") {
                let preRefresh = DeliveryAuthorizationSnapshot(
                    authorizationStatus: .authorized,
                    alertSetting: .enabled
                )
                let postRefresh = DeliveryAuthorizationSnapshot(
                    authorizationStatus: .denied,
                    alertSetting: .disabled
                )

                DeliveryAuthorizationProvider.lastSnapshot = preRefresh
                let provider = DeferredDeliveryAuthorizationProvider(snapshot: postRefresh)
                DeliveryAuthorizationProvider.current = provider

                var observedDuringCompletion: DeliveryAuthorizationSnapshot?
                DeliveryAuthorizationProvider.refresh {
                    observedDuringCompletion = DeliveryAuthorizationProvider.lastSnapshot
                }

                expect(DeliveryAuthorizationProvider.lastSnapshot?.authorizationStatus)
                    .to(equal(preRefresh.authorizationStatus))
                expect(observedDuringCompletion).to(beNil())

                provider.fireAll()

                expect(observedDuringCompletion?.authorizationStatus)
                    .to(equal(postRefresh.authorizationStatus))
                expect(observedDuringCompletion?.alertSetting)
                    .to(equal(postRefresh.alertSetting))
                expect(DeliveryAuthorizationProvider.lastSnapshot?.authorizationStatus)
                    .to(equal(postRefresh.authorizationStatus))
            }

            it("clears lastSnapshot to nil when the provider returns nil") {
                DeliveryAuthorizationProvider.lastSnapshot = DeliveryAuthorizationSnapshot(
                    authorizationStatus: .authorized,
                    alertSetting: .enabled
                )
                let provider = DeferredDeliveryAuthorizationProvider(snapshot: nil)
                DeliveryAuthorizationProvider.current = provider

                var didFireCompletion = false
                var snapshotInsideCompletion: DeliveryAuthorizationSnapshot?
                DeliveryAuthorizationProvider.refresh {
                    didFireCompletion = true
                    snapshotInsideCompletion = DeliveryAuthorizationProvider.lastSnapshot
                }

                expect(didFireCompletion).to(beFalse())

                provider.fireAll()

                expect(didFireCompletion).to(beTrue())
                expect(snapshotInsideCompletion).to(beNil())
                expect(DeliveryAuthorizationProvider.lastSnapshot).to(beNil())
            }
        }
    }
}

//
//  UrlOpenerSpec.swift
//  ExponeaSDKTests
//
//  Copyright © 2026 Exponea. All rights reserved.
//

import Quick
import Nimble
import UIKit

@testable import ExponeaSDK

/// Test double for `SceneUniversalLinkForwarding` — `UIWindowScene` has no public initializer,
/// so real scene instances cannot be constructed in unit tests.
final class MockSceneForwarding: SceneUniversalLinkForwarding {
    let isForegroundActive: Bool
    let canForwardUniversalLink: Bool
    private(set) var forwardedActivity: NSUserActivity?

    init(isForegroundActive: Bool, canForwardUniversalLink: Bool) {
        self.isForegroundActive = isForegroundActive
        self.canForwardUniversalLink = canForwardUniversalLink
    }

    func forwardUniversalLink(_ userActivity: NSUserActivity) {
        forwardedActivity = userActivity
    }
}

final class UrlOpenerSpec: QuickSpec {
    override func spec() {
        describe("UrlOpener") {
            let urlOpener = UrlOpener()

            it("falls back to URL scheme open when universal link simulation is unavailable") {
                urlOpener.openDeeplink("exponea://deeplink")
            }

            it("ignores invalid universal link URLs and tries URL scheme fallback") {
                urlOpener.openDeeplink("not-a-valid-url")
            }

            it("accepts https URLs for universal link simulation without crashing") {
                expect {
                    urlOpener.openDeeplink("https://example.com/page")
                }.notTo(raiseException())
            }

            it("opens custom URL scheme deeplinks through the single system open handler") {
                // `openURLSchemeDeeplink` must have exactly one delivery path — `openURLHandler`
                // (real `UIApplication.open`), which iOS itself routes to
                // `SceneDelegate.scene(_:openURLContexts:)` under UIScene or
                // `AppDelegate.application(_:open:options:)` on the legacy lifecycle. There must
                // be no separate, unconditional manual AppDelegate short-circuit ahead of it —
                // that would both mask the UIScene delivery path for apps whose AppDelegate still
                // implements `application(_:open:options:)`, and risk invoking the AppDelegate
                // handler twice (see `defaultOpenURLHandler`'s own fallback).
                var openedURL: URL?
                var openCallCount = 0
                let scenedUrlOpener = UrlOpener(openURLHandler: { url, _ in
                    openedURL = url
                    openCallCount += 1
                })

                scenedUrlOpener.openDeeplink("exponea://mobile-sdk-example-apps.web.app/exponea/anonymize.html")

                expect(openedURL?.absoluteString)
                    .to(equal("exponea://mobile-sdk-example-apps.web.app/exponea/anonymize.html"))
                expect(openCallCount).to(equal(1))
            }

            context("UIScene delivery") {
                beforeEach {
                    IntegrationManager.shared.isStopped = false
                }

                it("forwards the user activity to the foreground-active scene when its delegate implements scene(_:continue:)") {
                    let backgroundScene = MockSceneForwarding(isForegroundActive: false, canForwardUniversalLink: true)
                    let activeScene = MockSceneForwarding(isForegroundActive: true, canForwardUniversalLink: true)
                    let scenedUrlOpener = UrlOpener(connectedWindowScenesProvider: {
                        [backgroundScene, activeScene]
                    })

                    scenedUrlOpener.openDeeplink("https://example.com/page")

                    expect(activeScene.forwardedActivity?.webpageURL?.absoluteString)
                        .to(equal("https://example.com/page"))
                    expect(backgroundScene.forwardedActivity).to(beNil())
                }

                it("ignores scenes whose delegate does not implement scene(_:continue:)") {
                    let nonForwardingScene = MockSceneForwarding(isForegroundActive: true, canForwardUniversalLink: false)
                    let scenedUrlOpener = UrlOpener(connectedWindowScenesProvider: {
                        [nonForwardingScene]
                    })

                    scenedUrlOpener.openDeeplink("https://example.com/page")

                    expect(nonForwardingScene.forwardedActivity).to(beNil())
                }

                it("tracks the campaign click directly when no connected scene delegate implements forwarding") {
                    let exponea = MockExponeaImplementation()
                    Exponea.shared = exponea
                    exponea.configure(plistName: "ExponeaConfig")

                    let nonForwardingScene = MockSceneForwarding(isForegroundActive: true, canForwardUniversalLink: false)
                    let scenedUrlOpener = UrlOpener(connectedWindowScenesProvider: {
                        [nonForwardingScene]
                    })

                    // `xnpe_cmp` is required for `trackCampaignClick` to consider the campaign data valid.
                    scenedUrlOpener.openDeeplink("https://example.com/page?xnpe_cmp=cmp123")

                    let campaignClick = findEvent(exponea: exponea, eventType: "campaign_click")
                    expect(campaignClick).notTo(beNil())
                }

                it("still falls back to URL opening when no connected scene delegate implements forwarding") {
                    let exponea = MockExponeaImplementation()
                    Exponea.shared = exponea
                    exponea.configure(plistName: "ExponeaConfig")

                    let nonForwardingScene = MockSceneForwarding(isForegroundActive: true, canForwardUniversalLink: false)
                    var openedURL: URL?
                    let scenedUrlOpener = UrlOpener(
                        connectedWindowScenesProvider: { [nonForwardingScene] },
                        openURLHandler: { url, _ in openedURL = url }
                    )

                    scenedUrlOpener.openDeeplink("https://example.com/page?xnpe_cmp=cmp123")

                    let campaignClick = findEvent(exponea: exponea, eventType: "campaign_click")
                    expect(campaignClick).notTo(beNil())
                    expect(openedURL?.absoluteString).to(equal("https://example.com/page?xnpe_cmp=cmp123"))
                }

                it("does not double-track when a scene delegate does implement forwarding") {
                    let exponea = MockExponeaImplementation()
                    Exponea.shared = exponea
                    exponea.configure(plistName: "ExponeaConfig")

                    let forwardingScene = MockSceneForwarding(isForegroundActive: true, canForwardUniversalLink: true)
                    let scenedUrlOpener = UrlOpener(connectedWindowScenesProvider: {
                        [forwardingScene]
                    })

                    scenedUrlOpener.openDeeplink("https://example.com/page?xnpe_cmp=cmp123")

                    // Forwarding is delegated to the (mocked) scene delegate, which in a real app
                    // would perform its own tracking (e.g. via `ExponeaSceneDelegate`) — `UrlOpener`
                    // itself must not also call `handleUniversalLink` in this branch.
                    expect(forwardingScene.forwardedActivity).notTo(beNil())
                    let campaignClick = findEvent(exponea: exponea, eventType: "campaign_click")
                    expect(campaignClick).to(beNil())
                }

                it("falls back to URL scheme opening without crashing when no scene is connected at all") {
                    var openedURL: URL?
                    let scenedUrlOpener = UrlOpener(
                        connectedWindowScenesProvider: { [] },
                        openURLHandler: { url, _ in openedURL = url }
                    )
                    scenedUrlOpener.openDeeplink("https://example.com/page")

                    expect(openedURL?.absoluteString).to(equal("https://example.com/page"))
                }
            }
        }
    }
}

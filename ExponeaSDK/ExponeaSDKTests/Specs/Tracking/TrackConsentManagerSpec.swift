//
//  TrackConsentManagerSpec.swift
//  ExponeaSDKTests
//
//  Created by Adam Mihalik on 28/09/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//

import Foundation
import Nimble
import Mockingjay
import Quick

@testable import ExponeaSDK
@testable import ExponeaSDKShared

final class TrackConsentManagerSpec: QuickSpec {
    
    let EXAMPLE_LINK_NON_FORCED = "https://example.com/action"
    let EXAMPLE_LINK_FORCED = "https://example.com/action?xnpe_force_track"
    
    struct TestCaseSetup {
        let expectTrackEvent: Bool
        let description: String
        let consentMode: MODE
        let invoke: (TrackingConsentManagerType, MODE) -> Void
        let expectingConsentCategory: String?
        let expectingTrackType: EventType?
        let expectedInapEventType: InAppMessageEvent?
    }
    
    override func spec() {
        describe("TrackingManager") {
            var onEventOccuredCalls: Int = 0
            var trackingManager: MockTrackingManager!
            var trackingConsentManager: TrackingConsentManagerType!
            beforeEach {
                onEventOccuredCalls = 0
                trackingManager = MockTrackingManager(onEventCallback: { _, _ in
                    onEventOccuredCalls += 1
                })
                trackingManager.clearCalls()
                trackingConsentManager = TrackingConsentManager(trackingManager: trackingManager)
            }
            let testsConfs = [
                // INAPP show
                TestCaseSetup(
                    expectTrackEvent: true,
                    description: "when showing inapp with TRUE tracking consent and consider it",
                    consentMode: .CONSIDER_CONSENT,
                    invoke: { manager, mode in
                        let message = SampleInAppMessage.getSampleInAppMessage(
                            hasTrackingConsent: true,
                            consentCategoryTracking: "I have consent"
                        )
                        manager.trackInAppMessageShown(message: message, mode: mode)
                    },
                    expectingConsentCategory: "I have consent",
                    expectingTrackType: .banner,
                    expectedInapEventType: .show
                ),
                TestCaseSetup(
                    expectTrackEvent: true,
                    description: "when showing inapp with TRUE tracking consent and ignore it",
                    consentMode: .IGNORE_CONSENT,
                    invoke: { manager, mode in
                        let message = SampleInAppMessage.getSampleInAppMessage(
                            hasTrackingConsent: true,
                            consentCategoryTracking: "I have consent"
                        )
                        manager.trackInAppMessageShown(message: message, mode: mode)
                    },
                    expectingConsentCategory: "I have consent",
                    expectingTrackType: .banner,
                    expectedInapEventType: .show
                ),
                TestCaseSetup(
                    expectTrackEvent: false,
                    description: "when showing inapp with FALSE tracking consent and consider it",
                    consentMode: .CONSIDER_CONSENT,
                    invoke: { manager, mode in
                        let message = SampleInAppMessage.getSampleInAppMessage(
                            hasTrackingConsent: false,
                            consentCategoryTracking: "I have consent"
                        )
                        manager.trackInAppMessageShown(message: message, mode: mode)
                    },
                    expectingConsentCategory: nil,
                    expectingTrackType: nil,
                    expectedInapEventType: nil
                ),
                TestCaseSetup(
                    expectTrackEvent: true,
                    description: "when showing inapp with FALSE tracking consent and ignore it",
                    consentMode: .IGNORE_CONSENT,
                    invoke: { manager, mode in
                        let message = SampleInAppMessage.getSampleInAppMessage(
                            hasTrackingConsent: false,
                            consentCategoryTracking: "I have consent"
                        )
                        manager.trackInAppMessageShown(message: message, mode: mode)
                    },
                    expectingConsentCategory: "I have consent",
                    expectingTrackType: .banner,
                    expectedInapEventType: .show
                ),
                // INAPP Close
                TestCaseSetup(
                    expectTrackEvent: true,
                    description: "when closing inapp with TRUE tracking consent and consider it",
                    consentMode: .CONSIDER_CONSENT,
                    invoke: { manager, mode in
                        let message = SampleInAppMessage.getSampleInAppMessage(
                            hasTrackingConsent: true,
                            consentCategoryTracking: "I have consent"
                        )
                        manager.trackInAppMessageClose(message: message, mode: mode)
                    },
                    expectingConsentCategory: "I have consent",
                    expectingTrackType: .banner,
                    expectedInapEventType: .close
                ),
                TestCaseSetup(
                    expectTrackEvent: true,
                    description: "when closing inapp with TRUE tracking consent and ignore it",
                    consentMode: .IGNORE_CONSENT,
                    invoke: { manager, mode in
                        let message = SampleInAppMessage.getSampleInAppMessage(
                            hasTrackingConsent: true,
                            consentCategoryTracking: "I have consent"
                        )
                        manager.trackInAppMessageClose(message: message, mode: mode)
                    },
                    expectingConsentCategory: "I have consent",
                    expectingTrackType: .banner,
                    expectedInapEventType: .close
                ),
                TestCaseSetup(
                    expectTrackEvent: false,
                    description: "when closing inapp with FALSE tracking consent and consider it",
                    consentMode: .CONSIDER_CONSENT,
                    invoke: { manager, mode in
                        let message = SampleInAppMessage.getSampleInAppMessage(
                            hasTrackingConsent: false,
                            consentCategoryTracking: "I have consent"
                        )
                        manager.trackInAppMessageClose(message: message, mode: mode)
                    },
                    expectingConsentCategory: nil,
                    expectingTrackType: nil,
                    expectedInapEventType: nil
                ),
                TestCaseSetup(
                    expectTrackEvent: true,
                    description: "when closing inapp with FALSE tracking consent and ignore it",
                    consentMode: .IGNORE_CONSENT,
                    invoke: { manager, mode in
                        let message = SampleInAppMessage.getSampleInAppMessage(
                            hasTrackingConsent: false,
                            consentCategoryTracking: "I have consent"
                        )
                        manager.trackInAppMessageClose(message: message, mode: mode)
                    },
                    expectingConsentCategory: "I have consent",
                    expectingTrackType: .banner,
                    expectedInapEventType: .close
                ),
                // INAPP Error
                TestCaseSetup(
                    expectTrackEvent: true,
                    description: "when erroring inapp with TRUE tracking consent and consider it",
                    consentMode: .CONSIDER_CONSENT,
                    invoke: { manager, mode in
                        let message = SampleInAppMessage.getSampleInAppMessage(
                            hasTrackingConsent: true,
                            consentCategoryTracking: "I have consent"
                        )
                        manager.trackInAppMessageError(message: message, error: "some error", mode: mode)
                    },
                    expectingConsentCategory: "I have consent",
                    expectingTrackType: .banner,
                    expectedInapEventType: .error(message: "some error")
                ),
                TestCaseSetup(
                    expectTrackEvent: true,
                    description: "when erroring inapp with TRUE tracking consent and ignore it",
                    consentMode: .IGNORE_CONSENT,
                    invoke: { manager, mode in
                        let message = SampleInAppMessage.getSampleInAppMessage(
                            hasTrackingConsent: true,
                            consentCategoryTracking: "I have consent"
                        )
                        manager.trackInAppMessageError(message: message, error: "some error", mode: mode)
                    },
                    expectingConsentCategory: "I have consent",
                    expectingTrackType: .banner,
                    expectedInapEventType: .error(message: "some error")
                ),
                TestCaseSetup(
                    expectTrackEvent: false,
                    description: "when erroring inapp with FALSE tracking consent and consider it",
                    consentMode: .CONSIDER_CONSENT,
                    invoke: { manager, mode in
                        let message = SampleInAppMessage.getSampleInAppMessage(
                            hasTrackingConsent: false,
                            consentCategoryTracking: "I have consent"
                        )
                        manager.trackInAppMessageError(message: message, error: "some error", mode: mode)
                    },
                    expectingConsentCategory: nil,
                    expectingTrackType: nil,
                    expectedInapEventType: nil
                ),
                TestCaseSetup(
                    expectTrackEvent: true,
                    description: "when erroring inapp with FALSE tracking consent and ignore it",
                    consentMode: .IGNORE_CONSENT,
                    invoke: { manager, mode in
                        let message = SampleInAppMessage.getSampleInAppMessage(
                            hasTrackingConsent: false,
                            consentCategoryTracking: "I have consent"
                        )
                        manager.trackInAppMessageError(message: message, error: "some error", mode: mode)
                    },
                    expectingConsentCategory: "I have consent",
                    expectingTrackType: .banner,
                    expectedInapEventType: .error(message: "some error")
                ),
                // INAPP click - non Forced
                TestCaseSetup(
                    expectTrackEvent: true,
                    description: "when clicking inapp with TRUE tracking consent without force-track and consider it",
                    consentMode: .CONSIDER_CONSENT,
                    invoke: { manager, mode in
                        let message = SampleInAppMessage.getSampleInAppMessage(
                            hasTrackingConsent: true,
                            consentCategoryTracking: "I have consent"
                        )
                        manager.trackInAppMessageClick(
                            message: message,
                            buttonText: "click me",
                            buttonLink: self.EXAMPLE_LINK_NON_FORCED,
                            mode: mode
                        )
                    },
                    expectingConsentCategory: "I have consent",
                    expectingTrackType: .banner,
                    expectedInapEventType: .click(buttonLabel: "click me", url: self.EXAMPLE_LINK_NON_FORCED)
                ),
                TestCaseSetup(
                    expectTrackEvent: true,
                    description: "when clicking inapp with TRUE tracking consent without force-track and ignore it",
                    consentMode: .IGNORE_CONSENT,
                    invoke: { manager, mode in
                        let message = SampleInAppMessage.getSampleInAppMessage(
                            hasTrackingConsent: true,
                            consentCategoryTracking: "I have consent"
                        )
                        manager.trackInAppMessageClick(
                            message: message,
                            buttonText: "click me",
                            buttonLink: self.EXAMPLE_LINK_NON_FORCED,
                            mode: mode
                        )
                    },
                    expectingConsentCategory: "I have consent",
                    expectingTrackType: .banner,
                    expectedInapEventType: .click(buttonLabel: "click me", url: self.EXAMPLE_LINK_NON_FORCED)
                ),
                TestCaseSetup(
                    expectTrackEvent: false,
                    description: "when clicking inapp with FALSE tracking consent without force-track and consider it",
                    consentMode: .CONSIDER_CONSENT,
                    invoke: { manager, mode in
                        let message = SampleInAppMessage.getSampleInAppMessage(
                            hasTrackingConsent: false,
                            consentCategoryTracking: "I have consent"
                        )
                        manager.trackInAppMessageClick(
                            message: message,
                            buttonText: "click me",
                            buttonLink: self.EXAMPLE_LINK_NON_FORCED,
                            mode: mode
                        )
                    },
                    expectingConsentCategory: nil,
                    expectingTrackType: nil,
                    expectedInapEventType: nil
                ),
                TestCaseSetup(
                    expectTrackEvent: true,
                    description: "when clicking inapp with FALSE tracking without force-track consent and ignore it",
                    consentMode: .IGNORE_CONSENT,
                    invoke: { manager, mode in
                        let message = SampleInAppMessage.getSampleInAppMessage(
                            hasTrackingConsent: false,
                            consentCategoryTracking: "I have consent"
                        )
                        manager.trackInAppMessageClick(
                            message: message,
                            buttonText: "click me",
                            buttonLink: self.EXAMPLE_LINK_NON_FORCED,
                            mode: mode
                        )
                    },
                    expectingConsentCategory: "I have consent",
                    expectingTrackType: .banner,
                    expectedInapEventType: .click(buttonLabel: "click me", url: self.EXAMPLE_LINK_NON_FORCED)
                ),
                // INAPP click - Forced
                TestCaseSetup(
                    expectTrackEvent: true,
                    description: "when clicking inapp with TRUE tracking consent with force-track and consider it",
                    consentMode: .CONSIDER_CONSENT,
                    invoke: { manager, mode in
                        let message = SampleInAppMessage.getSampleInAppMessage(
                            hasTrackingConsent: true,
                            consentCategoryTracking: "I have consent"
                        )
                        manager.trackInAppMessageClick(
                            message: message,
                            buttonText: "click me",
                            buttonLink: self.EXAMPLE_LINK_FORCED,
                            mode: mode
                        )
                    },
                    expectingConsentCategory: "I have consent",
                    expectingTrackType: .banner,
                    expectedInapEventType: .click(buttonLabel: "click me", url: self.EXAMPLE_LINK_FORCED)
                ),
                TestCaseSetup(
                    expectTrackEvent: true,
                    description: "when clicking inapp with TRUE tracking consent with force-track and ignore it",
                    consentMode: .IGNORE_CONSENT,
                    invoke: { manager, mode in
                        let message = SampleInAppMessage.getSampleInAppMessage(
                            hasTrackingConsent: true,
                            consentCategoryTracking: "I have consent"
                        )
                        manager.trackInAppMessageClick(
                            message: message,
                            buttonText: "click me",
                            buttonLink: self.EXAMPLE_LINK_FORCED,
                            mode: mode
                        )
                    },
                    expectingConsentCategory: "I have consent",
                    expectingTrackType: .banner,
                    expectedInapEventType: .click(buttonLabel: "click me", url: self.EXAMPLE_LINK_FORCED)
                ),
                TestCaseSetup(
                    expectTrackEvent: true,
                    description: "when clicking inapp with FALSE tracking consent with force-track and consider it",
                    consentMode: .CONSIDER_CONSENT,
                    invoke: { manager, mode in
                        let message = SampleInAppMessage.getSampleInAppMessage(
                            hasTrackingConsent: false,
                            consentCategoryTracking: "I have consent"
                        )
                        manager.trackInAppMessageClick(
                            message: message,
                            buttonText: "click me",
                            buttonLink: self.EXAMPLE_LINK_FORCED,
                            mode: mode
                        )
                    },
                    expectingConsentCategory: "I have consent",
                    expectingTrackType: .banner,
                    expectedInapEventType: .click(buttonLabel: "click me", url: self.EXAMPLE_LINK_FORCED)
                ),
                TestCaseSetup(
                    expectTrackEvent: true,
                    description: "when clicking inapp with FALSE tracking with force-track consent and ignore it",
                    consentMode: .IGNORE_CONSENT,
                    invoke: { manager, mode in
                        let message = SampleInAppMessage.getSampleInAppMessage(
                            hasTrackingConsent: false,
                            consentCategoryTracking: "I have consent"
                        )
                        manager.trackInAppMessageClick(
                            message: message,
                            buttonText: "click me",
                            buttonLink: self.EXAMPLE_LINK_FORCED,
                            mode: mode
                        )
                    },
                    expectingConsentCategory: "I have consent",
                    expectingTrackType: .banner,
                    expectedInapEventType: .click(buttonLabel: "click me", url: self.EXAMPLE_LINK_FORCED)
                ),
                // Delivered PUSH notif
                TestCaseSetup(
                    expectTrackEvent: true,
                    description: "when delivered push notif with TRUE tracking consent and consider it",
                    consentMode: .CONSIDER_CONSENT,
                    invoke: { manager, mode in
                        let notifData = NotificationData.deserialize(
                            attributes: [:],
                            campaignData: [:],
                            consentCategoryTracking: "I have consent",
                            hasTrackingConsent: GdprTracking.readTrackingConsentFlag(true),
                            considerConsent: true
                        )
                        manager.trackDeliveredPush(data: notifData!)
                    },
                    expectingConsentCategory: "I have consent",
                    expectingTrackType: .pushDelivered,
                    expectedInapEventType: nil
                ),
                TestCaseSetup(
                    expectTrackEvent: true,
                    description: "when delivered push notif with TRUE tracking consent and ignore it",
                    consentMode: .IGNORE_CONSENT,
                    invoke: { manager, mode in
                        let notifData = NotificationData.deserialize(
                            attributes: [:],
                            campaignData: [:],
                            consentCategoryTracking: "I have consent",
                            hasTrackingConsent: GdprTracking.readTrackingConsentFlag(true),
                            considerConsent: false
                        )
                        manager.trackDeliveredPush(data: notifData!)
                    },
                    expectingConsentCategory: "I have consent",
                    expectingTrackType: .pushDelivered,
                    expectedInapEventType: nil
                ),
                TestCaseSetup(
                    expectTrackEvent: false,
                    description: "when delivered push notif with FALSE tracking consent and consider it",
                    consentMode: .CONSIDER_CONSENT,
                    invoke: { manager, mode in
                        let notifData = NotificationData.deserialize(
                            attributes: [:],
                            campaignData: [:],
                            consentCategoryTracking: "I have consent",
                            hasTrackingConsent: GdprTracking.readTrackingConsentFlag(false),
                            considerConsent: true
                        )
                        manager.trackDeliveredPush(data: notifData!)
                    },
                    expectingConsentCategory: nil,
                    expectingTrackType: nil,
                    expectedInapEventType: nil
                ),
                TestCaseSetup(
                    expectTrackEvent: true,
                    description: "when delivered push notif with FALSE tracking consent and ignore it",
                    consentMode: .IGNORE_CONSENT,
                    invoke: { manager, mode in
                        let notifData = NotificationData.deserialize(
                            attributes: [:],
                            campaignData: [:],
                            consentCategoryTracking: "I have consent",
                            hasTrackingConsent: GdprTracking.readTrackingConsentFlag(false),
                            considerConsent: false
                        )
                        manager.trackDeliveredPush(data: notifData!)
                    },
                    expectingConsentCategory: "I have consent",
                    expectingTrackType: .pushDelivered,
                    expectedInapEventType: nil
                ),
                // Clicked PUSH notif - not forced
                TestCaseSetup(
                    expectTrackEvent: true,
                    description: "when opened push notif with TRUE tracking consent and consider it",
                    consentMode: .CONSIDER_CONSENT,
                    invoke: { manager, mode in
                        do {
                            let userInfo = try JSONSerialization.jsonObject(
                                with: PushNotificationsTestData()
                                    .deliveredNotificationWithConsent("true", "I have consent")
                                    .data(using: String.Encoding.utf8)!,
                                options: []
                            ) as AnyObject
                            let notifData = PushNotificationParser.parsePushOpened(
                                userInfoObject: userInfo,
                                actionIdentifier: "com.apple.UNNotificationDefaultActionIdentifier",
                                timestamp: PushNotificationsTestData.timestamp,
                                considerConsent: true
                            )
                            manager.trackClickedPush(data: notifData!)
                        } catch {
                            // nothing
                        }
                    },
                    expectingConsentCategory: "I have consent",
                    expectingTrackType: .pushOpened,
                    expectedInapEventType: nil
                ),
                TestCaseSetup(
                    expectTrackEvent: true,
                    description: "when opened push notif with TRUE tracking consent and ignore it",
                    consentMode: .IGNORE_CONSENT,
                    invoke: { manager, mode in
                        do {
                            let userInfo = try JSONSerialization.jsonObject(
                                with: PushNotificationsTestData()
                                    .deliveredNotificationWithConsent("true", "I have consent")
                                    .data(using: String.Encoding.utf8)!,
                                options: []
                            ) as AnyObject
                            let notifData = PushNotificationParser.parsePushOpened(
                                userInfoObject: userInfo,
                                actionIdentifier: "com.apple.UNNotificationDefaultActionIdentifier",
                                timestamp: PushNotificationsTestData.timestamp,
                                considerConsent: false
                            )
                            manager.trackClickedPush(data: notifData!)
                        } catch {
                            // nothing
                        }
                    },
                    expectingConsentCategory: "I have consent",
                    expectingTrackType: .pushOpened,
                    expectedInapEventType: nil
                ),
                TestCaseSetup(
                    expectTrackEvent: false,
                    description: "when opened push notif with FALSE tracking consent and consider it",
                    consentMode: .CONSIDER_CONSENT,
                    invoke: { manager, mode in
                        do {
                            let userInfo = try JSONSerialization.jsonObject(
                                with: PushNotificationsTestData()
                                    .deliveredNotificationWithConsent("false", "I have consent")
                                    .data(using: String.Encoding.utf8)!,
                                options: []
                            ) as AnyObject
                            let notifData = PushNotificationParser.parsePushOpened(
                                userInfoObject: userInfo,
                                actionIdentifier: "com.apple.UNNotificationDefaultActionIdentifier",
                                timestamp: PushNotificationsTestData.timestamp,
                                considerConsent: true
                            )
                            manager.trackClickedPush(data: notifData!)
                        } catch {
                            // nothing
                        }
                    },
                    expectingConsentCategory: nil,
                    expectingTrackType: nil,
                    expectedInapEventType: nil
                ),
                TestCaseSetup(
                    expectTrackEvent: true,
                    description: "when opened push with FALSE tracking consent and ignore it",
                    consentMode: .IGNORE_CONSENT,
                    invoke: { manager, mode in
                        do {
                            let userInfo = try JSONSerialization.jsonObject(
                                with: PushNotificationsTestData()
                                    .deliveredNotificationWithConsent("true", "I have consent")
                                    .data(using: String.Encoding.utf8)!,
                                options: []
                            ) as AnyObject
                            let notifData = PushNotificationParser.parsePushOpened(
                                userInfoObject: userInfo,
                                actionIdentifier: "com.apple.UNNotificationDefaultActionIdentifier",
                                timestamp: PushNotificationsTestData.timestamp,
                                considerConsent: false
                            )
                            manager.trackClickedPush(data: notifData!)
                        } catch {
                            // nothing
                        }
                    },
                    expectingConsentCategory: "I have consent",
                    expectingTrackType: .pushOpened,
                    expectedInapEventType: nil
                ),
                // Clicked PUSH notif - forced
                TestCaseSetup(
                    expectTrackEvent: true,
                    description: "when opened push notif with TRUE tracking consent and FORCED action and consider it",
                    consentMode: .CONSIDER_CONSENT,
                    invoke: { manager, mode in
                        do {
                            let userInfo = try JSONSerialization.jsonObject(
                                with: PushNotificationsTestData()
                                    .deliveredNotificationWithConsent(
                                        "true",
                                        "I have consent",
                                        "browser",
                                        "https://google.com/action?xnpe_force_track=true"
                                    )
                                    .data(using: String.Encoding.utf8)!,
                                options: []
                            ) as AnyObject
                            let notifData = PushNotificationParser.parsePushOpened(
                                userInfoObject: userInfo,
                                actionIdentifier: "2",
                                timestamp: PushNotificationsTestData.timestamp,
                                considerConsent: true
                            )
                            manager.trackClickedPush(data: notifData!)
                        } catch {
                            // nothing
                        }
                    },
                    expectingConsentCategory: "I have consent",
                    expectingTrackType: .pushOpened,
                    expectedInapEventType: nil
                ),
                TestCaseSetup(
                    expectTrackEvent: true,
                    description: "when opened push notif with TRUE tracking consent and FORCED action and ignore it",
                    consentMode: .IGNORE_CONSENT,
                    invoke: { manager, mode in
                        do {
                            let userInfo = try JSONSerialization.jsonObject(
                                with: PushNotificationsTestData()
                                    .deliveredNotificationWithConsent(
                                        "true",
                                        "I have consent",
                                        "browser",
                                        "https://google.com/action?xnpe_force_track=true"
                                    )
                                    .data(using: String.Encoding.utf8)!,
                                options: []
                            ) as AnyObject
                            let notifData = PushNotificationParser.parsePushOpened(
                                userInfoObject: userInfo,
                                actionIdentifier: "2",
                                timestamp: PushNotificationsTestData.timestamp,
                                considerConsent: false
                            )
                            manager.trackClickedPush(data: notifData!)
                        } catch {
                            // nothing
                        }
                    },
                    expectingConsentCategory: "I have consent",
                    expectingTrackType: .pushOpened,
                    expectedInapEventType: nil
                ),
                TestCaseSetup(
                    expectTrackEvent: true,
                    description: "when opened push notif with FALSE tracking consent but FORCED action and consider it",
                    consentMode: .CONSIDER_CONSENT,
                    invoke: { manager, mode in
                        do {
                            let userInfo = try JSONSerialization.jsonObject(
                                with: PushNotificationsTestData()
                                    .deliveredNotificationWithConsent(
                                        "false",
                                        "I have consent",
                                        "browser",
                                        "https://google.com/action?xnpe_force_track=true"
                                    )
                                    .data(using: String.Encoding.utf8)!,
                                options: []
                            ) as AnyObject
                            let notifData = PushNotificationParser.parsePushOpened(
                                userInfoObject: userInfo,
                                actionIdentifier: "2",
                                timestamp: PushNotificationsTestData.timestamp,
                                considerConsent: true
                            )
                            manager.trackClickedPush(data: notifData!)
                        } catch {
                            // nothing
                        }
                    },
                    expectingConsentCategory: "I have consent",
                    expectingTrackType: .pushOpened,
                    expectedInapEventType: nil
                ),
                TestCaseSetup(
                    expectTrackEvent: true,
                    description: "when opened push notif with FALSE tracking consent but FORCED action and ignore it",
                    consentMode: .IGNORE_CONSENT,
                    invoke: { manager, mode in
                        do {
                            let userInfo = try JSONSerialization.jsonObject(
                                with: PushNotificationsTestData()
                                    .deliveredNotificationWithConsent(
                                        "false",
                                        "I have consent",
                                        "browser",
                                        "https://google.com/action?xnpe_force_track=true"
                                    )
                                    .data(using: String.Encoding.utf8)!,
                                options: []
                            ) as AnyObject
                            let notifData = PushNotificationParser.parsePushOpened(
                                userInfoObject: userInfo,
                                actionIdentifier: "2",
                                timestamp: PushNotificationsTestData.timestamp,
                                considerConsent: false
                            )
                            manager.trackClickedPush(data: notifData!)
                        } catch {
                            // nothing
                        }
                    },
                    expectingConsentCategory: "I have consent",
                    expectingTrackType: .pushOpened,
                    expectedInapEventType: nil
                )
            ]
            testsConfs.forEach { testCaseConf in
                let testNamePrefix = testCaseConf.expectTrackEvent ? "should" : "shouldn't"
                it("\(testNamePrefix) track event \(testCaseConf.description)") {
                    testCaseConf.invoke(trackingConsentManager, testCaseConf.consentMode)
                    expect(onEventOccuredCalls).to(be(1))
                    if (testCaseConf.expectedInapEventType == nil) {
                        expect(trackingManager.trackedInappEvents).to(beEmpty())
                    }
                    if (testCaseConf.expectTrackEvent == false) {
                        expect(trackingManager.trackedEvents).to(beEmpty())
                        return
                    }
                    // Should track so:
                    if let inappType = testCaseConf.expectedInapEventType {
                        expect(trackingManager.trackedInappEvents.count).to(equal(1))
                        expect(trackingManager.trackedInappEvents[0].event.action).to(equal(inappType.action))
                    }
                    expect(trackingManager.trackedEvents.count).to(equal(1))
                    if trackingManager.trackedEvents.count == 0 {
                        return
                    }
                    let trackedEvent = trackingManager.trackedEvents[0]
                    expect(trackedEvent.type).to(equal(testCaseConf.expectingTrackType))
                    if (testCaseConf.expectingConsentCategory == nil) {
                        expect(trackedEvent.data?.properties["consent_category_tracking"] as? String).to(beNil())
                    } else {
                        expect(trackedEvent.data?.properties["consent_category_tracking"] as? String).to(equal(testCaseConf.expectingConsentCategory))
                    }
                }
            }
            it("Should not contains track_forced field for delivered push") {
                trackingConsentManager.trackDeliveredPush(data: NotificationData.deserialize(
                    attributes: [:],
                    campaignData: [:],
                    consentCategoryTracking: "I have consent",
                    hasTrackingConsent: true,
                    considerConsent: false
                )!)
                checkForEventWithoutForceTrack()
            }
            it("Should not contains track_forced field for shown inapp") {
                trackingConsentManager.trackInAppMessageShown(message: SampleInAppMessage.getSampleInAppMessage(
                    hasTrackingConsent: true,
                    consentCategoryTracking: "I have consent"
                ), mode: .IGNORE_CONSENT)
                checkForEventWithoutForceTrack()
            }
            it("Should not contains track_forced field for closed inapp") {
                trackingConsentManager.trackInAppMessageClose(message: SampleInAppMessage.getSampleInAppMessage(
                    hasTrackingConsent: true,
                    consentCategoryTracking: "I have consent"
                ), mode: .IGNORE_CONSENT)
                checkForEventWithoutForceTrack()
            }
            it("Should not contains track_forced field for error inapp") {
                trackingConsentManager.trackInAppMessageError(message: SampleInAppMessage.getSampleInAppMessage(
                    hasTrackingConsent: true,
                    consentCategoryTracking: "I have consent"
                ), error: "error", mode: .IGNORE_CONSENT)
                checkForEventWithoutForceTrack()
            }
            it("Should not contains track_forced field for clicked push without forced url") {
                let userInfo = try JSONSerialization.jsonObject(
                    with: PushNotificationsTestData()
                        .deliveredNotificationWithConsent(
                            "true",
                            "I have consent",
                            "browser",
                            "https://google.com/action"
                        )
                        .data(using: String.Encoding.utf8)!,
                    options: []
                ) as AnyObject
                let notifData = PushNotificationParser.parsePushOpened(
                    userInfoObject: userInfo,
                    actionIdentifier: "2",
                    timestamp: PushNotificationsTestData.timestamp,
                    considerConsent: false
                )
                trackingConsentManager.trackClickedPush(data: notifData!)
                checkForEventWithoutForceTrack()
            }
            it("Should contains track_forced field for clicked push with forced url") {
                let userInfo = try JSONSerialization.jsonObject(
                    with: PushNotificationsTestData()
                        .deliveredNotificationWithConsent(
                            "true",
                            "I have consent",
                            "browser",
                            "https://google.com/action?xnpe_force_track=true"
                        )
                        .data(using: String.Encoding.utf8)!,
                    options: []
                ) as AnyObject
                let notifData = PushNotificationParser.parsePushOpened(
                    userInfoObject: userInfo,
                    actionIdentifier: "2",
                    timestamp: PushNotificationsTestData.timestamp,
                    considerConsent: false
                )
                trackingConsentManager.trackClickedPush(data: notifData!)
                checkForEventWithForceTrack()
            }
            it("Should not contains track_forced field for clicked inapp without forced url") {
                trackingConsentManager.trackInAppMessageClick(message: SampleInAppMessage.getSampleInAppMessage(
                    hasTrackingConsent: true,
                    consentCategoryTracking: "I have consent"
                ), buttonText: "Action", buttonLink: "https://google.com/action", mode: .IGNORE_CONSENT)
                checkForEventWithoutForceTrack()
            }
            it("Should contains track_forced field for clicked inapp with forced url") {
                trackingConsentManager.trackInAppMessageClick(message: SampleInAppMessage.getSampleInAppMessage(
                    hasTrackingConsent: true,
                    consentCategoryTracking: "I have consent"
                ), buttonText: "Action", buttonLink: "https://google.com/action?xnpe_force_track=true", mode: .IGNORE_CONSENT)
                checkForEventWithForceTrack()
            }
            func checkForEventWithoutForceTrack() {
                expect(trackingManager.trackedEvents.count).to(equal(1))
                if trackingManager.trackedEvents.count == 0 {
                    // prevents crash, test is marked as fail already
                    return
                }
                let trackedEvent = trackingManager.trackedEvents[0]
                expect(trackedEvent.data?.properties["tracking_forced"]).to(beNil())
            }
            func checkForEventWithForceTrack() {
                expect(trackingManager.trackedEvents.count).to(equal(1))
                if trackingManager.trackedEvents.count == 0 {
                    // prevents crash, test is marked as fail already
                    return
                }
                let trackedEvent = trackingManager.trackedEvents[0]
                expect(trackedEvent.data?.properties["tracking_forced"]).toNot(beNil())
            }
        }
    }
}

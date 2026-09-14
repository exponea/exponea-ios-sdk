//
//  ExponeaSceneDelegateSpec.swift
//  ExponeaSDKTests
//
//  Copyright © 2026 Exponea. All rights reserved.
//

import Quick
import Nimble
import UIKit

@testable import ExponeaSDK

final class ExponeaSceneDelegateSpec: QuickSpec {
    override func spec() {
        let mockData = MockData()

        describe("ExponeaUniversalLinkForwarding") {
            beforeEach {
                IntegrationManager.shared.isStopped = false
            }

            context("warm launch") {
                it("tracks browsing-web universal links") {
                    let exponea = MockExponeaImplementation()
                    Exponea.shared = exponea
                    exponea.configure(plistName: "ExponeaConfig")

                    let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
                    activity.webpageURL = mockData.campaignUrl

                    ExponeaUniversalLinkForwarding.forwardFromUserActivity(activity)

                    let campaignClick = findEvent(exponea: exponea, eventType: "campaign_click")
                    expect(campaignClick).notTo(beNil())
                }

                it("ignores non-browsing-web activities") {
                    let exponea = MockExponeaImplementation()
                    Exponea.shared = exponea
                    exponea.configure(plistName: "ExponeaConfig")

                    let activity = NSUserActivity(activityType: "com.example.other")
                    activity.webpageURL = mockData.campaignUrl

                    ExponeaUniversalLinkForwarding.forwardFromUserActivity(activity)

                    let campaignClick = findEvent(exponea: exponea, eventType: "campaign_click")
                    expect(campaignClick).to(beNil())
                }
            }

            context("cold launch") {
                it("tracks the first browsing-web activity from connection options") {
                    let exponea = MockExponeaImplementation()
                    Exponea.shared = exponea
                    exponea.configure(plistName: "ExponeaConfig")

                    let browsingActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
                    browsingActivity.webpageURL = mockData.campaignUrl
                    let otherActivity = NSUserActivity(activityType: "com.example.other")

                    ExponeaUniversalLinkForwarding.forwardFromUserActivities(
                        Set([otherActivity, browsingActivity])
                    )

                    let campaignClick = findEvent(exponea: exponea, eventType: "campaign_click")
                    expect(campaignClick).notTo(beNil())
                }

                it("ignores connection options without browsing-web activities") {
                    let exponea = MockExponeaImplementation()
                    Exponea.shared = exponea
                    exponea.configure(plistName: "ExponeaConfig")

                    let otherActivity = NSUserActivity(activityType: "com.example.other")
                    otherActivity.webpageURL = mockData.campaignUrl

                    ExponeaUniversalLinkForwarding.forwardFromUserActivities(Set([otherActivity]))

                    let campaignClick = findEvent(exponea: exponea, eventType: "campaign_click")
                    expect(campaignClick).to(beNil())
                }
            }
        }
    }
}


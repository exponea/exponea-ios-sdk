//
//  TrackUniversalLinkSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 07/06/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import CoreData
import Foundation
import Nimble
import Quick
import Mockingjay

@testable import ExponeaSDK

class TrackUniversalLinkSpec: QuickSpec {
    override func spec() {
        let mockData = MockData()

        describe("Track universal link") {
            context("repository") {
                let repository = ServerRepository(configuration: try! Configuration(plistName: "ExponeaConfig"))
                let projectToken = UUID().uuidString
                let data: [DataType] = [.projectToken(projectToken),
                                        .properties(mockData.campaignData),
                                        .timestamp(nil)]
                var lastRequest: URLRequest?
                NetworkStubbing.stubNetwork(
                    forProjectToken: projectToken,
                    withStatusCode: 200,
                    withRequestHook: { request in lastRequest = request }
                )
                waitUntil(timeout: 3) { done in
                    repository.trackEvent(with: data + [.eventType(Constants.EventTypes.campaignClick)], for: mockData.customerIds) { result in
                        it("should have nil result error") {
                            expect(result.error).to(beNil())
                        }
                        it("should call correct url") {
                            expect(lastRequest?.url?.absoluteString)
                                .to(equal("https://api.exponea.com/track/v2/projects/\(projectToken)/campaigns/clicks"))
                        }
                        done()
                    }
                }
            }
            context("Tracking manager") {
                context("with SDK started") {
                    it("track campaign_click and update session when called within update threshold") {
                        let exponea = MockExponea()
                        exponea.configure(plistName: "ExponeaConfig")

                        // track campaign click, session_start should be updated with utm params
                        exponea.trackCampaignClick(url: mockData.campaignUrl!, timestamp: nil)

                        let campaignClick = findEvent(exponea: exponea, eventType: "campaign_click")
                        expect(campaignClick).notTo(beNil())
                        let sessionStart = findEvent(exponea: exponea, eventType: "session_start")
                        expect(sessionStart).notTo(beNil())
                        expect(sessionStart!.properties?["utm_campaign"]?.rawValue as? String).to(equal("mycampaign"))
                    }
                    it("track campaign_click and should not update session when called after update threshold") {
                        let exponea = MockExponea()
                        exponea.configure(plistName: "ExponeaConfig")
                        Exponea.logger.logLevel = .verbose
                        expect {
                            try exponea.trackingManager!.updateLastPendingEvent(
                                ofType: Constants.EventTypes.sessionStart,
                                with: .timestamp(Date().timeIntervalSince1970 - Constants.Session.sessionUpdateThreshold))
                        }.notTo(raiseException())

                        // track campaign click, session_start should not be updated with utm params
                        exponea.trackCampaignClick(url: mockData.campaignUrl!, timestamp: nil)

                        let campaignClick = findEvent(exponea: exponea, eventType: "campaign_click")
                        expect(campaignClick).notTo(beNil())
                        let sessionStart = findEvent(exponea: exponea, eventType: "session_start")
                        expect(sessionStart).toNot(beNil())
                        expect(sessionStart!.properties?["utm_campaign"]?.rawValue as? String).to(beNil())
                    }
                }
                context("before SDK started") {
                    it("track campaign_click and update session when called within update threshold") {
                        let exponea = MockExponea()

                        // track campaign click, session_start should be updated with utm params
                        exponea.trackCampaignClick(url: mockData.campaignUrl!, timestamp: nil)

                        exponea.configure(plistName: "ExponeaConfig")

                        let campaignClick = findEvent(exponea: exponea, eventType: "campaign_click")
                        expect(campaignClick).notTo(beNil())
                        let sessionStart = findEvent(exponea: exponea, eventType: "session_start")
                        expect(sessionStart).notTo(beNil())
                        expect(sessionStart!.properties?["utm_campaign"]?.rawValue as? String).to(equal("mycampaign"))
                    }
                    it("processes saved campaigns only once") {
                        let exponea = MockExponea()

                        // track campaign click, session_start should be updated with utm params
                        exponea.trackCampaignClick(url: mockData.campaignUrl!, timestamp: nil)

                        exponea.configure(plistName: "ExponeaConfig")
                        exponea.processSavedCampaignData()
                        var trackEvents: [TrackEventThreadSafe] = []
                        expect { trackEvents = try exponea.fetchTrackEvents() }.toNot(raiseException())
                        expect {trackEvents.filter({ $0.eventType == "campaign_click"}).count }.to(equal(1))
                    }
                }
            }
        }
    }
}

func findEvent(exponea: MockExponea, eventType: String) -> TrackEventThreadSafe? {
    var trackEvents: [TrackEventThreadSafe] = []
    expect { trackEvents = try exponea.fetchTrackEvents() }.toNot(raiseException())
    return trackEvents.first(where: { $0.eventType == eventType })
}

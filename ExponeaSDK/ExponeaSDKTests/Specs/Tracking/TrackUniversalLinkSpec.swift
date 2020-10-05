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
                let data: [DataType] = [
                    .properties(mockData.campaignData),
                    .timestamp(nil),
                    .eventType(Constants.EventTypes.campaignClick)
                ]
                var lastRequest: URLRequest?
                NetworkStubbing.stubNetwork(
                    forProjectToken: projectToken,
                    withStatusCode: 200,
                    withRequestHook: { request in lastRequest = request }
                )
                waitUntil(timeout: .seconds(3)) { done in
                    let event = EventTrackingObject(
                        exponeaProject: ExponeaProject(
                            baseUrl: "https://my-url.com",
                            projectToken: projectToken,
                            authorization: .none
                        ),
                        customerIds: mockData.customerIds,
                        eventType: Constants.EventTypes.campaignClick,
                        timestamp: 123,
                        dataTypes: data
                    )
                    repository.trackObject(event) { result in
                        it("should have nil result error") {
                            expect(result.error).to(beNil())
                        }
                        it("should call correct url") {
                            expect(lastRequest?.url?.absoluteString)
                                .to(equal("https://my-url.com/track/v2/projects/\(projectToken)/campaigns/clicks"))
                        }
                        done()
                    }
                }
            }
            context("Tracking manager") {
                context("with SDK started") {
                    it("track campaign_click and update session when called within update threshold") {
                        let exponea = MockExponeaImplementation()
                        exponea.configure(plistName: "ExponeaConfig")

                        // track campaign click, session_start should be updated with utm params
                        exponea.trackCampaignClick(url: mockData.campaignUrl!, timestamp: nil)

                        let campaignClick = findEvent(exponea: exponea, eventType: "campaign_click")
                        expect(campaignClick).notTo(beNil())
                        let sessionStart = findEvent(exponea: exponea, eventType: "session_start")
                        expect(sessionStart).notTo(beNil())
                        expect(sessionStart!.dataTypes.properties["utm_campaign"] as? String)
                            .to(equal("mycampaign"))
                    }
                    it("track campaign_click and should not update session when called after update threshold") {
                        let exponea = MockExponeaImplementation()
                        exponea.configure(plistName: "ExponeaConfig")
                        Exponea.logger.logLevel = .verbose
                        expect {
                            try exponea.trackingManager!.updateLastPendingEvent(
                                ofType: Constants.EventTypes.sessionStart,
                                with: .timestamp(
                                    Date().timeIntervalSince1970 - Constants.Session.sessionUpdateThreshold
                                )
                            )
                        }.notTo(raiseException())

                        // track campaign click, session_start should not be updated with utm params
                        exponea.trackCampaignClick(url: mockData.campaignUrl!, timestamp: nil)

                        let campaignClick = findEvent(exponea: exponea, eventType: "campaign_click")
                        expect(campaignClick).notTo(beNil())
                        let sessionStart = findEvent(exponea: exponea, eventType: "session_start")
                        expect(sessionStart).toNot(beNil())
                        expect(sessionStart!.dataTypes.properties["utm_campaign"] as? String).to(beNil())
                    }
                }
                context("before SDK started") {
                    it("track campaign_click and update session when called within update threshold") {
                        let exponea = MockExponeaImplementation()

                        // track campaign click, session_start should be updated with utm params
                        exponea.trackCampaignClick(url: mockData.campaignUrl!, timestamp: nil)

                        exponea.configure(plistName: "ExponeaConfig")

                        let campaignClick = findEvent(exponea: exponea, eventType: "campaign_click")
                        expect(campaignClick).notTo(beNil())
                        let sessionStart = findEvent(exponea: exponea, eventType: "session_start")
                        expect(sessionStart).notTo(beNil())
                        expect(sessionStart!.dataTypes.properties["utm_campaign"] as? String)
                            .to(equal("mycampaign"))
                    }
                    it("processes saved campaigns only once") {
                        let exponea = MockExponeaImplementation()

                        // track campaign click, session_start should be updated with utm params
                        exponea.trackCampaignClick(url: mockData.campaignUrl!, timestamp: nil)

                        exponea.configure(plistName: "ExponeaConfig")
                        exponea.processSavedCampaignData()
                        var trackEvents: [TrackEventProxy] = []
                        expect { trackEvents = try exponea.fetchTrackEvents() }.toNot(raiseException())
                        expect { trackEvents.filter({ $0.eventType == "campaign_click" }).count }.to(equal(1))
                    }
                }
            }
        }
    }
}

func findEvent(exponea: MockExponeaImplementation, eventType: String) -> TrackEventProxy? {
    var trackEvents: [TrackEventProxy] = []
    expect { trackEvents = try exponea.fetchTrackEvents() }.toNot(raiseException())
    return trackEvents.first(where: { $0.eventType == eventType })
}

//
//  EventsRequestSpec.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 31/07/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class EventsRequestSpec: QuickSpec {
    override func spec() {
        describe("A event request") {
            context("Setting events for a customer") {
                
                let eventsRequest = EventsRequest(eventTypes: ["install",
                                                               "session_start",
                                                               "session_end"],
                                                  sortOrder: nil,
                                                  limit: nil,
                                                  skip: nil)
                
                it("Should return 3 event types") {
                    expect(eventsRequest.eventTypes.count).to(equal(3))
                }
                
                it("Should return install as first item") {
                    expect(eventsRequest.eventTypes.first).to(equal("install"))
                }
                
                it("Should return session_end as last item") {
                    expect(eventsRequest.eventTypes.last).to(equal("session_end"))
                }
            }
        }
    }
}

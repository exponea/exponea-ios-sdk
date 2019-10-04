//
//  EventTypeSpec.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 31/07/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class EventTypeSpec: QuickSpec {
    override func spec() {
        describe("A device") {
            context("Setting the event types") {

                var eventType: EventType!

                it("Should have type install") {
                    eventType = .install
                    expect(eventType.rawValue).to(equal("INSTALL"))
                }
                it("Should have type session start") {
                    eventType = .sessionStart
                    expect(eventType.rawValue).to(equal("SESSION_START"))
                }
                it("Should have type session end") {
                    eventType = .sessionEnd
                    expect(eventType.rawValue).to(equal("SESSION_END"))
                }
                it("Should have type track event") {
                    eventType = .customEvent
                    expect(eventType.rawValue).to(equal("TRACK_EVENT"))
                }
                it("Should have type track customer") {
                    eventType = .identifyCustomer
                    expect(eventType.rawValue).to(equal("TRACK_CUSTOMER"))
                }
                it("Should have type payment") {
                    eventType = .payment
                    expect(eventType.rawValue).to(equal("PAYMENT"))
                }
                it("Should have type push token") {
                    eventType = .registerPushToken
                    expect(eventType.rawValue).to(equal("PUSH_TOKEN"))
                }
                it("Should have type push delivered") {
                    eventType = .pushDelivered
                    expect(eventType.rawValue).to(equal("PUSH_DELIVERED"))
                }
                it("Should have type push opened") {
                    eventType = .pushOpened
                    expect(eventType.rawValue).to(equal("PUSH_OPENED"))
                }
            }
        }
    }
}

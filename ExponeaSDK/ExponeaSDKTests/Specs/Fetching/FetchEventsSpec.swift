//
//  FetchEventsSpec.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 18/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class FetchEventsSpec: QuickSpec {

    override func spec() {
        describe("Fetch Events") {
            context("Fetch events from mock repository") {

                let configuration = try! Configuration(plistName: "ExponeaConfig")
                let repo = ServerRepository(configuration: configuration)

                NetworkStubbing.stubNetwork(withStatusCode: 200, withResponseData: MockData().eventsResponse)
                let mockData = MockData()

                waitUntil(timeout: 3) { done in
                    repo.fetchEvents(events: mockData.eventRequest, for: mockData.customerIds) { (result) in
                        it("Result error should be nil") {
                            expect(result.error).to(beNil())
                        }

                        it("Result should be true ") {
                            expect(result.value?.success).to(beTrue())
                        }
                        it("Result values should have 3 items") {
                            expect(result.value?.data.count).to(equal(3))
                        }

                        context("Check the values returned from json file") {

                            guard let values =  result.value?.data else {
                                fatalError("Get events should not be empty")
                            }

                            context("Validating the first item") {
                                let firstItem = values[0]
                                it("First item should have type [session_start]") {
                                    expect(firstItem.type).to(equal("session_start"))
                                }
                                it("First item should have propertie [browser: Chorme]") {
                                    expect(firstItem.properties?["browser"]).to(equal(.string("Chrome")))
                                }
                                it("First item should have propertie [device: Other]") {
                                    expect(firstItem.properties?["device"]).to(equal(.string("Other")))
                                }
                                it("First item should have propertie [location: https://app.exponea.com/]") {
                                    expect(firstItem.properties?["location"]).to(equal(.string("https://app.exponea.com/")))
                                }
                                it("First item should have propertie [os: Linux]") {
                                    expect(firstItem.properties?["os"]).to(equal(.string("Linux")))
                                }
                            }

                            context("Validating the second item") {
                                let firstItem = values[1]
                                it("First item should have type [purchase]") {
                                    expect(firstItem.type).to(equal("purchase"))
                                }
                                it("First item should have propertie [price: 100]") {
                                    expect(firstItem.properties?["price"]).to(equal(.int(100)))
                                }
                                it("First item should have propertie [product_name: iPad]") {
                                    expect(firstItem.properties?["product_name"]).to(equal(.string("iPad")))
                                }
                            }

                            context("Validating the thrid item") {
                                let firstItem = values[2]
                                it("First item should have type [session_end]") {
                                    expect(firstItem.type).to(equal("session_end"))
                                }
                                it("First item should have propertie [browser: Safari]") {
                                    expect(firstItem.properties?["browser"]).to(equal(.string("Safari")))
                                }
                                it("First item should have propertie [device: MacBook]") {
                                    expect(firstItem.properties?["device"]).to(equal(.string("MacBook")))
                                }
                                it("First item should have propertie [location: https://app.exponea.com/]") {
                                    expect(firstItem.properties?["location"]).to(equal(.string("https://app.exponea.com/")))
                                }
                                it("First item should have propertie [os: macOS High Sierra]") {
                                    expect(firstItem.properties?["os"]).to(equal(.string("macOS High Sierra")))
                                }
                            }
                        }

                        done()
                    }
                }
            }
        }
    }
}

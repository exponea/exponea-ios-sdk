//
//  TrackEventSpec.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 13/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class TrackEventSpec: QuickSpec {

    override func spec() {
        describe("Track a customer event") {
            context("Track customer with mock repository") {

                let configuration = try! Configuration(plistName: "ExponeaConfig")
                let mockRepo = MockRepository(configuration: configuration)
                let mockData = MockData()
                
                let data: [DataType] = [.projectToken(mockData.projectToken),
                                        .properties(mockData.properties)]
                
                waitUntil(timeout: 3) { done in
                    mockRepo.trackEvent(with: data, for: mockData.customerIds) { (result) in
                        it("Result error should be nil") {
                            expect(result.error).to(beNil())
                        }
                        done()
                    }
                }
            }
        }
    }
}

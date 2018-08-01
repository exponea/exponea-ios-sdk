//
//  FetchPersonalizationSpec.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 02/08/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class FetchPersonalizationSpec: QuickSpec {
    override func spec() {
        describe("A personalization") {
            context("Fetch personalization from mock repository") {
                
                let configuration = try! Configuration(plistName: "ExponeaConfig")
                let mockRepo = MockRepository(configuration: configuration)
                let mockData = MockData()
                
                waitUntil(timeout: 3) { done in
                    mockRepo.fetchPersonalization(with: mockData.personalizationRequest, for: mockData.customerIds) { (result) in
                        it("Result error should be nil") {
                            expect(result.error).to(beNil())
                        }
                        
                        context("Validating personalization data") {
                            let data = result.value?.data[0]
                            
                            it("html should contain value [String: exponea-banner]") {
                                expect(data?.html).to(contain("exponea-banner"))
                            }
                            
                            it("script should have the prefix [String: var self = this]") {
                                expect(data?.script).to(beginWith("var self = this"))
                            }
                            
                            it("style should have the prefix [String: .exponea-leaderboard]") {
                                expect(data?.style).to(beginWith(".exponea-leaderboard"))
                            }
                        }
                        done()
                    }
                }
            }
        }
    }
}

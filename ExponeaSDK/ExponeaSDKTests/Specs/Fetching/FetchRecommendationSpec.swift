//
//  FetchRecommendationSpec.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 20/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class FetchRecommendationSpec: QuickSpec {

    override func spec() {
        describe("Fetch recommendation") {
            context("Fetch recommendation from mock repository") {
                
                let configuration = try! Configuration(plistName: "ExponeaConfig")
                let mockRepo = MockRepository(configuration: configuration)
                let mockData = MockData()
                
                let data = mockData.recommendRequest
                
                waitUntil(timeout: 3) { done in
                    mockRepo.fetchRecommendation(recommendation: data, for: mockData.customerIds) { (result) in
                        it("Result error should be nil") {
                            expect(result.error).to(beNil())
                        }
                        
                        it("Result should be true ") {
                            expect(result.value?.success).to(beTrue())
                        }
                        it("Result values should have 3 items") {
                            expect(result.value?.results?.count).to(equal(3))
                        }
                        
                        context("Check the values returned from json file") {
                            
                            guard let values =  result.value?.results else {
                                fatalError("Get recommendation should not be empty")
                            }
                            
                            it("First item should have value [Marian]") {
                                let firstItem = values[0]
                                expect(firstItem.success).to(beTrue())
                                expect(firstItem.value).to(equal("Marian"))
                            }
                            it("Second item should have value [Galik]") {
                                let firstItem = values[1]
                                expect(firstItem.success).to(beTrue())
                                expect(firstItem.value).to(equal("Galik"))
                            }
                            it("Third item should have value [Payers]") {
                                let firstItem = values[2]
                                expect(firstItem.success).to(beTrue())
                                expect(firstItem.value).to(equal("Payers"))
                            }
                        }

                        done()
                    }
                }
            }
        }
    }
}

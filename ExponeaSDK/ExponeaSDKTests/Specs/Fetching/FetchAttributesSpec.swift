//
//  FetchAttributesSpec.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 02/08/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Mockingjay

@testable import ExponeaSDK

class FetchAttributesSpec: QuickSpec {
    override func spec() {
        describe("A attribute") {
            context("Fetch attributes from mock repository") {
                
                let configuration = try! Configuration(plistName: "ExponeaConfig")
                let repo = ServerRepository(configuration: configuration)

                MockingjayProtocol.addStub(matcher: { (request) -> (Bool) in
                    return true
                }) { (request) -> (Response) in
                    let data = MockData().attributesResponse
                    let stubResponse = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                    return Response.success(stubResponse, .content(data))
                }
                let mockData = MockData()
                
                waitUntil(timeout: 3) { done in
                    repo.fetchAttributes(attributes: [mockData.attributesDesc], for: mockData.customerIds) { (result) in
                        it("Result error should be nil") {
                            expect(result.error).to(beNil())
                        }
                        
                        it("Result should be true ") {
                            expect(result.value?.success).to(beTrue())
                        }
                        it("Result values should have 3 items") {
                            expect(result.value?.results.count).to(equal(3))
                        }
                        
                        context("Check the values returned from json file") {
                            
                            guard let values = result.value?.results else {
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

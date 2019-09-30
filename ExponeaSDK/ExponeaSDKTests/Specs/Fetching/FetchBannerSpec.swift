//
//  FetchBannerSpec.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 02/08/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class FetchBannerSpec: QuickSpec {
    
    override func spec() {
        describe("Fetch banner") {
            context("Fetch banners from mock repository") {
                
                let configuration = try! Configuration(plistName: "ExponeaConfig")
                let repo = ServerRepository(configuration: configuration)

                NetworkStubbing.stubNetwork(withStatusCode: 200, withResponseData: MockData().bannerResponse)
                
                waitUntil(timeout: 3) { done in
                    repo.fetchBanners() { (result) in
                        it("Result error should be nil") {
                            expect(result.error).to(beNil())
                        }
                        
                        context("Validating banner data") {
                            let data = result.value?.data[0]
                            
                            it("Date filter should be disabled") {
                                expect(data?.dateFilter.enabled).to(beFalse())
                            }
                            
                            it("Device target should be [Any]") {
                                expect(data?.deviceTarget.type).to(equal(.any))
                            }
                            
                            it("Frequency should be type [Until visitor interacts]") {
                                expect(data?.frequency).to(equal(.untilVisitorInteracts))
                            }
                            
                            it("Id should be value [String: 5af313effb60092ebbfb2207]") {
                                expect(data?.id).to(equal("5af313effb60092ebbfb2207"))
                            }
                        }
                        
                        done()
                    }
                }
            }
        }
    }
}

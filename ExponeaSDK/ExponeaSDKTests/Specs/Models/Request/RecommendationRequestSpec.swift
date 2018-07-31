//
//  RecommendationRequestSpec.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 31/07/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class RecommendationRequestSpec: QuickSpec {
    override func spec() {
        describe("A recommedation request") {
            context("Setting events for a customer") {
                
                let recommendationRequest =

                
                it("Should return type recommendation") {
                    expect(recommendationRequest.type).to(equal("recommendation"))
                }
                
                it("Should return id 592ff585fb60094e02bfaf6a") {
                    expect(recommendationRequest.id).to(equal("592ff585fb60094e02bfaf6a"))
                }
                
                it("Should have strategy winner") {
                    expect(recommendationRequest.strategy).to(equal("winner"))
                }
            }
        }
    }
}

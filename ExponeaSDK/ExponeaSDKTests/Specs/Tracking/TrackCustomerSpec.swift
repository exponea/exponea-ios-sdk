//
//  TrackCustomerSpec.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 17/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class TrackCustomerSpec: QuickSpec {

    // TODO: Finish implementation of unit tests with coredata tests
    override func spec() {
        describe("A Track Customer") {
            context("Track customer with mock repository") {
                let configuration = try! Configuration(plistName: "ExponeaConfig")
                let mockRepo = MockRepository(configuration: configuration)
                let mockData = MockData()
                
                let data: [DataType] = [.projectToken(mockData.projectToken),
                                        .properties(mockData.properties),
                                        .timestamp(nil),
                                        .eventType("install")]
                
                waitUntil(timeout: 3) { done in
                    mockRepo.trackCustomer(with: data, for: mockData.customerIds) { (result) in
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

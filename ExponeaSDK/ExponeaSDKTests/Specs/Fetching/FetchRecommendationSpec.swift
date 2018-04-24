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

        let database = MockDatabase()
        let data = FetchMockData()
        let configuration = Configuration(plistName: "ExponeaConfig")!
        let repository = MockFetchRepository(configuration: configuration)

        let exponea = Exponea(database: database,
                              repository: repository)

        describe("Fetch recommendation") {

            exponea.configure(plistName: "ExponeaConfig")

            context("Fetch recommendation from exponea api") {

                expect(exponea.configuration.authorization).toNot(beNil())
                waitUntil(timeout: 5) { done in
                    exponea.fetchRecommendation(projectToken: configuration.projectToken!,
                                                customerId: data.customerId,
                                                recommendation: data.recommendation) { result in
                        it("Should not return error") {
                            expect(result.error).to(beNil())
                        }
                        it("Should return success") {
                            expect(result.value?.success).to(beTrue())
                        }
                        // FIXME: API returning 0 values
                        //                    it("Should return any response") {
                        //                        expect(result.value?.data?.count).to(beGreaterThan(0))
                        //                    }
                        done()
                    }
                }
            }

            context("Fetch recommendation from mock data") {
                guard let projectToken = exponea.configuration.projectToken else {
                    fatalError("There is no project token configured")
                }
                repository.fetchRecommendation(projectToken: projectToken,
                                               customerId: data.customerId,
                                               recommendation: data.recommendation) { (result) in
                    it("error should be nil") {
                        expect(result.error).to(beNil())
                    }
                    it("should return success") {
                        expect(result.value?.success).to(beTrue())
                    }
                    it("should return 3 items") {
                        expect(result.value?.results?.count).to(equal(3))
                    }
                    it("first item should be Marian") {
                        expect(result.value?.results?.first?.value).to(equal("Marian"))
                    }
                }
            }
        }
    }
}

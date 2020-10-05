//
//  FetchConsentsSpec.swift
//  ExponeaSDKTests
//
//  Created by Dominik Hádl on 11/06/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class FetchConsentsSpec: QuickSpec {

    override func spec() {
        describe("A Repository") {
            let configuration = try! Configuration(
                projectToken: UUID().uuidString,
                authorization: .token("mock-token"),
                baseUrl: "https://mock-base-url.com"
            )
            let repo = ServerRepository(configuration: configuration)
            context("when fetching consent categories") {
                NetworkStubbing.stubNetwork(
                    forProjectToken: configuration.projectToken,
                    withStatusCode: 200,
                    withResponseData: MockData().consentsResponse
                )

                waitUntil(timeout: .seconds(3)) { done in
                    repo.fetchConsents { (result) in
                        it("should not fail") {
                            expect(result.error).to(beNil())
                        }

                        it("should have 1 consent category") {
                            expect(result.value?.consents.count).to(equal(1))
                        }

                        it("should have english translation with 2 key-value pairs") {
                            expect(result.value?.consents.first?.translations.first?.key).to(equal("en"))
                            expect(result.value?.consents.first?.translations["en"]?.count).to(equal(2))
                        }

                        done()
                    }
                }

                context("when fetching consent categories with null translation description") {
                    NetworkStubbing.stubNetwork(
                        forProjectToken: configuration.projectToken,
                        withStatusCode: 200,
                        withResponseData: MockData().consentsResponse2
                    )

                    waitUntil(timeout: .seconds(3)) { done in
                        repo.fetchConsents { (result) in
                            it("should not fail") {
                                expect(result.error).to(beNil())
                            }

                            it("should have 1 consent category") {
                                expect(result.value?.consents.count).to(equal(1))
                            }

                            it("should have '' translation") {
                                expect(result.value?.consents.first?.translations.first?.key).to(equal(""))
                                guard let translation = result.value?.consents.first?.translations[""] else {
                                    XCTFail("Translation not found")
                                    return
                                }
                                expect(translation.count).to(equal(2))
                                expect(translation["Description"]).to(beNil())
                                expect(translation["name"]).to(equal("Other"))
                            }

                            done()
                        }
                    }
                }
            }
        }
    }
}

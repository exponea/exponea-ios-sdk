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
import Mockingjay

@testable import ExponeaSDK

class FetchConsentsSpec: QuickSpec {

    override func spec() {
        describe("A Repository") {
            context("when fetching consent categories") {

                let configuration = try! Configuration(plistName: "ExponeaConfig")
                let repo = ServerRepository(configuration: configuration)

                MockingjayProtocol.addStub(matcher: { (request) -> (Bool) in
                    return true
                }) { (request) -> (Response) in
                    let data = MockData().consentsResponse
                    let stubResponse = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                    return Response.success(stubResponse, .content(data))
                }

                waitUntil(timeout: 3) { done in
                    repo.fetchConsents() { (result) in
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
            }
        }
    }
}

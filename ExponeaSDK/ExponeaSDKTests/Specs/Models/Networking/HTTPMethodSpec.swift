//
//  HTTPMethodSpec.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 01/08/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDKShared

class HTTPMethodSpec: QuickSpec {
    override func spec() {
        describe("A http method") {
            context("HTTP methods available") {

                it("Method post") {
                    let httpMethod = HTTPMethod.post
                    expect(httpMethod.rawValue).to(equal("POST"))
                }

                it("Method put") {
                    let httpMethod = HTTPMethod.put
                    expect(httpMethod.rawValue).to(equal("PUT"))
                }

                it("Method get") {
                    let httpMethod = HTTPMethod.get
                    expect(httpMethod.rawValue).to(equal("GET"))
                }

                it("Method delete") {
                    let httpMethod = HTTPMethod.delete
                    expect(httpMethod.rawValue).to(equal("DELETE"))
                }

                it("Method patch") {
                    let httpMethod = HTTPMethod.patch
                    expect(httpMethod.rawValue).to(equal("PATCH"))
                }
            }
        }
    }
}

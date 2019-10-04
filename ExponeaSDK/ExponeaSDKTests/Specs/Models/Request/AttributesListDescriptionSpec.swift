//
//  AttributesListDescriptionSpec.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 31/07/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class AttributesListDescriptionSpec: QuickSpec {
    override func spec() {
        describe("A attribute list description") {
            context("Defining a list with respective description") {

                let attribDesc = AttributesDescription(key: "id",
                                                       value: "registered",
                                                       identificationKey: "property",
                                                       identificationValue: "first_name")

                let attribList = AttributesListDescription(type: "myType",
                                                           list: [attribDesc])

                it("Should have 1 item on list") {
                    expect(attribList.list.count).to(equal(1))
                }

                it("First item should be of type myType") {
                    expect(attribList.type).to(equal("myType"))
                }

                it("List should have key 'id'") {
                    expect(attribList.list.first?.typeKey).to(equal("id"))
                }

                it("List should have type registered") {
                    expect(attribList.list.first?.typeValue).to(equal("registered"))
                }

                it("List should have identification key property") {
                    expect(attribList.list.first?.identificationKey).to(equal("property"))
                }

                it("List should have identification first_name") {
                    expect(attribList.list.first?.identificationValue).to(equal("first_name"))
                }
            }
        }
    }
}

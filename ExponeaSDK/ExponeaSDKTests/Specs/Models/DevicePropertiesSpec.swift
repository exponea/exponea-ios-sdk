//
//  DevicePropertiesSpec.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 16/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class DevicePropertiesSpec: QuickSpec {

    override func spec() {
        describe("A device properties") {
            context("after beign properly initialized") {
                let device = DeviceProperties()
                it("Should not be nil") {
                    expect(device).toNot(beNil())
                }
                it("Should have a valid device type") {
                    expect(device.deviceType).to(equal("mobile"))
                }
                it("Should return a dictionary of type [KeyValueModel]") {
                    expect(device.asKeyValueModel()).to(beAnInstanceOf([KeyValueModel].self))
                }
            }
        }
    }
}

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

    class MockBundle: Bundle {
        override var infoDictionary: [String: Any]? {
            return [Constants.Keys.appVersion: "1.2"]
        }
    }

    override func spec() {
        describe("A device") {
            context("after beign properly initialized") {

                let device = DeviceProperties(bundle: MockBundle())

                it("Should not be nil") {
                    expect(device).toNot(beNil())
                }

                it("Should have a valid device type") {
                    expect(device.deviceType).to(equal("mobile"))
                }

                it("Should have a OS Version equals iOS current version") {
                    expect(device.osVersion).to(equal(UIDevice.current.systemVersion))
                }

                it("Should have a device type equals mobile") {
                    expect(device.deviceType).to(equal("mobile"))
                }

                it("Should have version number different from N/A") {
                    expect(device.appVersion).toNot(equal("N/A"))
                    expect(device.appVersion).to(equal("1.2"))
                }
            }
        }
    }
}

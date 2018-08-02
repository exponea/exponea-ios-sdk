//
//  TrackSessionSpec.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 16/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class TrackSessionSpec: QuickSpec {

    override func spec() {
        describe("A session tracking") {
            context("After being instantiated") {
                // TODO: Refactor
//                // Force the first launch to set the default timeout value
//                Exponea.shared.userDefaults.set(false, forKey: Constants.Keys.launchedBefore)
//
//                it("session start shouldn't have any value") {
//                    expect(Exponea.shared.userDefaults.integer(forKey: Constants.Keys.sessionStarted)).to(equal(0))
//                }
//                it("session end shouldn't have any value") {
//                    expect(Exponea.shared.userDefaults.integer(forKey: Constants.Keys.sessionEnded)).to(equal(0))
//                }
//                it("session should have default timeout value") {
//                    expect(UserDefaults.standard.double(forKey: Constants.Keys.timeout)).to(equal(Constants.Session.defaultTimeout))
//                }
            }
        }
    }
}

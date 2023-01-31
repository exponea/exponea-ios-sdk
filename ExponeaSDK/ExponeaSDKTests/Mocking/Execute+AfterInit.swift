//
//  Execute+AfterInit.swift
//  ExponeaSDKTests
//
//  Created by Michal Severín on 07.02.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import XCTest
import Quick
import Nimble
import ExponeaSDKObjC

@testable import ExponeaSDK
@testable import ExponeaSDKShared

class ExponeaSpecInit: QuickSpec {

    private var counter: Int = 0
    private let manager = ExpoInitManager.manager

    func failMethod() throws {
        throw NSError(domain: "error", code: 0)
    }

    func successMethod() {
        counter += 1
    }

    func successTryMethod() throws {
        let name = "test"
        if name != "test" {
            throw NSError(domain: "error", code: 99)
        } else {
            counter += 1
        }
    }

    override func spec() {
        context("executing after exponea init") {
            Nimble.AsyncDefaults.timeout = .seconds(5)
            it("After init manager") {
                /// Counter += 1
                self.manager.doActionAfterExponeaInit(self.increment)
                /// Counter += 1
                Exponea.shared.executeSafely(self.increment)
                waitUntil { done in
                    expect {
                        try self.manager.doActionAfterExponeaInit {
                            try self.failMethod()
                        }
                    }.to(throwError())
                    Exponea.shared.fetchAppInbox { _ in
                        self.increment()
                    }
                    DispatchQueue.global().asyncAfter(deadline: .now() + 4) {
                        /// Counter += 1
                        self.manager.doActionAfterExponeaInit(self.increment)
                        done()
                    }
                }
                Exponea.shared.executeSafely(self.increment)
                self.manager.setStatus(status: .configured)
                expect(self.manager.actionBlocks.isEmpty).to(beTruthy())
                expect(self.counter).to(equal(5))
                /// Counter += 1
                self.manager.doActionAfterExponeaInit(self.increment)
                expect(self.manager.actionBlocks.isEmpty).to(beTruthy())
                expect {
                    /// Counter += 1
                    try self.manager.doActionAfterExponeaInit(self.successTryMethod)
                    expect(self.manager.actionBlocks.isEmpty).to(beTruthy())
                }.toNot(throwError())
                expect(self.counter).to(equal(7))
                waitUntil { done in
                    expect {
                        try self.manager.doActionAfterExponeaInit {
                            try self.failMethod()
                        }
                    }.to(throwError())
                    DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                        /// Counter += 1
                        self.manager.doActionAfterExponeaInit(self.increment)
                        expect(self.manager.actionBlocks.isEmpty).to(beTruthy())
                        done()
                    }
                }
                expect(self.counter).to(equal(8))
                /// Just clean
                self.clean()
                expect(self.counter).to(equal(0))
                waitUntil { done in
                    Exponea.shared.executeSafely {
                        try self.failMethod()
                    } errorHandler: { error in
                        expect((error as NSError).domain).to(equal("error"))
                        self.increment()
                        done()
                    }
                }
                expect(self.counter).to(equal(1))
            }
        }
    }

    @discardableResult
    func clean() -> Int {
        counter = 0
        manager.clean()
        return manager.actionBlocks.count
    }

    func increment() {
        counter += 1
    }
}

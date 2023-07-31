//
//  AtomicValueSpec.swift
//  ExponeaSDKTests
//
//  Created by Gustavo Pizano on 06/03/2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation
import XCTest
import Quick
import Nimble

@testable import ExponeaSDK

final class AtomicValueSpec: QuickSpec {

    private struct ComplexAtomicTestStruct {
        @Atomic var x = [1, 2, 3]
    }

    private struct SimpleAtomicTestStruct {
        @Atomic var x = 0
        @AtomicLock var y = true
        var atomicIntProperty = AtomicProperty(property: 0)
    }

    private let queue1 = DispatchQueue(label: "com.exponea.ExponeaSDK.atomicValueTestQueue1")
    private let queue2 = DispatchQueue(label: "com.exponea.ExponeaSDK.atomicValueTestQueue2")

    override func spec() {
        describe("Exponea Atomic Property wrapper") {
            context("Simple Atomic access operation") {
                var simpleTest = SimpleAtomicTestStruct()
                simpleTest.$x.changeValue { $0 += 1 }
                simpleTest.y = false
                it("Should be equals to 1") {
                    expect(simpleTest.x).to(equal(1))
                }
                it("Y Should be equals to false") {
                    expect(simpleTest.y).to(equal(false))
                }
            }

            context("Complex Atomic access operation") {
                var complexTest = ComplexAtomicTestStruct()
                complexTest.$x.changeValue { $0[0] += 1 }
                it("Should be equals to 2") {
                    expect(complexTest.x[1]).to(equal(2))
                }
            }

            context("Simple multi-thread reading/writting") {
                var simpleTest = SimpleAtomicTestStruct()
                let expectation = expectation(description: "Queues tasks completion")
                expectation.expectedFulfillmentCount = 2

                queue2.asyncAfter(deadline: .now() + 3) {
                    simpleTest.$x.changeValue { $0 += 1 }
                    simpleTest.y = true
                    simpleTest.atomicIntProperty.performAtomic { $0 += 1 }
                    expectation.fulfill()
                }

                queue1.asyncAfter(deadline: .now() + 1) {
                    simpleTest.$x.changeValue { $0 += 2 }
                    sleep(3)
                    simpleTest.y = false
                    simpleTest.atomicIntProperty.performAtomic { $0 = 4 }
                    expectation.fulfill()
                }
                wait(for: [expectation], timeout: 10)
                it("SimpleAtomicTest x shall be 3") {
                    expect(simpleTest.x).to(equal(3))
                }

                it("SimpleAtomicTest y shall be false") {
                    expect(simpleTest.y).to(equal(false))
                }

                it("SimpleAtomicTest atomicProperty shall be 4") {
                    expect(simpleTest.atomicIntProperty.property).to(equal(4))
                }
            }

            context("Complex multi-threading reading/writting") {
                var complexTest = SimpleAtomicTestStruct()
                let expectation = expectation(description: "Queues complex task completion")
                expectation.expectedFulfillmentCount = 20
                let readingExpectaiton = self.expectation(description: "Reading queue expecation")
                readingExpectaiton.expectedFulfillmentCount = 20
                // Writting
                var currentWrittenResult = 1
                DispatchQueue.global().async {
                    for i in 1...20 {
                        let label = "com.exponea.ExponeaSDK.atomicValueComplexTestQueue" + String(i)
                        let queue = DispatchQueue(label: label)
                        let delay = Double(20 - i)
                        queue.asyncAfter(deadline: .now() + delay) {
                            complexTest.$x.changeValue { $0 += 1 }
                            currentWrittenResult = complexTest.x
                            expectation.fulfill()
                            expect(complexTest.x).notTo(equal(i))
                        }
                    }
                }
                // Reading
                DispatchQueue.global().async {
                    for i in 1...20 {
                        DispatchQueue.global().sync {
                            sleep(UInt32(i/2))
                            expect(complexTest.x).to(equal(currentWrittenResult))
                            readingExpectaiton.fulfill()
                        }
                    }
                }
                wait(for: [expectation, readingExpectaiton], timeout: 1000)
            }
        }
    }
}

//
//  ArrayComparisonTests.swift
//  ExponeaSDKTests
//
//  Created by Adam Mihalik on 10/07/2024.
//  Copyright © 2024 Exponea. All rights reserved.
//

import Nimble
import Quick
@testable import ExponeaSDK

final class ArrayComparisonTests: QuickSpec {
    private func areArraysEqual(_ lhs: [(String?, Bool)]?, _ rhs: [(String?, Bool)]?) -> Bool {
        MockTrackingManager.TrackedEvent.areArraysEqual(lhs, rhs)
    }
    override func spec() {
        it("atomic test") {
            @Atomic var testArray: [String] = []
            waitUntil(timeout: .seconds(3)) { done in
                for i in 0..<10000 {
                    if i < 9000 {
                        if i % 2 == 0 {
                            DispatchQueue.global().async {
                                _testArray.changeValue(with: { $0.append("\(i)") })
                            }
                        } else {
                            DispatchQueue.main.async {
                                _testArray.changeValue(with: { $0.append("\(i)") })
                            }
                        }
                    }
                    if i >= 9000 {
                        DispatchQueue.main.async {
                            _testArray.changeValue(with: { $0.append("\(i)") })
                        }
                        DispatchQueue.global().async {
                            _testArray.changeValue(with: { $0.append("\(i)") })
                        }
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    done()
                }
            }
            let count = testArray.count
            expect(count).to(be(11000))
        }

        it("compare string with bool arrays") {
            expect(self.areArraysEqual([
                (nil, false)
            ], [
                (nil, false)
            ])).to(beTrue())
            expect(self.areArraysEqual([
                ("a", false),
                ("b", true)
            ], [
                (nil, false),
                ("b", false)
            ])).to(beFalse())
            expect(self.areArraysEqual([
                ("a", false),
                ("a", true),
                ("b", false)
            ], [
                ("a", false),
                ("b", true),
                ("b", false)
            ])).to(beFalse())
            expect(self.areArraysEqual([
                (nil, true)
            ], [
                (nil, true)
            ])).to(beTrue())
            expect(self.areArraysEqual([
                (nil, false)
            ], [
                (nil, true)
            ])).to(beFalse())
            expect(self.areArraysEqual([
                ("a", false),
                ("a", false),
                ("a", false),
                ("b", false),
            ], [
                ("a", false),
                ("b", false),
                ("b", false),
                ("b", false),
            ])).to(beFalse())
            expect(self.areArraysEqual([
                ("a", false),
                ("a", false),
                ("a", false),
                ("b", false),
            ], [
                ("a", false),
                ("a", false),
                ("b", false),
                ("b", false),
            ])).to(beFalse())
            expect(self.areArraysEqual([
                ("a", false),
                ("a", false),
                ("b", false),
                ("b", false),
            ], [
                ("a", false),
                ("a", false),
                ("b", false),
                ("b", false),
            ])).to(beTrue())
        }
    }
}

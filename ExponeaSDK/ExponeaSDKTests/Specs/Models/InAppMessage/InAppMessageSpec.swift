//
//  InAppMessageSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 28/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//
import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class InAppMessageSpec: QuickSpec {
    override func spec() {
        it("should deserialize from JSON") {
            let jsonDecoder = JSONDecoder()
            jsonDecoder.dateDecodingStrategy = .secondsSince1970
            expect(
                try? jsonDecoder.decode(InAppMessage.self, from: SampleInAppMessage.samplePayload.data(using: .utf8)!)
            ).to(equal(SampleInAppMessage.getSampleInAppMessage()))
        }
    }
}

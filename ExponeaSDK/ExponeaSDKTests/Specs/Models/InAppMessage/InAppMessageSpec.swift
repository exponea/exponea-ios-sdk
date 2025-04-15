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
            var msg: InAppMessage?
            do {
                msg = try jsonDecoder.decode(InAppMessage.self, from: SampleInAppMessage.samplePayload.data(using: .utf8)!)
            } catch {
                let error = error
                print("======== \(error)")
            }
            expect(
                msg
            ).to(equal(SampleInAppMessage.getSampleInAppMessage(delayMS: 1000, timeoutMS: 2000)))
        }

        it("should deserialize from JSON rich") {
            let jsonDecoder = JSONDecoder()
            jsonDecoder.dateDecodingStrategy = .secondsSince1970
            var msg: InAppMessage?
            do {
                msg = try jsonDecoder.decode(InAppMessage.self, from: SampleInAppMessage.samplePayloadRich.data(using: .utf8)!)
            } catch {
                let error = error
                print("======== \(error)")
            }
            expect(
                msg?.payload
            ).toNot(beNil())
        }
    }
}

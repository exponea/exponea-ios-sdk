//
//  PushOpenedDataSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 07/09/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//
import Nimble
import Quick

@testable import ExponeaSDK

final class PushOpenedDataSpec: QuickSpec {
    override func spec() {
        it("should serialize and deserialize push") {
            let sampleData = PushNotificationsTestData().openedProductionNotificationData
            let serializedString = String(data: sampleData.serialize()!, encoding: .utf8)!
            print(serializedString)
            let deserialized = PushOpenedData.deserialize(from: serializedString.data(using: .utf8)!)
            expect(deserialized).to(equal(sampleData))
        }
    }
}

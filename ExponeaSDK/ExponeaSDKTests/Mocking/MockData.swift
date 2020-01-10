//
//  MockData.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 31/07/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

@testable import ExponeaSDK

struct MockData {
    // We need bundle to load files
    private final class BundleClass {}
    private static var bundle: Bundle { return Bundle(for: MockData.BundleClass.self) }

    let projectToken = "TokenForUnitTest"

    let customerIds: [String: JSONValue] = {
        return ["registered": .string("marian.galik@exponea.com")]
    }()

    let properties: [String: JSONValue] = {
        return [
            "properties": .dictionary([
                "first_name": .string("Marian"),
                "last_name": .string("Galik"),
                "email": .string("marian.galik@exponea.com")])
        ]
    }()

    let eventTypes: [String] = {
        return ["install",
                "session_start",
                "session_end"]
    }()

    let items: [String: JSONValue] = {
        return [
            "items": JSONValue.dictionary(
                [
                    "item01": .int(1),
                    "item02": .int(2)
                ]
            )
        ]
    }()

    let personalizationRequest = PersonalizationRequest(ids: ["1", "2", "3"],
                                                        timeout: 5,
                                                        timezone: "GMT+2",
                                                        customParameters: nil)

    let purchasedItem = PurchasedItem(grossAmount: 10.0,
                                      currency: "EUR",
                                      paymentSystem: "Bank Transfer",
                                      productId: "123",
                                      productTitle: "iPad",
                                      receipt: nil)

    let recommendationResponse = retrieveDataFromFile(with: "get-recommendation", fileType: "json")
    let eventsResponse = retrieveDataFromFile(with: "get-events", fileType: "json")
    let bannerResponse = retrieveDataFromFile(with: "get-banner", fileType: "json")
    let personalizationResponse = retrieveDataFromFile(with: "get-personalization", fileType: "json")
    let attributesResponse = retrieveDataFromFile(with: "get-attributes", fileType: "json")
    let consentsResponse = retrieveDataFromFile(with: "get-consents", fileType: "json")

    static func retrieveDataFromFile(with fileName: String, fileType: String) -> Data {

        /// Get the json content of file
        guard
            let file = bundle.url(forResource: fileName, withExtension: fileType),
            let data = try? Data(contentsOf: file)
            else {
                fatalError("Something is horribly wrong with the data.")
        }
        return data
    }

    let campaignData: [String: JSONValue] = [
        // swiftlint:disable:next line_length
        "url": .string("https://mockurl?param?utm_source=utm&utm_campaign=mycampaign&utm_content=utmcontent&utm_medium=utmmedium&utm_term=term&xnpe_cmp=cmp&itt=usertoken"),
        "platform": .string("iOS")
    ]

    // swiftlint:disable:next line_length
    let campaignUrl = URL(string: "https://mockurl?param?utm_source=utm&utm_campaign=mycampaign&utm_content=utmcontent&utm_medium=utmmedium&utm_term=term&xnpe_cmp=cmp&itt=usertoken")
}

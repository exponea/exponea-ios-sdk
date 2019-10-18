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

    let recommendRequest = RecommendationRequest(type: "recommendation",
                                                 id: "592ff585fb60094e02bfaf6a",
                                                 size: 10,
                                                 strategy: "winner",
                                                 knowItems: false,
                                                 anti: false,
                                                 items: [
                                                    "items": JSONValue.dictionary([
                                                            "item01": .int(1),
                                                            "item02": .int(2)])
                                                ])

    let attributesDesc = AttributesDescription(key: "id",
                                               value: "registered",
                                               identificationKey: "property",
                                               identificationValue: "first_name")

    let eventRequest = EventsRequest(eventTypes: ["install",
                                                  "session_start",
                                                  "session_end"],
                                     sortOrder: nil,
                                     limit: nil,
                                     skip: nil)

    let customerExportRequest = CustomerExportRequest(attributes: nil,
                                                      filter: nil,
                                                      executionTime: nil,
                                                      timezone: nil,
                                                      responseFormat: ExportFormat.csv)

    let personalizationRequest = PersonalizationRequest(ids: ["1", "2", "3"],
                                                        timeout: 5,
                                                        timezone: "GMT+2",
                                                        customParameters: nil)

    let customerParameters = CustomerParameters(customer: ["registered": .string("marian.galik@exponea.com")],
                                                property: "myProperty",
                                                id: "123",
                                                recommendation: nil,
                                                attributes: nil,
                                                events: nil,
                                                data: nil)

    let event = Event(type: "purchase",
                      timestamp: nil,
                      properties: ["name": .string("iPad"),
                                   "description": .string("Tablet")],
                      errors: nil)

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

    let sessionStart = Event(type: "session_start",
                      timestamp: nil,
                      properties: ["name": .string("iPad"),
                                   "description": .string("Tablet")],
                      errors: nil)

    let campaignData: [String: JSONValue] = [
        "url": .string("https://mockurl?param?utm_source=utm&utm_campaign=mycampaign&utm_content=utmcontent&utm_medium=utmmedium&utm_term=term&xnpe_cmp=cmp&itt=usertoken"),
        "platform": .string("iOS")
    ]

    let campaignUrl = URL(string: "https://mockurl?param?utm_source=utm&utm_campaign=mycampaign&utm_content=utmcontent&utm_medium=utmmedium&utm_term=term&xnpe_cmp=cmp&itt=usertoken")
    let universalLinkEvent = Event(type: "campaign_click", timestamp: nil, properties: [:], errors: nil)
}

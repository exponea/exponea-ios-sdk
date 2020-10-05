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

    let customerIds: [String: String] = {
        return ["registered": "marian.galik@exponea.com"]
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

    let consentsResponse = retrieveDataFromFile(with: "get-consents", fileType: "json")
    let consentsResponse2 = retrieveDataFromFile(with: "get-consents2", fileType: "json")

    static func retrieveDataFromFile(with fileName: String, fileType: String) -> Data {
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

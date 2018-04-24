//
//  PurchasedItem.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 18/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

struct PurchasedItem {
    var grossAmount: Double
    var currency: String
    var paymentSystem: String
    var productId: String
    var productTitle: String
    var receipt: String?
    /// Returns an array with all purchased info.
    var properties: [KeyValueItem] {
        var data = [KeyValueItem]()

        data.append(KeyValueItem(key: "gross_amount", value: grossAmount))
        data.append(KeyValueItem(key: "currency", value: currency))
        data.append(KeyValueItem(key: "payment_system", value: paymentSystem))
        data.append(KeyValueItem(key: "product_id", value: productId))
        data.append(KeyValueItem(key: "product_title", value: productTitle))

        if let receipt = receipt {
            data.append(KeyValueItem(key: "receipt", value: receipt))
        }

        return data
    }
}

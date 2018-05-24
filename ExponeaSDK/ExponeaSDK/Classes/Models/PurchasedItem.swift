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
    var properties: [String: JSONConvertible] {
        var data = [String: JSONConvertible]()

        data["gross_amount"] = grossAmount
        data["currency"] = currency
        data["payment_system"] = paymentSystem
        data["product_id"] = productId
        data["product_title"] = productTitle

        if let receipt = receipt {
            data["receipt"] = receipt
        }

        return data
    }
}

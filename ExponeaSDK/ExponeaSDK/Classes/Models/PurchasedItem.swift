//
//  PurchasedItem.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 18/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

internal struct PurchasedItem {
    
    /// <#Description#>
    internal var grossAmount: Double
    
    /// <#Description#>
    internal var currency: String
    
    /// <#Description#>
    internal var paymentSystem: String
    
    /// <#Description#>
    internal var productId: String
    
    /// <#Description#>
    internal var productTitle: String
    
    /// <#Description#>
    internal var receipt: String?
    
    /// Returns an array with all purchased info.
    internal var properties: [String: JSONValue] {
        var data = [String: JSONValue]()

        data["gross_amount"] = .double(grossAmount)
        data["currency"] = .string(currency)
        data["payment_system"] = .string(paymentSystem)
        data["product_id"] = .string(productId)
        data["product_title"] = .string(productTitle)

        if let receipt = receipt {
            data["receipt"] = .string(receipt)
        }

        return data
    }
}

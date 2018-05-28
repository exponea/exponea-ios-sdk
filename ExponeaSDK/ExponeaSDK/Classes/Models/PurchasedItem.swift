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
    internal var properties: [AnyHashable: JSONConvertible] {
        var data = [AnyHashable: JSONConvertible]()

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

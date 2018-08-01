//
//  PurchasedItemSpec.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 01/08/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class PurchasedItemSpec: QuickSpec {
    override func spec() {
        describe("A purchased item") {
            
            let mock = MockData()
            
            context("Setting the event values") {
                
                let item = mock.purchasedItem
                
                it("Should be more than 0") {
                    expect(item.grossAmount).to(beGreaterThan(0))
                }
                
                it("Currency should be EUR") {
                    expect(item.currency).to(equal("EUR"))
                }
                
                it("Payment system should be Bank Transfer") {
                    expect(item.paymentSystem).to(equal("Bank Transfer"))
                }
                
                it("Product ID should be 123") {
                    expect(item.productId).to(equal("123"))
                }
                
                it("Receipt should be nil") {
                    expect(item.receipt).to(beNil())
                }
                
                it("Properties should not be nil") {
                    expect(item.properties).toNot(beNil())
                }
                
                it("Gross amount from properties should be more than 0") {
                    let value = item.properties["gross_amount"]
                    expect(value).to(equal(.double(10.0)))
                }
                
                it("Currency from properties should be EUR") {
                    let currency = item.properties["currency"]
                    expect(currency).to(equal(.string("EUR")))
                }
                
                it("Payment system from properties should be Bank Transfer") {
                    let payment = item.properties["payment_system"]
                    expect(payment).to(equal(.string("Bank Transfer")))
                }
                
                it("Product ID from properties should be 123") {
                    let id = item.properties["product_id"]
                    expect(id).to(equal(.string("123")))
                }
            }
        }
    }
}

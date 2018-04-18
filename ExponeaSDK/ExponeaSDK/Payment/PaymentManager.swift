//
//  PaymentManager.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 18/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import StoreKit

class PaymentManager: SKPaymentQueue, PaymentManagerType {

    /// Check if is it possible to make payments through the app.
    let canMakePurchases = SKPaymentQueue.canMakePayments()

    let trackingManager: TrackingManager
    let device: DeviceProperties
    var receipt: String?

    init(trackingMananger: TrackingManager) {
        self.trackingManager = trackingMananger
        self.device = DeviceProperties()
    }

    deinit {
        SKPaymentQueue.default().remove(self)
    }

    /// Add the observer to the payment queue in order to receive
    /// all the payments done by the user.
    func listenPayments() {
        if canMakePurchases {
            SKPaymentQueue.default().add(self)
        }
    }

    func trackPayment(properties: [KeyValueModel]) -> Bool {
        return trackingManager.trackPayment(with: [.timestamp(nil),
                                                   .properties(properties)])
    }
}

extension PaymentManager: SKPaymentTransactionObserver {
    /// Track the information for the successfully payment and removing from the queue.
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                guard let receiptURL = Bundle.main.appStoreReceiptURL else {
                    break
                }
                receipt = NSData.init(contentsOf: receiptURL)?.base64EncodedString(options: [])
                SKPaymentQueue.default().finishTransaction(transaction)
            default:
                break
            }
        }
    }
}

extension PaymentManager: SKProductsRequestDelegate {
    /// Retrive information from the purchase item.
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        for product in response.products {

            var currencyCode = ""
            var currency = ""

            if let code = Locale.current.currencyCode {
                currencyCode = code
            }
            if let curr = Locale.current.localizedString(forCurrencyCode: currencyCode) {
                currency = curr
            }

            let item = PurchasedItem(grossAmount: Double(truncating: product.price),
                                     currency: currency,
                                     paymentSystem: Constants.General.iTunesStore,
                                     productId: product.productIdentifier,
                                     productTitle: product.localizedTitle,
                                     receipt: receipt)
            var properties = item.properties
            properties.append(contentsOf: device.properties)

            if trackPayment(properties: properties) {
                Exponea.logger.log(.verbose, message: Constants.SuccessMessages.paymentDone)
            } else {
                Exponea.logger.log(.error, message: Constants.ErrorMessages.couldNotTrackPayment +
                                                    Constants.ErrorMessages.verifyLogError)
            }
        }
    }
}

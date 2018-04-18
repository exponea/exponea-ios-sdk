//
//  Payment.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 18/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import StoreKit

class Payment: SKPaymentQueue, PaymentType {

    /// Check if is it possible to make payments through the app.
    let canMakePurchases = SKPaymentQueue.canMakePayments
    let trackingManager: TrackingManager
    let device: DeviceProperties

    /// List of available products to buy.
    fileprivate var products = [SKProduct]()

    private init(trackingMananger: TrackingManager) {
        self.trackingManager = trackingMananger
        self.device = DeviceProperties()
    }

    deinit {
        SKPaymentQueue.default().remove(self)
    }

    /// Add the observer to the payment queue in order to receive
    /// all the payments done by the user.
    func processPayments() {
        SKPaymentQueue.default().add(self)
    }

    func trackPayment(properties: [KeyValueModel]) -> Bool {
        return trackingManager.trackPayment(with: [.timestamp(nil),
                                                   .properties(properties)])
    }
}

extension Payment: SKPaymentTransactionObserver {
    /// Track the information for the successfully payment
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction: AnyObject in transactions {
            guard let trans = transaction as? SKPaymentTransaction else {
                return
            }

            switch trans.transactionState {
            case .purchased:
                break
            default:
                break
            }
        }
    }
}

extension Payment: SKProductsRequestDelegate {
    /// Retrive information from the purchase item.
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        for product in response.products {
            let item = PurchasedItem(grossAmount: Double(truncating: product.price),
                                     currency: product.priceLocale.localizedString(forCurrencyCode: Locale.current.currencyCode!)!,
                                     paymentSystem: Constants.General.iTunesStore,
                                     productId: product.productIdentifier,
                                     productTitle: product.localizedTitle)
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

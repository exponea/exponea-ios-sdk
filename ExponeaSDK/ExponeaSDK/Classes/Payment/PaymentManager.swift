//
//  PaymentManager.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 18/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import StoreKit

public class PaymentManager: NSObject, PaymentManagerType {
    internal var deviceProperties = DeviceProperties()
    internal var receipt: String?
    
    /// The delegat that is responsible for tracking payment events.
    public weak var delegate: PaymentManagerDelegate?
    
    public override init() { }
    
    init(delegate: PaymentManagerDelegate) {
        self.delegate = delegate
    }

    deinit {
        stopObservingPayments()
    }

    /// Add the observer to the payment queue in order to receive
    /// all the payments done by the user.
    func startObservingPayments() {
        /// Check if it is possible to make payments through the app.
        if SKPaymentQueue.canMakePayments() {
            SKPaymentQueue.default().add(self)
        }
    }

    func stopObservingPayments() {
        SKPaymentQueue.default().remove(self)
    }

    func trackPayment(properties: [String: JSONValue]) {
        guard let delegate = delegate else {
            Exponea.logger.log(.warning, message: """
                No delegate for `PaymentManager` set.
                Payment has been observer, but not tracked.
                """)
            return
        }
        
        delegate.trackPaymentEvent(with: [.timestamp(nil), .properties(properties)])
    }
}

extension PaymentManager: SKPaymentTransactionObserver {
    /// Track the information for the successfully payment and removing from the queue.
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                guard let receiptURL = Bundle.main.appStoreReceiptURL else {
                    break
                }
                do {
                    receipt = try Data.init(contentsOf: receiptURL).base64EncodedString(options: [])
                } catch {
                    Exponea.logger.log(.error, message: "Unresolved error \(error.localizedDescription)")
                }
                SKPaymentQueue.default().finishTransaction(transaction)
            default:
                break
            }
        }
    }
}

extension PaymentManager: SKProductsRequestDelegate {
    /// Retrive information from the purchase item.
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        for product in response.products {
            let currencyCode = Locale.current.currencyCode ?? "N/A"
            let currency = Locale.current.localizedString(forCurrencyCode: currencyCode) ?? "N/A"
            
            let item = PurchasedItem(grossAmount: Double(truncating: product.price),
                                     currency: currency,
                                     paymentSystem: Constants.General.iTunesStore,
                                     productId: product.productIdentifier,
                                     productTitle: product.localizedTitle,
                                     receipt: receipt)
            
            let properties = item.properties.merging(deviceProperties.properties,
                                                     uniquingKeysWith: { first, _ in return first })
            trackPayment(properties: properties)
        }
    }
}

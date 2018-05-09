//
//  PaymentManagerDelegate.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 09/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// Delegate that will be notified of payments that happened.
public protocol PaymentManagerDelegate: class {
    
    /// This function will be called whenever a payment has been observed with according information.
    ///
    /// - Parameter data: Data related to the payment, such as timestamp, value, name and similar.
    func trackPaymentEvent(with data: [DataType])
}

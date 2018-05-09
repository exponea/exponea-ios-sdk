//
//  PaymentManagerType.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 18/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

protocol PaymentManagerType: class {
    var delegate: PaymentManagerDelegate? { get set }
    
    func startObservingPayments()
    func stopObservingPayments()
    func trackPayment(properties: [KeyValueItem])
}

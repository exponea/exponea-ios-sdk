//
//  PaymentManagerType.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 18/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

protocol PaymentManagerType: class {
    func listenPayments()
    func trackPayment(properties: [KeyValueModel]) -> Bool
}

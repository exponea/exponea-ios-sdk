//
//  InAppMessageTrackingDelegate.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 16/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

protocol InAppMessageTrackingDelegate: class {
    func track(message: InAppMessage, action: String, interaction: Bool)
}

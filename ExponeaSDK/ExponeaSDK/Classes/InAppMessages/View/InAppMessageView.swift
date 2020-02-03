//
//  InAppMessageView.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 27/01/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation

protocol InAppMessageView {
    var viewController: UIViewController { get }

    var actionCallback: (() -> Void) { get }
    var dismissCallback: (() -> Void) { get }
}

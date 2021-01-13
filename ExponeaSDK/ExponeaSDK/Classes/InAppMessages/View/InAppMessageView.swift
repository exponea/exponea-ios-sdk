//
//  InAppMessageView.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 27/01/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation
import UIKit

protocol InAppMessageView {
    var actionCallback: ((InAppMessagePayloadButton) -> Void) { get }
    var dismissCallback: (() -> Void) { get }

    func present(in viewController: UIViewController, window: UIWindow?) throws
    func dismiss()
}

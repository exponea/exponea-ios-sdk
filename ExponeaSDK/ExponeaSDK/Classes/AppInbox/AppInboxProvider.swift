//
//  AppInboxProvider.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 14/11/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//

import Foundation
import UIKit

public protocol AppInboxProvider {
    func getAppInboxButton() -> UIButton
    func getAppInboxListViewController() -> UIViewController
    func getAppInboxDetailViewController(_ messageId: String) -> UIViewController
}

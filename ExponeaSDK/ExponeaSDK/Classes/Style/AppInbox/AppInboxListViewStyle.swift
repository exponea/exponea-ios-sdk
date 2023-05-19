//
//  AppInboxListViewStyle.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 19/05/2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation
import UIKit

class AppInboxListViewStyle {
    var backgroundColor: String?
    var item: AppInboxListItemStyle?

    init(backgroundColor: String? = nil, item: AppInboxListItemStyle? = nil) {
        self.backgroundColor = backgroundColor
        self.item = item
    }

    func applyTo(_ target: UITableView) {
        if let backgroundColor = UIColor.parse(backgroundColor) {
            target.backgroundColor = backgroundColor
        }
        // note: 'item' style is used elsewhere due to performance reasons
    }
}

//
//  Extension+UIView.swift
//  ExponeaSDK
//
//  Created by Ankmara on 24.02.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import UIKit

extension UIView {
    func addSubviews(_ views: [UIView]) {
        views.forEach(addSubview(_:))
    }

    func addSubviews(_ views: UIView...) {
        addSubviews(views)
    }
}

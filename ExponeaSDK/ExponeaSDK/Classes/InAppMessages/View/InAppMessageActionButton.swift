//
//  InAppMessageActionButton.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 11/02/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import UIKit

final class InAppMessageActionButton: UIButton {
    var payload: InAppMessagePayloadButton?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

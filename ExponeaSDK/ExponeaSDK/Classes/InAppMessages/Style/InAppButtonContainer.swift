//
//  InAppButtonContainer.swift
//  ExponeaSDK
//
//  Created by Ankmara on 29.10.2024.
//  Copyright © 2024 Exponea. All rights reserved.
//

import UIKit
import SwiftUI

final class InAppButtonContainer: UIView {

    private let config: [InAppButtonConfig]

    init(config: [InAppButtonConfig], alignment: InAppButtonAlignmentType) {
        self.config = config
        super.init(frame: .zero)

        if let container = UIHostingController(
            rootView: InAppButtonContainerSwiftUI(
                buttons: config,
                alignment: alignment
            )
        ).view {
            addSubview(container)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

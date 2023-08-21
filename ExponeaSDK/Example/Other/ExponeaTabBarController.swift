//
//  ExponeaTabBarController.swift
//  Example
//
//  Created by Ankmara on 07.08.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import UIKit

enum TabbarItem {

    case fetch
    case tracking
    case flush
    case logging
    case contentBlocks

    var index: Int {
        switch self {
        case .fetch:
            return 0
        case .tracking:
            return 1
        case .flush:
            return 2
        case .logging:
            return 3
        case .contentBlocks:
            return 4
        }
    }
}

final class ExponeaTabBarController: UITabBarController {
    var coordiantor: Coordinator?
}

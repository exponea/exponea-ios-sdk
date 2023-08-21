//
//  Coordinator.swift
//  Example
//
//  Created by Ankmara on 07.08.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import UIKit

enum CoordinatorType {
    case fetch
    case track
    case manualFlush
    case anonymize

    init(deeplinkType: DeeplinkType) {
        switch deeplinkType {
        case .fetch:
            self = .fetch
        case .track:
            self = .track
        case .manual:
            self = .manualFlush
        case .anonymize:
            self = .anonymize
        }
    }
}

final class Coordinator {

    let navigationController: UINavigationController?
    private let deeplinkManager = DeeplinkManager.manager

    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
        // Delay presenting vc
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.deeplinkManager.listener = { [weak self] type in
                self?.navigate(type: .init(deeplinkType: type))
            }
        }
    }

    func start() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        guard let tabbar = sb.instantiateViewController(withIdentifier: "tabbar") as? ExponeaTabBarController else { return }
        tabbar.coordiantor = self
        navigationController?.present(tabbar, animated: true)
    }

    func navigate(type: CoordinatorType) {
        guard let tabbar = navigationController?.presentedViewController as? ExponeaTabBarController else { return }
        switch type {
        case .anonymize, .manualFlush:
            tabbar.selectedIndex = TabbarItem.flush.index
        case .fetch:
            tabbar.selectedIndex = TabbarItem.fetch.index
        case .track:
            tabbar.selectedIndex = TabbarItem.tracking.index
        }
    }
}

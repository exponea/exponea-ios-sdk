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
    case flush
    case anonymize
    case inappcb

    init(deeplinkType: DeeplinkType) {
        switch deeplinkType {
        case .fetch:
            self = .fetch
        case .track:
            self = .track
        case .flush:
            self = .flush
        case .anonymize:
            self = .anonymize
        case .inappcb:
            self = .inappcb
        }
    }
}

final class Coordinator {

    let navigationController: UINavigationController?
    let tabbar: ExponeaTabBarController?
    private let deeplinkManager = DeeplinkManager.manager

    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
        self.tabbar = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "tabbar") as? ExponeaTabBarController
        // Delay presenting vc
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.deeplinkManager.listener = { [weak self] type in
                self?.navigate(type: .init(deeplinkType: type))
            }
        }
    }

    func start() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        guard let tabbar else { return }
        tabbar.coordinator = self
        navigationController?.pushViewController(tabbar, animated: true)
    }

    func navigate(type: CoordinatorType) {
        guard let navigationController,
              let tabbar else {
            return
        }
        switch type {
        case .flush:
            tabbar.selectedIndex = TabbarItem.flush.index
        case .anonymize:
            tabbar.selectedIndex = TabbarItem.anonymize.index
        case .fetch:
            tabbar.selectedIndex = TabbarItem.fetch.index
        case .track:
            tabbar.selectedIndex = TabbarItem.tracking.index
        case .inappcb:
            tabbar.selectedIndex = TabbarItem.contentBlocks.index
        }
        navigationController.dismiss(animated: true)
    }
}

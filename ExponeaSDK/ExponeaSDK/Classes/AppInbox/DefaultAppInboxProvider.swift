//
//  DefaultAppInboxProvider.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 14/11/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//

import Foundation
import UIKit

open class DefaultAppInboxProvider: AppInboxProvider {

    public init() { }

    open func getAppInboxButton() -> UIButton {
        let button = UIButton()
        var buttonFrame = button.frame
        buttonFrame.size = CGSize(width: 48, height: 48)
        button.frame = buttonFrame
        button.backgroundColor = UIColor(red: 0.0, green: 122.0, blue: 255.0, alpha: 1.0)
        let bundle = getFrameworkBundle()
        #if compiler(>=5)
        let trayDown = UIImage(named: "tray.and.arrow.down",
                            in: bundle,
                            compatibleWith: nil)
        #else
        let trayDown = UIImage(named: "tray.and.arrow.down",
                            inBundle: bundle,
                            compatibleWithTraitCollection: nil)
        #endif
        button.setImage(trayDown, for: .normal)
        button.setTitle(NSLocalizedString(
            "exponea.inbox.button",
            value: "",
            comment: ""
        ), for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        return button
    }

    open func getAppInboxListViewController() -> UIViewController {
        let bundle = getFrameworkBundle()
        let listView = UIStoryboard(name: "AppInboxTemplates", bundle: bundle)
            .instantiateViewController(withIdentifier: "list_view")
        return listView
    }

    open func getAppInboxDetailViewController(_ messageId: String) -> UIViewController {
        let bundle = getFrameworkBundle()
        let detailViewController = UIStoryboard(name: "AppInboxTemplates", bundle: bundle)
            .instantiateViewController(withIdentifier: "detail_view")
        Exponea.shared.fetchAppInboxItem(messageId) { result in
            switch result {
            case .success(let message):
                (detailViewController as! AppInboxDetailViewController).withData(message)
            case .failure:
                Exponea.logger.log(.error, message: "AppInbox message not found for ID \(messageId)")
            }
        }
        return detailViewController
    }

    @objc
    private func buttonAction(sender: UIButton!) {
        let window = UIApplication.shared.keyWindow
        guard let topViewController = InAppMessagePresenter.getTopViewController(window: window) else {
            Exponea.logger.log(.error, message: "Unable to show AppInbox list - no view controller")
            return
        }
        let listView = getAppInboxListViewController()
        let naviController = UINavigationController(rootViewController: listView)
        naviController.modalPresentationStyle = .formSheet
        topViewController.present(naviController, animated: true)
    }

    private func getFrameworkBundle() -> Bundle {
        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        #else
        let bundle = Bundle(for: DefaultAppInboxProvider.self)
        #endif
        return bundle
    }
}

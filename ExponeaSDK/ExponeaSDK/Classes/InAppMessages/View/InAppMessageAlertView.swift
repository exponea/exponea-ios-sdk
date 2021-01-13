//
//  InAppMessageAlertView.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 27/01/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import UIKit

final class InAppMessageAlertView: InAppMessageView {
    let alertController: UIAlertController
    let actionCallback: ((InAppMessagePayloadButton) -> Void)
    let dismissCallback: (() -> Void)

    init(
        payload: InAppMessagePayload,
        actionCallback: @escaping ((InAppMessagePayloadButton) -> Void),
        dismissCallback: @escaping (() -> Void)
    ) throws {
        guard let buttons = payload.buttons else {
            throw InAppMessagePresenter.InAppMessagePresenterError.unableToCreateView
        }
        self.actionCallback = actionCallback
        self.dismissCallback = dismissCallback
        alertController = UIAlertController(
            title: payload.title,
            message: payload.bodyText,
            preferredStyle: .alert
        )
        var hasCancelButton = false
        buttons.forEach { button in
            switch button.buttonType {
            case .cancel:
                hasCancelButton = true
                alertController.addAction(
                    UIAlertAction(title: button.buttonText, style: .cancel, handler: { _ in dismissCallback() })
                )
            case .deeplink:
                alertController.addAction(
                    UIAlertAction(title: button.buttonText, style: .default, handler: { _ in actionCallback(button) })
                )
            }
        }
        if !hasCancelButton {
            alertController.addAction(
                UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in dismissCallback() })
            )
        }
    }

    func present(in viewController: UIViewController, window: UIWindow?) {
        viewController.present(alertController, animated: true)
    }

    func dismiss() {
        guard alertController.presentingViewController != nil else {
            return
        }
        dismissCallback()
        alertController.dismiss(animated: true)
    }
}

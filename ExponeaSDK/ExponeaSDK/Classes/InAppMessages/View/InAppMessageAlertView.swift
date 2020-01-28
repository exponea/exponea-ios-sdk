//
//  InAppMessageAlertView.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 27/01/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

final class InAppMessageAlertView: InAppMessageView {
    let alertController: UIAlertController
    let actionCallback: (() -> Void)
    let dismissCallback: (() -> Void)

    init(
        payload: InAppMessagePayload,
        actionCallback: @escaping (() -> Void),
        dismissCallback: @escaping (() -> Void)
    ) {
        self.actionCallback = actionCallback
        self.dismissCallback = dismissCallback
        alertController = UIAlertController(
            title: payload.title,
            message: payload.bodyText,
            preferredStyle: .alert
        )
        alertController.addAction(
            UIAlertAction(title: payload.buttonText, style: .default, handler: { _ in actionCallback() })
        )
        alertController.addAction(
            UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in dismissCallback() })
        )
    }

    func present(in viewController: UIViewController, window: UIWindow?) {
        viewController.present(alertController, animated: true)
    }
}

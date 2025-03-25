//
//  InAppMessageAlertView.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 27/01/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import UIKit

final class InAppMessageAlertView: InAppMessageView {
    var showCallback: EmptyBlock?
    var isPresented: Bool {
        return alertController.presentingViewController != nil
    }
    let alertController: UIAlertController
    let actionCallback: ((InAppMessagePayloadButton) -> Void)
    let dismissCallback: TypeBlock<(Bool, InAppMessagePayloadButton?)>

    init(
        payload: InAppMessagePayload,
        actionCallback: @escaping ((InAppMessagePayloadButton) -> Void),
        dismissCallback: @escaping TypeBlock<(Bool, InAppMessagePayloadButton?)>
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
                    UIAlertAction(title: button.buttonText, style: .cancel, handler: { [weak self] _ in
                        guard let self else { return }
                        self.dismiss(isUserInteraction: true, cancelButton: button)
                    })
                )
            case .deeplink, .browser:
                alertController.addAction(
                    UIAlertAction(title: button.buttonText, style: .default, handler: { [weak self] _ in
                        guard let self else { return }
                        self.dismiss(actionButton: button)
                    })
                )
            }
        }
        if !hasCancelButton {
            let button = InAppMessagePayloadButton(
                buttonText: "Cancel",
                rawButtonType: "cancel",
                buttonLink: nil,
                buttonTextColor: nil,
                buttonBackgroundColor: nil
            )
            alertController.addAction(
                UIAlertAction(title: button.buttonText, style: .cancel, handler: { [weak self] _ in
                    guard let self else { return }
                    self.dismiss(isUserInteraction: true, cancelButton: button)
                })
            )
        }
    }

    func present(in viewController: UIViewController, window: UIWindow?) {
        viewController.present(alertController, animated: true)
    }

    func dismiss(isUserInteraction: Bool, cancelButton: InAppMessagePayloadButton?) {
        dismissCallback((isUserInteraction, cancelButton))
        dismissFromSuperView()
    }

    func dismiss(actionButton: InAppMessagePayloadButton) {
        actionCallback(actionButton)
        dismissFromSuperView()
    }

    func dismissFromSuperView() {
        guard alertController.presentingViewController != nil else {
            return
        }
        alertController.dismiss(animated: true)
    }
}

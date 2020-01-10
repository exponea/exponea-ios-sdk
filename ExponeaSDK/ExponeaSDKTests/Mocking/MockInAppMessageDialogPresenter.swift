//
//  MockInAppMessageDialogPresenter.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 05/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

@testable import ExponeaSDK

class MockInAppMessageDialogPresenter: InAppMessageDialogPresenterType {
    struct PresentedMessageData {
        let payload: InAppMessagePayload
        let imageData: Data
        let actionCallback: () -> Void
        let dismissCallback: () -> Void
        let presentedCallback: ((InAppMessageDialogViewController?) -> Void)?
    }

    public var presentedMessages: [PresentedMessageData] = []

    public var presentResult: Bool = true
    public var mockViewController = InAppMessageDialogViewController()

    func presentInAppMessage(
        payload: InAppMessagePayload,
        imageData: Data,
        actionCallback: @escaping () -> Void,
        dismissCallback: @escaping () -> Void,
        presentedCallback: ((InAppMessageDialogViewController?) -> Void)?
    ) {
        if presentResult {
            presentedMessages.append(
                PresentedMessageData(
                    payload: payload,
                    imageData: imageData,
                    actionCallback: actionCallback,
                    dismissCallback: dismissCallback,
                    presentedCallback: presentedCallback
                )
            )
        }
        presentedCallback?(presentResult ? mockViewController : nil)
    }
}

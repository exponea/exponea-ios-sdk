//
//  MockInAppMessagePresenter.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 05/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

@testable import ExponeaSDK

class MockInAppMessagePresenter: InAppMessagePresenterType {
    struct PresentedMessageData {
        let messageType: InAppMessageType
        let payload: InAppMessagePayload
        let imageData: Data?
        let actionCallback: (InAppMessagePayloadButton) -> Void
        let dismissCallback: () -> Void
        let presentedCallback: ((InAppMessageView?) -> Void)?
    }

    public var presentedMessages: [PresentedMessageData] = []

    public var presentResult: Bool = true
    func presentInAppMessage(
        messageType: InAppMessageType,
        payload: InAppMessagePayload,
        delay: TimeInterval,
        timeout: TimeInterval?,
        imageData: Data?,
        actionCallback: @escaping (InAppMessagePayloadButton) -> Void,
        dismissCallback: @escaping () -> Void,
        presentedCallback: ((InAppMessageView?) -> Void)?
    ) {
        if presentResult {
            presentedMessages.append(
                PresentedMessageData(
                    messageType: messageType,
                    payload: payload,
                    imageData: imageData,
                    actionCallback: actionCallback,
                    dismissCallback: dismissCallback,
                    presentedCallback: presentedCallback
                )
            )
            DispatchQueue.main.async {
                presentedCallback?(
                    InAppMessageDialogView(
                        payload: payload,
                        image: UIImage(),
                        actionCallback: actionCallback,
                        dismissCallback: dismissCallback,
                        fullscreen: false
                    )
                )
            }
        } else {
            presentedCallback?(nil)
        }
    }
}

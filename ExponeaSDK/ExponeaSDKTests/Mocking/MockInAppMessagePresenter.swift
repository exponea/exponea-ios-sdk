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
        let payload: InAppMessagePayload?
        let payloadHtml: String?
        let imageData: Data?
        let actionCallback: (InAppMessagePayloadButton) -> Void
        let dismissCallback: TypeBlock<Bool>
        let presentedCallback: ((InAppMessageView?, String?) -> Void)?
    }

    public var presentedMessages: [PresentedMessageData] = []

    public var presentResult: Bool = true
    func presentInAppMessage(
        messageType: InAppMessageType,
        payload: InAppMessagePayload?,
        payloadHtml: String?,
        delay: TimeInterval,
        timeout: TimeInterval?,
        imageData: Data?,
        actionCallback: @escaping (InAppMessagePayloadButton) -> Void,
        dismissCallback: @escaping TypeBlock<Bool>,
        presentedCallback: ((InAppMessageView?, String?) -> Void)?
    ) {
        if presentResult {
            presentedMessages.append(
                PresentedMessageData(
                    messageType: messageType,
                    payload: payload,
                    payloadHtml: payloadHtml,
                    imageData: imageData,
                    actionCallback: actionCallback,
                    dismissCallback: dismissCallback,
                    presentedCallback: presentedCallback
                )
            )
            DispatchQueue.main.async {
                presentedCallback?(
                    InAppMessageDialogView(
                        payload: payload!,
                        image: UIImage(),
                        actionCallback: actionCallback,
                        dismissCallback: dismissCallback,
                        fullscreen: false
                    ),
                    nil
                )
            }
        } else {
            presentedCallback?(nil, nil)
        }
    }
}

//
//  MockInAppMessagePresenter.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 05/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

@testable import ExponeaSDK

class MockInAppMessagePresenter: InAppMessagePresenterType {
    var presenting: Bool = false

    struct PresentedMessageData {
        let messageType: InAppMessageType
        let payload: InAppMessagePayload?
        let payloadHtml: String?
        let imageData: Data?
        let actionCallback: (InAppMessagePayloadButton) -> Void
        let dismissCallback: (Bool, InAppMessagePayloadButton?) -> Void
        let presentedCallback: ((InAppMessageView?, String?) -> Void)?
    }

    public var presentedMessages: [PresentedMessageData] = []

    public var presentResult: Bool = true
    
    
    
    func presentInAppMessage(
        messageType: InAppMessageType,
        payload: RichInAppMessagePayload?,
        oldPayload: InAppMessagePayload?,
        payloadHtml: String?,
        delay: TimeInterval,
        timeout: TimeInterval?,
        imageData: Data?,
        actionCallback: @escaping (InAppMessagePayloadButton) -> Void,
        dismissCallback: @escaping (Bool, InAppMessagePayloadButton?) -> Void,
        presentedCallback: ((InAppMessageView?, String?) -> Void)?
    ) {
        if presentResult {
            presentedMessages.append(
                PresentedMessageData(
                    messageType: messageType,
                    payload: oldPayload,
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
                        payload: oldPayload!,
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

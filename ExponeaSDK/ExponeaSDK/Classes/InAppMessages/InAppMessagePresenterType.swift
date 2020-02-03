//
//  InAppMessagePresenterType.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 05/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

protocol InAppMessagePresenterType {
    func presentInAppMessage(
        messageType: InAppMessageType,
        payload: InAppMessagePayload,
        imageData: Data?,
        actionCallback: @escaping () -> Void,
        dismissCallback: @escaping () -> Void,
        presentedCallback: ((InAppMessageView?) -> Void)?
    )
}

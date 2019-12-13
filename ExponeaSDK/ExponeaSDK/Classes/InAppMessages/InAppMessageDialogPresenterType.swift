//
//  InAppMessageDialogPresenterType.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 05/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

protocol InAppMessageDialogPresenterType {
    func presentInAppMessage(
        payload: InAppMessagePayload,
        imageData: Data,
        actionCallback: @escaping () -> Void,
        presentedCallback: ((Bool) -> Void)?
    )
}

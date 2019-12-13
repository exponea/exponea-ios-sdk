//
//  InAppMessagesManager.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 29/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

final class InAppMessagesManager: InAppMessagesManagerType {
    private let repository: RepositoryType
    private let trackingManager: TrackingManagerType
    // cache is synchronous, be careful about calling it from main thread
    private let cache: InAppMessagesCacheType
    private let presenter: InAppMessageDialogPresenterType

    init(
        repository: RepositoryType,
        trackingManager: TrackingManagerType,
        cache: InAppMessagesCacheType = InAppMessagesCache(),
        presenter: InAppMessageDialogPresenterType = InAppMessageDialogPresenter()
    ) {
        self.repository = repository
        self.trackingManager = trackingManager
        self.cache = cache
        self.presenter = presenter
    }

    func preload(completion: (() -> Void)?) {
        DispatchQueue.global(qos: .background).async {
            self.repository.fetchInAppMessages(for: self.trackingManager.customerIds) { result in
                guard case .success(let response) = result else {
                    Exponea.logger.log(.warning, message: "Fetching in-app messages from server failed.")
                    completion?()
                    return
                }
                self.cache.saveInAppMessages(inAppMessages: response.data)
                completion?()
            }
        }
    }

    func getInAppMessage() -> InAppMessage? {
        return self.cache.getInAppMessages().randomElement()
    }

    private func getImageData(message: InAppMessage) -> Data? {
        let imageUrl = URL(string: message.payload.imageUrl)
        return try? Data(contentsOf: imageUrl!)
    }

    func showInAppMessage(callback: ((Bool) -> Void)? = nil) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let message = self.getInAppMessage(),
                  let imageData = self.getImageData(message: message) else {
                callback?(false)
                return
            }

            self.presenter.presentInAppMessage(
                payload: message.payload,
                imageData: imageData,
                actionCallback: { print("ACTION CLICKED - not implemented") },
                presentedCallback: { presented in callback?(presented) }
            )
        }
    }
}

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
                self.cache.deleteImages(except: response.data.map { $0.payload.imageUrl })
                self.preloadImages(inAppMessages: response.data, completion: completion)
            }
        }
    }

    private func preloadImages(inAppMessages: [InAppMessage], completion: (() -> Void)?) {
        inAppMessages.forEach { message in
            if let imageUrl = URL(string: message.payload.imageUrl),
               let data = try? Data(contentsOf: imageUrl) {
                self.cache.saveImageData(at: message.payload.imageUrl, data: data)
            }
        }
        completion?()
    }

    func getInAppMessage() -> InAppMessage? {
        return self.cache.getInAppMessages()
            .filter { return self.cache.hasImageData(at: $0.payload.imageUrl) }
            .randomElement()
    }

    private func getImageData(message: InAppMessage) -> Data? {
        return cache.getImageData(at: message.payload.imageUrl)
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

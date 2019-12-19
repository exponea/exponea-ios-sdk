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
    // cache is synchronous, be careful about calling it from main thread
    private let cache: InAppMessagesCacheType
    private let presenter: InAppMessageDialogPresenterType
    private let displayStatusStore: InAppMessageDisplayStatusStore
    private var sessionStartDate: Date = Date()

    init(
        repository: RepositoryType,
        cache: InAppMessagesCacheType = InAppMessagesCache(),
        displayStatusStore: InAppMessageDisplayStatusStore,
        presenter: InAppMessageDialogPresenterType = InAppMessageDialogPresenter()
    ) {
        self.repository = repository
        self.cache = cache
        self.presenter = presenter
        self.displayStatusStore = displayStatusStore
    }

    func sessionDidStart(at date: Date) {
        sessionStartDate = date
    }

    func preload(for customerIds: [String: JSONValue], completion: (() -> Void)?) {
        DispatchQueue.global(qos: .background).async {
            self.repository.fetchInAppMessages(for: customerIds) { result in
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

    func getInAppMessage(for eventType: String) -> InAppMessage? {
        return self.cache.getInAppMessages()
            .filter {
                return self.cache.hasImageData(at: $0.payload.imageUrl)
                    && $0.applyDateFilter(date: Date())
                    && $0.applyEventFilter(eventType: eventType)
                    && $0.applyFrequencyFilter(
                           displayState: displayStatusStore.status(for: $0),
                           sessionStart: sessionStartDate
                       )
            }.randomElement()
    }

    private func getImageData(for message: InAppMessage) -> Data? {
        return cache.getImageData(at: message.payload.imageUrl)
    }

    func showInAppMessage(
        for eventType: String,
        trackingDelegate: InAppMessageTrackingDelegate? = nil,
        callback: ((Bool) -> Void)? = nil) {
        Exponea.logger.log(.verbose, message: "Attempting to show in-app message for event type \(eventType).")
        DispatchQueue.global(qos: .userInitiated).async {
            guard let message = self.getInAppMessage(for: eventType),
                  let imageData = self.getImageData(for: message) else {
                callback?(false)
                return
            }

            self.presenter.presentInAppMessage(
                payload: message.payload,
                imageData: imageData,
                actionCallback: {
                    print("ACTION CLICKED - not implemented")
                    self.displayStatusStore.didInteract(with: message, at: Date())
                    trackingDelegate?.track(message: message, action: "click", interaction: true)
                },
                dismissCallback: {
                    trackingDelegate?.track(message: message, action: "close", interaction: false)
                },
                presentedCallback: { presented in
                    if presented {
                        self.displayStatusStore.didDisplay(message, at: Date())
                        trackingDelegate?.track(message: message, action: "show", interaction: false)
                    }
                    callback?(presented)
                }
            )
        }
    }
}

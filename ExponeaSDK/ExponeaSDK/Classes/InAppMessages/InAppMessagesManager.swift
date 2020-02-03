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
    private let presenter: InAppMessagePresenterType
    private let displayStatusStore: InAppMessageDisplayStatusStore
    private var sessionStartDate: Date = Date()

    init(
        repository: RepositoryType,
        cache: InAppMessagesCacheType = InAppMessagesCache(),
        displayStatusStore: InAppMessageDisplayStatusStore,
        presenter: InAppMessagePresenterType = InAppMessagePresenter()
    ) {
        self.repository = repository
        self.cache = cache
        self.presenter = presenter
        self.displayStatusStore = displayStatusStore
    }

    func sessionDidStart(at date: Date) {
        sessionStartDate = date
    }

    func anonymize() {
        cache.clear()
        displayStatusStore.clear()
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
            if !message.payload.imageUrl.isEmpty,
               let imageUrl = URL(string: message.payload.imageUrl),
               let data = try? Data(contentsOf: imageUrl) {
                self.cache.saveImageData(at: message.payload.imageUrl, data: data)
            }
        }
        completion?()
    }

    func getInAppMessage(for eventType: String) -> InAppMessage? {
        let messages = self.cache.getInAppMessages()
            .filter {
                return ($0.payload.imageUrl.isEmpty || self.cache.hasImageData(at: $0.payload.imageUrl))
                    && $0.applyDateFilter(date: Date())
                    && $0.applyEventFilter(eventType: eventType)
                    && $0.applyFrequencyFilter(
                           displayState: displayStatusStore.status(for: $0),
                           sessionStart: sessionStartDate
                       )
            }
        Exponea.logger.log(.verbose, message: "Found \(messages.count) eligible in-app messages.")
        return messages.randomElement()
    }

    private func getImageData(for message: InAppMessage) -> Data? {
        return cache.getImageData(at: message.payload.imageUrl)
    }

    func showInAppMessage(
        for eventType: String,
        trackingDelegate: InAppMessageTrackingDelegate? = nil,
        callback: ((InAppMessageView?) -> Void)? = nil
    ) {
        Exponea.logger.log(.verbose, message: "Attempting to show in-app message for event type \(eventType).")
        DispatchQueue.global(qos: .userInitiated).async {
            guard let message = self.getInAppMessage(for: eventType) else {
                callback?(nil)
                return
            }
            var imageData: Data?
            if !message.payload.imageUrl.isEmpty {
                guard let createdImageData = self.getImageData(for: message) else {
                    callback?(nil)
                    return
                }
                imageData = createdImageData
            }

            self.presenter.presentInAppMessage(
                messageType: message.messageType,
                payload: message.payload,
                imageData: imageData,
                actionCallback: {
                    self.displayStatusStore.didInteract(with: message, at: Date())
                    trackingDelegate?.track(message: message, action: "click", interaction: true)
                    self.processInAppMessageAction(message: message)
                },
                dismissCallback: {
                    trackingDelegate?.track(message: message, action: "close", interaction: false)
                },
                presentedCallback: { presented in
                    if presented != nil {
                        self.displayStatusStore.didDisplay(message, at: Date())
                        trackingDelegate?.track(message: message, action: "show", interaction: false)
                    }
                    callback?(presented)
                }
            )
        }
    }

    private func processInAppMessageAction(message: InAppMessage) {
        // there are no other actions right now, add enum later
        if message.payload.buttonType == "deep-link", let url = URL(string: message.payload.buttonLink) {
            let application = UIApplication.shared
            application.open(
                url,
                options: [:],
                completionHandler: { success in
                    // If no success opening url using shared app,
                    // try opening using current app
                    if !success {
                        _ = application.delegate?.application?(application, open: url, options: [:])
                    }
                }
            )
        } else {
            Exponea.logger.log(
                .error,
                message: """
                    Unable to process in-app message action
                    type: \(message.payload.buttonType) link: \(message.payload.buttonLink)"
                """
            )
        }
    }
}

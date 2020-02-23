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
                self.cache.deleteImages(except: response.data.compactMap { $0.payload.imageUrl })
                self.preloadImages(inAppMessages: response.data, completion: completion)
            }
        }
    }

    private func preloadImages(inAppMessages: [InAppMessage], completion: (() -> Void)?) {
        inAppMessages.forEach { message in
            if let imageUrlString = message.payload.imageUrl,
               !imageUrlString.isEmpty,
               let imageUrl = URL(string: imageUrlString),
               let data = try? Data(contentsOf: imageUrl) {
                self.cache.saveImageData(at: imageUrlString, data: data)
            }
        }
        completion?()
    }

    func getInAppMessages(for event: [DataType]) -> [InAppMessage] {
        let messages = self.cache.getInAppMessages()
            .filter {
                let imageUrl = $0.payload.imageUrl ?? ""
                return (imageUrl.isEmpty || self.cache.hasImageData(at: imageUrl))
                    && $0.applyDateFilter(date: Date())
                    && $0.applyEventFilter(event: event)
                    && $0.applyFrequencyFilter(
                           displayState: displayStatusStore.status(for: $0),
                           sessionStart: sessionStartDate
                       )
            }
        let highestPriority = messages.map { $0.priority }.compactMap { $0 }.max() ?? 0
        return messages.filter { $0.priority ?? 0 >= highestPriority }
    }

    func getInAppMessage(for event: [DataType]) -> InAppMessage? {
        let messages = getInAppMessages(for: event)
        Exponea.logger.log(.verbose, message: "Found \(messages.count) eligible in-app messages.")
        return messages.randomElement()
    }

    private func getImageData(for message: InAppMessage) -> Data? {
        guard let imageUrl = message.payload.imageUrl else {
            return nil
        }
        return cache.getImageData(at: imageUrl)
    }

    func showInAppMessage(
        for event: [DataType],
        trackingDelegate: InAppMessageTrackingDelegate? = nil,
        callback: ((InAppMessageView?) -> Void)? = nil
    ) {
        Exponea.logger.log(
            .verbose,
            message: "Attempting to show in-app message for event with types \(event.eventTypes)."
        )
        DispatchQueue.global(qos: .userInitiated).async {
            guard let message = self.getInAppMessage(for: event) else {
                callback?(nil)
                return
            }
            var imageData: Data?
            if !(message.payload.imageUrl ?? "").isEmpty {
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
                actionCallback: { button in
                    self.displayStatusStore.didInteract(with: message, at: Date())
                    trackingDelegate?.track(message: message, action: "click", interaction: true)
                    self.processInAppMessageAction(button: button)
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

    private func processInAppMessageAction(button: InAppMessagePayloadButton) {
        if case .deeplink = button.buttonType,
           let buttonLink = button.buttonLink,
           let url = URL(string: buttonLink) {
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
                    Unable to process in-app message button action
                    type: \(String(describing: button.buttonType))
                    link: \(String(describing: button.buttonLink))"
                """
            )
        }
    }
}

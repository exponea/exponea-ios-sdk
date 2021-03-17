//
//  InAppMessagesManager.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 29/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

final class InAppMessagesManager: InAppMessagesManagerType {
    private static let refreshCacheAfter: TimeInterval = 60 * 30 // refresh on session start if cache is older than this
    private static let maxPendingMessageAge: TimeInterval = 3 // time window to show pending message after preloading

    struct InAppMessageShowRequest {
        let event: [DataType]
        weak var trackingDelegate: InAppMessageTrackingDelegate?
        var callback: ((InAppMessageView?) -> Void)?
        let timestamp: TimeInterval
    }

    private let repository: RepositoryType
    // cache is synchronous, be careful about calling it from main thread
    private let cache: InAppMessagesCacheType
    private let presenter: InAppMessagePresenterType
    private let displayStatusStore: InAppMessageDisplayStatusStore
    private let urlOpener: UrlOpener
    private var sessionStartDate: Date = Date()

    private var preloaded = false
    private var pendingShowRequests: [InAppMessageShowRequest] = []

    init(
        repository: RepositoryType,
        cache: InAppMessagesCacheType = InAppMessagesCache(),
        displayStatusStore: InAppMessageDisplayStatusStore,
        presenter: InAppMessagePresenterType = InAppMessagePresenter(),
        urlOpener: UrlOpener = UrlOpener()
    ) {
        self.repository = repository
        self.cache = cache
        self.presenter = presenter
        self.displayStatusStore = displayStatusStore
        self.urlOpener = urlOpener
    }

    func sessionDidStart(at date: Date, for customerIds: [String: String], completion: (() -> Void)?) {
        sessionStartDate = date
        let refreshTime = cache.getInAppMessagesTimestamp() + InAppMessagesManager.refreshCacheAfter
        if refreshTime < date.timeIntervalSince1970 {
            preload(for: customerIds, completion: completion)
        } else {
            completion?()
        }
    }

    func anonymize() {
        cache.clear()
        displayStatusStore.clear()
    }

    func preload(for customerIds: [String: String], completion: (() -> Void)?) {
        preloaded = false
        DispatchQueue.global(qos: .background).async {
            self.repository.fetchInAppMessages(for: customerIds) { result in
                guard case .success(let response) = result else {
                    Exponea.logger.log(.warning, message: "Fetching in-app messages from server failed.")
                    self.preloaded = true // even though this failed, we can try to use cached data from another run
                    completion?()
                    return
                }
                self.cache.saveInAppMessages(inAppMessages: response.data)
                self.cache.deleteImages(except: response.data.compactMap { $0.payload?.imageUrl })
                self.preloadImages(inAppMessages: response.data, completion: completion)
            }
        }
    }

    @discardableResult private func preloadImage(for message: InAppMessage) -> Bool {
        guard let imageUrlString = message.payload?.imageUrl, !imageUrlString.isEmpty else {
            return true // there is no image, call preload successful
        }
        if let imageUrl = URL(string: imageUrlString),
           let data = try? Data(contentsOf: imageUrl) {
            self.cache.saveImageData(at: imageUrlString, data: data)
            return true
        }
        return false
    }

    private func preloadImages(inAppMessages: [InAppMessage], completion: (() -> Void)?) {
        var messages = inAppMessages
        // if there is a pending message that we should display, preload image for it first and show, then preload rest
        if let pending = pickPendingMessage(requireImageLoaded: false), preloadImage(for: pending.1) {
            messages.removeAll { $0 == pending.1 }
            showPendingInAppMessage(pickedMessage: pending)
        }
        messages.forEach { message in preloadImage(for: message) }
        preloaded = true
        showPendingInAppMessage(pickedMessage: nil)
        completion?()
    }

    private func pickPendingMessage(requireImageLoaded: Bool) -> (InAppMessageShowRequest, InAppMessage)? {
        var pendingMessages: [(InAppMessageShowRequest, InAppMessage)] = []
        pendingShowRequests.filter {
            $0.timestamp + InAppMessagesManager.maxPendingMessageAge > Date().timeIntervalSince1970
        }.forEach { request in
            getInAppMessages(for: request.event, requireImage: requireImageLoaded).forEach { message in
                pendingMessages.append((request, message))
            }
        }
        let highestPriority = pendingMessages.map { $0.1.priority }.compactMap { $0 }.max() ?? 0
        return pendingMessages.filter { $0.1.priority ?? 0 >= highestPriority }.randomElement()
    }

    private func showPendingInAppMessage(pickedMessage: (InAppMessageShowRequest, InAppMessage)?) {
        guard let pending = pickedMessage ?? pickPendingMessage(requireImageLoaded: true) else {
            return
        }
        pendingShowRequests = []
        DispatchQueue.global(qos: .userInitiated).async {
            guard let trackingDelegate = pending.0.trackingDelegate else {
                return
            }
            self.handleInAppMessage(pending.1, trackingDelegate: trackingDelegate, callback: pending.0.callback)
        }
    }

    private func handleInAppMessage(
        _ message: InAppMessage,
        trackingDelegate: InAppMessageTrackingDelegate?,
        callback: ((InAppMessageView?) -> Void)?
    ) {
        if message.payload == nil && message.variantId == -1 {
            Exponea.logger.log(
                .verbose,
                message: "Only logging in-app message for control group '\(message.name)'"
            )
            self.trackInAppMessage(message, trackingDelegate: trackingDelegate)
            callback?(nil)
        } else {
            self.showInAppMessage(message, trackingDelegate: trackingDelegate, callback: callback)
        }
    }

    func getInAppMessages(for event: [DataType], requireImage: Bool) -> [InAppMessage] {
        var messages = self.cache.getInAppMessages()
        Exponea.logger.log(
            .verbose,
            message: "Picking in-app message for eventTypes \(event.eventTypes). " +
            "\(messages.count) messages available: \(messages.map { $0.name })."
        )
        messages = messages.filter {
            let imageUrl = $0.payload?.imageUrl ?? ""
            return (!requireImage || (imageUrl.isEmpty || self.cache.hasImageData(at: imageUrl)))
                && $0.applyDateFilter(date: Date())
                && $0.applyEventFilter(event: event)
                && $0.applyFrequencyFilter(
                       displayState: displayStatusStore.status(for: $0),
                       sessionStart: sessionStartDate
                   )
        }
        Exponea.logger.log(
            .verbose,
            message: "\(messages.count) messages available after filtering. Picking highest priority message."
        )
        let highestPriority = messages.map { $0.priority }.compactMap { $0 }.max() ?? 0
        messages = messages.filter { $0.priority ?? 0 >= highestPriority }
        Exponea.logger.log(
            .verbose,
            message: "Got \(messages.count) messages with highest priority. \(messages.map { $0.name })")
        return messages
    }

    func getInAppMessage(for event: [DataType], requireImage: Bool) -> InAppMessage? {
        let messages = getInAppMessages(for: event, requireImage: requireImage)
        if messages.count > 1 {
            Exponea.logger.log(.verbose, message: "Found \(messages.count) eligible in-app messages. Picking at random")
        }
        return messages.randomElement()
    }

    private func getImageData(for message: InAppMessage) -> Data? {
        guard let imageUrl = message.payload?.imageUrl else {
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
        guard preloaded else {
            Exponea.logger.log(.verbose, message: "Data not preloaded, saving message for later.")
            pendingShowRequests.append(
                InAppMessageShowRequest(
                    event: event,
                    trackingDelegate: trackingDelegate,
                    callback: callback,
                    timestamp: Date().timeIntervalSince1970
                )
            )
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            Exponea.logger.log(.verbose, message: "In-app message data preloaded, picking a message to display")
            guard let message = self.getInAppMessage(for: event) else {
                callback?(nil)
                return
            }
            self.handleInAppMessage(message, trackingDelegate: trackingDelegate, callback: callback)
        }
    }

    private func showInAppMessage(
        _ message: InAppMessage,
        trackingDelegate: InAppMessageTrackingDelegate?,
        callback: ((InAppMessageView?) -> Void)? = nil
    ) {
        guard message.payload != nil else {
            Exponea.logger.log(.verbose, message: "Not showing message with empty payload '\(message.name)'")
            return
        }
        Exponea.logger.log(.verbose, message: "Attempting to show in-app message '\(message.name)'")
        var imageData: Data?
        if !(message.payload?.imageUrl ?? "").isEmpty {
            guard let createdImageData = self.getImageData(for: message) else {
                callback?(nil)
                return
            }
            imageData = createdImageData
        }

        self.presenter.presentInAppMessage(
            messageType: message.messageType,
            payload: message.payload!,
            delay: message.delay,
            timeout: message.timeout,
            imageData: imageData,
            actionCallback: { button in
                self.displayStatusStore.didInteract(with: message, at: Date())
                trackingDelegate?.track(.click(buttonLabel: button.buttonText ?? ""), for: message)
                self.processInAppMessageAction(button: button)
            },
            dismissCallback: {
                trackingDelegate?.track(.close, for: message)
            },
            presentedCallback: { presented in
                if presented != nil {
                    self.trackInAppMessage(message, trackingDelegate: trackingDelegate)
                }
                callback?(presented)
            }
        )
    }

    private func trackInAppMessage(
        _ message: InAppMessage,
        trackingDelegate: InAppMessageTrackingDelegate?
    ) {
        displayStatusStore.didDisplay(message, at: Date())
        trackingDelegate?.track(.show, for: message)
        Exponea.shared.telemetryManager?.report(
            eventWithType: .showInAppMessage,
            properties: ["messageType": message.rawMessageType]
        )
    }

    private func processInAppMessageAction(button: InAppMessagePayloadButton) {
        if case .deeplink = button.buttonType,
           let buttonLink = button.buttonLink {
            urlOpener.openDeeplink(buttonLink)
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

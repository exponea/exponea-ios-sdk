//
//  InAppMessagesManager.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 29/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation
#if canImport(ExponeaSDKShared)
import ExponeaSDKShared
#endif

final class InAppMessagesManager: InAppMessagesManagerType {
    private static let refreshCacheAfter: TimeInterval = 60 * 30 // refresh on session start if cache is older than this
    private static let maxPendingMessageAge: TimeInterval = 3 // time window to show pending message after preloading

    struct InAppMessageShowRequest {
        let event: [DataType]
        var callback: ((InAppMessageView?) -> Void)?
        let timestamp: TimeInterval
    }

    private let repository: RepositoryType
    // cache is synchronous, be careful about calling it from main thread
    private let cache: InAppMessagesCacheType
    private let presenter: InAppMessagePresenterType
    private let displayStatusStore: InAppMessageDisplayStatusStore
    private let trackingConsentManager: TrackingConsentManagerType
    private let urlOpener: UrlOpenerType
    private var sessionStartDate: Date = Date()

    private var preloaded = false
    private let pendingRequestsBarrier = DispatchQueue(label: "pendingShowRequests.barrier", attributes: .concurrent)
    private var pendingShowRequests: [InAppMessageShowRequest] = []
    private var delegateValue: InAppMessageActionDelegate = DefaultInAppDelegate()
    internal var delegate: InAppMessageActionDelegate {
        get {
            return delegateValue
        }
        set {
            delegateValue = newValue
        }
    }

    init(
        repository: RepositoryType,
        cache: InAppMessagesCacheType = InAppMessagesCache(),
        displayStatusStore: InAppMessageDisplayStatusStore,
        presenter: InAppMessagePresenterType = InAppMessagePresenter(),
        urlOpener: UrlOpenerType = UrlOpener(),
        delegate: InAppMessageActionDelegate,
        trackingConsentManager: TrackingConsentManagerType
    ) {
        self.repository = repository
        self.cache = cache
        self.presenter = presenter
        self.displayStatusStore = displayStatusStore
        self.urlOpener = urlOpener
        self.trackingConsentManager = trackingConsentManager
        self.delegate = delegate
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
                DispatchQueue.global(qos: .background).async {
                    self.cache.saveInAppMessages(inAppMessages: response.data)
                    self.cache.deleteImages(except: response.data.compactMap { $0.payload?.imageUrl })
                    self.preloadImages(inAppMessages: response.data, completion: completion)
                }
            }
        }
    }

    @discardableResult private func preloadImage(for message: InAppMessage) -> Bool {
        var imageUrlStrings: [String] = []
        if (message.isHtml && message.payloadHtml != nil) {
            imageUrlStrings.append(contentsOf: HtmlNormalizer(message.payloadHtml!).collectImages() ?? [])
        } else if (message.payload?.imageUrl?.isEmpty == false) {
            imageUrlStrings.append(message.payload!.imageUrl!)
        }
        if (imageUrlStrings.isEmpty) {
            return true // there is no image, call preload successful
        }
        for imageUrlString in imageUrlStrings {
            if (cache.hasImageData(at: imageUrlString)) {
                continue
            }
            let imageData: Data? = tryDownloadImage(imageUrlString)
            guard imageData != nil else {
                return false
            }
            cache.saveImageData(at: imageUrlString, data: imageData!)
            return false
        }
        return true
    }

    private func tryDownloadImage(_ imageSource: String?) -> Data? {
        guard imageSource != nil,
              let imageUrl = URL(string: imageSource!)
                else {
            Exponea.logger.log(.error, message: "Image cannot be downloaded \(imageSource ?? "<is nil>")")
            return nil
        }
        let semaphore = DispatchSemaphore(value: 0)
        var imageData: Data?
        let dataTask = URLSession.shared.dataTask(with: imageUrl) { data, response, error in {
            imageData = data
            semaphore.signal()
        }() }
        dataTask.resume()
        let awaitResult = semaphore.wait(timeout: .now() + 10.0)
        switch (awaitResult) {
        case .success:
            // Nothing to do, let check imageData
            break
        case .timedOut:
            Exponea.logger.log(.warning, message: "Image \(imageSource!) may be too large or slow connection - aborting")
            dataTask.cancel()
        }
        return imageData
    }

    internal func preloadImages(inAppMessages: [InAppMessage], completion: (() -> Void)?) {
            var messages = inAppMessages
            // if there is a pending message that we should display,
            // preload image for it first and show, then preload rest
            if let pending = self.pickPendingMessage(requireImageLoaded: false),
               self.preloadImage(for: pending.1) {
                messages.removeAll { $0 == pending.1 }
                self.showPendingInAppMessage(pickedMessage: pending)
            }
            messages.forEach { message in self.preloadImage(for: message) }
            self.preloaded = true
            self.showPendingInAppMessage(pickedMessage: nil)
            completion?()
    }

    private func pickPendingMessage(requireImageLoaded: Bool) -> (InAppMessageShowRequest, InAppMessage)? {
        var pendingMessages: [(InAppMessageShowRequest, InAppMessage)] = []
        pendingRequestsBarrier.sync(flags: .barrier) {
            pendingShowRequests.filter {
                $0.timestamp + InAppMessagesManager.maxPendingMessageAge > Date().timeIntervalSince1970
            }.forEach { request in
                getInAppMessages(for: request.event, requireImage: requireImageLoaded).forEach { message in
                    pendingMessages.append((request, message))
                }
            }
        }
        let highestPriority = pendingMessages.map { $0.1.priority }.compactMap { $0 }.max() ?? 0
        return pendingMessages.filter { $0.1.priority ?? 0 >= highestPriority }.randomElement()
    }

    private func showPendingInAppMessage(pickedMessage: (InAppMessageShowRequest, InAppMessage)?) {
        guard let pending = pickedMessage ?? pickPendingMessage(requireImageLoaded: true) else {
            return
        }
        pendingRequestsBarrier.sync(flags: .barrier) {
            pendingShowRequests = []
        }
        DispatchQueue.global(qos: .userInitiated).async {
            self.handleInAppMessage(pending.1, callback: pending.0.callback)
        }
    }

    private func handleInAppMessage(
        _ message: InAppMessage,
        callback: ((InAppMessageView?) -> Void)?
    ) {
        if !message.hasPayload() && message.variantId == -1 {
            Exponea.logger.log(
                .verbose,
                message: "Only logging in-app message for control group '\(message.name)'"
            )
            self.trackInAppMessage(message)
            callback?(nil)
        } else {
            self.showInAppMessage(message, callback: callback)
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
        callback: ((InAppMessageView?) -> Void)? = nil
    ) {
        Exponea.logger.log(
            .verbose,
            message: "Attempting to show in-app message for event with types \(event.eventTypes)."
        )
        guard preloaded else {
            Exponea.logger.log(.verbose, message: "Data not preloaded, saving message for later.")
            pendingRequestsBarrier.sync(flags: .barrier) {
                pendingShowRequests.append(
                    InAppMessageShowRequest(
                        event: event,
                        callback: callback,
                        timestamp: Date().timeIntervalSince1970
                    )
                )
            }
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            Exponea.logger.log(.verbose, message: "In-app message data preloaded, picking a message to display")
            guard let message = self.getInAppMessage(for: event) else {
                callback?(nil)
                return
            }
            self.handleInAppMessage(message, callback: callback)
        }
    }

    private func showInAppMessage(
        _ message: InAppMessage,
        callback: ((InAppMessageView?) -> Void)? = nil
    ) {
        guard message.hasPayload() else {
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
            payload: message.payload,
            payloadHtml: message.payloadHtml,
            delay: message.delay,
            timeout: message.timeout,
            imageData: imageData,
            actionCallback: { button in
                self.displayStatusStore.didInteract(with: message, at: Date())

                    if self.delegate.trackActions {
                        self.trackingConsentManager.trackInAppMessageClick(
                            message: message,
                            buttonText: button.buttonText,
                            buttonLink: button.buttonLink,
                            mode: .CONSIDER_CONSENT
                        )
                    }
                    self.delegate.inAppMessageAction(
                        with: message,
                        button: InAppMessageButton(text: button.buttonText, url: button.buttonLink),
                        interaction: true
                    )

                    if !self.delegate.overrideDefaultBehavior {
                        self.processInAppMessageAction(button: button)
                    }
            },
            dismissCallback: {
                    if self.delegate.trackActions {
                        self.trackingConsentManager.trackInAppMessageClose(
                            message: message,
                            mode: .CONSIDER_CONSENT
                        )
                    }
                    self.delegate.inAppMessageAction(with: message, button: nil, interaction: false)
            },
            presentedCallback: { presented, error in
                if (presented == nil && error != nil) {
                    self.trackingConsentManager.trackInAppMessageError(message: message, error: error!, mode: .CONSIDER_CONSENT)
                } else if (presented != nil) {
                    self.trackInAppMessage(message)
                }
                callback?(presented)
            }
        )
    }

    private func trackInAppMessage(
        _ message: InAppMessage
    ) {
        displayStatusStore.didDisplay(message, at: Date())
        trackingConsentManager.trackInAppMessageShown(message: message, mode: .CONSIDER_CONSENT)
        Exponea.shared.telemetryManager?.report(
            eventWithType: .showInAppMessage,
            properties: ["messageType": message.rawMessageType ?? "null"]
        )
    }

    private func processInAppMessageAction(button: InAppMessagePayloadButton) {
        if case .deeplink = button.buttonType,
           let buttonLink = button.buttonLink {
            urlOpener.openDeeplink(buttonLink)
        } else if case .browser = button.buttonType,
                  let buttonLink = button.buttonLink {
            urlOpener.openBrowserLink(buttonLink)
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

    func onEventOccurred(of type: EventType, for event: [DataType]) {
        if (type == .sessionStart) {
            self.sessionDidStart(
                at: Date(timeIntervalSince1970: event.latestTimestamp ?? Date().timeIntervalSince1970),
                for: event.customerIds,
                completion: {}
            )
        } else if (type == .install) {
            self.preload(for: event.customerIds)
        }
        self.showInAppMessage(for: event)
    }
}

public protocol InAppMessageActionDelegate: AnyObject {

    var overrideDefaultBehavior: Bool { get }
    var trackActions: Bool { get }

    func inAppMessageAction(
        with message: InAppMessage,
        button: InAppMessageButton?,
        interaction: Bool
    )
}

public struct InAppMessageButton {
    public let text: String?
    public let url: String?
}

public class DefaultInAppDelegate: InAppMessageActionDelegate {
    public let overrideDefaultBehavior = false
    public let trackActions = true

    public func inAppMessageAction(with message: InAppMessage, button: InAppMessageButton?, interaction: Bool) {}
}

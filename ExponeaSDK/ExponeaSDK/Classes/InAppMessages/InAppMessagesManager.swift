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

extension Dictionary {
    func compareWith(other: [String: String]) -> Bool {
        guard self.count == other.count else { return false }
        return filter { key, value in
            guard let key = key as? String, let value = value as? String else { return false }
            if let check = other[key] {
                return check == value
            }
            return false
        }.count == other.count
    }
}

internal enum IdentifyTriggerState {
    case identifyFetch
    case shouldReloadFetch
    case storedFetch
}

final class InAppMessagesManager: InAppMessagesManagerType {

    struct InAppMessageShowRequest {
        let event: [DataType]
        var callback: ((InAppMessageView?) -> Void)?
        let timestamp: TimeInterval
    }

    struct PendingMessageData {
        let request: InAppMessagesManager.InAppMessageShowRequest
        let message: InAppMessage?
    }

    private let repository: RepositoryType
    // cache is synchronous, be careful about calling it from main thread
    private let cache: InAppMessagesCacheType
    private let presenter: InAppMessagePresenterType
    private let displayStatusStore: InAppMessageDisplayStatusStore
    private let trackingConsentManager: TrackingConsentManagerType
    private let urlOpener: UrlOpenerType
    internal var sessionStartDate: Date = Date()
    private var isIdentifyFlowInProcess: Bool = false
    private static let refreshCacheAfter: TimeInterval = 60 * 30 // refresh on session start if cache is older than this
    private static let maxPendingMessageAge: TimeInterval = 3 // time window to show pending message after preloading
    @Atomic internal var pendingShowRequests: [String: InAppMessageShowRequest] = [:]

    init(
        repository: RepositoryType,
        cache: InAppMessagesCacheType = InAppMessagesCache(),
        displayStatusStore: InAppMessageDisplayStatusStore,
        presenter: InAppMessagePresenterType = InAppMessagePresenter(),
        urlOpener: UrlOpenerType = UrlOpener(),
        trackingConsentManager: TrackingConsentManagerType
    ) {
        self.repository = repository
        self.cache = cache
        self.presenter = presenter
        self.displayStatusStore = displayStatusStore
        self.urlOpener = urlOpener
        self.trackingConsentManager = trackingConsentManager
    }

    // MARK: - Methods
    private func shouldReload(timestamp: TimeInterval) -> Bool {
        let refreshTime = cache.getInAppMessagesTimestamp() + InAppMessagesManager.refreshCacheAfter
        return refreshTime < timestamp
    }

    func anonymize() {
        pendingShowRequests.removeAll()
        cache.clear()
        displayStatusStore.clear()
        if let cookie = Exponea.shared.trackingManager?.customerIds {
            startIdentifyCustomerFlow(for: [.customerIds(cookie)], isAnonymized: true)
        }
    }

    @discardableResult private func preloadImage(for message: InAppMessage) -> Bool {
        var imageUrlStrings: [String] = []
        if message.isHtml && message.payloadHtml != nil {
            imageUrlStrings.append(contentsOf: HtmlNormalizer(message.payloadHtml!).collectImages())
        } else if message.payload?.imageUrl?.isEmpty == false {
            imageUrlStrings.append(message.payload!.imageUrl!)
        }
        if imageUrlStrings.isEmpty {
            Exponea.logger.log(
                .verbose,
                message: "[InApp] There is no image, call preload successful"
            )
            return true // there is no image, call preload successful
        }
        for imageUrlString in imageUrlStrings {
            if cache.hasImageData(at: imageUrlString) {
                continue
            }
            let imageData: Data? = ImageUtils.tryDownloadImage(imageUrlString)
            guard imageData != nil else {
                return false
            }
            cache.saveImageData(at: imageUrlString, data: imageData!)
            return false
        }
        return true
    }

    private var pickPendingMessage: InAppMessage? {
        guard let currentCustomerIds = Exponea.shared.trackingManager?.customerIds, !presenter.presenting else {
            Exponea.logger.log(
                .verbose,
                message: "[InApp] Pick pending messages faield due to customer id: \(Exponea.shared.trackingManager?.customerIds ?? [:]) or presenter.presenting: \(presenter.presenting)"
            )
            return nil
        }
        Exponea.logger.log(
            .verbose,
            message: "[InApp] Pick pending messages start"
        )
        let pendingMessages = pendingShowRequests
            .filter { $0.value.timestamp + InAppMessagesManager.maxPendingMessageAge > Date().timeIntervalSince1970 }
            .filter { $0.value.event.customerIds.compareWith(other: currentCustomerIds) }
            .map { PendingMessageData(request: $0.value, message: loadMessageToShow(for: $0.value.event)) }
        Exponea.logger.log(
            .verbose,
            message: "[InApp] Filtered pending messages \(pendingMessages)"
        )
        let highestPriority = pendingMessages.compactMap { $0.message?.priority }.max() ?? 0
        let message = pendingMessages.filter { $0.message?.priority ?? 0 >= highestPriority }.randomElement()
        return message?.message
    }

    private func handleInAppMessage(
        _ message: InAppMessage,
        callback: ((InAppMessageView?) -> Void)?
    ) {
        if !message.hasPayload() && message.variantId == -1 {
            Exponea.logger.log(
                .verbose,
                message: "[InApp] Only logging in-app message for control group '\(message.name)'"
            )
            self.trackInAppMessageShown(message)
            callback?(nil)
        } else {
            self.showInAppMessage(message, callback: callback)
        }
    }

    private func getImageData(for message: InAppMessage) -> Data? {
        guard let imageUrl = message.payload?.imageUrl else {
            return nil
        }
        Exponea.logger.log(
            .verbose,
            message: "[InApp] Image data \(message)"
        )
        return cache.getImageData(at: imageUrl)
    }

    internal func showInAppMessage(for type: [DataType], callback: ((InAppMessageView?) -> Void)?) {
        guard let message = loadMessageToShow(for: type) else {
            callback?(nil)
            return
        }
        Exponea.logger.log(
            .verbose,
            message: "[InApp] Show InAppMessage \(message)"
        )
        showInAppMessage(message, callback: callback)
    }

    private func showInAppMessage(
        _ message: InAppMessage,
        callback: ((InAppMessageView?) -> Void)? = nil
    ) {
        guard message.hasPayload() && message.variantId != -1 else {
            Exponea.logger.log(
                .verbose,
                message: "[InApp] Only logging in-app message for control group '\(message.name)'"
            )
            self.trackInAppMessageShown(message)
            callback?(nil)
            return
        }
        Exponea.logger.log(.verbose, message: "[InApp] Attempting to show in-app message '\(message.name)'")
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
                if Exponea.shared.inAppMessagesDelegate.trackActions {
                    self.trackingConsentManager.trackInAppMessageClick(
                        message: message,
                        buttonText: button.buttonText,
                        buttonLink: button.buttonLink,
                        mode: .CONSIDER_CONSENT,
                        isUserInteraction: true
                    )
                }
                Exponea.shared.inAppMessagesDelegate.inAppMessageAction(
                    with: message,
                    button: InAppMessageButton(
                        text: button.buttonText,
                        url: button.buttonLink
                    ),
                    interaction: true
                )

                if !Exponea.shared.inAppMessagesDelegate.overrideDefaultBehavior {
                    self.processInAppMessageAction(button: button)
                }
            },
            dismissCallback: { isUserInteraction in
                if Exponea.shared.inAppMessagesDelegate.trackActions {
                    self.trackingConsentManager.trackInAppMessageClose(
                        message: message,
                        mode: .CONSIDER_CONSENT,
                        isUserInteraction: isUserInteraction
                    )
                }
                Exponea.shared.inAppMessagesDelegate.inAppMessageAction(
                    with: message,
                    button: nil,
                    interaction: isUserInteraction
                )
            },
            presentedCallback: { presented, error in
                if presented == nil && error != nil {
                    self.trackInAppMessageError(message, error!)
                } else if presented != nil {
                    self.trackInAppMessageShown(message)
                }
                callback?(presented)
            }
        )
    }
    
    private func trackInAppMessageError(
        _ message: InAppMessage,
        _ error: String
    ) {
        self.trackingConsentManager.trackInAppMessageError(message: message, error: error, mode: .CONSIDER_CONSENT)
        Exponea.shared.inAppMessagesDelegate.inAppMessageError(message: message, errorMessage: error)
    }

    private func trackInAppMessageShown(
        _ message: InAppMessage
    ) {
        displayStatusStore.didDisplay(message, at: Date())
        trackingConsentManager.trackInAppMessageShown(message: message, mode: .CONSIDER_CONSENT)
        Exponea.shared.inAppMessagesDelegate.inAppMessageShown(message: message)
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
                    [InApp]
                    Unable to process in-app message button action
                    type: \(String(describing: button.buttonType))
                    link: \(String(describing: button.buttonLink))"
                """
            )
        }
    }

    private func checkPendingRequests() -> [DataType] {
        if let event = pendingShowRequests.map({ $0.value }).last?.event {
            return event
        }
        Exponea.logger.log(.warning, message: "[InApp] No more pending requests")
        return []
    }

    func fetchInAppMessages(for event: [DataType], completion: EmptyBlock? = nil) {
        repository.fetchInAppMessages(for: event.customerIds) { [weak self] result in
            self?.isIdentifyFlowInProcess = false
            guard case let .success(response) = result,
                    let self,
                    var currentCustomerIds = Exponea.shared.trackingManager?.customerIds
            else {
                Exponea.logger.log(
                    .verbose,
                    message: "[InApp] fetchInAppMessages failed '\(result)', current customer: '\(Exponea.shared.trackingManager?.customerIds ?? [:])'"
                )
                completion?()
                return
            }
            // For test purpose only
            if event.customerIds.isEmpty {
                currentCustomerIds.removeAll()
            }
            guard event.customerIds.compareWith(other: currentCustomerIds) else {
                Exponea.logger.log(
                    .verbose,
                    message: "[InApp] Fetch InAppMessages - different customer ids"
                )
                return
            }
            Exponea.logger.log(
                .verbose,
                message: "[InApp] Fetch completed \(response.data ?? []), total messages: \(response.data?.count ?? 0)"
            )
            self.cache.saveInAppMessages(inAppMessages: response.data ?? [])
            self.cache.deleteImages(except: response.data?.compactMap { $0.payload?.imageUrl } ?? [])
            completion?()
        }
    }

    internal func addToPendingShowRequest(event: [DataType]) {
        _pendingShowRequests.changeValue { value in
            let newRequest = InAppMessageShowRequest(
                event: event,
                callback: nil,
                timestamp: Date().timeIntervalSince1970
            )
            if let eventType = newRequest.event.eventTypes.last {
                value[eventType] = newRequest
            }
        }
    }

    internal func startIdentifyCustomerFlow(
        for event: [DataType],
        isFromIdentifyCustomer: Bool = false,
        isFetchDisabled: Bool = false,
        isAnonymized: Bool = false,
        triggerCompletion: TypeBlock<IdentifyTriggerState>? = nil
    ) {
        // Register pending request if event is not identify customer
        if !isFromIdentifyCustomer {
            Exponea.logger.log(
                .verbose,
                message: "[InApp] Add event - \(event) to pending requests"
            )
            addToPendingShowRequest(event: event)
        }
        guard Exponea.shared.isAppForeground else {
            Exponea.logger.log(
                .verbose,
                message: "[InApp] Skipping messages process for \(event) because app is not in foreground state"
            )
            return
        }
        // Should reload or identify customer
        switch true {
        case isFromIdentifyCustomer:
            Exponea.logger.log(
                .verbose,
                message: "[InApp] Identify customer in progress"
            )
            pendingShowRequests.removeAll()
            isIdentifyFlowInProcess = true
            if triggerCompletion != nil {
                isIdentifyFlowInProcess = false
                triggerCompletion?(.identifyFetch)
            }
            fetchInAppMessages(for: event) {
                loadMessageIfNeeded()
            }
        case isAnonymized:
            Exponea.logger.log(
                .verbose,
                message: "[InApp] Fetch in app messages, because 'isAnonymized'"
            )
            fetchInAppMessages(for: event)
        case shouldReload(timestamp: event.latestTimestamp ?? Date().timeIntervalSince1970) && !isFetchDisabled:
            Exponea.logger.log(
                .verbose,
                message: "[InApp] Reloading in app messages, because 'shouldReload'"
            )
            fetchInAppMessages(for: event) {
                loadMessageIfNeeded()
            }
            // For test purposes. Initialized only inside test
            if triggerCompletion != nil {
                sessionStartDate = Date().addingTimeInterval(-Date().timeIntervalSince1970)
                isIdentifyFlowInProcess = false
                triggerCompletion?(.shouldReloadFetch)
            }
        default:
            if !isIdentifyFlowInProcess {
                Exponea.logger.log(
                    .verbose,
                    message: "[InApp] ShoulReload is false. Just load messages'"
                )
                loadMessageIfNeeded()
                // For test purposes. Initialized only inside test
                if triggerCompletion != nil {
                    isIdentifyFlowInProcess = false
                    triggerCompletion?(.storedFetch)
                }
            }
        }
        func loadMessageIfNeeded() {
            if let message = pickPendingMessage {
                Exponea.logger.log(
                    .verbose,
                    message: "[InApp] Show pending InAppMessage for event \(event)"
                )
                if preloadImage(for: message) {
                    isIdentifyFlowInProcess = false
                    onMain(self.showInAppMessage(message))
                }
            } else {
                if let message = loadMessageToShow(for: event) {
                    if preloadImage(for: message) {
                        isIdentifyFlowInProcess = false
                        onMain(self.showInAppMessage(message))
                    }
                }
            }
            pendingShowRequests.removeAll()
        }
    }

    @discardableResult
    func loadMessagesToShow(for event: [DataType]) -> [InAppMessage] {
        var messages = cache.getInAppMessages()
        Exponea.logger.log(
            .verbose,
            message: "[InApp] Picking in-app message for eventTypes \(event.eventTypes). " +
            "\(messages.count) messages available: \(messages.map { $0.name })."
        )
        messages = messages.filter {
            $0.applyDateFilter(date: Date())
            && $0.applyEventFilter(event: event)
            && $0.applyFrequencyFilter(
                displayState: displayStatusStore.status(for: $0),
                sessionStart: sessionStartDate
            )
        }
        Exponea.logger.log(
            .verbose,
            message: "[InApp] \(messages.count) messages available after filtering. Picking highest priority message."
        )
        let messagesWithImage = messages.filter { preloadImage(for: $0) }
        let highestPriority = messagesWithImage.map { $0.priority }.compactMap { $0 }.max() ?? 0
        messages = messages.filter { $0.priority ?? 0 >= highestPriority }
        Exponea.logger.log(
            .verbose,
            message: "[InApp] Got \(messages.count) messages with highest priority. \(messages.map { $0.name })")
        return messages
    }

    @discardableResult
    func loadMessageToShow(for event: [DataType]) -> InAppMessage? {
        loadMessagesToShow(for: event).randomElement()
    }

    internal func onEventOccurred(of type: EventType, for event: [DataType], triggerCompletion: TypeBlock<IdentifyTriggerState>? = nil) {
        switch type {
        case .sessionStart:
            Exponea.logger.log(
                .verbose,
                message: "[InApp] Session start"
            )
            sessionStartDate = Date(timeIntervalSince1970: event.latestTimestamp ?? Date().timeIntervalSince1970)
            startIdentifyCustomerFlow(for: event, triggerCompletion: triggerCompletion)
        case .sessionEnd, .pushDelivered, .pushOpened:
            Exponea.logger.log(
                .verbose,
                message: "[InApp] Event type - \(type)"
            )
            startIdentifyCustomerFlow(for: event, isFetchDisabled: true)
        default:
            Exponea.logger.log(
                .verbose,
                message: "[InApp] Event type - \(type)"
            )
            startIdentifyCustomerFlow(for: event, isFromIdentifyCustomer: type == .identifyCustomer, triggerCompletion: triggerCompletion)
        }
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
    func inAppMessageShown(message: InAppMessage)
    func inAppMessageError(message: InAppMessage?, errorMessage: String)
}

public struct InAppMessageButton: Codable {
    public let text: String?
    public let url: String?
}

public class DefaultInAppDelegate: InAppMessageActionDelegate {
    public let overrideDefaultBehavior = false
    public let trackActions = true

    public func inAppMessageAction(with message: InAppMessage, button: InAppMessageButton?, interaction: Bool) {}
    public func inAppMessageShown(message: InAppMessage) {}
    public func inAppMessageError(message: InAppMessage?, errorMessage: String) {}
}

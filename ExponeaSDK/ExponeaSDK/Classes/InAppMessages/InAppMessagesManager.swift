//
//  InAppMessagesManager.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 29/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import UIKit
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

final class InAppMessagesManager: InAppMessagesManagerType, @unchecked Sendable {

    struct InAppMessageShowRequest {
        let event: [DataType]
        var callback: ((InAppMessageView?) -> Void)?
        let timestamp: TimeInterval
    }

    struct PendingMessageData {
        let request: InAppMessagesManager.InAppMessageShowRequest
        let message: InAppMessage?
    }

    enum InAppMessageError: Error {
        case diferrentCustomers
        case fetchInAppMessagesFailed
        case imageNotFound
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
    private lazy var identifyFlowQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "identify flow"
        return queue
    }()

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

        IntegrationManager.shared.onIntegrationStoppedCallbacks.append { [weak self] in
            guard let self else { return }
            self.pendingShowRequests.removeAll()
            self.cache.clear()
            self.displayStatusStore.clear()
        }
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
            Task { [weak self] in
                await self?.startIdentifyCustomerFlow(for: [.customerIds(cookie)], isAnonymized: true)
            }
        }
    }

    @_disfavoredOverload
    private func preloadImage(for message: InAppMessage) -> Bool {
        preloadImage(for: message) != nil
    }

    @discardableResult private func preloadImage(for message: InAppMessage) -> UIImage? {
        var imageUrlStrings: [String] = []
        if message.isHtml && message.payloadHtml != nil {
            imageUrlStrings.append(contentsOf: HtmlNormalizer(message.payloadHtml!).collectImages())
        } else if let imageUrl = message.payload?.imageConfig.url {
            imageUrlStrings.append(imageUrl.absoluteString)
        } else if let imageUrl = message.oldPayload?.imageUrl {
            imageUrlStrings.append(imageUrl)
        }
        if imageUrlStrings.isEmpty {
            Exponea.logger.log(
                .verbose,
                message: "[InApp] There is no image, call preload successful"
            )
            return .init() // there is no image, call preload successful
        }
        for imageUrlString in imageUrlStrings {
            if imageUrlString.isEmpty {
                continue
            }
            if cache.hasImageData(at: imageUrlString) {
                continue
            }
            guard let imageData = ImageUtils.tryDownloadImage(imageUrlString) else {
                return nil
            }
            cache.saveImageData(at: imageUrlString, data: imageData)
            return .init(data: imageData)
        }
        return .init()
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
        _pendingShowRequests.changeValue(with: { $0.removeAll() })
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
            Task { [weak self] in
                await self?.showInAppMessage(message, callback: callback)
            }
        }
    }

    private func getImageData(for message: InAppMessage) -> Data? {
        guard let imageUrl = message.oldPayload?.imageUrl ?? message.payload?.imageConfig.url?.absoluteString else {
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
        Task { @MainActor [weak self] in
            await self?.showInAppMessage(message, callback: callback)
        }
    }

    private func showInAppMessage(
        _ message: InAppMessage,
        callback: ((InAppMessageView?) -> Void)? = nil
    ) async {
        guard !IntegrationManager.shared.isStopped else {
            Exponea.logger.log(
                .error,
                message: "In-app UI is unavailable, SDK is stopping"
            )
            return
        }
        await withCheckedContinuation { [weak self] continuation in
            guard let self else { return }
            guard message.hasPayload() && message.variantId != -1 else {
                Exponea.logger.log(
                    .verbose,
                    message: "[InApp] Only logging in-app message for control group '\(message.name)'"
                )
                self.trackInAppMessageShown(message)
                callback?(nil)
                continuation.resume()
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
            if !(message.oldPayload?.imageUrl ?? "").isEmpty {
                guard let createdImageData = self.getImageData(for: message) else {
                    callback?(nil)
                    return
                }
                imageData = createdImageData
            }

            self.presenter.presentInAppMessage(
                messageType: message.messageType,
                payload: message.payload,
                oldPayload: message.oldPayload,
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
                    Exponea.shared.inAppMessagesDelegate.inAppMessageClickAction(
                        message: message,
                        button: InAppMessageButton(
                            text: button.buttonText,
                            url: button.buttonLink
                        )
                    )

                    if !Exponea.shared.inAppMessagesDelegate.overrideDefaultBehavior {
                        self.processInAppMessageAction(button: button)
                    }
                },
                dismissCallback: { isUserInteraction, cancelButtonPayload in
                    if Exponea.shared.inAppMessagesDelegate.trackActions {
                        self.trackingConsentManager.trackInAppMessageClose(
                            message: message,
                            buttonText: cancelButtonPayload?.buttonText,
                            mode: .CONSIDER_CONSENT,
                            isUserInteraction: isUserInteraction
                        )
                    }
                    var cancelButton: InAppMessageButton?
                    if let cancelButtonPayload {
                        cancelButton = InAppMessageButton(
                            text: cancelButtonPayload.buttonText, url: cancelButtonPayload.buttonLink
                        )
                    }
                    Exponea.shared.inAppMessagesDelegate.inAppMessageCloseAction(
                        message: message,
                        button: cancelButton,
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
            continuation.resume()
        }
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

    let semaphore = DispatchSemaphore(value: 0)

    private func extractFont(url: String, fontSize: String?, size: CGFloat?) async -> InAppButtonFontData? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .background).async {
                if let data = FileCache.shared.getOrDownloadFile(at: url),
                   let dataProvider = CGDataProvider(data: data as CFData),
                   let cgFont = CGFont(dataProvider) {
                    var fontData: InAppButtonFontData = .init()
                    var error: Unmanaged<CFError>?
                    if CTFontManagerRegisterGraphicsFont(cgFont, &error) {
                        fontData.fontName = cgFont.postScriptName as? String
                        CTFontManagerUnregisterGraphicsFont(cgFont, &error)
                        let size = size ?? fontSize?.convertPxToFloatWithDefaultValue() ?? 13
                        fontData.fontSize = size
                        fontData.fontData = data.base64EncodedString()
                    } else {
                        Exponea.logger.log(
                            .error,
                            message: "[InApp] Cant download custom font from url"
                        )
                    }
                    continuation.resume(returning: fontData)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func fetchImagesAndFonts(inAppMessages: [InAppMessage]) async -> [InAppMessage] {
        await withCheckedContinuation { [weak self] continuation in
            guard let self else {
                continuation.resume(returning: [])
                return
            }
            Task(priority: .background) { @MainActor in
                var messagesToReturn: [InAppMessage] = []
                for message in inAppMessages {
                    var copy = message
                    self.preloadImage(for: copy)
                    if let titleConfig = copy.payload?.titleConfig, let customFont = titleConfig.customFont {
                        copy.payload?.titleFontData = await self.extractFont(url: customFont, fontSize: nil, size: titleConfig.size)
                    }
                    if let bodyConfig = copy.payload?.bodyConfig, let customFont = bodyConfig.customFont {
                        copy.payload?.bodyFontData = await self.extractFont(url: customFont, fontSize: nil, size: bodyConfig.size)
                    }
                    let buttons: [InAppButtonPayload] = copy.payload?.buttons ?? []
                    var updatedButtons: [InAppButtonPayload] = []
                    for button in buttons {
                        var copyButton = button
                        if let buttonConfig = copyButton.buttonConfig, let customFont = buttonConfig.fontURL {
                            copyButton.fontData = await self.extractFont(url: customFont, fontSize: nil, size: CGFloat(buttonConfig.size))
                        }
                        updatedButtons.append(copyButton)
                    }
                    copy.payload?.buttons = updatedButtons
                    messagesToReturn.append(copy)
                }
                continuation.resume(returning: messagesToReturn)
            }
        }
    }

    private func checkAndClearCustomerIdsIfNeeded(event: [DataType], currentCustomerIds: inout [String: String]) {
        // For test purpose only
        if event.customerIds.isEmpty {
            currentCustomerIds.removeAll()
        }
    }

    func fetchInAppMessages(for event: [DataType], completion: EmptyBlock? = nil) {
        guard !IntegrationManager.shared.isStopped else {
            Exponea.logger.log(
                .error,
                message: "In-app fetch failed, SDK is stopping"
            )
            return
        }
        repository.fetchInAppMessages(for: event.customerIds) { [weak self] result in
            guard !IntegrationManager.shared.isStopped else {
                Exponea.logger.log(
                    .error,
                    message: "In-app fetch failed, SDK is stopping"
                )
                return
            }
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
            self.cache.deleteImages(except: response.data?.compactMap { message in
                if message.oldPayload != nil {
                    return message.oldPayload?.imageUrl
                } else {
                    return message.payload?.imageUrl
                }
            } ?? [])
            completion?()
        }
    }

    @discardableResult
    internal func isFetchInAppMessagesDone(for event: [DataType]) async throws -> Bool {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self else { return }
            DispatchQueue.global(qos: .userInitiated).async {
                self.repository.fetchInAppMessages(for: event.customerIds) { result in
                    Task {
                        self.isIdentifyFlowInProcess = false
                        switch result {
                        case let .success(response):
                            if var currentCustomerIds = Exponea.shared.trackingManager?.customerIds, !currentCustomerIds.isEmpty {
                                var messages = response.data ?? []
                                messages = await self.fetchImagesAndFonts(inAppMessages: messages)
                                self.checkAndClearCustomerIdsIfNeeded(event: event, currentCustomerIds: &currentCustomerIds)
                                if !event.customerIds.compareWith(other: currentCustomerIds) {
                                    Exponea.logger.log(
                                        .verbose,
                                        message: "[InApp] Fetch InAppMessages - different customer ids"
                                    )
                                    continuation.resume(returning: true)
                                } else {
                                    Exponea.logger.log(
                                        .verbose,
                                        message: "[InApp] Fetch completed \(messages), total messages: \(messages.count)"
                                    )
                                    self.cache.saveInAppMessages(inAppMessages: messages)
                                    self.cache.deleteImages(except: response.data?.compactMap { message in
                                        if message.oldPayload != nil {
                                            return message.oldPayload?.imageUrl
                                        } else {
                                            return message.payload?.imageUrl
                                        }
                                    } ?? [])
                                    continuation.resume(returning: true)
                                }
                            } else {
                                Exponea.logger.log(
                                    .verbose,
                                    message: "[InApp] fetchInAppMessages failed '\(result)', current customer: '\(Exponea.shared.trackingManager?.customerIds ?? [:])'"
                                )
                                continuation.resume(throwing: InAppMessageError.fetchInAppMessagesFailed)
                            }
                        case let .failure(error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
        }
    }

    private func clearImagesAndFonts() {
        cache.deleteImages(except: [])
    }

    internal func addToPendingShowRequest(event: [DataType]) async {
        await withCheckedContinuation { continuation in
            _pendingShowRequests.changeValue { value in
                let newRequest = InAppMessageShowRequest(
                    event: event,
                    callback: nil,
                    timestamp: Date().timeIntervalSince1970
                )
                if let eventType = newRequest.event.eventTypes.last {
                    value[eventType] = newRequest
                }
                continuation.resume()
            }
        }
    }

    @discardableResult
    private func isFlushDone() async -> Bool {
        await withCheckedContinuation { continuation in
            switch Exponea.shared.flushingMode {
            case .immediate:
                Exponea.shared.flushingManager?.flushData()
                continuation.resume(returning: true)
            default:
                continuation.resume(returning: true)
            }
        }
    }

    internal func startIdentifyCustomerFlow(
        for event: [DataType],
        isFromIdentifyCustomer: Bool = false,
        isFetchDisabled: Bool = false,
        isAnonymized: Bool = false,
        triggerCompletion: TypeBlock<IdentifyTriggerState>? = nil
    ) async {
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
            _pendingShowRequests.changeValue(with: { $0.removeAll() })
            clearImagesAndFonts()
            isIdentifyFlowInProcess = true
            await isFlushDone()
            await addToPendingShowRequest(event: event)
            if triggerCompletion != nil {
                isIdentifyFlowInProcess = false
                triggerCompletion?(.identifyFetch)
            }
            guard Exponea.shared.isAppForeground else { return }
            do {
                try await isFetchInAppMessagesDone(for: event)
                let message = try await loadMessageIfNeeded(event: event)
                await showInAppMessage(message)
            } catch {
                Exponea.logger.log(
                    .error,
                    message: "[InApp] fetchInAppMessages error \(error)"
                )
            }
        case isAnonymized:
            Exponea.logger.log(
                .verbose,
                message: "[InApp] Fetch in app messages, because 'isAnonymized'"
            )
            _pendingShowRequests.changeValue(with: { $0.removeAll() })
            clearImagesAndFonts()
            do {
                try await isFetchInAppMessagesDone(for: event)
            } catch {
                Exponea.logger.log(
                    .error,
                    message: "[InApp] fetchInAppMessages error \(error)"
                )
            }
        case shouldReload(timestamp: event.latestTimestamp ?? Date().timeIntervalSince1970) && !isFetchDisabled:
            Exponea.logger.log(
                .verbose,
                message: "[InApp] Reloading in app messages, because 'shouldReload'"
            )
            do {
                try await isFetchInAppMessagesDone(for: event)
                let message = try await loadMessageIfNeeded(event: event)
                await showInAppMessage(message)
            } catch {
                Exponea.logger.log(
                    .error,
                    message: "[InApp] fetchInAppMessages error \(error)"
                )
            }
            // For test purposes. Initialized only inside test
            if triggerCompletion != nil {
                sessionStartDate = Date().addingTimeInterval(-Date().timeIntervalSince1970)
                isIdentifyFlowInProcess = false
                triggerCompletion?(.shouldReloadFetch)
            }
        default:
            if let banner = event.first(where: { $0 == .eventType("banner") }), banner == .properties(["action": .string("show")]) {
                Exponea.logger.log(
                    .verbose,
                    message: "InApp: Skipping messages process for In-app show event"
                )
                return
            }
            if !isIdentifyFlowInProcess {
                Exponea.logger.log(
                    .verbose,
                    message: "[InApp] ShoulReload is false. Just load messages'"
                )
                do {
                    let message = try await loadMessageIfNeeded(event: event)
                    await showInAppMessage(message)
                } catch {
                    Exponea.logger.log(
                        .error,
                        message: "[InApp] loadMessageIfNeeded error \(error)"
                    )
                }

                // For test purposes. Initialized only inside test
                if triggerCompletion != nil {
                    isIdentifyFlowInProcess = false
                    triggerCompletion?(.storedFetch)
                }
            }
        }
    }

    private func loadMessageIfNeeded(event: [DataType]) async throws -> InAppMessage {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self else { return }
            DispatchQueue.global(qos: .userInitiated).async {
                if var message = self.pickPendingMessage {
                    self.pendingShowRequests.removeAll()
                    if !self.presenter.presenting &&
                        event.customerIds.compareWith(
                            other: Exponea.shared.trackingManager?.customerIds ?? [:]
                    ) {
                        Exponea.logger.log(
                            .verbose,
                            message: """
                                [InApp] Show pending InAppMessage for event \(event)
                                presenter.presenting is \(self.presenter.presenting)
                                compareWith is \(event.customerIds.compareWith(
                                    other: Exponea.shared.trackingManager?.customerIds ?? [:]
                                ))
                            """
                        )
                        self.isIdentifyFlowInProcess = false
                        if message.downloadedImage == nil, let image = self.preloadImage(for: message) {
                            message.downloadedImage = image
                            onMain {
                                continuation.resume(returning: message)
                            }
                        } else {
                            onMain {
                                if message.downloadedImage == nil {
                                    Exponea.logger.log(
                                        .verbose,
                                        message: "[InApp] Fetch InAppMessages - no download image found for message (\(message.id))"
                                    )
                                    continuation.resume(throwing: InAppMessageError.imageNotFound)
                                } else {
                                    continuation.resume(returning: message)
                                }
                            }
                        }
                    } else {
                        Exponea.logger.log(
                            .verbose,
                            message: "[InApp] Fetch InAppMessages - different customer ids"
                        )
                        onMain {
                            continuation.resume(throwing: InAppMessageError.fetchInAppMessagesFailed)
                        }
                    }
                } else {
                    if var message = self.loadMessageToShow(for: event) {
                        self.isIdentifyFlowInProcess = false
                        if message.downloadedImage == nil, let image = self.preloadImage(for: message) {
                            message.downloadedImage = image
                            onMain {
                                continuation.resume(returning: message)
                            }
                        } else {
                            onMain {
                                if message.downloadedImage == nil {
                                    Exponea.logger.log(
                                        .verbose,
                                        message: "[InApp] Fetch InAppMessages - no download image found for message (\(message.id))"
                                    )
                                    continuation.resume(throwing: InAppMessageError.imageNotFound)
                                } else {
                                    continuation.resume(returning: message)
                                }
                            }
                        }
                    } else {
                        onMain {
                            continuation.resume(throwing: InAppMessageError.fetchInAppMessagesFailed)
                        }
                    }
                }
            }
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

    private func extractFont(base64: String?, size: CGFloat?) -> UIFont? {
        if let base64 = base64,
           let data = Data(base64Encoded: base64),
           let dataProvider = CGDataProvider(data: data as CFData),
           let cgFont = CGFont(dataProvider) {
            var error: Unmanaged<CFError>?
            if CTFontManagerRegisterGraphicsFont(cgFont, &error) {
                var font: UIFont?
                if let fontName = cgFont.postScriptName as? String {
                    font = UIFont(name: fontName, size: size ?? 13)
                }
                CTFontManagerUnregisterGraphicsFont(cgFont, &error)
                return font
            }
        }
        return nil
    }

    @discardableResult
    func loadMessageToShow(for event: [DataType]) -> InAppMessage? {
        loadMessagesToShow(for: event).randomElement()
    }

    internal func onEventOccurred(of type: EventType, for event: [DataType], triggerCompletion: TypeBlock<IdentifyTriggerState>? = nil) {
        identifyFlowQueue.addOperation { [weak self] in
            Task {
                guard let self else { return }
                switch type {
                case .sessionStart:
                    Exponea.logger.log(
                        .verbose,
                        message: "[InApp] Session start"
                    )
                    self.sessionStartDate = Date(timeIntervalSince1970: event.latestTimestamp ?? Date().timeIntervalSince1970)
                    await self.startIdentifyCustomerFlow(for: event, triggerCompletion: triggerCompletion)
                case .sessionEnd, .pushDelivered, .pushOpened:
                    Exponea.logger.log(
                        .verbose,
                        message: "[InApp] Event type - \(type)"
                    )
                    await self.startIdentifyCustomerFlow(for: event, isFetchDisabled: true)
                default:
                    Exponea.logger.log(
                        .verbose,
                        message: "[InApp] Event type - \(type)"
                    )
                    await self.startIdentifyCustomerFlow(for: event, isFromIdentifyCustomer: type == .identifyCustomer, triggerCompletion: triggerCompletion)
                }
            }
        }
    }
}

public protocol InAppMessageActionDelegate: AnyObject {
    var overrideDefaultBehavior: Bool { get }
    var trackActions: Bool { get }

    func inAppMessageShown(message: InAppMessage)
    func inAppMessageError(message: InAppMessage?, errorMessage: String)
    func inAppMessageClickAction(message: InAppMessage, button: InAppMessageButton)
    func inAppMessageCloseAction(message: InAppMessage, button: InAppMessageButton?, interaction: Bool)
}

public struct InAppMessageButton: Codable {
    public let text: String?
    public let url: String?
}

public class DefaultInAppDelegate: InAppMessageActionDelegate {
    public let overrideDefaultBehavior = false
    public let trackActions = true

    public func inAppMessageShown(message: InAppMessage) {}
    public func inAppMessageError(message: InAppMessage?, errorMessage: String) {}
    public func inAppMessageClickAction(message: InAppMessage, button: InAppMessageButton) {}
    public func inAppMessageCloseAction(message: InAppMessage, button: InAppMessageButton?, interaction: Bool) {}
}

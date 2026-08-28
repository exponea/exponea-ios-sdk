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

/// Serial FIFO pipeline for async identify / IAM work. `enqueue` appends synchronously on the
/// caller's thread; a single consumer drains items one at a time in submission order.
final class IdentifyFlowWorkQueue {
    private let continuation: AsyncStream<() async -> Void>.Continuation
    private let processingTask: Task<Void, Never>

    init() {
        let (stream, continuation) = AsyncStream.makeStream(of: (() async -> Void).self)
        self.continuation = continuation
        self.processingTask = Task {
            for await work in stream {
                await work()
            }
        }
    }

    deinit {
        continuation.finish()
        processingTask.cancel()
    }

    func enqueue(_ work: @escaping () async -> Void) {
        continuation.yield(work)
    }
}

/// Owns deferred session_start replay state.
/// Compound invariants (e.g. claim-and-clear pending payload) are atomic within the actor.
private actor IdentifyFlowState {
    private var pendingBackgroundSessionStart: [DataType]?
    private var sessionStartReplayCompleted = false
    private var isReplayedSessionStartFlow = false
    private var isIdentifyFlowInProcess = false

    func storePendingSessionStart(_ event: [DataType]) {
        sessionStartReplayCompleted = false
        pendingBackgroundSessionStart = event
    }

    func claimPendingSessionStart() -> [DataType]? {
        defer { pendingBackgroundSessionStart = nil }
        return pendingBackgroundSessionStart
    }

    func clearReplaySlots() {
        pendingBackgroundSessionStart = nil
    }

    func clearReplayState() {
        pendingBackgroundSessionStart = nil
        sessionStartReplayCompleted = false
    }

    func markReplayFinished() {
        sessionStartReplayCompleted = true
    }

    func resetReplayDedupeOnBackground() {
        sessionStartReplayCompleted = false
    }

    func setReplayInProgress(_ value: Bool) {
        isReplayedSessionStartFlow = value
    }

    func isReplayInProgress() -> Bool {
        isReplayedSessionStartFlow
    }

    func setIdentifyInProcess(_ value: Bool) {
        isIdentifyFlowInProcess = value
    }

    func identifyInProcess() -> Bool {
        isIdentifyFlowInProcess
    }

    func pendingSessionStart() -> [DataType]? {
        pendingBackgroundSessionStart
    }

    func restorePendingSessionStart(_ event: [DataType]) {
        pendingBackgroundSessionStart = event
    }

    /// Returns true when a foreground session_start should be skipped after a successful replay dedupe.
    func consumeSessionStartReplayDedupeIfNeeded() -> Bool {
        guard sessionStartReplayCompleted else { return false }
        sessionStartReplayCompleted = false
        pendingBackgroundSessionStart = nil
        return true
    }
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
    private static let refreshCacheAfter: TimeInterval = 60 * 30 // refresh on session start if cache is older than this
    private static let maxPendingMessageAge: TimeInterval = 3 // time window to show pending message after preloading
    @Atomic internal var pendingShowRequests: [String: InAppMessageShowRequest] = [:]
    private let flowState = IdentifyFlowState()
    private let identifyFlowWorkQueue = IdentifyFlowWorkQueue()

    /// Runs async identify / IAM work serially: one operation at a time, in submission order,
    /// without blocking any thread while waiting for each to finish.
    private func enqueueIdentifyFlowWork(_ work: @escaping () async -> Void) {
        identifyFlowWorkQueue.enqueue(work)
    }

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
            self.enqueueIdentifyFlowWork { [weak self] in
                await self?.flowState.clearReplayState()
            }
            self.cache.clear()
            self.displayStatusStore.clear()
        }
    }

    private func isSessionStartEvent(_ event: [DataType]) -> Bool {
        event.eventTypes.contains(EventType.sessionStart.rawValue)
            || event.eventTypes.contains(Constants.EventTypes.sessionStart)
    }

    private func eventCustomerIdsMatchForInApp(event: [DataType], current: [String: String]) -> Bool {
        let stored = event.customerIds
        // Production session_start payloads always include customerIds. An empty stored snapshot
        // means there is nothing to compare, so treat as incompatible to avoid replaying a
        // deferred session_start after an unrelated identify.
        guard !stored.isEmpty else { return false }
        for (key, value) in stored {
            guard current[key] == value else { return false }
        }
        return true
    }

    private func hydratedSessionStartEvent(from stored: [DataType]) -> [DataType] {
        let currentIds = Exponea.shared.trackingManager?.customerIds ?? stored.customerIds
        return stored.withCustomerIds(currentIds)
    }

    private func replayPendingSessionStart(stored: [DataType]) async {
        let hydrated = hydratedSessionStartEvent(from: stored)
        Exponea.logger.log(
            .verbose,
            message: "[InApp] Replaying skipped session_start in-app message processing"
        )
        await flowState.setReplayInProgress(true)
        await startIdentifyCustomerFlow(for: hydrated)
        await flowState.setReplayInProgress(false)
    }

    private func replaySkippedSessionStartIfForeground() async {
        guard Exponea.shared.isAppForeground else { return }
        guard let stored = await flowState.claimPendingSessionStart() else { return }
        await replayPendingSessionStart(stored: stored)
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
        enqueueIdentifyFlowWork { [weak self] in
            guard let self else { return }
            await self.flowState.clearReplayState()
            if let cookie = Exponea.shared.trackingManager?.customerIds {
                await self.startIdentifyCustomerFlow(for: [.customerIds(cookie)], isAnonymized: true)
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
            guard let self else {
                continuation.resume()
                return
            }
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
                    continuation.resume()
                    return
                }
                imageData = createdImageData
            }
            if !(message.oldPayload?.imageUrl ?? "").isEmpty {
                guard let createdImageData = self.getImageData(for: message) else {
                    callback?(nil)
                    continuation.resume()
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
            eventWithType: .inappMessageShown,
            properties: [
                "type": message.rawMessageType ?? "",
                "isRichStyle": message.isRichText.description,
                "messageId": message.id
            ]
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

    private func processMessages(_ inAppMessages: [InAppMessage]) async -> [InAppMessage] {
        var output: [InAppMessage] = []
        for message in inAppMessages {
            var copy = message
            preloadImage(for: copy)
            if let titleConfig = copy.payload?.titleConfig,
               let customFont = titleConfig.customFont {
                copy.payload?.titleFontData = await extractFont(url: customFont, fontSize: nil, size: titleConfig.size)
            }
            if let bodyConfig = copy.payload?.bodyConfig,
               let customFont = bodyConfig.customFont {
                copy.payload?.bodyFontData = await extractFont(url: customFont, fontSize: nil, size: bodyConfig.size)
            }
            let buttons = copy.payload?.buttons ?? []
            var updatedButtons: [InAppButtonPayload] = []
            for button in buttons {
                var copyButton = button
                if let buttonConfig = copyButton.buttonConfig,
                   let customFont = buttonConfig.fontURL {
                    copyButton.fontData = await extractFont(url: customFont, fontSize: nil, size: CGFloat(buttonConfig.size))
                }
                updatedButtons.append(copyButton)
            }
            copy.payload?.buttons = updatedButtons
            output.append(copy)
        }
        return output
    }

    private func fetchImagesAndFonts(inAppMessages: [InAppMessage]) async -> [InAppMessage] {
        await withCheckedContinuation { [weak self] continuation in
            guard let self else {
                continuation.resume(returning: [])
                return
            }
            Task(priority: .background) {
                let result: [InAppMessage] = await self.processMessages(inAppMessages)
                await MainActor.run {
                    continuation.resume(returning: result)
                }
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
            self.trackTelemetry(response.data ?? [])
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
            guard let self else {
                continuation.resume(throwing: InAppMessageError.fetchInAppMessagesFailed)
                return
            }
            DispatchQueue.global(qos: .userInitiated).async {
                self.repository.fetchInAppMessages(for: event.customerIds) { result in
                    Task {
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
                                    self.trackTelemetry(messages)
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

    private func trackTelemetry(_ messages: [InAppMessage]) {
        Exponea.shared.telemetryManager?.report(
            eventWithType: .inappMessageFetch,
            properties: [
                "count": String(messages.count),
                "data": TelemetryUtility.toJson(messages.map { [
                    "type": $0.rawMessageType ?? "",
                    "isRichStyle": $0.isRichText.description,
                    "messageId": $0.id
                ] })
            ]
        )
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
            if isSessionStartEvent(event) {
                await flowState.storePendingSessionStart(event)
                // Foreground may flip before this queued operation runs (TOCTOU).
                if Exponea.shared.isAppForeground, let stored = await flowState.claimPendingSessionStart() {
                    await replayPendingSessionStart(stored: stored)
                }
            }
            return
        }
        // After a replayed background session_start succeeds, ignore another foreground session_start
        // in the same active stint (tracking often emits session_start again on foreground). The flag is
        // cleared on applicationDidEnterBackground so a later session_start after background is still processed.
        if isSessionStartEvent(event), await flowState.consumeSessionStartReplayDedupeIfNeeded() {
            return
        }
        // Past foreground guard — clear any pending replay to prevent double-show
        if isSessionStartEvent(event) {
            await flowState.clearReplaySlots()
        }
        // Should reload or identify customer
        switch true {
        case isFromIdentifyCustomer:
            Exponea.logger.log(
                .verbose,
                message: "[InApp] Identify customer in progress"
            )
            _pendingShowRequests.changeValue(with: { $0.removeAll() })
            if let pending = await flowState.pendingSessionStart(),
               !eventCustomerIdsMatchForInApp(event: pending, current: event.customerIds) {
                await flowState.clearReplayState()
            }
            clearImagesAndFonts()
            await flowState.setIdentifyInProcess(true)
            await isFlushDone()
            await addToPendingShowRequest(event: event)
            if triggerCompletion != nil {
                await flowState.setIdentifyInProcess(false)
                triggerCompletion?(.identifyFetch)
            }
            guard Exponea.shared.isAppForeground else {
                // The app backgrounded before the fetch could run. Without this reset,
                // isIdentifyFlowInProcess stays stuck true, which incorrectly gates the
                // message-loading logic for every subsequent event, not only replayed ones.
                await flowState.setIdentifyInProcess(false)
                return
            }
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
            // Clear on the serial path so subsequent FIFO work sees a consistent flag
            // (do not rely on fire-and-forget Tasks from GCD completion handlers).
            await flowState.setIdentifyInProcess(false)
            await replaySkippedSessionStartIfForeground()
        case isAnonymized:
            Exponea.logger.log(
                .verbose,
                message: "[InApp] Fetch in app messages, because 'isAnonymized'"
            )
            _pendingShowRequests.changeValue(with: { $0.removeAll() })
            await flowState.clearReplayState()
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
                if await flowState.isReplayInProgress(), isSessionStartEvent(event) {
                    await flowState.markReplayFinished()
                }
            } catch {
                Exponea.logger.log(
                    .error,
                    message: "[InApp] fetchInAppMessages error \(error)"
                )
                // Claim already cleared pending; restore so a later become-active can retry.
                if await flowState.isReplayInProgress(), isSessionStartEvent(event) {
                    await flowState.restorePendingSessionStart(event)
                }
            }
            // For test purposes. Initialized only inside test
            if triggerCompletion != nil {
                sessionStartDate = Date().addingTimeInterval(-Date().timeIntervalSince1970)
                await flowState.setIdentifyInProcess(false)
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
            if !(await flowState.identifyInProcess()) {
                Exponea.logger.log(
                    .verbose,
                    message: "[InApp] ShoulReload is false. Just load messages'"
                )
                do {
                    let message = try await loadMessageIfNeeded(event: event)
                    await showInAppMessage(message)
                    if await flowState.isReplayInProgress(), isSessionStartEvent(event) {
                        await flowState.markReplayFinished()
                    }
                } catch {
                    Exponea.logger.log(
                        .error,
                        message: "[InApp] loadMessageIfNeeded error \(error)"
                    )
                    // Claim already cleared pending; restore so a later become-active can retry.
                    if await flowState.isReplayInProgress(), isSessionStartEvent(event) {
                        await flowState.restorePendingSessionStart(event)
                    }
                }

                // For test purposes. Initialized only inside test
                if triggerCompletion != nil {
                    await flowState.setIdentifyInProcess(false)
                    triggerCompletion?(.storedFetch)
                }
            } else if await flowState.isReplayInProgress(), isSessionStartEvent(event) {
                // Identify is still in progress, so no fetch/show was attempted for this replay.
                // Restore the pending event instead of marking the replay finished, so it is
                // retried once the in-progress identify flow completes (see the
                // replaySkippedSessionStartIfForeground() call at the end of the
                // isFromIdentifyCustomer case above).
                await flowState.restorePendingSessionStart(event)
            }
        }
    }

    private func loadMessageIfNeeded(event: [DataType]) async throws -> InAppMessage {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self else {
                continuation.resume(throwing: InAppMessageError.fetchInAppMessagesFailed)
                return
            }
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
        messages = messagesWithImage.filter { $0.priority ?? 0 >= highestPriority }
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
        enqueueIdentifyFlowWork { [weak self] in
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
                await self.startIdentifyCustomerFlow(
                    for: event,
                    isFromIdentifyCustomer: type == .identifyCustomer,
                    triggerCompletion: triggerCompletion
                )
            }
        }
    }

    func applicationDidBecomeActive() {
        enqueueIdentifyFlowWork { [weak self] in
            guard let self else { return }
            await self.replaySkippedSessionStartIfForeground()
        }
    }

    func applicationDidEnterBackground() {
        enqueueIdentifyFlowWork { [weak self] in
            await self?.flowState.resetReplayDedupeOnBackground()
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

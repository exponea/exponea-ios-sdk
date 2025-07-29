//
//  InAppContentBlocksManager.swift
//  ExponeaSDK
//
//  Created by Ankmara on 17.05.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation
import AppTrackingTransparency
import WebKit
#if canImport(ExponeaSDKShared)
import ExponeaSDKShared
#endif

final class InAppContentBlocksManager: NSObject {

    // MARK: - Properties
    static let manager = InAppContentBlocksManager()
    @Atomic var inAppContentBlockMessages: [InAppContentBlockResponse] = []
    var refreshCallback: TypeBlock<IndexPath>?
    let urlOpener: UrlOpenerType = UrlOpener()
    let disableZoomSource: String =
    """
        var meta = document.createElement('meta');
        meta.name = 'viewport';
        meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
        var head = document.getElementsByTagName('head')[0];
        head.appendChild(meta);
    """
    let blockRules =
    """
        [{
            "trigger": {
                "url-filter": ".*",
                "resource-type": []
            },
            "action": {
                "type": "block"
            }
        }]
    """
    var contentRuleList: WKContentRuleList?

    private var isStaticUpdating = false
    private var isUpdating = false
    private var isLoadUpdating = false
    private var isCarouselLoading = false
    @Atomic private var queue: [QueueData] = []
    @Atomic private var loadQueue: [QueueLoadData] = []
    @Atomic private var staticQueue: [StaticQueueData] = []
    @Atomic private var carouselQueue: [String] = []

    private var newUsedInAppContentBlocks: UsedInAppContentBlocks? {
        willSet {
            guard let newValue, let placeholder = newValue.placeholderData else { return }
            if placeholder.content == nil, newValue.height == 0 {
                loadContentForPlacehoder(newValue: newValue, message: placeholder)
            } else if let html = placeholder.content?.html, newValue.height == 0 {
                calculator = .init()
                calculator.heightUpdate = { [weak self] height in
                    guard let self else { return }
                    self.calculateStaticData(height: height, newValue: newValue, placeholder: placeholder)
                }
                calculator.loadHtml(placedholderId: newValue.messageId, html: html)
            }
        }
    }
    @Atomic private var usedInAppContentBlocks: [String: [UsedInAppContentBlocks]] = [:]
    private let sessionStart = Date()
    private let provider: InAppContentBlocksDataProviderType

    // MARK: - Init
    override init() {
        self.provider = InAppContentBlocksDataProvider()
        super.init()
        
        _usedInAppContentBlocks.changeValue(with: { $0.removeAll() })

        IntegrationManager.shared.onIntegrationStoppedCallbacks.append { [weak self] in
            guard let self else { return }
            self.usedInAppContentBlocks.forEach { key, value in
                let content = self.usedInAppContentBlocks[key] ?? []
                let updatedMessages = content.map { content in
                    var copy = content
                    copy.height = 0
                    return copy
                }
                self.usedInAppContentBlocks[key] = updatedMessages
            }
            self._inAppContentBlockMessages.changeValue(with: { $0.removeAll() })
            self.usedInAppContentBlocks.removeAll()
        }
    }

    internal func addMessage(_ message: InAppContentBlockResponse) {
        inAppContentBlockMessages.append(message)
    }

    func initBlocker() {
        onMain {
            WKContentRuleListStore.default().compileContentRuleList(
                forIdentifier: "ContentBlockingRules",
                encodedContentRuleList: self.blockRules
            ) { contentRuleList, error in
                guard error == nil else { return }
                self.contentRuleList = contentRuleList
            }
        }
    }

    private var key: String = "key_WKWebView"
    private var web: WKWebView {
        get {
            objc_getAssociatedObject(self, &key) as! WKWebView
        }
        set {
            let userScript: WKUserScript = .init(source: disableZoomSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            let newWebview = newValue
            newValue.frame = .init(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 0)
            newWebview.scrollView.showsVerticalScrollIndicator = false
            newWebview.scrollView.bounces = false
            newWebview.backgroundColor = .clear
            newWebview.isOpaque = false
            let configuration = newWebview.configuration
            configuration.userContentController.addUserScript(userScript)
            if let contentRuleList {
                configuration.userContentController.add(contentRuleList)
            }
            objc_setAssociatedObject(self, &key, newWebview, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    private var calculatorKey: String = "key_calculator"
    var calculator: WKWebViewHeightCalculator {
        get {
            objc_getAssociatedObject(self, &calculatorKey) as! WKWebViewHeightCalculator
        }
        set {
            objc_setAssociatedObject(self, &calculatorKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}

struct WKWebViewData {
    let height: CGFloat
    let tag: Int
}

// MARK: InAppContentBlocksManagerType
extension InAppContentBlocksManager: InAppContentBlocksManagerType, WKNavigationDelegate {    
    func hasHtmlImages(html: String) -> Bool {
        let collectImages = HtmlNormalizer(html).collectImages()
        guard !collectImages.isEmpty else { return true }
        let isAnyCorrectImage = !collectImages.map { $0 }
            .compactMap { URL(string: $0) }
            .compactMap { try? Data(contentsOf: $0) }
            .compactMap { UIImage(data: $0) }
            .isEmpty
        if !isAnyCorrectImage {
            Exponea.logger.log(.warning, message: "No correct images inside \(html)")
        }
        return isAnyCorrectImage
    }

    func getUsedInAppContentBlocks(placeholder: String, indexPath: IndexPath) -> UsedInAppContentBlocks? {
        return usedInAppContentBlocks[placeholder]?.first(where: { $0.indexPath == indexPath && $0.isActive })
    }

    func anonymize() {
        usedInAppContentBlocks.removeAll()
        inAppContentBlockMessages.removeAll()
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        let webviewtag = webView.tag
        var selectedUsed: UsedInAppContentBlocks?
        for message in inAppContentBlockMessages where message.tags?.contains(webviewtag) == true {
            for placeholder in message.placeholders {
                if let used = usedInAppContentBlocks[placeholder], let selected = used.first(where: { $0.isActive && $0.messageId == message.id }) {
                    selectedUsed = selected
                    break
                }
            }
        }
        guard let selectedUsed, let inAppContentBlockResponse = inAppContentBlockMessages.first(where: { $0.id == selectedUsed.messageId }) else {
            decisionHandler(.cancel)
            return
        }
        let webAction: WebActionManager = .init { _ in
            self.updateInteractedState(for: selectedUsed.messageId)
            Exponea.shared.trackInAppContentBlockClose(
                placeholderId: selectedUsed.placeholder,
                message: inAppContentBlockResponse
            )
            self.refreshCallback?(selectedUsed.indexPath)
        } onActionCallback: { action in
            let inAppCbAction = InAppContentBlockAction(
                name: action.buttonText,
                url: action.actionUrl,
                type: self.determineActionType(action: action)
            )
            self.updateInteractedState(for: selectedUsed.messageId)
            Exponea.shared.trackInAppContentBlockClick(
                placeholderId: selectedUsed.placeholder,
                action: inAppCbAction,
                message: inAppContentBlockResponse
            )
            self.invokeActionInternally(inAppCbAction)
            self.refreshCallback?(selectedUsed.indexPath)
        } onErrorCallback: { error in
            let errorMessage = "WebActionManager error \(error.localizedDescription)"
            Exponea.logger.log(.error, message: errorMessage)
            Exponea.shared.trackInAppContentBlockError(
                placeholderId: selectedUsed.placeholder,
                message: inAppContentBlockResponse,
                errorMessage: errorMessage
            )
        }
        webAction.htmlPayload = inAppContentBlockResponse.normalizedResult ?? inAppContentBlockResponse.personalizedMessage?.htmlPayload
        let handled = webAction.handleActionClick(navigationAction.request.url)
        if handled {
            Exponea.logger.log(.verbose, message: "[HTML] Action \(navigationAction.request.url?.absoluteString ?? "Invalid") has been handled")
            decisionHandler(.cancel)
        } else {
            Exponea.logger.log(.verbose, message: "[HTML] Action \(navigationAction.request.url?.absoluteString ?? "Invalid") has not been handled, continue")
            decisionHandler(.allow)
        }
    }
    
    private func invokeActionInternally(_ action: InAppContentBlockAction) {
        switch action.type {
        case .browser:
            openBrowserAction(action)
        case .deeplink:
            openDeeplinkAction(action)
        default:
            Exponea.logger.log(.warning, message: "No AppInbox action for type \(action.type)")
        }
    }

    func openBrowserAction(_ action: InAppContentBlockAction) {
        guard let buttonLink = action.url else {
            Exponea.logger.log(.error, message: "AppInbox action \"\(action.name ?? "<nil>")\" contains invalid browser link \(action.url ?? "<nil>")")
            return
        }
        urlOpener.openBrowserLink(buttonLink)
    }

    func openDeeplinkAction(_ action: InAppContentBlockAction) {
        guard let buttonLink = action.url else {
            Exponea.logger.log(.error, message: "AppInbox action \"\(action.name ?? "<nil>")\" contains invalid universal link \(action.url ?? "<nil>")")
            return
        }
        urlOpener.openDeeplink(buttonLink)
    }

    private func determineActionType(action: ActionInfo) -> InAppContentBlockActionType {
        switch action.actionType {
        case .browser:
            return .browser
        case .deeplink:
            return .deeplink
        case .close:
            return .close
        }
    }

    private func parseData(placeholderId: String, data: ResponseData<PersonalizedInAppContentBlockResponseData>, tags: Set<Int>, completion: EmptyBlock?) {
        ensureBackground {
            let personalizedWithPayload: [PersonalizedInAppContentBlockResponse] = data.data?.data.compactMap { response in
                var newInAppContentBlocks = response
                let normalizeConf = HtmlNormalizerConfig(
                    makeResourcesOffline: true,
                    ensureCloseButton: false
                )
                let normalizedPayload = HtmlNormalizer(newInAppContentBlocks.content?.html ?? "").normalize(normalizeConf)
                newInAppContentBlocks.htmlPayload = normalizedPayload
                let isCorruptedImage = !self.hasHtmlImages(html: response.content?.html ?? "")
                newInAppContentBlocks.isCorruptedImage = isCorruptedImage
                return newInAppContentBlocks
            } ?? []
            var updatedPlaceholders: [InAppContentBlockResponse] = self.inAppContentBlockMessages
            var updatedContentBlocksForTelemetry: [InAppContentBlockResponse] = []
            for (index, inAppContentBlocks) in updatedPlaceholders.enumerated() {
                if var personalized = personalizedWithPayload.first(where: { $0.id == inAppContentBlocks.id }) {
                    personalized.ttlSeen = Date()
                    updatedPlaceholders[index].personalizedMessage = personalized
                    updatedContentBlocksForTelemetry.append(updatedPlaceholders[index])
                }
            }
            self.inAppContentBlockMessages = updatedPlaceholders
            self.trackTelemetryForFetch(.contentBlockPersonalisedFetch, updatedContentBlocksForTelemetry)
            onMain {
                completion?()
            }
        }
    }
    
    private func trackTelemetryForFetch(_ fetchType: TelemetryEventType, _ info: [InAppContentBlockResponse]) {
        Exponea.shared.telemetryManager?.report(
            eventWithType: fetchType,
            properties: [
                "count": String(info.count),
                "data": TelemetryUtility.toJson(info.map { [
                    "messageId": $0.id,
                    "placeholders": TelemetryUtility.toJson($0.placeholders),
                    "type": ($0.content == nil ? "personal" : "static")
                ] })
            ]
        )
    }

    func prefetchPlaceholdersWithIds(input: [InAppContentBlockResponse], ids: [String]) -> [InAppContentBlockResponse] {
        input.filter { inAppContentBlocks in
            !inAppContentBlocks.placeholders.filter { placeholder in
                ids.contains(placeholder)
            }.isEmpty
        }
    }

    func prefetchPlaceholdersWithIds(ids: [String]) {
        Exponea.logger.log(.verbose, message: "In-app Content Blocks prefetch starts.")
        guard let customerIds = try? DatabaseManager().currentCustomer.ids, !ids.isEmpty else {
            Exponea.logger.log(.verbose, message: "In-app Content Blocks prefetch starts failed due to customer ids or ids are empty")
            return
        }
        Exponea.logger.log(.verbose, message: "In-app Content Blocks prefetch ids \(ids)")
        provider.loadPersonalizedInAppContentBlocks(
            data: PersonalizedInAppContentBlockResponseData.self,
            customerIds: customerIds,
            inAppContentBlocksIds: prefetchPlaceholdersWithIds(input: inAppContentBlockMessages, ids: ids).map { $0.id }
        ) { [weak self] messages in
            guard let self else { return }
            ensureBackground {
                let prefetchedMessagesDescriptions = (messages.data?.data ?? []).map { $0.describeDetailed() }
                Exponea.logger.log(.verbose, message: "In-app Content Blocks downloaded prefetched messages \(prefetchedMessagesDescriptions)")
                let personalizedWithPayload: [PersonalizedInAppContentBlockResponse]? = messages.data?.data.filter { $0.status == .ok }.compactMap { response in
                    var newInAppContentBlocks = response
                    let normalizeConf = HtmlNormalizerConfig(
                        makeResourcesOffline: false,
                        ensureCloseButton: false
                    )
                    let normalizedPayload = HtmlNormalizer(newInAppContentBlocks.content?.html ?? "").normalize(normalizeConf)
                    newInAppContentBlocks.htmlPayload = normalizedPayload
                    let isCorruptedImage = !self.hasHtmlImages(html: response.content?.html ?? "")
                    newInAppContentBlocks.isCorruptedImage = isCorruptedImage
                    return newInAppContentBlocks
                }
                var updatedPlaceholders: [InAppContentBlockResponse] = self.inAppContentBlockMessages
                var updatedContentBlocksForTelemetry: [InAppContentBlockResponse] = []
                for (index, inAppContentBlocks) in updatedPlaceholders.enumerated() {
                    if var personalized = personalizedWithPayload?.first(where: { $0.id == inAppContentBlocks.id }) {
                        personalized.ttlSeen = Date()
                        updatedPlaceholders[index].personalizedMessage = personalized
                        updatedContentBlocksForTelemetry.append(updatedPlaceholders[index])
                    }
                }
                self.inAppContentBlockMessages = updatedPlaceholders
                self.trackTelemetryForFetch(.contentBlockPersonalisedFetch, updatedContentBlocksForTelemetry)
            }
        }
    }

    func getFilteredMessage(message: InAppContentBlockResponse) -> Bool {        
        let displayState = getDisplayState(of: message.id)
        switch message.frequency {
        case .oncePerVisit:
            let shouldDisplay = displayState.displayed == nil
            if !shouldDisplay {
                Exponea.logger.log(.verbose, message: "In-app Content Blocks '\(message.name)' already displayed.")
            }
            return shouldDisplay
        case .onlyOnce:
            let shouldDisplay = displayState.displayed ?? Date(timeIntervalSince1970: 0) < sessionStart
            if !shouldDisplay {
                Exponea.logger.log(.verbose, message: "In-app Content Blocks '\(message.name)' already displayed this session.")
            }
            return shouldDisplay
        case .untilVisitorInteracts:
            let shouldDisplay = displayState.interacted == nil
            Exponea.logger.log(.verbose, message: "shouldDisplay \(shouldDisplay) for id \(message.id)")
            if !shouldDisplay {
                Exponea.logger.log(.verbose, message: "In-app Content Blocks '\(message.name)' already interacted with.")
            }
            return shouldDisplay
        case .always:
            return true
        case .none:
            Exponea.logger.log(.warning, message: "Unknown inAppContentBlocks message frequency.")
            return true
        }
    }

    func filterPriority(input: [InAppContentBlockResponse]) -> [Int: [InAppContentBlockResponse]] {
        var toReturn: [Int: [InAppContentBlockResponse]] = [:]
        for inAppContentBlocks in input {
            let prio = inAppContentBlocks.loadPriority ?? 0
            if toReturn[prio] != nil {
                toReturn[prio]?.append(inAppContentBlocks)
            } else {
                toReturn[prio] = [inAppContentBlocks]
            }
        }
        return toReturn
    }

    private func markAsActive(message: InAppContentBlockResponse, indexPath: IndexPath, placeholderId: String) {
        let usedMessages = usedInAppContentBlocks[placeholderId] ?? []
        var blocksToReturn: [UsedInAppContentBlocks] = []
        for msg in usedMessages {
            var value = msg
            value.isActive = value.messageId == message.id
            if value.isActive {
                value.indexPath = indexPath
            }
            blocksToReturn.append(value)
        }
        Exponea.logger.log(.verbose, message: "In-app Content Blocks markAsActive indexPath: \(indexPath), placeholderId: \(placeholderId).")
        _usedInAppContentBlocks.changeValue(with: { $0[placeholderId] = blocksToReturn })
        Exponea.logger.log(.verbose, message: "In-app Content Blocks updated \(usedInAppContentBlocks.mapValues { $0.map { $0.describeDetailed() } })")
    }

    private func markAsInactive(indexPath: IndexPath, placeholderId: String) {
        let usedMessages = usedInAppContentBlocks[placeholderId] ?? []
        var blocksToReturn: [UsedInAppContentBlocks] = []
        for msg in usedMessages {
            var value = msg
            if value.indexPath == indexPath {
                value.isActive = false
            }
            blocksToReturn.append(value)
        }
        Exponea.logger.log(.verbose, message: "In-app Content Blocks markAsInactive indexPath: \(indexPath), placeholderId: \(placeholderId).")
        _usedInAppContentBlocks.changeValue(with: { $0[placeholderId] = blocksToReturn })
        Exponea.logger.log(.verbose, message: "In-app Content Blocks updated \(usedInAppContentBlocks.mapValues { $0.map { $0.describeDetailed() } })")
    }

    func prepareInAppContentBlockView(placeholderId: String, indexPath: IndexPath) -> UIView {
        guard !IntegrationManager.shared.isStopped else {
            Exponea.logger.log(.verbose, message: "In-app content blocks fetch failed: SDK is stopping")
            return .init()
        }
        let messagesToUse = inAppContentBlockMessages.filter { $0.placeholders.contains(placeholderId) }
        let messagesNeedToRefresh = messagesToUse.filter { $0.personalizedMessage == nil && $0.content?.html == nil }
        let expiredMessages = messagesToUse.filter { inAppContentBlocks in
            if let ttlSeen = inAppContentBlocks.personalizedMessage?.ttlSeen,
               let ttl = inAppContentBlocks.personalizedMessage?.ttlSeconds,
               inAppContentBlocks.content == nil {
                return Date() > ttlSeen.addingTimeInterval(TimeInterval(ttl))
            }
            return false
        }
        guard messagesNeedToRefresh.isEmpty && expiredMessages.isEmpty else {
            Exponea.logger.log(.verbose, message: "Loading content for In-app Content Block with placeholder: \(placeholderId) and indxPath \(indexPath)")
            markAsInactive(indexPath: indexPath, placeholderId: placeholderId)
            loadContent(indexPath: indexPath, placeholder: placeholderId, expired: expiredMessages)
            return returnEmptyView(tag: Int.random(in: 0..<99999999))
        }
        let contentBlocksForId = usedInAppContentBlocks[placeholderId] ?? []
        let messagesForThisIndexPath = contentBlocksForId.filter { $0.indexPath == indexPath }
        var messagesToFilter: [InAppContentBlockResponse] = []
        for message in inAppContentBlockMessages where contentBlocksForId.contains(where: { $0.messageId == message.id }) {
            messagesToFilter.append(message)
        }
        guard let message = filterPersonalizedMessages(input: messagesToFilter) else {
            Exponea.logger.log(.verbose, message: "No more In-app Content Block messages for indexPath  \(indexPath)")
            markAsInactive(indexPath: indexPath, placeholderId: placeholderId)
            return returnEmptyView(tag: Int.random(in: 0..<99999999))
        }
        Exponea.logger.log(.verbose, message: "Filtered In-app Content Block \(message.describe())")
        markAsActive(message: message, indexPath: indexPath, placeholderId: placeholderId)
        let tag = createUniqueTag(placeholder: message)
        let indexOfPlaceholder: Int = inAppContentBlockMessages.firstIndex(where: { $0.indexPath == message.indexPath }) ?? 0
        updateDisplayedState(for: message.id)

        web = .init()
        web.tag = tag
        web.navigationDelegate = self

        if let html = message.content?.html, !html.isEmpty {
            Exponea.logger.log(
                .verbose,
                message: "In-app Content Block prepareInAppContentBlockView for \(message.describe())"
            )
            if inAppContentBlockMessages[indexOfPlaceholder].normalizedResult == nil {
                let normalizeConf = HtmlNormalizerConfig(
                    makeResourcesOffline: true,
                    ensureCloseButton: false
                )
                Exponea.logger.log(.verbose, message: "In-app Content Block prepareInAppContentBlockView normalizeConf \(normalizeConf)")
                let normalizedPayload = HtmlNormalizer(html).normalize(normalizeConf)
                Exponea.logger.log(
                    .verbose,
                    message: "In-app Content Block prepareInAppContentBlockView normalizedPayload is valid: \(normalizedPayload.valid)"
                )
                inAppContentBlockMessages[indexOfPlaceholder].normalizedResult = normalizedPayload
            }
            let finalHTML = inAppContentBlockMessages[indexOfPlaceholder].normalizedResult?.html ?? html
            if inAppContentBlockMessages[indexOfPlaceholder].personalizedMessage?.ttlSeen == nil {
                _inAppContentBlockMessages.changeValue(with: { $0[indexOfPlaceholder].personalizedMessage?.ttlSeen = Date() })
            }
            web.loadHTMLString(finalHTML, baseURL: nil)
            return web
        } else if let personalized = message.personalizedMessage, let payloadData = personalized.htmlPayload?.html?.data(using: .utf8), !payloadData.isEmpty {
            if inAppContentBlockMessages[indexOfPlaceholder].personalizedMessage?.ttlSeen == nil {
                _inAppContentBlockMessages.changeValue(with: { $0[indexOfPlaceholder].personalizedMessage?.ttlSeen = Date() })
            }
            if let html = personalized.htmlPayload?.html, !html.isEmpty {
                web.loadHTMLString(html, baseURL: nil)
                return web
            } else {
                return returnEmptyView(tag: tag)
            }
        } else {
            return returnEmptyView(tag: tag)
        }
    }

    func filterCarouselData(placeholder: String, continueCallback: TypeBlock<[InAppContentBlockResponse]>?, expiredCompletion: EmptyBlock?) {
        let placehodlersToUse = inAppContentBlockMessages.filter { !$0.placeholders.filter { $0 == placeholder }.isEmpty }
        let placeholdersNeedToRefresh = placehodlersToUse.filter { $0.personalizedMessage == nil && $0.content?.html == nil }
        let expiredMessages = inAppContentBlockMessages.filter { inAppContentBlocks in
            if let ttlSeen = inAppContentBlocks.personalizedMessage?.ttlSeen,
               let ttl = inAppContentBlocks.personalizedMessage?.ttlSeconds {
                return Date() > ttlSeen.addingTimeInterval(TimeInterval(ttl))
            }
            return false
        }
        let notFoundPersonalizedMessages = inAppContentBlockMessages.filter { inAppContentBlocks in
            inAppContentBlocks.personalizedMessage == nil
        }
        let expiredMessagesDescriptions = expiredMessages.map { $0.describe() }
        Exponea.logger.log(
            .verbose,
            message: "In-app Content Blocks prepareInAppContentBlocksStaticView expiredMessages \(expiredMessagesDescriptions)."
        )
        if expiredMessages.isEmpty && !notFoundPersonalizedMessages.isEmpty && placehodlersToUse.isEmpty {
            continueCallback?([])
            return
        }
        guard placeholdersNeedToRefresh.isEmpty && expiredMessages.isEmpty else {
            expiredCompletion?()
            return
        }
        let filtered = placehodlersToUse.filter { inAppContentBlocksPlaceholder in
            if inAppContentBlocksPlaceholder.personalizedMessage?.status == .ok && inAppContentBlocksPlaceholder.personalizedMessage?.isCorruptedImage == false {
                return self.getFilteredMessage(message: inAppContentBlocksPlaceholder)
            } else {
                return false
            }
        }
        Exponea.logger.log(
            .verbose,
            message: "In-app Content Blocks filtering result: \(filtered.map { $0.describe() })"
        )
        guard !filtered.isEmpty else {
            expiredCompletion?()
            return
        }
        continueCallback?(filtered)
    }

    func prepareInAppContentBlocksStaticView(
        placeholderId: String
    ) -> StaticReturnData {
        let placehodlersToUse = inAppContentBlockMessages.filter { !$0.placeholders.filter { $0 == placeholderId }.isEmpty }
        let placeholdersNeedToRefresh = placehodlersToUse.filter { $0.personalizedMessage == nil && $0.content?.html == nil }
        let expiredMessages = placehodlersToUse.filter { inAppContentBlocks in
            if let ttlSeen = inAppContentBlocks.personalizedMessage?.ttlSeen,
               let ttl = inAppContentBlocks.personalizedMessage?.ttlSeconds,
               inAppContentBlocks.content == nil {
                return Date() > ttlSeen.addingTimeInterval(TimeInterval(ttl))
            }
            return false
        }
        let expiredMessagesDescriptions = expiredMessages.map { $0.describe() }
        Exponea.logger.log(
            .verbose,
            message: "In-app Content Blocks prepareInAppContentBlocksStaticView expiredMessages \(expiredMessagesDescriptions)."
        )
        guard placeholdersNeedToRefresh.isEmpty && expiredMessages.isEmpty else {
            return .init(html: "", tag: 0, message: nil)
        }

        // Found message
        guard var message = filterPersonalizedMessages(input: placehodlersToUse.filter { $0.personalizedMessage?.status == .ok }) else {
            Exponea.logger.log(.verbose, message: "In-app Content Blocks prepareInAppContentBlocksStaticView message not found.")
            return .init(html: "", tag: 0, message: nil)
        }
        Exponea.logger.log(
            .verbose,
            message: "In-app Content Blocks prepareInAppContentBlocksStaticView message \(message.describe())."
        )

        // Add random for 100% unique
        let tag = createUniqueTag(placeholder: message)
        Exponea.logger.log(.verbose, message: "In-app Content Blocks prepareInAppContentBlocksStaticView tag \(tag).")

        // Update display status
        let indexOfPlaceholder: Int = inAppContentBlockMessages.firstIndex(where: { $0.id == message.id }) ?? 0
        updateDisplayedState(for: message.id)
        message.tags?.insert(tag)

        if let personalized = message.personalizedMessage, let payloadData = personalized.htmlPayload?.html?.data(using: .utf8), !payloadData.isEmpty {
            Exponea.logger.log(
                .verbose,
                message: "In-app Content Blocks prepareInAppContentBlocksStaticView personalized \(personalized.describeDetailed())."
            )
            if self.inAppContentBlockMessages[indexOfPlaceholder].personalizedMessage?.ttlSeen == nil {
                _inAppContentBlockMessages.changeValue(with: { $0[indexOfPlaceholder].personalizedMessage?.ttlSeen = Date() })
            }
            if let html = personalized.htmlPayload?.html, !html.isEmpty {
                _inAppContentBlockMessages.changeValue(with: { $0[indexOfPlaceholder] = message })
                return .init(html: html, tag: tag, message: message)
            }
        } else {
            Exponea.logger.log(
                .verbose,
                message: "In-app Content Blocks prepareInAppContentBlocksStaticView static \(message.describe())."
            )
            if let html = message.content?.html, !html.isEmpty {
                _inAppContentBlockMessages.changeValue(with: { $0[indexOfPlaceholder] = message })
                return .init(html: html, tag: tag, message: message)
            }
        }
        return .init(html: "", tag: 0, message: nil)
    }

    func loadInAppContentBlockMessages(completion: EmptyBlock?) {
        provider.getInAppContentBlocks(
            data: InAppContentBlocksDataResponse.self
        ) { [weak self] result in
            guard result.data?.success == true, let messages = result.data?.data else { return }
            ensureBackground {
                let filteredMessages: [InAppContentBlockResponse] = messages.map { message in
                    if let content = message.content?.html {
                        var msg = message
                        msg.isCorruptedImage = self?.hasHtmlImages(html: content) == false
                        return msg
                    }
                    return message
                }
                self?.inAppContentBlockMessages = filteredMessages
                let loadedMessagesDescriptions = (result.data?.data ?? []).map { $0.describe() }
                Exponea.logger.log(
                    .verbose,
                    message: "In-app Content Blocks loadInAppContentBlockMessages done with \(loadedMessagesDescriptions)."
                )
                self?.trackTelemetryForFetch(.contentBlockInitFetch, messages)
                completion?()
            }
        }
    }
}

private extension InAppContentBlocksManager {
    func loadPersonalizedInAppContentBlocks(for placeholderId: String, tags: Set<Int>, skipLoad: Bool = false, completion: EmptyBlock?) {
        Exponea.logger.log(.verbose, message: "In-app Content Blocks loadPersonalizedInAppContentBlocks starts")
        guard !placeholderId.isEmpty, let ids = try? DatabaseManager().currentCustomer.ids else {
            Exponea.logger.log(.verbose, message: "In-app Content Blocks loadPersonalizedInAppContentBlocks failed placeholderId.isEmpty: \(placeholderId.isEmpty) and ids: \(String(describing: try? DatabaseManager().currentCustomer.ids))")
            return
        }
        DispatchQueue.global().async {
            if skipLoad {
                onMain {
                    completion?()
                }
            } else {
                self.provider.loadPersonalizedInAppContentBlocks(
                    data: PersonalizedInAppContentBlockResponseData.self,
                    customerIds: ids,
                    inAppContentBlocksIds: [placeholderId]
                ) { [weak self] data in
                    guard let self else { return }
                    let responseDescribed = """
                        {
                            data: \(String(describing: data.data?.data.map { $0.describeDetailed() })),
                            error: \(String(describing: data.error))
                        }
                        """
                    Exponea.logger.log(
                        .verbose,
                        message: "In-app Content Blocks loadPersonalizedInAppContentBlocks loaded: \(responseDescribed)"
                    )
                    self.parseData(placeholderId: placeholderId, data: data, tags: tags, completion: completion)
                }
            }
        }
    }

    internal func applyDateFilter(message: InAppContentBlockResponse) -> Bool {
        guard message.dateFilter.enabled else {
            return true
        }
        if let start = message.dateFilter.fromDate, start > Date() {
            Exponea.logger.log(.verbose, message: "In-app Content Blocks '\(message.name)' outside of date range.")
            return false
        }
        if let end = message.dateFilter.toDate, end < Date() {
            Exponea.logger.log(.verbose, message: "In-app Content Blocks '\(message.name)' outside of date range.")
            return false
        }
        return true
    }

    func filterPersonalizedMessages(input: [InAppContentBlockResponse]) -> InAppContentBlockResponse? {
        Exponea.logger.log(
            .verbose,
            message: "In-app Content Blocks filterPersonalizedMessages filtering: \(input.map { $0.describe() })"
        )
        let filtered = input
            .filter { applyDateFilter(message: $0) }
            .filter { inAppContentBlocksPlaceholder in
            if inAppContentBlocksPlaceholder.personalizedMessage?.status == .ok && inAppContentBlocksPlaceholder.personalizedMessage?.isCorruptedImage == false {
                return self.getFilteredMessage(message: inAppContentBlocksPlaceholder)
            } else {
                return false
            }
        }
        Exponea.logger.log(
            .verbose,
            message: "In-app Content Blocks filtering result: \(filtered.map { $0.describe() })"
        )
        guard !filtered.isEmpty else {
            return nil
        }
        let sorted = filtered.sorted { lhs, rhs in
            lhs.loadPriority ?? 0 > rhs.loadPriority ?? 0
        }
        let toReturnArray = filterPriority(input: sorted).sorted(by: { $0.key > $1.key })
        let toReturn = toReturnArray.first?.value.randomElement()
        Exponea.logger.log(
            .verbose,
            message: "In-app Content Blocks winner from filtering: \(String(describing: toReturn?.describe()))")
        return toReturn
    }

    func createUniqueTag(placeholder: InAppContentBlockResponse) -> Int {
        if let tags = placeholder.tags?.first {
            return tags
        }
        return Int.random(in: 0..<99999999)
    }

    func returnEmptyView(tag: Int) -> UIView {
        let view = WKWebView(frame: .zero)
        view.tag = tag
        return view
    }

    func returnEmptyStaticView(tag: Int) -> UIView {
        let view = UIView()
        view.tag = tag
        return view
    }

    func loadContent(indexPath: IndexPath, placeholder: String, expired: [InAppContentBlockResponse]) {
        guard let ids = try? DatabaseManager().currentCustomer.ids else {
            Exponea.logger.log(.verbose, message: "In-app Content Blocks loadContent - customer ids not found")
            return
        }
        if !isLoadUpdating {
            isLoadUpdating = true
            let placehodlersToUse = inAppContentBlockMessages.filter { $0.placeholders.contains(placeholder) }
            var placeholdersNeedToGetContent = placehodlersToUse.filter { $0.indexPath == nil || $0.personalizedMessage == nil && $0.content?.html == nil }
            if placeholdersNeedToGetContent.isEmpty && !expired.isEmpty {
                placeholdersNeedToGetContent = expired
            }
            Exponea.logger.log(.verbose, message: "In-app Content Blocks placeholdersNeedToGetContent count \(placeholdersNeedToGetContent.count)")
            Exponea.logger.log(
                .verbose,
                message: "In-app Content Blocks placeholdersNeedToGetContent \(placeholdersNeedToGetContent.map { $0.describe() })"
            )
            Exponea.logger.log(.verbose, message:
                """
                In-app Content Blocks loadContent(indexPath: IndexPath, placeholder: String, expired: [InAppContentBlockResponse])
                indexPath: \(indexPath)
                placeholder: \(placeholder)
                expired: \(expired.map { $0.describe() })
                """
            )
            guard !placeholdersNeedToGetContent.isEmpty else {
                for placeholderInLoop in placehodlersToUse {
                    let tag = createUniqueTag(placeholder: placeholderInLoop)
                    let usedInAppContentBlocksHeight = usedInAppContentBlocks[placeholder]?.first(where: { $0.messageId == placeholderInLoop.id && $0.indexPath == indexPath })?.height ?? 0
                    self.newUsedInAppContentBlocks = .init(tag: tag, indexPath: indexPath, messageId: placeholderInLoop.id, placeholder: placeholder, height: !expired.isEmpty ? 0 : usedInAppContentBlocksHeight, placeholderData: placeholderInLoop)
                }
                isLoadUpdating = false
                if !loadQueue.isEmpty {
                    let go = loadQueue.removeFirst()
                    loadContent(indexPath: go.indexPath, placeholder: go.placeholder, expired: go.expired)
                }
                return
            }
            self.provider.loadPersonalizedInAppContentBlocks(
                data: PersonalizedInAppContentBlockResponseData.self,
                customerIds: ids,
                inAppContentBlocksIds: placeholdersNeedToGetContent.map { $0.id }
            ) { [weak self] data in
                guard let self else { return }
                ensureBackground {
                    let personalizedWithPayload: [PersonalizedInAppContentBlockResponse] = data.data?.data.compactMap { response in
                        var newInAppContentBlocks = response
                        let normalizeConf = HtmlNormalizerConfig(
                            makeResourcesOffline: true,
                            ensureCloseButton: false
                        )
                        let normalizedPayload = HtmlNormalizer(newInAppContentBlocks.content?.html ?? "").normalize(normalizeConf)
                        newInAppContentBlocks.htmlPayload = normalizedPayload
                        let isCorruptedImage = !self.hasHtmlImages(html: response.content?.html ?? "")
                        newInAppContentBlocks.isCorruptedImage = isCorruptedImage
                        return newInAppContentBlocks
                    } ?? []
                    var updatedPlaceholders: [InAppContentBlockResponse] = self.inAppContentBlockMessages
                    for (index, inAppContentBlocks) in updatedPlaceholders.enumerated() {
                        if var personalized = personalizedWithPayload.first(where: { $0.id == inAppContentBlocks.id }) {
                            let tag = self.createUniqueTag(placeholder: inAppContentBlocks)
                            personalized.ttlSeen = Date()
                            updatedPlaceholders[index].personalizedMessage = personalized
                            updatedPlaceholders[index].tags?.insert(tag)
                            updatedPlaceholders[index].indexPath = indexPath
                        }
                    }
                    Exponea.logger.log(
                        .verbose,
                        message: "In-app Content Blocks updatedPlaceholders \(updatedPlaceholders.map { $0.describe() })"
                    )
                    self._inAppContentBlockMessages.changeValue(with: { $0 = updatedPlaceholders })
                    let updatedPlacehodlersToUse = self.inAppContentBlockMessages.filter { $0.placeholders.contains(placeholder) }
                    for placeholderInLoop in updatedPlacehodlersToUse {
                        let tag = self.createUniqueTag(placeholder: placeholderInLoop)
                        let usedInAppContentBlocksHeight = self.usedInAppContentBlocks[placeholder]?.first(where: { $0.messageId == placeholderInLoop.id })?.height ?? 0
                        self.newUsedInAppContentBlocks = .init(tag: tag, indexPath: indexPath, messageId: placeholderInLoop.id, placeholder: placeholder, height: !expired.isEmpty ? 0 : usedInAppContentBlocksHeight, placeholderData: placeholderInLoop)
                    }
                    if !self.loadQueue.isEmpty {
                        self.isLoadUpdating = false
                        let go = self.loadQueue.removeFirst()
                        Exponea.logger.log(
                            .verbose,
                            message: "In-app Content Blocks load content and continue with queue {indexPath:\(go.indexPath), placeholder: \(go.placeholder), expired: \(go.expired.map { $0.describe() })}"
                        )
                        self.loadContent(indexPath: go.indexPath, placeholder: go.placeholder, expired: go.expired)
                    }
                }
            }
        } else {
            Exponea.logger.log(.verbose, message:
                """
                In-app Content Blocks added to queue
                indexPath: \(indexPath)
                placeholder: \(placeholder)
                expired: \(expired.map { $0.describe() })
                """
            )
            _loadQueue.changeValue(with: { $0.append(.init(placeholder: placeholder, indexPath: indexPath, expired: expired)) })
        }
    }

    func calculateStaticData(height: CalculatorData, newValue: UsedInAppContentBlocks, placeholder: InAppContentBlockResponse) {
        let savedNewValue = newValue
        let placeholderValueFromUsedLine = savedNewValue.placeholder
        let savedInAppContentBlocksToDeactived = self.usedInAppContentBlocks[placeholderValueFromUsedLine] ?? []
        Exponea.logger.log(.verbose, message:
            """
            In-app Content Blocks savedInAppContentBlocksToDeactived
            height: \(height)
            newValue: \(newValue.describeDetailed())
            placeholder: \(placeholder.describe())
            """
        )
        guard let indexPath = placeholder.indexPath else { return }
        if savedInAppContentBlocksToDeactived.isEmpty {
            Exponea.logger.log(
                .verbose,
                message: "In-app Content Blocks savedInAppContentBlocksToDeactived are empty. Saved usedInAppContentBlocks \(usedInAppContentBlocks.mapValues { $0.map { $0.describeDetailed() } })"
            )
            self._usedInAppContentBlocks.changeValue { store in
                let newSavedInAppContentBlocks: UsedInAppContentBlocks = .init(tag: savedNewValue.tag, indexPath: indexPath, messageId: savedNewValue.messageId, placeholder: savedNewValue.placeholder, height: height.height)
                if store[placeholderValueFromUsedLine] == nil {
                    store[placeholderValueFromUsedLine] = [newSavedInAppContentBlocks]
                } else if store[placeholderValueFromUsedLine]?.isEmpty == true {
                    store[placeholderValueFromUsedLine]?.append(newSavedInAppContentBlocks)
                }
            }
            self.continueWithQueue()
            self.calculator.heightUpdate = nil
            self.refreshCallback?(savedNewValue.indexPath)
        } else {
            Exponea.logger.log(.verbose, message: "In-app Content Blocks usedInAppContentBlocks \(usedInAppContentBlocks.mapValues { $0.map { $0.describeDetailed() } })")
            if let indexOfSavedInAppContentBlocks: Int = self.usedInAppContentBlocks[placeholderValueFromUsedLine]?.firstIndex(where: { $0.messageId == savedNewValue.messageId && $0.height == 0 }) {
                if var savedInAppContentBlocks = self.usedInAppContentBlocks[placeholderValueFromUsedLine]?[indexOfSavedInAppContentBlocks] {
                    if savedInAppContentBlocks.height == 0 {
                        savedInAppContentBlocks.height = height.height
                    }
                    self._usedInAppContentBlocks.changeValue(with: { $0[placeholderValueFromUsedLine]?.insert(savedInAppContentBlocks, at: indexOfSavedInAppContentBlocks) })
                }
            } else {
                let newSavedInAppContentBlocks: UsedInAppContentBlocks = .init(tag: savedNewValue.tag, indexPath: indexPath, messageId: savedNewValue.messageId, placeholder: savedNewValue.placeholder, height: height.height)
                self._usedInAppContentBlocks.changeValue { store in
                    store[placeholderValueFromUsedLine]?.append(newSavedInAppContentBlocks)
                }
            }
            self.continueWithQueue()
            self.calculator.heightUpdate = nil
            self.refreshCallback?(savedNewValue.indexPath)
        }
    }
}

// Static inAppContentBlocks
extension InAppContentBlocksManager {
    private func continueWithStaticQueue() {
        isStaticUpdating = false
        if !staticQueue.isEmpty {
            let go = staticQueue.removeFirst()
            Exponea.logger.log(.verbose, message: "In-app Content Blocks continueWithStaticQueue \(go)")
            refreshStaticViewContent(staticQueueData: go)
        }
    }

    private func continueWithCarouselQueue(dataCompletion: TypeBlock<[StaticReturnData]>?) {
        isCarouselLoading = false
        if !carouselQueue.isEmpty {
            let go = carouselQueue.removeFirst()
            Exponea.logger.log(.verbose, message: "In-app Content Blocks carousel queue \(go)")
            refreshCarouselData(placeholder: go, dataCompletion: dataCompletion)
        }
    }

    public func isMessageValid(message: InAppContentBlockResponse, isValidCompletion: TypeBlock<Bool>?, refreshCallback: EmptyBlock?) {
        var isMessageExpired = false
        if let ttlSeen = message.personalizedMessage?.ttlSeen,
           let ttl = message.personalizedMessage?.ttlSeconds, message.content == nil {
            isMessageExpired = Date() > ttlSeen.addingTimeInterval(TimeInterval(ttl))
        }
        let isValid = getFilteredMessage(message: message)
        // Just expired - refresh content
        if isMessageExpired && isValid {
            refreshCallback?()
        } else {
            isValidCompletion?(isValid)
        }
    }

    func loadMessagesForCarousel(placeholder: String, completion: EmptyBlock?) {
        guard !placeholder.isEmpty, let ids = try? DatabaseManager().currentCustomer.ids else {
            Exponea.logger.log(.verbose, message: "In-app Content Blocks Carousel cant refresh placeholderId: \(placeholder), ids: \(String(describing: try? DatabaseManager().currentCustomer.ids))")
            return
        }
        let idsForDownload = inAppContentBlockMessages.filter { $0.placeholders.contains(placeholder) }.map { $0.id }
        provider.loadPersonalizedInAppContentBlocks(
            data: PersonalizedInAppContentBlockResponseData.self,
            customerIds: ids,
            inAppContentBlocksIds: idsForDownload
        ) { [weak self] data in
            guard let self else { return }
            ensureBackground {
                let refreshStaticViewContentDescriptions = (data.data?.data ?? []).map { $0.describeDetailed() }
                Exponea.logger.log(.verbose, message: "In-app Content Blocks refreshStaticViewContent data: \(refreshStaticViewContentDescriptions)")
                let personalizedWithPayload: [PersonalizedInAppContentBlockResponse] = data.data?.data.compactMap { response in
                    var newInAppContentBlocks = response
                    let normalizeConf = HtmlNormalizerConfig(
                        makeResourcesOffline: true,
                        ensureCloseButton: false
                    )
                    let normalizedPayload = HtmlNormalizer(newInAppContentBlocks.content?.html ?? "").normalize(normalizeConf)
                    newInAppContentBlocks.htmlPayload = normalizedPayload
                    let isCorruptedImage = !self.hasHtmlImages(html: response.content?.html ?? "")
                    newInAppContentBlocks.isCorruptedImage = isCorruptedImage
                    return newInAppContentBlocks
                } ?? []
                var updatedPlaceholders: [InAppContentBlockResponse] = self.inAppContentBlockMessages
                for (index, inAppContentBlocks) in updatedPlaceholders.enumerated() {
                    if var personalized = personalizedWithPayload.first(where: { $0.id == inAppContentBlocks.id }) {
                        personalized.ttlSeen = Date()
                        updatedPlaceholders[index].personalizedMessage = personalized
                    }
                }
                self._inAppContentBlockMessages.changeValue(with: { $0 = updatedPlaceholders })
                completion?()
            }
        }
    }

    func refreshMessage(message: InAppContentBlockResponse, completion: TypeBlock<InAppContentBlockResponse>?) {
        guard let ids = try? DatabaseManager().currentCustomer.ids else {
            return
        }
        provider.loadPersonalizedInAppContentBlocks(
            data: PersonalizedInAppContentBlockResponseData.self,
            customerIds: ids,
            inAppContentBlocksIds: [message.id]
        ) { [weak self] data in
            guard let self else { return }
            ensureBackground {
                let personalizedWithPayload: [PersonalizedInAppContentBlockResponse] = data.data?.data
                    .filter { $0.id == message.id }
                    .compactMap { response in
                        var newInAppContentBlocks = response
                        let normalizeConf = HtmlNormalizerConfig(
                            makeResourcesOffline: true,
                            ensureCloseButton: false
                        )
                        let normalizedPayload = HtmlNormalizer(newInAppContentBlocks.content?.html ?? "").normalize(normalizeConf)
                        newInAppContentBlocks.htmlPayload = normalizedPayload
                        let isCorruptedImage = !self.hasHtmlImages(html: response.content?.html ?? "")
                        newInAppContentBlocks.isCorruptedImage = isCorruptedImage
                        return newInAppContentBlocks
                    } ?? []
                for (index, inAppContentBlocks) in self.inAppContentBlockMessages.enumerated() {
                    if let personal = personalizedWithPayload.first, inAppContentBlocks.id == personal.id {
                        var personalized = personal
                        print("Refreshed personalized: \(personal.id) for message \(inAppContentBlocks.id)")
                        personalized.ttlSeen = Date()
                        if self.inAppContentBlockMessages[safeIndex: index]?.personalizedMessage != nil {
                            self._inAppContentBlockMessages.changeValue(with: { $0[index].personalizedMessage = personalized })
                        }
                        completion?(self.inAppContentBlockMessages[index])
                    }
                }
            }
        }
    }

    func refreshCarouselData(placeholder: String, dataCompletion: TypeBlock<[StaticReturnData]>?) {
        Exponea.logger.log(.verbose, message: "In-app Content Blocks refreshStaticViewContent")
        if !isCarouselLoading {
            isCarouselLoading = true
            guard !placeholder.isEmpty, let ids = try? DatabaseManager().currentCustomer.ids else {
                Exponea.logger.log(.verbose, message: "In-app Content Blocks Carousel cant refresh placeholderId: \(placeholder), ids: \(String(describing: try? DatabaseManager().currentCustomer.ids))")
                return
            }
            let idsForDownload = inAppContentBlockMessages.filter { $0.placeholders.contains(placeholder) }.map { $0.id }
            provider.loadPersonalizedInAppContentBlocks(
                data: PersonalizedInAppContentBlockResponseData.self,
                customerIds: ids,
                inAppContentBlocksIds: idsForDownload
            ) { [weak self] data in
                guard let self else { return }
                ensureBackground {
                    let refreshStaticViewContentDescriptions = (data.data?.data ?? []).map { $0.describeDetailed() }
                    Exponea.logger.log(.verbose, message: "In-app Content Blocks refreshStaticViewContent data: \(refreshStaticViewContentDescriptions)")
                    let personalizedWithPayload: [PersonalizedInAppContentBlockResponse] = data.data?.data.compactMap { response in
                        var newInAppContentBlocks = response
                        let normalizeConf = HtmlNormalizerConfig(
                            makeResourcesOffline: true,
                            ensureCloseButton: false
                        )
                        let normalizedPayload = HtmlNormalizer(newInAppContentBlocks.content?.html ?? "").normalize(normalizeConf)
                        newInAppContentBlocks.htmlPayload = normalizedPayload
                        let isCorruptedImage = !self.hasHtmlImages(html: response.content?.html ?? "")
                        newInAppContentBlocks.isCorruptedImage = isCorruptedImage
                        return newInAppContentBlocks
                    } ?? []
                    var updatedPlaceholders: [InAppContentBlockResponse] = self.inAppContentBlockMessages
                    var updatedContentBlocksForTelemetry: [InAppContentBlockResponse] = []
                    for (index, inAppContentBlocks) in updatedPlaceholders.enumerated() {
                        if var personalized = personalizedWithPayload.first(where: { $0.id == inAppContentBlocks.id }) {
                            personalized.ttlSeen = Date()
                            updatedPlaceholders[index].personalizedMessage = personalized
                            updatedContentBlocksForTelemetry.append(updatedPlaceholders[index])
                        }
                    }
                    self.inAppContentBlockMessages = updatedPlaceholders
                    self.trackTelemetryForFetch(.contentBlockPersonalisedFetch, updatedContentBlocksForTelemetry)
                    let toReturn = updatedPlaceholders.filter { $0.placeholders.contains(placeholder) }
                        .compactMap { response in
                            self.prepareCarouselStaticData(messages: response)
                        }
                    dataCompletion?(toReturn)
                    self.continueWithCarouselQueue(dataCompletion: dataCompletion)
                }
            }
        } else {
            _carouselQueue.changeValue(with: { $0.append(placeholder) })
        }
    }
    
    func refreshStaticViewContent(staticQueueData: StaticQueueData) {
        Exponea.logger.log(.verbose, message: "In-app Content Blocks refreshStaticViewContent")
        if !isStaticUpdating {
            isStaticUpdating = true
            guard !staticQueueData.placeholderId.isEmpty, let ids = try? DatabaseManager().currentCustomer.ids else {
                isStaticUpdating = false
                staticQueueData.completion?(.init(html: "", tag: 0, message: nil))
                Exponea.logger.log(.verbose, message: "In-app Content Blocks cant refresh static content staticQueueData.placeholderId: \(staticQueueData.placeholderId), ids: \(String(describing: try? DatabaseManager().currentCustomer.ids))")
                isStaticUpdating = false
                return
            }
            let idsForDownload = inAppContentBlockMessages.filter { $0.placeholders.contains(staticQueueData.placeholderId) }.map { $0.id }
            provider.loadPersonalizedInAppContentBlocks(
                data: PersonalizedInAppContentBlockResponseData.self,
                customerIds: ids,
                inAppContentBlocksIds: idsForDownload
            ) { [weak self] data in
                guard let self else { return }
                ensureBackground {
                    let refreshStaticViewContentDescriptions = (data.data?.data ?? []).map { $0.describeDetailed() }
                    Exponea.logger.log(.verbose, message: "In-app Content Blocks refreshStaticViewContent data: \(refreshStaticViewContentDescriptions)")
                    let personalizedWithPayload: [PersonalizedInAppContentBlockResponse] = data.data?.data.compactMap { response in
                        var newInAppContentBlocks = response
                        let normalizeConf = HtmlNormalizerConfig(
                            makeResourcesOffline: true,
                            ensureCloseButton: false
                        )
                        let normalizedPayload = HtmlNormalizer(newInAppContentBlocks.content?.html ?? "").normalize(normalizeConf)
                        newInAppContentBlocks.htmlPayload = normalizedPayload
                        let isCorruptedImage = !self.hasHtmlImages(html: response.content?.html ?? "")
                        newInAppContentBlocks.isCorruptedImage = isCorruptedImage
                        return newInAppContentBlocks
                    } ?? []
                    var updatedPlaceholders: [InAppContentBlockResponse] = self.inAppContentBlockMessages
                    var updatedContentBlocksForTelemetry: [InAppContentBlockResponse] = []
                    for (index, inAppContentBlocks) in updatedPlaceholders.enumerated() {
                        if var personalized = personalizedWithPayload.first(where: { $0.id == inAppContentBlocks.id }) {
                            personalized.ttlSeen = Date()
                            updatedPlaceholders[index].personalizedMessage = personalized
                            updatedContentBlocksForTelemetry.append(updatedPlaceholders[index])
                        }
                    }
                    self.inAppContentBlockMessages = updatedPlaceholders
                    self.trackTelemetryForFetch(.contentBlockPersonalisedFetch, updatedContentBlocksForTelemetry)
                    let data = self.prepareInAppContentBlocksStaticView(placeholderId: staticQueueData.placeholderId)
                    onMain {
                        staticQueueData.completion?(data)
                    }
                    self.continueWithStaticQueue()
                }
            }
        } else {
            _staticQueue.changeValue(with: { $0.append(staticQueueData) })
        }
    }
    
    func prepareCarouselStaticData(
        messages: InAppContentBlockResponse
    ) -> StaticReturnData? {
        // Found message
        guard var message = filterPersonalizedMessages(input: messages.personalizedMessage?.status == .ok ? [messages] : []) else {
            Exponea.logger.log(.verbose, message: "In-app Content Blocks prepareInAppContentBlocksStaticView message not found.")
            return nil
        }
        message.status = getDisplayState(of: message.id)
        Exponea.logger.log(
            .verbose,
            message: "In-app Content Blocks prepareInAppContentBlocksStaticView message \(message.describe())."
        )

        // Add random for 100% unique
        let tag = createUniqueTag(placeholder: message)
        Exponea.logger.log(.verbose, message: "In-app Content Blocks prepareInAppContentBlocksStaticView tag \(tag).")

        let indexOfPlaceholder: Int = inAppContentBlockMessages.firstIndex(where: { $0.id == message.id }) ?? 0

        message.tags?.insert(tag)

        if let personalized = message.personalizedMessage, let payloadData = personalized.htmlPayload?.html?.data(using: .utf8), !payloadData.isEmpty {
            Exponea.logger.log(
                .verbose,
                message: "In-app Content Blocks prepareInAppContentBlocksStaticView personalized \(personalized.describeDetailed())."
            )
            if self.inAppContentBlockMessages[indexOfPlaceholder].personalizedMessage?.ttlSeen == nil {
                _inAppContentBlockMessages.changeValue(with: { $0[indexOfPlaceholder].personalizedMessage?.ttlSeen = Date() })
            }
            if let html = personalized.htmlPayload?.html, !html.isEmpty {
                return .init(html: html, tag: tag, message: message)
            }
        } else {
            Exponea.logger.log(
                .verbose,
                message: "In-app Content Blocks prepareInAppContentBlocksStaticView static \(message.describe())."
            )
            if let html = message.content?.html, !html.isEmpty {
                return .init(html: html, tag: tag, message: message)
            }
        }
        return nil
    }
}

// Synchro
private extension InAppContentBlocksManager {
    func continueWithQueue() {
        isUpdating = false
        if !queue.isEmpty {
            let go = queue.removeFirst()
            Exponea.logger.log(.verbose, message: "In-app Content Blocks continueWithQueue data: \(go.describeDetailed())")
            loadContentForPlacehoder(newValue: go.newValue, message: go.inAppContentBlocks)
        }
    }

    func loadContentForPlacehoder(newValue: UsedInAppContentBlocks, message: InAppContentBlockResponse) {
        if !isUpdating {
            isUpdating = true
            let savedNewValue = newValue
            let savedPlaceholder = message
            loadPersonalizedInAppContentBlocks(for: savedNewValue.messageId, tags: [savedNewValue.tag], skipLoad: true) { [weak self] in
                guard let self else { return }
                self.calculator = .init()
                self.calculator.heightUpdate = { height in
                    let tag = self.createUniqueTag(placeholder: message)
                    Exponea.logger.log(.verbose, message: "In-app Content Blocks loadContentForPlacehoder calculator data \(height)")
                    // Update display status
                    let indexOfPlaceholder: Int = self.inAppContentBlockMessages.firstIndex(where: { $0.id == message.id }) ?? 0
                    self.updateDisplayedState(for: message.id)

                    self._inAppContentBlockMessages.changeValue(with: { $0[indexOfPlaceholder].tags?.insert(tag) })
                    self._inAppContentBlockMessages.changeValue(with: { $0[indexOfPlaceholder].indexPath = savedPlaceholder.indexPath })
                    Exponea.logger.log(.verbose, message: "In-app Content Blocks loadContentForPlacehoder count \(self.inAppContentBlockMessages.count)")
                    Exponea.logger.log(.verbose, message: "In-app Content Blocks loadContentForPlacehoder \(self.inAppContentBlockMessages.map { $0.describe() })")
                    Exponea.logger.log(.verbose, message:
                        """
                        In-app Content Blocks loadContentForPlacehoder(newValue: UsedInAppContentBlocks, placeholder: InAppContentBlockResponse)
                        newValue: \(newValue.describeDetailed())
                        placeholder: \(message.describe())
                        """
                    )
                    let placeholderValueFromUsedLine = savedNewValue.placeholder
                    let savedInAppContentBlocksToDeactived = self.usedInAppContentBlocks[placeholderValueFromUsedLine] ?? []
                    if savedInAppContentBlocksToDeactived.isEmpty {
                        self._usedInAppContentBlocks.changeValue { store in
                            let newSavedInAppContentBlocks: UsedInAppContentBlocks = .init(tag: savedNewValue.tag, indexPath: savedNewValue.indexPath, messageId: savedPlaceholder.id, placeholder: savedNewValue.placeholder, height: height.height, placeholderData: savedPlaceholder)
                            if store[placeholderValueFromUsedLine] == nil {
                                store[placeholderValueFromUsedLine] = [newSavedInAppContentBlocks]
                            } else if store[placeholderValueFromUsedLine]?.isEmpty == true {
                                store[placeholderValueFromUsedLine]?.append(newSavedInAppContentBlocks)
                            }
                        }
                        self.continueWithQueue()
                        self.calculator.heightUpdate = nil
                        self.refreshCallback?(savedNewValue.indexPath)
                    } else {
                        if let indexOfSavedInAppContentBlocks: Int = self.usedInAppContentBlocks[placeholderValueFromUsedLine]?.firstIndex(where: { $0.indexPath == savedPlaceholder.indexPath && $0.height == 0 }) {
                            if var savedInAppContentBlocks = self.usedInAppContentBlocks[placeholderValueFromUsedLine]?[indexOfSavedInAppContentBlocks] {
                                if savedInAppContentBlocks.height == 0 {
                                    savedInAppContentBlocks.height = height.height
                                }
                                self._usedInAppContentBlocks.changeValue(with: { $0[placeholderValueFromUsedLine]?.insert(savedInAppContentBlocks, at: indexOfSavedInAppContentBlocks) })
                            }
                        } else {
                            let newSavedInAppContentBlocks: UsedInAppContentBlocks = .init(tag: savedNewValue.tag, indexPath: savedNewValue.indexPath, messageId: savedPlaceholder.id, placeholder: savedNewValue.placeholder, height: height.height, placeholderData: savedPlaceholder)
                            self._usedInAppContentBlocks.changeValue { store in
                                if store[placeholderValueFromUsedLine]?.contains(where: { $0.indexPath == newSavedInAppContentBlocks.indexPath && $0.messageId == newSavedInAppContentBlocks.messageId && $0.height == 0 }) == false {
                                    store[placeholderValueFromUsedLine]?.append(newSavedInAppContentBlocks)
                                }
                            }
                        }
                        self.continueWithQueue()
                        self.calculator.heightUpdate = nil
                        self.refreshCallback?(savedNewValue.indexPath)
                    }
                }
                guard let html = self.inAppContentBlockMessages.first(where: { $0.tags?.contains(newValue.tag) == true })?.personalizedMessage?.htmlPayload?.html, !html.isEmpty else {
                    self.isUpdating = false
                    return
                }
                self.calculator.loadHtml(placedholderId: message.id, html: html)
            }
        } else {
            Exponea.logger.log(.verbose, message:
                """
                In-app Content Blocks added to queue
                newValue: \(newValue.describeDetailed())
                placeholder: \(message.describe())
                """
            )
            _queue.changeValue(with: { $0.append(.init(inAppContentBlocks: message, newValue: newValue)) })
        }
    }
}

// Display and Interaction state
extension InAppContentBlocksManager {

    /// Stores timestamp of interaction (click/close) for given In-app content block message ID
    func updateInteractedState(for messageId: String) {
        Exponea.shared.inAppContentBlockStatusStore.didInteract(with: messageId, at: Date())
    }

    /// Stores timestamp of displaying (show) of given In-app content block message ID
    func updateDisplayedState(for messageId: String) {
        Exponea.shared.inAppContentBlockStatusStore.didDisplay(of: messageId, at: Date())
    }

    func getDisplayState(of messageId: String) -> InAppContentBlocksDisplayStatus {
        Exponea.shared.inAppContentBlockStatusStore.status(for: messageId)
    }
}

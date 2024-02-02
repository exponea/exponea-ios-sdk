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
    @Atomic private var queue: [QueueData] = []
    @Atomic private var loadQueue: [QueueLoadData] = []
    @Atomic private var staticQueue: [StaticQueueData] = []
    private var newUsedInAppContentBlocks: UsedInAppContentBlocks? {
        willSet {
            guard let newValue, let placeholder = newValue.placeholderData else { return }
            if placeholder.content == nil, newValue.height == 0 {
                loadContentForPlacehoder(newValue: newValue, placeholder: placeholder)
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
    }

    func initBlocker() {
        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: "ContentBlockingRules",
            encodedContentRuleList: blockRules
        ) { contentRuleList, error in
            guard error == nil else { return }
            self.contentRuleList = contentRuleList
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
    func getUsedInAppContentBlocks(placeholder: String, indexPath: IndexPath) -> UsedInAppContentBlocks? {
        usedInAppContentBlocks[placeholder]?.first(where: { $0.indexPath == indexPath && $0.isActive })
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
        let webAction: WebActionManager = .init {
            guard let indexOfMessage: Int = self.inAppContentBlockMessages.firstIndex(where: { $0.id == inAppContentBlockResponse.id }) else {
                Exponea.logger.log(.error, message: "Placeholder cant be found for action click")
                return
            }
            let currentDisplay = self.inAppContentBlockMessages[indexOfMessage].displayState
            self.inAppContentBlockMessages[indexOfMessage].displayState = .init(displayed: currentDisplay?.displayed, interacted: Date())
            Exponea.shared.trackInAppContentBlockClose(
                placeholderId: selectedUsed.placeholder,
                message: inAppContentBlockResponse
            )
            self.refreshCallback?(selectedUsed.indexPath)
        } onActionCallback: { action in
            let inAppCbAction = InAppContentBlockAction(
                name: action.buttonText,
                url: action.actionUrl,
                type: self.determineActionType(action.actionUrl)
            )
            guard let indexOfPlaceholder: Int = self.inAppContentBlockMessages.firstIndex(where: { $0.id == inAppContentBlockResponse.id }) else {
                Exponea.logger.log(.error, message: "Placeholder cant be found for action click")
                return
            }
            let currentDisplay = self.inAppContentBlockMessages[indexOfPlaceholder].displayState
            self.inAppContentBlockMessages[indexOfPlaceholder].displayState = .init(displayed: currentDisplay?.displayed, interacted: Date())
            Exponea.shared.trackInAppContentBlockClick(
                placeholderId: selectedUsed.placeholder,
                action: inAppCbAction,
                message: inAppContentBlockResponse
            )
            self.urlOpener.openBrowserLink(action.actionUrl)
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

    private func determineActionType(_ url: String) -> InAppContentBlockActionType {
        if url == "https://exponea.com/close_action" {
            return .close
        }
        if url.hasPrefix("http://") || url.hasPrefix("https://") {
            return .browser
        } else {
            return .deeplink
        }
    }

    private func parseData(placeholderId: String, data: ResponseData<PersonalizedInAppContentBlockResponseData>, tags: Set<Int>, completion: EmptyBlock?) {
        let personalizedWithPayload: [PersonalizedInAppContentBlockResponse] = data.data?.data.compactMap { response in
            var newInAppContentBlocks = response
            let normalizeConf = HtmlNormalizerConfig(
                makeResourcesOffline: true,
                ensureCloseButton: false
            )
            let normalizedPayload = HtmlNormalizer(newInAppContentBlocks.content?.html ?? "").normalize(normalizeConf)
            newInAppContentBlocks.htmlPayload = normalizedPayload
            return newInAppContentBlocks
        } ?? []
        var updatedPlaceholders: [InAppContentBlockResponse] = self.inAppContentBlockMessages
        for (index, inAppContentBlocks) in updatedPlaceholders.enumerated() {
            if var personalized = personalizedWithPayload.first(where: { $0.id == inAppContentBlocks.id }) {
                personalized.ttlSeen = Date()
                updatedPlaceholders[index].personalizedMessage = personalized
            }
        }
        self.inAppContentBlockMessages = updatedPlaceholders
        completion?()
    }

    func prefetchPlaceholdersWithIds(input: [InAppContentBlockResponse], ids: [String]) -> [InAppContentBlockResponse] {
        input.filter { inAppContentBlocks in
            !inAppContentBlocks.placeholders.filter { placeholder in
                ids.contains(placeholder)
            }.isEmpty
        }
    }

    func prefetchPlaceholdersWithIds(ids: [String]) {
        guard let customerIds = try? DatabaseManager().currentCustomer.ids else { return }
        provider.loadPersonalizedInAppContentBlocks(
            data: PersonalizedInAppContentBlockResponseData.self,
            customerIds: customerIds,
            inAppContentBlocksIds: prefetchPlaceholdersWithIds(input: inAppContentBlockMessages, ids: ids).map { $0.id }
        ) { [weak self] messages in
            guard let self else { return }
            let personalizedWithPayload: [PersonalizedInAppContentBlockResponse]? = messages.data?.data.filter { $0.status == .ok }.map { response in
                var newInAppContentBlocks = response
                let normalizeConf = HtmlNormalizerConfig(
                    makeResourcesOffline: false,
                    ensureCloseButton: false
                )
                let normalizedPayload = HtmlNormalizer(newInAppContentBlocks.content?.html ?? "").normalize(normalizeConf)
                newInAppContentBlocks.htmlPayload = normalizedPayload
                return newInAppContentBlocks
            }
            var updatedPlaceholders: [InAppContentBlockResponse] = self.inAppContentBlockMessages
            for (index, inAppContentBlocks) in updatedPlaceholders.enumerated() {
                if var personalized = personalizedWithPayload?.first(where: { $0.id == inAppContentBlocks.id }) {
                    personalized.ttlSeen = Date()
                    updatedPlaceholders[index].personalizedMessage = personalized
                }
            }
            self.inAppContentBlockMessages = updatedPlaceholders
        }
    }

    func getFilteredMessage(message: InAppContentBlockResponse) -> Bool {
        guard let displayState = message.displayState else { return false }
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
            if value.indexPath == indexPath {
                value.isActive = value.messageId == message.id
            }
            blocksToReturn.append(value)
        }
        _usedInAppContentBlocks.changeValue(with: { $0[placeholderId] = blocksToReturn })
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
        _usedInAppContentBlocks.changeValue(with: { $0[placeholderId] = blocksToReturn })
    }

    func prepareInAppContentBlockView(placeholderId: String, indexPath: IndexPath) -> UIView {
        let messagesToUse = inAppContentBlockMessages.filter { $0.placeholders.contains(placeholderId) }
        let messagesNeedToRefresh = messagesToUse.filter { $0.indexPath == nil || $0.personalizedMessage == nil && $0.content?.html == nil }
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
        for message in inAppContentBlockMessages where messagesForThisIndexPath.contains(where: { $0.messageId == message.id }) {
            messagesToFilter.append(message)
        }
        guard let message = filterPersonalizedMessages(input: messagesToFilter) else {
            Exponea.logger.log(.verbose, message: "No more In-app Content Block messages for indexPath  \(indexPath)")
            markAsInactive(indexPath: indexPath, placeholderId: placeholderId)
            return returnEmptyView(tag: Int.random(in: 0..<99999999))
        }
        Exponea.logger.log(.verbose, message: "Filtered In-app Content Block \(message)")
        markAsActive(message: message, indexPath: indexPath, placeholderId: placeholderId)
        let tag = createUniqueTag(placeholder: message)
        let indexOfPlaceholder: Int = inAppContentBlockMessages.firstIndex(where: { $0.indexPath == message.indexPath }) ?? 0
        let currentDisplay = inAppContentBlockMessages[safeIndex: indexOfPlaceholder]?.displayState
        let state: InAppContentBlocksDisplayStatus = .init(displayed: currentDisplay?.displayed ?? Date(), interacted: currentDisplay?.interacted)

        web = .init()
        web.tag = tag
        web.navigationDelegate = self

        if let html = message.content?.html, !html.isEmpty {
            if inAppContentBlockMessages[indexOfPlaceholder].normalizedResult == nil {
                let normalizeConf = HtmlNormalizerConfig(
                    makeResourcesOffline: true,
                    ensureCloseButton: false
                )
                let normalizedPayload = HtmlNormalizer(html).normalize(normalizeConf)
                inAppContentBlockMessages[indexOfPlaceholder].normalizedResult = normalizedPayload
            }
            let finalHTML = inAppContentBlockMessages[indexOfPlaceholder].normalizedResult?.html ?? html
            if inAppContentBlockMessages[indexOfPlaceholder].personalizedMessage?.ttlSeen == nil {
                _inAppContentBlockMessages.changeValue(with: { $0[indexOfPlaceholder].personalizedMessage?.ttlSeen = Date() })
            }
            _inAppContentBlockMessages.changeValue(with: { $0[indexOfPlaceholder].displayState = state })
            web.loadHTMLString(finalHTML, baseURL: nil)
            return web
        } else if let personalized = message.personalizedMessage, let payloadData = personalized.htmlPayload?.html?.data(using: .utf8), !payloadData.isEmpty {
            if inAppContentBlockMessages[indexOfPlaceholder].personalizedMessage?.ttlSeen == nil {
                _inAppContentBlockMessages.changeValue(with: { $0[indexOfPlaceholder].personalizedMessage?.ttlSeen = Date() })
            }
            if let html = personalized.htmlPayload?.html, !html.isEmpty {
                _inAppContentBlockMessages.changeValue(with: { $0[indexOfPlaceholder].displayState = state })
                web.loadHTMLString(html, baseURL: nil)
                return web
            } else {
                return returnEmptyView(tag: tag)
            }
        } else {
            return returnEmptyView(tag: tag)
        }
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

        guard placeholdersNeedToRefresh.isEmpty && expiredMessages.isEmpty else {
            return .init(html: "", tag: 0, message: nil)
        }

        // Found message
        guard var message = filterPersonalizedMessages(input: placehodlersToUse.filter { $0.personalizedMessage?.status == .ok }) else {
            return .init(html: "", tag: 0, message: nil)
        }

        // Add random for 100% unique
        let tag = createUniqueTag(placeholder: message)

        // Update display status
        let indexOfPlaceholder: Int = inAppContentBlockMessages.firstIndex(where: { $0.id == message.id }) ?? 0
        let currentDisplay = inAppContentBlockMessages[safeIndex: indexOfPlaceholder]?.displayState
        let state: InAppContentBlocksDisplayStatus = .init(displayed: currentDisplay?.displayed ?? Date(), interacted: currentDisplay?.interacted)
        message.tags?.insert(tag)

        if let personalized = message.personalizedMessage, let payloadData = personalized.htmlPayload?.html?.data(using: .utf8), !payloadData.isEmpty {
            if self.inAppContentBlockMessages[indexOfPlaceholder].personalizedMessage?.ttlSeen == nil {
                _inAppContentBlockMessages.changeValue(with: { $0[indexOfPlaceholder].personalizedMessage?.ttlSeen = Date() })
            }
            if let html = personalized.htmlPayload?.html, !html.isEmpty {
                message.displayState = state
                _inAppContentBlockMessages.changeValue(with: { $0[indexOfPlaceholder] = message })
                Exponea.shared.trackInAppContentBlockShown(
                    placeholderId: placeholderId,
                    message: message
                )
                return .init(html: html, tag: tag, message: message)
            }
        } else {
            if let html = message.content?.html, !html.isEmpty {
                message.displayState = state
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
            guard result.data?.success == true else { return }
            self?.inAppContentBlockMessages = result.data?.data ?? []
            completion?()
        }
    }
}

private extension InAppContentBlocksManager {
    func loadPersonalizedInAppContentBlocks(for placeholderId: String, tags: Set<Int>, skipLoad: Bool = false, completion: EmptyBlock?) {
        guard !placeholderId.isEmpty, let ids = try? DatabaseManager().currentCustomer.ids else {
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
                    self.parseData(placeholderId: placeholderId, data: data, tags: tags, completion: completion)
                }
            }
        }
    }

    func filterPersonalizedMessages(input: [InAppContentBlockResponse]) -> InAppContentBlockResponse? {
        let filtered = input.filter { inAppContentBlocksPlaceholder in
            if inAppContentBlocksPlaceholder.personalizedMessage?.status == .ok {
                return self.getFilteredMessage(message: inAppContentBlocksPlaceholder)
            } else {
                return false
            }
        }
        guard !filtered.isEmpty else {
            return nil
        }
        let sorted = filtered.sorted { lhs, rhs in
            lhs.loadPriority ?? 0 > rhs.loadPriority ?? 0
        }
        let toReturn = filterPriority(input: sorted).sorted(by: { $0.key > $1.key })
        return toReturn.first?.value.randomElement()
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
        guard let ids = try? DatabaseManager().currentCustomer.ids else { return }
        if !isLoadUpdating {
            isLoadUpdating = true
            let placehodlersToUse = inAppContentBlockMessages.filter { $0.placeholders.contains(placeholder) }
            var placeholdersNeedToGetContent = placehodlersToUse.filter { $0.indexPath == nil || $0.personalizedMessage == nil && $0.content?.html == nil }
            if placeholdersNeedToGetContent.isEmpty && !expired.isEmpty {
                placeholdersNeedToGetContent = expired
            }
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
            DispatchQueue.global().async { [weak self] in
                guard let self else { return }
                self.provider.loadPersonalizedInAppContentBlocks(
                    data: PersonalizedInAppContentBlockResponseData.self,
                    customerIds: ids,
                    inAppContentBlocksIds: placeholdersNeedToGetContent.map { $0.id }
                ) { data in
                    let personalizedWithPayload: [PersonalizedInAppContentBlockResponse] = data.data?.data.compactMap { response in
                        var newInAppContentBlocks = response
                        let normalizeConf = HtmlNormalizerConfig(
                            makeResourcesOffline: true,
                            ensureCloseButton: false
                        )
                        let normalizedPayload = HtmlNormalizer(newInAppContentBlocks.content?.html ?? "").normalize(normalizeConf)
                        newInAppContentBlocks.htmlPayload = normalizedPayload
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
                        self.loadContent(indexPath: go.indexPath, placeholder: go.placeholder, expired: go.expired)
                    }
                }
            }
        } else {
            _loadQueue.changeValue(with: { $0.append(.init(placeholder: placeholder, indexPath: indexPath, expired: expired)) })
        }
    }

    func calculateStaticData(height: CalculatorData, newValue: UsedInAppContentBlocks, placeholder: InAppContentBlockResponse) {
        let savedNewValue = newValue
        let placeholderValueFromUsedLine = savedNewValue.placeholder
        let savedInAppContentBlocksToDeactived = self.usedInAppContentBlocks[placeholderValueFromUsedLine] ?? []
        guard let indexPath = placeholder.indexPath else { return }
        if savedInAppContentBlocksToDeactived.isEmpty {
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
            refreshStaticViewContent(staticQueueData: go)
        }
    }

    func refreshStaticViewContent(staticQueueData: StaticQueueData) {
        if !isStaticUpdating {
            isStaticUpdating = true
            guard !staticQueueData.placeholderId.isEmpty, let ids = try? DatabaseManager().currentCustomer.ids else {
                staticQueueData.completion?(.init(html: "", tag: 0, message: nil))
                return
            }
            let idsForDownload = inAppContentBlockMessages.filter { $0.placeholders.contains(staticQueueData.placeholderId) }.map { $0.id }
            provider.loadPersonalizedInAppContentBlocks(
                data: PersonalizedInAppContentBlockResponseData.self,
                customerIds: ids,
                inAppContentBlocksIds: idsForDownload
            ) { [weak self] data in
                guard let self else { return }
                let personalizedWithPayload: [PersonalizedInAppContentBlockResponse] = data.data?.data.compactMap { response in
                    var newInAppContentBlocks = response
                    let normalizeConf = HtmlNormalizerConfig(
                        makeResourcesOffline: true,
                        ensureCloseButton: false
                    )
                    let normalizedPayload = HtmlNormalizer(newInAppContentBlocks.content?.html ?? "").normalize(normalizeConf)
                    newInAppContentBlocks.htmlPayload = normalizedPayload
                    return newInAppContentBlocks
                } ?? []
                var updatedPlaceholders: [InAppContentBlockResponse] = self.inAppContentBlockMessages
                for (index, inAppContentBlocks) in updatedPlaceholders.enumerated() {
                    if var personalized = personalizedWithPayload.first(where: { $0.id == inAppContentBlocks.id }) {
                        personalized.ttlSeen = Date()
                        updatedPlaceholders[index].personalizedMessage = personalized
                    }
                }
                self.inAppContentBlockMessages = updatedPlaceholders
                let data = self.prepareInAppContentBlocksStaticView(placeholderId: staticQueueData.placeholderId)
                staticQueueData.completion?(data)
                self.continueWithStaticQueue()
            }
        } else {
            _staticQueue.changeValue(with: { $0.append(staticQueueData) })
        }
    }
}

// Synchro
private extension InAppContentBlocksManager {
    func continueWithQueue() {
        isUpdating = false
        if !queue.isEmpty {
            let go = queue.removeFirst()
            loadContentForPlacehoder(newValue: go.newValue, placeholder: go.inAppContentBlocks)
        }
    }

    func loadContentForPlacehoder(newValue: UsedInAppContentBlocks, placeholder: InAppContentBlockResponse) {
        if !isUpdating {
            isUpdating = true
            let savedNewValue = newValue
            let savedPlaceholder = placeholder
            loadPersonalizedInAppContentBlocks(for: savedNewValue.messageId, tags: [savedNewValue.tag], skipLoad: true) { [weak self] in
                guard let self else { return }
                calculator = .init()
                calculator.heightUpdate = { height in
                    let tag = self.createUniqueTag(placeholder: placeholder)
                    // Update display status
                    let indexOfPlaceholder: Int = self.inAppContentBlockMessages.firstIndex(where: { $0.id == placeholder.id }) ?? 0
                    let currentDisplay = self.inAppContentBlockMessages[safeIndex: indexOfPlaceholder]?.displayState
                    let state: InAppContentBlocksDisplayStatus = .init(displayed: currentDisplay?.displayed ?? Date(), interacted: currentDisplay?.interacted)

                    self._inAppContentBlockMessages.changeValue(with: { $0[indexOfPlaceholder].tags?.insert(tag) })
                    self._inAppContentBlockMessages.changeValue(with: { $0[indexOfPlaceholder].indexPath = savedPlaceholder.indexPath })
                    self._inAppContentBlockMessages.changeValue(with: { $0[indexOfPlaceholder].displayState = state })

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
                guard let html = inAppContentBlockMessages.first(where: { $0.tags?.contains(newValue.tag) == true })?.personalizedMessage?.htmlPayload?.html, !html.isEmpty else {
                    isUpdating = false
                    return
                }
                calculator.loadHtml(placedholderId: placeholder.id, html: html)
            }
        } else {
            _queue.changeValue(with: { $0.append(.init(inAppContentBlocks: placeholder, newValue: newValue)) })
        }
    }
}

//
//  InlineMessageManager.swift
//  ExponeaSDK
//
//  Created by Ankmara on 17.05.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation
import AppTrackingTransparency
import WebKit

public final class InlineMessageManager: NSObject {

    // MARK: - Properties
    public static let manager = InlineMessageManager()
    @Atomic public var inlinePlaceholders: [InlineMessageResponse] = []
    public var refreshCallback: TypeBlock<IndexPath>?
    public let urlOpener: UrlOpenerType = UrlOpener()
    public let disableZoomSource: String =
    """
        var meta = document.createElement('meta');
        meta.name = 'viewport';
        meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
        var head = document.getElementsByTagName('head')[0];
        head.appendChild(meta);
    """
    public let blockRules =
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
    public var contentRuleList: WKContentRuleList?

    private var isStaticUpdating = false
    private var isUpdating = false
    @Atomic private var queue: [QueueData] = []
    @Atomic private var staticQueue: [StaticQueueData] = []
    private var newUsedInline: UsedInline? {
        willSet {
            guard let newValue else { return }
            if let placeholder = inlinePlaceholders.first(where: { $0.tags?.contains(newValue.tag) == true }), placeholder.content == nil, newValue.height == 0 {
                self.loadContentForPlacehoder(newValue: newValue, placeholder: placeholder)
            }
        }
    }
    @Atomic private var usedInlines: [String: [UsedInline]] = [:]
    private let sessionStart = Date()
    private let provider: InlineMessageDataProviderType

    // MARK: - Init
    public override init() {
        self.provider = InlineMessageDataProvider()
        super.init()
    }

    public func initBlocker() {
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
            let configuration = newWebview.configuration
            configuration.userContentController.addUserScript(userScript)
            if let contentRuleList {
                configuration.userContentController.add(contentRuleList)
            }
            objc_setAssociatedObject(self, &key, newWebview, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    private var calculatorKey: String = "key_calculator"
    public var calculator: WKWebViewHeightCalculator {
        get {
            objc_getAssociatedObject(self, &calculatorKey) as! WKWebViewHeightCalculator
        }
        set {
            objc_setAssociatedObject(self, &calculatorKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}

public struct WKWebViewData {
    public let height: CGFloat
    public let tag: Int
}

// MARK: InlineMessageManagerType
extension InlineMessageManager: InlineMessageManagerType, WKNavigationDelegate {
    public func getUsedInline(placeholder: String, indexPath: IndexPath) -> UsedInline? {
        usedInlines[placeholder]?.first(where: { $0.isActive })
    }

    func openBrowserAction(_ action: MessageItemAction) {
        guard let buttonLink = action.url else {
            Exponea.logger.log(.error, message: "AppInbox action \"\(action.title ?? "<nil>")\" contains invalid browser link \(action.url ?? "<nil>")")
            return
        }
        urlOpener.openBrowserLink(buttonLink)
    }

    func openDeeplinkAction(_ action: MessageItemAction) {
        guard let buttonLink = action.url else {
            Exponea.logger.log(.error, message: "AppInbox action \"\(action.title ?? "<nil>")\" contains invalid universal link \(action.url ?? "<nil>")")
            return
        }
        urlOpener.openDeeplink(buttonLink)
    }

    public func anonymize() {
        usedInlines.removeAll()
        inlinePlaceholders.removeAll()
    }

    public func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        let result = inlinePlaceholders.first(where: { $0.tags?.contains(webView.tag) == true })
        let webAction: WebActionManager = .init {
            let indexOfPlaceholder: Int = self.inlinePlaceholders.firstIndex(where: { $0.id == result?.id ?? "" }) ?? 0
            let currentDisplay = self.inlinePlaceholders[indexOfPlaceholder].displayState
            self.inlinePlaceholders[indexOfPlaceholder].displayState = .init(displayed: currentDisplay?.displayed, interacted: Date())
            if let message = result {
                Exponea.shared.trackInlineMessageClose(message: message, isUserInteraction: true)
            }
            if let path = result?.indexPath {
                self.refreshCallback?(path)
            }
        } onActionCallback: { action in
            let indexOfPlaceholder: Int = self.inlinePlaceholders.firstIndex(where: { $0.id == result?.id ?? "" }) ?? 0
            let currentDisplay = self.inlinePlaceholders[indexOfPlaceholder].displayState
            self.inlinePlaceholders[indexOfPlaceholder].displayState = .init(displayed: currentDisplay?.displayed, interacted: Date())
            if let message = result {
                Exponea.shared.trackInlineMessageClick(message: message, buttonText: action.buttonText, buttonLink: action.actionUrl)
            }
            self.urlOpener.openBrowserLink(action.actionUrl)
            if let path = result?.indexPath {
                self.refreshCallback?(path)
            }
        } onErrorCallback: { error in
            Exponea.logger.log(.error, message: "WebActionManager error \(error.localizedDescription)")
        }
        webAction.htmlPayload = result?.personalizedMessage?.htmlPayload
        let handled = webAction.handleActionClick(navigationAction.request.url)
        if handled {
            Exponea.logger.log(.verbose, message: "[HTML] Action \(navigationAction.request.url?.absoluteString ?? "Invalid") has been handled")
            decisionHandler(.cancel)
        } else {
            Exponea.logger.log(.verbose, message: "[HTML] Action \(navigationAction.request.url?.absoluteString ?? "Invalid") has not been handled, continue")
            decisionHandler(.allow)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            if let indexPath = result?.indexPath {
                self?.newUsedInline = .init(tag: webView.tag, indexPath: indexPath, placeholderId: "", placeholder: "", height: webView.scrollView.contentSize.height + 10)
            }
        }
    }

    private func parseData(placeholderId: String, data: ResponseData<PersonalizedInlineMessageResponseData>, tags: Set<Int>, completion: EmptyBlock?) {
        let personalizedWithPayload: [PersonalizedInlineMessageResponse] = data.data?.data.compactMap { response in
            var newInlineMessage = response
            let normalizeConf = HtmlNormalizerConfig(
                makeResourcesOffline: true,
                ensureCloseButton: false,
                allowAnchorButton: true
            )
            let normalizedPayload = HtmlNormalizer(newInlineMessage.content?.html ?? "").normalize(normalizeConf)
            newInlineMessage.htmlPayload = normalizedPayload
            return newInlineMessage
        } ?? []
        var updatedPlaceholders: [InlineMessageResponse] = self.inlinePlaceholders
        for (index, inlineMessage) in updatedPlaceholders.enumerated() {
            if var personalized = personalizedWithPayload.first(where: { $0.id == inlineMessage.id }) {
                personalized.ttlSeen = Date()
                updatedPlaceholders[index].personalizedMessage = personalized
            }
        }
        self.inlinePlaceholders = updatedPlaceholders
        completion?()
    }

    private func delayledLoad(for placeholderId: String, tags: Set<Int>, completion: EmptyBlock?) {
        guard !placeholderId.isEmpty, let ids = try? DatabaseManager().currentCustomer.ids else {
            return
        }
        DispatchQueue.global().async {
            self.provider.loadPersonalizedInlineMessages(
                 data: PersonalizedInlineMessageResponseData.self,
                 customerIds: ids,
                 inlineMessageIds: [placeholderId]
             ) { [weak self] data in
                 guard let self else { return }
                 self.parseData(placeholderId: placeholderId, data: data, tags: tags, completion: completion)
             }
        }
    }

    public func loadPersonalizedInlineMessage(for placeholderId: String, tags: Set<Int>, completion: EmptyBlock?) {
        delayledLoad(for: placeholderId, tags: tags, completion: completion)
    }

    public func prefetchPlaceholdersWithIds(input: [InlineMessageResponse], ids: [String]) -> [InlineMessageResponse] {
        input.filter { inline in
            !inline.placeholders.filter { placeholder in
                ids.contains(placeholder)
            }.isEmpty
        }
    }

    public func prefetchPlaceholdersWithIds(ids: [String]) {
        guard let customerIds = try? DatabaseManager().currentCustomer.ids else { return }
        provider.loadPersonalizedInlineMessages(
            data: PersonalizedInlineMessageResponseData.self,
            customerIds: customerIds,
            inlineMessageIds: prefetchPlaceholdersWithIds(input: inlinePlaceholders, ids: ids).map { $0.id }
        ) { [weak self] messages in
            guard let self else { return }
            let personalizedWithPayload: [PersonalizedInlineMessageResponse]? = messages.data?.data.filter { $0.status == .ok }.map { response in
                var newInlineMessage = response
                let normalizeConf = HtmlNormalizerConfig(
                    makeResourcesOffline: false,
                    ensureCloseButton: false,
                    allowAnchorButton: true
                )
                let normalizedPayload = HtmlNormalizer(newInlineMessage.content?.html ?? "").normalize(normalizeConf)
                newInlineMessage.htmlPayload = normalizedPayload
                return newInlineMessage
            }
            var updatedPlaceholders: [InlineMessageResponse] = self.inlinePlaceholders
            for (index, inlineMessage) in updatedPlaceholders.enumerated() {
                if var personalized = personalizedWithPayload?.first(where: { $0.id == inlineMessage.id }) {
                    personalized.ttlSeen = Date()
                    updatedPlaceholders[index].personalizedMessage = personalized
                }
            }
            self.inlinePlaceholders = updatedPlaceholders
        }
    }

    public func getFilteredMessage(message: InlineMessageResponse) -> Bool {
        guard let displayState = message.displayState else { return false }
        switch message.frequency {
        case .oncePerVisit:
            let shouldDisplay = displayState.displayed == nil
            if !shouldDisplay {
                Exponea.logger.log(.verbose, message: "Inline message '\(message.name)' already displayed.")
            }
            return shouldDisplay
        case .onlyOnce:
            let shouldDisplay = displayState.displayed ?? Date(timeIntervalSince1970: 0) < sessionStart
            if !shouldDisplay {
                Exponea.logger.log(.verbose, message: "Inline message '\(message.name)' already displayed this session.")
            }
            return shouldDisplay
        case .untilVisitorInteracts:
            let shouldDisplay = displayState.interacted == nil
            if !shouldDisplay {
                Exponea.logger.log(.verbose, message: "Inline message '\(message.name)' already interacted with.")
            }
            return shouldDisplay
        case .always:
            return true
        case .none:
            Exponea.logger.log(.warning, message: "Unknown inline message frequency.")
            return true
        }
    }

    private func filterPersonalizedMessages(input: [InlineMessageResponse]) -> InlineMessageResponse? {
        let filtered = input.filter { inlinePlaceholder in
            if inlinePlaceholder.personalizedMessage?.status == .ok {
                return self.getFilteredMessage(message: inlinePlaceholder)
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

    public func filterPriority(input: [InlineMessageResponse]) -> [Int: [InlineMessageResponse]] {
        var toReturn: [Int: [InlineMessageResponse]] = [:]
        for inline in input {
            let prio = inline.loadPriority ?? 0
            if toReturn[prio] != nil {
                toReturn[prio]?.append(inline)
            } else {
                toReturn[prio] = [inline]
            }
        }
        return toReturn
    }

    public func createUniqueTag(placeholder: InlineMessageResponse) -> Int {
        if let existingTag = usedInlines[placeholder.placeholders.first ?? ""]?.first(where: { placeholder.id == $0.placeholderId })?.tag {
            return existingTag
        } else {
            return Int.random(in: 0..<99999999)
        }
    }

    public func checkTTLForMessage(completion: EmptyBlock?) {
        guard let messagesNeeedToRefresh = inlinePlaceholders.first(where: { inlineMessage in
            if let ttlSeen = inlineMessage.personalizedMessage?.ttlSeen,
               let ttl = inlineMessage.personalizedMessage?.ttlSeconds,
               inlineMessage.content == nil {
                return Date() > ttlSeen.addingTimeInterval(TimeInterval(ttl))
            }
            return false
        }) else { return }
        loadPersonalizedInlineMessage(for: messagesNeeedToRefresh.id, tags: messagesNeeedToRefresh.tags ?? [], completion: completion)
    }

    private func returnEmptyView(tag: Int) -> UIView {
        let view = WKWebView(frame: .zero)
        view.tag = tag
        return view
    }

    private func returnEmptyStaticView(tag: Int) -> UIView {
        let view = UIView()
        view.tag = tag
        return view
    }

    private func updateDisplayStatus(placeholderId: String, tags: Set<Int>) -> InlineMessageDisplayStatus {
        let indexOfPlaceholder: Int = inlinePlaceholders.firstIndex(where: { $0.id == placeholderId }) ?? 0
        let currentDisplay = inlinePlaceholders[safeIndex: indexOfPlaceholder]?.displayState
        let state: InlineMessageDisplayStatus = .init(displayed: currentDisplay?.displayed ?? Date(), interacted: currentDisplay?.interacted)
        inlinePlaceholders[indexOfPlaceholder].displayState = state
        inlinePlaceholders[indexOfPlaceholder].tags = tags
        return state
    }

    func markInlineAsActive(placeholder: InlineMessageResponse) {
        Exponea.shared.trackInlineMessageShow(message: placeholder)
        let placeholderValue = placeholder.placeholders.first ?? ""
        var savedInlinesToDeactived = usedInlines[placeholderValue] ?? []

        // Mark all as inactive
        for (index, savedInline) in savedInlinesToDeactived.enumerated() {
            var currentSavedInline = savedInline
            currentSavedInline.isActive = false
            savedInlinesToDeactived[index] = currentSavedInline
        }
        usedInlines[placeholderValue] = savedInlinesToDeactived

        // Mark showed as active
        if let indexOfSavedInline: Int = usedInlines[placeholderValue]?.firstIndex(where: { $0.placeholderId == placeholder.id }) {
            if var savedInline = usedInlines[placeholderValue]?[indexOfSavedInline] {
                savedInline.isActive = true
                self._usedInlines.changeValue(with: { $0[placeholderValue]?[indexOfSavedInline] = savedInline })
            }
        }
    }

    private func load(placeholderId: String, indexPath: IndexPath, placeholdersNeedToRefresh: [InlineMessageResponse], isRefreshingExpired: Bool) {
        guard let ids = try? DatabaseManager().currentCustomer.ids else {
            return
        }
        DispatchQueue.global().async { [weak self] in
            guard let self else { return }
            self.provider.loadPersonalizedInlineMessages(
                 data: PersonalizedInlineMessageResponseData.self,
                 customerIds: ids,
                 inlineMessageIds: placeholdersNeedToRefresh.map { $0.id }
             ) { data in
                 let personalizedWithPayload: [PersonalizedInlineMessageResponse] = data.data?.data.compactMap { response in
                     var newInlineMessage = response
                     let normalizeConf = HtmlNormalizerConfig(
                         makeResourcesOffline: true,
                         ensureCloseButton: false,
                         allowAnchorButton: true
                     )
                     let normalizedPayload = HtmlNormalizer(newInlineMessage.content?.html ?? "").normalize(normalizeConf)
                     newInlineMessage.htmlPayload = normalizedPayload
                     return newInlineMessage
                 } ?? []
                 var updatedPlaceholders: [InlineMessageResponse] = self.inlinePlaceholders
                 for (index, inlineMessage) in updatedPlaceholders.enumerated() {
                     if var personalized = personalizedWithPayload.first(where: { $0.id == inlineMessage.id }) {
                         personalized.ttlSeen = Date()
                         updatedPlaceholders[index].personalizedMessage = personalized
                         updatedPlaceholders[index].indexPath = indexPath
                     }
                 }
                 self.inlinePlaceholders = updatedPlaceholders
                 let placehodlersToUse = self.inlinePlaceholders.filter { $0.placeholders.contains(placeholderId) }
                 for placeholder in placehodlersToUse {
                     let tag = self.createUniqueTag(placeholder: placeholder)
                     if let index: Int = self.inlinePlaceholders.firstIndex(where: { $0.id == placeholder.id }) {
                         self.inlinePlaceholders[index].tags?.insert(tag)
                     }
                     let usedInlineHeight = self.usedInlines[placeholderId]?.first(where: { $0.placeholderId == placeholder.id })?.height ?? 0
                     self.newUsedInline = .init(tag: tag, indexPath: indexPath, placeholderId: placeholder.id, placeholder: placeholderId, height: isRefreshingExpired ? 0 : usedInlineHeight)
                 }
             }
        }
    }

    public func prepareInlineView(
        placeholderId: String,
        indexPath: IndexPath
    ) -> UIView {
        let placehodlersToUse = inlinePlaceholders.filter { $0.placeholders.contains(placeholderId) }
        let placeholdersNeedToRefresh = placehodlersToUse.filter { $0.personalizedMessage == nil && $0.content?.html == nil }
        let expiredMessages = placehodlersToUse.filter { inlineMessage in
            if let ttlSeen = inlineMessage.personalizedMessage?.ttlSeen,
               let ttl = inlineMessage.personalizedMessage?.ttlSeconds,
               inlineMessage.content == nil {
                return Date() > ttlSeen.addingTimeInterval(TimeInterval(ttl))
            }
            return false
        }
        guard placeholdersNeedToRefresh.isEmpty && expiredMessages.isEmpty else {
            load(placeholderId: placeholderId, indexPath: indexPath, placeholdersNeedToRefresh: placehodlersToUse, isRefreshingExpired: !expiredMessages.isEmpty)
            return returnEmptyView(tag: Int.random(in: 0..<99999999))
        }

        // Found message
        guard var placeholder = filterPersonalizedMessages(input: placehodlersToUse.filter { $0.personalizedMessage?.status == .ok }) else {
            // No placeholders passed through filter. Then set all heights to 0 for the placeholderId
            var savedInlinesToDeactived = usedInlines[placeholderId] ?? []
            for (index, savedInline) in savedInlinesToDeactived.enumerated() {
                var currentSavedInline = savedInline
                currentSavedInline.isActive = false
                currentSavedInline.height = 0
                savedInlinesToDeactived[index] = currentSavedInline
            }
            usedInlines[placeholderId] = savedInlinesToDeactived
            return returnEmptyView(tag: Int.random(in: 0..<99999999))
        }

        // Add random for 100% unique
        let tag = createUniqueTag(placeholder: placeholder)

        // Update display status
        let indexOfPlaceholder: Int = inlinePlaceholders.firstIndex(where: { $0.id == placeholder.id }) ?? 0
        let currentDisplay = inlinePlaceholders[safeIndex: indexOfPlaceholder]?.displayState
        let state: InlineMessageDisplayStatus = .init(displayed: currentDisplay?.displayed ?? Date(), interacted: currentDisplay?.interacted)

        _inlinePlaceholders.changeValue(with: { $0[indexOfPlaceholder].tags?.insert(tag) })
        _inlinePlaceholders.changeValue(with: { $0[indexOfPlaceholder].indexPath = indexPath })

        placeholder.tags?.insert(tag)
        placeholder.displayState = state

        web = .init()
        web.tag = tag

        if let personalized = placeholder.personalizedMessage, let payloadData = personalized.htmlPayload?.html?.data(using: .utf8), !payloadData.isEmpty {
            if usedInlines[placeholderId] == nil {
                let usedInlineHeight = usedInlines[placeholderId]?.first(where: { $0.placeholderId == placeholder.id })?.height ?? 0
                self.newUsedInline = .init(tag: tag, indexPath: indexPath, placeholderId: placeholder.id, placeholder: placeholderId, height: 0)
            } else {
                if usedInlines[placeholderId]?.contains(where: { $0.placeholderId == placeholder.id }) == false {
                    let usedInlineHeight = usedInlines[placeholderId]?.first(where: { $0.placeholderId == placeholder.id })?.height ?? 0
                    self.newUsedInline = .init(tag: tag, indexPath: indexPath, placeholderId: placeholder.id, placeholder: placeholderId, height: 0)
                }
            }
            if inlinePlaceholders[indexOfPlaceholder].personalizedMessage?.ttlSeen == nil {
                _inlinePlaceholders.changeValue(with: { $0[indexOfPlaceholder].personalizedMessage?.ttlSeen = Date() })
            }
            if let html = personalized.htmlPayload?.html, !html.isEmpty {
                _inlinePlaceholders.changeValue(with: { $0[indexOfPlaceholder].displayState = state })
                web.navigationDelegate = self
                web.loadHTMLString(html, baseURL: nil)
                markInlineAsActive(placeholder: placeholder)
                return web
            } else {
                return returnEmptyView(tag: tag)
            }
        } else {
            if let html = placeholder.content?.html, !html.isEmpty {
                _inlinePlaceholders.changeValue(with: { $0[indexOfPlaceholder].displayState = state })
                web.navigationDelegate = self
                web.loadHTMLString(html, baseURL: nil)
                return web
            } else {
                return returnEmptyView(tag: tag)
            }
        }
    }

    public func prepareInlineStaticView(
        placeholderId: String
    ) -> StaticReturnData {
        let placehodlersToUse = inlinePlaceholders.filter { !$0.placeholders.filter { $0 == placeholderId }.isEmpty }
        let placeholdersNeedToRefresh = placehodlersToUse.filter { $0.personalizedMessage == nil && $0.content?.html == nil }
        let expiredMessages = placehodlersToUse.filter { inlineMessage in
            if let ttlSeen = inlineMessage.personalizedMessage?.ttlSeen,
               let ttl = inlineMessage.personalizedMessage?.ttlSeconds,
               inlineMessage.content == nil {
                return Date() > ttlSeen.addingTimeInterval(TimeInterval(ttl))
            }
            return false
        }

        guard placeholdersNeedToRefresh.isEmpty && expiredMessages.isEmpty else {
            return .init(html: "", tag: 0)
        }

        // Found message
        guard var placeholder = filterPersonalizedMessages(input: placehodlersToUse.filter { $0.personalizedMessage?.status == .ok }) else {
            return .init(html: "", tag: 0)
        }

        // Add random for 100% unique
        let tag = createUniqueTag(placeholder: placeholder)

        // Update display status
        let indexOfPlaceholder: Int = inlinePlaceholders.firstIndex(where: { $0.id == placeholder.id }) ?? 0
        let currentDisplay = inlinePlaceholders[safeIndex: indexOfPlaceholder]?.displayState
        let state: InlineMessageDisplayStatus = .init(displayed: currentDisplay?.displayed ?? Date(), interacted: currentDisplay?.interacted)
        placeholder.tags?.insert(tag)

        if let personalized = placeholder.personalizedMessage, let payloadData = personalized.htmlPayload?.html?.data(using: .utf8), !payloadData.isEmpty {
            if self.inlinePlaceholders[indexOfPlaceholder].personalizedMessage?.ttlSeen == nil {
                _inlinePlaceholders.changeValue(with: { $0[indexOfPlaceholder].personalizedMessage?.ttlSeen = Date() })
            }
            if let html = personalized.htmlPayload?.html, !html.isEmpty {
                placeholder.displayState = state
                _inlinePlaceholders.changeValue(with: { $0[indexOfPlaceholder] = placeholder })
                Exponea.shared.trackInlineMessageShow(message: placeholder)
                return .init(html: html, tag: tag)
            }
        } else {
            if let html = placeholder.content?.html, !html.isEmpty {
                placeholder.displayState = state
                _inlinePlaceholders.changeValue(with: { $0[indexOfPlaceholder] = placeholder })
                return .init(html: html, tag: tag)
            }
        }
        return .init(html: "", tag: 0)
    }

    public func loadInlinePlaceholders(completion: EmptyBlock?) {
        provider.getInlineMessages(
            data: InlineMessageDataResponse.self
        ) { [weak self] result in
            guard result.data?.success == true else { return }
            self?.inlinePlaceholders = result.data?.data ?? []
            completion?()
        }
    }
}

// Static inline
extension InlineMessageManager {
    private func continueWithStaticQueue() {
        isStaticUpdating = false
        if !staticQueue.isEmpty {
            let go = staticQueue.removeFirst()
            refreshStaticViewContent(staticQueueData: go)
        }
    }

    public func refreshStaticViewContent(staticQueueData: StaticQueueData) {
        if !isStaticUpdating {
            isStaticUpdating = true
            guard !staticQueueData.placeholderId.isEmpty, let ids = try? DatabaseManager().currentCustomer.ids else {
                staticQueueData.completion?(.init(html: "", tag: 0))
                return
            }
            let idsForDownload = inlinePlaceholders.filter { $0.placeholders.contains(staticQueueData.placeholderId) }.map { $0.id }
            provider.loadPersonalizedInlineMessages(
                data: PersonalizedInlineMessageResponseData.self,
                customerIds: ids,
                inlineMessageIds: idsForDownload
            ) { [weak self] data in
                guard let self else { return }
                let personalizedWithPayload: [PersonalizedInlineMessageResponse] = data.data?.data.compactMap { response in
                    var newInlineMessage = response
                    let normalizeConf = HtmlNormalizerConfig(
                        makeResourcesOffline: true,
                        ensureCloseButton: false,
                        allowAnchorButton: true
                    )
                    let normalizedPayload = HtmlNormalizer(newInlineMessage.content?.html ?? "").normalize(normalizeConf)
                    newInlineMessage.htmlPayload = normalizedPayload
                    return newInlineMessage
                } ?? []
                var updatedPlaceholders: [InlineMessageResponse] = self.inlinePlaceholders
                for (index, inlineMessage) in updatedPlaceholders.enumerated() {
                    if var personalized = personalizedWithPayload.first(where: { $0.id == inlineMessage.id }) {
                        personalized.ttlSeen = Date()
                        updatedPlaceholders[index].personalizedMessage = personalized
                    }
                }
                self.inlinePlaceholders = updatedPlaceholders
                let data = self.prepareInlineStaticView(placeholderId: staticQueueData.placeholderId)
                staticQueueData.completion?(data)
                self.continueWithStaticQueue()
            }
        } else {
            _staticQueue.changeValue(with: { $0.append(staticQueueData) })
        }
    }
}

// Synchro
private extension InlineMessageManager {
    func continueWithQueue() {
        isUpdating = false
        if !queue.isEmpty {
            let go = queue.removeFirst()
            loadContentForPlacehoder(newValue: go.newValue, placeholder: go.inline)
        }
    }

    func loadContentForPlacehoder(newValue: UsedInline, placeholder: InlineMessageResponse) {
        if !isUpdating {
            isUpdating = true
            let savedNewValue = newValue
            let savedPlaceholder = placeholder
            loadPersonalizedInlineMessage(for: savedNewValue.placeholderId, tags: [savedNewValue.tag]) {
                self.calculator = .init()
                self.calculator.heightUpdate = { height in
                    let placeholderValueFromUsedLine = savedNewValue.placeholder
                    let savedInlinesToDeactived = self.usedInlines[placeholderValueFromUsedLine] ?? []
                    guard let indexPath = placeholder.indexPath else { return }
                    if savedInlinesToDeactived.isEmpty {
                        self._usedInlines.changeValue { store in
                            let newSavedInline: UsedInline = .init(tag: savedNewValue.tag, indexPath: indexPath, placeholderId: savedPlaceholder.id, placeholder: savedNewValue.placeholder, height: height.height)
                            if store[placeholderValueFromUsedLine] == nil {
                                store[placeholderValueFromUsedLine] = [newSavedInline]
                            } else if store[placeholderValueFromUsedLine]?.isEmpty == true {
                                store[placeholderValueFromUsedLine]?.append(newSavedInline)
                            }
                        }
                        self.continueWithQueue()
                        if let path = savedPlaceholder.indexPath {
                            self.calculator.heightUpdate = nil
                            self.refreshCallback?(path)
                        }
                    } else {
                        if let indexOfSavedInline: Int = self.usedInlines[placeholderValueFromUsedLine]?.firstIndex(where: { $0.placeholderId == savedPlaceholder.id && $0.height == 0 }) {
                            if var savedInline = self.usedInlines[placeholderValueFromUsedLine]?[indexOfSavedInline] {
                                if savedInline.height == 0 {
                                    savedInline.height = height.height
                                }
                                self._usedInlines.changeValue(with: { $0[placeholderValueFromUsedLine]?.insert(savedInline, at: indexOfSavedInline) })
                            }
                        } else {
                            let newSavedInline: UsedInline = .init(tag: savedNewValue.tag, indexPath: indexPath, placeholderId: savedPlaceholder.id, placeholder: savedNewValue.placeholder, height: height.height)
                            self._usedInlines.changeValue { store in
                                store[placeholderValueFromUsedLine]?.append(newSavedInline)
                            }
                        }
                        self.continueWithQueue()
                        if let path = savedPlaceholder.indexPath {
                            self.calculator.heightUpdate = nil
                            self.refreshCallback?(path)
                        }
                    }
                }
                guard let html = self.inlinePlaceholders.first(where: { $0.tags?.contains(newValue.tag) == true })?.personalizedMessage?.htmlPayload?.html, !html.isEmpty else {
                    self.isUpdating = false
                    if !self.queue.isEmpty {
                        let go = self.queue[0]
                        self.loadContentForPlacehoder(newValue: go.newValue, placeholder: go.inline)
                    }
                    return
                }
                self.calculator.loadHtml(placedholderId: placeholder.id, html: html)
            }
        } else {
            _queue.changeValue(with: { $0.append(.init(inline: placeholder, newValue: newValue)) })
        }
    }
}

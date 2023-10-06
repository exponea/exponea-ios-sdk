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
    @Atomic var inAppContentBlocksPlaceholders: [InAppContentBlockResponse] = []
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
    @Atomic private var queue: [QueueData] = []
    @Atomic private var staticQueue: [StaticQueueData] = []
    private var newUsedInAppContentBlocks: UsedInAppContentBlocks? {
        willSet {
            guard let newValue, let placeholder = inAppContentBlocksPlaceholders.first(where: { $0.tags?.contains(newValue.tag) == true }) else { return }
            if placeholder.content == nil, newValue.height == 0 {
                loadContentForPlacehoder(newValue: newValue, placeholder: placeholder)
            } else if let html = placeholder.content?.html, newValue.height == 0 {
                calculator = .init()
                calculator.heightUpdate = { [weak self] height in
                    guard let self else { return }
                    self.calculateStaticData(height: height, newValue: newValue, placeholder: placeholder)
                }
                calculator.loadHtml(placedholderId: newValue.placeholderId, html: html)
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
        usedInAppContentBlocks[placeholder]?.first(where: { $0.isActive })
    }

    func anonymize() {
        usedInAppContentBlocks.removeAll()
        inAppContentBlocksPlaceholders.removeAll()
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        let result = inAppContentBlocksPlaceholders.first(where: { $0.tags?.contains(webView.tag) == true })
        let webAction: WebActionManager = .init {
            let indexOfPlaceholder: Int = self.inAppContentBlocksPlaceholders.firstIndex(where: { $0.id == result?.id ?? "" }) ?? 0
            let currentDisplay = self.inAppContentBlocksPlaceholders[indexOfPlaceholder].displayState
            self.inAppContentBlocksPlaceholders[indexOfPlaceholder].displayState = .init(displayed: currentDisplay?.displayed, interacted: Date())
            if let message = result {
                Exponea.shared.trackInAppContentBlocksClose(message: message, isUserInteraction: true)
            }
            if let path = result?.indexPath {
                self.refreshCallback?(path)
            }
        } onActionCallback: { action in
            let indexOfPlaceholder: Int = self.inAppContentBlocksPlaceholders.firstIndex(where: { $0.id == result?.id ?? "" }) ?? 0
            let currentDisplay = self.inAppContentBlocksPlaceholders[indexOfPlaceholder].displayState
            self.inAppContentBlocksPlaceholders[indexOfPlaceholder].displayState = .init(displayed: currentDisplay?.displayed, interacted: Date())
            if let message = result {
                Exponea.shared.trackInAppContentBlocksClick(message: message, buttonText: action.buttonText, buttonLink: action.actionUrl)
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
                self?.newUsedInAppContentBlocks = .init(tag: webView.tag, indexPath: indexPath, placeholderId: "", placeholder: "", height: webView.scrollView.contentSize.height + 10)
            }
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
        var updatedPlaceholders: [InAppContentBlockResponse] = self.inAppContentBlocksPlaceholders
        for (index, inAppContentBlocks) in updatedPlaceholders.enumerated() {
            if var personalized = personalizedWithPayload.first(where: { $0.id == inAppContentBlocks.id }) {
                personalized.ttlSeen = Date()
                updatedPlaceholders[index].personalizedMessage = personalized
            }
        }
        self.inAppContentBlocksPlaceholders = updatedPlaceholders
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
            inAppContentBlocksIds: prefetchPlaceholdersWithIds(input: inAppContentBlocksPlaceholders, ids: ids).map { $0.id }
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
            var updatedPlaceholders: [InAppContentBlockResponse] = self.inAppContentBlocksPlaceholders
            for (index, inAppContentBlocks) in updatedPlaceholders.enumerated() {
                if var personalized = personalizedWithPayload?.first(where: { $0.id == inAppContentBlocks.id }) {
                    personalized.ttlSeen = Date()
                    updatedPlaceholders[index].personalizedMessage = personalized
                }
            }
            self.inAppContentBlocksPlaceholders = updatedPlaceholders
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

    func prepareInAppContentBlockView(
        placeholderId: String,
        indexPath: IndexPath
    ) -> UIView {
        let placehodlersToUse = inAppContentBlocksPlaceholders.filter { $0.placeholders.contains(placeholderId) }
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
            load(placeholderId: placeholderId, indexPath: indexPath, placeholdersNeedToRefresh: placehodlersToUse, isRefreshingExpired: !expiredMessages.isEmpty)
            return returnEmptyView(tag: Int.random(in: 0..<99999999))
        }

        // Found message
        guard var placeholder = filterPersonalizedMessages(input: placehodlersToUse.filter { $0.personalizedMessage?.status == .ok }) else {
            // No placeholders passed through filter. Then set all heights to 0 for the placeholderId
            var savedInAppContentBlocksToDeactived = usedInAppContentBlocks[placeholderId] ?? []
            for (index, savedInAppContentBlocks) in savedInAppContentBlocksToDeactived.enumerated() {
                var currentSavedInAppContentBlocks = savedInAppContentBlocks
                currentSavedInAppContentBlocks.isActive = false
                currentSavedInAppContentBlocks.height = 0
                savedInAppContentBlocksToDeactived[index] = currentSavedInAppContentBlocks
            }
            usedInAppContentBlocks[placeholderId] = savedInAppContentBlocksToDeactived
            return returnEmptyView(tag: Int.random(in: 0..<99999999))
        }

        // Add random for 100% unique
        let tag = createUniqueTag(placeholder: placeholder)

        // Update display status
        let indexOfPlaceholder: Int = inAppContentBlocksPlaceholders.firstIndex(where: { $0.id == placeholder.id }) ?? 0
        let currentDisplay = inAppContentBlocksPlaceholders[safeIndex: indexOfPlaceholder]?.displayState
        let state: InAppContentBlocksDisplayStatus = .init(displayed: currentDisplay?.displayed ?? Date(), interacted: currentDisplay?.interacted)

        _inAppContentBlocksPlaceholders.changeValue(with: { $0[indexOfPlaceholder].tags?.insert(tag) })
        _inAppContentBlocksPlaceholders.changeValue(with: { $0[indexOfPlaceholder].indexPath = indexPath })

        placeholder.tags?.insert(tag)
        placeholder.displayState = state

        web = .init()
        web.tag = tag
        web.navigationDelegate = self

        if usedInAppContentBlocks[placeholderId] == nil {
            self.newUsedInAppContentBlocks = .init(tag: tag, indexPath: indexPath, placeholderId: placeholder.id, placeholder: placeholderId, height: 0)
        } else {
            if usedInAppContentBlocks[placeholderId]?.contains(where: { $0.placeholderId == placeholder.id }) == false {
                self.newUsedInAppContentBlocks = .init(tag: tag, indexPath: indexPath, placeholderId: placeholder.id, placeholder: placeholderId, height: 0)
            }
        }

        if let html = placeholder.content?.html, !html.isEmpty {
            if inAppContentBlocksPlaceholders[indexOfPlaceholder].normalizedHtml == nil {
                let normalizeConf = HtmlNormalizerConfig(
                    makeResourcesOffline: true,
                    ensureCloseButton: false
                )
                let normalizedPayload = HtmlNormalizer(html).normalize(normalizeConf)
                inAppContentBlocksPlaceholders[indexOfPlaceholder].normalizedHtml = normalizedPayload.html
            }
            let finalHTML = inAppContentBlocksPlaceholders[indexOfPlaceholder].normalizedHtml ?? html
            if inAppContentBlocksPlaceholders[indexOfPlaceholder].personalizedMessage?.ttlSeen == nil {
                _inAppContentBlocksPlaceholders.changeValue(with: { $0[indexOfPlaceholder].personalizedMessage?.ttlSeen = Date() })
            }
            _inAppContentBlocksPlaceholders.changeValue(with: { $0[indexOfPlaceholder].displayState = state })
            web.loadHTMLString(finalHTML, baseURL: nil)
            markInAppContentBlocksAsActive(placeholder: placeholder)
            return web
        } else if let personalized = placeholder.personalizedMessage, let payloadData = personalized.htmlPayload?.html?.data(using: .utf8), !payloadData.isEmpty {
            if inAppContentBlocksPlaceholders[indexOfPlaceholder].personalizedMessage?.ttlSeen == nil {
                _inAppContentBlocksPlaceholders.changeValue(with: { $0[indexOfPlaceholder].personalizedMessage?.ttlSeen = Date() })
            }
            if let html = personalized.htmlPayload?.html, !html.isEmpty {
                _inAppContentBlocksPlaceholders.changeValue(with: { $0[indexOfPlaceholder].displayState = state })
                web.loadHTMLString(html, baseURL: nil)
                markInAppContentBlocksAsActive(placeholder: placeholder)
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
        let placehodlersToUse = inAppContentBlocksPlaceholders.filter { !$0.placeholders.filter { $0 == placeholderId }.isEmpty }
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
            return .init(html: "", tag: 0)
        }

        // Found message
        guard var placeholder = filterPersonalizedMessages(input: placehodlersToUse.filter { $0.personalizedMessage?.status == .ok }) else {
            return .init(html: "", tag: 0)
        }

        // Add random for 100% unique
        let tag = createUniqueTag(placeholder: placeholder)

        // Update display status
        let indexOfPlaceholder: Int = inAppContentBlocksPlaceholders.firstIndex(where: { $0.id == placeholder.id }) ?? 0
        let currentDisplay = inAppContentBlocksPlaceholders[safeIndex: indexOfPlaceholder]?.displayState
        let state: InAppContentBlocksDisplayStatus = .init(displayed: currentDisplay?.displayed ?? Date(), interacted: currentDisplay?.interacted)
        placeholder.tags?.insert(tag)

        if let personalized = placeholder.personalizedMessage, let payloadData = personalized.htmlPayload?.html?.data(using: .utf8), !payloadData.isEmpty {
            if self.inAppContentBlocksPlaceholders[indexOfPlaceholder].personalizedMessage?.ttlSeen == nil {
                _inAppContentBlocksPlaceholders.changeValue(with: { $0[indexOfPlaceholder].personalizedMessage?.ttlSeen = Date() })
            }
            if let html = personalized.htmlPayload?.html, !html.isEmpty {
                placeholder.displayState = state
                _inAppContentBlocksPlaceholders.changeValue(with: { $0[indexOfPlaceholder] = placeholder })
                Exponea.shared.trackInAppContentBlocksShow(message: placeholder)
                return .init(html: html, tag: tag)
            }
        } else {
            if let html = placeholder.content?.html, !html.isEmpty {
                placeholder.displayState = state
                _inAppContentBlocksPlaceholders.changeValue(with: { $0[indexOfPlaceholder] = placeholder })
                return .init(html: html, tag: tag)
            }
        }
        return .init(html: "", tag: 0)
    }

    func loadInAppContentBlocksPlaceholders(completion: EmptyBlock?) {
        provider.getInAppContentBlocks(
            data: InAppContentBlocksDataResponse.self
        ) { [weak self] result in
            guard result.data?.success == true else { return }
            self?.inAppContentBlocksPlaceholders = result.data?.data ?? []
            completion?()
        }
    }
}

private extension InAppContentBlocksManager {
    func loadPersonalizedInAppContentBlocks(for placeholderId: String, tags: Set<Int>, completion: EmptyBlock?) {
        guard !placeholderId.isEmpty, let ids = try? DatabaseManager().currentCustomer.ids else {
            return
        }
        DispatchQueue.global().async {
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
        if let existingTag = usedInAppContentBlocks[placeholder.placeholders.first ?? ""]?.first(where: { placeholder.id == $0.placeholderId })?.tag {
            return existingTag
        } else {
            return Int.random(in: 0..<99999999)
        }
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

    func markInAppContentBlocksAsActive(placeholder: InAppContentBlockResponse) {
        Exponea.shared.trackInAppContentBlocksShow(message: placeholder)
        let placeholderValue = placeholder.placeholders.first ?? ""
        var savedInAppContentBlocksToDeactived = usedInAppContentBlocks[placeholderValue] ?? []

        // Mark all as inactive
        for (index, savedInAppContentBlocks) in savedInAppContentBlocksToDeactived.enumerated() {
            var currentSavedInAppContentBlocks = savedInAppContentBlocks
            currentSavedInAppContentBlocks.isActive = false
            savedInAppContentBlocksToDeactived[index] = currentSavedInAppContentBlocks
        }
        usedInAppContentBlocks[placeholderValue] = savedInAppContentBlocksToDeactived

        // Mark showed as active
        if let indexOfSavedInAppContentBlocks: Int = usedInAppContentBlocks[placeholderValue]?.firstIndex(where: { $0.placeholderId == placeholder.id }) {
            if var savedInAppContentBlocks = usedInAppContentBlocks[placeholderValue]?[indexOfSavedInAppContentBlocks] {
                savedInAppContentBlocks.isActive = true
                self._usedInAppContentBlocks.changeValue(with: { $0[placeholderValue]?[indexOfSavedInAppContentBlocks] = savedInAppContentBlocks })
            }
        }
    }

    func load(placeholderId: String, indexPath: IndexPath, placeholdersNeedToRefresh: [InAppContentBlockResponse], isRefreshingExpired: Bool) {
        guard let ids = try? DatabaseManager().currentCustomer.ids else {
            return
        }
        DispatchQueue.global().async { [weak self] in
            guard let self else { return }
            self.provider.loadPersonalizedInAppContentBlocks(
                data: PersonalizedInAppContentBlockResponseData.self,
                customerIds: ids,
                inAppContentBlocksIds: placeholdersNeedToRefresh.map { $0.id }
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
                var updatedPlaceholders: [InAppContentBlockResponse] = self.inAppContentBlocksPlaceholders
                for (index, inAppContentBlocks) in updatedPlaceholders.enumerated() {
                    if var personalized = personalizedWithPayload.first(where: { $0.id == inAppContentBlocks.id }) {
                        personalized.ttlSeen = Date()
                        updatedPlaceholders[index].personalizedMessage = personalized
                        updatedPlaceholders[index].indexPath = indexPath
                    }
                }
                self.inAppContentBlocksPlaceholders = updatedPlaceholders
                let placehodlersToUse = self.inAppContentBlocksPlaceholders.filter { $0.placeholders.contains(placeholderId) }
                for placeholder in placehodlersToUse {
                    let tag = self.createUniqueTag(placeholder: placeholder)
                    if let index: Int = self.inAppContentBlocksPlaceholders.firstIndex(where: { $0.id == placeholder.id }) {
                        self.inAppContentBlocksPlaceholders[index].tags?.insert(tag)
                    }
                    let usedInAppContentBlocksHeight = self.usedInAppContentBlocks[placeholderId]?.first(where: { $0.placeholderId == placeholder.id })?.height ?? 0
                    self.newUsedInAppContentBlocks = .init(tag: tag, indexPath: indexPath, placeholderId: placeholder.id, placeholder: placeholderId, height: isRefreshingExpired ? 0 : usedInAppContentBlocksHeight)
                }
            }
        }
    }

    func calculateStaticData(height: CalculatorData, newValue: UsedInAppContentBlocks, placeholder: InAppContentBlockResponse) {
        let savedNewValue = newValue
        let placeholderValueFromUsedLine = savedNewValue.placeholder
        let savedInAppContentBlocksToDeactived = self.usedInAppContentBlocks[placeholderValueFromUsedLine] ?? []
        guard let indexPath = placeholder.indexPath else { return }
        if savedInAppContentBlocksToDeactived.isEmpty {
            self._usedInAppContentBlocks.changeValue { store in
                let newSavedInAppContentBlocks: UsedInAppContentBlocks = .init(tag: savedNewValue.tag, indexPath: indexPath, placeholderId: savedNewValue.placeholderId, placeholder: savedNewValue.placeholder, height: height.height)
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
            if let indexOfSavedInAppContentBlocks: Int = self.usedInAppContentBlocks[placeholderValueFromUsedLine]?.firstIndex(where: { $0.placeholderId == savedNewValue.placeholderId && $0.height == 0 }) {
                if var savedInAppContentBlocks = self.usedInAppContentBlocks[placeholderValueFromUsedLine]?[indexOfSavedInAppContentBlocks] {
                    if savedInAppContentBlocks.height == 0 {
                        savedInAppContentBlocks.height = height.height
                    }
                    self._usedInAppContentBlocks.changeValue(with: { $0[placeholderValueFromUsedLine]?.insert(savedInAppContentBlocks, at: indexOfSavedInAppContentBlocks) })
                }
            } else {
                let newSavedInAppContentBlocks: UsedInAppContentBlocks = .init(tag: savedNewValue.tag, indexPath: indexPath, placeholderId: savedNewValue.placeholderId, placeholder: savedNewValue.placeholder, height: height.height)
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
                staticQueueData.completion?(.init(html: "", tag: 0))
                return
            }
            let idsForDownload = inAppContentBlocksPlaceholders.filter { $0.placeholders.contains(staticQueueData.placeholderId) }.map { $0.id }
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
                var updatedPlaceholders: [InAppContentBlockResponse] = self.inAppContentBlocksPlaceholders
                for (index, inAppContentBlocks) in updatedPlaceholders.enumerated() {
                    if var personalized = personalizedWithPayload.first(where: { $0.id == inAppContentBlocks.id }) {
                        personalized.ttlSeen = Date()
                        updatedPlaceholders[index].personalizedMessage = personalized
                    }
                }
                self.inAppContentBlocksPlaceholders = updatedPlaceholders
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
            loadPersonalizedInAppContentBlocks(for: savedNewValue.placeholderId, tags: [savedNewValue.tag]) {
                self.calculator = .init()
                self.calculator.heightUpdate = { height in
                    let placeholderValueFromUsedLine = savedNewValue.placeholder
                    let savedInAppContentBlocksToDeactived = self.usedInAppContentBlocks[placeholderValueFromUsedLine] ?? []
                    guard let indexPath = placeholder.indexPath else { return }
                    if savedInAppContentBlocksToDeactived.isEmpty {
                        self._usedInAppContentBlocks.changeValue { store in
                            let newSavedInAppContentBlocks: UsedInAppContentBlocks = .init(tag: savedNewValue.tag, indexPath: indexPath, placeholderId: savedPlaceholder.id, placeholder: savedNewValue.placeholder, height: height.height)
                            if store[placeholderValueFromUsedLine] == nil {
                                store[placeholderValueFromUsedLine] = [newSavedInAppContentBlocks]
                            } else if store[placeholderValueFromUsedLine]?.isEmpty == true {
                                store[placeholderValueFromUsedLine]?.append(newSavedInAppContentBlocks)
                            }
                        }
                        self.continueWithQueue()
                        if let path = savedPlaceholder.indexPath {
                            self.calculator.heightUpdate = nil
                            self.refreshCallback?(path)
                        }
                    } else {
                        if let indexOfSavedInAppContentBlocks: Int = self.usedInAppContentBlocks[placeholderValueFromUsedLine]?.firstIndex(where: { $0.placeholderId == savedPlaceholder.id && $0.height == 0 }) {
                            if var savedInAppContentBlocks = self.usedInAppContentBlocks[placeholderValueFromUsedLine]?[indexOfSavedInAppContentBlocks] {
                                if savedInAppContentBlocks.height == 0 {
                                    savedInAppContentBlocks.height = height.height
                                }
                                self._usedInAppContentBlocks.changeValue(with: { $0[placeholderValueFromUsedLine]?.insert(savedInAppContentBlocks, at: indexOfSavedInAppContentBlocks) })
                            }
                        } else {
                            let newSavedInAppContentBlocks: UsedInAppContentBlocks = .init(tag: savedNewValue.tag, indexPath: indexPath, placeholderId: savedPlaceholder.id, placeholder: savedNewValue.placeholder, height: height.height)
                            self._usedInAppContentBlocks.changeValue { store in
                                store[placeholderValueFromUsedLine]?.append(newSavedInAppContentBlocks)
                            }
                        }
                        self.continueWithQueue()
                        if let path = savedPlaceholder.indexPath {
                            self.calculator.heightUpdate = nil
                            self.refreshCallback?(path)
                        }
                    }
                }
                guard let html = self.inAppContentBlocksPlaceholders.first(where: { $0.tags?.contains(newValue.tag) == true })?.personalizedMessage?.htmlPayload?.html, !html.isEmpty else {
                    self.isUpdating = false
                    if !self.queue.isEmpty {
                        let go = self.queue[0]
                        self.loadContentForPlacehoder(newValue: go.newValue, placeholder: go.inAppContentBlocks)
                    }
                    return
                }
                self.calculator.loadHtml(placedholderId: placeholder.id, html: html)
            }
        } else {
            _queue.changeValue(with: { $0.append(.init(inAppContentBlocks: placeholder, newValue: newValue)) })
        }
    }
}

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
        },
        {
            "trigger": {
                "url-filter": "^exponea-cache://.*"
            },
            "action": {
                "type": "ignore-previous-rules"
            }
        }]
    """
    var contentRuleList: WKContentRuleList?

    private var isStaticUpdating = false
    private var isUpdating = false
    private var isLoadUpdating = false
    private var isCarouselLoading = false
    private let carouselValidationQueue = DispatchQueue(
        label: "com.exponea.ExponeaSDK.inappcontentblocks.carouselvalidation",
        qos: .utility,
        attributes: .concurrent
    )
    private let maxImageValidationConcurrency = 4
    private let maxCarouselValidationConcurrency = 2
    private let imageValidationTimeout: TimeInterval = 10
    private let renderResourcePreloader = HtmlRenderResourcePreloader()
    // Per-placeholder validation tokens. Multiple `CarouselInAppContentBlockView`s may load in parallel,
    // so cancellation must be scoped per placeholder to avoid concurrent carousels invalidating each other.
    @Atomic var carouselValidationTokens: [String: UUID] = [:]
    // Per-placeholder in-flight dedup state. Without this, two back-to-back reload()
    // calls for the same placeholder would issue two identical personalization POSTs.
    // Second and later callers attach as waiters on the first in-flight fetch rather
    // than issue a duplicate provider call. The record's `validationToken` anchors
    // the completion to THIS fetch so a late-arriving callback from a superseded run
    // cannot consume a newer run's waiters.
    @Atomic var carouselInFlightFetches: [String: CarouselInFlightFetch] = [:]
    @Atomic private var queue: [QueueData] = []
    @Atomic private var loadQueue: [QueueLoadData] = []
    private var staticQueue: [StaticQueueData] = []
    @Atomic private var carouselQueue: [String] = []
    @Atomic var imageValidationStates: [String: ImageValidationState] = [:]
    @Atomic private var heightCalculationMessageByPlaceholder: [String: String] = [:]
    @Atomic private var cacheGeneration: UInt = 0
    private let catalogStateLock = NSLock()
    private var catalogState: CatalogState = .dirty
    private var catalogWaiters: [(Bool) -> Void] = []

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
    private let provider: InAppContentBlocksDataProviderType & InAppContentBlocksETagDataProviding
    private let etagStore: InAppContentBlocksETagStore
    private let batchKeyIndexLock = NSLock()
    private var _batchKeysByPlaceholder: [String: Set<String>] = [:]
    @Atomic private var coalescedRefreshKeys: Set<String> = []
    private var didWarmHeightCalculator = false
    private let maxPreparedContentBlockWebViews = 2
    private var preparedContentBlockWebViews: [WKWebView] = []
    private var issuedContentBlockWebViews: [WeakWKWebView] = []
    private var isContentBlockWebViewWarmupScheduled = false
    private let maxPreparedStaticHeightCalculators = 1
    private var preparedStaticHeightCalculators: [WKWebViewHeightCalculator] = []
    private var warmingStaticHeightCalculator: WKWebViewHeightCalculator?
    private var isStaticHeightCalculatorWarmupScheduled = false

    private func clearAllETags() {
        etagStore.clearAll()
        batchKeyIndexLock.withLock { _batchKeysByPlaceholder.removeAll() }
    }

    private func warmHeightCalculator() {
        onMain { [weak self] in
            guard let self, !self.didWarmHeightCalculator else { return }
            self.didWarmHeightCalculator = true
            guard self.calculator.heightUpdate == nil else {
                return
            }
            self.calculator.heightUpdate = { [weak self] _ in
                guard let self else { return }
                self.calculator.heightUpdate = nil
            }
            self.calculator.loadHtml(
                placedholderId: "heightCalculatorWarmup",
                html: "<html><body style=\"margin:0\"></body></html>"
            )
        }
    }

    private func prepareNormalizedHtmlPayload(
        html: String,
        makeResourcesOffline: Bool,
        ensureCloseButton: Bool = false
    ) -> NormalizedResult? {
        renderResourcePreloader.prepareNormalizedHtml(html: html, config: HtmlNormalizerConfig(
            makeResourcesOffline: makeResourcesOffline,
            ensureCloseButton: ensureCloseButton
        ))
    }

    private func preparePersonalizedResponseForRender(
        _ response: PersonalizedInAppContentBlockResponse,
        makeResourcesOffline: Bool
    ) -> PersonalizedInAppContentBlockResponse {
        var newInAppContentBlocks = response
        guard response.status == .ok,
              let html = response.content?.html,
              !html.isEmpty else {
            return newInAppContentBlocks
        }
        guard let normalizedPayload = prepareNormalizedHtmlPayload(
            html: html,
            makeResourcesOffline: makeResourcesOffline,
            ensureCloseButton: false
        ) else {
            newInAppContentBlocks.htmlPayload = nil
            newInAppContentBlocks.isCorruptedImage = true
            return newInAppContentBlocks
        }
        newInAppContentBlocks.htmlPayload = normalizedPayload
        newInAppContentBlocks.isCorruptedImage = false
        return newInAppContentBlocks
    }

    private func notifyRefreshCallback(
        indexPath: IndexPath,
        source: String,
        placeholder: String?
    ) {
        if shouldCoalesceRefreshCallback(source: source) {
            let coalescingKey = makeRefreshCoalescingKey(indexPath: indexPath, placeholder: placeholder)
            var inserted = false
            _coalescedRefreshKeys.changeValue { keys in
                if !keys.contains(coalescingKey) {
                    keys.insert(coalescingKey)
                    inserted = true
                }
            }
            if !inserted {
                return
            }
        }
        refreshCallback?(indexPath)
    }

    private func shouldCoalesceRefreshCallback(source: String) -> Bool {
        source.hasPrefix("loadContentForPlaceholder") || source.hasPrefix("calculateStaticData")
    }

    private func makeRefreshCoalescingKey(indexPath: IndexPath, placeholder: String?) -> String {
        "\(placeholder ?? "n/a")|\(indexPath.section):\(indexPath.row)"
    }

    private func clearRefreshCoalescingIfIdle() {
        let isIdle = !isLoadUpdating && !isUpdating && loadQueue.isEmpty && queue.isEmpty
        guard isIdle else { return }
        _coalescedRefreshKeys.changeValue { keys in
            keys.removeAll()
        }
    }

    private func clearHeightCalculationSelectionIfIdle() {
        let isIdle = !isUpdating && queue.isEmpty
        guard isIdle else { return }
        _heightCalculationMessageByPlaceholder.changeValue { selections in
            selections.removeAll()
        }
    }

    private func queueDedupKey(for data: QueueData) -> String {
        "\(data.newValue.placeholder)|\(data.newValue.indexPath.section):\(data.newValue.indexPath.row)|\(data.newValue.messageId)"
    }

    private func queueCellDedupKey(for data: QueueData) -> String {
        "\(data.newValue.placeholder)|\(data.newValue.indexPath.section):\(data.newValue.indexPath.row)"
    }

    private func loadQueueDedupKey(for data: QueueLoadData) -> String {
        "\(data.placeholder)|\(data.indexPath.section):\(data.indexPath.row)"
    }

    enum QueueDedupResult {
        case duplicate
        case replacedPendingCell
        case enqueued
    }

    @discardableResult
    func dedupEnqueue(message: InAppContentBlockResponse, newValue: UsedInAppContentBlocks) -> QueueDedupResult {
        let queuedItem = QueueData(inAppContentBlocks: message, newValue: newValue)
        let dedupKey = queueDedupKey(for: queuedItem)
        let cellDedupKey = queueCellDedupKey(for: queuedItem)
        var result: QueueDedupResult = .duplicate
        _queue.changeValue { queue in
            if queue.contains(where: { self.queueDedupKey(for: $0) == dedupKey }) {
                result = .duplicate
            } else if let existingCellIndex = queue.firstIndex(where: { self.queueCellDedupKey(for: $0) == cellDedupKey }) {
                queue[existingCellIndex] = queuedItem
                result = .replacedPendingCell
            } else {
                queue.append(queuedItem)
                result = .enqueued
            }
        }
        return result
    }

    // MARK: - Init
    override init() {
        self.provider = InAppContentBlocksDataProvider()
        self.etagStore = UserDefaultsETagStore()
        super.init()
        commonInit()
    }

    init(
        provider: InAppContentBlocksDataProviderType & InAppContentBlocksETagDataProviding,
        etagStore: InAppContentBlocksETagStore
    ) {
        self.provider = provider
        self.etagStore = etagStore
        super.init()
        commonInit()
    }

    private func commonInit() {
        _usedInAppContentBlocks.changeValue(with: { $0.removeAll() })

        IntegrationManager.shared.onIntegrationStoppedCallbacks.append { [weak self] in
            guard let self else { return }
            self._cacheGeneration.changeValue { $0 &+= 1 }
            self.markCatalogDirty()
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
            self._imageValidationStates.changeValue(with: { $0.removeAll() })
            self._carouselValidationTokens.changeValue(with: { $0.removeAll() })
            self._coalescedRefreshKeys.changeValue(with: { $0.removeAll() })
            self._heightCalculationMessageByPlaceholder.changeValue(with: { $0.removeAll() })
            self.clearPreparedContentBlockWebViews()
            // Drop in-flight carousel dedup records; outstanding callbacks no-op at the token guard.
            self._carouselInFlightFetches.changeValue(with: { $0.removeAll() })
            // Clear ETags so the next session does not send stale If-None-Match headers.
            self.clearAllETags()
        }
    }

    internal func addMessage(_ message: InAppContentBlockResponse) {
        _inAppContentBlockMessages.changeValue { $0.append(message) }
    }

    internal func onEventOccurred(of type: EventType, for event: [DataType]) {
        // Identity-change clearing is handled directly via onCustomerIdentified(), called
        // synchronously in the identifyCustomer path. Handling it here as well would fire after
        // an async flush in .immediate mode, creating a race window, and would also cause a
        // double cacheGeneration bump that discards valid in-flight requests for the new customer.
    }

    internal func onCustomerIdentified() {
        Exponea.logger.log(.verbose, message: "CustomerIDs are updated, invalidating In-app Content Blocks personalised cache")
        clearPersonalisedContent()
        clearAllETags()
    }

    /// Bumps `cacheGeneration` to fence off in-flight personalisation responses and clears all
    /// per-message personalised payloads and display-state caches. The catalog (message list) and
    /// ETag store are left intact and are cleared by their own dedicated paths.
    private func clearPersonalisedContent() {
        _cacheGeneration.changeValue { $0 &+= 1 }
        _inAppContentBlockMessages.changeValue { messages in
            for index in messages.indices {
                messages[index].personalizedMessage = nil
                messages[index].normalizedResult = nil
            }
        }
        _usedInAppContentBlocks.changeValue { $0.removeAll() }
        _heightCalculationMessageByPlaceholder.changeValue { $0.removeAll() }
    }

    func initBlocker() {
        initBlocker(completion: nil)
    }

    func initBlocker(completion: EmptyBlock?) {
        onMain {
            WKContentRuleListStore.default().compileContentRuleList(
                forIdentifier: "ContentBlockingRules",
                encodedContentRuleList: self.blockRules
            ) { contentRuleList, error in
                if error == nil {
                    self.contentRuleList = contentRuleList
                }
                completion?()
            }
        }
    }

    private var calculatorKey: String = "key_calculator"
    var calculator: WKWebViewHeightCalculator {
        get {
            if let calculator = objc_getAssociatedObject(self, &calculatorKey) as? WKWebViewHeightCalculator {
                return calculator
            }
            let calculator = WKWebViewHeightCalculator()
            objc_setAssociatedObject(self, &calculatorKey, calculator, .OBJC_ASSOCIATION_RETAIN)
            return calculator
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

private final class WeakWKWebView {
    weak var value: WKWebView?

    init(_ value: WKWebView) {
        self.value = value
    }
}

extension InAppContentBlocksManager {
    func prewarmReusableContentBlockResourcesForStartup() {
        prewarmForStartup()
    }

    func preparedStaticHeightCalculator() -> WKWebViewHeightCalculator {
        dequeueStaticHeightCalculator()
    }

    // MARK: - Test-support accessors

    var preparedContentBlockWebViewCount: Int {
        preparedContentBlockWebViews.count
    }

    func dequeueContentBlockWebViewForTest(tag: Int) -> WKWebView {
        dequeueContentBlockWebView(tag: tag)
    }

    var queueCount: Int {
        queue.count
    }

    @discardableResult
    func enqueueForTest(message: InAppContentBlockResponse, newValue: UsedInAppContentBlocks) -> QueueDedupResult {
        dedupEnqueue(message: message, newValue: newValue)
    }

    func notifyRefreshCallbackForTest(
        indexPath: IndexPath,
        source: String,
        placeholder: String?
    ) {
        notifyRefreshCallback(indexPath: indexPath, source: source, placeholder: placeholder)
    }

    func clearRefreshCoalescingState() {
        _coalescedRefreshKeys.changeValue { $0.removeAll() }
    }

    func clearQueueForTest() {
        _queue.changeValue { $0.removeAll() }
    }
}

internal enum ImageValidationState {
    case pending
    case valid
    case corrupted
}

/// Per-placeholder in-flight carousel fetch record.
///
/// Anchors the result of an in-flight `loadMessagesForCarousel` call to the `validationToken`
/// captured at fetch-registration time. Additional callers for the same placeholder append
/// themselves to `waiters` rather than issuing a duplicate provider call. When the fetch
/// completes, the callback claims this record only if its `validationToken` still matches —
/// a newer fetch that rotated the token mid-flight will have registered its own record and
/// must not be silently consumed by a stale callback.
///
/// `fileprivate`-equivalent via the `internal` struct scope paired with the consumer being
/// the owning manager file. Not part of the public SDK surface.
internal struct CarouselInFlightFetch {
    let validationToken: UUID
    var waiters: [(initial: EmptyBlock?, completion: EmptyBlock?)]
}

private extension InAppContentBlocksManager {
    func dequeueContentBlockWebView(tag: Int) -> WKWebView {
        let webView: WKWebView
        if let prepared = preparedContentBlockWebViews.first(where: { $0.superview == nil }) {
            preparedContentBlockWebViews.removeAll { $0 === prepared }
            webView = prepared
        } else if let detached = takeDetachedIssuedContentBlockWebView() {
            webView = detached
        } else {
            webView = makeContentBlockWebView()
        }
        prepareContentBlockWebViewForUse(webView, tag: tag)
        rememberIssuedContentBlockWebView(webView)
        scheduleContentBlockWebViewWarmup()
        return webView
    }

    func makeContentBlockWebView() -> WKWebView {
        let userScript = WKUserScript(
            source: disableZoomSource,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        let configuration = HtmlNormalizer.createWebViewConfiguration()
        configuration.userContentController.addUserScript(userScript)
        if let contentRuleList {
            configuration.userContentController.add(contentRuleList)
        }
        let webView = WKWebView(
            frame: .init(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 0),
            configuration: configuration
        )
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.bounces = false
        webView.backgroundColor = .clear
        webView.isOpaque = false
        return webView
    }

    func prepareContentBlockWebViewForUse(_ webView: WKWebView, tag: Int) {
        webView.stopLoading()
        webView.navigationDelegate = self
        webView.tag = tag
        webView.frame = .init(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 0)
        webView.alpha = 1
        webView.isHidden = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.bounces = false
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.scrollView.setContentOffset(.zero, animated: false)
        webView.constraints.forEach { $0.isActive = false }
    }

    func prepareContentBlockWebViewForIdle(_ webView: WKWebView) {
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.tag = 0
        webView.loadHTMLString("", baseURL: nil)
        webView.constraints.forEach { $0.isActive = false }
    }

    func rememberIssuedContentBlockWebView(_ webView: WKWebView) {
        issuedContentBlockWebViews.removeAll { ref in
            guard let value = ref.value else { return true }
            return value === webView
        }
        issuedContentBlockWebViews.append(WeakWKWebView(webView))
    }

    func takeDetachedIssuedContentBlockWebView() -> WKWebView? {
        issuedContentBlockWebViews.removeAll { $0.value == nil }
        guard let index = issuedContentBlockWebViews.firstIndex(where: { $0.value?.superview == nil }),
              let webView = issuedContentBlockWebViews[index].value else {
            return nil
        }
        issuedContentBlockWebViews.remove(at: index)
        return webView
    }

    func scheduleContentBlockWebViewWarmup() {
        onMain { [weak self] in
            guard let self else { return }
            guard !self.isContentBlockWebViewWarmupScheduled else { return }
            self.isContentBlockWebViewWarmupScheduled = true
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.isContentBlockWebViewWarmupScheduled = false
                self.prepareSpareContentBlockWebView()
            }
        }
    }

    func prewarmContentBlockWebViews() {
        onMain { [weak self] in
            self?.prepareSpareContentBlockWebView()
        }
    }

    func prewarmForStartup() {
        onMain { [weak self] in
            guard let self else { return }
            guard !IntegrationManager.shared.isStopped else {
                return
            }
            self.prewarmStaticHeightCalculator()
            self.prepareSpareContentBlockWebView()
        }
    }

    func prepareSpareContentBlockWebView() {
        preparedContentBlockWebViews.removeAll { $0.superview != nil }
        while preparedContentBlockWebViews.count < maxPreparedContentBlockWebViews {
            let webView: WKWebView
            if let detached = takeDetachedIssuedContentBlockWebView() {
                webView = detached
            } else {
                webView = makeContentBlockWebView()
            }
            prepareContentBlockWebViewForIdle(webView)
            preparedContentBlockWebViews.append(webView)
        }
    }

    func dequeueStaticHeightCalculator() -> WKWebViewHeightCalculator {
        guard Thread.isMainThread else {
            return WKWebViewHeightCalculator()
        }
        if !preparedStaticHeightCalculators.isEmpty {
            let calculator = preparedStaticHeightCalculators.removeFirst()
            calculator.stopLoading()
            calculator.heightUpdate = nil
            prewarmStaticHeightCalculator()
            return calculator
        }
        prewarmStaticHeightCalculator()
        return WKWebViewHeightCalculator()
    }

    func prewarmStaticHeightCalculator() {
        guard Thread.isMainThread else {
            onMain { [weak self] in
                self?.prewarmStaticHeightCalculator()
            }
            return
        }
        guard !IntegrationManager.shared.isStopped else {
            return
        }
        guard preparedStaticHeightCalculators.count < maxPreparedStaticHeightCalculators else {
            return
        }
        guard !isStaticHeightCalculatorWarmupScheduled else {
            return
        }
        isStaticHeightCalculatorWarmupScheduled = true
        let calculator = WKWebViewHeightCalculator()
        warmingStaticHeightCalculator = calculator
        var didFinish = false

        func finish(shouldKeepPrepared: Bool) {
            guard !didFinish else { return }
            didFinish = true
            calculator.heightUpdate = nil
            warmingStaticHeightCalculator = nil
            isStaticHeightCalculatorWarmupScheduled = false
            if shouldKeepPrepared, preparedStaticHeightCalculators.count < maxPreparedStaticHeightCalculators {
                preparedStaticHeightCalculators.append(calculator)
            }
        }

        calculator.heightUpdate = { _ in
            finish(shouldKeepPrepared: true)
        }
        calculator.loadHtml(
            placedholderId: "staticHeightCalculatorWarmup",
            html: "<html><body style=\"margin:0;height:1px\"></body></html>"
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            finish(shouldKeepPrepared: false)
        }
    }

    func clearPreparedContentBlockWebViews() {
        onMain { [weak self] in
            guard let self else { return }
            for webView in self.preparedContentBlockWebViews {
                webView.stopLoading()
                webView.navigationDelegate = nil
            }
            for ref in self.issuedContentBlockWebViews {
                ref.value?.stopLoading()
                ref.value?.navigationDelegate = nil
            }
            self.preparedContentBlockWebViews.removeAll()
            self.issuedContentBlockWebViews.removeAll()
            self.isContentBlockWebViewWarmupScheduled = false
            self.warmingStaticHeightCalculator?.stopLoading()
            self.warmingStaticHeightCalculator?.heightUpdate = nil
            self.warmingStaticHeightCalculator = nil
            self.preparedStaticHeightCalculators.forEach { calculator in
                calculator.stopLoading()
                calculator.heightUpdate = nil
            }
            self.preparedStaticHeightCalculators.removeAll()
            self.isStaticHeightCalculatorWarmupScheduled = false
        }
    }
}

// MARK: InAppContentBlocksManagerType
extension InAppContentBlocksManager:
    InAppContentBlocksManagerType,
    RuntimeInContentBlockManagerType,
    WKNavigationDelegate {
    func hasHtmlImages(html: String) -> Bool {
        return hasHtmlImages(html: html, maxConcurrentDownloads: maxImageValidationConcurrency)
    }

    private func hasHtmlImages(
        html: String,
        maxConcurrentDownloads: Int,
        shouldCancel: @escaping () -> Bool = { false }
    ) -> Bool {
        dispatchPrecondition(condition: .notOnQueue(.main))
        let collectImages = HtmlNormalizer(html).collectImages()
        guard !collectImages.isEmpty else { return true }
        let imageUrls = collectImages.compactMap { URL(string: $0) }
        guard !imageUrls.isEmpty else {
            Exponea.logger.log(.warning, message: "No correct images inside \(html)")
            return false
        }
        if shouldCancel() {
            return false
        }
        // Try the on-disk image cache before hitting the network.
        //
        // On the primary carousel path, `HtmlNormalizer.asBase64Image` (invoked during
        // `loadMessagesForCarousel`'s offline-bake step) has already downloaded every image
        // URL and written it to `InAppMessagesCache`. Re-fetching those same URLs here over
        // an ephemeral `URLSession` with `.reloadIgnoringLocalCacheData` would add ~hundreds
        // of ms per carousel cold-paint for no verdict benefit. A decoded `UIImage` from
        // the cache is sufficient proof the message has at least one valid image, which is
        // all `hasHtmlImages` promises.
        //
        // URLs whose cache entry is missing or whose cached bytes fail to decode fall
        // through to the existing network validation path, preserving behaviour for
        // non-carousel call sites and for cache misses/corruption on the carousel path.
        let imageCache: InAppMessagesCacheType = InAppMessagesCache()
        var urlsNeedingNetwork: [URL] = []
        urlsNeedingNetwork.reserveCapacity(imageUrls.count)
        for url in imageUrls {
            if shouldCancel() {
                return false
            }
            if let data = imageCache.getImageData(at: url.absoluteString),
               UIImage(data: data) != nil {
                return true
            }
            urlsNeedingNetwork.append(url)
        }
        let timeout = imageValidationTimeout
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.timeoutIntervalForRequest = timeout
        sessionConfig.timeoutIntervalForResource = timeout
        let session = URLSession(configuration: sessionConfig)
        let stateLock = NSLock()
        var isAnyCorrectImage = false
        let maxConcurrent = max(1, min(maxConcurrentDownloads, urlsNeedingNetwork.count))
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = maxConcurrent
        operationQueue.qualityOfService = .utility
        for url in urlsNeedingNetwork {
            operationQueue.addOperation {
                stateLock.lock()
                let alreadyFound = isAnyCorrectImage
                stateLock.unlock()
                if shouldCancel() || alreadyFound {
                    return
                }
                let request = URLRequest(
                    url: url,
                    cachePolicy: .reloadIgnoringLocalCacheData,
                    timeoutInterval: timeout
                )
                let taskDone = DispatchSemaphore(value: 0)
                let task = session.dataTask(with: request) { data, _, _ in
                    defer { taskDone.signal() }
                    guard !shouldCancel() else { return }
                    autoreleasepool {
                        if let data, UIImage(data: data) != nil {
                            stateLock.lock()
                            let wasFirst = !isAnyCorrectImage
                            isAnyCorrectImage = true
                            stateLock.unlock()
                            if wasFirst {
                                // One valid image is enough — tear down sibling downloads
                                // eagerly rather than waiting for each task's `timeout + 1`
                                // to elapse. Safe to call once; subsequent completions fall
                                // through `wasFirst == false`. The trailing
                                // `session.invalidateAndCancel()` after the wait loop
                                // remains as a no-op safety net for the no-success path.
                                session.invalidateAndCancel()
                            }
                        }
                    }
                }
                task.resume()
                if taskDone.wait(timeout: .now() + timeout + 1) == .timedOut {
                    task.cancel()
                }
            }
        }
        operationQueue.waitUntilAllOperationsAreFinished()
        session.invalidateAndCancel()
        if shouldCancel() {
            return false
        }
        if !isAnyCorrectImage {
            Exponea.logger.log(.warning, message: "No correct images inside \(html)")
        }
        return isAnyCorrectImage
    }

    func getUsedInAppContentBlocks(placeholder: String, indexPath: IndexPath) -> UsedInAppContentBlocks? {
        return usedInAppContentBlocks[placeholder]?.first(where: { $0.indexPath == indexPath && $0.isActive })
    }

    func anonymize() {
        _cacheGeneration.changeValue { $0 &+= 1 }
        markCatalogDirty()
        usedInAppContentBlocks.removeAll()
        inAppContentBlockMessages.removeAll()
        _imageValidationStates.changeValue(with: { $0.removeAll() })
        _heightCalculationMessageByPlaceholder.changeValue(with: { $0.removeAll() })
        _carouselValidationTokens.changeValue(with: { $0.removeAll() })
        clearAllETags()
        onMain { [weak self] in
            self?.isLoadUpdating = false
            self?.isCarouselLoading = false
        }
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if navigationAction.request.url?.scheme?.lowercased() == HtmlNormalizer.offlineResourceScheme {
            decisionHandler(.allow)
            return
        }
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
            self.notifyRefreshCallback(
                indexPath: selectedUsed.indexPath,
                source: "webAction.close",
                placeholder: selectedUsed.placeholder
            )
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
            self.notifyRefreshCallback(
                indexPath: selectedUsed.indexPath,
                source: "webAction.action",
                placeholder: selectedUsed.placeholder
            )
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

    private func parseData(
        placeholderId: String,
        data: ResponseData<PersonalizedInAppContentBlockResponseData>,
        tags: Set<Int>,
        completion: EmptyBlock?
    ) {
        ensureBackground {
            let personalizedWithPayload: [PersonalizedInAppContentBlockResponse] = data.data?.data.compactMap { response in
                self.preparePersonalizedResponseForRender(
                    response,
                    makeResourcesOffline: true
                )
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

    func invalidatePlaceholders(_ placeholderIds: [String]) {
        guard !placeholderIds.isEmpty else { return }
        _cacheGeneration.changeValue { $0 &+= 1 }

        for placeholderId in placeholderIds {
            _inAppContentBlockMessages.changeValue { messages in
                for index in messages.indices where messages[index].placeholders.contains(placeholderId) {
                    messages[index].personalizedMessage = nil
                    messages[index].normalizedResult = nil
                }
            }
            _usedInAppContentBlocks.changeValue { $0.removeValue(forKey: placeholderId) }
            _heightCalculationMessageByPlaceholder.changeValue { $0.removeValue(forKey: placeholderId) }
        }

        evictETags(forPlaceholderIds: placeholderIds)
    }

    private func evictETags(forPlaceholderIds placeholderIds: [String]) {
        guard let customerIds = try? DatabaseManager().currentCustomer.ids else { return }
        let projectToken = Exponea.shared.configuration?.mainProject.integrationId ?? ""

        let exactKeys = etagPlaceholderIdBatches(for: placeholderIds).compactMap {
            etagCacheKey(projectToken: projectToken, customerIds: customerIds, placeholderIds: $0)
        }

        let supersetKeys = batchKeyIndexLock.withLock {
            var keys = Set<String>()
            for id in placeholderIds {
                if let batchKeys = _batchKeysByPlaceholder.removeValue(forKey: id) {
                    keys.formUnion(batchKeys)
                }
            }
            return keys
        }

        for key in Set(exactKeys).union(supersetKeys) {
            etagStore.remove(forKey: key)
        }
    }

    private func etagPlaceholderIdBatches(for placeholderIds: [String]) -> [[String]] {
        var batches = placeholderIds.map { [$0] }
        if placeholderIds.count > 1 {
            batches.append(placeholderIds)
        }
        return batches
    }

    private func etagCacheKey(
        projectToken: String,
        customerIds: [String: String],
        placeholderIds: [String]
    ) -> String? {
        let blockIds = prefetchPlaceholdersWithIds(
            input: inAppContentBlockMessages,
            ids: placeholderIds
        ).map(\.id).sorted()
        guard !blockIds.isEmpty else { return nil }
        return type(of: etagStore).cacheKey(
            projectToken: projectToken,
            customerIds: customerIds,
            blockIds: blockIds
        )
    }

    func prefetchPlaceholdersWithIds(ids: [String]) {
        prefetchPlaceholdersWithIds(ids: ids, completion: nil)
    }

    func prefetchPlaceholdersWithIds(ids: [String], completion: (() -> Void)?) {
        prefetchRuntimePlaceholdersWithIds(ids: ids) { _ in completion?() }
    }

    func prefetchRuntimePlaceholdersWithIds(
        ids: [String],
        completion: @escaping (RuntimeInContentBlockPrefetchOutcome) -> Void
    ) {
        Exponea.logger.log(.verbose, message: "In-app Content Blocks prefetch starts.")
        guard !ids.isEmpty else {
            Exponea.logger.log(.verbose, message: "In-app Content Blocks prefetch starts failed because IDs are empty")
            completion(.completed)
            return
        }
        ensureCatalogLoaded { [weak self] isLoaded in
            guard let self, isLoaded else {
                completion(.retryableFailure)
                return
            }
            guard let customerIds = try? DatabaseManager().currentCustomer.ids else {
                Exponea.logger.log(.verbose, message: "In-app Content Blocks prefetch starts failed due to customer IDs")
                completion(.retryableFailure)
                return
            }
            self.prefetchPlaceholdersWithIds(
                ids: ids,
                customerIds: customerIds,
                completion: { completion(.completed) }
            )
        }
    }

    private func prefetchPlaceholdersWithIds(
        ids: [String],
        customerIds: [String: String],
        completion: (() -> Void)?
    ) {
        Exponea.logger.log(.verbose, message: "In-app Content Blocks prefetch ids \(ids)")
        let messageIds = prefetchPlaceholdersWithIds(input: inAppContentBlockMessages, ids: ids).map { $0.id }
        guard !messageIds.isEmpty else {
            completion?()
            return
        }
        let generation = cacheGeneration
        // Prefetch only warms cache; conditional revalidation does not apply.
        provider.loadPersonalizedInAppContentBlocks(
            data: PersonalizedInAppContentBlockResponseData.self,
            customerIds: customerIds,
            inAppContentBlocksIds: messageIds
        ) { [weak self] messages in
            guard let self else {
                completion?()
                return
            }
            ensureBackground {
                guard self.cacheGeneration == generation else {
                    completion?()
                    return
                }
                let prefetchedMessagesDescriptions = (messages.data?.data ?? []).map { $0.describeDetailed() }
                Exponea.logger.log(.verbose, message: "In-app Content Blocks downloaded prefetched messages \(prefetchedMessagesDescriptions)")
                let personalizedWithPayload: [PersonalizedInAppContentBlockResponse]? = messages.data?.data.filter { $0.status == .ok }.compactMap { response in
                    self.preparePersonalizedResponseForRender(
                        response,
                        makeResourcesOffline: false
                    )
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
                let applied = self.updateMessagesIfCurrent(generation: generation) { messages in
                    messages = updatedPlaceholders
                }
                guard applied else {
                    completion?()
                    return
                }
                self.trackTelemetryForFetch(.contentBlockPersonalisedFetch, updatedContentBlocksForTelemetry)
                completion?()
            }
        }
    }

    func availabilityForPlaceholder(id: String) -> InAppContentBlockAvailability {
        let candidates = prefetchPlaceholdersWithIds(input: inAppContentBlockMessages, ids: [id])
        let renderable = candidates.filter { applyDateFilter(message: $0) && hasRenderablePayload($0) }
        guard !renderable.isEmpty else { return .empty }
        if renderable.contains(where: { !($0.content?.html ?? "").isEmpty }) {
            return .ready
        }
        if filterPersonalizedMessages(input: renderable) != nil {
            return .ready
        }
        return .empty
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
        guard isCatalogReady else {
            ensureCatalogLoaded { [weak self] isLoaded in
                guard let self, isLoaded else { return }
                onMain {
                    self.notifyRefreshCallback(
                        indexPath: indexPath,
                        source: "prepareInAppContentBlockView.catalog",
                        placeholder: placeholderId
                    )
                }
            }
            return returnEmptyView(tag: Int.random(in: 0..<99999999))
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

        let web = dequeueContentBlockWebView(tag: tag)

        if let html = message.content?.html, !html.isEmpty {
            Exponea.logger.log(
                .verbose,
                message: "In-app Content Block prepareInAppContentBlockView for \(message.describe())"
            )
            if inAppContentBlockMessages[indexOfPlaceholder].normalizedResult == nil {
                Exponea.logger.log(.verbose, message: "In-app Content Block prepareInAppContentBlockView normalizeConf makeResourcesOffline=true ensureCloseButton=false")
                guard let normalizedPayload = prepareNormalizedHtmlPayload(
                    html: html,
                    makeResourcesOffline: true,
                    ensureCloseButton: false
                ) else {
                    return returnEmptyView(tag: tag)
                }
                Exponea.logger.log(
                    .verbose,
                    message: "In-app Content Block prepareInAppContentBlockView normalizedPayload is valid: \(normalizedPayload.valid)"
                )
                inAppContentBlockMessages[indexOfPlaceholder].normalizedResult = normalizedPayload
            }
            guard let finalHTML = inAppContentBlockMessages[indexOfPlaceholder].normalizedResult?.html else {
                return returnEmptyView(tag: tag)
            }
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
        guard isCatalogReady else {
            ensureCatalogLoaded { [weak self] isLoaded in
                guard let self, isLoaded else {
                    continueCallback?([])
                    return
                }
                self.filterCarouselData(
                    placeholder: placeholder,
                    continueCallback: continueCallback,
                    expiredCompletion: expiredCompletion
                )
            }
            return
        }
        let placehodlersToUse = inAppContentBlockMessages.filter { !$0.placeholders.filter { $0 == placeholder }.isEmpty }
        let placeholdersNeedToRefresh = placehodlersToUse.filter { $0.personalizedMessage == nil && $0.content?.html == nil }
        // Scope expiration to the placeholder being loaded. `loadMessagesForCarousel`
        // only re-fetches `idsForDownload = messages.filter { $0.placeholders.contains(placeholder) }`,
        // so an unrelated placeholder's expired messages can never be refreshed via this
        // path. Including them here used to cause a permanent deadlock: e.g. when the
        // app comes back from a long background (phone locked > TTL), every unrelated
        // static-CB message is past its `ttlSeen + ttlSeconds`, the guard below
        // forwards to `expiredCompletion?()` which re-runs `loadMessagesForCarousel`,
        // which only refreshes the carousel's own messages, which leaves the unrelated
        // ones expired — and the loop continues forever, leaving the carousel blank.
        // The static-CB sibling `prepareInAppContentBlocksStaticView` already scopes
        // its expiration check to `placehodlersToUse`; this matches it.
        let expiredMessages = placehodlersToUse.filter { inAppContentBlocks in
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
            let validationState = self.imageValidationStates[inAppContentBlocksPlaceholder.id]
            if validationState == .pending || validationState == .corrupted {
                return false
            }
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
        placeholderId: String,
        makeResourcesOffline: Bool = true
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

        let candidates = placehodlersToUse.filter { $0.personalizedMessage?.status == .ok }
        var skippedMessageIds: Set<String> = []
        while true {
            let selectableCandidates = candidates.filter { !skippedMessageIds.contains($0.id) }
            guard var message = filterPersonalizedMessages(input: selectableCandidates) else {
                Exponea.logger.log(.verbose, message: "In-app Content Blocks prepareInAppContentBlocksStaticView message not found.")
                return .init(html: "", tag: 0, message: nil)
            }
            Exponea.logger.log(
                .verbose,
                message: "In-app Content Blocks prepareInAppContentBlocksStaticView message \(message.describe())."
            )

            let tag = createUniqueTag(placeholder: message)
            Exponea.logger.log(.verbose, message: "In-app Content Blocks prepareInAppContentBlocksStaticView tag \(tag).")

            if var personalized = message.personalizedMessage {
                let needsNormalization = personalized.htmlPayload?.html?.isEmpty ?? true
                if needsNormalization || !makeResourcesOffline {
                    if let normalizedPayload = prepareNormalizedHtmlPayload(
                        html: personalized.content?.html ?? "",
                        makeResourcesOffline: makeResourcesOffline,
                        ensureCloseButton: false
                    ) {
                        personalized.htmlPayload = normalizedPayload
                        personalized.isCorruptedImage = false
                    } else {
                        personalized.htmlPayload = nil
                        personalized.isCorruptedImage = true
                    }
                    message.personalizedMessage = personalized
                }
            }

            if let personalized = message.personalizedMessage,
               let payloadData = personalized.htmlPayload?.html?.data(using: .utf8),
               !payloadData.isEmpty {
                Exponea.logger.log(
                    .verbose,
                    message: "In-app Content Blocks prepareInAppContentBlocksStaticView personalized \(personalized.describeDetailed())."
                )
                if let html = personalized.htmlPayload?.html, !html.isEmpty {
                    updateDisplayedState(for: message.id)
                    message.tags?.insert(tag)
                    _inAppContentBlockMessages.changeValue { messages in
                        guard let index = messages.firstIndex(where: { $0.id == message.id }) else { return }
                        let existingTtlSeen = messages[index].personalizedMessage?.ttlSeen
                        messages[index] = message
                        if messages[index].personalizedMessage?.ttlSeen == nil {
                            messages[index].personalizedMessage?.ttlSeen = existingTtlSeen ?? Date()
                        }
                    }
                    return .init(html: html, tag: tag, message: message)
                }
            } else if let personalized = message.personalizedMessage {
                _inAppContentBlockMessages.changeValue { messages in
                    guard let index = messages.firstIndex(where: { $0.id == message.id }) else { return }
                    messages[index].personalizedMessage = personalized
                }
                skippedMessageIds.insert(message.id)
                continue
            } else {
                Exponea.logger.log(
                    .verbose,
                    message: "In-app Content Blocks prepareInAppContentBlocksStaticView static \(message.describe())."
                )
                if let html = message.content?.html, !html.isEmpty {
                    updateDisplayedState(for: message.id)
                    message.tags?.insert(tag)
                    _inAppContentBlockMessages.changeValue { messages in
                        guard let index = messages.firstIndex(where: { $0.id == message.id }) else { return }
                        messages[index] = message
                    }
                    return .init(html: html, tag: tag, message: message)
                }
                skippedMessageIds.insert(message.id)
                continue
            }
        }
    }

    func loadInAppContentBlockMessages(completion: EmptyBlock?) {
        loadCatalog { _ in completion?() }
    }

    private func ensureCatalogLoaded(completion: @escaping (Bool) -> Void) {
        catalogStateLock.lock()
        switch catalogState {
        case .ready:
            catalogStateLock.unlock()
            completion(true)
        case .loading:
            catalogWaiters.append(completion)
            catalogStateLock.unlock()
        case .dirty:
            catalogStateLock.unlock()
            loadCatalog(completion: completion)
        }
    }

    private var isCatalogReady: Bool {
        catalogStateLock.lock()
        defer { catalogStateLock.unlock() }
        return catalogState == .ready
    }

    private func loadCatalog(completion: @escaping (Bool) -> Void) {
        catalogStateLock.lock()
        if catalogState == .loading {
            catalogWaiters.append(completion)
            catalogStateLock.unlock()
            return
        }
        catalogState = .loading
        catalogWaiters.append(completion)
        catalogStateLock.unlock()

        let generation = cacheGeneration
        provider.getInAppContentBlocks(
            data: InAppContentBlocksDataResponse.self
        ) { [weak self] result in
            guard let self else { return }
            guard result.data?.success == true, let messages = result.data?.data else {
                self.completeCatalogLoad(generation: generation, succeeded: false)
                return
            }
            ensureBackground {
                guard self.cacheGeneration == generation else {
                    self.completeCatalogLoad(generation: generation, succeeded: false)
                    return
                }
                let filteredMessages: [InAppContentBlockResponse] = messages.map { message in
                    if let content = message.content?.html {
                        var msg = message
                        if let normalizedPayload = self.prepareNormalizedHtmlPayload(
                            html: content,
                            makeResourcesOffline: true,
                            ensureCloseButton: false
                        ) {
                            msg.normalizedResult = normalizedPayload
                            msg.isCorruptedImage = false
                        } else {
                            msg.isCorruptedImage = true
                        }
                        return msg
                    }
                    return message
                }
                let applied = self.updateMessagesIfCurrent(generation: generation) { currentMessages in
                    currentMessages = filteredMessages
                }
                guard applied else {
                    self.completeCatalogLoad(generation: generation, succeeded: false)
                    return
                }
                let validIds = Set(filteredMessages.map { $0.id })
                self._imageValidationStates.changeValue { states in
                    states = states.filter { validIds.contains($0.key) }
                }
                let loadedMessagesDescriptions = (result.data?.data ?? []).map { $0.describe() }
                Exponea.logger.log(
                    .verbose,
                    message: "In-app Content Blocks loadInAppContentBlockMessages done with \(loadedMessagesDescriptions)."
                )
                self.trackTelemetryForFetch(.contentBlockInitFetch, messages)
                self.completeCatalogLoad(generation: generation, succeeded: true)
            }
        }
    }

    private func markCatalogDirty() {
        catalogStateLock.lock()
        catalogState = .dirty
        let waiters = catalogWaiters
        catalogWaiters.removeAll()
        catalogStateLock.unlock()
        waiters.forEach { $0(false) }
    }

    @discardableResult
    private func updateMessagesIfCurrent(
        generation: UInt,
        mutation: (inout [InAppContentBlockResponse]) -> Void
    ) -> Bool {
        guard cacheGeneration == generation else { return false }
        var applied = false
        _inAppContentBlockMessages.changeValue { messages in
            mutation(&messages)
            applied = true
        }
        guard cacheGeneration == generation else {
            _inAppContentBlockMessages.changeValue { messages in
                messages.removeAll()
            }
            return false
        }
        return applied
    }

    private func completeCatalogLoad(generation: UInt, succeeded: Bool) {
        let isCurrentGeneration = cacheGeneration == generation
        catalogStateLock.lock()
        if !isCurrentGeneration {
            // A newer generation (triggered by anonymize/identifyCustomer) superseded this fetch.
            // If the newer load has already moved catalogState to .loading, flipping it back to
            // .dirty here is a known coarse-grained tradeoff: cacheGeneration is a UInt counter,
            // not a per-load token, so this branch cannot distinguish "new load in-flight" from
            // "still dirty". The consequence is one spurious retryableFailure and an extra network
            // round trip on the next ensureCatalogLoaded call — no hang and no data corruption.
            // Under normal usage (identity changes are seconds apart) this path is never hit.
            if catalogState == .loading {
                catalogState = .dirty
                let waiters = catalogWaiters
                catalogWaiters.removeAll()
                catalogStateLock.unlock()
                waiters.forEach { $0(false) }
                return
            }
            catalogStateLock.unlock()
            return
        }
        guard catalogState == .loading else {
            catalogStateLock.unlock()
            return
        }
        catalogState = succeeded ? .ready : .dirty
        let waiters = catalogWaiters
        catalogWaiters.removeAll()
        catalogStateLock.unlock()
        waiters.forEach { $0(succeeded) }
    }
}

private enum CatalogState: Equatable {
    case dirty
    case loading
    case ready
}

private extension InAppContentBlocksManager {
    /// Dispatches to the main queue for WKWebView height calculation; fetch is handled by `loadContent`.
    func loadPersonalizedInAppContentBlocks(
        for placeholderId: String,
        tags: Set<Int>,
        completion: EmptyBlock?
    ) {
        Exponea.logger.log(.verbose, message: "In-app Content Blocks loadPersonalizedInAppContentBlocks starts")
        guard !placeholderId.isEmpty, (try? DatabaseManager().currentCustomer.ids) != nil else {
            Exponea.logger.log(.verbose, message: "In-app Content Blocks loadPersonalizedInAppContentBlocks failed placeholderId.isEmpty: \(placeholderId.isEmpty) and ids: \(String(describing: try? DatabaseManager().currentCustomer.ids))")
            return
        }
        DispatchQueue.global().async {
            onMain {
                completion?()
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

    private func hasRenderablePayload(_ message: InAppContentBlockResponse) -> Bool {
        if let html = message.content?.html, !html.isEmpty {
            return true
        }
        guard message.personalizedMessage?.status == .ok,
              message.personalizedMessage?.isCorruptedImage == false else {
            return false
        }
        if let html = message.personalizedMessage?.htmlPayload?.html, !html.isEmpty {
            return true
        }
        if let html = message.personalizedMessage?.content?.html, !html.isEmpty {
            return true
        }
        return false
    }

    private func renderableMessagesForHeightCalculation(
        from messages: [InAppContentBlockResponse],
        placeholder: String
    ) -> [InAppContentBlockResponse] {
        let renderableMessages = messages.filter { hasRenderablePayload($0) }
        if let messageId = heightCalculationMessageByPlaceholder[placeholder],
           let selectedMessage = renderableMessages.first(where: { $0.id == messageId }) {
            return [selectedMessage]
        }
        guard let selectedMessage = filterPersonalizedMessages(input: renderableMessages) else {
            return []
        }
        _heightCalculationMessageByPlaceholder.changeValue { store in
            store[placeholder] = selectedMessage.id
        }
        return [selectedMessage]
    }

    private func clearHeightCalculationSelection(placeholder: String, messageId: String) {
        _heightCalculationMessageByPlaceholder.changeValue { selections in
            if selections[placeholder] == messageId {
                selections.removeValue(forKey: placeholder)
            }
        }
    }

    private func prepareMessageForHeightCalculation(
        _ message: InAppContentBlockResponse,
        placeholder: String,
        indexPath: IndexPath
    ) -> InAppContentBlockResponse? {
        if let html = message.content?.html, !html.isEmpty {
            return message
        }
        guard var personalized = message.personalizedMessage,
              personalized.status == .ok,
              personalized.isCorruptedImage == false else {
            return nil
        }
        if let html = personalized.htmlPayload?.html, !html.isEmpty {
            return message
        }
        guard personalized.content?.html.isEmpty == false else {
            return nil
        }
        personalized = preparePersonalizedResponseForRender(
            personalized,
            makeResourcesOffline: true
        )
        if personalized.ttlSeen == nil {
            personalized.ttlSeen = Date()
        }
        var preparedMessage: InAppContentBlockResponse?
        _inAppContentBlockMessages.changeValue { messages in
            guard let idx = messages.firstIndex(where: { $0.id == message.id }) else { return }
            messages[idx].personalizedMessage = personalized
            messages[idx].indexPath = indexPath
            preparedMessage = messages[idx]
        }
        guard personalized.isCorruptedImage == false,
              let html = personalized.htmlPayload?.html,
              !html.isEmpty else {
            return nil
        }
        return preparedMessage
    }

    private func preparedRenderableMessagesForHeightCalculation(
        from messages: [InAppContentBlockResponse],
        placeholder: String,
        indexPath: IndexPath
    ) -> [InAppContentBlockResponse] {
        var skippedMessageIds: Set<String> = []
        while true {
            let selectableMessages = messages.filter { !skippedMessageIds.contains($0.id) }
            guard let selectedMessage = renderableMessagesForHeightCalculation(
                from: selectableMessages,
                placeholder: placeholder
            ).first else {
                return []
            }
            guard let preparedMessage = prepareMessageForHeightCalculation(
                selectedMessage,
                placeholder: placeholder,
                indexPath: indexPath
            ) else {
                skippedMessageIds.insert(selectedMessage.id)
                clearHeightCalculationSelection(placeholder: placeholder, messageId: selectedMessage.id)
                continue
            }
            return [preparedMessage]
        }
    }

    func returnEmptyView(tag: Int) -> UIView {
        dequeueContentBlockWebView(tag: tag)
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
        guard isCatalogReady else {
            ensureCatalogLoaded { [weak self] isLoaded in
                guard let self, isLoaded else { return }
                onMain {
                    self.loadContent(indexPath: indexPath, placeholder: placeholder, expired: expired)
                }
            }
            return
        }
        if !isLoadUpdating {
            // Clear stale coalescing keys when a new load cycle starts.
            clearRefreshCoalescingIfIdle()
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
                let renderablePlaceholdersToUse = self.preparedRenderableMessagesForHeightCalculation(
                    from: placehodlersToUse,
                    placeholder: placeholder,
                    indexPath: indexPath
                )
                if !renderablePlaceholdersToUse.isEmpty {
                    prewarmContentBlockWebViews()
                }
                for placeholderInLoop in renderablePlaceholdersToUse {
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
            warmHeightCalculator()
            // Conditional revalidation applies only when refreshing the full expired set.
            let isRevalidation = !expired.isEmpty
                && Set(placeholdersNeedToGetContent.map { $0.id }) == Set(expired.map { $0.id })
            let blockIds = placeholdersNeedToGetContent.map { $0.id }.sorted()
            let generation = cacheGeneration
            let projectToken = Exponea.shared.configuration?.mainProject.integrationId ?? ""
            let cacheKey = type(of: self.etagStore).cacheKey(projectToken: projectToken, customerIds: ids, blockIds: blockIds)
            let storedEtag = isRevalidation ? self.etagStore.retrieve(forKey: cacheKey) : nil

            let onNotModified: (() -> Void)? = isRevalidation ? { [weak self] in
                guard let self, self.cacheGeneration == generation else { return }
                Exponea.logger.log(.verbose, message: "ICB loadContent: 304 cache hit for placeholder \(placeholder)")
                let placehodlersToUse = self.inAppContentBlockMessages.filter { $0.placeholders.contains(placeholder) }
                let renderablePlaceholdersToUse = self.preparedRenderableMessagesForHeightCalculation(
                    from: placehodlersToUse,
                    placeholder: placeholder,
                    indexPath: indexPath
                )
                if !renderablePlaceholdersToUse.isEmpty {
                    self._inAppContentBlockMessages.changeValue { messages in
                        for i in messages.indices {
                            guard messages[i].placeholders.contains(placeholder),
                                  messages[i].personalizedMessage != nil else { continue }
                            messages[i].personalizedMessage?.ttlSeen = Date()
                        }
                    }
                    self.prewarmContentBlockWebViews()
                    for placeholderInLoop in renderablePlaceholdersToUse {
                        let tag = self.createUniqueTag(placeholder: placeholderInLoop)
                        let usedHeight = self.usedInAppContentBlocks[placeholder]?.first(where: { $0.messageId == placeholderInLoop.id && $0.indexPath == indexPath })?.height ?? 0
                        self.newUsedInAppContentBlocks = .init(tag: tag, indexPath: indexPath, messageId: placeholderInLoop.id, placeholder: placeholder, height: usedHeight, placeholderData: placeholderInLoop)
                    }
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        self.isLoadUpdating = false
                        self.notifyRefreshCallback(
                            indexPath: indexPath,
                            source: "loadContentForPlaceholder.304",
                            placeholder: placeholder
                        )
                        guard !self.loadQueue.isEmpty else { return }
                        let go = self.loadQueue.removeFirst()
                        self.loadContent(indexPath: go.indexPath, placeholder: go.placeholder, expired: go.expired)
                    }
                } else {
                    self.etagStore.remove(forKey: cacheKey)
                    Exponea.logger.log(.verbose, message: "ICB loadContent: no renderable cache on 304, evicting ETag and re-fetching")
                    self.isLoadUpdating = false
                    self.loadContent(indexPath: indexPath, placeholder: placeholder, expired: [])
                }
            } : nil

            self.provider.loadPersonalizedInAppContentBlocks(
                data: PersonalizedInAppContentBlockResponseData.self,
                customerIds: ids,
                inAppContentBlocksIds: blockIds,
                etag: storedEtag,
                onNotModified: onNotModified,
                onEtagHeader: { [weak self] etag in
                    guard let self, self.cacheGeneration == generation else { return }
                    self.etagStore.store(etag: etag, forKey: cacheKey)
                    Exponea.logger.log(.verbose, message: "ICB loadContent: received ETag from server, storing for key=\(cacheKey.prefix(16))…")
                    self.batchKeyIndexLock.withLock {
                        self._batchKeysByPlaceholder[placeholder, default: []].insert(cacheKey)
                    }
                }
            ) { [weak self] data in
                guard let self else { return }
                ensureBackground {
                    let personalizedResponses = data.data?.data ?? []
                    var logDescriptions: [String] = []
                    let applied = self.updateMessagesIfCurrent(generation: generation) { messages in
                        for (index, inAppContentBlocks) in messages.enumerated() {
                            if var personalized = personalizedResponses.first(where: { $0.id == inAppContentBlocks.id }) {
                                let tag = self.createUniqueTag(placeholder: inAppContentBlocks)
                                personalized.ttlSeen = Date()
                                messages[index].personalizedMessage = personalized
                                messages[index].tags?.insert(tag)
                                messages[index].indexPath = indexPath
                            }
                        }
                        logDescriptions = messages.map { $0.describe() }
                    }
                    guard applied else { return }
                    Exponea.logger.log(
                        .verbose,
                        message: "In-app Content Blocks updatedPlaceholders \(logDescriptions)"
                    )
                    let updatedPlacehodlersToUse = self.inAppContentBlockMessages.filter { $0.placeholders.contains(placeholder) }
                    let renderablePlaceholdersToUse = self.preparedRenderableMessagesForHeightCalculation(
                        from: updatedPlacehodlersToUse,
                        placeholder: placeholder,
                        indexPath: indexPath
                    )
                    if !renderablePlaceholdersToUse.isEmpty {
                        self.prewarmContentBlockWebViews()
                    }
                    for placeholderInLoop in renderablePlaceholdersToUse {
                        let tag = self.createUniqueTag(placeholder: placeholderInLoop)
                        let usedInAppContentBlocksHeight = self.usedInAppContentBlocks[placeholder]?.first(where: { $0.messageId == placeholderInLoop.id })?.height ?? 0
                        self.newUsedInAppContentBlocks = .init(tag: tag, indexPath: indexPath, messageId: placeholderInLoop.id, placeholder: placeholder, height: !expired.isEmpty ? 0 : usedInAppContentBlocksHeight, placeholderData: placeholderInLoop)
                    }
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        self.isLoadUpdating = false
                        guard !self.loadQueue.isEmpty else { return }
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
            let queuedItem = QueueLoadData(placeholder: placeholder, indexPath: indexPath, expired: expired)
            let dedupKey = loadQueueDedupKey(for: queuedItem)
            var shouldEnqueue = false
            _loadQueue.changeValue { queue in
                if queue.contains(where: { loadQueueDedupKey(for: $0) == dedupKey }) {
                    shouldEnqueue = false
                } else {
                    queue.append(queuedItem)
                    shouldEnqueue = true
                }
            }
            if shouldEnqueue {
                Exponea.logger.log(.verbose, message:
                    """
                    In-app Content Blocks added to queue
                    indexPath: \(indexPath)
                    placeholder: \(placeholder)
                    expired: \(expired.map { $0.describe() })
                    """
                )
            }
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
            self.prewarmContentBlockWebViews()
            self.notifyRefreshCallback(
                indexPath: savedNewValue.indexPath,
                source: "calculateStaticData.empty",
                placeholder: savedNewValue.placeholder
            )
        } else {
            Exponea.logger.log(.verbose, message: "In-app Content Blocks usedInAppContentBlocks \(usedInAppContentBlocks.mapValues { $0.map { $0.describeDetailed() } })")
            if let indexOfSavedInAppContentBlocks: Int = self.usedInAppContentBlocks[placeholderValueFromUsedLine]?.firstIndex(where: { $0.messageId == savedNewValue.messageId && $0.height == 0 }) {
                if var savedInAppContentBlocks = self.usedInAppContentBlocks[placeholderValueFromUsedLine]?[indexOfSavedInAppContentBlocks] {
                    if savedInAppContentBlocks.height == 0 {
                        savedInAppContentBlocks.height = height.height
                    }
                    self._usedInAppContentBlocks.changeValue(with: { $0[placeholderValueFromUsedLine]?[indexOfSavedInAppContentBlocks] = savedInAppContentBlocks })
                }
            } else {
                let newSavedInAppContentBlocks: UsedInAppContentBlocks = .init(tag: savedNewValue.tag, indexPath: indexPath, messageId: savedNewValue.messageId, placeholder: savedNewValue.placeholder, height: height.height)
                self._usedInAppContentBlocks.changeValue { store in
                    store[placeholderValueFromUsedLine]?.append(newSavedInAppContentBlocks)
                }
            }
            self.continueWithQueue()
            self.calculator.heightUpdate = nil
            self.prewarmContentBlockWebViews()
            self.notifyRefreshCallback(
                indexPath: savedNewValue.indexPath,
                source: "calculateStaticData.update",
                placeholder: savedNewValue.placeholder
            )
        }
    }
}

// MARK: - Static inAppContentBlocks
extension InAppContentBlocksManager {
    private func completeStaticRequestsWithEmpty(_ requests: [StaticQueueData]) {
        for request in requests {
            onMain { request.completion?(.init(html: "", tag: 0, message: nil)) }
        }
    }

    private func continueWithStaticQueue() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            dispatchPrecondition(condition: .onQueue(.main))
            if !self.staticQueue.isEmpty {
                self.processStaticBatch()
            } else {
                self.isStaticUpdating = false
            }
        }
    }

    private func scheduleBatchProcessing() {
        DispatchQueue.main.async { [weak self] in
            self?.processStaticBatch()
        }
    }

    private func processStaticBatch() {
        dispatchPrecondition(condition: .onQueue(.main))
        let batch = staticQueue
        staticQueue.removeAll()
        guard !batch.isEmpty else {
            isStaticUpdating = false
            return
        }
        guard let customerIds = try? DatabaseManager().currentCustomer.ids else {
            Exponea.logger.log(
                .verbose,
                message: "In-app Content Blocks cant refresh static content — no customer IDs"
            )
            batch.forEach { $0.completion?(.init(html: "", tag: 0, message: nil)) }
            isStaticUpdating = false
            return
        }
        var validRequests: [StaticQueueData] = []
        for request in batch {
            if request.placeholderId.isEmpty {
                Exponea.logger.log(
                    .verbose,
                    message: "In-app Content Blocks skipping empty placeholderId in batch"
                )
                request.completion?(.init(html: "", tag: 0, message: nil))
            } else {
                validRequests.append(request)
            }
        }
        guard !validRequests.isEmpty else {
            isStaticUpdating = false
            return
        }
        let allPlaceholderIds = Set(validRequests.map { $0.placeholderId })
        let mergedIds = Set(
            inAppContentBlockMessages
                .filter { !Set($0.placeholders).isDisjoint(with: allPlaceholderIds) }
                .map { $0.id }
        ).sorted()
        guard !mergedIds.isEmpty else {
            completeStaticRequestsWithEmpty(validRequests)
            continueWithStaticQueue()
            return
        }
        let generation = cacheGeneration
        // Batch-level ETag; skipEtag on any queued request bypasses conditional fetch for the whole batch.
        let batchSkipEtag = validRequests.contains { $0.skipEtag }
        Exponea.logger.log(
            .verbose,
            message: "In-app Content Blocks batched refresh for \(allPlaceholderIds.count) placeholder(s), \(mergedIds.count) message ID(s)"
        )
        let projectToken = Exponea.shared.configuration?.mainProject.integrationId ?? ""
        let batchCacheKey = type(of: etagStore).cacheKey(projectToken: projectToken, customerIds: customerIds, blockIds: mergedIds)
        Exponea.logger.log(
            .verbose,
            message: "ICB processStaticBatch: projectToken=\(projectToken.isEmpty ? "<empty>" : projectToken.prefix(8).description + "…") cacheKey=\(batchCacheKey.prefix(16))… skipEtag=\(batchSkipEtag)"
        )
        let batchStoredEtag = batchSkipEtag ? nil : etagStore.retrieve(forKey: batchCacheKey)
        let batchOnNotModified: (() -> Void)? = batchSkipEtag ? nil : { [weak self, batchCacheKey] in
            guard let self else { return }
            guard self.cacheGeneration == generation else {
                self.completeStaticRequestsWithEmpty(validRequests)
                self.continueWithStaticQueue()
                return
            }
            Exponea.logger.log(
                .verbose,
                message: "ICB processStaticBatch: 304 cache hit for placeholder(s) \(allPlaceholderIds.joined(separator: ", "))"
            )
            let batchMessages = self.inAppContentBlockMessages.filter {
                !Set($0.placeholders).isDisjoint(with: allPlaceholderIds)
            }
            let hasRenderableCache = batchMessages.contains { self.hasRenderablePayload($0) }
            if hasRenderableCache {
                // Reset TTL anchor so cached content is not treated as expired.
                self._inAppContentBlockMessages.changeValue { messages in
                    for i in messages.indices {
                        guard !Set(messages[i].placeholders).isDisjoint(with: allPlaceholderIds),
                              self.hasRenderablePayload(messages[i]) else { continue }
                        messages[i].personalizedMessage?.ttlSeen = Date()
                    }
                }
                var preparedResults: [StaticReturnData] = []
                for request in validRequests {
                    preparedResults.append(
                        self.prepareInAppContentBlocksStaticView(
                            placeholderId: request.placeholderId,
                            makeResourcesOffline: request.makeResourcesOffline
                        )
                    )
                }
                let hasPreparedContent = preparedResults.contains { !$0.html.isEmpty }
                if hasPreparedContent {
                    for (index, request) in validRequests.enumerated() {
                        let result = preparedResults[index]
                        onMain { request.completion?(result) }
                    }
                    self.continueWithStaticQueue()
                } else {
                    self.etagStore.remove(forKey: batchCacheKey)
                    Exponea.logger.log(.verbose, message: "ICB processStaticBatch: no renderable cache on 304, evicting ETag and re-fetching")
                    var forcedRequests = validRequests
                    for i in forcedRequests.indices { forcedRequests[i].skipEtag = true }
                    forcedRequests.forEach { self.staticQueue.insert($0, at: 0) }
                    self.processStaticBatch()
                }
            } else {
                self.etagStore.remove(forKey: batchCacheKey)
                var forcedRequests = validRequests
                for i in forcedRequests.indices { forcedRequests[i].skipEtag = true }
                forcedRequests.forEach { self.staticQueue.insert($0, at: 0) }
                self.processStaticBatch()
            }
        }
        provider.loadPersonalizedInAppContentBlocks(
            data: PersonalizedInAppContentBlockResponseData.self,
            customerIds: customerIds,
            inAppContentBlocksIds: mergedIds,
            etag: batchStoredEtag,
            onNotModified: batchOnNotModified,
            onEtagHeader: { [weak self] etag in
                guard let self, self.cacheGeneration == generation else { return }
                Exponea.logger.log(.verbose, message: "ICB processStaticBatch: received ETag from server, storing for key=\(batchCacheKey.prefix(16))…")
                self.etagStore.store(etag: etag, forKey: batchCacheKey)
                let placeholderSnapshot = allPlaceholderIds
                self.batchKeyIndexLock.withLock {
                    for id in placeholderSnapshot {
                        self._batchKeysByPlaceholder[id, default: []].insert(batchCacheKey)
                    }
                }
            }
        ) { [weak self] data in
            guard let self else { return }
            ensureBackground {
                guard self.cacheGeneration == generation else {
                    self.completeStaticRequestsWithEmpty(validRequests)
                    self.continueWithStaticQueue()
                    return
                }
                if let error = data.error {
                    Exponea.logger.log(
                        .error,
                        message: "In-app Content Blocks batched refresh failed: \(error.localizedDescription)"
                    )
                    for request in validRequests {
                        onMain {
                            request.completion?(.init(html: "", tag: 0, message: nil))
                        }
                    }
                    self.continueWithStaticQueue()
                    return
                }
                guard data.data != nil else {
                    Exponea.logger.log(
                        .error,
                        message: "In-app Content Blocks batched refresh failed: missing data"
                    )
                    for request in validRequests {
                        onMain {
                            request.completion?(.init(html: "", tag: 0, message: nil))
                        }
                    }
                    self.continueWithStaticQueue()
                    return
                }
                let descriptions = (data.data?.data ?? []).map { $0.describeDetailed() }
                Exponea.logger.log(
                    .verbose,
                    message: "In-app Content Blocks batched refreshStaticViewContent data: \(descriptions)"
                )
                let personalizedResponses = data.data?.data ?? []
                var updatedContentBlocksForTelemetry: [InAppContentBlockResponse] = []
                let applied = self.updateMessagesIfCurrent(generation: generation) { messages in
                    for (index, inAppContentBlocks) in messages.enumerated() {
                        if var personalized = personalizedResponses.first(where: { $0.id == inAppContentBlocks.id }) {
                            personalized.ttlSeen = Date()
                            messages[index].personalizedMessage = personalized
                            updatedContentBlocksForTelemetry.append(messages[index])
                        }
                    }
                }
                guard applied else {
                    self.completeStaticRequestsWithEmpty(validRequests)
                    self.continueWithStaticQueue()
                    return
                }
                self.trackTelemetryForFetch(.contentBlockPersonalisedFetch, updatedContentBlocksForTelemetry)
                for request in validRequests {
                    let result = self.prepareInAppContentBlocksStaticView(
                        placeholderId: request.placeholderId,
                        makeResourcesOffline: request.makeResourcesOffline
                    )
                    onMain {
                        request.completion?(result)
                    }
                }
                self.continueWithStaticQueue()
            }
        }
    }

    private func continueWithCarouselQueue(dataCompletion: TypeBlock<[StaticReturnData]>?) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            dispatchPrecondition(condition: .onQueue(.main))
            self.isCarouselLoading = false
            if !self.carouselQueue.isEmpty {
                let go = self.carouselQueue.removeFirst()
                Exponea.logger.log(.verbose, message: "In-app Content Blocks carousel queue \(go)")
                self.refreshCarouselData(placeholder: go, dataCompletion: dataCompletion)
            }
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

    /// Token-anchored claim for an in-flight carousel fetch.
    ///
    /// Returns the waiters registered on the placeholder's in-flight record only when
    /// the record was registered by this fetch (i.e. its `validationToken` matches the
    /// one captured when the fetch was kicked off) and atomically removes the record.
    /// If a newer fetch has since rotated the token and installed its own record,
    /// returns nil and leaves the newer record intact — the stale callback drops its
    /// result instead of orphaning the newer run's waiters.
    ///
    /// Kept `internal` (not exposed via `InAppContentBlocksManagerType`) so tests can
    /// drive the invariant without the public SDK surface growing.
    internal func claimInFlightCarouselFetch(
        placeholder: String,
        validationToken: UUID
    ) -> [(initial: EmptyBlock?, completion: EmptyBlock?)]? {
        var claimed: [(initial: EmptyBlock?, completion: EmptyBlock?)]?
        _carouselInFlightFetches.changeValue { map in
            if let record = map[placeholder], record.validationToken == validationToken {
                claimed = record.waiters
                map.removeValue(forKey: placeholder)
            }
        }
        return claimed
    }

    /// Loads personalized messages for a carousel placeholder and validates their images.
    ///
    /// - Parameters:
    ///   - placeholder: The placeholder ID to load messages for.
    ///   - initialCompletion: Called once the first valid (non-corrupted) message is available,
    ///     or after all validations complete if none are valid. Called on a **background queue** —
    ///     callers must dispatch to main for UI work.
    ///   - completion: Called after all image validations finish. Called on a **background queue** —
    ///     callers must dispatch to main for UI work.
    func loadMessagesForCarousel(
        placeholder: String,
        initialCompletion: EmptyBlock?,
        completion: EmptyBlock?
    ) {
        guard isCatalogReady else {
            ensureCatalogLoaded { [weak self] isLoaded in
                guard let self, isLoaded else {
                    ensureBackground {
                        initialCompletion?()
                        completion?()
                    }
                    return
                }
                self.loadMessagesForCarousel(
                    placeholder: placeholder,
                    initialCompletion: initialCompletion,
                    completion: completion
                )
            }
            return
        }
        guard !placeholder.isEmpty, let ids = try? DatabaseManager().currentCustomer.ids else {
            Exponea.logger.log(.verbose, message: "In-app Content Blocks Carousel cant refresh placeholderId: \(placeholder), ids: \(String(describing: try? DatabaseManager().currentCustomer.ids))")
            ensureBackground {
                initialCompletion?()
                completion?()
            }
            return
        }

        // Dedup gate: if this placeholder already has an in-flight fetch, attach as a
        // waiter and return. The in-flight fetch's `validationToken` remains the active
        // one — we deliberately do NOT rotate it, so the currently-running image
        // validation (which uses that token as its cancellation key) keeps running
        // for the benefit of every waiter. Two back-to-back `reload()` calls now share
        // one provider call, one HTML-normalization pass, and one image-validation
        // pass (fan-out happens via the `broadcastInitial` / `broadcastCompletion`
        // wrappers below).
        var alreadyInFlight = false
        _carouselInFlightFetches.changeValue { map in
            if map[placeholder] != nil {
                map[placeholder]?.waiters.append((initialCompletion, completion))
                alreadyInFlight = true
            }
        }
        if alreadyInFlight {
            return
        }

        let validationToken = UUID()
        _carouselValidationTokens.changeValue { tokens in
            tokens[placeholder] = validationToken
        }
        _carouselInFlightFetches.changeValue { map in
            map[placeholder] = CarouselInFlightFetch(
                validationToken: validationToken,
                waiters: [(initialCompletion, completion)]
            )
        }

        let idsForDownload = inAppContentBlockMessages.filter { $0.placeholders.contains(placeholder) }.map { $0.id }
        guard !idsForDownload.isEmpty else {
            let waiters = claimInFlightCarouselFetch(
                placeholder: placeholder,
                validationToken: validationToken
            ) ?? []
            ensureBackground {
                waiters.forEach {
                    $0.initial?()
                    $0.completion?()
                }
            }
            return
        }
        let generation = cacheGeneration
        // Fresh fetch required for carousel rotation and image validation.
        provider.loadPersonalizedInAppContentBlocks(
            data: PersonalizedInAppContentBlockResponseData.self,
            customerIds: ids,
            inAppContentBlocksIds: idsForDownload
        ) { [weak self] data in
            guard let self else { return }

            guard let waiters = self.claimInFlightCarouselFetch(
                placeholder: placeholder,
                validationToken: validationToken
            ) else {
                Exponea.logger.log(
                    .verbose,
                    message: "In-app Content Blocks Carousel: dropping stale personalized fetch result for placeholder \(placeholder) — token rotated during flight"
                )
                return
            }
            guard self.cacheGeneration == generation else {
                ensureBackground {
                    waiters.forEach {
                        $0.initial?()
                        $0.completion?()
                    }
                }
                return
            }

            ensureBackground {
                let refreshStaticViewContentDescriptions = (data.data?.data ?? []).map { $0.describeDetailed() }
                Exponea.logger.log(.verbose, message: "In-app Content Blocks refreshStaticViewContent data: \(refreshStaticViewContentDescriptions)")
                let personalizedWithPayload: [PersonalizedInAppContentBlockResponse] = data.data?.data ?? []
                let applied = self.updateMessagesIfCurrent(generation: generation) { messages in
                    for (index, inAppContentBlocks) in messages.enumerated() {
                        if var personalized = personalizedWithPayload.first(where: { $0.id == inAppContentBlocks.id }) {
                            personalized.ttlSeen = Date()
                            messages[index].personalizedMessage = personalized
                        }
                    }
                }
                guard applied else {
                    waiters.forEach {
                        $0.initial?()
                        $0.completion?()
                    }
                    return
                }
                // Fan-out: broadcast the single shared validation pass to every waiter.
                // `startCarouselImageValidation` internally one-shots its `initialCompletion`
                // via the `initialSent` atomic, so these wrappers fire each waiter's
                // `initial` exactly once (matching the per-waiter pre-dedup contract)
                // and each waiter's `completion` exactly once.
                let broadcastInitial: EmptyBlock = {
                    for waiter in waiters { waiter.initial?() }
                }
                let broadcastCompletion: EmptyBlock = {
                    for waiter in waiters { waiter.completion?() }
                }
                self.startCarouselImageValidation(
                    placeholder: placeholder,
                    responses: personalizedWithPayload,
                    validationToken: validationToken,
                    initialCompletion: broadcastInitial,
                    completion: broadcastCompletion
                )
            }
        }
    }

    private func startCarouselImageValidation(
        placeholder: String,
        responses: [PersonalizedInAppContentBlockResponse],
        validationToken: UUID,
        initialCompletion: EmptyBlock?,
        completion: EmptyBlock?
    ) {
        let candidates = responses.filter { $0.status == .ok }
        guard !candidates.isEmpty else {
            initialCompletion?()
            completion?()
            return
        }
        let priorityById = Dictionary(
            uniqueKeysWithValues: inAppContentBlockMessages.map { ($0.id, $0.loadPriority ?? 0) }
        )
        let sortedCandidates = candidates.sorted { lhs, rhs in
            let lhsPriority = priorityById[lhs.id] ?? 0
            let rhsPriority = priorityById[rhs.id] ?? 0
            if lhsPriority == rhsPriority {
                return lhs.id < rhs.id
            }
            return lhsPriority > rhsPriority
        }
        let semaphore = DispatchSemaphore(value: maxCarouselValidationConcurrency)
        let group = DispatchGroup()
        let initialSent = Atomic(wrappedValue: false)
        // Token-based cancellation scoped to the reloading placeholder so that parallel carousels
        // for different placeholders do not cancel each other. `shouldCancel` only instructs workers
        // to skip the expensive image download — completion callbacks still fire so the UI side can
        // make its own decision (it has its own `reloadToken` guard).
        let shouldCancel: () -> Bool = { [weak self] in
            guard let self else { return true }
            return self.carouselValidationTokens[placeholder] != validationToken
        }
        // Stale write protection: only persist state transitions while this run is still current.
        let writeStateIfCurrent: (String, ImageValidationState) -> Void = { [weak self] messageId, state in
            guard let self else { return }
            self._imageValidationStates.changeValue { states in
                guard self.carouselValidationTokens[placeholder] == validationToken else { return }
                states[messageId] = state
            }
        }
        for response in sortedCandidates {
            if shouldCancel() {
                break
            }
            writeStateIfCurrent(response.id, .pending)
            group.enter()
            carouselValidationQueue.async { [weak self] in
                semaphore.wait()
                defer {
                    semaphore.signal()
                    group.leave()
                }
                guard let self else { return }
                if shouldCancel() {
                    return
                }
                let preparedResponse = self.preparePersonalizedResponseForRender(
                    response,
                    makeResourcesOffline: true
                )
                let isCorrupted = preparedResponse.isCorruptedImage
                if shouldCancel() {
                    return
                }
                self.updatePersonalizedResponseIfCurrent(
                    response: preparedResponse,
                    placeholder: placeholder,
                    validationToken: validationToken
                )
                self.updateImageValidationState(
                    messageId: response.id,
                    placeholder: placeholder,
                    validationToken: validationToken,
                    isCorrupted: isCorrupted
                )
                if !isCorrupted {
                    var shouldCall = false
                    initialSent.changeValue { value in
                        if !value {
                            value = true
                            shouldCall = true
                        }
                    }
                    if shouldCall {
                        initialCompletion?()
                    }
                }
            }
        }
        group.notify(queue: carouselValidationQueue) {
            var shouldCall = false
            initialSent.changeValue { value in
                if !value {
                    value = true
                    shouldCall = true
                }
            }
            if shouldCall {
                initialCompletion?()
            }
            completion?()
        }
    }

    /// Applies the state transition only when `validationToken` is still active for `placeholder`.
    internal func updateImageValidationState(
        messageId: String,
        placeholder: String,
        validationToken: UUID,
        isCorrupted: Bool
    ) {
        let newState: ImageValidationState = isCorrupted ? .corrupted : .valid
        var applied = false
        _imageValidationStates.changeValue { states in
            guard self.carouselValidationTokens[placeholder] == validationToken else { return }
            states[messageId] = newState
            applied = true
        }
        guard applied else { return }
        _inAppContentBlockMessages.changeValue { messages in
            if let index = messages.firstIndex(where: { $0.id == messageId }) {
                messages[index].personalizedMessage?.isCorruptedImage = isCorrupted
            }
        }
    }

    internal func updatePersonalizedResponseIfCurrent(
        response: PersonalizedInAppContentBlockResponse,
        placeholder: String,
        validationToken: UUID
    ) {
        _inAppContentBlockMessages.changeValue { messages in
            guard self.carouselValidationTokens[placeholder] == validationToken else { return }
            guard let index = messages.firstIndex(where: { $0.id == response.id }) else { return }
            var personalized = response
            personalized.ttlSeen = messages[index].personalizedMessage?.ttlSeen ?? Date()
            messages[index].personalizedMessage = personalized
        }
    }

    func refreshMessage(message: InAppContentBlockResponse, completion: TypeBlock<InAppContentBlockResponse>?) {
        guard !message.id.isEmpty, let ids = try? DatabaseManager().currentCustomer.ids else {
            return
        }
        let generation = cacheGeneration
        // Force refresh bypasses conditional revalidation.
        provider.loadPersonalizedInAppContentBlocks(
            data: PersonalizedInAppContentBlockResponseData.self,
            customerIds: ids,
            inAppContentBlocksIds: [message.id]
        ) { [weak self] data in
            guard let self else { return }
            ensureBackground {
                guard self.cacheGeneration == generation else { return }
                let personalizedWithPayload: [PersonalizedInAppContentBlockResponse] = data.data?.data
                    .filter { $0.id == message.id }
                    .compactMap { response in
                        self.preparePersonalizedResponseForRender(
                            response,
                            makeResourcesOffline: true
                        )
                    } ?? []
                if let personal = personalizedWithPayload.first {
                    self._imageValidationStates.changeValue { states in
                        guard self.cacheGeneration == generation else { return }
                        states[personal.id] = personal.isCorruptedImage ? .corrupted : .valid
                    }
                }
                var updatedMessage: InAppContentBlockResponse?
                let applied = self.updateMessagesIfCurrent(generation: generation) { messages in
                    for (index, inAppContentBlocks) in messages.enumerated() {
                        if let personal = personalizedWithPayload.first, inAppContentBlocks.id == personal.id {
                            var personalized = personal
                            personalized.ttlSeen = Date()
                            if messages[index].personalizedMessage != nil {
                                messages[index].personalizedMessage = personalized
                            }
                            updatedMessage = messages[index]
                        }
                    }
                }
                guard applied else { return }
                if let updatedMessage {
                    Exponea.logger.log(.verbose, message: "In-app Content Blocks refreshed personalized: \(updatedMessage.id)")
                    completion?(updatedMessage)
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
                isCarouselLoading = false
                return
            }
            let idsForDownload = inAppContentBlockMessages.filter { $0.placeholders.contains(placeholder) }.map { $0.id }
            guard !idsForDownload.isEmpty else {
                dataCompletion?([])
                continueWithCarouselQueue(dataCompletion: dataCompletion)
                return
            }
            let generation = cacheGeneration
            // Fresh fetch required for carousel rotation and image validation.
            provider.loadPersonalizedInAppContentBlocks(
                data: PersonalizedInAppContentBlockResponseData.self,
                customerIds: ids,
                inAppContentBlocksIds: idsForDownload
            ) { [weak self] data in
                guard let self else { return }
                ensureBackground {
                    guard self.cacheGeneration == generation else {
                        dataCompletion?([])
                        self.continueWithCarouselQueue(dataCompletion: dataCompletion)
                        return
                    }
                    let refreshStaticViewContentDescriptions = (data.data?.data ?? []).map { $0.describeDetailed() }
                    Exponea.logger.log(.verbose, message: "In-app Content Blocks refreshStaticViewContent data: \(refreshStaticViewContentDescriptions)")
                    let personalizedWithPayload: [PersonalizedInAppContentBlockResponse] = data.data?.data.compactMap { response in
                        self.preparePersonalizedResponseForRender(
                            response,
                            makeResourcesOffline: true
                        )
                    } ?? []
                    self._imageValidationStates.changeValue { state in
                        guard self.cacheGeneration == generation else { return }
                        personalizedWithPayload.forEach { personalized in
                            state[personalized.id] = personalized.isCorruptedImage ? .corrupted : .valid
                        }
                    }
                    var updatedContentBlocksForTelemetry: [InAppContentBlockResponse] = []
                    let applied = self.updateMessagesIfCurrent(generation: generation) { messages in
                        for (index, inAppContentBlocks) in messages.enumerated() {
                            if var personalized = personalizedWithPayload.first(where: { $0.id == inAppContentBlocks.id }) {
                                personalized.ttlSeen = Date()
                                messages[index].personalizedMessage = personalized
                                updatedContentBlocksForTelemetry.append(messages[index])
                            }
                        }
                    }
                    guard applied else {
                        dataCompletion?([])
                        self.continueWithCarouselQueue(dataCompletion: dataCompletion)
                        return
                    }
                    self.trackTelemetryForFetch(.contentBlockPersonalisedFetch, updatedContentBlocksForTelemetry)
                    let toReturn = self.inAppContentBlockMessages.filter { $0.placeholders.contains(placeholder) }
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
        // Public API: host apps may call from any thread. All access to `staticQueue` and
        // `isStaticUpdating` is serialized on the main queue — hop there unconditionally.
        onMain { [weak self] in
            guard let self else { return }
            guard self.isCatalogReady else {
                self.ensureCatalogLoaded { [weak self] isLoaded in
                    guard let self else { return }
                    if isLoaded {
                        self.refreshStaticViewContent(staticQueueData: staticQueueData)
                    } else {
                        onMain {
                            staticQueueData.completion?(.init(html: "", tag: 0, message: nil))
                        }
                    }
                }
                return
            }
            Exponea.logger.log(.verbose, message: "In-app Content Blocks refreshStaticViewContent")
            self.staticQueue.append(staticQueueData)
            guard !self.isStaticUpdating else { return }
            self.isStaticUpdating = true
            self.scheduleBatchProcessing()
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

        message.tags?.insert(tag)

        if let personalized = message.personalizedMessage, let payloadData = personalized.htmlPayload?.html?.data(using: .utf8), !payloadData.isEmpty {
            Exponea.logger.log(
                .verbose,
                message: "In-app Content Blocks prepareInAppContentBlocksStaticView personalized \(personalized.describeDetailed())."
            )
            _inAppContentBlockMessages.changeValue { messages in
                guard let idx = messages.firstIndex(where: { $0.id == message.id }) else { return }
                if messages[idx].personalizedMessage?.ttlSeen == nil {
                    messages[idx].personalizedMessage?.ttlSeen = Date()
                }
            }
            if let html = personalized.htmlPayload?.html, !html.isEmpty {
                return .init(html: html, tag: tag, message: message)
            }
        } else if message.personalizedMessage != nil {
            return nil
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
        } else {
            clearHeightCalculationSelectionIfIdle()
        }
    }

    func loadContentForPlacehoder(newValue: UsedInAppContentBlocks, message: InAppContentBlockResponse) {
        if let cachedHeight = cachedHeight(for: newValue.placeholder, messageId: newValue.messageId) {
            updateDisplayedState(for: message.id)
            upsertUsedInAppContentBlockHeight(cachedHeight, newValue: newValue, message: message)
            prewarmContentBlockWebViews()
            notifyRefreshCallback(
                indexPath: newValue.indexPath,
                source: "loadContentForPlaceholder.cachedHeight",
                placeholder: newValue.placeholder
            )
            clearHeightCalculationSelectionIfIdle()
            return
        }
        if !isUpdating {
            isUpdating = true
            let savedNewValue = newValue
            let savedPlaceholder = message
            loadPersonalizedInAppContentBlocks(for: savedNewValue.messageId, tags: [savedNewValue.tag]) { [weak self] in
                guard let self else { return }
                self.calculator.heightUpdate = { height in
                    let tag = self.createUniqueTag(placeholder: message)
                    Exponea.logger.log(.verbose, message: "In-app Content Blocks loadContentForPlacehoder calculator data \(height)")
                    // Update display status
                    self.updateDisplayedState(for: message.id)
                    self._inAppContentBlockMessages.changeValue { messages in
                        guard let idx = messages.firstIndex(where: { $0.id == message.id }) else { return }
                        messages[idx].tags?.insert(tag)
                        messages[idx].indexPath = savedPlaceholder.indexPath
                    }
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
                        self.prewarmContentBlockWebViews()
                        self.notifyRefreshCallback(
                            indexPath: savedNewValue.indexPath,
                            source: "loadContentForPlaceholder.empty",
                            placeholder: savedNewValue.placeholder
                        )
                    } else {
                        if let indexOfSavedInAppContentBlocks: Int = self.usedInAppContentBlocks[placeholderValueFromUsedLine]?.firstIndex(where: { $0.indexPath == savedPlaceholder.indexPath && $0.height == 0 }) {
                            if var savedInAppContentBlocks = self.usedInAppContentBlocks[placeholderValueFromUsedLine]?[indexOfSavedInAppContentBlocks] {
                                if savedInAppContentBlocks.height == 0 {
                                    savedInAppContentBlocks.height = height.height
                                }
                                self._usedInAppContentBlocks.changeValue(with: { $0[placeholderValueFromUsedLine]?[indexOfSavedInAppContentBlocks] = savedInAppContentBlocks })
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
                        self.prewarmContentBlockWebViews()
                        self.notifyRefreshCallback(
                            indexPath: savedNewValue.indexPath,
                            source: "loadContentForPlaceholder.update",
                            placeholder: savedNewValue.placeholder
                        )
                    }
                }
                guard let html = self.inAppContentBlockMessages.first(where: { $0.tags?.contains(newValue.tag) == true })?.personalizedMessage?.htmlPayload?.html, !html.isEmpty else {
                    onMain {
                        self.continueWithQueue()
                    }
                    return
                }
                self.prewarmContentBlockWebViews()
                self.calculator.loadHtml(placedholderId: message.id, html: html)
            }
        } else {
            let result = dedupEnqueue(message: message, newValue: newValue)
            if result == .enqueued {
                Exponea.logger.log(.verbose, message:
                    """
                    In-app Content Blocks added to queue
                    newValue: \(newValue.describeDetailed())
                    placeholder: \(message.describe())
                    """
                )
            }
        }
    }

    func cachedHeight(for placeholder: String, messageId: String) -> CGFloat? {
        usedInAppContentBlocks[placeholder]?.first {
            $0.messageId == messageId && $0.height > 0
        }?.height
    }

    func upsertUsedInAppContentBlockHeight(
        _ height: CGFloat,
        newValue: UsedInAppContentBlocks,
        message: InAppContentBlockResponse
    ) {
        let placeholder = newValue.placeholder
        _usedInAppContentBlocks.changeValue { store in
            var usedBlocks = store[placeholder] ?? []
            if let index = usedBlocks.firstIndex(where: {
                $0.indexPath == newValue.indexPath && $0.messageId == message.id
            }) {
                usedBlocks[index].height = height
                usedBlocks[index].tag = newValue.tag
                usedBlocks[index].placeholderData = message
            } else {
                usedBlocks.append(.init(
                    tag: newValue.tag,
                    indexPath: newValue.indexPath,
                    messageId: message.id,
                    placeholder: placeholder,
                    height: height,
                    placeholderData: message
                ))
            }
            store[placeholder] = usedBlocks
        }
    }
}

// MARK: - Test support
extension InAppContentBlocksManager {

    internal func test_setCatalogReady() {
        catalogStateLock.lock()
        catalogState = .ready
        catalogWaiters.removeAll()
        catalogStateLock.unlock()
    }

    internal func test_seedPlaceholderCacheStores(
        placeholderId: String,
        messageId: String,
        height: CGFloat = 100
    ) {
        let used = UsedInAppContentBlocks(
            tag: 1,
            indexPath: IndexPath(row: 0, section: 0),
            messageId: messageId,
            placeholder: placeholderId,
            height: height,
            isActive: true
        )
        _usedInAppContentBlocks.changeValue { $0[placeholderId] = [used] }
        _heightCalculationMessageByPlaceholder.changeValue { $0[placeholderId] = messageId }
    }

    internal func test_heightSelectionMessageId(for placeholderId: String) -> String? {
        heightCalculationMessageByPlaceholder[placeholderId]
    }

    internal var test_cacheGeneration: UInt {
        cacheGeneration
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

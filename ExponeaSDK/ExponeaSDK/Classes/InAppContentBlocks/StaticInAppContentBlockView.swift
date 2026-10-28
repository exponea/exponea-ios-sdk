//
//  StaticInAppContentBlockView.swift
//  ExponeaSDK
//
//  Created by Ankmara on 25.06.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import UIKit
import WebKit
#if canImport(ExponeaSDKShared)
import ExponeaSDKShared
#endif

public final class StaticInAppContentBlockView: UIView, WKNavigationDelegate {

    // MARK: - Properties
    public var contentReadyCompletion: TypeBlock<Bool>?
    public var heightCompletion: TypeBlock<Int>?
    public var behaviourCallback: InAppContentBlockCallbackType = DefaultInAppContentBlockCallback()
    public var skipNativeRendering: Bool = false

    private lazy var webview: WKWebView = {
        let userScript: WKUserScript = .init(source: inAppContentBlocksManager.disableZoomSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let configuration = HtmlNormalizer.createWebViewConfiguration()
        configuration.userContentController.addUserScript(userScript)
        if let contentRuleList = inAppContentBlocksManager.contentRuleList {
            configuration.userContentController.add(contentRuleList)
        }
        let newWebview = ContentBlockWebViewFactory.makeWebView(
            frame: .init(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 0),
            configuration: configuration
        )
        newWebview.scrollView.showsVerticalScrollIndicator = false
        newWebview.scrollView.bounces = false
        newWebview.scrollView.contentInsetAdjustmentBehavior = .never
        newWebview.scrollView.contentInset = .zero
        newWebview.scrollView.verticalScrollIndicatorInsets = .zero
        newWebview.backgroundColor = .clear
        newWebview.isOpaque = false
        newWebview.translatesAutoresizingMaskIntoConstraints = false
        newWebview.navigationDelegate = self
        newWebview.tag = contentTag
        isWebviewCreated = true
        return newWebview
    }()

    override public var bounds: CGRect {
        didSet {
            guard let currentContentReadyFlag = contentReadyFlag else {
                return
            }
            contentReadyFlag = nil
            contentReadyCompletion?(currentContentReadyFlag)
        }
    }

    private let placeholder: String
    private lazy var inAppContentBlocksManager = InAppContentBlocksManager.manager
    /// Called on the main thread whenever the rendered content block changes height, only once
    /// there is content to show. When shown content goes away, it is called once with height `0`.
    /// Setting it does not create a web view, so prefer it over `calculator.publicHeightUpdate`.
    public var publicHeightUpdate: TypeBlock<CalculatorData>?
    private var hasReportedPublicHeight = false
    /// Measures the content block height in an offscreen web view.
    /// The first access creates that web view, so avoid reading it before content arrives;
    /// use `publicHeightUpdate` on this view to observe height changes instead.
    public lazy var calculator: WKWebViewHeightCalculator = makeCalculator()
    private var isWebviewCreated = false
    private var isCalculatorCreated = false
    private var contentTag: Int = 0 {
        didSet {
            if isWebviewCreated {
                webview.tag = contentTag
            }
        }
    }
    private var html: String = ""
    private var height: NSLayoutConstraint?
    private var contentReadyFlag: Bool?
    private var assignedMessage: InAppContentBlockResponse?
    private var didReportMessageShown = false

    public init(placeholder: String, deferredLoad: Bool = false, heightCompletion: TypeBlock<Int>? = nil) {
        self.placeholder = placeholder
        self.heightCompletion = heightCompletion
        super.init(frame: .zero)

        if !deferredLoad {
            getContent()
        }

        IntegrationManager.shared.onIntegrationStoppedCallbacks.append { [weak self] in
            guard let self else { return }
            self.height?.constant = 0
            self.sizeToFit()
            self.layoutIfNeeded()
            onMain { self.reportPublicHeightCollapsedIfNeeded() }
        }
    }

    private func makeCalculator() -> WKWebViewHeightCalculator {
        let calculator = InAppContentBlocksManager.manager.preparedStaticHeightCalculator()
        isCalculatorCreated = true
        calculator.heightUpdate = { [weak self] height in
            guard let self else { return }
            guard height.height > 0 else {
                self.notifyContentReadyState(true)
                self.reportMessageShownIfNeeded()
                onMain { self.reportPublicHeightCollapsedIfNeeded() }
                return
            }
            let usableHeight = height.height
            // The display web view is created lazily, so check it on main.
            onMain {
                if self.webview.superview != nil {
                    self.height?.constant = usableHeight
                    self.heightCompletion?(Int(usableHeight))
                    self.reportPublicHeight(height)
                    self.webview.loadHTMLString(self.html, baseURL: nil)
                    self.webview.layoutIfNeeded()
                    self.reportMessageShownIfNeeded()
                    return
                }
                self.replacePlaceholder(inputView: self, loadedInAppContentBlocksView: self.webview, height: usableHeight) {
                    self.heightCompletion?(Int(usableHeight))
                    self.reportPublicHeight(height)
                    self.prepareContentReadyState(true)
                    self.reportMessageShownIfNeeded()
                }
            }
        }
        return calculator
    }

    /// Starts deferred loading with conditional revalidation when a stored ETag exists.
    /// Use `reload()` for an explicit force refresh.
    public func load() {
        getContent(force: false)
    }

    public func reload() {
        getContent(force: true)
    }

    private func reportPublicHeight(_ data: CalculatorData) {
        hasReportedPublicHeight = true
        publicHeightUpdate?(data)
    }

    // An empty placeholder reports no height; only shown content that goes away reports 0.
    private func reportPublicHeightCollapsedIfNeeded() {
        guard hasReportedPublicHeight else { return }
        hasReportedPublicHeight = false
        publicHeightUpdate?(.init(height: 0, placeholderId: placeholder))
    }

    // MARK: - Test-support accessors

    func loadContentForTest(html: String) {
        loadContent(html: html, message: nil)
    }

    var hasCreatedWebViews: Bool {
        isWebviewCreated || isCalculatorCreated
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // `load()` and `reload()` can be called from any thread. Content is prepared on the calling
    // thread, since it can wait for resource downloads. The view state, including the lazily created
    // web view and its tag, is only touched on the main thread.
    private func getContent(force: Bool = false) {
        guard !IntegrationManager.shared.isStopped else {
            Exponea.logger.log(.verbose, message: "In-app content blocks UI is unavailable, SDK is stopping")
            return
        }
        guard !placeholder.isEmpty else {
            replacePlaceholder(inputView: self, loadedInAppContentBlocksView: .init(frame: .zero), height: 0) {
                self.prepareContentReadyState(false)
                self.behaviourCallback.onNoMessageFound(placeholderId: self.placeholder)
            }
            return
        }
        let data = inAppContentBlocksManager.prepareInAppContentBlocksStaticView(
            placeholderId: placeholder,
            makeResourcesOffline: !skipNativeRendering
        )
        let makeResourcesOffline = !skipNativeRendering
        onMain { [weak self] in
            guard let self else { return }
            self.contentTag = data.tag
            if data.html.isEmpty || force {
                self.inAppContentBlocksManager.refreshStaticViewContent(staticQueueData: .init(
                    tag: data.tag,
                    placeholderId: self.placeholder,
                    makeResourcesOffline: makeResourcesOffline,
                    skipEtag: force
                ) { [weak self] result in
                    guard let self else { return }
                    self.contentTag = result.tag
                    self.loadContent(
                        html: result.html,
                        message: result.message
                    )
                })
            } else {
                self.loadContent(
                    html: data.html,
                    message: data.message
                )
            }
        }
    }

    private func loadContent(
        html: String,
        message: InAppContentBlockResponse?
    ) {
        guard !html.isEmpty else {
            if skipNativeRendering {
                onMain {
                    self.notifyContentReadyState(true)
                    self.behaviourCallback.onNoMessageFound(placeholderId: self.placeholder)
                }
            } else {
                replacePlaceholder(inputView: self, loadedInAppContentBlocksView: .init(frame: .zero), height: 0) {
                    self.reportPublicHeightCollapsedIfNeeded()
                    self.prepareContentReadyState(true)
                    self.behaviourCallback.onNoMessageFound(placeholderId: self.placeholder)
                }
            }
            return
        }
        self.html = html
        self.assignedMessage = message
        self.didReportMessageShown = false
        if skipNativeRendering {
            onMain {
                self.notifyContentReadyState(true)
                self.reportMessageShownIfNeeded()
            }
        } else {
            InAppContentBlockRenderHistory.shared.recordRender()
            // The calculator is a WKWebView and may be created here.
            onMain {
                self.calculator.loadHtml(placedholderId: self.placeholder, html: html)
            }
        }
    }

    private func replacePlaceholder(
        inputView: UIView,
        loadedInAppContentBlocksView: UIView,
        height: CGFloat,
        onCompletion: @escaping EmptyBlock
    ) {
        onMain {
            let duration: TimeInterval = 0.3
            loadedInAppContentBlocksView.alpha = 0
            UIView.animate(withDuration: duration) {
                loadedInAppContentBlocksView.alpha = 0
            } completion: { [weak self] isDone in
                guard let self else {
                    onCompletion()
                    return
                }
                if isDone {
                    loadedInAppContentBlocksView.constraints.forEach { cons in
                        self.removeConstraint(cons)
                    }
                    loadedInAppContentBlocksView.removeFromSuperview()
                    inputView.addSubview(loadedInAppContentBlocksView)
                    loadedInAppContentBlocksView.topAnchor.constraint(equalTo: inputView.topAnchor).isActive = true
                    loadedInAppContentBlocksView.leadingAnchor.constraint(equalTo: inputView.leadingAnchor).isActive = true
                    loadedInAppContentBlocksView.trailingAnchor.constraint(equalTo: inputView.trailingAnchor).isActive = true
                    if self.height != nil {
                        self.height?.constant = height
                    } else {
                        self.height = loadedInAppContentBlocksView.heightAnchor.constraint(equalToConstant: height)
                        self.height?.isActive = true
                    }
                    loadedInAppContentBlocksView.bottomAnchor.constraint(equalTo: inputView.bottomAnchor).isActive = true
                    loadedInAppContentBlocksView.sizeToFit()
                    loadedInAppContentBlocksView.layoutIfNeeded()
                    UIView.animate(withDuration: duration) {
                        loadedInAppContentBlocksView.alpha = 1
                    }
                    // No content so far: don't create a WKWebView just to load nothing.
                    if self.isWebviewCreated {
                        self.webview.loadHTMLString(self.html, baseURL: nil)
                    }
                    onCompletion()
                }
            }
        }
    }

    public func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        let handled = handleUrlClick(navigationAction.request.url)
        decisionHandler(handled ? .cancel : .allow)
    }

    private func determineActionType(_ action: ActionInfo) -> InAppContentBlockActionType {
        switch action.actionType {
        case .browser:
            return .browser
        case .deeplink:
            return .deeplink
        case .close:
            return .close
        }
    }

    private func reportMessageShownIfNeeded() {
        guard !didReportMessageShown, let message = assignedMessage else { return }
        didReportMessageShown = true
        behaviourCallback.onMessageShown(
            placeholderId: placeholder,
            contentBlock: message
        )
        Exponea.shared.telemetryManager?.report(
            eventWithType: .contentBlockShown,
            properties: [
                "type": (message.content == nil ? "personal" : "static"),
                "messageId": message.id,
                "placeholders": TelemetryUtility.toJson(message.placeholders)
            ]
        )
    }

    // directly calls `contentReadyCompletion` with given contentReady flag
    // use this method in case that no layout is going to be invoked
    private func notifyContentReadyState(_ contentReady: Bool) {
        onMain {
            self.contentReadyCompletion?(contentReady)
        }
    }

    // registers contentReady flag that will be used for `contentReadyCompletion` when layout/bounds will be updated
    private func prepareContentReadyState(_ contentReady: Bool) {
        contentReadyFlag = contentReady
    }

    public func invokeActionClick(actionUrl: String) {
        Exponea.logger.log(.verbose, message: "InAppCB: Manual action \(actionUrl) invoked on placeholder \(placeholder)")
        _ = handleUrlClick(actionUrl.cleanedURL())
    }

    private func handleUrlClick(_ actionUrl: URL?) -> Bool {
        guard let actionUrl else {
            Exponea.logger.log(.warning, message: "InAppCB: Unknown action URL: \(String(describing: actionUrl))")
            return false
        }
        if isOfflineResourceNav(actionUrl) {
            return false
        }
        if isBlankNav(actionUrl) {
            // on first load
            // nothing to do, not need to continue loading
            return false
        }
        guard let message = assignedMessage else {
            Exponea.logger.log(.error, message: "InAppCB: Placeholder \(placeholder) has invalid state - action or message is invalid")
            behaviourCallback.onError(placeholderId: placeholder, contentBlock: nil, errorMessage: "Invalid action definition")
            // webView has to stop navigation, missing message data are internal issue
            return true
        }
        let webAction: WebActionManager = .init { _ in
            InAppContentBlocksManager.manager.updateInteractedState(for: message.id)
            self.behaviourCallback.onCloseClicked(placeholderId: self.placeholder, contentBlock: message)
            self.reload()
        } onActionCallback: { action in
            InAppContentBlocksManager.manager.updateInteractedState(for: message.id)
            let actionType = self.determineActionType(action)
            if actionType == .close {
                self.behaviourCallback.onCloseClicked(placeholderId: self.placeholder, contentBlock: message)
            } else {
                self.behaviourCallback.onActionClicked(
                    placeholderId: self.placeholder,
                    contentBlock: message,
                    action: .init(
                        name: action.buttonText,
                        url: action.actionUrl,
                        type: actionType
                    )
                )
            }
            self.reload()
        } onErrorCallback: { error in
            Exponea.logger.log(.error, message: "WebActionManager error \(error.localizedDescription)")
        }
        webAction.htmlPayload = message.normalizedResult ?? message.personalizedMessage?.htmlPayload 
        let handled = webAction.handleActionClick(actionUrl)
        if handled {
            Exponea.logger.log(.verbose, message: "[HTML] Action \(actionUrl.absoluteString) has been handled")
        } else {
            Exponea.logger.log(.verbose, message: "[HTML] Action \(actionUrl.absoluteString) has not been handled, continue")
        }
        return handled
    }

    private func isBlankNav(_ url: URL?) -> Bool {
        url?.absoluteString == "about:blank"
    }

    private func isOfflineResourceNav(_ url: URL?) -> Bool {
        url?.scheme?.lowercased() == HtmlNormalizer.offlineResourceScheme
    }
}

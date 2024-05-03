//
//  StaticInAppContentBlockView.swift
//  ExponeaSDK
//
//  Created by Ankmara on 25.06.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import UIKit
import WebKit

public final class StaticInAppContentBlockView: UIView, WKNavigationDelegate {

    // MARK: - Properties
    public var contentReadyCompletion: TypeBlock<Bool>?
    public var heightCompletion: TypeBlock<Int>?
    public var behaviourCallback: InAppContentBlockCallbackType = DefaultInAppContentBlockCallback()

    private lazy var webview: WKWebView = {
        let userScript: WKUserScript = .init(source: inAppContentBlocksManager.disableZoomSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let newWebview = WKWebView(frame: .init(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 0))
        newWebview.scrollView.showsVerticalScrollIndicator = false
        newWebview.scrollView.bounces = false
        newWebview.backgroundColor = .clear
        newWebview.isOpaque = false
        newWebview.translatesAutoresizingMaskIntoConstraints = false
        let configuration = newWebview.configuration
        configuration.userContentController.addUserScript(userScript)
        if let contentRuleList = inAppContentBlocksManager.contentRuleList {
            configuration.userContentController.add(contentRuleList)
        }
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
    private lazy var calculator: WKWebViewHeightCalculator = .init()
    private var html: String = ""
    private var height: NSLayoutConstraint?
    private var contentReadyFlag: Bool?
    private var assignedMessage: InAppContentBlockResponse?

    public init(placeholder: String, deferredLoad: Bool = false, heightCompletion: TypeBlock<Int>? = nil) {
        self.placeholder = placeholder
        self.heightCompletion = heightCompletion
        super.init(frame: .zero)

        webview.navigationDelegate = self
        calculator.heightUpdate = { [weak self] height in
            guard let self, height.height > 0 else {
                guard let self else {
                    return
                }
                self.notifyContentReadyState(true)
                guard let message = self.assignedMessage else {
                    return
                }
                self.behaviourCallback.onMessageShown(
                    placeholderId: placeholder,
                    contentBlock: message
                )
                return
            }
            let usableHeight = height.height - calculator.defaultPadding
            self.replacePlaceholder(inputView: self, loadedInAppContentBlocksView: self.webview, height: usableHeight) {
                self.heightCompletion?(Int(usableHeight))
                self.prepareContentReadyState(true)
                guard let message = self.assignedMessage else {
                    return
                }
                self.behaviourCallback.onMessageShown(
                    placeholderId: placeholder,
                    contentBlock: message
                )
            }
        }
        if !deferredLoad {
            getContent()
        }
    }

    public func reload() {
        getContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func getContent() {
        guard !placeholder.isEmpty else {
            replacePlaceholder(inputView: self, loadedInAppContentBlocksView: .init(frame: .zero), height: 0) {
                self.prepareContentReadyState(false)
                self.behaviourCallback.onNoMessageFound(placeholderId: self.placeholder)
            }
            return
        }
        let data = inAppContentBlocksManager.prepareInAppContentBlocksStaticView(placeholderId: placeholder)
        webview.tag = data.tag
        if data.html.isEmpty {
            inAppContentBlocksManager.refreshStaticViewContent(staticQueueData: .init(tag: data.tag, placeholderId: placeholder) {
                self.webview.tag = $0.tag
                self.loadContent(html: $0.html, message: $0.message)
            })
        } else {
            loadContent(html: data.html, message: data.message)
        }
    }

    private func loadContent(html: String, message: InAppContentBlockResponse?) {
        guard !html.isEmpty else {
            replacePlaceholder(inputView: self, loadedInAppContentBlocksView: .init(frame: .zero), height: 0) {
                self.prepareContentReadyState(true)
                self.behaviourCallback.onNoMessageFound(placeholderId: self.placeholder)
            }
            return
        }
        self.html = html
        self.assignedMessage = message
        calculator.loadHtml(placedholderId: placeholder, html: html)
        // calls `notifyContentReadyState` inside calculator
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
                    self.webview.loadHTMLString(self.html, baseURL: nil)
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
        case .unknown:
            if action.actionUrl == "https://exponea.com/close_action" {
                return .close
            }
            if action.actionUrl.starts(with: "http://") || action.actionUrl.starts(with: "https://") {
                return .browser
            }
            return .deeplink
        }
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
        let webAction: WebActionManager = .init {
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
}

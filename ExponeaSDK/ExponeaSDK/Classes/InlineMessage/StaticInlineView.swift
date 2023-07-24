//
//  StaticInlineView.swift
//  ExponeaSDK
//
//  Created by Ankmara on 25.06.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import UIKit
import WebKit

public final class StaticInlineView: UIView, WKNavigationDelegate {

    // MARK: - Properties
    public var refresh: EmptyBlock?
    private lazy var webview: WKWebView = {
        let userScript: WKUserScript = .init(source: inlineManager.disableZoomSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let newWebview = WKWebView(frame: .init(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 0))
        newWebview.scrollView.showsVerticalScrollIndicator = false
        newWebview.scrollView.bounces = false
        newWebview.translatesAutoresizingMaskIntoConstraints = false
        let configuration = newWebview.configuration
        configuration.userContentController.addUserScript(userScript)
        if let contentRuleList = inlineManager.contentRuleList {
            configuration.userContentController.add(contentRuleList)
        }
        return newWebview
    }()

    private let placeholder: String
    private lazy var inlineManager = InlineMessageManager.manager
    private lazy var calculator: WKWebViewHeightCalculator = .init()
    private var html: String = ""
    private var height: NSLayoutConstraint?

    public init(placeholder: String) {
        self.placeholder = placeholder
        super.init(frame: .zero)

        webview.navigationDelegate = self
        calculator.heightUpdate = { [weak self] height in
            guard let self = self, height.height > 0 else { return }
            self.replacePlaceholder(inputView: self, loadedInlineView: self.webview, height: height.height - 15)
        }
        getContent()
    }

    public func reload() {
        getContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func getContent() {
        guard !placeholder.isEmpty else {
            replacePlaceholder(inputView: self, loadedInlineView: .init(frame: .zero), height: 0)
            return
        }
        let data = inlineManager.prepareInlineStaticView(placeholderId: placeholder)
        webview.tag = data.tag
        if data.html.isEmpty {
            inlineManager.refreshStaticViewContent(staticQueueData: .init(tag: data.tag, placeholderId: placeholder) {
                self.loadContent(html: $0.html)
            })
        } else {
            loadContent(html: data.html)
        }
    }

    private func loadContent(html: String) {
        guard !html.isEmpty else {
            replacePlaceholder(inputView: self, loadedInlineView: .init(frame: .zero), height: 0)
            return
        }
        self.html = html
        calculator.loadHtml(placedholderId: placeholder, html: html)
    }

    private func replacePlaceholder(inputView: UIView, loadedInlineView: UIView, height: CGFloat) {
        onMain {
            let duration: TimeInterval = 0.3
            loadedInlineView.alpha = 0
            UIView.animate(withDuration: duration) {
                loadedInlineView.alpha = 0
            } completion: { [weak self] isDone in
                guard let self else { return }
                if isDone {
                    loadedInlineView.removeFromSuperview()
                    inputView.addSubview(loadedInlineView)
                    loadedInlineView.topAnchor.constraint(equalTo: inputView.topAnchor, constant: 5).isActive = true
                    loadedInlineView.leadingAnchor.constraint(equalTo: inputView.leadingAnchor, constant: 5).isActive = true
                    loadedInlineView.trailingAnchor.constraint(equalTo: inputView.trailingAnchor, constant: -5).isActive = true
                    if self.height != nil {
                        self.height?.constant = height
                    } else {
                        self.height = loadedInlineView.heightAnchor.constraint(equalToConstant: height)
                        self.height?.isActive = true
                    }
                    loadedInlineView.bottomAnchor.constraint(equalTo: inputView.bottomAnchor, constant: -5).isActive = true
                    loadedInlineView.sizeToFit()
                    loadedInlineView.layoutIfNeeded()
                    UIView.animate(withDuration: duration) {
                        loadedInlineView.alpha = 1
                    }
                    self.webview.loadHTMLString(self.html, baseURL: nil)
                }
            }
        }
    }

    public func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        let result = inlineManager.inlinePlaceholders.first(where: { $0.tag == webView.tag })
        let webAction: WebActionManager = .init {
            let indexOfPlaceholder: Int = self.inlineManager.inlinePlaceholders.firstIndex(where: { $0.id == result?.id ?? "" }) ?? 0
            let currentDisplay = self.inlineManager.inlinePlaceholders[indexOfPlaceholder].displayState
            self.inlineManager.inlinePlaceholders[indexOfPlaceholder].displayState = .init(displayed: currentDisplay?.displayed, interacted: Date())
            if let message = result {
                Exponea.shared.trackInlineMessageClose(message: message, isUserInteraction: true)
            }
            self.reload()
        } onActionCallback: { action in
            let indexOfPlaceholder: Int = self.inlineManager.inlinePlaceholders.firstIndex(where: { $0.id == result?.id ?? "" }) ?? 0
            let currentDisplay = self.inlineManager.inlinePlaceholders[indexOfPlaceholder].displayState
            self.inlineManager.inlinePlaceholders[indexOfPlaceholder].displayState = .init(displayed: currentDisplay?.displayed, interacted: Date())
            if let message = result {
                Exponea.shared.trackInlineMessageClick(message: message, buttonText: action.buttonText, buttonLink: action.actionUrl)
            }
            self.inlineManager.urlOpener.openBrowserLink(action.actionUrl)
            self.reload()
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
    }
}

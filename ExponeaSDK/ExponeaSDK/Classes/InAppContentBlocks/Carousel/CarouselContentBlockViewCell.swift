//
//  CarouselContentBlockViewCell.swift
//  ExponeaSDK
//
//  Created by Ankmara on 22.07.2024.
//  Copyright © 2024 Exponea. All rights reserved.
//

import UIKit
import WebKit

class CarouselContentBlockViewCell: UICollectionViewCell, WKNavigationDelegate {
    private lazy var inAppContentBlocksManager = InAppContentBlocksManager.manager
    var webview = WKWebView()
    var assignedMessage: InAppContentBlockResponse?
    var placeholder: String = ""
    var actionClicked: EmptyBlock?
    var closeClicked: EmptyBlock?
    var touchCallback: EmptyBlock?
    var releaseCallback: EmptyBlock?
    var contentBlockCarouselCallback: DefaultContentBlockCarouselCallback?

    override func prepareForReuse() {
        super.prepareForReuse()

        contentBlockCarouselCallback = nil
        assignedMessage = nil
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(webview)
        webview.scrollView.showsVerticalScrollIndicator = false
        webview.scrollView.bounces = false
        webview.backgroundColor = .clear
        webview.isOpaque = false
        webview.translatesAutoresizingMaskIntoConstraints = false
        webview.navigationDelegate = self
        webview.topAnchor.constraint(equalTo: topAnchor).isActive = true
        webview.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        webview.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        webview.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        let userScript: WKUserScript = .init(source: inAppContentBlocksManager.disableZoomSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let configuration = webview.configuration
        configuration.userContentController.addUserScript(userScript)
        if let contentRuleList = inAppContentBlocksManager.contentRuleList {
            configuration.userContentController.add(contentRuleList)
        }
        contentView.backgroundColor = .clear

        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(checkAction))
        webview.addGestureRecognizer(gesture)
    }

    @objc func checkAction(sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began:
            touchCallback?()
        default:
            releaseCallback?()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func loadHtml(html: String, assignedMessage: InAppContentBlockResponse?, placeholder: String) {
        if html.isEmpty {
            contentBlockCarouselCallback?.onNoMessageFound(placeholderId: placeholder)
        }
        self.assignedMessage = assignedMessage
        self.placeholder = placeholder
        webview.loadHTMLString(html, baseURL: nil)
    }

    public func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        let handled = handleUrlClick(navigationAction.request.url)
        decisionHandler(handled ? .cancel : .allow)
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
            return true
        }
        let webAction: WebActionManager = .init { [weak self] _ in
            guard let self else { return }
            InAppContentBlocksManager.manager.updateInteractedState(for: message.id)
            self.contentBlockCarouselCallback?.onCloseClicked(placeholderId: self.placeholder, contentBlock: message)
            self.closeClicked?()
        } onActionCallback: { [weak self] action in
            guard let self else { return }
            InAppContentBlocksManager.manager.updateInteractedState(for: message.id)
            let actionType = self.determineActionType(action)
            if actionType == .close {
                self.contentBlockCarouselCallback?.onCloseClicked(placeholderId: self.placeholder, contentBlock: message)
            } else {
                self.contentBlockCarouselCallback?.onActionClickedSafari(
                    placeholderId: self.placeholder,
                    contentBlock: message,
                    action: .init(
                        name: action.buttonText,
                        url: action.actionUrl,
                        type: actionType
                    )
                )
            }
            self.actionClicked?()
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
}

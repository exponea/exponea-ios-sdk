//
//  WebActionsManager.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 11/01/2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation
import WebKit

final class WebActionManager: NSObject, WKNavigationDelegate {

    // MARK: - Properties

    var htmlPayload: NormalizedResult?

    private var onCloseCallback: (() -> Void)?
    private var onActionCallback: ((ActionInfo) -> Void)?
    private var onErrorCallback: ((ExponeaError) -> Void)?

    // MARK: - Init

    init(
        onCloseCallback: (() -> Void)? = nil,
        onActionCallback: ((ActionInfo) -> Void)? = nil,
        onErrorCallback: ((ExponeaError) -> Void)? = nil
    ) {
        self.onCloseCallback = onCloseCallback
        self.onActionCallback = onActionCallback
        self.onErrorCallback = onErrorCallback
    }

    // MARK: - Methods

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        let handled = handleActionClick(navigationAction.request.url)
        if handled {
            Exponea.logger.log(.verbose, message: "[HTML] Action \(navigationAction.request.url?.absoluteString ?? "Invalid") has been handled")
            decisionHandler(.cancel)
        } else {
            Exponea.logger.log(.verbose, message: "[HTML] Action \(navigationAction.request.url?.absoluteString ?? "Invalid") has not been handled, continue")
            decisionHandler(.allow)
        }
    }
}

private extension WebActionManager {

    func handleActionClick(_ url: URL?) -> Bool {
        Exponea.logger.log(.verbose, message: "[HTML] action for \(String(describing: url))")
        if isCloseAction(url) {
            onCloseCallback?()
            return true
        } else if isActionUrl(url) {
            guard let url = url,
                  let action = findActionByUrl(url) else {
                Exponea.logger.log(.error, message: "[HTML] Action URL \(url?.absoluteString ?? "<nil>") cannot be found as action")
                onErrorCallback?(ExponeaError.unknownError("Invalid Action URL - not found"))
                // anyway we define it as Action, so URL opening has to be prevented
                return true
            }
            onActionCallback?(action)
            return true
        } else if isBlankNav(url) {
            // on first load
            // nothing to do, not need to continue loading
            return false
        } else {
            Exponea.logger.log(.warning, message: "[HTML] Unknown action URL: \(String(describing: url))")
            onErrorCallback?(ExponeaError.unknownError("Invalid Action URL - unknown"))
            return false
        }
    }

    func isBlankNav(_ url: URL?) -> Bool {
        url?.absoluteString == "about:blank"
    }

    func isActionUrl(_ url: URL?) -> Bool {
        guard let url = url else {
            return false
        }
        return !isCloseAction(url) && findActionByUrl(url) != nil
    }

    func isCloseAction(_ url: URL?) -> Bool {
        guard let htmlPayload = htmlPayload else {
            return false
        }
        return url?.absoluteString == htmlPayload.closeActionUrl
    }

    func findActionByUrl(_ url: URL?) -> ActionInfo? {
        guard let url = url,
              let htmlPayload = htmlPayload else {
            return nil
        }
        return htmlPayload.actions.first(where: { action in
            areEqualAsURLs(action.actionUrl, url.absoluteString)
        })
    }

    /**
     Put URL().absoluteString here.
     WKWebView is returning a slash at the end of URL, so we need to compare it properly
     */
    func areEqualAsURLs(_ urlPath1: String, _ urlPath2: String) -> Bool {
        let url1 = URL(string: urlPath1)
        let scheme1 = url1?.scheme
        let host1 = url1?.host
        let path1 = url1?.path == "/" ? "" : url1?.path
        let query1 = url1?.query
        let url2 = URL(string: urlPath2)
        let scheme2 = url2?.scheme
        let host2 = url2?.host
        let path2 = url2?.path == "/" ? "" : url2?.path
        let query2 = url2?.query
        return (
                scheme1 == scheme2
                && host1 == host2
                && path1 == path2
                && query1 == query2
        )
    }

}

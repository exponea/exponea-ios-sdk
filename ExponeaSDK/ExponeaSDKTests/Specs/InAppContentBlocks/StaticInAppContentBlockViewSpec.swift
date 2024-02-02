//
//  StaticInAppContentBlockViewSpec.swift
//  ExponeaSDKTests
//
//  Created by Adam Mihalik on 02/02/2024.
//  Copyright © 2024 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble
import WebKit

@testable import ExponeaSDK

class StaticInAppContentBlockViewSpec: QuickSpec {
    let configuration = try! Configuration(
        projectToken: "token",
        authorization: Authorization.none,
        baseUrl: "baseUrl"
    )
    override func spec() {
        it("should NOT invoke error event for about:blank action URL") {
            let view = StaticInAppContentBlockView(placeholder: "ph_1", deferredLoad: true)
            var errorCalled = false
            view.behaviourCallback = SimpleBehaviourCallback(
                onErrorAction: { _, _, _ in
                    errorCalled = true
                }
            )
            let action = SimpleNavigationAction(url: URL(string: "about:blank")!)
            var actionHasBeenHandled: Bool?
            view.webView(WKWebView(), decidePolicyFor: action) { decision in
                // canceled action means that action has been handled internaly, WebView is not allowed to continue
                actionHasBeenHandled = decision == .cancel
            }
            expect(actionHasBeenHandled).toNot(beNil())
            guard let actionHasBeenHandled = actionHasBeenHandled else {
                return
            }
            expect(actionHasBeenHandled).to(beFalse())
            expect(errorCalled).to(beFalse())
        }
    }
}

class SimpleBehaviourCallback: InAppContentBlockCallbackType {
    private var onMessageShownAction: ((String, ExponeaSDK.InAppContentBlockResponse) -> Void)?
    private var onNoMessageFoundAction: ((String) -> Void)?
    private var onErrorAction: ((String, ExponeaSDK.InAppContentBlockResponse?, String) -> Void)?
    private var onCloseClickedAction: ((String, ExponeaSDK.InAppContentBlockResponse) -> Void)?
    private var onActionClickedAction: ((String, ExponeaSDK.InAppContentBlockResponse, ExponeaSDK.InAppContentBlockAction) -> Void)?
    init(
        onMessageShownAction: ((String, ExponeaSDK.InAppContentBlockResponse) -> Void)? = nil,
        onNoMessageFoundAction: ((String) -> Void)? = nil,
        onErrorAction: ((String, ExponeaSDK.InAppContentBlockResponse?, String) -> Void)? = nil,
        onCloseClickedAction: ((String, ExponeaSDK.InAppContentBlockResponse) -> Void)? = nil,
        onActionClickedAction: ((String, ExponeaSDK.InAppContentBlockResponse, ExponeaSDK.InAppContentBlockAction) -> Void)? = nil
    ) {
        self.onMessageShownAction = onMessageShownAction
        self.onNoMessageFoundAction = onNoMessageFoundAction
        self.onErrorAction = onErrorAction
        self.onCloseClickedAction = onCloseClickedAction
        self.onActionClickedAction = onActionClickedAction
    }
    func onMessageShown(placeholderId: String, contentBlock: ExponeaSDK.InAppContentBlockResponse) {
        onMessageShownAction?(placeholderId, contentBlock)
    }
    func onNoMessageFound(placeholderId: String) {
        onNoMessageFoundAction?(placeholderId)
    }
    func onError(placeholderId: String, contentBlock: ExponeaSDK.InAppContentBlockResponse?, errorMessage: String) {
        onErrorAction?(placeholderId, contentBlock, errorMessage)
    }
    func onCloseClicked(placeholderId: String, contentBlock: ExponeaSDK.InAppContentBlockResponse) {
        onCloseClickedAction?(placeholderId, contentBlock)
    }
    
    func onActionClicked(placeholderId: String, contentBlock: ExponeaSDK.InAppContentBlockResponse, action: ExponeaSDK.InAppContentBlockAction) {
        onActionClickedAction?(placeholderId, contentBlock, action)
    }
}

final class SimpleNavigationAction: WKNavigationAction {
    let urlRequest: URLRequest
    var receivedPolicy: WKNavigationActionPolicy?
    override var request: URLRequest { urlRequest }
    init(
        urlRequest: URLRequest
    ) {
        self.urlRequest = urlRequest
        super.init()
    }
    convenience init(url: URL) {
        self.init(urlRequest: URLRequest(url: url))
    }
    func decisionHandler(_ policy: WKNavigationActionPolicy) { self.receivedPolicy = policy }
}

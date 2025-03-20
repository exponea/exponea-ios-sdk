//
//  ContentBlockCarouselCallback.swift
//  ExponeaSDK
//
//  Created by Ankmara on 17.07.2024.
//  Copyright © 2024 Exponea. All rights reserved.
//

import Foundation
import SafariServices

public protocol DefaultContentBlockCarouselCallback {
    var overrideDefaultBehavior: Bool { get set }
    var trackActions: Bool { get set }

    func onMessageShown(placeholderId: String, contentBlock: InAppContentBlockResponse, index: Int, count: Int)
    func onMessagesChanged(count: Int, messages: [InAppContentBlockResponse])
    func onNoMessageFound(placeholderId: String)
    func onError(placeholderId: String, contentBlock: InAppContentBlockResponse?, errorMessage: String)
    func onCloseClicked(placeholderId: String, contentBlock: InAppContentBlockResponse)
    func onActionClickedSafari(placeholderId: String, contentBlock: InAppContentBlockResponse, action: InAppContentBlockAction)
    func onHeightUpdate(placeholderId: String, height: CGFloat)
}

internal struct ContentBlockCarouselCallback: DefaultContentBlockCarouselCallback {

    var trackActions: Bool = true
    var overrideDefaultBehavior: Bool = false
    private var behaviourCallback: DefaultContentBlockCarouselCallback?

    init(behaviourCallback: DefaultContentBlockCarouselCallback?) {
        self.trackActions = behaviourCallback?.trackActions ?? true
        self.overrideDefaultBehavior = behaviourCallback?.overrideDefaultBehavior ?? false
        self.behaviourCallback = behaviourCallback
    }

    func onMessageShown(placeholderId: String, contentBlock: InAppContentBlockResponse, index: Int, count: Int) {
        Exponea.logger.log(
            .verbose,
            message: "Tracking of Carousel Content Block \(contentBlock) show"
        )
        Exponea.shared.trackInAppContentBlockShown(placeholderId: placeholderId, message: contentBlock)
        behaviourCallback?.onMessageShown(placeholderId: placeholderId, contentBlock: contentBlock, index: index, count: count)
    }

    func onMessagesChanged(count: Int, messages: [InAppContentBlockResponse]) {
        behaviourCallback?.onMessagesChanged(count: count, messages: messages)
    }

    func onNoMessageFound(placeholderId: String) {
        Exponea.logger.log(.verbose, message: "Carousel Content Block has no content for \(placeholderId)")
        behaviourCallback?.onNoMessageFound(placeholderId: placeholderId)
    }

    func onError(placeholderId: String, contentBlock: InAppContentBlockResponse?, errorMessage: String) {
        guard let contentBlock else {
            Exponea.logger.log(.error, message: "Carousel Content Block is empty!!! Nothing to track")
            return
        }
        Exponea.logger.log(.verbose, message: "Tracking of Carousel Content Block \(contentBlock.id) error")
        Exponea.shared.trackInAppContentBlockError(
            placeholderId: placeholderId,
            message: contentBlock,
            errorMessage: errorMessage
        )
        behaviourCallback?.onError(placeholderId: placeholderId, contentBlock: contentBlock, errorMessage: errorMessage)
    }

    func onCloseClicked(placeholderId: String, contentBlock: InAppContentBlockResponse) {
        Exponea.logger.log(.verbose, message: "Tracking of Carousel Content Block \(contentBlock.id) close")
        if trackActions {
            Exponea.shared.trackInAppContentBlockClose(
                placeholderId: placeholderId,
                message: contentBlock
            )
        }
        behaviourCallback?.onCloseClicked(placeholderId: placeholderId, contentBlock: contentBlock)
    }

    func onActionClickedSafari(
        placeholderId: String,
        contentBlock: InAppContentBlockResponse,
        action: InAppContentBlockAction
    ) {
        Exponea.logger.log(.verbose, message: "Tracking of Carousel Content Block \(contentBlock.id) action \(action.name ?? "")")
        if action.type == .close {
            return
        }
        if trackActions {
            Exponea.shared.trackInAppContentBlockClick(
                placeholderId: placeholderId,
                action: action,
                message: contentBlock
            )
        }
        if !overrideDefaultBehavior {
            if action.type == .browser {
                guard let stringUrl = action.url, let url = URL(safeString: stringUrl) else { return }
                let safari = SFSafariViewController(url: url)
                if let presented = UIApplication.shared.windows.first?.rootViewController?.presentedViewController {
                    presented.present(safari, animated: true)
                } else {
                    UIApplication.shared.windows.first?.rootViewController?.present(safari, animated: true)
                }
            } else {
                invokeAction(action, contentBlock)
            }
        }
        behaviourCallback?.onActionClickedSafari(placeholderId: placeholderId, contentBlock: contentBlock, action: action)
    }

    func onHeightUpdate(placeholderId: String, height: CGFloat) {
        Exponea.logger.log(.verbose, message: "Carousel Content Block \(placeholderId) height update: \(height)")
        behaviourCallback?.onHeightUpdate(placeholderId: placeholderId, height: height)
    }

    private func invokeAction(_ action: InAppContentBlockAction, _ contentBlock: InAppContentBlockResponse) {
        Exponea.logger.log(.verbose, message: "Invoking Carousel Content Block \(contentBlock.id) action '\(action.name ?? "")'")
        guard let actionUrl = action.url,
              action.type != .close else {
            return
        }
        let urlOpener = UrlOpener()
        switch action.type {
        case .deeplink:
            urlOpener.openDeeplink(actionUrl)
        case .browser:
            urlOpener.openBrowserLink(actionUrl)
        case .close:
            break
        }
    }
}

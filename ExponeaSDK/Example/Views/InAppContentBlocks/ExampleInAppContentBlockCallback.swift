//
//  ExampleInAppContentBlockCallback.swift
//  Example
//
//  Created by Adam Mihalik on 14/12/2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation
import ExponeaSDK

class ExampleInAppContentBlockCallback: InAppContentBlockCallbackType {

    private let originalBehaviour: InAppContentBlockCallbackType
    private let ownerView: StaticInAppContentBlockView

    init(
        originalBehaviour: InAppContentBlockCallbackType,
        ownerView: StaticInAppContentBlockView
    ) {
        self.originalBehaviour = originalBehaviour
        self.ownerView = ownerView
    }

    func onMessageShown(placeholderId: String, contentBlock: ExponeaSDK.InAppContentBlockResponse) {
        originalBehaviour.onMessageShown(placeholderId: placeholderId, contentBlock: contentBlock)
        let htmlContent = contentBlock.content?.html ?? contentBlock.personalizedMessage?.content?.html
        Exponea.logger.log(.verbose, message: "Content block with HTML: \(htmlContent ?? "empty")")
        let normalizerConf = HtmlNormalizerConfig(makeResourcesOffline: true, ensureCloseButton: false)
        if let htmlContent,
           let normalizedHtml = HtmlNormalizer(htmlContent).normalize(normalizerConf).html {
            Exponea.logger.log(.verbose, message: "Normalized HTML: \(normalizedHtml)")
        }
    }

    func onNoMessageFound(placeholderId: String) {
        originalBehaviour.onNoMessageFound(placeholderId: placeholderId)
    }

    func onError(placeholderId: String, contentBlock: ExponeaSDK.InAppContentBlockResponse?, errorMessage: String) {
        guard let contentBlock else {
            return
        }
        Exponea.shared.trackInAppContentBlockErrorWithoutTrackingConsent(
            placeholderId: placeholderId,
            message: contentBlock,
            errorMessage: errorMessage
        )
    }

    func onCloseClicked(placeholderId: String, contentBlock: ExponeaSDK.InAppContentBlockResponse) {
        Exponea.shared.trackInAppContentBlockCloseWithoutTrackingConsent(
            placeholderId: placeholderId,
            message: contentBlock
        )
    }

    private var actionClickBounce = false

    func onActionClicked(placeholderId: String, contentBlock: ExponeaSDK.InAppContentBlockResponse, action: ExponeaSDK.InAppContentBlockAction) {
        Exponea.logger.log(.verbose, message: "Handling In-app content block action \(action.url ?? "none")")
        guard let actionUrl = action.url,
              let url = actionUrl.cleanedURL() else {
            return
        }
        if actionClickBounce {
            actionClickBounce = false
            Exponea.shared.trackInAppContentBlockClickWithoutTrackingConsent(
                placeholderId: placeholderId,
                action: action,
                message: contentBlock
            )
            switch action.type {
            case .browser:
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            case .deeplink:
                if !openUniversalLink(url, application: UIApplication.shared) {
                    openURLSchemeDeeplink(url, application: UIApplication.shared)
                }
            case .close:
                Exponea.logger.log(.error, message: "In-app content block close has to be handled elsewhere")
            }
        } else {
            actionClickBounce = true
            ownerView.invokeActionClick(actionUrl: actionUrl)
        }
    }

    private func openUniversalLink(_ url: URL, application: UIApplication) -> Bool {
        guard url.scheme == "http" || url.scheme == "https" else {
            return false
        }
        // Simulate universal link user activity
        let userActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        userActivity.webpageURL = url

        // Try and open the link as universal link
        return application.delegate?.application?(
            application,
            continue: userActivity,
            restorationHandler: { _ in }
        ) ?? false
    }

    private func openURLSchemeDeeplink(_ url: URL, application: UIApplication) {
        // Open the deeplink, iOS will handle if deeplink to safari/other apps
        application.open(url, options: [:], completionHandler: { success in
            if !success { // If opening url using shared app failed, try opening using current app
                _ = application.delegate?.application?(UIApplication.shared, open: url, options: [:])
            }
        })
    }
}

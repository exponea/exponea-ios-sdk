//
//  Deeplinker.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 10/01/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation
import UIKit

/// Abstraction over a connected `UIWindowScene`'s ability to forward a universal-link
/// `NSUserActivity` to its scene delegate. Exists so `UrlOpener` can be unit-tested without
/// needing a real, UIKit-created `UIWindowScene` instance (which has no public initializer).
protocol SceneUniversalLinkForwarding {
    /// Whether this scene is the current foreground-active one.
    var isForegroundActive: Bool { get }
    /// Whether this scene's delegate actually implements `scene(_:continue:)`.
    /// `UIWindowSceneDelegate.scene(_:continue:)` is an `@objc optional` protocol requirement,
    /// so simply having a non-nil `delegate` is not sufficient evidence that anything will happen.
    var canForwardUniversalLink: Bool { get }
    /// Forwards the activity to the scene's delegate.
    func forwardUniversalLink(_ userActivity: NSUserActivity)
}

extension UIWindowScene: SceneUniversalLinkForwarding {
    var isForegroundActive: Bool {
        activationState == .foregroundActive
    }

    var canForwardUniversalLink: Bool {
        delegate?.responds(to: #selector(UIWindowSceneDelegate.scene(_:continue:))) ?? false
    }

    func forwardUniversalLink(_ userActivity: NSUserActivity) {
        delegate?.scene?(self, continue: userActivity)
    }
}

final class UrlOpener: UrlOpenerType {
    private let connectedWindowScenesProvider: () -> [SceneUniversalLinkForwarding]
    private let openURLHandler: (URL, UIApplication) -> Void

    init(
        connectedWindowScenesProvider: @escaping () -> [SceneUniversalLinkForwarding] = {
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene } as [SceneUniversalLinkForwarding]
        },
        openURLHandler: @escaping (URL, UIApplication) -> Void = UrlOpener.defaultOpenURLHandler
    ) {
        self.connectedWindowScenesProvider = connectedWindowScenesProvider
        self.openURLHandler = openURLHandler
    }

    /// Opens the URL via `UIApplication.open`, which iOS correctly routes to
    /// `SceneDelegate.scene(_:openURLContexts:)` under the UIScene lifecycle or to
    /// `AppDelegate.application(_:open:options:)` on the legacy lifecycle — no manual
    /// lifecycle detection needed. Falls back to a direct `AppDelegate` call only if the
    /// system reports the open as unsuccessful (single, well-defined fallback path).
    private static func defaultOpenURLHandler(_ url: URL, application: UIApplication) {
        application.open(url, options: [:], completionHandler: { success in
            if !success {
                _ = application.delegate?.application?(UIApplication.shared, open: url, options: [:])
            }
        })
    }

    func openBrowserLink(_ urlString: String) {
        guard let url = urlString.cleanedURL() else {
            Exponea.logger.log(.warning, message: "Provided url \"\(urlString)\" is invalid")
            return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    func openDeeplink(_ urlString: String) {
        guard let url = urlString.cleanedURL() else {
            Exponea.logger.log(.warning, message: "Provided url \"\(urlString)\" is invalid")
            return
        }
        self.openUniversalLink(url, application: UIApplication.shared) { result in
            if !result {
                self.openURLSchemeDeeplink(url, application: UIApplication.shared)
            }
        }
    }

    private func openUniversalLink(_ url: URL, application: UIApplication, callBackHandler: @escaping (Bool) -> Void) {
        // Validate this is a valid URL, prevents NSUserActivity crash with invalid URL
        // only http/https is allowed
        // https://developer.apple.com/documentation/foundation/nsuseractivity/1418086-webpageurl
        // eg. MYDEEPLINK::HOME:SCREEN:1, exponea://deeplink
        guard url.absoluteString.isValidURL, url.scheme == "http" || url.scheme == "https" else {
            callBackHandler(false)
            return
        }
        // Simulate universal link user activity
        let userActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        userActivity.webpageURL = url

        // Legacy AppDelegate path
        if application.delegate?.application?(application, continue: userActivity, restorationHandler: { _ in }) ?? false {
            callBackHandler(true)
            return
        }

        // UIScene path — AppDelegate continue is not called when a scene manifest is active
        if deliverUserActivityToSceneDelegates(userActivity) {
            callBackHandler(true)
            return
        }

        callBackHandler(false)
    }

    private func deliverUserActivityToSceneDelegates(_ userActivity: NSUserActivity) -> Bool {
        let forwardingScenes = connectedWindowScenesProvider().filter { $0.canForwardUniversalLink }
        guard let scene = forwardingScenes.first(where: { $0.isForegroundActive }) ?? forwardingScenes.first else {
            // No connected scene's delegate implements `scene(_:continue:)`. Track for telemetry so the
            // campaign click isn't silently lost, but return false so the caller still falls back to
            // `openURLSchemeDeeplink` for actual navigation — tracking must not suppress opening.
            Exponea.shared.handleUniversalLink(userActivity)
            return false
        }
        scene.forwardUniversalLink(userActivity)
        return true
    }

    private func openURLSchemeDeeplink(_ url: URL, application: UIApplication) {
        // Open the deeplink; iOS routes it to SceneDelegate.scene(_:openURLContexts:) under
        // UIScene or AppDelegate.application(_:open:options:) on the legacy lifecycle.
        openURLHandler(url, application)
    }
}

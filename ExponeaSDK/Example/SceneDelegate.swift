//
//  SceneDelegate.swift
//  Example
//
//  Copyright © 2026 Exponea. All rights reserved.
//

import UIKit
import ExponeaSDK

class SceneDelegate: ExponeaSceneDelegate {
    var window: UIWindow?

    override func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        super.scene(scene, willConnectTo: session, options: connectionOptions)
        handleDeeplinkRouting(from: connectionOptions.userActivities)
        handleURLSchemeDeeplinks(from: connectionOptions.urlContexts)
    }

    override func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        super.scene(scene, continue: userActivity)
        handleDeeplinkRouting(from: [userActivity])
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        handleURLSchemeDeeplinks(from: URLContexts)
    }

    private func handleDeeplinkRouting(from userActivities: Set<NSUserActivity>) {
        guard let activity = userActivities.first(where: { $0.activityType == NSUserActivityTypeBrowsingWeb }),
              let incomingURL = activity.webpageURL,
              let type = DeeplinkType(input: incomingURL.absoluteString) else {
            return
        }
        DeeplinkManager.manager.setDeeplinkType(type: type)
    }

    private func handleURLSchemeDeeplinks(from urlContexts: Set<UIOpenURLContext>) {
        for context in urlContexts {
            handleURLSchemeDeeplink(context.url)
        }
    }

    private func handleURLSchemeDeeplink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == "exponea" else {
            return
        }
        if let type = DeeplinkType(input: url.absoluteString) {
            DeeplinkManager.manager.setDeeplinkType(type: type)
        }
    }
}


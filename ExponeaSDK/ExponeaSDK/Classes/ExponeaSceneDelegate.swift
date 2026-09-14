//
//  ExponeaSceneDelegate.swift
//  ExponeaSDK
//
//  Copyright © 2026 Exponea. All rights reserved.
//

import UIKit

enum ExponeaUniversalLinkForwarding {
    static func forwardFromUserActivities(_ userActivities: Set<NSUserActivity>) {
        if let activity = userActivities.first(where: { $0.activityType == NSUserActivityTypeBrowsingWeb }) {
            Exponea.shared.handleUniversalLink(activity)
        }
    }

    static func forwardFromUserActivity(_ userActivity: NSUserActivity) {
        Exponea.shared.handleUniversalLink(userActivity)
    }
}

/// Base `UISceneDelegate` that forwards universal links to the SDK for campaign-click tracking.
///
/// Subclass this in your `SceneDelegate` and call `super` from scene lifecycle methods.
/// For fully custom scene delegates, call `Exponea.shared.handleUniversalLink(_:)` manually.
open class ExponeaSceneDelegate: UIResponder, UIWindowSceneDelegate {
    open func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        ExponeaUniversalLinkForwarding.forwardFromUserActivities(connectionOptions.userActivities)
    }

    open func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        ExponeaUniversalLinkForwarding.forwardFromUserActivity(userActivity)
    }
}

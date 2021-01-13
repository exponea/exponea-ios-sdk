//
//  Deeplinker.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 10/01/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation
import UIKit

final class UrlOpener: UrlOpenerType {
    func openBrowserLink(_ urlString: String) {
        guard let url = parseUrlString(urlString) else {
            return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    func openDeeplink(_ urlString: String) {
        guard let url = parseUrlString(urlString) else {
            return
        }
        if !openUniversalLink(url, application: UIApplication.shared) {
            openURLSchemeDeeplink(url, application: UIApplication.shared)
        }
    }

    private func parseUrlString(_ urlString: String) -> URL? {
        let sanitizedUrlString = urlString.replacingOccurrences(of: " ", with: "%20")
        guard let url = URL(string: sanitizedUrlString) else {
            Exponea.logger.log(.verbose, message: "Unable to parse url \(urlString).")
            return nil
        }
        return url
    }

    private func openUniversalLink(_ url: URL, application: UIApplication) -> Bool {
        // Validate this is a valid URL, prevents NSUserActivity crash with invalid URL
        // only http/https is allowed
        // https://developer.apple.com/documentation/foundation/nsuseractivity/1418086-webpageurl
        // eg. MYDEEPLINK::HOME:SCREEN:1, exponea://deeplink
        guard url.absoluteString.isValidURL, url.scheme == "http" || url.scheme == "https" else {
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

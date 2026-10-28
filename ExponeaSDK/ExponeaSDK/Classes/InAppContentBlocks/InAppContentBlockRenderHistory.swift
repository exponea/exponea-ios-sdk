//
//  InAppContentBlockRenderHistory.swift
//  ExponeaSDK
//
//  Copyright © 2026 Exponea. All rights reserved.
//

import Foundation
#if canImport(ExponeaSDKShared)
import ExponeaSDKShared
#endif

/// Remembers when in-app content blocks last rendered HTML in a `WKWebView` on this device.
///
/// The SDK reads it at startup to decide whether preparing WebKit in advance is worth it: apps
/// whose placeholders stay empty, or that render content natively, never record a render.
/// It also remembers whether the first startup with render tracking has been handled, so that
/// startup prewarms fully until there is history to decide from.
final class InAppContentBlockRenderHistory {
    static let shared = InAppContentBlockRenderHistory(
        userDefaults: UserDefaults(suiteName: Constants.General.userDefaultsSuite) ?? .standard
    )

    private static let lastRenderKey = "EXPONEA_IN_APP_CONTENT_BLOCK_LAST_WEB_RENDER"
    private static let lastSpareWebViewRenderKey = "EXPONEA_IN_APP_CONTENT_BLOCK_LAST_SPARE_WEB_RENDER"
    private static let firstStartupKey = "EXPONEA_IN_APP_CONTENT_BLOCK_FIRST_STARTUP_RECORDED"
    /// Renders within this interval after the stored one keep it, so rendering does not write to
    /// `UserDefaults` every time. The stored timestamp never moves backwards.
    private static let recordGranularity: TimeInterval = 60 * 60

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    /// - Parameter usedSpareWebView: `true` when the render took a spare display web view, which only
    ///   the table and collection API does. Startup then prepares spare web views as well.
    func recordRender(at date: Date = Date(), usedSpareWebView: Bool = false) {
        // Stopping the integration clears the history; a render still in flight must not refill it.
        guard !IntegrationManager.shared.isStopped else { return }
        record(date, forKey: Self.lastRenderKey)
        if usedSpareWebView {
            record(date, forKey: Self.lastSpareWebViewRenderKey)
        }
    }

    func hasRendered(since date: Date) -> Bool {
        guard let lastRender = storedDate(forKey: Self.lastRenderKey) else { return false }
        return lastRender >= date
    }

    func hasRenderedWithSpareWebView(since date: Date) -> Bool {
        guard let lastRender = storedDate(forKey: Self.lastSpareWebViewRenderKey) else { return false }
        return lastRender >= date
    }

    var hasRecordedFirstStartup: Bool {
        userDefaults.bool(forKey: Self.firstStartupKey)
    }

    func recordFirstStartup() {
        userDefaults.set(true, forKey: Self.firstStartupKey)
    }

    /// Removes the render timestamps and the first-startup marker, so the next `configure` after a
    /// stopped integration or cleared data prewarms fully, like a fresh install.
    func clear() {
        userDefaults.removeObject(forKey: Self.lastRenderKey)
        userDefaults.removeObject(forKey: Self.lastSpareWebViewRenderKey)
        userDefaults.removeObject(forKey: Self.firstStartupKey)
    }

    private func record(_ date: Date, forKey key: String) {
        if let stored = storedDate(forKey: key), date.timeIntervalSince(stored) < Self.recordGranularity {
            return
        }
        userDefaults.set(date.timeIntervalSince1970, forKey: key)
    }

    private func storedDate(forKey key: String) -> Date? {
        guard userDefaults.object(forKey: key) != nil else { return nil }
        return Date(timeIntervalSince1970: userDefaults.double(forKey: key))
    }
}

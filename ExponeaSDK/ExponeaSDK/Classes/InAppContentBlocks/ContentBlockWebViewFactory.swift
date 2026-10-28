//
//  ContentBlockWebViewFactory.swift
//  ExponeaSDK
//
//  Copyright © 2026 Exponea. All rights reserved.
//

import WebKit

/// Single creation point for every `WKWebView` used by in-app content blocks.
///
/// The first `WKWebView` in a process initializes WebKit on the main thread, which can block it
/// for hundreds of milliseconds on older devices. The counters make web view creation observable.
enum ContentBlockWebViewFactory {
    private static let lock = NSLock()
    private static var _createdCount = 0
    private static var _createdOffMainThreadCount = 0

    /// Number of web views created through this factory since process start.
    static var createdCount: Int {
        lock.withLock { _createdCount }
    }

    /// Number of web views created off the main thread since process start. Expected to be zero.
    static var createdOffMainThreadCount: Int {
        lock.withLock { _createdOffMainThreadCount }
    }

    static func makeWebView(frame: CGRect, configuration: WKWebViewConfiguration) -> WKWebView {
        recordCreation()
        return WKWebView(frame: frame, configuration: configuration)
    }

    static func makeHeightCalculator() -> WKWebViewHeightCalculator {
        recordCreation()
        return WKWebViewHeightCalculator()
    }

    private static func recordCreation() {
        let isMainThread = Thread.isMainThread
        lock.withLock {
            _createdCount += 1
            if !isMainThread {
                _createdOffMainThreadCount += 1
            }
        }
    }
}

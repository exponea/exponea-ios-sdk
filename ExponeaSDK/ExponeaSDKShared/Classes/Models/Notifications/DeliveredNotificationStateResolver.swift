//
//  DeliveredNotificationStateResolver.swift
//  ExponeaSDKShared
//
//  Created on 23/04/2026.
//  Copyright © 2026 Exponea. All rights reserved.
//
//  The `state` property on delivered-push events previously hardcoded
//  `"shown"` in three sites (DeliveredNotificationTracker,
//  TrackingConsentManager.trackDeliveredPush, PushNotificationParser).
//  This file owns the pure, side-effect-free rule for deriving the state
//  value from a silent flag + an optional authorization snapshot, plus a
//  thin provider abstraction over UNUserNotificationCenter so call sites
//  can resolve state without depending directly on UserNotifications APIs.
//
//  The resolver returns legacy `"shown"` when the caller cannot supply an
//  authorization snapshot. This is intentional: it preserves historical
//  behaviour for call paths that do not yet refresh the snapshot, so the
//  change is additive rather than a mass-relabel of in-flight events.
//

import Foundation
import UserNotifications

/// Minimal subset of `UNNotificationSettings` needed by the delivered-state
/// resolver. We intentionally avoid passing the whole `UNNotificationSettings`
/// around because it is not directly constructible in unit tests; this struct
/// is.
public struct DeliveryAuthorizationSnapshot {
    public let authorizationStatus: UNAuthorizationStatus
    public let alertSetting: UNNotificationSetting

    public init(authorizationStatus: UNAuthorizationStatus, alertSetting: UNNotificationSetting) {
        self.authorizationStatus = authorizationStatus
        self.alertSetting = alertSetting
    }
}

/// Asynchronous abstraction over the source of the current delivery
/// authorization. `UNUserNotificationCenter` is the production implementation;
/// unit tests substitute a synchronous mock through
/// `DeliveryAuthorizationProvider.current`.
public protocol DeliveryAuthorizationProviding {
    func currentDeliveryAuthorization(completion: @escaping (DeliveryAuthorizationSnapshot?) -> Void)
}

extension UNUserNotificationCenter: DeliveryAuthorizationProviding {
    public func currentDeliveryAuthorization(completion: @escaping (DeliveryAuthorizationSnapshot?) -> Void) {
        getNotificationSettings { settings in
            completion(
                DeliveryAuthorizationSnapshot(
                    authorizationStatus: settings.authorizationStatus,
                    alertSetting: settings.alertSetting
                )
            )
        }
    }
}

/// Shared access point for the current delivery authorization.
///
/// Mirrors the pattern established by `UNAuthorizationStatusProvider` in the
/// main SDK, with one deliberate twist: the default backing is a no-op that
/// always returns a `nil` snapshot. Production code promotes the backend to
/// `UNUserNotificationCenter.current()` via `installProductionBackend()` from
/// two independent call sites:
///
/// 1. The host application's first `Exponea.configure` (so the main-app
///    delivered-push path through `TrackingConsentManager.trackDeliveredPush`
///    can read a fresh snapshot synchronously).
/// 2. `ExponeaNotificationService.init` in the notification-service
///    extension (so the NSE-side delivered-event path resolves real
///    authorization rather than the no-op `nil`). The NSE runs in a
///    different process and therefore needs its own promotion — it cannot
///    inherit the one performed by the host application.
///
/// Rationale for the no-op default: `UNUserNotificationCenter.current()` is
/// not safe to eagerly instantiate inside the test bundle (no app container /
/// entitlements), and multiple existing test specs construct
/// `PushNotificationManager` / `ExponeaNotificationService` without stubbing
/// the provider. Both production install sites are guarded against the
/// XCTest environment via the same `XCTestConfigurationFilePath` check, so
/// the no-op default sticks in tests; specs that need a specific
/// authorization substitute their own `DeliveryAuthorizationProviding`
/// implementation into `current` directly.
///
/// `lastSnapshot` is a fire-and-forget cache populated by
/// `refresh(completion:)` and read synchronously by call sites that cannot
/// afford an async hop (e.g. `TrackingConsentManager.trackDeliveredPush`).
/// Call sites that can afford an async hop — notably the NSE — go direct to
/// `current`, because the NSE runs in a separate process and does not share
/// the main app's in-memory cache.
public enum DeliveryAuthorizationProvider {
    private struct NoopProvider: DeliveryAuthorizationProviding {
        func currentDeliveryAuthorization(completion: @escaping (DeliveryAuthorizationSnapshot?) -> Void) {
            completion(nil)
        }
    }

    private static let snapshotLock = NSLock()

    /// Reads are `public` because consumers in `ExponeaSDK` (e.g.
    /// `TrackingConsentManager.trackDeliveredPush`) and `ExponeaSDK-Notifications`
    /// (NSE) live in separate modules and must observe the current provider /
    /// last snapshot. Writes are restricted to `internal` so SDK integrators
    /// cannot stomp this global state at runtime; only the module-internal
    /// production-install path (`installProductionBackend()`) and the
    /// refresh pump (`refresh(completion:)`) — both `public` entry points
    /// defined below — may mutate them. Test bundles get full write access
    /// via `@testable import ExponeaSDKShared`.
    public internal(set) static var current: DeliveryAuthorizationProviding = NoopProvider()

    private static var _lastSnapshot: DeliveryAuthorizationSnapshot?
    public internal(set) static var lastSnapshot: DeliveryAuthorizationSnapshot? {
        get {
            snapshotLock.lock()
            defer { snapshotLock.unlock() }
            return _lastSnapshot
        }
        set {
            snapshotLock.lock()
            defer { snapshotLock.unlock() }
            _lastSnapshot = newValue
        }
    }

    public static func installProductionBackend() {
        current = UNUserNotificationCenter.current()
    }

    public static func refresh(completion: (() -> Void)? = nil) {
        current.currentDeliveryAuthorization { snapshot in
            lastSnapshot = snapshot
            completion?()
        }
    }
}

/// Pure resolver for the `state` property on delivered-push events.
///
/// - `silent == true`: the push never surfaced UI; always `"not_shown"`.
/// - `silent == false, authorization == nil`: we could not determine the
///   user's current permission state. Fall back to `"shown"` to preserve the
///   event shape clients already consume; this matches the legacy
///   behaviour for callers that have not yet opted into snapshot refresh.
/// - `silent == false, authorization != nil`: `"shown"` iff both the
///   authorization status allows user-visible notifications AND the alert
///   setting is enabled; otherwise `"not_shown"`.
public enum DeliveredNotificationStateResolver {

    /// Use these exact string values to write the `state` property onto
    /// delivered-push event payloads. Kept as static lets rather than a
    /// `String` enum so they can be embedded directly into JSON properties
    /// without extra mapping.
    public static let shownValue: String = "shown"
    public static let notShownValue: String = "not_shown"

    public static func resolve(
        authorization: DeliveryAuthorizationSnapshot?,
        silent: Bool
    ) -> String {
        if silent {
            return notShownValue
        }
        guard let authorization else {
            return shownValue
        }
        let authorized: Bool = Self.isUserVisible(authorization.authorizationStatus)
        let alertsEnabled = authorization.alertSetting == .enabled
        return (authorized && alertsEnabled) ? shownValue : notShownValue
    }

    private static func isUserVisible(_ status: UNAuthorizationStatus) -> Bool {
        switch status {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined, .denied:
            return false
        @unknown default:
            return false
        }
    }
}

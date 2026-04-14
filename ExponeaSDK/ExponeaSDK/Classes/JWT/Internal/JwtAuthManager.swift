//
//  JwtAuthManager.swift
//  ExponeaSDKShared
//
//  Created by Bloomreach on 29/01/2026.
//  Copyright © 2026 Exponea. All rights reserved.
//

import Foundation
#if canImport(ExponeaSDKObjC)
import ExponeaSDKObjC
#endif

/// Manager responsible for Stream JWT lifecycle: storage, validation, refresh scheduling, and error handling.
final class JwtAuthManager {
    
    /// Notification posted when the JWT token is refreshed.
    static let tokenRefreshedNotification = Notification.Name("brx.jwtTokenRefreshed")
    
    private let store: JwtTokenStore
    private let queue = DispatchQueue(label: "brx.jwt.manager", qos: .userInitiated)
    
    private var currentToken: String?
    private var expirationDate: Date?
    private var errorHandler: ((JwtErrorContext) -> Void)?
    private var customerIdsProvider: (() -> [String: String]?)?
    /// Whether SDK is in Stream integration mode (matches Configuration.usesStreamIntegration / IntegrationSourceType.isStream).
    private var isStreamIntegration: Bool

    private let timerLock = NSLock()
    private weak var _refreshTimer: Timer?

    /// Time buffer (in seconds) before expiration to trigger proactive refresh.
    private let expirationBuffer: TimeInterval = 60
    
    /// Returns a snapshot of the current JWT token (thread-safe).
    var currentTokenSnapshot: String? {
        queue.sync { currentToken }
    }
    
    /// Whether a JWT error handler has been registered (thread-safe).
    var hasErrorHandler: Bool {
        queue.sync { errorHandler != nil }
    }
    
    /// Creates a new JWT auth manager.
    /// - Parameters:
    ///   - store: The token store for persistence.
    ///   - isStreamIntegration: Whether SDK is configured for Stream integration (matches Configuration.usesStreamIntegration).
    init(
        store: JwtTokenStore,
        isStreamIntegration: Bool
    ) {
        self.store = store
        self.isStreamIntegration = isStreamIntegration
        loadPersisted()
    }
    
    deinit {
        timerLock.lock()
        let timer = _refreshTimer
        timerLock.unlock()
        DispatchQueue.main.async {
            timer?.invalidate()
        }
    }
    
    /// Loads persisted token from store on initialization.
    private func loadPersisted() {
        queue.async { [weak self] in
            guard let self = self else { return }
            guard let token = self.store.loadToken() else {
                Exponea.logger.log(.verbose, message: "JWT: No persisted token found.")
                return
            }
            
            self.currentToken = token
            self.expirationDate = self.parseExpiration(from: token)
            
            // Check if loaded token is already expired
            if let exp = self.expirationDate, exp <= Date() {
                Exponea.logger.log(.warning, message: "JWT: Persisted token is already expired")
                // Clear the expired token but keep it until new one is provided
                // Trigger error handler so app can refresh the token
                self.triggerRefreshOnQueue(reason: .expired, endpoint: "init", status: 0, error: nil)
            } else {
                self.scheduleRefreshIfNeeded()
                Exponea.logger.log(.verbose, message: "JWT: Loaded persisted token, expires at \(self.expirationDate?.description ?? "unknown")")
            }
        }
    }
    
    /// Updates integration mode (e.g., after configuration change).
    /// - Parameter isStreamIntegration: Whether SDK uses Stream integration (matches Configuration.usesStreamIntegration).
    func updateIntegrationMode(isStreamIntegration: Bool) {
        queue.async { [weak self] in
            self?.isStreamIntegration = isStreamIntegration
        }
    }
    
    /// Sets the error handler for JWT-related errors.
    /// - Parameter handler: Closure called when JWT errors occur.
    func setErrorHandler(_ handler: @escaping (JwtErrorContext) -> Void) {
        queue.async { [weak self] in
            self?.errorHandler = handler
        }
    }

    /// Sets a provider for current customer IDs, so the error context can include them when the handler is invoked.
    /// - Parameter provider: Closure that returns current customer IDs, or nil.
    func setCustomerIdsProvider(_ provider: (() -> [String: String]?)?) {
        queue.async { [weak self] in
            self?.customerIdsProvider = provider
        }
    }
    
    /// Updates the JWT token asynchronously.
    /// - Parameter token: New JWT token, or nil to clear.
    func setToken(_ token: String?) {
        queue.async { [weak self] in
            self?.performSetToken(token)
        }
    }

    /// Updates the JWT token synchronously.
    /// Use when the caller must guarantee the token is set before proceeding (e.g. `identifyCustomer`).
    /// - Parameter token: New JWT token, or nil to clear.
    func setTokenSync(_ token: String?) {
        queue.sync {
            performSetToken(token)
        }
    }

    private func performSetToken(_ token: String?) {
        guard isStreamIntegration else {
            if token != nil {
                Exponea.logger.log(.warning, message: "JWT: Ignoring token - SDK not configured with Stream integration")
            }
            return
        }

        currentToken = token
        store.saveToken(token)
        invalidateTimerOnMain()

        guard let token = token else {
            expirationDate = nil
            Exponea.logger.log(.verbose, message: "JWT: Token cleared")
            return
        }

        expirationDate = parseExpiration(from: token)

        if let exp = expirationDate, exp <= Date() {
            Exponea.logger.log(.warning, message: "JWT: Provided token is already expired")
            triggerRefreshOnQueue(reason: .expired, endpoint: "setToken", status: 0, error: nil)
        } else {
            scheduleRefreshIfNeeded()
            Exponea.logger.log(.verbose, message: "JWT: Token updated, expires at \(expirationDate?.description ?? "unknown")")
        }

        notifyTokenRefreshed()
    }
    
    /// Returns the Authorization header value for Stream requests.
    /// Returns nil when not in Stream mode or no token; never used in Engagement-only flows.
    /// Triggers .expiredSoon callback if token is about to expire.
    /// - Returns: "Bearer <token>" or nil.
    func getAuthorizationHeader() -> String? {
        return queue.sync { [weak self] () -> String? in
            guard let self = self else { return nil }
            guard self.isStreamIntegration else { return nil }
            
            guard let token = self.currentToken else {
                // Token not provided in Stream mode - trigger error
                self.triggerRefreshOnQueue(reason: .notProvided, endpoint: "tracking", status: 0, error: nil)
                return nil
            }
            
            // Check if token is about to expire
            if let exp = self.expirationDate {
                if exp <= Date() {
                    // Token is expired
                    self.triggerRefreshOnQueue(reason: .expired, endpoint: "tracking", status: 0, error: nil)
                } else if exp <= Date().addingTimeInterval(self.expirationBuffer) {
                    // Token expires soon
                    self.triggerRefreshOnQueue(reason: .expiredSoon, endpoint: "tracking", status: 0, error: nil)
                }
            }
            
            return "Bearer \(token)"
        }
    }
    
    /// Handles JWT errors from HTTP responses.
    /// - Parameters:
    ///   - reason: The error reason.
    ///   - endpoint: The endpoint that failed.
    ///   - status: HTTP status code.
    ///   - underlying: The underlying error, if any.
    func handleTokenError(
        reason: JwtErrorContext.Reason,
        endpoint: String,
        status: Int,
        underlying: Error?
    ) {
        queue.async { [weak self] in
            guard let self = self else { return }
            guard self.isStreamIntegration else { return }
            
            // Try to determine more specific reason for 401 errors
            var actualReason = reason
            if status == 401, let token = self.currentToken {
                if let exp = self.parseExpiration(from: token), exp <= Date() {
                    actualReason = .expired
                }
            }
            
            self.triggerRefreshOnQueue(reason: actualReason, endpoint: endpoint, status: status, error: underlying)
        }
    }
    
    /// Clears the stored JWT token and state asynchronously.
    func clear() {
        queue.async { [weak self] in
            self?.performClear()
        }
    }

    /// Clears the stored JWT token and state synchronously.
    /// Use when the caller must guarantee the token is cleared before proceeding (e.g. `identifyCustomer`).
    func clearSync() {
        queue.sync {
            performClear()
        }
    }

    private func performClear() {
        currentToken = nil
        expirationDate = nil
        invalidateTimerOnMain()
        store.clearToken()
        Exponea.logger.log(.verbose, message: "JWT: Token and state cleared")
    }
    
    // MARK: - Helpers
    
    /// Parses the expiration date from a JWT token.
    /// - Parameter token: The JWT token string.
    /// - Returns: The expiration date, or nil if parsing fails.
    private func parseExpiration(from token: String) -> Date? {
        if token.contains(" ") {
            Exponea.logger.log(.warning, message: "JWT: Invalid token format - token must not contain spaces or prefixes")
            return nil
        }
        let parts = token.split(separator: ".")
        guard parts.count == 3 else {
            Exponea.logger.log(.warning, message: "JWT: Invalid token format - expected 3 parts, got \(parts.count)")
            return nil
        }
        let payloadPart = String(parts[1])
        
        var base64 = payloadPart
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        while base64.count % 4 != 0 { base64.append("=") }
        
        guard let data = Data(base64Encoded: base64) else {
            Exponea.logger.log(.warning, message: "JWT: Failed to decode base64 payload")
            return nil
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            Exponea.logger.log(.warning, message: "JWT: Failed to parse payload JSON")
            return nil
        }
        
        // Support both Int and Double for exp claim
        let exp: TimeInterval?
        if let expInt = json["exp"] as? Int {
            exp = TimeInterval(expInt)
        } else if let expDouble = json["exp"] as? Double {
            exp = expDouble
        } else {
            Exponea.logger.log(.warning, message: "JWT: No 'exp' claim found in token")
            return nil
        }
        
        guard let expValue = exp else { return nil }
        return Date(timeIntervalSince1970: expValue)
    }
    
    /// Schedules a refresh timer if token has an expiration date.
    /// Must be called from the queue.
    private func scheduleRefreshIfNeeded() {
        guard let exp = expirationDate else { return }
        
        let refreshDate = exp.addingTimeInterval(-expirationBuffer)
        guard refreshDate > Date() else {
            triggerRefreshOnQueue(reason: .expiredSoon, endpoint: "tracking", status: 0, error: nil)
            return
        }
        
        let timeInterval = refreshDate.timeIntervalSinceNow
        guard timeInterval > 0 else {
            triggerRefreshOnQueue(reason: .expiredSoon, endpoint: "tracking", status: 0, error: nil)
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.timerLock.lock()
            self._refreshTimer?.invalidate()
            self.timerLock.unlock()

            let timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
                self?.queue.async { [weak self] in
                    self?.triggerRefreshOnQueue(reason: .expiredSoon, endpoint: "tracking", status: 0, error: nil)
                }
            }

            self.timerLock.lock()
            self._refreshTimer = timer
            self.timerLock.unlock()

            Exponea.logger.log(.verbose, message: "JWT: Refresh timer scheduled for \(refreshDate)")
        }
    }
    
    private func invalidateTimerOnMain() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.timerLock.lock()
            self._refreshTimer?.invalidate()
            self._refreshTimer = nil
            self.timerLock.unlock()
        }
    }
    
    /// Triggers the error handler. Must be called from within the queue.
    private func triggerRefreshOnQueue(
        reason: JwtErrorContext.Reason,
        endpoint: String,
        status: Int,
        error: Error?
    ) {
        // Capture handler while on queue
        guard let handler = errorHandler else {
            Exponea.logger.log(.verbose, message: "JWT: Error occurred (\(reason)) but no error handler registered")
            return
        }
        let customerIds = customerIdsProvider?() ?? nil
        let ctx = JwtErrorContext(reason: reason, customerIds: customerIds)
        Exponea.logger.log(.verbose, message: "JWT: Triggering error handler - reason: \(reason), endpoint: \(endpoint), status: \(status)")
        DispatchQueue.main.async {
            let exception = objc_tryCatch {
                handler(ctx)
            }
            if let exception = exception {
                Exponea.logger.log(
                    .error,
                    message: "JWT error handler threw an exception for \(reason): \(exception), proceeding as if no handler was registered"
                )
            }
        }
    }
    
    private func notifyTokenRefreshed() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: JwtAuthManager.tokenRefreshedNotification,
                object: nil
            )
        }
    }
}

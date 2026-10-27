import Foundation
import UIKit
import UserNotifications
import ExponeaSDK

@MainActor
final class TrackingViewModel: ObservableObject {

    @Published var feedback: String?
    @Published var isStreamMode: Bool

    init(isStreamMode: Bool) {
        self.isStreamMode = isStreamMode
    }

    private static let cookiePlaceholder = "<not initialized>"

    @Published private(set) var cookieDisplay: String = TrackingViewModel.cookiePlaceholder

    var canCopyCookie: Bool {
        cookieDisplay != Self.cookiePlaceholder
    }

    func refreshCookie() {
        let cookie = ExponeaService.customerCookie ?? ""
        cookieDisplay = cookie.isEmpty ? Self.cookiePlaceholder : cookie
    }

    /// The SDK initializes asynchronously after Start, so the cookie can appear a moment after the screen.
    /// Re-reads it every 250 ms for up to 10 s, until it is available or the task is cancelled.
    func refreshCookieUntilAvailable() async {
        for _ in 0..<40 where !Task.isCancelled {
            refreshCookie()
            if canCopyCookie { return }
            try? await Task.sleep(nanoseconds: 250_000_000)
        }
    }

    func copyCookieToClipboard() {
        guard canCopyCookie else { return }
        UIPasteboard.general.string = cookieDisplay
        feedback = "Cookie ID copied to clipboard"
    }

    // MARK: - Identify

    /// Returns `false` when nothing was sent to the SDK.
    @discardableResult
    func identify(
        customerIds: [String: String],
        properties: [String: String],
        withToken: Bool
    ) -> Bool {
        if withToken && !DemoJwtSession.isConfigured {
            feedback = "JWT Key ID and Secret must be provided during configuration."
            return false
        }
        let sdkProps: [String: JSONConvertible] = properties.mapValues { $0 }
        let token: String? = withToken
            ? DemoJwtSession.generateToken(customerIds: customerIds)
            : nil
        ExponeaService.identifyCustomer(customerIds: customerIds, properties: sdkProps, jwtToken: token)
        feedback = "Customer identified"
        return true
    }

    // MARK: - Set auth token

    func setAuthToken(customerId: String, isCustomerIdentified: Bool) {
        guard DemoJwtSession.isConfigured else {
            feedback = "JWT not configured"
            return
        }
        guard isCustomerIdentified, !customerId.isEmpty else {
            feedback = "Identify a customer first"
            return
        }
        guard let token = DemoJwtSession.generateToken(customerIds: ["registered": customerId]) else {
            feedback = "Token generation failed"
            return
        }
        ExponeaService.setSdkAuthToken(token)
        feedback = "Auth token set"
    }

    // MARK: - Events

    func trackCustomEvent(name: String, properties: [String: String]) {
        let sdkProps: [String: JSONConvertible] = properties.mapValues { $0 }
        ExponeaService.trackEvent(name: name, properties: sdkProps)
        feedback = "Custom event tracked: \(name)"
    }

    func trackPayment() {
        ExponeaService.trackPayment(properties: [
            "product_id": "demo_item",
            "product_title": "Demo Product",
            "price": 99,
            "currency": "USD",
            "quantity": 1
        ])
        feedback = "Payment tracked: 99 USD demo_item"
    }

    func trackPageView() {
        ExponeaService.trackPageView(screenName: "Tracking")
        feedback = "Page view tracked: Tracking"
    }

    // MARK: - Push

    func requestPushPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                if let error {
                    self?.feedback = "Permission error: \(error.localizedDescription)"
                } else {
                    self?.feedback = granted ? "Push permission granted." : "Push permission denied."
                    if granted {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            }
        }
    }

    /// Tracks the device's APNs token again as notification_state. Without one (push permission not
    /// granted yet, or no APNs token on the simulator) it tracks a demo value, which replaces any token
    /// stored for this customer until the app registers for remote notifications.
    func trackPushToken() {
        if let token = AppDelegate.lastPushToken {
            ExponeaService.trackPushToken(token)
            feedback = "Push token tracked."
        } else {
            let token = "demo-push-token-\(Int(Date().timeIntervalSince1970 * 1000))"
            ExponeaService.trackPushToken(Data(token.utf8))
            feedback = "No APNs token yet; push token tracked (demo value)."
        }
    }

    func trackDeliveredPush() {
        ExponeaService.trackDeliveredPush()
        feedback = "Delivered push tracked."
    }

    func trackClickedPush() {
        ExponeaService.trackClickedPush()
        feedback = "Clicked push tracked."
    }
}

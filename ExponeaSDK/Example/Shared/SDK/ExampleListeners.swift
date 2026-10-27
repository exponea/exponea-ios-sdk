import Foundation
import ExponeaSDK

/// SDK listeners that write into the in-app logs sheet. In-app messages keep the SDK's default button
/// handling and tracking; on top of that, GDPR and "Stop SDK" test messages can stop the integration.
enum ExampleListeners {

    /// Posted on the main queue after an in-app message stopped the SDK integration.
    static let integrationStoppedNotification = Notification.Name("ExampleIntegrationStoppedByInAppMessage")

    private static var segmentationRegistered = false
    private static let inAppObserver = ExampleInAppMessageHandler()
    private static let pushObserver = ExamplePushObserver()

    /// Passed to `configure` through `.enabled(appGroup:delegate:)`; the SDK keeps only a weak reference.
    static var pushDelegate: PushNotificationManagerDelegate { pushObserver }

    static func register() {
        // A new configure starts a new session that a stop scheduled by the previous one must not reach.
        inAppObserver.cancelScheduledStop()
        Exponea.shared.inAppMessagesDelegate = inAppObserver
        // Before the first configure the SDK has no push manager to attach the delegate to;
        // `configure` sets it from `pushDelegate` instead.
        if Exponea.shared.isConfigured {
            Exponea.shared.pushNotificationsDelegate = pushObserver
        }
        registerSegmentationCallbacksOnce()
    }

    /// Segmentation callbacks live until the app terminates, so they are registered once per process.
    private static func registerSegmentationCallbacksOnce() {
        guard !segmentationRegistered else { return }
        segmentationRegistered = true
        let categories: [(name: String, category: SegmentCategory)] = [
            ("discovery", .discovery()),
            ("content", .content()),
            ("merchandising", .merchandising())
        ]
        for (name, category) in categories {
            SegmentationManager.shared.addCallback(
                callbackData: SegmentCallbackData(category: category, isIncludeFirstLoad: false) { segments in
                    log(.verbose, "Segments: New for \(name) with IDs: \(segments)")
                }
            )
        }
    }

    /// Called on the main queue whenever the integration stops, so a pending "Stop SDK" timer can't fire later.
    static func cancelScheduledStop() {
        inAppObserver.cancelScheduledStop()
    }

    fileprivate static func log(_ level: LogLevel, _ message: String) {
        DispatchQueue.main.async {
            InAppLogStore.shared.append(level: level, message: message)
        }
    }
}

/// Keeps the SDK's default button handling and tracking, and reacts to two kinds of test messages:
/// - a message named "Stop SDK" / "StopSDK" stops the integration 4 seconds after it is shown;
/// - a GDPR message (name contains "GDPR") tracks a `gdpr` event when the allow button is tapped, and
///   stops the integration when the deny button is tapped or the user closes the message.
private final class ExampleInAppMessageHandler: InAppMessageActionDelegate {
    let overrideDefaultBehavior = false
    let trackActions = true

    private static let gdprAllowUrl = "https://bloomreach.com/tracking/allow"
    private static let gdprDenyUrl = "https://bloomreach.com/tracking/deny"

    /// The pending "Stop SDK" stop; only touched on the main queue.
    private var scheduledStop: DispatchWorkItem?

    func inAppMessageShown(message: InAppMessage) {
        ExampleListeners.log(.verbose, "In-app message \(message.name) has been shown")
        if isStopSdkMessage(message) {
            ExampleListeners.log(.verbose, "In-app message \(message.name) stops the SDK integration in 4 s")
            DispatchQueue.main.async {
                self.scheduledStop?.cancel()
                let stop = DispatchWorkItem {
                    self.stopIntegration(reason: "In-app message \(message.name)")
                }
                self.scheduledStop = stop
                DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: stop)
            }
        }
    }

    func cancelScheduledStop() {
        scheduledStop?.cancel()
        scheduledStop = nil
    }

    func inAppMessageError(message: InAppMessage?, errorMessage: String) {
        ExampleListeners.log(.error, "Error '\(errorMessage)' while showing in-app message \(message?.name ?? "-")")
    }

    func inAppMessageClickAction(message: InAppMessage, button: InAppMessageButton) {
        ExampleListeners.log(.verbose, "In-app message \(message.name) has been clicked: \(button.url ?? "-")")
        guard isGdprMessage(message) else { return }
        switch button.url {
        case Self.gdprAllowUrl:
            ExponeaService.trackEvent(name: "gdpr", properties: ["status": "allowed"])
            ExampleListeners.log(.verbose, "GDPR consent allowed; tracked gdpr event")
        case Self.gdprDenyUrl:
            stopIntegration(reason: "GDPR consent denied")
        default:
            break
        }
    }

    func inAppMessageCloseAction(message: InAppMessage, button: InAppMessageButton?, interaction: Bool) {
        ExampleListeners.log(.verbose, "In-app message \(message.name) has been closed (interaction: \(interaction))")
        if isGdprMessage(message) && interaction {
            stopIntegration(reason: "GDPR message closed by the user")
        }
    }

    private func isStopSdkMessage(_ message: InAppMessage) -> Bool {
        message.name.lowercased().replacingOccurrences(of: " ", with: "").contains("stopsdk")
    }

    private func isGdprMessage(_ message: InAppMessage) -> Bool {
        message.name.uppercased().contains("GDPR")
    }

    private func stopIntegration(reason: String) {
        DispatchQueue.main.async {
            ExampleListeners.log(.verbose, "\(reason): stopping the SDK integration")
            ExponeaService.stopIntegration {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: ExampleListeners.integrationStoppedNotification, object: nil)
                }
            }
        }
    }
}

private final class ExamplePushObserver: PushNotificationManagerDelegate {
    func pushNotificationOpened(with action: ExponeaNotificationActionType, value: String?, extraData: [AnyHashable: Any]?) {
        ExampleListeners.log(.verbose, "Push notification opened: action \(action), value \(value ?? "-")")
    }

    func silentPushNotificationReceived(extraData: [AnyHashable: Any]?) {
        ExampleListeners.log(.verbose, "Silent push notification received: \(extraData ?? [:])")
    }
}

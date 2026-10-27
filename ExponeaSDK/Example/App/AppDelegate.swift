import UIKit
import ExponeaSDK

// Queried through reflection by the SDK to identify its bundled example app.
@objc(IsExponeaExampleApp)
protocol IsExponeaExampleApp {
}

/// `ExponeaAppDelegate` becomes the notification center delegate and forwards the push token, opened
/// pushes and silent pushes to the SDK. It also hides Bloomreach pushes in the foreground once the
/// integration is stopped.
final class AppDelegate: ExponeaAppDelegate {

    /// The APNs token from the latest registration in this process, so the Tracking screen can track it again.
    static private(set) var lastPushToken: Data?

    override func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        AppDelegate.lastPushToken = deviceToken
        super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        InAppLogStore.shared.append(level: .error, message: "APNs registration failed: \(error.localizedDescription)")
    }
}

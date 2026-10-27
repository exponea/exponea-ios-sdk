import SwiftUI

@main
struct ExampleApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var sdkState = SdkState()
    @StateObject private var logStore = InAppLogStore.shared
    @StateObject private var deeplinks = DeeplinkCenter.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(sdkState)
                .environmentObject(logStore)
                .environmentObject(deeplinks)
                // Scene-based app: exponea:// links arrive here on cold and warm start.
                .onOpenURL { deeplinks.handle($0) }
                // Universal links arrive as a browsing-web activity, both from the system and from the SDK
                // (in-app message and content block buttons). Without this handler SwiftUI accepts the
                // SDK-forwarded activity but never delivers it to onOpenURL.
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    guard let url = activity.webpageURL else { return }
                    deeplinks.handle(url)
                }
        }
    }
}

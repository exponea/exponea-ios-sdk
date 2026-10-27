import SwiftUI
import ExponeaSDK

// Root router driven by SdkState: shows the loading screen, then ConfigurationView or MainTabView.
struct RootView: View {

    @EnvironmentObject private var sdkState: SdkState
    @EnvironmentObject private var deeplinks: DeeplinkCenter
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if sdkState.isInitialized {
                MainTabView()
            } else {
                NavigationView {
                    ConfigurationView()
                }
                .navigationViewStyle(.stack)
            }
        }
        // A link that arrives before login waits for the shell; stopAndRestart already ends on this screen.
        .onReceive(deeplinks.$pending) { action in
            if action == .stopAndRestart && !isLoading && !sdkState.isInitialized {
                _ = deeplinks.consume()
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            ConfigurationBootstrap.runIfNeeded(sdkState: sdkState)
            isLoading = false
        }
    }
}

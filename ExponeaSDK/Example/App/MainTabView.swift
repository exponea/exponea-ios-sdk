import SwiftUI
import UIKit

struct MainTabView: View {

    @EnvironmentObject private var sdkState: SdkState
    @EnvironmentObject private var logStore: InAppLogStore
    @EnvironmentObject private var deeplinks: DeeplinkCenter
    @State private var selectedTab: AppTab = .fetching
    @State private var isLogsPresented = false
    @State private var isConfigSheetPresented = false
    @State private var isResetSheetPresented = false

    // Owned here so each tab keeps its state while only the selected screen is in the view tree.
    @StateObject private var fetchingViewModel = FetchingViewModel()
    @StateObject private var trackingViewModel = TrackingViewModel(isStreamMode: false)
    @StateObject private var flushingViewModel = FlushingViewModel()
    @StateObject private var anonymizeViewModel = AnonymizeViewModel()
    @StateObject private var contentBlocksViewModel = ContentBlocksViewModel()

    var body: some View {
        Group {
            if #available(iOS 16.0, *) {
                NavigationStack {
                    shellTabView
                }
            } else {
                NavigationView {
                    shellTabView
                }
                .navigationViewStyle(.stack)
            }
        }
        .onAppear {
            ExampleAppearance.configureShellNavigationBar()
            trackPageView(selectedTab)
            performPendingDeeplink()
        }
        .onReceive(deeplinks.$pending) { action in
            if action != nil { performPendingDeeplink() }
        }
        .onReceive(NotificationCenter.default.publisher(for: ExampleListeners.integrationStoppedNotification)) { _ in
            sdkState.markStopped()
        }
        .onChange(of: selectedTab) { newTab in
            ExampleAppearance.configureShellNavigationBar()
            trackPageView(newTab)
        }
        .sheet(isPresented: $isLogsPresented) {
            LogsView()
                .environmentObject(logStore)
        }
        .sheet(isPresented: $isConfigSheetPresented) {
            ConfigurationSummarySheet(
                isConfigured: ExponeaService.isConfigured,
                tokenTrackFrequencyLabel: ExponeaService.configurationSnapshot?.tokenTrackFrequencyLabel,
                applicationId: ExponeaService.configurationSnapshot?.applicationId
            )
        }
        .sheet(isPresented: $isResetSheetPresented) {
            ResetIntegrationSheet(
                onBackToAuth: handleResetBackToAuth,
                onStopAndContinue: handleResetStopAndContinue
            )
        }
    }

    /// Only the selected screen is in the view tree, so XCUITest never sees another tab's ids
    /// (hidden SwiftUI views stay in the WebDriverAgent tree). View models live above, so state is kept.
    private var shellTabView: some View {
        screenView(for: selectedTab)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                ExampleBottomNavigation(selection: $selectedTab)
            }
            .exampleShellNavigationBar()
            .toolbar { shellToolbar }
    }

    @ViewBuilder
    private func screenView(for tab: AppTab) -> some View {
        switch tab {
        case .fetching:
            FetchingView(viewModel: fetchingViewModel)
        case .tracking:
            TrackingView(viewModel: trackingViewModel)
        case .flushing:
            FlushingView(viewModel: flushingViewModel)
        case .anonymize:
            AnonymizeView(viewModel: anonymizeViewModel)
        case .contentBlocks:
            ContentBlocksView(viewModel: contentBlocksViewModel)
        }
    }

    @ToolbarContentBuilder
    private var shellToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            ExampleShellLogoButton {
                isConfigSheetPresented = true
            }
            .accessibilityIdentifier(A11yID.shell.shellLogo)
            .accessibilityLabel("Bloomreach logo")
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 4) {
                StatusSemaphoreView()

                Button {
                    isLogsPresented = true
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 18, weight: .regular))
                }
                .buttonStyle(.plain)
                .foregroundColor(BrandColors.white)
                .accessibilityIdentifier(A11yID.shell.openLogs)
                .accessibilityLabel("Logs")

                Button("Reset") {
                    isResetSheetPresented = true
                }
                .buttonStyle(.plain)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(BrandColors.white)
                .fixedSize(horizontal: true, vertical: false)
                .accessibilityIdentifier(A11yID.shell.resetState)
                .accessibilityLabel("Reset state")
            }
        }
    }

    private func performPendingDeeplink() {
        switch deeplinks.consume() {
        case .open(let tab):
            selectedTab = tab
        case .stopAndContinue:
            selectedTab = .fetching
            handleResetStopAndContinue()
        case .stopAndRestart:
            handleResetBackToAuth()
        case nil:
            break
        }
    }

    private func handleResetBackToAuth() {
        isResetSheetPresented = false
        ExponeaService.stopIntegration {
            DispatchQueue.main.async {
                logStore.clear()
                sdkState.resetToAuthentication()
            }
        }
    }

    private func handleResetStopAndContinue() {
        isResetSheetPresented = false
        ExponeaService.stopIntegration {
            DispatchQueue.main.async {
                sdkState.markStopped()
            }
        }
    }
}

struct ConfigurationSummarySheet: View {
    @Environment(\.dismiss) private var dismiss

    let isConfigured: Bool
    let tokenTrackFrequencyLabel: String?
    let applicationId: String?

    var body: some View {
        VStack(spacing: 0) {
            ExampleSheetHeader(
                title: "Exponea configuration",
                onClose: { dismiss() },
                closeAccessibilityId: A11yID.shell.configClose
            )

            Group {
                if isConfigured {
                    configuredList
                } else {
                    Text("SDK not configured")
                        .foregroundColor(BrandColors.grey600)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityIdentifier(A11yID.shell.configNotConfigured)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(BrandColors.grey100)
        }
    }

    private var configuredList: some View {
        List {
            Section {
                HStack {
                    Text("Token track frequency")
                    Spacer()
                    Text(tokenTrackFrequencyLabel ?? "on token change")
                        .foregroundColor(BrandColors.grey600)
                }
                HStack {
                    Text("Application ID")
                    Spacer()
                    Text(applicationId ?? "default-application")
                        .foregroundColor(BrandColors.grey600)
                }
            }
        }
        .modifier(HideScrollContentBackgroundIfAvailable())
    }
}

private struct HideScrollContentBackgroundIfAvailable: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.scrollContentBackground(.hidden)
        } else {
            content
        }
    }
}

struct ResetIntegrationSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onBackToAuth: () -> Void
    let onStopAndContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ExampleSheetHeader(
                title: "Reset state",
                onClose: { dismiss() }
            )

            VStack(alignment: .leading, spacing: 12) {
                Text("Stop integration?")
                    .font(.headline)
                    .foregroundColor(BrandColors.brBlack)
                Text("Choose how to reset SDK state.")
                    .font(.subheadline)
                    .foregroundColor(BrandColors.grey600)

                ExamplePrimaryButton(title: "Back to Auth", action: onBackToAuth)
                    .accessibilityIdentifier(A11yID.shell.resetBackToAuth)

                ExampleOutlinedButton(title: "Stop and Continue", action: onStopAndContinue)
                    .accessibilityIdentifier(A11yID.shell.resetStopAndContinue)

                Button("Cancel") { dismiss() }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .foregroundColor(BrandColors.grey600)
                    .accessibilityIdentifier(A11yID.shell.resetCancel)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(BrandColors.grey100)
        }
    }
}

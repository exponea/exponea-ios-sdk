import SwiftUI

/// Brief Bloomreach branding screen shown before the configuration screen or the main shell.
struct LoadingView: View {
    var body: some View {
        ZStack {
            BrandColors.white
                .ignoresSafeArea()
            ExampleBrandMiniLogo(size: 96)
                .accessibilityIdentifier(A11yID.shell.loadingLogo)
                .accessibilityLabel("Bloomreach logo")
        }
    }
}

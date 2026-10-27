import SwiftUI

struct StatusSemaphoreView: View {

    @EnvironmentObject private var sdkState: SdkState

    private var accessibilityValue: String {
        switch sdkState.semaphore {
        case .notInitialized: return "notInitialized"
        case .anonymous:      return "anonymous"
        case .identified:     return "identified"
        }
    }

    var body: some View {
        Circle()
            .fill(sdkState.semaphore.color)
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .stroke(BrandColors.white, lineWidth: 1)
            )
            .padding(.horizontal, 4)
            .accessibilityElement(children: .ignore)
            .accessibilityIdentifier(A11yID.shell.statusIndicator)
            .accessibilityValue(accessibilityValue)
            .accessibilityLabel("SDK status")
    }
}

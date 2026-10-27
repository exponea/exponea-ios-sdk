import SwiftUI

struct AnonymizeView: View {

    @EnvironmentObject private var sdkState: SdkState
    @EnvironmentObject private var logStore: InAppLogStore
    @ObservedObject var viewModel: AnonymizeViewModel

    var body: some View {
        VStack(spacing: 8) {
            ExampleSectionCard(title: "Anonymize") {
                VStack(alignment: .leading, spacing: 12) {
                    Text(
                        "Anonymize clears local customer data and starts a new anonymous session. "
                            + "Stop Integration de-integrates the SDK."
                    )
                    .font(.subheadline)
                    .foregroundColor(BrandColors.grey600)

                    ExamplePrimaryButton(
                        title: "Anonymize",
                        disabled: viewModel.isBusy,
                        action: { viewModel.anonymize() }
                    )
                    .accessibilityIdentifier(A11yID.anonymize.anonymize)

                    ExampleOutlinedButton(
                        title: "Stop Integration",
                        borderColor: BrandColors.red,
                        foreground: BrandColors.red,
                        disabled: viewModel.isBusy,
                        action: { viewModel.showStopConfirmation = true }
                    )
                    .accessibilityIdentifier(A11yID.anonymize.stopIntegration)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .exampleScreenBackground()
        .onAppear {
            viewModel.sdkState = sdkState
            viewModel.logStore = logStore
        }
        .alert("Customer anonymized", isPresented: $viewModel.showAnonymizedDialog) {
            Button("Ok") { viewModel.showAnonymizedDialog = false }
                .accessibilityIdentifier(A11yID.anonymize.anonymizedOk)
        } message: {
            Text("Stored customer data cleared.")
        }
        .alert("SDK is stopped", isPresented: $viewModel.showStoppedDialog) {
            Button("Ok", role: .cancel) {}
        } message: {
            Text("The SDK integration is stopped, so nothing was anonymized.")
        }
        .alert("Stop integration?", isPresented: $viewModel.showStopConfirmation) {
            Button("Back to Auth") {
                viewModel.stopBackToAuth()
            }
            .accessibilityIdentifier(A11yID.anonymize.stopBackToAuth)

            Button("Stop & Continue") {
                viewModel.stopAndContinue()
            }
            .accessibilityIdentifier(A11yID.anonymize.stopStopAndContinue)

            Button("Cancel", role: .cancel) {}
                .accessibilityIdentifier(A11yID.anonymize.stopCancel)
        } message: {
            Text(
                "This de-integrates the SDK. Choose Back to Auth to stop the SDK and "
                    + "re-configure, Stop & Continue to stop the SDK and remain on this "
                    + "screen (broken state), or Cancel to keep the current session."
            )
        }
        .overlay {
            if viewModel.isBusy {
                ProgressView()
                    .tint(BrandColors.brBlack)
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(8)
            }
        }
    }
}

import SwiftUI

/// Runtime ICB lab: drives `Exponea.shared.inAppContentBlocksController` (prefetch, invalidate,
/// availability) and logs the results.
struct RuntimeControllerLabView: View {

    @EnvironmentObject private var sdkState: SdkState
    @StateObject private var viewModel = RuntimeControllerLabViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                inputsCard
                scenariosCard
                ForEach(viewModel.mounted, id: \.self) { placeholderId in
                    ExampleSectionCard(title: "Placeholder: \(placeholderId)") {
                        ContentBlockPlaceholderView(placeholderId: placeholderId) { event in
                            viewModel.log("VIEW \(placeholderId): \(event)")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .id("\(viewModel.mountVersion):\(placeholderId)")
                }
                logCard
            }
        }
        // Leaving the lab (another tab or screen) discards it, so stop its running scenario too.
        .onAppear { viewModel.sdkState = sdkState }
        .onDisappear { viewModel.cancel() }
    }

    private var inputsCard: some View {
        ExampleSectionCard(title: "Runtime ICB Lab") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Exponea.shared.inAppContentBlocksController")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(BrandColors.grey600)
                Text("Controller: \(viewModel.isControllerPresent ? "present" : "not configured")")
                    .font(.subheadline)
                    .foregroundColor(BrandColors.brBlack)
                Text("Placeholder IDs (comma-separated)")
                    .font(.caption)
                    .foregroundColor(BrandColors.grey600)
                TextField("", text: $viewModel.idsText)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .disabled(viewModel.isBusy)
                    .exampleInputStyle()
                    .accessibilityIdentifier(A11yID.contentBlocks.runtimeIdsInput)
                Text("Availability / prefetch snapshot deadline (milliseconds)")
                    .font(.caption)
                    .foregroundColor(BrandColors.grey600)
                TextField("", text: $viewModel.deadlineText)
                    .keyboardType(.numberPad)
                    .disabled(viewModel.isBusy)
                    .exampleInputStyle()
                    .accessibilityIdentifier(A11yID.contentBlocks.runtimeDeadlineInput)
                Text("Identity scenarios change the SDK customer to user_a, user_b or anonymous.")
                    .font(.caption)
                    .foregroundColor(BrandColors.grey600)
            }
        }
    }

    private var scenariosCard: some View {
        ExampleSectionCard(title: "Scenarios") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(RuntimeLabScenario.allCases) { scenario in
                    ExamplePrimaryButton(title: scenario.title, disabled: viewModel.isBusy) {
                        viewModel.start(scenario)
                    }
                    .modifier(OptionalAccessibilityIdentifier(identifier: scenario.identifier))
                }
                Text("Happy path and post-login mount warmed content. Lazy invalidate waits 500ms before fetching again. Timeout uses a 1ms deadline.")
                    .font(.caption)
                    .foregroundColor(BrandColors.grey600)
            }
        }
    }

    private var logCard: some View {
        ExampleSectionCard(title: "Log") {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.logText)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(BrandColors.grey700)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier(A11yID.contentBlocks.runtimeStatus)
                HStack(spacing: 8) {
                    Button("Clear log") { viewModel.clearLog() }
                        .buttonStyle(ExampleOutlinedButtonStyle())
                    Button("Copy log") { viewModel.copyLog() }
                        .buttonStyle(ExampleOutlinedButtonStyle())
                }
            }
        }
    }
}

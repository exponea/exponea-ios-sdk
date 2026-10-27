import SwiftUI

struct ConfigurationView: View {

    @StateObject private var viewModel = ConfigurationViewModel()
    @EnvironmentObject private var sdkState: SdkState

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ExampleAuthLogo()
                    .padding(.top, 24)

                Text("SDK Configuration")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(BrandColors.brBlack)
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier(A11yID.auth.title)

                modeToggle

                if viewModel.mode == .project {
                    projectFields
                } else {
                    streamFields
                }

                commonFields

                if !viewModel.formIsValid, let hint = viewModel.validationError {
                    Text(hint)
                        .font(.footnote)
                        .foregroundColor(BrandColors.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(BrandColors.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                startButton
                clearLocalDataButton
            }
            .padding(24)
        }
        .background(BrandColors.white)
        .disabled(viewModel.isLoading)
        .onAppear {
            ExampleAppearance.configureAuthNavigationBar()
        }
    }

    private var modeToggle: some View {
        HStack(spacing: 8) {
            ExampleModeButton(
                title: IntegrationMode.project.rawValue,
                isSelected: viewModel.mode == .project,
                action: { viewModel.mode = .project }
            )
            .accessibilityIdentifier(A11yID.auth.modeProject)

            ExampleModeButton(
                title: "Stream",
                isSelected: viewModel.mode == .stream,
                action: { viewModel.mode = .stream }
            )
            .accessibilityIdentifier(A11yID.auth.modeStream)
        }
    }

    private var projectFields: some View {
        VStack(spacing: 12) {
            authField(
                label: NSLocalizedString("config.field.projectToken", comment: ""),
                text: $viewModel.projectToken,
                aid: A11yID.auth.projectToken
            )
            authField(
                label: NSLocalizedString("config.field.authToken", comment: ""),
                text: $viewModel.authToken,
                aid: A11yID.auth.authToken
            )
            authField(
                label: NSLocalizedString("config.field.advancedAuthKey", comment: ""),
                text: $viewModel.advancedAuthKey,
                aid: A11yID.auth.advancedAuth,
                required: false
            )
        }
    }

    private var streamFields: some View {
        VStack(spacing: 12) {
            authField(
                label: NSLocalizedString("config.field.streamId", comment: ""),
                text: $viewModel.streamId,
                aid: A11yID.auth.streamId
            )
            authField(
                label: NSLocalizedString("config.field.jwtKeyId", comment: ""),
                text: $viewModel.jwtKeyId,
                aid: A11yID.auth.jwtKeyId,
                required: false
            )
            authField(
                label: NSLocalizedString("config.field.jwtSecret", comment: ""),
                text: $viewModel.jwtSecret,
                aid: A11yID.auth.jwtSecret,
                required: false,
                isSecure: true
            )
        }
    }

    private var commonFields: some View {
        VStack(spacing: 12) {
            authField(
                label: NSLocalizedString("config.field.registeredId", comment: ""),
                text: $viewModel.registeredId,
                aid: A11yID.auth.registeredId,
                required: false
            )
            authField(
                label: NSLocalizedString("config.field.baseUrl", comment: ""),
                text: $viewModel.baseUrl,
                aid: A11yID.auth.apiUrl,
                keyboardType: .URL
            )
            authField(
                label: NSLocalizedString("config.field.applicationId", comment: ""),
                text: $viewModel.applicationId,
                aid: A11yID.auth.applicationId,
                required: false
            )
        }
    }

    private var startButton: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .tint(BrandColors.brBlack)
                    .frame(maxWidth: .infinity, minHeight: 44)
            } else {
                ExamplePrimaryButton(
                    title: NSLocalizedString("config.action.start", comment: ""),
                    disabled: !viewModel.formIsValid,
                    action: { viewModel.start(sdkState: sdkState) }
                )
            }
        }
        .accessibilityIdentifier(A11yID.auth.start)
    }

    private var clearLocalDataButton: some View {
        ExampleOutlinedButton(
            title: NSLocalizedString("config.action.clearLocalData", comment: ""),
            disabled: viewModel.isLoading,
            action: { viewModel.clearLocalData() }
        )
        .accessibilityIdentifier(A11yID.auth.clearLocalData)
    }

    private func authField(
        label: String,
        text: Binding<String>,
        aid: String,
        required: Bool = true,
        keyboardType: UIKeyboardType = .default,
        isSecure: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label + (required ? "" : " (optional)"))
                .font(.subheadline)
                .foregroundColor(BrandColors.grey600)

            Group {
                if isSecure {
                    SecureField(label, text: text)
                } else {
                    TextField(label, text: text)
                }
            }
            .exampleInputStyle()
            .keyboardType(keyboardType)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .accessibilityIdentifier(aid)
        }
    }
}

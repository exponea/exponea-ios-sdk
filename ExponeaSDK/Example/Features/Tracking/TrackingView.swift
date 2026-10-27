import SwiftUI

struct TrackingView: View {

    @EnvironmentObject private var sdkState: SdkState
    @ObservedObject var viewModel: TrackingViewModel

    @State private var showIdentifyDialog = false
    @State private var showCustomEventDialog = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 8) {
                    ExampleSectionCard(title: "Cookie ID") {
                    HStack(alignment: .top, spacing: 8) {
                        Text(viewModel.cookieDisplay)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(BrandColors.grey600)
                            .lineLimit(3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityIdentifier(A11yID.tracking.cookieId)
                        Button {
                            viewModel.copyCookieToClipboard()
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(BrandColors.brBlack)
                        }
                        .disabled(!viewModel.canCopyCookie)
                        .accessibilityIdentifier(A11yID.tracking.copyCookieId)
                    }
                }

                ExampleSectionCard(title: "Customer") {
                    VStack(spacing: 6) {
                        primaryRow(
                            title: NSLocalizedString("tracking.identify", comment: ""),
                            action: { showIdentifyDialog = true }
                        )
                        .accessibilityIdentifier(A11yID.tracking.identifyCustomer)

                        outlinedRow(
                            title: NSLocalizedString("tracking.setAuthToken", comment: ""),
                            action: {
                                viewModel.setAuthToken(
                                    customerId: sdkState.registeredId,
                                    isCustomerIdentified: sdkState.identity == .identified
                                )
                            }
                        )
                        .accessibilityIdentifier(A11yID.tracking.setAuthToken)
                    }
                }

                ExampleSectionCard(title: "Events") {
                    VStack(spacing: 6) {
                        outlinedRow(
                            title: NSLocalizedString("tracking.customEvent", comment: ""),
                            action: { showCustomEventDialog = true }
                        )
                        .accessibilityIdentifier(A11yID.tracking.customEvent)

                        outlinedRow(
                            title: NSLocalizedString("tracking.trackPayment", comment: ""),
                            action: { viewModel.trackPayment() }
                        )
                        .accessibilityIdentifier(A11yID.tracking.payment)

                        outlinedRow(
                            title: "Track Page View",
                            action: { viewModel.trackPageView() }
                        )
                        .accessibilityIdentifier(A11yID.tracking.pageView)
                    }
                }

                ExampleSectionCard(title: "Push") {
                    VStack(spacing: 6) {
                        primaryRow(
                            title: NSLocalizedString("tracking.requestPushPermission", comment: ""),
                            action: { viewModel.requestPushPermission() }
                        )
                        .accessibilityIdentifier(A11yID.tracking.requestPush)

                        outlinedRow(
                            title: "Track Push Token",
                            action: { viewModel.trackPushToken() }
                        )
                        .accessibilityIdentifier(A11yID.tracking.fcmToken)

                        HStack(spacing: 6) {
                            outlinedRow(
                                title: NSLocalizedString("tracking.trackDeliveredPush", comment: ""),
                                action: { viewModel.trackDeliveredPush() }
                            )
                            .accessibilityIdentifier(A11yID.tracking.deliveredPush)

                            outlinedRow(
                                title: NSLocalizedString("tracking.trackClickedPush", comment: ""),
                                action: { viewModel.trackClickedPush() }
                            )
                            .accessibilityIdentifier(A11yID.tracking.clickedPush)
                        }
                    }
                }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .exampleScreenBackground()
        .onAppear {
            viewModel.isStreamMode = sdkState.isStreamMode
        }
        .onReceive(sdkState.$identity) { _ in
            viewModel.isStreamMode = sdkState.isStreamMode
            viewModel.refreshCookie()
        }
        .task {
            await viewModel.refreshCookieUntilAvailable()
        }
        .sheet(isPresented: $showIdentifyDialog) {
            IdentifyDialog(
                isPresented: $showIdentifyDialog,
                isStreamMode: viewModel.isStreamMode,
                isCustomerIdentified: sdkState.identity == .identified,
                savedRegisteredId: sdkState.registeredId,
                onConfirm: { ids, props, withToken in
                    if viewModel.identify(customerIds: ids, properties: props, withToken: withToken) {
                        sdkState.markIdentified(registeredId: ids["registered"] ?? "")
                    }
                }
            )
        }
        .sheet(isPresented: $showCustomEventDialog) {
            TrackCustomEventDialog(isPresented: $showCustomEventDialog) { name, props in
                viewModel.trackCustomEvent(name: name, properties: props)
            }
        }
        .overlay(alignment: .bottom) {
            if let msg = viewModel.feedback {
                FeedbackBanner(message: msg) { viewModel.feedback = nil }
            }
        }
    }

    private func primaryRow(title: String, action: @escaping () -> Void) -> some View {
        ExamplePrimaryButton(title: title, action: action)
    }

    private func outlinedRow(title: String, action: @escaping () -> Void) -> some View {
        ExampleOutlinedButton(title: title, action: action)
    }
}

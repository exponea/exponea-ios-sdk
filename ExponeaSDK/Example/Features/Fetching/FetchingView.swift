import SwiftUI

struct FetchingView: View {

    @EnvironmentObject private var sdkState: SdkState
    @ObservedObject var viewModel: FetchingViewModel
    @State private var showInboxList = false

    var body: some View {
        VStack(spacing: 8) {
            fetchSection
            resultSection
                .frame(maxHeight: .infinity, alignment: .top)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .exampleScreenBackground()
        .background(
            NavigationLink(
                destination: AppInboxListPage(),
                isActive: $showInboxList
            ) { EmptyView() }
            .hidden()
        )
        .sheet(isPresented: $viewModel.showRecommendationDialog) {
            FetchRecommendationDialog(
                savedRecommendationId: RecommendationPreferences.load()
            ) { recommendationId in
                viewModel.fetchRecommendations(recommendationId: recommendationId)
            }
        }
    }

    private var fetchSection: some View {
        ExampleSectionCard(title: "Fetch") {
            VStack(spacing: 8) {
                fetchButton(title: "Consents") {
                    viewModel.fetchConsents()
                }
                .accessibilityIdentifier(A11yID.fetching.fetchConsents)

                fetchButton(title: "Recommendations") {
                    viewModel.showRecommendationDialog = true
                }
                .accessibilityIdentifier(A11yID.fetching.fetchRecommendations)

                fetchButton(title: "Segments") {
                    viewModel.fetchSegments()
                }
                .accessibilityIdentifier(A11yID.fetching.fetchSegments)

                if sdkState.isIntegrated {
                    AppInboxButtonRepresentable {
                        showInboxList = true
                    }
                    .frame(height: 44)
                    .accessibilityIdentifier(A11yID.fetching.appInboxProvider)

                    fetchButton(title: "Open App Inbox") {
                        showInboxList = true
                    }
                    .accessibilityIdentifier(A11yID.fetching.openInbox)
                }
            }
        }
    }

    private var resultSection: some View {
        ExampleSectionCard(title: "Result") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Spacer()
                    Button {
                        viewModel.clearResult()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(BrandColors.grey600)
                    }
                    .accessibilityIdentifier(A11yID.fetching.clearResult)
                    .accessibilityLabel("Clear result")
                }

                Group {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(BrandColors.brBlack)
                    } else {
                        Color.clear
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 4, maxHeight: 4)
                .accessibilityIdentifier(A11yID.fetching.fetchLoading)

                ScrollView {
                    Text(viewModel.resultText)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(BrandColors.grey600)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier(A11yID.fetching.fetchResult)
                }
                .frame(minHeight: 120)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(BrandColors.grey300)
                )
            }
        }
    }

    private func fetchButton(title: String, action: @escaping () -> Void) -> some View {
        ExamplePrimaryButton(title: title, disabled: viewModel.isLoading, action: action)
    }
}

struct FetchRecommendationDialog: View {

    @Environment(\.dismiss) private var dismiss

    let savedRecommendationId: String
    let onFetch: (String) -> Void

    @State private var recommendationId = ""

    private var canSubmit: Bool {
        !recommendationId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Recommendation id", text: $recommendationId)
                    .exampleInputStyle()
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .accessibilityIdentifier(A11yID.fetching.recommendationId)

                Spacer()
            }
            .padding()
            .background(BrandColors.grey100)
            .navigationTitle("Fetch recommendation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier(A11yID.fetching.recommendationDialogCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fetch") { submit() }
                        .disabled(!canSubmit)
                        .accessibilityIdentifier(A11yID.fetching.recommendationDialogFetch)
                }
            }
            .onAppear {
                if recommendationId.isEmpty {
                    recommendationId = savedRecommendationId
                }
            }
        }
    }

    private func submit() {
        let id = recommendationId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else { return }
        RecommendationPreferences.save(id)
        dismiss()
        onFetch(id)
    }
}

struct AppInboxListPage: View {

    @Environment(\.dismiss) private var dismiss
    @State private var selectedMessageId: String?

    var body: some View {
        AppInboxListRepresentable { messageId in
            selectedMessageId = messageId
        }
        .navigationTitle("App inbox")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .accessibilityIdentifier(A11yID.appInbox.back)
                .accessibilityLabel("Back")
            }
            ToolbarItem(placement: .principal) {
                Text("App inbox")
                    .accessibilityIdentifier(A11yID.appInbox.title)
            }
        }
        .background(
            NavigationLink(
                destination: AppInboxDetailPage(messageId: selectedMessageId ?? ""),
                isActive: Binding(
                    get: { selectedMessageId != nil },
                    set: { if !$0 { selectedMessageId = nil } }
                )
            ) { EmptyView() }
            .hidden()
        )
    }
}

struct AppInboxDetailPage: View {

    @Environment(\.dismiss) private var dismiss
    let messageId: String

    var body: some View {
        AppInboxDetailRepresentable(messageId: messageId)
            .navigationTitle("App inbox message")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .accessibilityIdentifier(A11yID.appInbox.detailBack)
                    .accessibilityLabel("Back")
                }
                ToolbarItem(placement: .principal) {
                    Text("App inbox message")
                        .accessibilityIdentifier(A11yID.appInbox.detailTitle)
                }
            }
    }
}

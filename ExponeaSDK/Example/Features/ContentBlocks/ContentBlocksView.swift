import SwiftUI

struct ContentBlocksView: View {

    @ObservedObject var viewModel: ContentBlocksViewModel

    var body: some View {
        VStack(spacing: 8) {
            tabRow
            switch viewModel.selectedTab {
            case .classic:
                classicTab
            case .runtimeLab:
                // Only the selected tab is in the view tree, so selecting Basic discards the lab and its log.
                RuntimeControllerLabView()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .exampleScreenBackground()
    }

    private var tabRow: some View {
        HStack(spacing: 8) {
            tabButton(title: "Basic", tab: .classic, identifier: A11yID.contentBlocks.tabClassic)
            tabButton(title: "Runtime Control", tab: .runtimeLab, identifier: A11yID.contentBlocks.tabRuntimeLab)
        }
    }

    private func tabButton(title: String, tab: ContentBlocksTab, identifier: String) -> some View {
        Button(title) {
            viewModel.selectedTab = tab
        }
        .buttonStyle(ExampleSegmentTabButtonStyle(isSelected: viewModel.selectedTab == tab))
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier(identifier)
    }

    private var classicTab: some View {
        VStack(spacing: 8) {
            toggleCard
            ScrollView {
                if viewModel.showCarousels {
                    if viewModel.carouselsBuilt {
                        carouselsGroup
                    }
                } else {
                    placeholdersGroup
                }
            }
        }
    }

    private var toggleCard: some View {
        ExampleSectionCard(title: "Display mode") {
            HStack {
                Text("Show carousels")
                    .font(.subheadline)
                    .foregroundColor(BrandColors.brBlack)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { viewModel.showCarousels },
                    set: { viewModel.setShowCarousels($0) }
                ))
                .labelsHidden()
                .tint(BrandColors.switchTrack)
                .accessibilityIdentifier(A11yID.contentBlocks.toggleCarousels)
            }
        }
    }

    private var placeholdersGroup: some View {
        VStack(spacing: 8) {
            ExampleSectionCard(title: "Placeholder: example_top") {
                ContentBlockPlaceholderView(
                    placeholderId: ContentBlocksConstants.placeholderTop,
                    tracksWithoutConsent: true
                )
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier(A11yID.contentBlocks.placeholderTop)
            }

            ExampleSectionCard(title: "Placeholder: ph_x_example_iOS") {
                ContentBlockPlaceholderView(
                    placeholderId: ContentBlocksConstants.placeholderPlatform
                )
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier(A11yID.contentBlocks.placeholderPlatform)
            }

            ExampleSectionCard(title: "Inline placeholder: example_list (every 5th row)") {
                InlineContentBlockList()
                    .frame(height: ContentBlocksConstants.listHeight)
                    .accessibilityIdentifier(A11yID.contentBlocks.placeholderList)
            }
        }
    }

    private var carouselsGroup: some View {
        VStack(spacing: 8) {
            ExampleSectionCard(title: "Default carousel: example_carousel") {
                VStack(spacing: 6) {
                    DefaultCarouselContentBlockRepresentable(viewModel: viewModel)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 150)
                        .accessibilityIdentifier(A11yID.contentBlocks.carouselDefault)

                    ExampleStatusBox(
                        text: viewModel.carouselStatusText,
                        identifier: A11yID.contentBlocks.carouselStatus
                    )
                }
            }

            ExampleSectionCard(title: "Filtered carousel: example_carousel") {
                FilteredCarouselContentBlockRepresentable()
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 150)
                    .accessibilityIdentifier(A11yID.contentBlocks.carouselFiltered)
            }

            ExampleSectionCard(title: "iOS carousel: example_carousel_ios") {
                PlatformCarouselContentBlockRepresentable()
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 150)
                    .accessibilityIdentifier(A11yID.contentBlocks.carouselPlatform)
            }
        }
    }
}

import SwiftUI

/// Bottom navigation bar for the five feature tabs.
/// A custom bar (not `TabView`) so every item exposes its `btn_nav_*` id to XCUITest.
struct ExampleBottomNavigation: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                item(for: tab)
            }
        }
        .frame(height: 56)
        .background(
            BrandColors.white
                .shadow(color: BrandColors.brBlack.opacity(0.12), radius: 2, x: 0, y: -1)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func item(for tab: AppTab) -> some View {
        let isSelected = tab == selection
        return Button {
            if !isSelected { selection = tab }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 20))
                    .frame(width: 24, height: 24)
                Text(tab.title)
                    .font(.system(size: 12, weight: isSelected ? .bold : .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(isSelected ? BrandColors.brBlack : BrandColors.grey600)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(tab.accessibilityId)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

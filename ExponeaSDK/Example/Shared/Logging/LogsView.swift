import SwiftUI
import ExponeaSDK

// In-app logs viewer, presented as a sheet from the toolbar Logs button.
struct LogsView: View {

    @EnvironmentObject private var logStore: InAppLogStore
    @StateObject private var viewModel: LogsViewModel
    @Environment(\.dismiss) private var dismiss

    init() {
        _viewModel = StateObject(wrappedValue: LogsViewModel(store: InAppLogStore.shared))
    }

    var body: some View {
        VStack(spacing: 0) {
            ExampleSheetHeader(
                title: NSLocalizedString("logs.title", comment: ""),
                onClose: { dismiss() },
                closeAccessibilityId: A11yID.logs.close,
                trailing: {
                    Button {
                        viewModel.copyToClipboard()
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(BrandColors.white)
                    }
                    .accessibilityLabel("Copy logs")
                    .accessibilityIdentifier(A11yID.logs.copyButton)

                    Button {
                        viewModel.clear()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(BrandColors.white)
                    }
                    .accessibilityLabel("Clear logs")
                    .accessibilityIdentifier(A11yID.logs.clearButton)
                }
            )

            filterBar
            Divider()
                .overlay(BrandColors.grey300)
            logList
        }
        .background(BrandColors.grey100)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(viewModel.filters, id: \.accessibilityIdentifier) { filter in
                    filterChip(filter)
                }
            }
            .padding(8)
        }
        .background(BrandColors.white)
    }

    private func filterChip(_ filter: LogsFilter) -> some View {
        let isSelected = viewModel.selectedFilter == filter
        return Button {
            viewModel.selectedFilter = filter
        } label: {
            Text(filter.label)
        }
        .buttonStyle(ExampleChipButtonStyle(isSelected: isSelected))
        .accessibilityIdentifier(filter.accessibilityIdentifier)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var logList: some View {
        Group {
            if viewModel.entries.isEmpty {
                Text(NSLocalizedString("logs.empty", comment: ""))
                    .foregroundColor(BrandColors.grey300)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(BrandColors.white)
                    .accessibilityIdentifier(A11yID.logs.empty)
            } else {
                List(viewModel.entries) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            levelPill(for: entry.level)
                            Text(viewModel.formattedTime(for: entry))
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(BrandColors.grey600)
                        }
                        Text(entry.message)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(BrandColors.brBlack)
                    }
                    .listRowSeparatorTint(BrandColors.grey100)
                }
                .listStyle(.plain)
                .background(BrandColors.white)
                .accessibilityIdentifier(A11yID.logs.list)
            }
        }
    }

    private func levelPill(for level: LogLevel) -> some View {
        Text(viewModel.shortLabel(for: level))
            .font(.system(.caption2, design: .monospaced).bold())
            .foregroundColor(BrandColors.brBlack)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(levelBackground(for: level))
            )
            .overlay(Capsule().stroke(BrandColors.grey300))
    }

    private func levelBackground(for level: LogLevel) -> Color {
        switch level {
        case .error:   return BrandColors.logError
        case .warning: return BrandColors.logWarn
        default:       return BrandColors.logVerbose
        }
    }
}

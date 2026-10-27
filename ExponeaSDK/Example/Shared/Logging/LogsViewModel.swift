import Foundation
import UIKit
import ExponeaSDK

/// Log filters, also used by the automated tests. `debug` and `info` have no iOS `LogLevel`
/// counterpart, so those two filters never match an entry.
enum LogsFilter: CaseIterable {
    case all
    case verbose
    case debug
    case info
    case warn
    case error

    var label: String {
        switch self {
        case .all:     return NSLocalizedString("logs.filter.all", comment: "")
        case .verbose: return "V"
        case .debug:   return "D"
        case .info:    return "I"
        case .warn:    return "W"
        case .error:   return "E"
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .all:     return A11yID.logs.filterAll
        case .verbose: return A11yID.logs.filterVerbose
        case .debug:   return A11yID.logs.filterDebug
        case .info:    return A11yID.logs.filterInfo
        case .warn:    return A11yID.logs.filterWarn
        case .error:   return A11yID.logs.filterError
        }
    }

}

@MainActor
final class LogsViewModel: ObservableObject {

    @Published var selectedFilter: LogsFilter = .all

    private let store: InAppLogStore

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    init(store: InAppLogStore) {
        self.store = store
    }

    var entries: [LogEntry] {
        switch selectedFilter {
        case .all:          return store.visibleEntries(filter: nil)
        case .verbose:      return store.visibleEntries(filter: .verbose)
        case .warn:         return store.visibleEntries(filter: .warning)
        case .error:        return store.visibleEntries(filter: .error)
        case .debug, .info: return []
        }
    }

    var filters: [LogsFilter] { LogsFilter.allCases }

    func shortLabel(for level: LogLevel) -> String {
        switch level {
        case .error:   return "E"
        case .warning: return "W"
        case .verbose: return "V"
        default:       return "-"
        }
    }

    func formattedTime(for entry: LogEntry) -> String {
        LogsViewModel.timeFormatter.string(from: entry.timestamp)
    }

    func clear() {
        store.clear()
    }

    func copyToClipboard() {
        let text = entries
            .map { "\(shortLabel(for: $0.level)) \(formattedTime(for: $0)) \($0.message)" }
            .joined(separator: "\n")
        UIPasteboard.general.string = text
    }
}

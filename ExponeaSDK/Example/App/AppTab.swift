import Foundation
import ExponeaSDK

enum AppTab: String, CaseIterable, Identifiable {
    case fetching
    case tracking
    case flushing
    case anonymize
    case contentBlocks

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fetching:      return NSLocalizedString("tab.fetching", comment: "")
        case .tracking:      return NSLocalizedString("tab.tracking", comment: "")
        case .flushing:      return NSLocalizedString("tab.flushing", comment: "")
        case .anonymize:     return NSLocalizedString("tab.anonymize", comment: "")
        case .contentBlocks: return NSLocalizedString("tab.contentBlocks", comment: "")
        }
    }

    var systemImage: String {
        switch self {
        case .fetching:      return "arrow.down.circle"
        case .tracking:      return "target"
        case .flushing:      return "arrow.up.arrow.down.circle"
        case .anonymize:     return "person.slash"
        case .contentBlocks: return "rectangle.3.group"
        }
    }

    var accessibilityId: String {
        switch self {
        case .fetching:      return A11yID.shell.navFetching
        case .tracking:      return A11yID.shell.navTracking
        case .flushing:      return A11yID.shell.navFlushing
        case .anonymize:     return A11yID.shell.navAnonymize
        case .contentBlocks: return A11yID.shell.navContentBlocks
        }
    }

    var screenName: String { title }
}

func trackPageView(_ tab: AppTab) {
    ExponeaService.trackEvent(name: "page_view", properties: ["screen_name": tab.screenName])
}

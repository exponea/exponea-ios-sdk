import Foundation
import ExponeaSDK

/// What an incoming deeplink asks the example app to do.
enum DeeplinkAction: Equatable {
    case open(AppTab)
    case stopAndContinue
    case stopAndRestart

    /// The only web host whose links open screens in this app. Links to other sites (for example the
    /// GDPR consent buttons on bloomreach.com) are not app navigation.
    static let appLinkHost = "mobile-sdk-example-apps.web.app"

    /// Loose, case-insensitive substring match on host + path for `exponea://`, and on the path for
    /// `https://mobile-sdk-example-apps.web.app/...`. Stop flows are matched first.
    static func resolve(_ url: URL) -> DeeplinkAction? {
        let haystack: String
        switch url.scheme?.lowercased() {
        case "exponea":
            haystack = ((url.host ?? "") + url.path).lowercased()
        case "http", "https":
            guard url.host?.lowercased() == appLinkHost else { return nil }
            haystack = url.path.lowercased()
        default:
            return nil
        }
        if haystack.contains("stopandcontinue") { return .stopAndContinue }
        if haystack.contains("stopandrestart") { return .stopAndRestart }
        if haystack.contains("track") { return .open(.tracking) }
        if haystack.contains("flush") { return .open(.flushing) }
        if haystack.contains("fetch") { return .open(.fetching) }
        if haystack.contains("inappcb") { return .open(.contentBlocks) }
        if haystack.contains("anonymize") { return .open(.anonymize) }
        return nil
    }
}

/// Receives every incoming URL (cold and warm start, universal links and `exponea://`) and holds the
/// resolved action until the main shell can perform it. Only the latest link is kept, in memory only,
/// and it is handed out exactly once.
final class DeeplinkCenter: ObservableObject {

    /// Shared so that SDK callbacks outside the view tree (content block actions) can route links too.
    static let shared = DeeplinkCenter()

    @Published private(set) var pending: DeeplinkAction?

    func handle(_ url: URL) {
        InAppLogStore.shared.append(level: .verbose, message: "Deeplink received: \(url.absoluteString)")
        // Only universal links carry campaign data. The SDK tracks a campaign click when the link has
        // xnpe_cmp, and adds the link to the next session_start either way.
        if let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" {
            Exponea.shared.trackCampaignClick(url: url, timestamp: nil)
        }
        pending = DeeplinkAction.resolve(url)
    }

    func consume() -> DeeplinkAction? {
        defer { pending = nil }
        return pending
    }
}

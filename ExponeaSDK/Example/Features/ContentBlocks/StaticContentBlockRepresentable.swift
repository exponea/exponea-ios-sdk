import SwiftUI
import SafariServices
import ExponeaSDK

struct StaticContentBlockRepresentable: UIViewRepresentable {

    let placeholderId: String
    var tracksWithoutConsent = false
    var onHeightChange: ((CGFloat) -> Void)?
    var onEvent: ((String) -> Void)?

    func makeUIView(context: Context) -> StaticInAppContentBlockView {
        let view = StaticInAppContentBlockView(placeholder: placeholderId, deferredLoad: true)
        var callback = view.behaviourCallback
        if tracksWithoutConsent {
            callback = ConsentIgnoringContentBlockCallback(wrapped: callback)
        }
        if let onEvent {
            callback = EventReportingContentBlockCallback(wrapped: callback, onEvent: onEvent)
        }
        view.behaviourCallback = callback
        view.heightCompletion = { height in
            DispatchQueue.main.async {
                onHeightChange?(CGFloat(height))
            }
        }
        // deferredLoad defers the fetch until an explicit reload(), which runs once the view is set up.
        DispatchQueue.main.async {
            view.reload()
        }
        return view
    }

    func updateUIView(_ uiView: StaticInAppContentBlockView, context: Context) {}
}

/// Self-sizing placeholder; collapses to zero height when no content block is served.
struct ContentBlockPlaceholderView: View {

    let placeholderId: String
    var tracksWithoutConsent = false
    var onEvent: ((String) -> Void)?

    @State private var height: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Height: \(Int(height))px")
                .font(.caption)
                .foregroundColor(BrandColors.grey600)
                .accessibilityIdentifier(A11yID.contentBlocks.placeholderHeight(placeholderId))

            StaticContentBlockRepresentable(
                placeholderId: placeholderId,
                tracksWithoutConsent: tracksWithoutConsent,
                onHeightChange: { newHeight in height = newHeight },
                onEvent: onEvent
            )
            .frame(height: height)
        }
    }
}

/// Reports shown / no message / error to `onEvent` and keeps the SDK default behaviour (tracking, actions).
private struct EventReportingContentBlockCallback: InAppContentBlockCallbackType {
    let wrapped: InAppContentBlockCallbackType
    let onEvent: (String) -> Void

    func onMessageShown(placeholderId: String, contentBlock: InAppContentBlockResponse) {
        wrapped.onMessageShown(placeholderId: placeholderId, contentBlock: contentBlock)
        report("shown")
    }

    func onNoMessageFound(placeholderId: String) {
        wrapped.onNoMessageFound(placeholderId: placeholderId)
        report("no message found")
    }

    func onError(placeholderId: String, contentBlock: InAppContentBlockResponse?, errorMessage: String) {
        wrapped.onError(placeholderId: placeholderId, contentBlock: contentBlock, errorMessage: errorMessage)
        report("error \(errorMessage)")
    }

    func onCloseClicked(placeholderId: String, contentBlock: InAppContentBlockResponse) {
        wrapped.onCloseClicked(placeholderId: placeholderId, contentBlock: contentBlock)
    }

    func onActionClicked(placeholderId: String, contentBlock: InAppContentBlockResponse, action: InAppContentBlockAction) {
        wrapped.onActionClicked(placeholderId: placeholderId, contentBlock: contentBlock, action: action)
    }

    func onActionClickedSafari(
        placeholderId: String,
        contentBlock: InAppContentBlockResponse,
        action: InAppContentBlockAction
    ) {
        wrapped.onActionClickedSafari(placeholderId: placeholderId, contentBlock: contentBlock, action: action)
    }

    private func report(_ event: String) {
        DispatchQueue.main.async { onEvent(event) }
    }
}

/// Tracks content block interactions with the `*WithoutTrackingConsent` methods (so they are tracked even
/// without the customer's tracking consent) and opens action links itself instead of leaving it to the SDK.
/// Showing a content block still goes through the SDK's default callback.
private struct ConsentIgnoringContentBlockCallback: InAppContentBlockCallbackType {
    let wrapped: InAppContentBlockCallbackType

    func onMessageShown(placeholderId: String, contentBlock: InAppContentBlockResponse) {
        wrapped.onMessageShown(placeholderId: placeholderId, contentBlock: contentBlock)
    }

    func onNoMessageFound(placeholderId: String) {
        wrapped.onNoMessageFound(placeholderId: placeholderId)
    }

    func onError(placeholderId: String, contentBlock: InAppContentBlockResponse?, errorMessage: String) {
        guard let contentBlock else { return }
        Exponea.shared.trackInAppContentBlockErrorWithoutTrackingConsent(
            placeholderId: placeholderId,
            message: contentBlock,
            errorMessage: errorMessage
        )
    }

    func onCloseClicked(placeholderId: String, contentBlock: InAppContentBlockResponse) {
        Exponea.shared.trackInAppContentBlockCloseWithoutTrackingConsent(
            placeholderId: placeholderId,
            message: contentBlock
        )
    }

    func onActionClicked(placeholderId: String, contentBlock: InAppContentBlockResponse, action: InAppContentBlockAction) {
        handleAction(placeholderId: placeholderId, contentBlock: contentBlock, action: action, inAppBrowser: false)
    }

    func onActionClickedSafari(
        placeholderId: String,
        contentBlock: InAppContentBlockResponse,
        action: InAppContentBlockAction
    ) {
        handleAction(placeholderId: placeholderId, contentBlock: contentBlock, action: action, inAppBrowser: true)
    }

    private func handleAction(
        placeholderId: String,
        contentBlock: InAppContentBlockResponse,
        action: InAppContentBlockAction,
        inAppBrowser: Bool
    ) {
        // A close action is tracked through onCloseClicked.
        guard action.type != .close else { return }
        Exponea.shared.trackInAppContentBlockClickWithoutTrackingConsent(
            placeholderId: placeholderId,
            action: action,
            message: contentBlock
        )
        guard let url = action.url.flatMap({ URL(string: $0.trimmingCharacters(in: .whitespacesAndNewlines)) }) else {
            InAppLogStore.shared.append(level: .warning, message: "Content block action has no valid URL")
            return
        }
        DispatchQueue.main.async {
            switch action.type {
            // SFSafariViewController only accepts http(s) URLs.
            case .browser where inAppBrowser && Self.isWebLink(url):
                Self.topViewController()?.present(SFSafariViewController(url: url), animated: true)
            case .deeplink where Self.isAppLink(url):
                DeeplinkCenter.shared.handle(url)
            default:
                UIApplication.shared.open(url)
            }
        }
    }

    /// Links this app handles itself: the `exponea` scheme and universal links on the app link host.
    /// Other links open outside the app.
    private static func isAppLink(_ url: URL) -> Bool {
        switch url.scheme?.lowercased() {
        case "exponea":
            return true
        case "http", "https":
            return url.host?.lowercased() == DeeplinkAction.appLinkHost
        default:
            return false
        }
    }

    private static func isWebLink(_ url: URL) -> Bool {
        ["http", "https"].contains(url.scheme?.lowercased() ?? "")
    }

    private static func topViewController() -> UIViewController? {
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
        var top = keyWindow?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}

import Foundation
import UIKit
import WebKit

final class InAppMessageWebView: UIView, InAppMessageView {
    private let payload: String
    let actionCallback: ((InAppMessagePayloadButton) -> Void)
    let dismissCallback: TypeBlock<Bool>

    var webView: WKWebView!

    var normalizedPayload: NormalizedResult?
    
    var actionManager: WebActionManager?

    required init(
        payload: String,
        actionCallback: @escaping ((InAppMessagePayloadButton) -> Void),
        dismissCallback: @escaping TypeBlock<Bool>
    ) {
        self.payload = payload
        self.actionCallback = actionCallback
        self.dismissCallback = dismissCallback
        super.init(frame: UIScreen.main.bounds)
        actionManager = WebActionManager(
            onCloseCallback: { [weak self] in
                guard let self = self else {
                    return
                }
                self.dismissCallback(false)
                self.dismiss(isUserInteraction: true)
            },
            onActionCallback: { [weak self] action in
                guard let self = self else {
                    return
                }
                self.actionCallback(self.toPayloadButton(action))
                self.dismiss(isUserInteraction: true)
            }
        )
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    func present(in viewController: UIViewController, window: UIWindow?) throws {
        guard let window = window else {
            throw InAppMessagePresenter.InAppMessagePresenterError.unableToPresentView
        }
        window.addSubview(self)
        if #available(iOS 11.0, *) {
            topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor).isActive = true
        } else {
            topAnchor.constraint(equalTo: window.topAnchor).isActive = true
        }
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 10),
            trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -10)
        ])
    }

    func dismiss(isUserInteraction: Bool) {
        guard superview != nil else {
            return
        }
        self.removeFromSuperview()
        self.dismissCallback(isUserInteraction)
    }

    func actionButtonAction(_ sender: InAppMessageActionButton) {
        guard let payload = sender.payload else {
            return
        }
        removeFromSuperview()
        actionCallback(payload)
    }

    func cancelButtonAction(_ sender: Any) {
        self.removeFromSuperview()
        self.dismissCallback(true)
    }

    func setup() {
        webView = WKWebView(frame: UIScreen.main.bounds, configuration: buildAntiXssSetup())
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        webView.scrollView.backgroundColor = UIColor.clear
        webView.navigationDelegate = actionManager
        addSubview(webView)

        DispatchQueue.global(qos: .background).async {
            self.normalizedPayload = HtmlNormalizer(self.payload).normalize()
            if self.normalizedPayload!.valid {
                self.actionManager?.htmlPayload = self.normalizedPayload
                DispatchQueue.main.async {
                    self.webView.loadHTMLString(self.normalizedPayload!.html!, baseURL: nil)
                }
            } else {
                self.dismiss(isUserInteraction: false)
            }
        }
    }

    private func buildAntiXssSetup() -> WKWebViewConfiguration {
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = false
        preferences.javaScriptEnabled = false
        #if compiler(>=5.6)
        if #available(iOS 15.4, *) {
            preferences.isElementFullscreenEnabled = false
        }
        #endif
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        configuration.allowsAirPlayForMediaPlayback = false
        configuration.allowsInlineMediaPlayback = false
        configuration.allowsPictureInPictureMediaPlayback = false
        if #available(iOS 14.0, *) {
            let webPagePreferences = WKWebpagePreferences()
            webPagePreferences.allowsContentJavaScript = false
            configuration.defaultWebpagePreferences = webPagePreferences
        }
        return configuration
    }

    private func toPayloadButton(_ action: ActionInfo) -> InAppMessagePayloadButton {
        InAppMessagePayloadButton(
                buttonText: action.buttonText,
                rawButtonType: detectActionType(URL(string: action.actionUrl)!).rawValue,
                buttonLink: action.actionUrl,
                buttonTextColor: nil,
                buttonBackgroundColor: nil
        )
    }

    private func detectActionType(_ url: URL) -> InAppMessageButtonType {
        if url.scheme == "http" || url.scheme == "https" {
            return .browser
        }
        return .deeplink
    }
}

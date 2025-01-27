import Foundation
import UIKit
import WebKit

final class InAppMessageWebView: UIView, InAppMessageView {
    private let payload: String
    let actionCallback: ((InAppMessagePayloadButton) -> Void)
    let dismissCallback: (Bool, InAppMessagePayloadButton?) -> Void

    var webView: WKWebView!
    private var inAppContentBlocksManager: InAppContentBlocksManagerType = InAppContentBlocksManager.manager

    var normalizedPayload: NormalizedResult?

    var actionManager: WebActionManager?
    
    var isPresented: Bool {
        return superview != nil
    }

    required init(
        payload: String,
        actionCallback: @escaping ((InAppMessagePayloadButton) -> Void),
        dismissCallback: @escaping (Bool, InAppMessagePayloadButton?) -> Void
    ) {
        self.payload = payload
        self.actionCallback = actionCallback
        self.dismissCallback = dismissCallback
        super.init(frame: UIScreen.main.bounds)
        actionManager = WebActionManager(
            onCloseCallback: { [weak self] cancelButtonInfo in
                guard let self = self else {
                    return
                }
                let cancelButtonPayload = InAppMessagePayloadButton(
                    buttonText: cancelButtonInfo?.buttonText,
                    rawButtonType: "cancel",
                    buttonLink: cancelButtonInfo?.actionUrl,
                    buttonTextColor: nil,
                    buttonBackgroundColor: nil
                )
                self.dismiss(isUserInteraction: true, cancelButton: cancelButtonPayload)
            },
            onActionCallback: { [weak self] action in
                guard let self = self else {
                    return
                }
                self.dismiss(actionButton: self.toPayloadButton(action))
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

    func dismiss(isUserInteraction: Bool, cancelButton: InAppMessagePayloadButton?) {
        onMain {
            self.dismissCallback(isUserInteraction, cancelButton)
            self.dismissFromSuperView()
        }
    }

    func dismiss(actionButton: InAppMessagePayloadButton) {
        onMain {
            self.actionCallback(actionButton)
            self.dismissFromSuperView()
        }
    }

    func dismissFromSuperView() {
        DispatchQueue.main.async { [weak self] in
            guard let self, superview != nil else {
                return
            }
            removeFromSuperview()
        }
    }

    func actionButtonAction(_ sender: InAppMessageActionButton) {
        guard let payload = sender.payload else {
            return
        }
        dismiss(actionButton: payload)
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
            onMain {
                if self.normalizedPayload!.valid {
                    self.actionManager?.htmlPayload = self.normalizedPayload
                    self.webView.loadHTMLString(self.normalizedPayload!.html!, baseURL: nil)
                } else {
                    self.dismiss(isUserInteraction: false, cancelButton: nil)
                }
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
        if let contentRuleList = inAppContentBlocksManager.contentRuleList {
            configuration.userContentController.add(contentRuleList)
        }
        return configuration
    }

    private func toPayloadButton(_ action: ActionInfo) -> InAppMessagePayloadButton {
        InAppMessagePayloadButton(
                buttonText: action.buttonText,
                rawButtonType: detectActionType(action).rawValue,
                buttonLink: action.actionUrl,
                buttonTextColor: nil,
                buttonBackgroundColor: nil
        )
    }

    private func detectActionType(_ action: ActionInfo) -> InAppMessageButtonType {
        switch action.actionType {
        case .browser:
            return .browser
        case .deeplink:
            return .deeplink
        case .close:
            return .cancel
        }
    }
}

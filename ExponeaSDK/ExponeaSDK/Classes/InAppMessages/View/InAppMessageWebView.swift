import Foundation
import UIKit
import WebKit

final class InAppMessageWebView: UIView, InAppMessageView, WKNavigationDelegate {
    private let payload: String
    let actionCallback: ((InAppMessagePayloadButton) -> Void)
    let dismissCallback: (() -> Void)

    var webView: WKWebView!

    var normalizedPayload: NormalizedResult?

    init(
        payload: String,
        actionCallback: @escaping ((InAppMessagePayloadButton) -> Void),
        dismissCallback: @escaping (() -> Void)
    ) {
        self.payload = payload
        self.actionCallback = actionCallback
        self.dismissCallback = dismissCallback
        super.init(frame: UIScreen.main.bounds)
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

    func dismiss() {
        guard superview != nil else {
            return
        }
        self.removeFromSuperview()
        self.dismissCallback()
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
        self.dismissCallback()
    }

    func setup() {
        webView = WKWebView(frame: UIScreen.main.bounds, configuration: buildAntiXssSetup())
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        webView.scrollView.backgroundColor = UIColor.clear
        webView.navigationDelegate = self
        addSubview(webView)

        DispatchQueue.global(qos: .background).async {
            self.normalizedPayload = HtmlNormalizer(self.payload).normalize()
            if (self.normalizedPayload!.valid) {
                DispatchQueue.main.async {
                    self.webView.loadHTMLString(self.normalizedPayload!.html!, baseURL: nil)
                }
            } else {
                self.dismiss()
            }
        }
    }

    private func buildAntiXssSetup() -> WKWebViewConfiguration {
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = false
        preferences.javaScriptEnabled = false

        #if swift(>=5.7)
        if #available(iOS 15.4, *) {
            preferences.isElementFullscreenEnabled = false
        }
        #else
        if #available(iOS 15.0, *) {
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

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> ()) {
        let handled = handleActionClick(navigationAction.request.url)
        if (handled) {
            Exponea.logger.log(.verbose, message: "[HTML] Action \(navigationAction.request.url?.absoluteString ?? "Invalid") has been handled")
            decisionHandler(.cancel)
        } else {
            Exponea.logger.log(.verbose, message: "[HTML] Action \(navigationAction.request.url?.absoluteString ?? "Invalid") has not been handled, continue")
            decisionHandler(.allow)
        }
    }

    private func handleActionClick(_ url: URL?) -> Bool {
        Exponea.logger.log(.verbose, message: "[HTML] action for \(String(describing: url))")
        if (isCloseAction(url)) {
            dismissCallback()
            dismiss()
            return true
        } else if (isActionUrl(url)) {
            actionCallback(toPayloadButton(url!))
            UIApplication.shared.open(url!, options: [:], completionHandler: nil)
            dismiss()
            return true
        } else if (isBlankNav(url)) {
            // on first load
            // nothing to do, not need to continue loading
            return false
        } else {
            Exponea.logger.log(.warning, message: "[HTML] Unknown action URL: \(String(describing: url))")
            return false
        }
    }

    private func isBlankNav(_ url: URL?) -> Bool {
        url?.absoluteString == "about:blank"
    }

    private func isActionUrl(_ url: URL?) -> Bool {
        !isCloseAction(url) && url?.absoluteString.starts(with: "http") ?? false
    }
    
    private func isCloseAction(_ url: URL?) -> Bool {
        url?.absoluteString == normalizedPayload!.closeActionUrl
    }

    private func toPayloadButton(_ url: URL) -> InAppMessagePayloadButton {
        InAppMessagePayloadButton(
                buttonText: findActionByUrl(url)?.buttonText ?? "Unknown",
                rawButtonType: "deep-link",
                buttonLink: url.absoluteString,
                buttonTextColor: nil,
                buttonBackgroundColor: nil
        )
    }

    private func findActionByUrl(_ url: URL) -> ActionInfo? {
        for each in self.normalizedPayload!.actions {
            if (areEqualAsURLs(each.actionUrl, url.absoluteString)) {
                return each
            }
        }
        return nil
    }

    /**
     Put URL().absoluteString here.
     WKWebView is returning a slash at the end of URL, so we need to compare it properly
     */
    private func areEqualAsURLs(_ urlPath1: String, _ urlPath2: String) -> Bool {
        let url1 = URL(string: urlPath1)
        let scheme1 = url1?.scheme
        let host1 = url1?.host
        let path1 = url1?.path == "/" ? "" : url1?.path
        let query1 = url1?.query
        let url2 = URL(string: urlPath2)
        let scheme2 = url2?.scheme
        let host2 = url2?.host
        let path2 = url2?.path == "/" ? "" : url2?.path
        let query2 = url2?.query
        return (
                scheme1 == scheme2
                && host1 == host2
                && path1 == path2
                && query1 == query2
        )
    }
}

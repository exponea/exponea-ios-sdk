//
//  WKWebViewHeightCalculator.swift
//  ExponeaSDK
//
//  Created by Ankmara on 07.07.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation
import WebKit
import UIKit

public final class WKWebViewHeightCalculator: WKWebView, WKNavigationDelegate {

    // MARK: - Properties
    var defaultPadding: CGFloat = 20
    var heightUpdate: TypeBlock<CalculatorData>?
    var height: CGFloat?
    var id: String = ""

    public init() {
        super.init(frame: .init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 0), configuration: .init())
        navigationDelegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.heightUpdate?(.init(height: webView.scrollView.contentSize.height + self.defaultPadding, placeholderId: self.id))
        }
        decisionHandler(.allow)
    }
}

public extension WKWebViewHeightCalculator {
    func loadHtml(placedholderId: String, html: String) {
        onMain {
            guard !html.isEmpty else {
                self.heightUpdate?(.init(height: 0, placeholderId: placedholderId))
                return
            }
            self.id = placedholderId
            self.loadHTMLString(html, baseURL: nil)
        }
    }
}

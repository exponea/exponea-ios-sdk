//
//  MockUrlOpener.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 10/01/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation
@testable import ExponeaSDK

final class MockUrlOpener: UrlOpenerType {
    var openedBrowserLinks: [String] = []
    var openedDeeplinks: [String] = []

    func openBrowserLink(_ urlString: String) {
        openedBrowserLinks.append(urlString)
    }

    func openDeeplink(_ urlString: String) {
        openedDeeplinks.append(urlString)
    }
}

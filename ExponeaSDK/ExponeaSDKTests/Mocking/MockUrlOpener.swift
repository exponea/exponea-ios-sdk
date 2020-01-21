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
    var openedBrowserLinks: [URL] = []
    var openedDeeplinks: [URL] = []

    func openBrowserLink(_ url: URL) {
        openedBrowserLinks.append(url)
    }

    func openDeeplink(_ url: URL) {
        openedDeeplinks.append(url)
    }
}

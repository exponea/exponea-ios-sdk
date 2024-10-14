//
//  AppInboxProviderSpec.swift
//  ExponeaSDKTests
//
//  Created by Adam Mihalik on 22/12/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class AppInboxProviderSpec: QuickSpec {

    let configuration = try! Configuration(
        projectToken: "token",
        authorization: Authorization.none,
        baseUrl: "baseUrl"
    )

    override func spec() {
        var appInboxProvider: AppInboxProvider!
        beforeEach {
            appInboxProvider = DefaultAppInboxProvider()
        }
        it("should show empty view for missing message") {
            let viewController = appInboxProvider.getAppInboxDetailViewController("unknownId") as? AppInboxDetailViewController
            guard let viewController = viewController else {
                XCTFail("View controller is not AppInboxDetailViewController")
                return
            }
            // viewController.withData(nil)
            viewController.loadViewIfNeeded()
            expect(viewController.pushContainer.isHidden).to(beTrue())
            expect(viewController.htmlContainer.isHidden).to(beTrue())
        }
        it("should show empty view for unknown type") {
            let now = Date().timeIntervalSince1970.doubleValue
            let message = AppInboxCacheSpec.getSampleMessage(id: "id3", received: now - 20, type: "whatSoEver")
            let viewController = appInboxProvider.getAppInboxDetailViewController("id3") as? AppInboxDetailViewController
            guard let viewController = viewController else {
                XCTFail("View controller is not AppInboxDetailViewController")
                return
            }
            viewController.withData(message)
            expect(viewController.pushContainer.isHidden).to(beTrue())
            expect(viewController.htmlContainer.isHidden).to(beTrue())
        }
        it("should show push view") {
            let now = Date().timeIntervalSince1970.doubleValue
            let message = AppInboxCacheSpec.getSampleMessage(id: "id1", received: now - 20, type: "push")
            let viewController = appInboxProvider.getAppInboxDetailViewController("id1") as? AppInboxDetailViewController
            guard let viewController = viewController else {
                XCTFail("View controller is not AppInboxDetailViewController")
                return
            }
            viewController.withData(message)
            expect(viewController.pushContainer.isHidden).to(beFalse())
            expect(viewController.htmlContainer.isHidden).to(beTrue())
        }
        it("should show html view") {
            let now = Date().timeIntervalSince1970.doubleValue
            let message = AppInboxCacheSpec.getSampleMessage(
                id: "id1",
                read: true,
                received: now - 20,
                type: "html",
                data: [
                    "title": .string("Title"),
                    "pre_header": .string("Message"),
                    "message": .string(AppInboxManagerSpec.htmlAppInboxMessageContent)
                ]
            )
            let viewController = appInboxProvider.getAppInboxDetailViewController("id1") as? AppInboxDetailViewController
            guard let viewController = viewController else {
                XCTFail("View controller is not AppInboxDetailViewController")
                return
            }
            viewController.withData(message)
            expect(viewController.pushContainer.isHidden).to(beTrue())
            expect(viewController.htmlContainer.isHidden).to(beFalse())
        }
        it("should trigger onItemClick override") {
            let now = Date().timeIntervalSince1970.doubleValue
            let message = AppInboxCacheSpec.getSampleMessage(
                id: "id1",
                read: true,
                received: now - 20,
                type: "html",
                data: [
                    "title": .string("Title"),
                    "pre_header": .string("Message"),
                    "message": .string(AppInboxManagerSpec.htmlAppInboxMessageContent)
                ]
            )
            var overrideCalled = false
            let onItemClickOverride = { (_: MessageItem, _: Int) in
                overrideCalled = true
            }
            let viewController = appInboxProvider.getAppInboxListViewController() as? AppInboxListViewController
            guard let viewController = viewController else {
                XCTFail("View controller is not AppInboxListViewController")
                return
            }
            viewController.onItemClickedOverride = onItemClickOverride
            viewController.withData([message])
            viewController.loadViewIfNeeded()
            let tableView = viewController.tableView
            let indexPath = IndexPath(row: 0, section: 0)
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .middle)
            tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
            expect(overrideCalled).to(beTrue())
        }
    }
}

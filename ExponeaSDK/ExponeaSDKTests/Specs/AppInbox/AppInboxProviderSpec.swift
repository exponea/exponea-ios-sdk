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
import UIKit

@testable import ExponeaSDK
@testable import ExponeaSDKShared

class AppInboxProviderSpec: QuickSpec {

    override func spec() {
        var appInboxProvider: AppInboxProvider!
        beforeEach {
            IntegrationManager.shared.isStopped = false
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

        describe("app inbox button visibility") {
            var defaultProvider: DefaultAppInboxProvider!

            beforeEach {
                IntegrationManager.shared.isStopped = false
                IntegrationManager.shared.onIntegrationStoppedCallbacks.removeAll()
                defaultProvider = DefaultAppInboxProvider()
            }

            it("hides the cached button when integration stops") {
                let button = defaultProvider.getAppInboxButton()
                expect(button.isHidden).to(beFalse())

                IntegrationManager.shared.isStopped = true
                IntegrationManager.shared.onIntegrationStoppedCallbacks.forEach { $0() }

                expect(button.isHidden).toEventually(beTrue(), timeout: .seconds(2))
                expect(button.isAccessibilityElement).toEventually(beFalse(), timeout: .seconds(2))
            }

            it("restores button visibility when integration is active again") {
                let button = defaultProvider.getAppInboxButton()

                IntegrationManager.shared.isStopped = true
                IntegrationManager.shared.onIntegrationStoppedCallbacks.forEach { $0() }
                expect(button.isHidden).toEventually(beTrue(), timeout: .seconds(2))

                IntegrationManager.shared.isStopped = false
                let restoredButton = defaultProvider.getAppInboxButton()

                expect(restoredButton).to(beIdenticalTo(button))
                expect(restoredButton.isHidden).to(beFalse())
                expect(restoredButton.isAccessibilityElement).to(beTrue())
            }

            it("does not unhide the button while integration is stopped") {
                let button = defaultProvider.getAppInboxButton()

                IntegrationManager.shared.isStopped = true
                IntegrationManager.shared.onIntegrationStoppedCallbacks.forEach { $0() }
                expect(button.isHidden).toEventually(beTrue(), timeout: .seconds(2))

                let stoppedButton = defaultProvider.getAppInboxButton()

                expect(stoppedButton).to(beIdenticalTo(button))
                expect(stoppedButton.isHidden).to(beTrue())
                expect(stoppedButton.isAccessibilityElement).to(beFalse())
            }

            it("hides the cached button on a second stop after reinit") {
                let button = defaultProvider.getAppInboxButton()
                expect(button.isHidden).to(beFalse())

                // First stop cycle
                IntegrationManager.shared.isStopped = true
                IntegrationManager.shared.onIntegrationStoppedCallbacks.forEach { $0() }
                IntegrationManager.shared.onIntegrationStoppedCallbacks.removeAll()
                expect(button.isHidden).toEventually(beTrue(), timeout: .seconds(2))

                // Reinit: SDK becomes active again, host re-fetches the button
                IntegrationManager.shared.isStopped = false
                let restoredButton = defaultProvider.getAppInboxButton()
                expect(restoredButton.isHidden).to(beFalse())

                // Second stop cycle — callback must have been re-registered
                IntegrationManager.shared.isStopped = true
                IntegrationManager.shared.onIntegrationStoppedCallbacks.forEach { $0() }
                IntegrationManager.shared.onIntegrationStoppedCallbacks.removeAll()

                expect(button.isHidden).toEventually(beTrue(), timeout: .seconds(2))
                expect(button.isAccessibilityElement).toEventually(beFalse(), timeout: .seconds(2))
            }

            it("does not apply a stale stop hide after reinit before onMain drains") {
                let button = defaultProvider.getAppInboxButton()
                expect(button.isHidden).to(beFalse())

                // Simulate clearUserData firing stop callbacks off the main thread so
                // the provider's onMain hide is queued asynchronously.
                IntegrationManager.shared.isStopped = true
                let stopScheduled = DispatchGroup()
                stopScheduled.enter()
                DispatchQueue.global().async {
                    IntegrationManager.shared.onIntegrationStoppedCallbacks.forEach { $0() }
                    IntegrationManager.shared.onIntegrationStoppedCallbacks.removeAll()
                    stopScheduled.leave()
                }
                stopScheduled.wait()

                // Reinit + restore on main before the pending hide block runs.
                IntegrationManager.shared.isStopped = false
                let restoredButton = defaultProvider.getAppInboxButton()
                expect(restoredButton).to(beIdenticalTo(button))
                expect(restoredButton.isHidden).to(beFalse())

                // Let the stale onMain block drain; button must stay visible.
                expect(button.isHidden).toEventually(beFalse(), timeout: .seconds(2))
                expect(button.isAccessibilityElement).toEventually(beTrue(), timeout: .seconds(2))
            }
        }

        describe("via stopIntegration()") {
            var exponea: ExponeaInternal!
            var repository: MockRepository!
            var configuration: Configuration!

            func wireRunningSDK(on target: ExponeaInternal) {
                configuration = try! Configuration(
                    integrationConfig: Exponea.StreamSettings(
                        streamId: UUID().uuidString,
                        baseUrl: "https://google.com"
                    ),
                    appGroup: "test-group"
                )
                configuration.automaticSessionTracking = false

                repository = MockRepository(configuration: configuration)
                repository.trackObjectResult = .success

                let database = try! MockDatabaseManager()
                let userDefaults = MockUserDefaults()
                let flushingManager = try! FlushingManager(
                    database: database,
                    repository: repository,
                    customerIdentifiedHandler: {}
                )
                flushingManager.flushingMode = .manual

                let trackingManager = try! TrackingManager(
                    repository: repository,
                    database: database,
                    flushingManager: flushingManager,
                    inAppMessageManager: nil,
                    trackManagerInitializator: { _ in },
                    userDefaults: userDefaults,
                    campaignRepository: CampaignRepository(userDefaults: userDefaults),
                    requirePushAuthorization: false,
                    onEventCallback: { _, _ in }
                )

                target.repository = repository
                target.trackingManager = trackingManager
                target.flushingManager = flushingManager
            }

            beforeEach {
                IntegrationManager.shared.isStopped = false
                IntegrationManager.shared.onIntegrationStoppedCallbacks.removeAll()
                exponea = ExponeaInternal()
                Exponea.shared = exponea
                wireRunningSDK(on: exponea)
            }

            afterEach {
                IntegrationManager.shared.isStopped = false
                IntegrationManager.shared.onIntegrationStoppedCallbacks.removeAll()
            }

            it("hides the cached button when stopIntegration completes") {
                let button = exponea.getAppInboxButton()
                expect(button.isHidden).to(beFalse())

                waitUntil(timeout: .seconds(5)) { done in
                    exponea.stopIntegration { done() }
                }

                expect(IntegrationManager.shared.isStopped).to(beTrue())
                expect(button.isHidden).toEventually(beTrue(), timeout: .seconds(2))
                expect(button.isAccessibilityElement).toEventually(beFalse(), timeout: .seconds(2))
            }

            it("hides the cached button on a second stopIntegration after reinit") {
                let button = exponea.getAppInboxButton()
                expect(button.isHidden).to(beFalse())

                waitUntil(timeout: .seconds(5)) { done in
                    exponea.stopIntegration { done() }
                }
                expect(button.isHidden).toEventually(beTrue(), timeout: .seconds(2))

                wireRunningSDK(on: exponea)
                IntegrationManager.shared.isStopped = false

                let restoredButton = exponea.getAppInboxButton()
                expect(restoredButton).to(beIdenticalTo(button))
                expect(restoredButton.isHidden).to(beFalse())
                expect(restoredButton.isAccessibilityElement).to(beTrue())

                waitUntil(timeout: .seconds(5)) { done in
                    exponea.stopIntegration { done() }
                }

                expect(IntegrationManager.shared.isStopped).to(beTrue())
                expect(button.isHidden).toEventually(beTrue(), timeout: .seconds(2))
                expect(button.isAccessibilityElement).toEventually(beFalse(), timeout: .seconds(2))
            }

            it("returns a separate hidden placeholder from getAppInboxButton while stopped") {
                let button = exponea.getAppInboxButton()
                expect(button.isHidden).to(beFalse())

                waitUntil(timeout: .seconds(5)) { done in
                    exponea.stopIntegration { done() }
                }

                expect(button.isHidden).toEventually(beTrue(), timeout: .seconds(2))

                let stoppedButton = exponea.getAppInboxButton()
                expect(stoppedButton).toNot(beIdenticalTo(button))
                expect(stoppedButton.isHidden).to(beTrue())
            }
        }
    }
}

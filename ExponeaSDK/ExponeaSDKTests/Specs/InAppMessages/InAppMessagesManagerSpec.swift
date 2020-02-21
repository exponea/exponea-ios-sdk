//
//  InAppMessagesManagerSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 05/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//
import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class InAppMessagesManagerSpec: QuickSpec {
    let configuration = try! Configuration(
        projectToken: "token",
        authorization: Authorization.none,
        baseUrl: "baseUrl"
    )

    override func spec() {
        var cache: MockInAppMessagesCache!
        var repository: MockRepository!
        var manager: InAppMessagesManager!
        var presenter: MockInAppMessageDialogPresenter!
        var displayStore: InAppMessageDisplayStatusStore!

        beforeEach {
            cache = MockInAppMessagesCache()
            repository = MockRepository(configuration: self.configuration)
            repository.fetchInAppMessagesResult = Result.success(
                InAppMessagesResponse(success: true, data: [SampleInAppMessage.getSampleInAppMessage()])
            )
            presenter = MockInAppMessageDialogPresenter()
            displayStore = InAppMessageDisplayStatusStore(userDefaults: MockUserDefaults())
            manager = InAppMessagesManager(
                repository: repository,
                cache: cache,
                displayStatusStore: displayStore,
                presenter: presenter
            )
        }

        it("should preload messages") {
            repository.fetchInAppMessagesResult = Result.success(
                InAppMessagesResponse(success: true, data: [SampleInAppMessage.getSampleInAppMessage()])
            )
            waitUntil { done in manager.preload(for: [:]) { done() } }
            expect(cache.getInAppMessages()).to(equal([SampleInAppMessage.getSampleInAppMessage()]))
        }

        it("should not overwrite preloaded messages on failure") {
            repository.fetchInAppMessagesResult = Result.success(
                InAppMessagesResponse(success: true, data: [SampleInAppMessage.getSampleInAppMessage()])
            )
            waitUntil { done in manager.preload(for: [:]) { done() } }
            repository.fetchInAppMessagesResult = Result.failure(ExponeaError.unknownError(""))
            waitUntil { done in manager.preload(for: [:]) { done() } }
            expect(cache.getInAppMessages()).to(equal([SampleInAppMessage.getSampleInAppMessage()]))
        }

        it("should overwrite preloaded messages on success") {
            repository.fetchInAppMessagesResult = Result.success(
                InAppMessagesResponse(success: true, data: [SampleInAppMessage.getSampleInAppMessage()])
            )
            waitUntil { done in manager.preload(for: [:]) { done() } }
            repository.fetchInAppMessagesResult = Result.success(
                InAppMessagesResponse(success: true, data: [SampleInAppMessage.getSampleInAppMessage(id: "new-id")])
            )
            waitUntil { done in manager.preload(for: [:]) { done() } }
            expect(cache.getInAppMessages()).to(equal([SampleInAppMessage.getSampleInAppMessage(id: "new-id")]))
        }

        it("should get nil in-app message on cold start") {
            expect(manager.getInAppMessage(for: "session_start")).to(beNil())
        }

        it("should get in-app messages from cache if image is precached") {
            cache.saveInAppMessages(inAppMessages: [SampleInAppMessage.getSampleInAppMessage()])
            cache.saveImageData(
                at: SampleInAppMessage.getSampleInAppMessage().payload.imageUrl,
                data: "mock data".data(using: .utf8)!
            )
            expect(manager.getInAppMessage(for: "session_start"))
                .to(equal(SampleInAppMessage.getSampleInAppMessage()))
        }

        it("should not get in-app messages from cache if image is not precached") {
            cache.saveInAppMessages(inAppMessages: [SampleInAppMessage.getSampleInAppMessage()])
            expect(manager.getInAppMessage(for: "session_start")).to(beNil())
        }

        context("filtering messages") {
            it("should apply date filter to messages") {
                let runTest = { (dateFilter: DateFilter, included: Bool) in
                    cache.saveInAppMessages(
                        inAppMessages: [SampleInAppMessage.getSampleInAppMessage(dateFilter: dateFilter)]
                    )
                    cache.saveImageData(
                        at: SampleInAppMessage.getSampleInAppMessage().payload.imageUrl,
                        data: "mock data".data(using: .utf8)!
                    )
                    if included {
                        expect(manager.getInAppMessage(for: "session_start")).notTo(beNil())
                    } else {
                        expect(manager.getInAppMessage(for: "session_start")).to(beNil())
                    }
                }
                let future = Date().addingTimeInterval(100)
                let past = Date().addingTimeInterval(-100)
                runTest(DateFilter(enabled: true, startDate: nil, endDate: nil), true)
                runTest(DateFilter(enabled: true, startDate: future, endDate: nil), false)
                runTest(DateFilter(enabled: true, startDate: past, endDate: nil), true)
                runTest(DateFilter(enabled: true, startDate: nil, endDate: future), true)
                runTest(DateFilter(enabled: true, startDate: nil, endDate: past), false)
                runTest(DateFilter(enabled: false, startDate: nil, endDate: past), true)
            }

            it("should apply trigger filter to messages") {
                let runTest = { (trigger: InAppMessageTrigger, eventType: String, included: Bool) in
                    cache.saveInAppMessages(
                        inAppMessages: [SampleInAppMessage.getSampleInAppMessage(trigger: trigger)]
                    )
                    cache.saveImageData(
                        at: SampleInAppMessage.getSampleInAppMessage().payload.imageUrl,
                        data: "mock data".data(using: .utf8)!
                    )
                    if included {
                        expect(manager.getInAppMessage(for: eventType)).notTo(beNil())
                    } else {
                        expect(manager.getInAppMessage(for: eventType)).to(beNil())
                    }
                }
                runTest(InAppMessageTrigger(type: "event", eventType: "session_start"), "session_start", true)
                runTest(InAppMessageTrigger(type: nil, eventType: nil), "session_start", false)
                runTest(InAppMessageTrigger(type: "event", eventType: "payment"), "session_start", false)
                runTest(InAppMessageTrigger(type: "event", eventType: "payment"), "payment", true)
            }

            context("with frequency filter") {
                let createMessage = { (frequency: InAppMessageFrequency) in
                    let message = SampleInAppMessage.getSampleInAppMessage(frequency: frequency)
                    cache.saveInAppMessages(inAppMessages: [message])
                    cache.saveImageData(at: message.payload.imageUrl, data: "mock data".data(using: .utf8)!)
                }
                it("should apply always filter") {
                    createMessage(.always)
                    expect(manager.getInAppMessage(for: "session_start")).notTo(beNil())
                    expect(manager.getInAppMessage(for: "session_start")).notTo(beNil())
                }
                it("should apply only_once filter") {
                    createMessage(.onlyOnce)
                    expect(manager.getInAppMessage(for: "session_start")).notTo(beNil())
                    waitUntil { done in manager.showInAppMessage(for: "session_start") { _ in done() } }
                    expect(manager.getInAppMessage(for: "session_start")).to(beNil())
                }
                it("should apply until_visitor_interacts filter") {
                    createMessage(.untilVisitorInteracts)
                    expect(manager.getInAppMessage(for: "session_start")).notTo(beNil())
                    waitUntil { done in manager.showInAppMessage(for: "session_start") { _ in done() } }
                    expect(manager.getInAppMessage(for: "session_start")).notTo(beNil())
                    presenter.presentedMessages[0].actionCallback()
                    expect(manager.getInAppMessage(for: "session_start")).to(beNil())
                }
                it("should apply once_per_visit filter") {
                    createMessage(.oncePerVisit)
                    expect(manager.getInAppMessage(for: "session_start")).notTo(beNil())
                    waitUntil { done in manager.showInAppMessage(for: "session_start") { _ in done() } }
                    expect(manager.getInAppMessage(for: "session_start")).to(beNil())
                    manager.sessionDidStart(at: Date())
                    expect(manager.getInAppMessage(for: "session_start")).notTo(beNil())
                }
            }
        }

        it("should show dialog") {
            cache.saveInAppMessages(inAppMessages: [SampleInAppMessage.getSampleInAppMessage()])
            cache.saveImageData(
                at: SampleInAppMessage.getSampleInAppMessage().payload.imageUrl,
                data: "mock data".data(using: .utf8)!
            )
            waitUntil { done in
                manager.showInAppMessage(for: "session_start") { viewController in
                    expect(viewController).notTo(beNil())
                    done()
                }
            }
        }

        it("should not show dialog without messages") {
            waitUntil { done in
                manager.showInAppMessage(for: "session_start") { viewController in
                    expect(viewController).to(beNil())
                    done()
                }
            }
        }

        context("tracking events") {
            var delegate: MockInAppMessageTrackingDelegate!
            beforeEach {
                delegate = MockInAppMessageTrackingDelegate()
                cache.saveInAppMessages(inAppMessages: [SampleInAppMessage.getSampleInAppMessage()])
                cache.saveImageData(
                    at: SampleInAppMessage.getSampleInAppMessage().payload.imageUrl,
                    data: "mock data".data(using: .utf8)!
                )
            }

            it("should not track anything if no message is shown") {
                presenter.presentResult = false
                waitUntil { done in manager.showInAppMessage(
                    for: "session_start",
                    trackingDelegate: delegate
                ) { _ in done() } }
                expect(delegate.calls).to(beEmpty())
            }

            it("should track show event when displaying message") {
                waitUntil { done in manager.showInAppMessage(
                    for: "session_start",
                    trackingDelegate: delegate
                ) { _ in done() } }
                expect(delegate.calls).to(equal([
                    MockInAppMessageTrackingDelegate.CallData(
                        message: SampleInAppMessage.getSampleInAppMessage(),
                        action: "show",
                        interaction: false
                    )
                ]))
            }

            it("should track dismiss event when closing message") {
                waitUntil { done in manager.showInAppMessage(
                    for: "session_start",
                    trackingDelegate: delegate
                ) { _ in done() } }
                presenter.presentedMessages[0].dismissCallback()
                expect(delegate.calls).to(equal([
                    MockInAppMessageTrackingDelegate.CallData(
                        message: SampleInAppMessage.getSampleInAppMessage(),
                        action: "show",
                        interaction: false
                    ),
                    MockInAppMessageTrackingDelegate.CallData(
                        message: SampleInAppMessage.getSampleInAppMessage(),
                        action: "close",
                        interaction: false
                    )
                ]))
            }

            it("should track action event when action button pressed on message") {
                waitUntil { done in manager.showInAppMessage(
                    for: "session_start",
                    trackingDelegate: delegate
                ) { _ in done() } }
                presenter.presentedMessages[0].actionCallback()
                expect(delegate.calls).to(equal([
                    MockInAppMessageTrackingDelegate.CallData(
                        message: SampleInAppMessage.getSampleInAppMessage(),
                        action: "show",
                        interaction: false
                    ),
                    MockInAppMessageTrackingDelegate.CallData(
                        message: SampleInAppMessage.getSampleInAppMessage(),
                        action: "click",
                        interaction: true
                    )
                ]))
            }
        }
    }
}

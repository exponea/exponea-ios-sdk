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
        var presenter: MockInAppMessagePresenter!
        var displayStore: InAppMessageDisplayStatusStore!
        var urlOpener: MockUrlOpener!
        var trackingConsentManager: TrackingConsentManagerType!
        var trackingManager: MockTrackingManager!

        beforeEach {
            cache = MockInAppMessagesCache()
            repository = MockRepository(configuration: self.configuration)
            repository.fetchInAppMessagesResult = Result.success(
                InAppMessagesResponse(success: true, data: [SampleInAppMessage.getSampleInAppMessage()])
            )
            presenter = MockInAppMessagePresenter()
            displayStore = InAppMessageDisplayStatusStore(userDefaults: MockUserDefaults())
            urlOpener = MockUrlOpener()
            trackingManager = MockTrackingManager(
                onEventCallback: { type, event in
                    manager.onEventOccurred(of: type, for: event)
                }
            )
            trackingConsentManager = TrackingConsentManager(
                trackingManager: trackingManager
            )
            manager = InAppMessagesManager(
                repository: repository,
                cache: cache,
                displayStatusStore: displayStore,
                presenter: presenter,
                urlOpener: urlOpener,
                delegate: DefaultInAppDelegate(),
                trackingConsentManager: trackingConsentManager
            )
        }

        it("should preload messages") {
            repository.fetchInAppMessagesResult = Result.success(
                InAppMessagesResponse(success: true, data: [SampleInAppMessage.getSampleInAppMessage()])
            )
            waitUntil(timeout: .seconds(3)) { done in manager.preload(for: [:]) { done() } }
            expect(cache.getInAppMessages()).to(equal([SampleInAppMessage.getSampleInAppMessage()]))
        }

        it("should preload messages on session start after timeout") {
            repository.fetchInAppMessagesResult = Result.success(
                InAppMessagesResponse(success: true, data: [SampleInAppMessage.getSampleInAppMessage()])
            )
            waitUntil(timeout: .seconds(3)) { done in manager.preload(for: [:]) { done() } }
            expect(cache.getInAppMessages()).to(equal([SampleInAppMessage.getSampleInAppMessage()]))
            repository.fetchInAppMessagesResult = Result.success(
                InAppMessagesResponse(success: true, data: [])
            )
            cache.setInAppMessagesTimestamp(10000)
            waitUntil(timeout: .seconds(3)) { done in
                manager.sessionDidStart(at: Date(timeIntervalSince1970: 12345), for: [:]) { done() }
            }
            expect(cache.getInAppMessages()).to(equal([]))
        }

        it("should not preload messages on session start during timeout") {
            repository.fetchInAppMessagesResult = Result.success(
                InAppMessagesResponse(success: true, data: [SampleInAppMessage.getSampleInAppMessage()])
            )
            waitUntil(timeout: .seconds(3)) { done in manager.preload(for: [:]) { done() } }
            expect(cache.getInAppMessages()).to(equal([SampleInAppMessage.getSampleInAppMessage()]))
            repository.fetchInAppMessagesResult = Result.success(
                InAppMessagesResponse(success: true, data: [])
            )
            cache.setInAppMessagesTimestamp(12300)
            waitUntil(timeout: .seconds(3)) { done in
                manager.sessionDidStart(at: Date(timeIntervalSince1970: 12345), for: [:]) { done() }
            }
            expect(cache.getInAppMessages()).to(equal([SampleInAppMessage.getSampleInAppMessage()]))
        }

        it("should not overwrite preloaded messages on failure") {
            repository.fetchInAppMessagesResult = Result.success(
                InAppMessagesResponse(success: true, data: [SampleInAppMessage.getSampleInAppMessage()])
            )
            waitUntil(timeout: .seconds(3)) { done in manager.preload(for: [:]) { done() } }
            repository.fetchInAppMessagesResult = Result.failure(ExponeaError.unknownError(""))
            waitUntil(timeout: .seconds(3)) { done in manager.preload(for: [:]) { done() } }
            expect(cache.getInAppMessages()).to(equal([SampleInAppMessage.getSampleInAppMessage()]))
        }

        it("should overwrite preloaded messages on success") {
            repository.fetchInAppMessagesResult = Result.success(
                InAppMessagesResponse(success: true, data: [SampleInAppMessage.getSampleInAppMessage()])
            )
            waitUntil(timeout: .seconds(3)) { done in manager.preload(for: [:]) { done() } }
            repository.fetchInAppMessagesResult = Result.success(
                InAppMessagesResponse(success: true, data: [SampleInAppMessage.getSampleInAppMessage(id: "new-id")])
            )
            waitUntil(timeout: .seconds(3)) { done in manager.preload(for: [:]) { done() } }
            expect(cache.getInAppMessages()).to(equal([SampleInAppMessage.getSampleInAppMessage(id: "new-id")]))
        }

        it("should get nil in-app message on cold start") {
            expect(manager.getInAppMessage(for: [.eventType("session_start")])).to(beNil())
        }

        it("should get in-app messages from cache if image is needed and precached") {
            cache.saveInAppMessages(inAppMessages: [SampleInAppMessage.getSampleInAppMessage()])
            cache.saveImageData(
                at: SampleInAppMessage.getSampleInAppMessage().payload!.imageUrl!,
                data: "mock data".data(using: .utf8)!
            )
            expect(manager.getInAppMessage(for: [.eventType("session_start")]))
                .to(equal(SampleInAppMessage.getSampleInAppMessage()))
        }

        it("should not get in-app messages from cache if image is needed and not precached") {
            cache.saveInAppMessages(inAppMessages: [SampleInAppMessage.getSampleInAppMessage()])
            expect(manager.getInAppMessage(for: [.eventType("session_start")])).to(beNil())
        }

        it("should not get in-app messages from cache if image is needed and not precached") {
            cache.saveInAppMessages(inAppMessages: [SampleInAppMessage.getSampleInAppMessage(imageUrl: "")])
            expect(manager.getInAppMessage(for: [.eventType("session_start")])).notTo(beNil())
        }

        context("filtering messages") {
            it("should apply date filter to messages") {
                let runTest = { (dateFilter: DateFilter, included: Bool) in
                    cache.saveInAppMessages(
                        inAppMessages: [SampleInAppMessage.getSampleInAppMessage(dateFilter: dateFilter)]
                    )
                    cache.saveImageData(
                        at: SampleInAppMessage.getSampleInAppMessage().payload!.imageUrl!,
                        data: "mock data".data(using: .utf8)!
                    )
                    if included {
                        expect(manager.getInAppMessage(for: [.eventType("session_start")])).notTo(beNil())
                    } else {
                        expect(manager.getInAppMessage(for: [.eventType("session_start")])).to(beNil())
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
                let runTest = { (trigger: EventFilter, data: [DataType], included: Bool) in
                    cache.saveInAppMessages(
                        inAppMessages: [SampleInAppMessage.getSampleInAppMessage(trigger: trigger)]
                    )
                    cache.saveImageData(
                        at: SampleInAppMessage.getSampleInAppMessage().payload!.imageUrl!,
                        data: "mock data".data(using: .utf8)!
                    )
                    if included {
                        expect(manager.getInAppMessage(for: data)).notTo(beNil())
                    } else {
                        expect(manager.getInAppMessage(for: data)).to(beNil())
                    }
                }
                runTest(EventFilter(eventType: "session_start", filter: []), [.eventType("session_start")], true)
                runTest(EventFilter(eventType: "payment", filter: []), [.eventType("session_start")], false)
                runTest(EventFilter(eventType: "payment", filter: []), [.eventType("payment")], true)
                let complexFilter = EventFilter(
                    eventType: "payment",
                    filter: [
                        EventPropertyFilter.property("item_id", StringConstraint.contains("sub")),
                        EventPropertyFilter.timestamp(NumberConstraint.greaterThan(1234))
                    ]
                )
                runTest(complexFilter, [.eventType("payment")], false)
                runTest(complexFilter, [.eventType("payment"), .properties(["item_id": .string("substring")])], false)
                runTest(complexFilter, [.eventType("payment"), .timestamp(12345)], false)
                runTest(
                    complexFilter,
                    [.eventType("payment"), .properties(["item_id": .string("substring")]), .timestamp(123)],
                    false
                )
                runTest(
                    complexFilter,
                    [.eventType("payment"), .properties(["item_id": .string("substring")]), .timestamp(12345)],
                    true
                )
            }

            context("with frequency filter") {
                beforeEach {
                    waitUntil { done in manager.preload(for: [:], completion: done) }
                }
                let createMessage = { (frequency: InAppMessageFrequency) in
                    let message = SampleInAppMessage.getSampleInAppMessage(frequency: frequency)
                    cache.saveInAppMessages(inAppMessages: [message])
                    cache.saveImageData(at: message.payload!.imageUrl!, data: "mock data".data(using: .utf8)!)
                }
                it("should apply always filter") {
                    createMessage(.always)
                    expect(manager.getInAppMessage(for: [.eventType("session_start")])).notTo(beNil())
                    expect(manager.getInAppMessage(for: [.eventType("session_start")])).notTo(beNil())
                }
                it("should apply only_once filter") {
                    createMessage(.onlyOnce)
                    expect(manager.getInAppMessage(for: [.eventType("session_start")])).notTo(beNil())
                    waitUntil { done in manager.showInAppMessage(for: [.eventType("session_start")]) { _ in done() } }
                    expect(manager.getInAppMessage(for: [.eventType("session_start")])).to(beNil())
                }
                it("should apply until_visitor_interacts filter") {
                    createMessage(.untilVisitorInteracts)
                    expect(manager.getInAppMessage(for: [.eventType("session_start")])).notTo(beNil())
                    waitUntil { done in manager.showInAppMessage(for: [.eventType("session_start")]) { _ in done() } }
                    expect(manager.getInAppMessage(for: [.eventType("session_start")])).notTo(beNil())
                    presenter.presentedMessages[0].actionCallback(
                        SampleInAppMessage.getSampleInAppMessage().payload!.buttons![0]
                    )
                    expect(manager.getInAppMessage(for: [.eventType("session_start")])).to(beNil())
                }
                it("should apply once_per_visit filter") {
                    createMessage(.oncePerVisit)
                    expect(manager.getInAppMessage(for: [.eventType("session_start")])).notTo(beNil())
                    waitUntil { done in manager.showInAppMessage(for: [.eventType("session_start")]) { _ in done() } }
                    expect(manager.getInAppMessage(for: [.eventType("session_start")])).to(beNil())
                    manager.sessionDidStart(at: Date(), for: [:], completion: nil)
                    expect(manager.getInAppMessage(for: [.eventType("session_start")])).notTo(beNil())
                }
            }

            it("should apply priority filter") {
                let runTest = { (allMessages: [InAppMessage], expectedMessages: [InAppMessage]) -> Void in
                    cache.saveInAppMessages(inAppMessages: allMessages)
                    allMessages.forEach {
                        cache.saveImageData(at: $0.payload!.imageUrl!, data: "mock data".data(using: .utf8)!)
                    }
                    expect(
                        manager.getInAppMessages(for: [.eventType("session_start")], requireImage: true)
                    ).to(equal(expectedMessages))
                }
                runTest(
                    [
                        SampleInAppMessage.getSampleInAppMessage(id: "1"),
                        SampleInAppMessage.getSampleInAppMessage(id: "2"),
                        SampleInAppMessage.getSampleInAppMessage(id: "3")
                    ],
                    [
                        SampleInAppMessage.getSampleInAppMessage(id: "1"),
                        SampleInAppMessage.getSampleInAppMessage(id: "2"),
                        SampleInAppMessage.getSampleInAppMessage(id: "3")
                    ]
                )
                runTest(
                    [
                        SampleInAppMessage.getSampleInAppMessage(id: "1", priority: 0),
                        SampleInAppMessage.getSampleInAppMessage(id: "2"),
                        SampleInAppMessage.getSampleInAppMessage(id: "3", priority: -1)
                    ],
                    [
                        SampleInAppMessage.getSampleInAppMessage(id: "1", priority: 0),
                        SampleInAppMessage.getSampleInAppMessage(id: "2")
                    ]
                )
                runTest(
                    [
                        SampleInAppMessage.getSampleInAppMessage(id: "1", priority: 2),
                        SampleInAppMessage.getSampleInAppMessage(id: "2", priority: 2),
                        SampleInAppMessage.getSampleInAppMessage(id: "3", priority: 1)
                    ],
                    [
                        SampleInAppMessage.getSampleInAppMessage(id: "1", priority: 2),
                        SampleInAppMessage.getSampleInAppMessage(id: "2", priority: 2)
                    ]
                )
            }
        }

        it("should show dialog") {
            waitUntil { done in manager.preload(for: [:], completion: done) }
            cache.saveInAppMessages(inAppMessages: [SampleInAppMessage.getSampleInAppMessage()])
            cache.saveImageData(
                at: SampleInAppMessage.getSampleInAppMessage().payload!.imageUrl!,
                data: "mock data".data(using: .utf8)!
            )
            waitUntil { done in
                manager.showInAppMessage(for: [.eventType("session_start")]) { viewController in
                    expect(viewController).notTo(beNil())
                    done()
                }
            }
        }

        it("should not show dialog without messages") {
            waitUntil { done in manager.preload(for: [:], completion: done) }
            cache.saveInAppMessages(inAppMessages: [])
            waitUntil { done in
                manager.showInAppMessage(for: [.eventType("session_start")]) { viewController in
                    expect(viewController).to(beNil())
                    done()
                }
            }
        }

        context("tracking events") {
            beforeEach {
                waitUntil { done in manager.preload(for: [:], completion: done) }
                trackingManager.clearCalls()
                cache.saveInAppMessages(inAppMessages: [SampleInAppMessage.getSampleInAppMessage()])
                cache.saveImageData(
                    at: SampleInAppMessage.getSampleInAppMessage().payload!.imageUrl!,
                    data: "mock data".data(using: .utf8)!
                )
            }

            it("should not track anything if no message is shown") {
                presenter.presentResult = false
                waitUntil { done in manager.showInAppMessage(
                    for: [.eventType("session_start")]
                ) { _ in done() } }
                expect(trackingManager.trackedInappEvents).to(beEmpty())
            }

            it("should track show event when displaying message") {
                waitUntil { done in manager.showInAppMessage(
                    for: [.eventType("session_start")]
                ) { _ in done() } }
                expect(trackingManager.trackedInappEvents).to(equal([
                    MockTrackingManager.CallData(
                        event: .show,
                        message: SampleInAppMessage.getSampleInAppMessage()
                    )
                ]))
            }

            it("should track dismiss event when closing message") {
                waitUntil { done in manager.showInAppMessage(
                    for: [.eventType("session_start")]
                ) { _ in done() } }
                presenter.presentedMessages[0].dismissCallback()
                expect(trackingManager.trackedInappEvents).to(equal([
                    MockTrackingManager.CallData(
                        event: .show,
                        message: SampleInAppMessage.getSampleInAppMessage()
                    ),
                    MockTrackingManager.CallData(
                        event: .close,
                        message: SampleInAppMessage.getSampleInAppMessage()
                    )
                ]))
            }

            it("should track action event when action button pressed on message") {
                waitUntil { done in manager.showInAppMessage(
                    for: [.eventType("session_start")]
                ) { _ in done() } }
                presenter.presentedMessages[0].actionCallback(
                    SampleInAppMessage.getSampleInAppMessage().payload!.buttons![0]
                )
                expect(trackingManager.trackedInappEvents).to(equal([
                    MockTrackingManager.CallData(
                        event: .show,
                        message: SampleInAppMessage.getSampleInAppMessage()
                    ),
                    MockTrackingManager.CallData(
                        event: .click(buttonLabel: "Action", url: "https://someaddress.com"),
                        message: SampleInAppMessage.getSampleInAppMessage()
                    )
                ]))
            }

            it("should not track dismiss event when delegate is setup without tracking") {
                let inAppDelegate = InAppMessageDelegate(
                    overrideDefaultBehavior: false,
                    trackActions: false,
                    trackingConsentManager: trackingConsentManager
                )
                manager.delegate = inAppDelegate
                waitUntil { done in manager.showInAppMessage(
                    for: [.eventType("session_start")]
                ) { _ in done() } }
                presenter.presentedMessages[0].dismissCallback()
                expect(trackingManager.trackedInappEvents).to(equal([
                    MockTrackingManager.CallData(
                        event: .show,
                        message: SampleInAppMessage.getSampleInAppMessage()
                    )
                ]))
                expect(inAppDelegate.inAppMessageActionCalled).to(equal(true))
            }

            it("should track dismiss event when delegate is setup with tracking") {
                let inAppDelegate = InAppMessageDelegate(
                    overrideDefaultBehavior: false,
                    trackActions: true,
                    trackingConsentManager: trackingConsentManager
                )
                manager.delegate = inAppDelegate
                waitUntil { done in manager.showInAppMessage(
                    for: [.eventType("session_start")]
                ) { _ in done() } }
                presenter.presentedMessages[0].dismissCallback()
                expect(trackingManager.trackedInappEvents).to(equal([
                    MockTrackingManager.CallData(
                        event: .show,
                        message: SampleInAppMessage.getSampleInAppMessage()
                    ),
                    MockTrackingManager.CallData(
                        event: .close,
                        message: SampleInAppMessage.getSampleInAppMessage()
                    )
                ]))
                expect(inAppDelegate.inAppMessageActionCalled).to(equal(true))
            }

            it("should not track action event when delegate is setup without tracking") {
                let inAppDelegate = InAppMessageDelegate(
                    overrideDefaultBehavior: false,
                    trackActions: false,
                    trackingConsentManager: trackingConsentManager
                )
                manager.delegate = inAppDelegate
                waitUntil { done in manager.showInAppMessage(
                    for: [.eventType("session_start")]
                ) { _ in done() } }
                presenter.presentedMessages[0].actionCallback(
                    SampleInAppMessage.getSampleInAppMessage().payload!.buttons![0]
                )
                expect(trackingManager.trackedInappEvents).to(equal([
                    MockTrackingManager.CallData(
                        event: .show,
                        message: SampleInAppMessage.getSampleInAppMessage()
                    )
                ]))
                expect(inAppDelegate.inAppMessageActionCalled).to(equal(true))
            }

            it("should track action event when delegate is setup with tracking") {
                let inAppDelegate = InAppMessageDelegate(
                    overrideDefaultBehavior: false,
                    trackActions: true,
                    trackingConsentManager: trackingConsentManager
                )
                manager.delegate = inAppDelegate
                waitUntil { done in manager.showInAppMessage(
                    for: [.eventType("session_start")]
                ) { _ in done() } }
                presenter.presentedMessages[0].actionCallback(
                    SampleInAppMessage.getSampleInAppMessage().payload!.buttons![0]
                )
                expect(trackingManager.trackedInappEvents).to(equal([
                    MockTrackingManager.CallData(
                        event: .show,
                        message: SampleInAppMessage.getSampleInAppMessage()
                    ),
                    MockTrackingManager.CallData(
                        event: .click(buttonLabel: "Action", url: "https://someaddress.com"),
                        message: SampleInAppMessage.getSampleInAppMessage()
                    )
                ]))
                expect(inAppDelegate.inAppMessageActionCalled).to(equal(true))
            }

            it("should track action event when track is called in delegate action callback") {
                let inAppDelegate = InAppMessageDelegate(
                    overrideDefaultBehavior: false,
                    trackActions: false,
                    trackClickInActionCallback: true,
                    inAppMessageManager: manager,
                    trackingConsentManager: trackingConsentManager
                )
                manager.delegate = inAppDelegate
                waitUntil { done in manager.showInAppMessage(
                    for: [.eventType("session_start")]
                ) { _ in done() } }
                presenter.presentedMessages[0].actionCallback(
                    SampleInAppMessage.getSampleInAppMessage().payload!.buttons![0]
                )
                expect(trackingManager.trackedInappEvents).to(equal([
                    MockTrackingManager.CallData(
                        event: .show,
                        message: SampleInAppMessage.getSampleInAppMessage()
                    ),
                    MockTrackingManager.CallData(
                        event: .click(buttonLabel: "Action", url: "https://someaddress.com"),
                        message: SampleInAppMessage.getSampleInAppMessage()
                    )
                ]))
                expect(inAppDelegate.inAppMessageActionCalled).to(equal(true))
            }
        }

        context("default action performing") {
            beforeEach {
                waitUntil { done in manager.preload(for: [:], completion: done) }
                cache.saveInAppMessages(inAppMessages: [SampleInAppMessage.getSampleInAppMessage()])
                cache.saveImageData(
                    at: SampleInAppMessage.getSampleInAppMessage().payload!.imageUrl!,
                    data: "mock data".data(using: .utf8)!
                )
            }

            it("should call default action when override is turned off in delegate ") {
                manager.delegate = InAppMessageDelegate(
                    overrideDefaultBehavior: false,
                    trackActions: true,
                    trackingConsentManager: trackingConsentManager
                )
                waitUntil { done in
                    manager.showInAppMessage(for: [.eventType("session_start")]) { _ in
                        done()
                    }
                }
                presenter.presentedMessages[0].actionCallback(
                    SampleInAppMessage.getSampleInAppMessage().payload!.buttons![0]
                )
                expect(urlOpener.openedDeeplinks.count).to(equal(1))
            }

            it("should not call default action when override is turned on in delegate ") {
                manager.delegate = InAppMessageDelegate(overrideDefaultBehavior: true, trackActions: true)
                waitUntil { done in manager.showInAppMessage(
                    for: [.eventType("session_start")]
                ) { _ in done() } }
                presenter.presentedMessages[0].actionCallback(
                    SampleInAppMessage.getSampleInAppMessage().payload!.buttons![0]
                )
                expect(urlOpener.openedDeeplinks.count).to(equal(0))
            }
        }

        it("should show in-app message after preload is complete") {
            cache.saveInAppMessages(inAppMessages: [SampleInAppMessage.getSampleInAppMessage()])
            cache.saveImageData(
                at: SampleInAppMessage.getSampleInAppMessage().payload!.imageUrl!,
                data: "mock data".data(using: .utf8)!
            )
            let delegate = MockInAppMessageTrackingDelegate()
            let semaphore = DispatchSemaphore(value: 0) // we'll wait for the message to be shown
            manager.showInAppMessage(for: [.eventType("session_start")]) { _ in
                semaphore.signal()
            }
            expect(presenter.presentedMessages.count).to(equal(0))
            waitUntil(timeout: .seconds(3)) { done in manager.preload(for: [:], completion: done) }
            _ = semaphore.wait(timeout: .now() + 1)
            expect(presenter.presentedMessages.count).to(equal(1))
        }

        it("should track control group message without showing it") {
            waitUntil { done in manager.preload(for: [:], completion: done) }
            trackingManager.clearCalls()
            let message = SampleInAppMessage.getSampleInAppMessage(
                payload: nil,
                variantName: "Control group",
                variantId: -1)
            cache.saveInAppMessages(inAppMessages: [message])
            waitUntil { done in manager.showInAppMessage(
                for: [.eventType("session_start")]
            ) { _ in done() } }
            expect(trackingManager.trackedInappEvents).to(equal([
                MockTrackingManager.CallData(
                    event: .show,
                    message: message
                )
            ]))
            expect(presenter.presentedMessages.count).to(equal(0))
        }

        it("should not download same image multiple times") {
            let message = SampleInAppMessage.getSampleInAppMessage()
            expect(cache.hasImageData(at: (message.payload?.imageUrl)!)).to(equal(false))
            expect(cache.getImageDownloadCount()).to(equal(0))
            waitUntil { done in manager.preloadImages(inAppMessages: [message], completion: done) }
            expect(cache.hasImageData(at: (message.payload?.imageUrl)!)).to(equal(true))
            expect(cache.getImageDownloadCount()).to(equal(1))
            waitUntil { done in manager.preloadImages(inAppMessages: [message], completion: done) }
            expect(cache.getImageDownloadCount()).to(equal(1))
        }

        it("should download image with different URL") {
            let message = SampleInAppMessage.getSampleInAppMessage()
            expect(cache.hasImageData(at: (message.payload?.imageUrl)!)).to(equal(false))
            expect(cache.getImageDownloadCount()).to(equal(0))
            waitUntil { done in manager.preloadImages(inAppMessages: [message], completion: done) }
            expect(cache.hasImageData(at: (message.payload?.imageUrl)!)).to(equal(true))
            expect(cache.getImageDownloadCount()).to(equal(1))

            let messageWithDifferentUrl = SampleInAppMessage.getSampleInAppMessage(
                imageUrl: "https://storage.googleapis.com/exp-app-storage/" +
                "f02807dc-6b57-11e9-8cc8-0a580a203636/media/original/8a32cbd6-43a1-11ec-8188-8a3224482d07"
            )
            waitUntil { done in manager.preloadImages(inAppMessages: [messageWithDifferentUrl], completion: done) }
            expect(cache.hasImageData(at: (messageWithDifferentUrl.payload?.imageUrl)!)).to(equal(true))
            expect(cache.getImageDownloadCount()).to(equal(2))
        }
    }
}

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

@MainActor
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
        let customer1 = ["fake": "user"]
        let event: DataType = .customerIds(Exponea.shared.trackingManager?.customerIds ?? customer1)

        beforeEach {
            cache = MockInAppMessagesCache()
            repository = MockRepository(configuration: self.configuration)
            let message = SampleInAppMessage.getSampleInAppMessage()
            repository.fetchInAppMessagesResult = Result.success(
                InAppMessagesResponse(success: true, data: [message])
            )
            presenter = MockInAppMessagePresenter()
            displayStore = InAppMessageDisplayStatusStore(userDefaults: MockUserDefaults())
            urlOpener = MockUrlOpener()
            trackingManager = MockTrackingManager(
                onEventCallback: { _, _ in }
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
                trackingConsentManager: trackingConsentManager
            )
            trackingManager.inAppManager = manager
        }

        describe("Load") {
            it("Try to append pending request during identify customer") {
                waitUntil(timeout: .seconds(3), action: { done in
                    Task {
                        manager.onEventOccurred(of: .identifyCustomer, for: [.customerIds(customer1)])
                        expect(manager.pendingShowRequests.count).to(equal(0))
                        try await Task.sleep(nanoseconds: UInt64(1 * 1_000_000_000))
                        await manager.addToPendingShowRequest(event: [.eventType("session_start"), .customerIds(customer1)])
                        await manager.addToPendingShowRequest(event: [.eventType("session_start"), .customerIds(customer1)])
                        expect(manager.pendingShowRequests.count).to(equal(1))
                        manager.onEventOccurred(of: .identifyCustomer, for: [.customerIds(customer1)])
                        expect(manager.pendingShowRequests.count).to(equal(1))
                        done()
                    }
                })
            }
            it("Check if pendingShowRequests are removed after identify customer") {
                manager.onEventOccurred(of: .identifyCustomer, for: [.customerIds(customer1)])
                expect(manager.pendingShowRequests.count).to(equal(0))
                manager.onEventOccurred(of: .sessionStart, for: [.customerIds(customer1)])
                manager.onEventOccurred(of: .sessionStart, for: [.customerIds(customer1)])
                manager.onEventOccurred(of: .identifyCustomer, for: [.customerIds(customer1)])
                expect(manager.pendingShowRequests.count).to(equal(0))
            }
            it("Load in appm essages and try all statuses") {
                Exponea.shared.flushingMode = .manual
                manager.onEventOccurred(of: .identifyCustomer, for: [.customerIds(customer1)])
                var successOperations = 0
                waitUntil(timeout: .seconds(3)) { done in
                    manager.onEventOccurred(of: .identifyCustomer, for: [.customerIds(customer1)]) { state in
                        switch state {
                        case .identifyFetch:
                            successOperations += 1
                            done()
                        case .shouldReloadFetch: break
                        case .storedFetch: break
                        }
                    }
                }
                waitUntil(timeout: .seconds(3)) { done in
                    manager.onEventOccurred(of: .sessionStart, for: [.customerIds(customer1), .timestamp(Date().timeIntervalSince1970)]) { state in
                        switch state {
                        case .identifyFetch: break
                        case .shouldReloadFetch:
                            successOperations += 1
                            done()
                        case .storedFetch: break
                        }
                    }
                }
                waitUntil(timeout: .seconds(3)) { done in
                    manager.onEventOccurred(of: .identifyCustomer, for: [.customerIds(customer1)]) { state in
                        switch state {
                        case .identifyFetch:
                            successOperations += 1
                            done()
                        case .shouldReloadFetch: break
                        case .storedFetch: break
                        }
                    }
                }
                waitUntil(timeout: .seconds(3)) { done in
                    // InApp cache is 0.0, so we need to add timestamp as 0 to get shouldReload false
                    let nulDate = Date().addingTimeInterval(-Date().timeIntervalSince1970).timeIntervalSince1970
                    manager.onEventOccurred(of: .customEvent, for: [.customerIds(customer1), .timestamp(nulDate)]) { state in
                        switch state {
                        case .identifyFetch: break
                        case .shouldReloadFetch: break
                        case .storedFetch:
                            successOperations += 1
                            done()
                        }
                    }
                }
                expect(successOperations).to(equal(4))
            }
        }

        it("should preload messages") {
            repository.fetchInAppMessagesResult = Result.success(
                InAppMessagesResponse(success: true, data: [SampleInAppMessage.getSampleInAppMessage()])
            )
            waitUntil(timeout: .seconds(3)) { done in
                Task {
                    do {
                        try await manager.isFetchInAppMessagesDone(for: [])
                        done()
                    } catch { done() }
                }
            }
            expect(cache.getInAppMessages()).to(equal([SampleInAppMessage.getSampleInAppMessage()]))
        }

        it("should not overwrite preloaded messages on failure") {
            repository.fetchInAppMessagesResult = Result.success(
                InAppMessagesResponse(success: true, data: [SampleInAppMessage.getSampleInAppMessage()])
            )
            waitUntil(timeout: .seconds(3)) { done in
                Task {
                    do {
                        try await manager.isFetchInAppMessagesDone(for: [])
                        done()
                    } catch {
                        done()
                    }
                }
            }
            repository.fetchInAppMessagesResult = Result.failure(ExponeaError.unknownError(""))
            waitUntil(timeout: .seconds(3)) { done in
                Task {
                    do {
                        try await manager.isFetchInAppMessagesDone(for: [])
                        done()
                    } catch {
                        done()
                    }
                }
            }
            expect(cache.getInAppMessages()).to(equal([SampleInAppMessage.getSampleInAppMessage()]))
        }

        it("should overwrite preloaded messages on success") {
            repository.fetchInAppMessagesResult = Result.success(
                InAppMessagesResponse(success: true, data: [SampleInAppMessage.getSampleInAppMessage()])
            )
            waitUntil(timeout: .seconds(3)) { done in
                Task {
                    do {
                        try await manager.isFetchInAppMessagesDone(for: [])
                        done()
                    } catch {
                        done()
                    }
                }
            }
            repository.fetchInAppMessagesResult = Result.success(
                InAppMessagesResponse(success: true, data: [SampleInAppMessage.getSampleInAppMessage(id: "new-id")])
            )
            waitUntil(timeout: .seconds(3)) { done in
                Task {
                    do {
                        try await manager.isFetchInAppMessagesDone(for: [])
                        done()
                    } catch { done() }
                }
            }
            expect(cache.getInAppMessages()).to(equal([SampleInAppMessage.getSampleInAppMessage(id: "new-id")]))
        }

        it("should get nil in-app message on cold start") {
            expect(manager.loadMessageToShow(for: [.eventType("session_start")])).to(beNil())
        }

        it("should get in-app messages from cache if image is needed and precached") {
            cache.saveInAppMessages(inAppMessages: [SampleInAppMessage.getSampleInAppMessage()])
            cache.saveImageData(
                at: SampleInAppMessage.getSampleInAppMessage().oldPayload!.imageUrl!,
                data: "mock data".data(using: .utf8)!
            )
            expect(manager.loadMessageToShow(for: [.eventType("session_start")]))
                .to(equal(SampleInAppMessage.getSampleInAppMessage()))
        }

        it("should not get in-app messages from cache if image is needed and not precached") {
            cache.saveInAppMessages(inAppMessages: [SampleInAppMessage.getSampleInAppMessage(imageUrl: "")])
            expect(manager.loadMessageToShow(for: [.eventType("session_start")])).notTo(beNil())
        }

        context("filtering messages") {
            it("should apply date filter to messages") {
                let runTest = { (dateFilter: DateFilter, included: Bool) in
                    cache.saveInAppMessages(
                        inAppMessages: [SampleInAppMessage.getSampleInAppMessage(dateFilter: dateFilter)]
                    )
                    cache.saveImageData(
                        at: SampleInAppMessage.getSampleInAppMessage().oldPayload!.imageUrl!,
                        data: "mock data".data(using: .utf8)!
                    )
                    if included {
                        expect(manager.loadMessageToShow(for: [.eventType("session_start")])).notTo(beNil())
                    } else {
                        expect(manager.loadMessageToShow(for: [.eventType("session_start")])).to(beNil())
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
                        at: SampleInAppMessage.getSampleInAppMessage().oldPayload!.imageUrl!,
                        data: "mock data".data(using: .utf8)!
                    )
                    if included {
                        expect(manager.loadMessageToShow(for: data)).notTo(beNil())
                    } else {
                        expect(manager.loadMessageToShow(for: data)).to(beNil())
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
                    waitUntil(timeout: .seconds(5)) { done in
                        Task {
                            do {
                                try await manager.isFetchInAppMessagesDone(for: [])
                                done()
                            } catch { done() }
                        }
                    }
                }
                let createMessage = { (frequency: InAppMessageFrequency) in
                    let message = SampleInAppMessage.getSampleInAppMessage(frequency: frequency)
                    cache.saveInAppMessages(inAppMessages: [message])
                    cache.saveImageData(at: message.oldPayload!.imageUrl!, data: "mock data".data(using: .utf8)!)
                }
                it("should apply always filter") {
                    createMessage(.always)
                    expect(manager.loadMessageToShow(for: [.eventType("session_start")])).notTo(beNil())
                    expect(manager.loadMessageToShow(for: [.eventType("session_start")])).notTo(beNil())
                }
                it("should apply only_once filter") {
                    createMessage(.onlyOnce)
                    expect(manager.loadMessageToShow(for: [.eventType("session_start")])).notTo(beNil())
                    waitUntil(timeout: .seconds(5)) { done in manager.showInAppMessage(for: [.eventType("session_start")]) { _ in done() } }
                    expect(manager.loadMessageToShow(for: [.eventType("session_start")])).to(beNil())
                }
                it("should apply until_visitor_interacts filter") {
                    createMessage(.untilVisitorInteracts)
                    expect(manager.loadMessageToShow(for: [.eventType("session_start")])).notTo(beNil())
                    waitUntil(timeout: .seconds(5)) { done in manager.showInAppMessage(for: [.eventType("session_start")]) { _ in done() } }
                    expect(manager.loadMessageToShow(for: [.eventType("session_start")])).notTo(beNil())
                    presenter.presentedMessages[0].actionCallback(
                        SampleInAppMessage.getSampleInAppMessage().oldPayload!.buttons![0]
                    )
                    expect(manager.loadMessageToShow(for: [.eventType("session_start")])).to(beNil())
                }
                it("should apply once_per_visit filter") {
                    createMessage(.oncePerVisit)
                    expect(manager.loadMessageToShow(for: [.eventType("session_start")])).notTo(beNil())
                    waitUntil(timeout: .seconds(5)) { done in manager.showInAppMessage(for: [.eventType("session_start")]) { _ in done() } }
                    expect(manager.loadMessageToShow(for: [.eventType("session_start")])).to(beNil())
                }
            }

            it("should apply priority filter") {
                let runTest = { (allMessages: [InAppMessage], expectedMessages: [InAppMessage]) -> Void in
                    cache.saveInAppMessages(inAppMessages: allMessages)
                    allMessages.forEach {
                        cache.saveImageData(at: $0.oldPayload!.imageUrl!, data: "mock data".data(using: .utf8)!)
                    }
                    expect(
                        manager.loadMessagesToShow(for: [.eventType("session_start")])
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
            waitUntil(timeout: .seconds(5)) { done in
                Task {
                    do {
                        try await manager.isFetchInAppMessagesDone(for: [])
                        done()
                    } catch { done() }
                }
            }
            cache.saveInAppMessages(inAppMessages: [SampleInAppMessage.getSampleInAppMessage()])
            cache.saveImageData(
                at: SampleInAppMessage.getSampleInAppMessage().oldPayload!.imageUrl!,
                data: "mock data".data(using: .utf8)!
            )
            waitUntil(timeout: .seconds(5)) { done in
                manager.showInAppMessage(for: [.eventType("session_start")]) { viewController in
                    expect(viewController).notTo(beNil())
                    done()
                }
            }
        }

        it("should not show dialog without messages") {
            waitUntil(timeout: .seconds(5)) { done in
                Task {
                    do {
                        try await manager.isFetchInAppMessagesDone(for: [])
                        done()
                    } catch { done() }
                }
            }
            cache.saveInAppMessages(inAppMessages: [])
            waitUntil(timeout: .seconds(5)) { done in
                manager.showInAppMessage(for: [.eventType("session_start")]) { viewController in
                    expect(viewController).to(beNil())
                    done()
                }
            }
        }

        context("tracking events") {
            beforeEach {
                waitUntil(timeout: .seconds(5)) { done in
                    Task {
                        do {
                            try await manager.isFetchInAppMessagesDone(for: [])
                            done()
                        } catch { done() }
                    }
                }
                trackingManager.clearCalls()
                cache.saveInAppMessages(inAppMessages: [SampleInAppMessage.getSampleInAppMessage()])
                cache.saveImageData(
                    at: SampleInAppMessage.getSampleInAppMessage().oldPayload!.imageUrl!,
                    data: "mock data".data(using: .utf8)!
                )
            }

            it("should not track anything if no message is shown") {
                presenter.presentResult = false
                waitUntil(timeout: .seconds(5)) { done in manager.showInAppMessage(
                    for: [.eventType("session_start")]
                ) { _ in done() } }
                expect(trackingManager.trackedInappEvents).to(beEmpty())
            }

            it("should track show event when displaying message") {
                waitUntil(timeout: .seconds(5)) { done in manager.showInAppMessage(
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
                let inAppDelegate = InAppMessageDelegate(
                    overrideDefaultBehavior: false,
                    trackActions: true,
                    trackingConsentManager: trackingConsentManager
                )
                Exponea.shared.inAppMessagesDelegate = inAppDelegate
                waitUntil(timeout: .seconds(5)) { done in manager.showInAppMessage(
                    for: [.eventType("session_start")]
                ) { _ in done() } }
                presenter.presentedMessages[0].dismissCallback(false, nil)
                expect(trackingManager.trackedInappEvents).to(equal([
                    MockTrackingManager.CallData(
                        event: .show,
                        message: SampleInAppMessage.getSampleInAppMessage()
                    ),
                    MockTrackingManager.CallData(
                        event: .close(buttonLabel: nil),
                        message: SampleInAppMessage.getSampleInAppMessage()
                    )
                ]))
            }
            
            it("should track action event when action button pressed on message") {
                let inAppDelegate = InAppMessageDelegate(
                    overrideDefaultBehavior: false,
                    trackActions: true,
                    trackingConsentManager: trackingConsentManager
                )
                Exponea.shared.inAppMessagesDelegate = inAppDelegate
                waitUntil(timeout: .seconds(5)) { done in manager.showInAppMessage(
                    for: [.eventType("session_start")]
                ) { _ in done() } }
                presenter.presentedMessages[0].actionCallback(
                    SampleInAppMessage.getSampleInAppMessage().oldPayload!.buttons![0]
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

            it("should show in-app message after preload is complete") {
                cache.saveInAppMessages(inAppMessages: [SampleInAppMessage.getSampleInAppMessage()])
                cache.saveImageData(
                    at: SampleInAppMessage.getSampleInAppMessage().oldPayload!.imageUrl!,
                    data: "mock data".data(using: .utf8)!
                )
                manager.onEventOccurred(of: .sessionStart, for: [.eventType("session_start")])
                waitUntil(timeout: .seconds(2)) { done in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        done()
                    }
                }
                expect(presenter.presentedMessages.count).to(equal(1))
            }

            it("should not track dismiss event when delegate is setup without tracking") {
                let inAppDelegate = InAppMessageDelegate(
                    overrideDefaultBehavior: false,
                    trackActions: false,
                    trackingConsentManager: trackingConsentManager
                )
                Exponea.shared.inAppMessagesDelegate = inAppDelegate
                waitUntil(timeout: .seconds(5)) { done in manager.showInAppMessage(
                    for: [.eventType("session_start")]
                ) { _ in done() } }
                presenter.presentedMessages[0].dismissCallback(false, nil)
                expect(trackingManager.trackedInappEvents).to(equal([
                    MockTrackingManager.CallData(
                        event: .show,
                        message: SampleInAppMessage.getSampleInAppMessage()
                    )
                ]))
                expect(inAppDelegate.inAppMessageCloseCalled).to(equal(true))
            }

            it("should track dismiss event when delegate is setup with tracking") {
                let inAppDelegate = InAppMessageDelegate(
                    overrideDefaultBehavior: false,
                    trackActions: true,
                    trackingConsentManager: trackingConsentManager
                )
                Exponea.shared.inAppMessagesDelegate = inAppDelegate
                waitUntil(timeout: .seconds(5)) { done in manager.showInAppMessage(
                    for: [.eventType("session_start")]
                ) { _ in done() } }
                presenter.presentedMessages[0].dismissCallback(false, nil)
                expect(trackingManager.trackedInappEvents).to(equal([
                    MockTrackingManager.CallData(
                        event: .show,
                        message: SampleInAppMessage.getSampleInAppMessage()
                    ),
                    MockTrackingManager.CallData(
                        event: .close(buttonLabel: nil),
                        message: SampleInAppMessage.getSampleInAppMessage()
                    )
                ]))
                expect(inAppDelegate.inAppMessageCloseCalled).to(equal(true))
            }

            it("should not track action event when delegate is setup without tracking") {
                let inAppDelegate = InAppMessageDelegate(
                    overrideDefaultBehavior: false,
                    trackActions: false,
                    trackingConsentManager: trackingConsentManager
                )
                Exponea.shared.inAppMessagesDelegate = inAppDelegate
                waitUntil(timeout: .seconds(5)) { done in manager.showInAppMessage(
                    for: [.eventType("session_start")]
                ) { _ in done() } }
                presenter.presentedMessages[0].actionCallback(
                    SampleInAppMessage.getSampleInAppMessage().oldPayload!.buttons![0]
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
                Exponea.shared.inAppMessagesDelegate = inAppDelegate
                waitUntil(timeout: .seconds(5)) { done in manager.showInAppMessage(
                    for: [.eventType("session_start")]
                ) { _ in done() } }
                if !presenter.presentedMessages.isEmpty {
                    presenter.presentedMessages[0].actionCallback(
                        SampleInAppMessage.getSampleInAppMessage().oldPayload!.buttons![0]
                    )
                }
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
                Exponea.shared.inAppMessagesDelegate = inAppDelegate
                waitUntil(timeout: .seconds(5)) { done in manager.showInAppMessage(
                    for: [.eventType("session_start")]
                ) { _ in done() } }
                presenter.presentedMessages[0].actionCallback(
                    SampleInAppMessage.getSampleInAppMessage().oldPayload!.buttons![0]
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

            it("should track show event when delegate is setup without tracking") {
                let inAppDelegate = InAppMessageDelegate(
                    overrideDefaultBehavior: false,
                    trackActions: false,
                    trackingConsentManager: trackingConsentManager
                )
                Exponea.shared.inAppMessagesDelegate = inAppDelegate
                waitUntil(timeout: .seconds(5)) { done in manager.showInAppMessage(
                    for: [.eventType("session_start")]
                ) { _ in done() } }
                expect(trackingManager.trackedInappEvents).to(equal([
                    MockTrackingManager.CallData(
                        event: .show,
                        message: SampleInAppMessage.getSampleInAppMessage()
                    )
                ]))
                expect(inAppDelegate.inAppMessageShownCalled).to(equal(true))
            }
            
            it("should track show event when delegate is setup with custom behaviour") {
                let inAppDelegate = InAppMessageDelegate(
                    overrideDefaultBehavior: true,
                    trackActions: false,
                    trackingConsentManager: trackingConsentManager
                )
                Exponea.shared.inAppMessagesDelegate = inAppDelegate
                waitUntil(timeout: .seconds(5)) { done in manager.showInAppMessage(
                    for: [.eventType("session_start")]
                ) { _ in done() } }
                expect(trackingManager.trackedInappEvents).to(equal([
                    MockTrackingManager.CallData(
                        event: .show,
                        message: SampleInAppMessage.getSampleInAppMessage()
                    )
                ]))
                expect(inAppDelegate.inAppMessageShownCalled).to(equal(true))
            }
            
            it("should track error event when delegate is setup without tracking") {
                let inAppDelegate = InAppMessageDelegate(
                    overrideDefaultBehavior: false,
                    trackActions: false,
                    trackingConsentManager: trackingConsentManager
                )
                Exponea.shared.inAppMessagesDelegate = inAppDelegate
                var alreadyDone = false
                waitUntil(timeout: .seconds(5)) { done in
                    manager.showInAppMessage(for: [.eventType("session_start")]) { _ in
                        if alreadyDone {
                            return
                        }
                        alreadyDone = true
                        done()
                    }
                }
                trackingManager.trackedInappEvents.removeAll()
                presenter.presentedMessages[0].presentedCallback!(nil, "Error occured")
                expect(trackingManager.trackedInappEvents).to(equal([
                    MockTrackingManager.CallData(
                        event: .error(message: "Error occured"),
                        message: SampleInAppMessage.getSampleInAppMessage()
                    )
                ]))
                expect(inAppDelegate.inAppMessageErrorCalled).to(equal(true))
            }
            
            it("should track error event when delegate is setup with custom behaviour") {
                let inAppDelegate = InAppMessageDelegate(
                    overrideDefaultBehavior: true,
                    trackActions: false,
                    trackingConsentManager: trackingConsentManager
                )
                Exponea.shared.inAppMessagesDelegate = inAppDelegate
                var alreadyDone = false
                waitUntil(timeout: .seconds(5)) { done in
                    manager.showInAppMessage(for: [.eventType("session_start")]) { _ in
                        if alreadyDone {
                            return
                        }
                        alreadyDone = true
                        done()
                    }
                }
                trackingManager.trackedInappEvents.removeAll()
                presenter.presentedMessages[0].presentedCallback!(nil, "Error occured")
                expect(trackingManager.trackedInappEvents).to(equal([
                    MockTrackingManager.CallData(
                        event: .error(message: "Error occured"),
                        message: SampleInAppMessage.getSampleInAppMessage()
                    )
                ]))
                expect(inAppDelegate.inAppMessageErrorCalled).to(equal(true))
            }
        }

        context("default action performing") {
            beforeEach {
                waitUntil(timeout: .seconds(5)) { done in
                    Task {
                        do {
                            try await manager.isFetchInAppMessagesDone(for: [])
                            done()
                        } catch { done() }
                    }
                }
                cache.saveInAppMessages(inAppMessages: [SampleInAppMessage.getSampleInAppMessage()])
                cache.saveImageData(
                    at: SampleInAppMessage.getSampleInAppMessage().oldPayload!.imageUrl!,
                    data: "mock data".data(using: .utf8)!
                )
            }

            it("should call default action when override is turned off in delegate ") {
                Exponea.shared.inAppMessagesDelegate = InAppMessageDelegate(
                    overrideDefaultBehavior: false,
                    trackActions: true,
                    trackingConsentManager: trackingConsentManager
                )
                waitUntil(timeout: .seconds(5)) { done in
                    manager.showInAppMessage(for: [.eventType("session_start")]) { _ in
                        done()
                    }
                }
                presenter.presentedMessages[0].actionCallback(
                    SampleInAppMessage.getSampleInAppMessage().oldPayload!.buttons![0]
                )
                expect(urlOpener.openedDeeplinks.count).to(equal(1))
            }

            it("should not call default action when override is turned on in delegate ") {
                Exponea.shared.inAppMessagesDelegate = InAppMessageDelegate(overrideDefaultBehavior: true, trackActions: true)
                waitUntil(timeout: .seconds(5)) { done in manager.showInAppMessage(
                    for: [.eventType("session_start")]
                ) { _ in done() } }
                presenter.presentedMessages[0].actionCallback(
                    SampleInAppMessage.getSampleInAppMessage().oldPayload!.buttons![0]
                )
                expect(urlOpener.openedDeeplinks.count).to(equal(0))
            }
        }

        it("should track control group message without showing it") {
            waitUntil(timeout: .seconds(5)) { done in
                Task {
                    do {
                        try await manager.isFetchInAppMessagesDone(for: [])
                        done()
                    } catch { done() }
                }
            }
            trackingManager.clearCalls()
            let message = SampleInAppMessage.getSampleInAppMessage(
                payload: SampleInAppMessage.getSampleInAppMessage().oldPayload!,
                variantName: "Control group",
                variantId: -1)
            cache.saveInAppMessages(inAppMessages: [message])
            waitUntil(timeout: .seconds(5)) { done in manager.showInAppMessage(
                for: [.eventType("session_start")]
            ) { _ in done() } }
            expect(trackingManager.trackedInappEvents).to(equal([
                MockTrackingManager.CallData(
                    event: .show,
                    message: message
                )
            ]))
        }
    }
}

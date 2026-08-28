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

        func productionSessionStartEvent(customerIds: [String: String]) -> [DataType] {
            [
                .eventType(EventType.sessionStart.rawValue),
                .eventType(Constants.EventTypes.sessionStart),
                .customerIds(customerIds),
                .timestamp(Date().timeIntervalSince1970)
            ]
        }

        func seedSessionStartMessageCache() {
            let message = SampleInAppMessage.getSampleInAppMessage()
            cache.saveInAppMessages(inAppMessages: [message])
            cache.saveImageData(
                at: message.oldPayload!.imageUrl!,
                data: "mock data".data(using: .utf8)!
            )
            cache.setInAppMessagesTimestamp(Date().timeIntervalSince1970)
        }

        beforeEach {
            IntegrationManager.shared.isStopped = false
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
            trackingManager.customerIds = customer1
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
            it("replays session_start IAM after app transitions from background to foreground") {
                seedSessionStartMessageCache()

                Exponea.shared.isAppForeground = false
                manager.onEventOccurred(
                    of: .sessionStart,
                    for: productionSessionStartEvent(customerIds: customer1)
                )
                expect(presenter.presentedMessages.count).toEventually(equal(0), timeout: .seconds(2))

                Exponea.shared.isAppForeground = true
                manager.applicationDidBecomeActive()
                expect(presenter.presentedMessages.count).toEventually(equal(1), timeout: .seconds(5))
            }
            it("does not double-show when foreground session_start follows a pending replay") {
                seedSessionStartMessageCache()

                Exponea.shared.isAppForeground = false
                manager.onEventOccurred(
                    of: .sessionStart,
                    for: productionSessionStartEvent(customerIds: customer1)
                )
                expect(presenter.presentedMessages.count).toEventually(equal(0), timeout: .seconds(2))

                Exponea.shared.isAppForeground = true
                manager.applicationDidBecomeActive()
                manager.onEventOccurred(
                    of: .sessionStart,
                    for: productionSessionStartEvent(customerIds: customer1)
                )
                expect(presenter.presentedMessages.count).toEventually(equal(1), timeout: .seconds(5))
            }
            it("does not replay non-session_start events after foreground transition") {
                seedSessionStartMessageCache()

                Exponea.shared.isAppForeground = false
                manager.onEventOccurred(
                    of: .customEvent,
                    for: [.eventType("button_clicked"), .customerIds(customer1)]
                )
                expect(presenter.presentedMessages.count).toEventually(equal(0), timeout: .seconds(2))

                Exponea.shared.isAppForeground = true
                manager.applicationDidBecomeActive()

                expect(presenter.presentedMessages.count).toEventually(equal(0), timeout: .seconds(2))
            }
            it("clears pending session_start replay on anonymize") {
                seedSessionStartMessageCache()

                Exponea.shared.isAppForeground = false
                manager.onEventOccurred(
                    of: .sessionStart,
                    for: productionSessionStartEvent(customerIds: customer1)
                )
                expect(presenter.presentedMessages.count).toEventually(equal(0), timeout: .seconds(2))

                manager.anonymize()

                Exponea.shared.isAppForeground = true
                manager.applicationDidBecomeActive()

                expect(presenter.presentedMessages.count).toEventually(equal(0), timeout: .seconds(2))
            }
            it("clears pending session_start replay on integration stop") {
                seedSessionStartMessageCache()

                Exponea.shared.isAppForeground = false
                manager.onEventOccurred(
                    of: .sessionStart,
                    for: productionSessionStartEvent(customerIds: customer1)
                )
                expect(presenter.presentedMessages.count).toEventually(equal(0), timeout: .seconds(2))

                IntegrationManager.shared.onIntegrationStoppedCallbacks.forEach { $0() }

                Exponea.shared.isAppForeground = true
                manager.applicationDidBecomeActive()

                expect(presenter.presentedMessages.count).toEventually(equal(0), timeout: .seconds(2))
            }
            it("clears pending session_start replay on identify customer") {
                seedSessionStartMessageCache()

                Exponea.shared.isAppForeground = false
                manager.onEventOccurred(
                    of: .sessionStart,
                    for: productionSessionStartEvent(customerIds: customer1)
                )
                expect(presenter.presentedMessages.count).toEventually(equal(0), timeout: .seconds(2))

                Exponea.shared.isAppForeground = true
                manager.onEventOccurred(of: .identifyCustomer, for: [.customerIds(["other": "user"])])
                expect(presenter.presentedMessages.count).toEventually(equal(0), timeout: .seconds(5))
                let countAfterIdentify = presenter.presentedMessages.count

                manager.applicationDidBecomeActive()

                expect(presenter.presentedMessages.count).toEventually(equal(countAfterIdentify), timeout: .seconds(5))
            }
            it("replays deferred session_start after identify with compatible customer") {
                seedSessionStartMessageCache()

                Exponea.shared.isAppForeground = false
                manager.onEventOccurred(
                    of: .sessionStart,
                    for: productionSessionStartEvent(customerIds: customer1)
                )
                expect(presenter.presentedMessages.count).toEventually(equal(0), timeout: .seconds(2))

                Exponea.shared.isAppForeground = true
                manager.onEventOccurred(of: .identifyCustomer, for: [.customerIds(customer1)])
                expect(presenter.presentedMessages.count).toEventually(equal(1), timeout: .seconds(5))
            }
            it("hydrated customer ids allow session_start replay when tracking ids are a superset") {
                seedSessionStartMessageCache()
                let cookieOnly = ["cookie": "test-cookie"]
                trackingManager.customerIds = ["cookie": "test-cookie", "fake": "user"]

                Exponea.shared.isAppForeground = false
                manager.onEventOccurred(
                    of: .sessionStart,
                    for: productionSessionStartEvent(customerIds: cookieOnly)
                )
                expect(presenter.presentedMessages.count).toEventually(equal(0), timeout: .seconds(2))

                Exponea.shared.isAppForeground = true
                manager.applicationDidBecomeActive()
                expect(presenter.presentedMessages.count).toEventually(equal(1), timeout: .seconds(5))
            }
            it("replays session_start when foreground is set before queued session_start is processed") {
                seedSessionStartMessageCache()

                Exponea.shared.isAppForeground = false
                manager.onEventOccurred(
                    of: .sessionStart,
                    for: productionSessionStartEvent(customerIds: customer1)
                )
                Exponea.shared.isAppForeground = true
                manager.applicationDidBecomeActive()
                expect(presenter.presentedMessages.count).toEventually(equal(1), timeout: .seconds(5))
            }
            it("processes a new session_start after background following an earlier foreground session_start") {
                seedSessionStartMessageCache()

                Exponea.shared.isAppForeground = true
                manager.onEventOccurred(
                    of: .sessionStart,
                    for: productionSessionStartEvent(customerIds: customer1)
                )
                expect(presenter.presentedMessages.count).toEventually(equal(1), timeout: .seconds(5))

                Exponea.shared.isAppForeground = false
                manager.applicationDidEnterBackground()
                Exponea.shared.isAppForeground = true
                manager.onEventOccurred(
                    of: .sessionStart,
                    for: productionSessionStartEvent(customerIds: customer1)
                )
                expect(presenter.presentedMessages.count).toEventually(equal(2), timeout: .seconds(5))
            }
            it("does not lose a session_start replay after an unrelated identify call left the app in background") {
                // An identifyCustomer() that hits the top-level foreground guard must not leave
                // isIdentifyFlowInProcess stuck true (it never sets the flag on that path). Deferred
                // session_start must still replay on become-active.
                seedSessionStartMessageCache()

                Exponea.shared.isAppForeground = false
                manager.onEventOccurred(of: .identifyCustomer, for: [.customerIds(customer1)])
                manager.onEventOccurred(
                    of: .sessionStart,
                    for: productionSessionStartEvent(customerIds: customer1)
                )
                expect(presenter.presentedMessages.count).toEventually(equal(0), timeout: .seconds(2))

                Exponea.shared.isAppForeground = true
                manager.applicationDidBecomeActive()
                expect(presenter.presentedMessages.count).toEventually(equal(1), timeout: .seconds(5))
            }
            it("does not lose a session_start replay after an identify mid-flow backgrounds") {
                // Identify passes the top-level guard (foreground), then backgrounds before fetch
                // completes so the mid-flow guard resets isIdentifyFlowInProcess. Pending
                // session_start must still replay on the next become-active.
                seedSessionStartMessageCache()

                Exponea.shared.isAppForeground = false
                manager.onEventOccurred(
                    of: .sessionStart,
                    for: productionSessionStartEvent(customerIds: customer1)
                )
                expect(presenter.presentedMessages.count).toEventually(equal(0), timeout: .seconds(2))

                let fetchStarted = DispatchSemaphore(value: 0)
                repository.onFetchInAppMessagesStarted = {
                    fetchStarted.signal()
                }
                repository.fetchInAppMessagesDelay = 0.5
                Exponea.shared.isAppForeground = true
                manager.onEventOccurred(of: .identifyCustomer, for: [.customerIds(customer1)])
                // Deterministically wait until identify has passed the top-level guard, set
                // identify-in-process and actually started the (delayed) fetch, then background
                // before it completes so the mid-flow guard aborts cleanly.
                let didStartFetch = fetchStarted.wait(timeout: .now() + 2) == .success
                expect(didStartFetch).to(beTrue())
                repository.onFetchInAppMessagesStarted = nil
                Exponea.shared.isAppForeground = false

                expect(presenter.presentedMessages.count).toEventually(equal(0), timeout: .seconds(3))

                repository.fetchInAppMessagesDelay = 0
                Exponea.shared.isAppForeground = true
                manager.applicationDidBecomeActive()
                expect(presenter.presentedMessages.count).toEventually(equal(1), timeout: .seconds(5))
            }
            it("retries session_start replay after a failed fetch when app becomes active again") {
                Exponea.shared.isAppForeground = false
                manager.onEventOccurred(
                    of: .sessionStart,
                    for: productionSessionStartEvent(customerIds: customer1)
                )
                expect(presenter.presentedMessages.count).toEventually(equal(0), timeout: .seconds(2))

                // Force shouldReload + failing fetch so replay claims pending then fails.
                cache.setInAppMessagesTimestamp(0)
                repository.fetchInAppMessagesResult = Result.failure(RepositoryError.connectionError)

                Exponea.shared.isAppForeground = true
                manager.applicationDidBecomeActive()
                expect(presenter.presentedMessages.count).toEventually(equal(0), timeout: .seconds(3))

                seedSessionStartMessageCache()
                let message = SampleInAppMessage.getSampleInAppMessage()
                repository.fetchInAppMessagesResult = Result.success(
                    InAppMessagesResponse(success: true, data: [message])
                )
                manager.applicationDidBecomeActive()
                expect(presenter.presentedMessages.count).toEventually(equal(1), timeout: .seconds(5))
            }
            it("processes session_start after anonymize when replay dedupe flag was set") {
                seedSessionStartMessageCache()

                Exponea.shared.isAppForeground = false
                manager.onEventOccurred(
                    of: .sessionStart,
                    for: productionSessionStartEvent(customerIds: customer1)
                )
                expect(presenter.presentedMessages.count).toEventually(equal(0), timeout: .seconds(2))

                Exponea.shared.isAppForeground = true
                manager.applicationDidBecomeActive()
                expect(presenter.presentedMessages.count).toEventually(equal(1), timeout: .seconds(5))

                manager.anonymize()
                expect(presenter.presentedMessages.count).toEventually(equal(1), timeout: .seconds(5))

                seedSessionStartMessageCache()

                manager.onEventOccurred(
                    of: .sessionStart,
                    for: productionSessionStartEvent(customerIds: customer1)
                )
                expect(presenter.presentedMessages.count).toEventually(equal(2), timeout: .seconds(5))
            }
        }

        describe("IdentifyFlowWorkQueue") {
            it("processes enqueued work in FIFO submission order") {
                waitUntil(timeout: .seconds(5)) { done in
                    Task {
                        let queue = IdentifyFlowWorkQueue()
                        var observedOrder: [Int] = []
                        let orderLock = NSLock()
                        let itemCount = 30

                        for index in 0..<itemCount {
                            queue.enqueue {
                                orderLock.lock()
                                observedOrder.append(index)
                                orderLock.unlock()
                                try? await Task.sleep(nanoseconds: 100_000)
                            }
                        }

                        for _ in 0..<100 {
                            orderLock.lock()
                            let count = observedOrder.count
                            orderLock.unlock()
                            if count == itemCount {
                                break
                            }
                            try? await Task.sleep(nanoseconds: 50_000_000)
                        }

                        orderLock.lock()
                        let result = observedOrder
                        orderLock.unlock()
                        expect(result).to(equal(Array(0..<itemCount)))
                        done()
                    }
                }
            }

            it("preserves FIFO submission order under concurrent enqueue") {
                waitUntil(timeout: .seconds(5)) { done in
                    Task {
                        let queue = IdentifyFlowWorkQueue()
                        var expectedSubmissionOrder: [Int] = []
                        var observedExecutionOrder: [Int] = []
                        let orderLock = NSLock()
                        let submitLock = NSLock()
                        let itemCount = 50

                        await withTaskGroup(of: Void.self) { group in
                            for _ in 0..<itemCount {
                                group.addTask {
                                    submitLock.lock()
                                    let submissionSequence = expectedSubmissionOrder.count
                                    expectedSubmissionOrder.append(submissionSequence)
                                    queue.enqueue {
                                        orderLock.lock()
                                        observedExecutionOrder.append(submissionSequence)
                                        orderLock.unlock()
                                    }
                                    submitLock.unlock()
                                }
                            }
                        }

                        for _ in 0..<100 {
                            orderLock.lock()
                            let count = observedExecutionOrder.count
                            orderLock.unlock()
                            if count == itemCount {
                                break
                            }
                            try? await Task.sleep(nanoseconds: 50_000_000)
                        }

                        orderLock.lock()
                        let expected = expectedSubmissionOrder
                        let observed = observedExecutionOrder
                        orderLock.unlock()
                        expect(observed).to(equal(expected))
                        done()
                    }
                }
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

            it("should exclude messages whose image preload fails from priority filter") {
                // Regression test for bug where messages.filter was used instead of
                // messagesWithImage.filter, causing failed-preload messages to be included
                // when their priority equalled or exceeded the highest successfully-preloaded priority.
                let lowPriorityMessage = SampleInAppMessage.getSampleInAppMessage(
                    id: "low-priority-cached",
                    priority: 3
                )
                let cachedImageUrl = lowPriorityMessage.oldPayload!.imageUrl!
                // Uses a URL that fails URL parsing so preload fails without a network request.
                let highPriorityMessage = SampleInAppMessage.getSampleInAppMessage(
                    id: "high-priority-preload-fails",
                    imageUrl: " ",
                    priority: 5
                )
                cache.saveInAppMessages(inAppMessages: [highPriorityMessage, lowPriorityMessage])
                // Only the low-priority message has its image in the cache.
                cache.saveImageData(at: cachedImageUrl, data: "mock data".data(using: .utf8)!)
                // The high-priority message must not appear in the result, even though its
                // priority (5) exceeds the highest successfully-preloaded priority (3).
                expect(
                    manager.loadMessagesToShow(for: [.eventType("session_start")])
                ).to(equal([lowPriorityMessage]))
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

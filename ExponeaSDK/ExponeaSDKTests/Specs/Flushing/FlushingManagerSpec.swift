//
//  FlushingManagerSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 13/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import CoreData
import Foundation
import Nimble
import Mockingjay
import Quick

@testable import ExponeaSDK
@testable import ExponeaSDKShared

/// Wraps a DatabaseManagerType and optionally throws on `delete` calls.
/// Used to test graceful degradation when database deletion fails.
private class ThrowingDeleteDatabaseWrapper: DatabaseManagerType {
    let wrapped: DatabaseManagerType
    var shouldThrowOnDelete = false

    init(_ wrapped: DatabaseManagerType) {
        self.wrapped = wrapped
    }

    var currentCustomer: CustomerThreadSafe { wrapped.currentCustomer }
    var customers: [CustomerThreadSafe] { wrapped.customers }

    func trackEvent(with data: [DataType], into project: any ExponeaIntegrationType) throws {
        try wrapped.trackEvent(with: data, into: project)
    }
    func identifyCustomer(with data: [DataType], into project: any ExponeaIntegrationType) throws {
        try wrapped.identifyCustomer(with: data, into: project)
    }
    func updateEvent(withId id: NSManagedObjectID, withData data: DataType) throws {
        try wrapped.updateEvent(withId: id, withData: data)
    }
    func fetchTrackCustomer() throws -> [TrackCustomerProxy] {
        try wrapped.fetchTrackCustomer()
    }
    func countTrackCustomer() throws -> Int {
        try wrapped.countTrackCustomer()
    }
    func fetchTrackEvent() throws -> [TrackEventProxy] {
        try wrapped.fetchTrackEvent()
    }
    func countTrackEvent() throws -> Int {
        try wrapped.countTrackEvent()
    }
    func fetchCustomer(_ uuid: UUID) throws -> Customer? {
        try wrapped.fetchCustomer(uuid)
    }
    func addRetry(_ object: DatabaseObjectProxy) throws {
        try wrapped.addRetry(object)
    }
    func delete(_ object: DatabaseObjectProxy) throws {
        if shouldThrowOnDelete {
            throw NSError(domain: "MockDB", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock delete error"])
        }
        try wrapped.delete(object)
    }
    func makeNewCustomer() {
        wrapped.makeNewCustomer()
    }
    func removeAllEvents() {
        wrapped.removeAllEvents()
    }
}

/// Overrides the resolved TrackingObject with a custom factory, allowing tests to control
/// the exact type (Customer vs Event), customerIds, dataTypes, and project.
private class CustomFlushableWrapper: FlushableObject {
    let databaseObjectProxy: DatabaseObjectProxy
    private let wrapped: FlushableObject
    private let trackingObjectFactory: (any TrackingObject) -> any TrackingObject

    init(
        wrapping object: FlushableObject,
        trackingObjectFactory: @escaping (any TrackingObject) -> any TrackingObject
    ) {
        self.databaseObjectProxy = object.databaseObjectProxy
        self.wrapped = object
        self.trackingObjectFactory = trackingObjectFactory
    }

    func getTrackingObject(
        defaultBaseUrl: String,
        defaultIntegrationId: String,
        defaultAuthorization: Authorization
    ) -> TrackingObject {
        let original = wrapped.getTrackingObject(
            defaultBaseUrl: defaultBaseUrl,
            defaultIntegrationId: defaultIntegrationId,
            defaultAuthorization: defaultAuthorization
        )
        return trackingObjectFactory(original)
    }

    static func customer(
        wrapping object: FlushableObject,
        customerIds: [String: String],
        dataTypes: [DataType],
        project: (any ExponeaIntegrationType)? = nil
    ) -> CustomFlushableWrapper {
        CustomFlushableWrapper(wrapping: object) { original in
            CustomerTrackingObject(
                exponeaProject: project ?? original.exponeaProject,
                customerIds: customerIds,
                timestamp: original.timestamp,
                dataTypes: dataTypes
            )
        }
    }

    static func event(
        wrapping object: FlushableObject,
        customerIds: [String: String],
        dataTypes: [DataType],
        project: (any ExponeaIntegrationType)? = nil
    ) -> CustomFlushableWrapper {
        CustomFlushableWrapper(wrapping: object) { original in
            EventTrackingObject(
                exponeaProject: project ?? original.exponeaProject,
                customerIds: customerIds,
                eventType: nil,
                timestamp: original.timestamp,
                dataTypes: dataTypes
            )
        }
    }
}

private class EmptyCustomerIdsFlushableWrapper: FlushableObject {
    let databaseObjectProxy: DatabaseObjectProxy
    private let wrapped: FlushableObject

    init(wrapping object: FlushableObject) {
        self.databaseObjectProxy = object.databaseObjectProxy
        self.wrapped = object
    }

    func getTrackingObject(
        defaultBaseUrl: String,
        defaultIntegrationId: String,
        defaultAuthorization: Authorization
    ) -> TrackingObject {
        let original = wrapped.getTrackingObject(
            defaultBaseUrl: defaultBaseUrl,
            defaultIntegrationId: defaultIntegrationId,
            defaultAuthorization: defaultAuthorization
        )
        return EventTrackingObject(
            exponeaProject: original.exponeaProject,
            customerIds: [:],
            eventType: nil,
            timestamp: original.timestamp,
            dataTypes: original.dataTypes
        )
    }
}

class FlushingManagerSpec: QuickSpec {
    override func spec() {
        describe("FlushingManager") {
            let configurations = TestConfigParams.configurationsForFlushing
            for testConfiguration in configurations {
                context(testConfiguration.integrationConfig.type.rawValue) {
                    runFlushingTests(for: testConfiguration)
                }
            }
        }
        
        func runFlushingTests(for testConfiguration: Configuration) {
            var flushingManager: FlushingManager!
            var repository: RepositoryType!
            var database: MockDatabaseManager!
            var configuration: ExponeaSDK.Configuration!
            
            var eventData: [DataType]!
            
            beforeEach {
                IntegrationManager.shared.isStopped = false
                configuration = testConfiguration
                configuration.automaticSessionTracking = false
                configuration.flushEventMaxRetries = 5
                repository = ServerRepository(configuration: configuration)
                database = try! MockDatabaseManager()
                
                flushingManager = try! FlushingManager(
                    database: database,
                    repository: repository,
                    customerIdentifiedHandler: {}
                )
                
                eventData = [.properties(MockData().properties)]
            }
            
            afterEach {
                NetworkStubbing.unstubNetwork()
            }
            
            it("should only allow one thread to flush") {
                try! database.trackEvent(with: eventData, into: configuration.mainProject)
                
                var networkRequests: Int = 0
                NetworkStubbing.stubNetwork(
                    forIntegrationType: configuration.integrationConfig.type,
                    withStatusCode: 200,
                    withRequestHook: { _ in
                        networkRequests += 1
                    }
                )
                // first approach
                waitUntil(timeout: .seconds(3)) { done in
                    let group = DispatchGroup()
                    for _ in 0..<10 {
                        group.enter()
                        DispatchQueue.global(qos: .background).async {
                            flushingManager.flushData(completion: { _ in group.leave() })
                        }
                    }
                    group.notify(queue: .main, execute: done)
                }
                expect(networkRequests).to(equal(1))
                // second approach
                networkRequests = 0
                try! database.trackEvent(with: eventData, into: configuration.mainProject)
                for i in 0...100 {
                    DispatchQueue.global().async {
                        flushingManager.flushData(isFromIdentify: true)
                    }
                }
                Thread.sleep(forTimeInterval: 1)
                expect(networkRequests).to(equal(1))
            }
            
            it("should flush event") {
                try! database.trackEvent(with: eventData, into: configuration.mainProject)
                NetworkStubbing.stubNetwork(
                    forIntegrationType: configuration.integrationConfig.type,
                    withStatusCode: 200
                )
                waitUntil(timeout: .seconds(5)) { done in
                    flushingManager.flushData(completion: { _ in done() })
                }
                expect { try database.fetchTrackEvent().count }.to(equal(0))
            }
            
            it("should retry flushing event `configuration.flushEventMaxRetries` times on weird errors") {
                try! database.trackEvent(with: eventData, into: configuration.mainProject)
                NetworkStubbing.stubNetwork(
                    forIntegrationType: configuration.integrationConfig.type,
                    withStatusCode: 418
                )
                for attempt in 1...4 {
                    waitUntil(timeout: .seconds(5)) { done in
                        flushingManager.flushData(completion: { _ in done() })
                    }
                    expect { try database.fetchTrackEvent().count }.to(equal(1))
                    expect { try database.fetchTrackEvent().first?.databaseObjectProxy.retries }.to(equal(attempt))
                }
                waitUntil(timeout: .seconds(5)) { done in
                    flushingManager.flushData(completion: { _ in done() })
                }
                expect { try database.fetchTrackEvent().count }.to(equal(0))
            }
            
            it("should retry flushing event forever on 500 errors") {
                try! database.trackEvent(with: eventData, into: configuration.mainProject)
                NetworkStubbing.stubNetwork(
                    forIntegrationType: configuration.integrationConfig.type,
                    withStatusCode: 500
                )
                for _ in 1...10 {
                    waitUntil(timeout: .seconds(5)) { done in
                        flushingManager.flushData(completion: { _ in done() })
                    }
                    expect { try database.fetchTrackEvent().count }.to(equal(1))
                }
            }
            context("flushing order") {
                func checkFlushOrder() {
                    waitUntil(timeout: .seconds(5)) { done in
                        var id = 1
                        NetworkStubbing.stubNetwork(
                            forIntegrationType: configuration.integrationConfig.type,
                            withStatusCode: 200,
                            withDelay: 0,
                            withResponseData: nil,
                            withRequestHook: { request in
                                let payload = try! JSONSerialization.jsonObject(
                                    with: request.httpBodyStream!.readFully(),
                                    options: []
                                ) as? NSDictionary ?? NSDictionary()
                                let properties = payload["properties"] as? NSDictionary
                                expect(properties?["id"] as? Int).to(equal(id))
                                id += 1
                                if id == 6 {
                                    done()
                                }
                            }
                        )
                        flushingManager.flushData()
                    }
                }
                
                it("should flush customer updates in correct order") {
                    for id in 1...5 {
                        try! database.identifyCustomer(
                            with: [.properties(["id": .int(id)])],
                            into: configuration.mainProject
                        )
                    }
                    checkFlushOrder()
                }
                
                it("should flush events in correct order") {
                    for id in 1...5 {
                        try! database.trackEvent(
                            with: [.properties(["id": .int(id)])],
                            into: configuration.mainProject
                        )
                    }
                    checkFlushOrder()
                }
            }
            
            it("should track age for events") {
                let eventData: [DataType] = [
                    .timestamp(Date().timeIntervalSince1970 - 1),
                    .properties(["customprop": .string("customval")]),
                    .eventType(Constants.EventTypes.sessionStart),
                    .pushNotificationToken(token: "tokenthatisgoingtobeignored", authorized: true)
                ]
                try! database.trackEvent(
                    with: eventData,
                    into: configuration.mainProject
                )
                waitUntil(timeout: .seconds(5)) { done in
                    NetworkStubbing.stubNetwork(
                        forIntegrationType: configuration.integrationConfig.type,
                        withStatusCode: 200,
                        withDelay: 0,
                        withResponseData: nil,
                        withRequestHook: { request in
                            let payload = try! JSONSerialization.jsonObject(
                                with: request.httpBodyStream!.readFully(),
                                options: []
                            ) as? NSDictionary ?? NSDictionary()
                            expect(payload["timestamp"] as? Double).notTo(beNil())
                            expect(payload["timestamp"] as? Double).to(beGreaterThan(0))
                            done()
                        }
                    )
                    flushingManager.flushData()
                }
            }
            
            it("should track timestamp for push events") {
                let timestamp = Date().timeIntervalSince1970
                let eventData: [DataType] = [
                    .timestamp(timestamp),
                    .properties(["customprop": .string("customval")]),
                    .eventType(Constants.EventTypes.pushOpen),
                    .pushNotificationToken(token: "tokenthatisgoingtobeignored", authorized: true)
                ]
                try! database.trackEvent(
                    with: eventData,
                    into: configuration.mainProject
                )
                waitUntil(timeout: .seconds(5)) { done in
                    NetworkStubbing.stubNetwork(
                        forIntegrationType: configuration.integrationConfig.type,
                        withStatusCode: 200,
                        withDelay: 0,
                        withResponseData: nil,
                        withRequestHook: { request in
                            let payload = try! JSONSerialization.jsonObject(
                                with: request.httpBodyStream!.readFully(),
                                options: []
                            ) as? NSDictionary ?? NSDictionary()
                            expect(payload["timestamp"] as? Double).notTo(beNil())
                            expect(payload["timestamp"] as? Double).to(equal(timestamp))
                            done()
                        }
                    )
                    flushingManager.flushData()
                }
            }
            
            it("should invoke inAppRefreshCallback when isFromIdentify is true and database is empty") {
                var inAppRefreshCallbackInvoked = false
                flushingManager.inAppRefreshCallback = {
                    inAppRefreshCallbackInvoked = true
                }
                waitUntil(timeout: .seconds(5)) { done in
                    NetworkStubbing.stubNetwork(
                        forIntegrationType: configuration.integrationConfig.type,
                        withStatusCode: 200
                    )
                    flushingManager.flushData(isFromIdentify: true, completion: { _ in done() })
                }
                expect(inAppRefreshCallbackInvoked).to(beTrue())
            }
            
            it("should invoke inAppRefreshCallback when isFromIdentify is true and database contains event") {
                var inAppRefreshCallbackInvoked = false
                flushingManager.inAppRefreshCallback = {
                    inAppRefreshCallbackInvoked = true
                }
                try! database.trackEvent(with: eventData, into: configuration.mainProject)
                waitUntil(timeout: .seconds(5)) { done in
                    NetworkStubbing.stubNetwork(
                        forIntegrationType: configuration.integrationConfig.type,
                        withStatusCode: 200
                    )
                    flushingManager.flushData(isFromIdentify: true, completion: { _ in done() })
                }
                expect(inAppRefreshCallbackInvoked).to(beTrue())
            }
            
            it("should invoke inAppRefreshCallback when isFromIdentify is true and database contains customer update event") {
                var inAppRefreshCallbackInvoked = false
                flushingManager.inAppRefreshCallback = {
                    inAppRefreshCallbackInvoked = true
                }
                try! database.identifyCustomer(with: [.properties(["id": .int(1)])], into: configuration.mainProject)
                waitUntil(timeout: .seconds(5)) { done in
                    NetworkStubbing.stubNetwork(
                        forIntegrationType: configuration.integrationConfig.type,
                        withStatusCode: 200
                    )
                    flushingManager.flushData(isFromIdentify: true, completion: { _ in done() })
                }
                expect(inAppRefreshCallbackInvoked).to(beTrue())
            }
            
            it("shouldn't invoke inAppRefreshCallback when isFromIdentify is false and database is empty") {
                var inAppRefreshCallbackInvoked = false
                flushingManager.inAppRefreshCallback = {
                    inAppRefreshCallbackInvoked = true
                }
                waitUntil(timeout: .seconds(5)) { done in
                    NetworkStubbing.stubNetwork(
                        forIntegrationType: configuration.integrationConfig.type,
                        withStatusCode: 200
                    )
                    flushingManager.flushData(isFromIdentify: false, completion: { _ in done() })
                }
                expect(inAppRefreshCallbackInvoked).to(beFalse())
            }
            
            it("shouldn't invoke inAppRefreshCallback when isFromIdentify is false and database contains event") {
                var inAppRefreshCallbackInvoked = false
                flushingManager.inAppRefreshCallback = {
                    inAppRefreshCallbackInvoked = true
                }
                try! database.trackEvent(with: eventData, into: configuration.mainProject)
                waitUntil(timeout: .seconds(5)) { done in
                    NetworkStubbing.stubNetwork(
                        forIntegrationType: configuration.integrationConfig.type,
                        withStatusCode: 200
                    )
                    flushingManager.flushData(isFromIdentify: false, completion: { _ in done() })
                }
                expect(inAppRefreshCallbackInvoked).to(beFalse())
            }
            
            it("should invoke inAppRefreshCallback when isFromIdentify is false and database contains customer update event") {
                var inAppRefreshCallbackInvoked = false
                flushingManager.inAppRefreshCallback = {
                    inAppRefreshCallbackInvoked = true
                }
                try! database.identifyCustomer(with: [.properties(["id": .int(1)])], into: configuration.mainProject)
                waitUntil(timeout: .seconds(5)) { done in
                    NetworkStubbing.stubNetwork(
                        forIntegrationType: configuration.integrationConfig.type,
                        withStatusCode: 200
                    )
                    flushingManager.flushData(isFromIdentify: false, completion: { _ in done() })
                }
                expect(inAppRefreshCallbackInvoked).to(beTrue())
            }

            context("flushTrackingObjects") {
                it("should complete with success(0) for empty array") {
                    waitUntil(timeout: .seconds(5)) { done in
                        flushingManager.flushTrackingObjects([]) { result in
                            guard case .success(let count) = result else {
                                fail("Expected .success result")
                                done()
                                return
                            }
                            expect(count).to(equal(0))
                            done()
                        }
                    }
                }

                it("should complete with success(1) and delete event after single successful flush") {
                    try! database.trackEvent(with: eventData, into: configuration.mainProject)
                    let events: [FlushableObject] = try! database.fetchTrackEvent()
                    expect(events.count).to(equal(1))
                    NetworkStubbing.stubNetwork(
                        forIntegrationType: configuration.integrationConfig.type,
                        withStatusCode: 200
                    )
                    waitUntil(timeout: .seconds(5)) { done in
                        flushingManager.flushTrackingObjects(events) { result in
                            guard case .success(let count) = result else {
                                fail("Expected .success result")
                                done()
                                return
                            }
                            expect(count).to(equal(1))
                            done()
                        }
                    }
                    expect { try database.fetchTrackEvent().count }.to(equal(0))
                }

                it("should complete with success(N) for multiple events") {
                    for _ in 1...3 {
                        try! database.trackEvent(with: eventData, into: configuration.mainProject)
                    }
                    let events: [FlushableObject] = try! database.fetchTrackEvent()
                    expect(events.count).to(equal(3))
                    NetworkStubbing.stubNetwork(
                        forIntegrationType: configuration.integrationConfig.type,
                        withStatusCode: 200
                    )
                    waitUntil(timeout: .seconds(5)) { done in
                        flushingManager.flushTrackingObjects(events) { result in
                            guard case .success(let count) = result else {
                                fail("Expected .success result")
                                done()
                                return
                            }
                            expect(count).to(equal(3))
                            done()
                        }
                    }
                    expect { try database.fetchTrackEvent().count }.to(equal(0))
                }

                it("should not increase retry on server error") {
                    try! database.trackEvent(with: eventData, into: configuration.mainProject)
                    let events: [FlushableObject] = try! database.fetchTrackEvent()
                    NetworkStubbing.stubNetwork(
                        forIntegrationType: configuration.integrationConfig.type,
                        withStatusCode: 500
                    )
                    waitUntil(timeout: .seconds(5)) { done in
                        flushingManager.flushTrackingObjects(events) { result in
                            guard case .success(let count) = result else {
                                fail("Expected .success result")
                                done()
                                return
                            }
                            expect(count).to(equal(0))
                            done()
                        }
                    }
                    expect { try database.fetchTrackEvent().count }.to(equal(1))
                    expect { try database.fetchTrackEvent().first?.databaseObjectProxy.retries }.to(equal(0))
                }

                it("should increase retry on non-connection error") {
                    try! database.trackEvent(with: eventData, into: configuration.mainProject)
                    let events: [FlushableObject] = try! database.fetchTrackEvent()
                    NetworkStubbing.stubNetwork(
                        forIntegrationType: configuration.integrationConfig.type,
                        withStatusCode: 418
                    )
                    waitUntil(timeout: .seconds(5)) { done in
                        flushingManager.flushTrackingObjects(events) { result in
                            guard case .success(let count) = result else {
                                fail("Expected .success result")
                                done()
                                return
                            }
                            expect(count).to(equal(0))
                            done()
                        }
                    }
                    expect { try database.fetchTrackEvent().count }.to(equal(1))
                    expect { try database.fetchTrackEvent().first?.databaseObjectProxy.retries }.to(equal(1))
                }

                it("should invoke customerIdentifiedHandler and inAppRefreshCallback on successful customer flush") {
                    var customerIdentifiedInvoked = false
                    var inAppRefreshInvoked = false
                    let localFlushingManager = try! FlushingManager(
                        database: database,
                        repository: repository,
                        customerIdentifiedHandler: { customerIdentifiedInvoked = true }
                    )
                    localFlushingManager.inAppRefreshCallback = { inAppRefreshInvoked = true }
                    try! database.identifyCustomer(
                        with: [.properties(["id": .int(1)])],
                        into: configuration.mainProject
                    )
                    let customers: [FlushableObject] = try! database.fetchTrackCustomer()
                    expect(customers.count).to(equal(1))
                    NetworkStubbing.stubNetwork(
                        forIntegrationType: configuration.integrationConfig.type,
                        withStatusCode: 200
                    )
                    waitUntil(timeout: .seconds(5)) { done in
                        localFlushingManager.flushTrackingObjects(customers) { result in
                            guard case .success(let count) = result else {
                                fail("Expected .success result")
                                done()
                                return
                            }
                            expect(count).to(equal(1))
                            done()
                        }
                    }
                    expect(customerIdentifiedInvoked).to(beTrue())
                    expect(inAppRefreshInvoked).to(beTrue())
                }

                it("should not crash when completion is nil") {
                    try! database.trackEvent(with: eventData, into: configuration.mainProject)
                    let events: [FlushableObject] = try! database.fetchTrackEvent()
                    NetworkStubbing.stubNetwork(
                        forIntegrationType: configuration.integrationConfig.type,
                        withStatusCode: 200
                    )
                    flushingManager.flushTrackingObjects(events, completion: nil)
                    expect { try database.fetchTrackEvent().count }
                        .toEventually(equal(0), timeout: .seconds(5))
                }

                it("should flush mixed events and customer updates") {
                    try! database.trackEvent(with: eventData, into: configuration.mainProject)
                    try! database.trackEvent(with: eventData, into: configuration.mainProject)
                    try! database.identifyCustomer(
                        with: [.properties(["id": .int(1)])],
                        into: configuration.mainProject
                    )
                    let events: [FlushableObject] = try! database.fetchTrackEvent()
                    let customers: [FlushableObject] = try! database.fetchTrackCustomer()
                    let allObjects = customers + events
                    expect(allObjects.count).to(equal(3))
                    NetworkStubbing.stubNetwork(
                        forIntegrationType: configuration.integrationConfig.type,
                        withStatusCode: 200
                    )
                    waitUntil(timeout: .seconds(5)) { done in
                        flushingManager.flushTrackingObjects(allObjects) { result in
                            guard case .success(let count) = result else {
                                fail("Expected .success result")
                                done()
                                return
                            }
                            expect(count).to(equal(3))
                            done()
                        }
                    }
                    expect { try database.fetchTrackEvent().count }.to(equal(0))
                    expect { try database.fetchTrackCustomer().count }.to(equal(0))
                }

                it("should report only successful count when some objects fail") {
                    for _ in 1...3 {
                        try! database.trackEvent(with: eventData, into: configuration.mainProject)
                    }
                    let events: [FlushableObject] = try! database.fetchTrackEvent()
                    expect(events.count).to(equal(3))

                    let mockRepository = MockRepository(configuration: configuration)
                    mockRepository.trackObjectResult = .success
                    var callCount = 0
                    mockRepository.trackObjectHook = { _ in
                        callCount += 1
                        if callCount == 3 {
                            mockRepository.trackObjectResult = .failure(.connectionError)
                        }
                    }

                    let localFlushingManager = try! FlushingManager(
                        database: database,
                        repository: mockRepository,
                        customerIdentifiedHandler: {}
                    )
                    waitUntil(timeout: .seconds(5)) { done in
                        localFlushingManager.flushTrackingObjects(events) { result in
                            guard case .success(let count) = result else {
                                fail("Expected .success result")
                                done()
                                return
                            }
                            expect(count).to(equal(2))
                            done()
                        }
                    }
                    expect { try database.fetchTrackEvent().count }.to(equal(1))
                }

                it("should skip all objects with empty customerIds and return success(0)") {
                    try! database.trackEvent(with: eventData, into: configuration.mainProject)
                    try! database.trackEvent(with: eventData, into: configuration.mainProject)
                    let events = try! database.fetchTrackEvent()
                    let emptyIdObjects: [FlushableObject] = events.map {
                        EmptyCustomerIdsFlushableWrapper(wrapping: $0)
                    }
                    let requestCountLock = NSLock()
                    var networkRequests = 0
                    NetworkStubbing.stubNetwork(
                        forIntegrationType: configuration.integrationConfig.type,
                        withStatusCode: 200,
                        withRequestHook: { _ in requestCountLock.withLock { networkRequests += 1 } }
                    )
                    waitUntil(timeout: .seconds(5)) { done in
                        flushingManager.flushTrackingObjects(emptyIdObjects) { result in
                            guard case .success(let count) = result else {
                                fail("Expected .success result")
                                done()
                                return
                            }
                            expect(count).to(equal(0))
                            done()
                        }
                    }
                    expect(networkRequests).to(equal(0))
                    expect { try database.fetchTrackEvent().count }.to(equal(2))
                }

                it("should only flush objects with non-empty customerIds in a mixed batch") {
                    for _ in 1...3 {
                        try! database.trackEvent(with: eventData, into: configuration.mainProject)
                    }
                    let events = try! database.fetchTrackEvent()
                    let mixedObjects: [FlushableObject] = [
                        EmptyCustomerIdsFlushableWrapper(wrapping: events[0]),
                        events[1],
                        events[2]
                    ]
                    let requestCountLock = NSLock()
                    var networkRequests = 0
                    NetworkStubbing.stubNetwork(
                        forIntegrationType: configuration.integrationConfig.type,
                        withStatusCode: 200,
                        withRequestHook: { _ in requestCountLock.withLock { networkRequests += 1 } }
                    )
                    waitUntil(timeout: .seconds(5)) { done in
                        flushingManager.flushTrackingObjects(mixedObjects) { result in
                            guard case .success(let count) = result else {
                                fail("Expected .success result")
                                done()
                                return
                            }
                            expect(count).to(equal(2))
                            done()
                        }
                    }
                    expect(networkRequests).to(equal(2))
                    expect { try database.fetchTrackEvent().count }.to(equal(1))
                }
            }

            // MARK: - Empty customer update filtering (stream mode)

            context("empty customer update filtering") {
                let streamProject = ExponeaIntegration(
                    baseUrl: "https://google.com/",
                    streamId: "test-stream-id"
                )
                let projectProject = ExponeaProject(
                    baseUrl: "https://google.com/",
                    projectToken: "test-project-token",
                    authorization: .token("mock-token")
                )

                it("should skip empty customer update with only cookie in stream mode") {
                    try! database.identifyCustomer(
                        with: [.properties(["id": .int(1)])],
                        into: configuration.mainProject
                    )
                    let customers = try! database.fetchTrackCustomer()
                    let wrapped: [FlushableObject] = customers.map {
                        CustomFlushableWrapper.customer(
                            wrapping: $0,
                            customerIds: ["cookie": "test-uuid"],
                            dataTypes: [.properties([:])],
                            project: streamProject
                        )
                    }
                    let mockRepo = MockRepository(configuration: configuration)
                    mockRepo.trackObjectResult = .success
                    var trackedObjects: [TrackingObject] = []
                    mockRepo.trackObjectHook = { trackedObjects.append($0) }
                    let localFlushingManager = try! FlushingManager(
                        database: database,
                        repository: mockRepo,
                        customerIdentifiedHandler: {}
                    )
                    waitUntil(timeout: .seconds(5)) { done in
                        localFlushingManager.flushTrackingObjects(wrapped) { result in
                            guard case .success(let count) = result else {
                                fail("Expected .success result")
                                done()
                                return
                            }
                            expect(count).to(equal(0))
                            done()
                        }
                    }
                    expect(trackedObjects).to(beEmpty())
                    expect { try database.fetchTrackCustomer().count }.to(equal(0))
                }

                it("should send customer update with trusted ID in stream mode") {
                    try! database.identifyCustomer(
                        with: [.properties(["id": .int(1)])],
                        into: configuration.mainProject
                    )
                    let customers = try! database.fetchTrackCustomer()
                    let wrapped: [FlushableObject] = customers.map {
                        CustomFlushableWrapper.customer(
                            wrapping: $0,
                            customerIds: ["cookie": "test-uuid", "registered": "user@example.com"],
                            dataTypes: [.properties([:])],
                            project: streamProject
                        )
                    }
                    let mockRepo = MockRepository(configuration: configuration)
                    mockRepo.trackObjectResult = .success
                    var trackedObjects: [TrackingObject] = []
                    mockRepo.trackObjectHook = { trackedObjects.append($0) }
                    let localFlushingManager = try! FlushingManager(
                        database: database,
                        repository: mockRepo,
                        customerIdentifiedHandler: {}
                    )
                    waitUntil(timeout: .seconds(5)) { done in
                        localFlushingManager.flushTrackingObjects(wrapped) { result in
                            guard case .success(let count) = result else {
                                fail("Expected .success result")
                                done()
                                return
                            }
                            expect(count).to(equal(1))
                            done()
                        }
                    }
                    expect(trackedObjects.count).to(equal(1))
                }

                it("should send cookie-only customer update with non-empty properties in stream mode") {
                    try! database.identifyCustomer(
                        with: [.properties(["id": .int(1)])],
                        into: configuration.mainProject
                    )
                    let customers = try! database.fetchTrackCustomer()
                    let wrapped: [FlushableObject] = customers.map {
                        CustomFlushableWrapper.customer(
                            wrapping: $0,
                            customerIds: ["cookie": "test-uuid"],
                            dataTypes: [.properties(["first_name": .string("Alice")])],
                            project: streamProject
                        )
                    }
                    let mockRepo = MockRepository(configuration: configuration)
                    mockRepo.trackObjectResult = .success
                    var trackedObjects: [TrackingObject] = []
                    mockRepo.trackObjectHook = { trackedObjects.append($0) }
                    let localFlushingManager = try! FlushingManager(
                        database: database,
                        repository: mockRepo,
                        customerIdentifiedHandler: {}
                    )
                    waitUntil(timeout: .seconds(5)) { done in
                        localFlushingManager.flushTrackingObjects(wrapped) { result in
                            guard case .success(let count) = result else {
                                fail("Expected .success result")
                                done()
                                return
                            }
                            expect(count).to(equal(1))
                            done()
                        }
                    }
                    expect(trackedObjects.count).to(equal(1))
                }

                it("should send empty customer update in project mode (no filtering)") {
                    try! database.identifyCustomer(
                        with: [.properties(["id": .int(1)])],
                        into: configuration.mainProject
                    )
                    let customers = try! database.fetchTrackCustomer()
                    let wrapped: [FlushableObject] = customers.map {
                        CustomFlushableWrapper.customer(
                            wrapping: $0,
                            customerIds: ["cookie": "test-uuid"],
                            dataTypes: [.properties([:])],
                            project: projectProject
                        )
                    }
                    let mockRepo = MockRepository(configuration: configuration)
                    mockRepo.trackObjectResult = .success
                    var trackedObjects: [TrackingObject] = []
                    mockRepo.trackObjectHook = { trackedObjects.append($0) }
                    let localFlushingManager = try! FlushingManager(
                        database: database,
                        repository: mockRepo,
                        customerIdentifiedHandler: {}
                    )
                    waitUntil(timeout: .seconds(5)) { done in
                        localFlushingManager.flushTrackingObjects(wrapped) { result in
                            guard case .success(let count) = result else {
                                fail("Expected .success result")
                                done()
                                return
                            }
                            expect(count).to(equal(1))
                            done()
                        }
                    }
                    expect(trackedObjects.count).to(equal(1))
                }

                it("should never filter event tracking objects in stream mode") {
                    try! database.trackEvent(with: eventData, into: configuration.mainProject)
                    let events = try! database.fetchTrackEvent()
                    let wrapped: [FlushableObject] = events.map {
                        CustomFlushableWrapper.event(
                            wrapping: $0,
                            customerIds: ["cookie": "test-uuid"],
                            dataTypes: [.properties([:])],
                            project: streamProject
                        )
                    }
                    let mockRepo = MockRepository(configuration: configuration)
                    mockRepo.trackObjectResult = .success
                    var trackedObjects: [TrackingObject] = []
                    mockRepo.trackObjectHook = { trackedObjects.append($0) }
                    let localFlushingManager = try! FlushingManager(
                        database: database,
                        repository: mockRepo,
                        customerIdentifiedHandler: {}
                    )
                    waitUntil(timeout: .seconds(5)) { done in
                        localFlushingManager.flushTrackingObjects(wrapped) { result in
                            guard case .success(let count) = result else {
                                fail("Expected .success result")
                                done()
                                return
                            }
                            expect(count).to(equal(1))
                            done()
                        }
                    }
                    expect(trackedObjects.count).to(equal(1))
                }

                it("should send customer update with multiple IDs including cookie in stream mode") {
                    try! database.identifyCustomer(
                        with: [.properties(["id": .int(1)])],
                        into: configuration.mainProject
                    )
                    let customers = try! database.fetchTrackCustomer()
                    let wrapped: [FlushableObject] = customers.map {
                        CustomFlushableWrapper.customer(
                            wrapping: $0,
                            customerIds: ["cookie": "test-uuid", "external": "ext-id"],
                            dataTypes: [.properties([:])],
                            project: streamProject
                        )
                    }
                    let mockRepo = MockRepository(configuration: configuration)
                    mockRepo.trackObjectResult = .success
                    var trackedObjects: [TrackingObject] = []
                    mockRepo.trackObjectHook = { trackedObjects.append($0) }
                    let localFlushingManager = try! FlushingManager(
                        database: database,
                        repository: mockRepo,
                        customerIdentifiedHandler: {}
                    )
                    waitUntil(timeout: .seconds(5)) { done in
                        localFlushingManager.flushTrackingObjects(wrapped) { result in
                            guard case .success(let count) = result else {
                                fail("Expected .success result")
                                done()
                                return
                            }
                            expect(count).to(equal(1))
                            done()
                        }
                    }
                    expect(trackedObjects.count).to(equal(1))
                }

                it("should skip empty customer update but send companion event in stream mode") {
                    try! database.identifyCustomer(
                        with: [.properties(["id": .int(1)])],
                        into: configuration.mainProject
                    )
                    try! database.trackEvent(with: eventData, into: configuration.mainProject)
                    let customers = try! database.fetchTrackCustomer()
                    let events = try! database.fetchTrackEvent()
                    let customerWrapped = customers.map {
                        CustomFlushableWrapper.customer(
                            wrapping: $0,
                            customerIds: ["cookie": "test-uuid"],
                            dataTypes: [.properties([:])],
                            project: streamProject
                        ) as FlushableObject
                    }
                    let eventWrapped = events.map {
                        CustomFlushableWrapper.event(
                            wrapping: $0,
                            customerIds: ["cookie": "test-uuid"],
                            dataTypes: [
                                .properties([
                                    "platform": .string("ios"),
                                    "push_notification_token": .string("abc"),
                                    "valid": .bool(true)
                                ]),
                                .eventType(Constants.EventTypes.notificationState)
                            ],
                            project: streamProject
                        ) as FlushableObject
                    }
                    let allObjects = customerWrapped + eventWrapped
                    let mockRepo = MockRepository(configuration: configuration)
                    mockRepo.trackObjectResult = .success
                    var trackedObjects: [TrackingObject] = []
                    mockRepo.trackObjectHook = { trackedObjects.append($0) }
                    let localFlushingManager = try! FlushingManager(
                        database: database,
                        repository: mockRepo,
                        customerIdentifiedHandler: {}
                    )
                    waitUntil(timeout: .seconds(5)) { done in
                        localFlushingManager.flushTrackingObjects(allObjects) { result in
                            guard case .success(let count) = result else {
                                fail("Expected .success result")
                                done()
                                return
                            }
                            expect(count).to(equal(1))
                            done()
                        }
                    }
                    expect(trackedObjects.count).to(equal(1))
                    expect(trackedObjects.first).to(beAnInstanceOf(EventTrackingObject.self))
                    expect { try database.fetchTrackCustomer().count }.to(equal(0))
                }

                it("should skip push token customer update with no default properties in stream mode") {
                    try! database.identifyCustomer(
                        with: [.properties(["id": .int(1)])],
                        into: configuration.mainProject
                    )
                    let customers = try! database.fetchTrackCustomer()
                    let wrapped: [FlushableObject] = customers.map {
                        CustomFlushableWrapper.customer(
                            wrapping: $0,
                            customerIds: ["cookie": "test-uuid"],
                            dataTypes: [.properties([:])],
                            project: streamProject
                        )
                    }
                    let mockRepo = MockRepository(configuration: configuration)
                    mockRepo.trackObjectResult = .success
                    var trackedObjects: [TrackingObject] = []
                    mockRepo.trackObjectHook = { trackedObjects.append($0) }
                    let localFlushingManager = try! FlushingManager(
                        database: database,
                        repository: mockRepo,
                        customerIdentifiedHandler: {}
                    )
                    waitUntil(timeout: .seconds(5)) { done in
                        localFlushingManager.flushTrackingObjects(wrapped) { result in
                            guard case .success(let count) = result else {
                                fail("Expected .success result")
                                done()
                                return
                            }
                            expect(count).to(equal(0))
                            done()
                        }
                    }
                    expect(trackedObjects).to(beEmpty())
                    expect { try database.fetchTrackCustomer().count }.to(equal(0))
                }

                it("should send push token customer update with default properties in stream mode") {
                    try! database.identifyCustomer(
                        with: [.properties(["id": .int(1)])],
                        into: configuration.mainProject
                    )
                    let customers = try! database.fetchTrackCustomer()
                    let wrapped: [FlushableObject] = customers.map {
                        CustomFlushableWrapper.customer(
                            wrapping: $0,
                            customerIds: ["cookie": "test-uuid"],
                            dataTypes: [.properties(["default_prop": .string("val")])],
                            project: streamProject
                        )
                    }
                    let mockRepo = MockRepository(configuration: configuration)
                    mockRepo.trackObjectResult = .success
                    var trackedObjects: [TrackingObject] = []
                    mockRepo.trackObjectHook = { trackedObjects.append($0) }
                    let localFlushingManager = try! FlushingManager(
                        database: database,
                        repository: mockRepo,
                        customerIdentifiedHandler: {}
                    )
                    waitUntil(timeout: .seconds(5)) { done in
                        localFlushingManager.flushTrackingObjects(wrapped) { result in
                            guard case .success(let count) = result else {
                                fail("Expected .success result")
                                done()
                                return
                            }
                            expect(count).to(equal(1))
                            done()
                        }
                    }
                    expect(trackedObjects.count).to(equal(1))
                }

                it("should skip empty customer update and send event in full push tracking flow (stream)") {
                    let pushData: [DataType] = [
                        .properties([
                            "platform": .string("ios"),
                            "description": .string("Permission granted")
                        ]),
                        .pushNotificationToken(token: "test-push-token", authorized: true)
                    ]
                    try! database.identifyCustomer(with: pushData, into: streamProject)
                    try! database.trackEvent(
                        with: pushData + [.eventType(Constants.EventTypes.notificationState)],
                        into: streamProject
                    )

                    let streamConfig = try! Configuration(
                        integrationConfig: Exponea.StreamSettings(
                            streamId: streamProject.streamId,
                            baseUrl: "https://google.com/"
                        )
                    )
                    let mockRepo = MockRepository(configuration: streamConfig)
                    mockRepo.trackObjectResult = .success
                    var trackedObjects: [TrackingObject] = []
                    mockRepo.trackObjectHook = { trackedObjects.append($0) }
                    let localFlushingManager = try! FlushingManager(
                        database: database,
                        repository: mockRepo,
                        customerIdentifiedHandler: {}
                    )
                    waitUntil(timeout: .seconds(5)) { done in
                        localFlushingManager.flushData(completion: { _ in done() })
                    }
                    expect(trackedObjects.count).to(equal(1))
                    expect(trackedObjects.first).to(beAnInstanceOf(EventTrackingObject.self))
                    expect { try database.fetchTrackCustomer().count }.to(equal(0))
                    expect { try database.fetchTrackEvent().count }.to(equal(0))
                }

                it("should send both customer update and event in full push tracking flow (project)") {
                    let pushData: [DataType] = [
                        .properties([
                            "platform": .string("ios"),
                            "description": .string("Permission granted")
                        ]),
                        .pushNotificationToken(token: "test-push-token", authorized: true)
                    ]
                    try! database.identifyCustomer(with: pushData, into: projectProject)
                    try! database.trackEvent(
                        with: pushData + [.eventType(Constants.EventTypes.notificationState)],
                        into: projectProject
                    )

                    let projectConfig = try! Configuration(
                        integrationConfig: Exponea.ProjectSettings(
                            projectToken: projectProject.projectToken,
                            authorization: projectProject.authorization,
                            baseUrl: "https://google.com/"
                        )
                    )
                    let mockRepo = MockRepository(configuration: projectConfig)
                    mockRepo.trackObjectResult = .success
                    var trackedObjects: [TrackingObject] = []
                    mockRepo.trackObjectHook = { trackedObjects.append($0) }
                    let localFlushingManager = try! FlushingManager(
                        database: database,
                        repository: mockRepo,
                        customerIdentifiedHandler: {}
                    )
                    waitUntil(timeout: .seconds(5)) { done in
                        localFlushingManager.flushData(completion: { _ in done() })
                    }
                    expect(trackedObjects.count).to(equal(2))
                    let customerObjects = trackedObjects.filter { $0 is CustomerTrackingObject }
                    let eventObjects = trackedObjects.filter { $0 is EventTrackingObject }
                    expect(customerObjects.count).to(equal(1))
                    expect(eventObjects.count).to(equal(1))
                    expect { try database.fetchTrackCustomer().count }.to(equal(0))
                    expect { try database.fetchTrackEvent().count }.to(equal(0))
                }

                it("should not invoke customerIdentifiedHandler or inAppRefreshCallback for skipped empty customer updates") {
                    var customerIdentifiedInvoked = false
                    var inAppRefreshInvoked = false
                    try! database.identifyCustomer(
                        with: [.properties(["id": .int(1)])],
                        into: configuration.mainProject
                    )
                    let customers = try! database.fetchTrackCustomer()
                    let wrapped: [FlushableObject] = customers.map {
                        CustomFlushableWrapper.customer(
                            wrapping: $0,
                            customerIds: ["cookie": "test-uuid"],
                            dataTypes: [.properties([:])],
                            project: streamProject
                        )
                    }
                    let mockRepo = MockRepository(configuration: configuration)
                    mockRepo.trackObjectResult = .success
                    let localFlushingManager = try! FlushingManager(
                        database: database,
                        repository: mockRepo,
                        customerIdentifiedHandler: { customerIdentifiedInvoked = true }
                    )
                    localFlushingManager.inAppRefreshCallback = { inAppRefreshInvoked = true }
                    waitUntil(timeout: .seconds(5)) { done in
                        localFlushingManager.flushTrackingObjects(wrapped) { _ in done() }
                    }
                    expect(customerIdentifiedInvoked).to(beFalse())
                    expect(inAppRefreshInvoked).to(beFalse())
                }

                it("should skip multiple empty customer updates in one batch in stream mode") {
                    for _ in 1...3 {
                        try! database.identifyCustomer(
                            with: [.properties(["id": .int(1)])],
                            into: configuration.mainProject
                        )
                    }
                    let customers = try! database.fetchTrackCustomer()
                    expect(customers.count).to(equal(3))
                    let wrapped: [FlushableObject] = customers.map {
                        CustomFlushableWrapper.customer(
                            wrapping: $0,
                            customerIds: ["cookie": "test-uuid"],
                            dataTypes: [.properties([:])],
                            project: streamProject
                        )
                    }
                    let mockRepo = MockRepository(configuration: configuration)
                    mockRepo.trackObjectResult = .success
                    var trackedObjects: [TrackingObject] = []
                    mockRepo.trackObjectHook = { trackedObjects.append($0) }
                    let localFlushingManager = try! FlushingManager(
                        database: database,
                        repository: mockRepo,
                        customerIdentifiedHandler: {}
                    )
                    waitUntil(timeout: .seconds(5)) { done in
                        localFlushingManager.flushTrackingObjects(wrapped) { result in
                            guard case .success(let count) = result else {
                                fail("Expected .success result")
                                done()
                                return
                            }
                            expect(count).to(equal(0))
                            done()
                        }
                    }
                    expect(trackedObjects).to(beEmpty())
                    expect { try database.fetchTrackCustomer().count }.to(equal(0))
                }

                it("should handle database delete failure gracefully for skipped empty customer updates") {
                    try! database.identifyCustomer(
                        with: [.properties(["id": .int(1)])],
                        into: configuration.mainProject
                    )
                    let customers = try! database.fetchTrackCustomer()
                    let wrapped: [FlushableObject] = customers.map {
                        CustomFlushableWrapper.customer(
                            wrapping: $0,
                            customerIds: ["cookie": "test-uuid"],
                            dataTypes: [.properties([:])],
                            project: streamProject
                        )
                    }
                    let throwingDb = ThrowingDeleteDatabaseWrapper(database)
                    throwingDb.shouldThrowOnDelete = true
                    let mockRepo = MockRepository(configuration: configuration)
                    mockRepo.trackObjectResult = .success
                    var trackedObjects: [TrackingObject] = []
                    mockRepo.trackObjectHook = { trackedObjects.append($0) }
                    let localFlushingManager = try! FlushingManager(
                        database: throwingDb,
                        repository: mockRepo,
                        customerIdentifiedHandler: {}
                    )
                    waitUntil(timeout: .seconds(5)) { done in
                        localFlushingManager.flushTrackingObjects(wrapped) { result in
                            guard case .success(let count) = result else {
                                fail("Expected .success result")
                                done()
                                return
                            }
                            expect(count).to(equal(0))
                            done()
                        }
                    }
                    expect(trackedObjects).to(beEmpty())
                    expect { try database.fetchTrackCustomer().count }.to(equal(1))
                }
            }
        }
    }
}

//
//  DatabaseSpec.swift
//  ExponeaSDKTests
//
//  Created by Dominik Hadl on 22/08/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import XCTest
import Quick
import Nimble
import CoreData

@testable import ExponeaSDK

class DatabaseManagerSpec: QuickSpec {

    override func spec() {
        let inMemoryDescription = NSPersistentStoreDescription()
        inMemoryDescription.type = NSInMemoryStoreType

        var db: DatabaseManager!

        let myProject = ExponeaProject(baseUrl: "http://mock-url.com", projectToken: "mytoken", authorization: .none)

        context("A database manager") {
            beforeEach {
                db = try! DatabaseManager(persistentStoreDescriptions: [inMemoryDescription])
            }

            describe("when properly instantiated", {
                let customerData: [DataType] = [
                    .timestamp(100),
                    .customerIds(["registered": "myemail"]),
                    .properties(["customprop": .string("customval")]),
                    .pushNotificationToken(token: "pushtoken", authorized: true)
                ]

                let eventData: [DataType] = [
                    .timestamp(100),
                    .properties(["customprop": .string("customval")]),
                    .eventType("myevent"),
                    .pushNotificationToken(token: "tokenthatisgoingtobeignored", authorized: true)
                ]

                describe("customer handling") {
                    it("should create first customer") {
                        expect(db.currentCustomer).toNot(beNil())
                    }
                    it("should create multiple customers") {
                        expect(db.customers.count).to(equal(1))
                        db.makeNewCustomer()
                        expect(db.customers.count).to(equal(2))
                        db.makeNewCustomer()
                        expect(db.customers.count).to(equal(3))
                    }

                    it("should return latest customer as currentCustomer") {
                        let firstUUID = db.currentCustomer.uuid
                        db.makeNewCustomer()
                        let secondUUID = db.currentCustomer.uuid
                        expect(firstUUID).notTo(equal(secondUUID))
                        db.makeNewCustomer()
                        let thirdUUID = db.currentCustomer.uuid
                        expect(firstUUID).notTo(equal(thirdUUID))
                        expect(secondUUID).notTo(equal(thirdUUID))
                    }

                    it("should delete old customers without events") {
                        _ = db.currentCustomer.uuid
                        db.makeNewCustomer()
                        expect(db.customers.count).to(equal(2))
                        // old customer has no events, it is deleted while fetching current customer
                        let secondUUID = db.currentCustomer.uuid
                        expect(db.customers.count).to(equal(1))
                        expect(db.customers[0].uuid).to(equal(secondUUID))
                    }

                    it("should not delete old customers with events assigned") {
                        let firstUUID = db.currentCustomer.uuid
                        try! db.identifyCustomer(
                            with: [.customerIds(["email": "a@b.com"])],
                            into: ExponeaProject(projectToken: "mock", authorization: .none)
                        )
                        db.makeNewCustomer()
                        expect(db.customers.count).to(equal(2))
                        let identify = try! db.fetchTrackCustomer()[0]
                        expect(identify.customerIds["cookie"]).to(equal(firstUUID.uuidString))
                        try! db.delete(identify.databaseObjectProxy)
                        _ = db.currentCustomer
                        expect(db.customers.count).to(equal(1))
                    }
                }
                it("should identify, fetch and delete a customer identification", closure: {
                    var objects: [TrackCustomerProxy] = []
                    expect { try db.identifyCustomer(with: customerData, into: myProject) }.toNot(raiseException())
                    expect { objects = try db.fetchTrackCustomer() }.toNot(raiseException())
                    expect(objects.count).to(equal(1))

                    let object = objects[0]
                    expect(db.currentCustomer.ids["registered"]).to(equal("myemail"))
                    expect(object.projectToken).to(equal("mytoken"))
                    let props = object.dataTypes.properties
                    expect(props.count).to(equal(3))

                    expect(props["customprop"] as? String).to(equal("customval"))
                    expect(props["apple_push_notification_id"] as? String).to(equal("pushtoken"))
                    expect(props["apple_push_notification_authorized"] as? Bool).to(equal(true))

                    expect(object.timestamp).to(equal(100))

                    expect { try db.delete(object.databaseObjectProxy) }.toNot(raiseException())
                    expect { objects = try db.fetchTrackCustomer() }.toNot(raiseException())
                    expect(objects).to(beEmpty())
                })

                it("should count customer identifications") {
                    expect(try? db.countTrackCustomer()).to(equal(0))
                    expect { try db.identifyCustomer(with: customerData, into: myProject) }.toNot(raiseException())
                    expect(try? db.countTrackCustomer()).to(equal(1))
                    expect { try db.identifyCustomer(with: customerData, into: myProject) }.toNot(raiseException())
                    expect(try? db.countTrackCustomer()).to(equal(2))
                }

                it("should track, fetch and delete an event", closure: {
                    var objects: [TrackEventProxy] = []
                    expect { try db.trackEvent(with: eventData, into: myProject) }.toNot(raiseException())
                    expect { objects = try db.fetchTrackEvent() }.toNot(raiseException())
                    expect(objects.count).to(equal(1))

                    let object = objects[0]
                    expect(object.projectToken).to(equal("mytoken"))
                    expect(object.dataTypes.properties["customprop"] as? String).to(equal("customval"))
                    expect(object.timestamp).to(equal(100))
                    expect(object.eventType).to(equal("myevent"))

                    expect { try db.delete(object.databaseObjectProxy) }.toNot(raiseException())
                    expect { objects = try db.fetchTrackEvent() }.toNot(raiseException())
                    expect(objects).to(beEmpty())
                })

                it("should track event with complex properties") {
                    let complexData: [DataType] = [.properties([
                        "array": [123, "abc", false].jsonValue,
                        "dictionary": ["int": 123, "string": "abc", "bool": true].jsonValue
                    ])]
                    expect { try db.trackEvent(with: complexData, into: myProject) }.toNot(raiseException())
                    let objects: [TrackEventProxy] = (try? db.fetchTrackEvent()) ?? []
                    let object: TrackEventProxy = objects[0]
                    expect(object.dataTypes.properties["array"]??.jsonValue)
                        .to(equal([123, "abc", false].jsonValue))
                    expect(object.dataTypes.properties["dictionary"]??.jsonValue)
                        .to(equal(["int": 123, "string": "abc", "bool": true].jsonValue))
                }

                it("should count events") {
                    expect(try? db.countTrackEvent()).to(equal(0))
                    expect { try db.trackEvent(with: eventData, into: myProject) }.toNot(raiseException())
                    expect(try? db.countTrackEvent()).to(equal(1))
                    expect { try db.trackEvent(with: eventData, into: myProject) }.toNot(raiseException())
                    expect(try? db.countTrackEvent()).to(equal(2))
                }

                describe("update", {
                    func createSampleEvent() -> TrackEventProxy {
                        var objects: [TrackEventProxy] = []
                        expect { try db.trackEvent(with: eventData, into: myProject) }.toNot(raiseException())
                        expect { objects = try db.fetchTrackEvent() }.toNot(raiseException())
                        expect(objects.count).to(equal(1))

                        return objects[0]
                    }

                    func fetchSampleEvent() -> TrackEventProxy {
                        var objects: [TrackEventProxy] = []
                        expect { objects = try db.fetchTrackEvent() }.toNot(raiseException())
                        expect(objects.count).to(equal(1))
                        return objects[0]
                    }

                    it("should add new property", closure: {
                        let sampleEvent = createSampleEvent()
                        let updateData = DataType.properties(["newcustomprop": .string("newcustomval")])
                        expect {
                            try db.updateEvent(withId: sampleEvent.databaseObjectProxy.objectID, withData: updateData)
                        }.toNot(raiseException())
                        let updatedEvent = fetchSampleEvent()
                        expect { updatedEvent.dataTypes.properties.count }.to(equal(2))
                        expect { updatedEvent.dataTypes.properties["customprop"] as? String }.to(equal("customval"))
                        expect {
                            updatedEvent.dataTypes.properties["newcustomprop"] as? String
                        }.to(equal("newcustomval"))
                    })

                    it("should update existing property", closure: {
                        let sampleEvent = createSampleEvent()
                        let updateData = DataType.properties(["customprop": .string("newcustomval")])
                        expect {
                            try db.updateEvent(withId: sampleEvent.databaseObjectProxy.objectID, withData: updateData)
                        }.toNot(raiseException())
                        let updatedEvent = fetchSampleEvent()
                        expect { updatedEvent.dataTypes.properties.count }.to(equal(1))
                        expect { updatedEvent.dataTypes.properties["customprop"] as? String }.to(equal("newcustomval"))
                    })

                    it("should throw updating an object if it was deleted", closure: {
                        let sampleEvent = createSampleEvent()
                        expect { try db.delete(sampleEvent.databaseObjectProxy) }.toNot(raiseException())
                        let updateData = DataType.properties(["newcustomprop": .string("newcustomval")])
                        expect {
                            try db.updateEvent(withId: sampleEvent.databaseObjectProxy.objectID, withData: updateData)

                        }.to(throwError(DatabaseManagerError.objectDoesNotExist))
                    })

                    it("should throw updating wrong object", closure: {
                        let customer = db.currentCustomer
                        let updateData = DataType.properties(["newcustomprop": .string("newcustomval")])
                        expect { try db.updateEvent(withId: customer.managedObjectID, withData: updateData) }
                            .to(throwError(DatabaseManagerError.wrongObjectType))
                    })
                })
            })

            describe("when accessed from a background thread", {
                let customerData: [DataType] = [
                    .customerIds(["registered": "myemail"]),
                    .properties(["customprop": .string("customval")]),
                    .pushNotificationToken(token: "pushtoken", authorized: true)
                ]

                let eventData: [DataType] = [
                    .properties(["customprop": .string("customval")]),
                    .eventType("myevent"),
                    .pushNotificationToken(token: "tokenthatisgoingtobeignored", authorized: true)
                ]

                // Create on main queue
                db = try! DatabaseManager(persistentStoreDescriptions: [inMemoryDescription])

                it("should fetch customer", closure: {
                    waitUntil { done in
                        DispatchQueue.global(qos: .background).async {
                            expect(Thread.isMainThread).to(beFalse())
                            expect(db.currentCustomer).toNot(beNil())
                            done()
                        }
                    }
                })

                it("should identify, fetch and delete a track customer event", closure: {
                    var objects: [TrackCustomerProxy] = []
                    var expectedTimestamp: Double = 1

                    waitUntil(timeout: .seconds(3)) { done in
                        DispatchQueue.global(qos: .background).async {
                            expect(Thread.isMainThread).to(beFalse())
                            expectedTimestamp = Date().timeIntervalSince1970
                            expect {
                                try db.identifyCustomer(with: customerData, into: myProject)
                            }.toNot(raiseException())
                            done()
                        }
                    }

                    waitUntil(timeout: .seconds(3)) { done in
                        DispatchQueue.global(qos: .default).async {
                            expect(Thread.isMainThread).to(beFalse())
                            expect { objects = try db.fetchTrackCustomer() }.toNot(raiseException())
                            expect(objects.count).to(equal(1))
                            done()
                        }
                    }

                    let object = objects[0]
                    expect(db.currentCustomer.ids["registered"]).to(equal("myemail"))
                    expect(object.projectToken).to(equal("mytoken"))
                    let props = object.dataTypes.properties
                    expect(props.count).to(equal(3))

                    expect(props["customprop"] as? String).to(equal("customval"))
                    expect(props["apple_push_notification_id"] as? String).to(equal("pushtoken"))
                    expect(props["apple_push_notification_authorized"] as? Bool).to(equal(true))

                    expect(object.timestamp).to(beCloseTo(expectedTimestamp, within: 0.5))

                    waitUntil { done in
                        DispatchQueue.global(qos: .background).async {
                            expect(Thread.isMainThread).to(beFalse())
                            expect { try db.delete(object.databaseObjectProxy) }.toNot(raiseException())
                            done()
                        }
                    }
                    expect { objects = try db.fetchTrackCustomer() }.toNot(raiseException())
                    expect(objects).to(beEmpty())
                })

                it("should track, fetch and delete an event", closure: {
                    var objects: [TrackEventProxy] = []
                    var expectedTimestamp: Double = 1

                    waitUntil { done in
                        DispatchQueue.global(qos: .background).async {
                            expect(Thread.isMainThread).to(beFalse())
                            expectedTimestamp =  Date().timeIntervalSince1970
                            expect { try db.trackEvent(with: eventData, into: myProject) }.toNot(raiseException())
                            done()
                        }
                    }
                    waitUntil { done in
                        DispatchQueue.global(qos: .background).async {
                            expect(Thread.isMainThread).to(beFalse())
                            expect { objects = try db.fetchTrackEvent() }.toNot(raiseException())
                            expect(objects.count).to(equal(1))
                            done()
                        }
                    }

                    let object = objects[0]

                    waitUntil(action: { (done) in
                        DispatchQueue.global(qos: .background).async {
                            expect(Thread.isMainThread).to(beFalse())
                            expect(object.projectToken).to(equal("mytoken"))
                            done()
                        }
                    })

                    expect(object.dataTypes.properties["customprop"] as? String).to(equal("customval"))

                    expect(object.eventType).to(equal("myevent"))

                    expect(object.timestamp).to(beCloseTo(expectedTimestamp, within: 0.05))

                    waitUntil(action: { (done) in
                        DispatchQueue.global(qos: .background).async {
                            expect(Thread.isMainThread).to(beFalse())
                            expect { try db.delete(object.databaseObjectProxy) }.toNot(raiseException())
                            done()
                        }
                    })

                    expect { objects = try db.fetchTrackEvent() }.toNot(raiseException())
                    expect(objects).to(beEmpty())
                })
            })

            describe("when stressed", {
                let customerData: [DataType] = [
                    .customerIds(["registered": "myemail"]),
                    .properties(["customprop": .string("customval")]),
                    .pushNotificationToken(token: "pushtoken", authorized: true)
                ]

                let eventData: [DataType] = [
                    .properties(["customprop": .string("customval")]),
                    .eventType("myevent"),
                    .pushNotificationToken(token: "tokenthatisgoingtobeignored", authorized: true)
                ]

                it("should not crash when tracking event", closure: {
                    db = try! DatabaseManager(persistentStoreDescriptions: [inMemoryDescription])
                    expect {
                        for _ in 0..<1000 {
                            try db.trackEvent(with: eventData, into: myProject)
                        }
                    }.toNot(raiseException())

                    var objects: [TrackEventProxy] = []
                    expect { objects = try db.fetchTrackEvent() }.toNot(raiseException())
                    expect(objects.count).to(equal(1000))
                })

                it("should not crash when tracking customer", closure: {
                    db = try! DatabaseManager(persistentStoreDescriptions: [inMemoryDescription])
                    expect {
                        for _ in 0..<1000 {
                            try db.identifyCustomer(with: customerData, into: myProject)
                        }
                        }.toNot(raiseException())

                    var objects: [TrackCustomerProxy] = []
                    expect { objects = try db.fetchTrackCustomer() }.toNot(raiseException())
                    expect(objects.count).to(equal(1000))
                })

                it("should not crash when tracking event from multiple threads") {
                    db = try! DatabaseManager(persistentStoreDescriptions: [inMemoryDescription])
                    var objects: [TrackEventProxy] = []

                    waitUntil(timeout: .seconds(6), action: { (allDone) in
                        var doneCount = 0
                        func done() {
                            doneCount += 1
                            if doneCount == 100 {
                                allDone()
                            }
                        }

                        for _ in 0..<100 {
                            DispatchQueue.global(qos: .background).async {
                                expect {
                                    try db.trackEvent(with: eventData, into: myProject)
                                }.toNot(raiseException())
                                done()
                            }
                        }
                    })

                    expect { objects = try db.fetchTrackEvent() }.toNot(raiseException())
                    expect(objects.count).to(equal(100))
                }
            })
        }
    }
}

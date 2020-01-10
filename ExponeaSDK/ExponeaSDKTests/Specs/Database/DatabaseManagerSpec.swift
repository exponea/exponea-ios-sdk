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

        context("A database manager") {
            beforeEach {
                db = try! DatabaseManager(persistentStoreDescriptions: [inMemoryDescription])
            }

            describe("when properly instantiated", {
                let customerData: [DataType] = [
                    .timestamp(100),
                    .customerIds(["registered": .string("myemail")]),
                    .projectToken("mytoken"),
                    .properties(["customprop": .string("customval")]),
                    .pushNotificationToken("pushtoken")
                ]

                let eventData: [DataType] = [
                    .timestamp(100),
                    .projectToken("mytoken"),
                    .properties(["customprop": .string("customval")]),
                    .eventType("myevent"),
                    .pushNotificationToken("tokenthatisgoingtobeignored")
                ]

                it("should create customer", closure: {
                    expect(db.customer).toNot(beNil())
                })

                it("should identify, fetch and delete a customer", closure: {
                    var objects: [TrackCustomerThreadSafe] = []
                    expect { try db.identifyCustomer(with: customerData) }.toNot(raiseException())
                    expect { objects = try db.fetchTrackCustomer() }.toNot(raiseException())
                    expect(objects.count).to(equal(1))

                    let object = objects[0]
                    expect(db.customer.ids["registered"]).to(equal("myemail".jsonValue))
                    expect(object.projectToken).to(equal("mytoken"))
                    let props = object.properties!
                    expect(props.count).to(equal(2))

                    expect(props["customprop"]?.rawValue as? String).to(equal("customval"))
                    expect(props["apple_push_notification_id"]?.rawValue as? String).to(equal("pushtoken"))

                    expect(object.timestamp).to(equal(100))

                    expect { try db.delete(object) }.toNot(raiseException())
                    expect { objects = try db.fetchTrackCustomer() }.toNot(raiseException())
                    expect(objects).to(beEmpty())
                })

                it("should track, fetch and delete an event", closure: {
                    var objects: [TrackEventThreadSafe] = []
                    expect { try db.trackEvent(with: eventData) }.toNot(raiseException())
                    expect { objects = try db.fetchTrackEvent() }.toNot(raiseException())
                    expect(objects.count).to(equal(1))

                    let object = objects[0]
                    expect(object.projectToken).to(equal("mytoken"))
                    expect(object.properties!["customprop"]?.rawValue as? String).to(equal("customval"))
                    expect(object.timestamp).to(equal(100))
                    expect(object.eventType).to(equal("myevent"))

                    expect { try db.delete(object) }.toNot(raiseException())
                    expect { objects = try db.fetchTrackEvent() }.toNot(raiseException())
                    expect(objects).to(beEmpty())
                })

                describe("update", {
                    func createSampleEvent() -> TrackEventThreadSafe {
                        var objects: [TrackEventThreadSafe] = []
                        expect { try db.trackEvent(with: eventData) }.toNot(raiseException())
                        expect { objects = try db.fetchTrackEvent() }.toNot(raiseException())
                        expect(objects.count).to(equal(1))

                        return objects[0]
                    }

                    func fetchSampleEvent() -> TrackEventThreadSafe {
                        var objects: [TrackEventThreadSafe] = []
                        expect { objects = try db.fetchTrackEvent() }.toNot(raiseException())
                        expect(objects.count).to(equal(1))
                        return objects[0]
                    }

                    it("should add new property", closure: {
                        let sampleEvent = createSampleEvent()
                        let updateData = DataType.properties(["newcustomprop": .string("newcustomval")])
                        expect {
                            try db.updateEvent(withId: sampleEvent.managedObjectID, withData: updateData)
                        }.toNot(raiseException())
                        let updatedEvent = fetchSampleEvent()
                        expect { updatedEvent.properties?.count}.to(equal(2))
                        expect { updatedEvent.properties?["customprop"]?.rawValue as? String }.to(equal("customval"))
                        expect {
                            updatedEvent.properties?["newcustomprop"]?.rawValue as? String
                        }.to(equal("newcustomval"))
                    })

                    it("should update existing property", closure: {
                        let sampleEvent = createSampleEvent()
                        let updateData = DataType.properties(["customprop": .string("newcustomval")])
                        expect {
                            try db.updateEvent(withId: sampleEvent.managedObjectID, withData: updateData)
                        }.toNot(raiseException())
                        let updatedEvent = fetchSampleEvent()
                        expect { updatedEvent.properties?.count}.to(equal(1))
                        expect { updatedEvent.properties?["customprop"]?.rawValue as? String }.to(equal("newcustomval"))
                    })

                    it("should throw updating an object if it was deleted", closure: {
                        let sampleEvent = createSampleEvent()
                        expect { try db.delete(sampleEvent) }.toNot(raiseException())
                        let updateData = DataType.properties(["newcustomprop": .string("newcustomval")])
                        expect { try db.updateEvent(withId: sampleEvent.managedObjectID, withData: updateData) }
                            .to(throwError(DatabaseManagerError.objectDoesNotExist))
                    })

                    it("should throw updating wrong object", closure: {
                        let customer = db.customer
                        let updateData = DataType.properties(["newcustomprop": .string("newcustomval")])
                        expect { try db.updateEvent(withId: customer.managedObjectID, withData: updateData) }
                            .to(throwError(DatabaseManagerError.wrongObjectType))
                    })
                })
            })

            describe("when accessed from a background thread", {
                let customerData: [DataType] = [
                    .customerIds(["registered": .string("myemail")]),
                    .projectToken("mytoken"),
                    .properties(["customprop": .string("customval")]),
                    .pushNotificationToken("pushtoken")
                ]

                let eventData: [DataType] = [
                    .projectToken("mytoken"),
                    .properties(["customprop": .string("customval")]),
                    .eventType("myevent"),
                    .pushNotificationToken("tokenthatisgoingtobeignored")
                ]

                // Create on main queue
                db = try! DatabaseManager(persistentStoreDescriptions: [inMemoryDescription])

                it("should fetch customer", closure: {
                    waitUntil { done in
                        DispatchQueue.global(qos: .background).async {
                            expect(Thread.isMainThread).to(beFalse())
                            expect(db.customer).toNot(beNil())
                            done()
                        }
                    }
                })

                it("should identify, fetch and delete a track customer event", closure: {
                    var objects: [TrackCustomerThreadSafe] = []
                    var expectedTimestamp: Double = 1

                    waitUntil { done in
                        DispatchQueue.global(qos: .background).async {
                            expect(Thread.isMainThread).to(beFalse())
                            expectedTimestamp = Date().timeIntervalSince1970
                            expect { try db.identifyCustomer(with: customerData) }.toNot(raiseException())
                            done()
                        }
                    }

                    waitUntil { done in
                        DispatchQueue.global(qos: .default).async {
                            expect(Thread.isMainThread).to(beFalse())
                            expect { objects = try db.fetchTrackCustomer() }.toNot(raiseException())
                            expect(objects.count).to(equal(1))
                            done()
                        }
                    }

                    let object = objects[0]
                    expect(db.customer.ids["registered"]).to(equal("myemail".jsonValue))
                    expect(object.projectToken).to(equal("mytoken"))
                    let props = object.properties!
                    expect(props.count).to(equal(2))

                    expect(props["customprop"]?.rawValue as? String).to(equal("customval"))
                    expect(props["apple_push_notification_id"]?.rawValue as? String).to(equal("pushtoken"))

                    expect(object.timestamp).to(beCloseTo(expectedTimestamp, within: 0.05))

                    waitUntil { done in
                        DispatchQueue.global(qos: .background).async {
                            expect(Thread.isMainThread).to(beFalse())
                            expect { try db.delete(object) }.toNot(raiseException())
                            done()
                        }
                    }
                    expect { objects = try db.fetchTrackCustomer() }.toNot(raiseException())
                    expect(objects).to(beEmpty())
                })

                it("should track, fetch and delete an event", closure: {
                    var objects: [TrackEventThreadSafe] = []
                    var expectedTimestamp: Double = 1

                    waitUntil { done in
                        DispatchQueue.global(qos: .background).async {
                            expect(Thread.isMainThread).to(beFalse())
                            expectedTimestamp =  Date().timeIntervalSince1970
                            expect { try db.trackEvent(with: eventData) }.toNot(raiseException())
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

                    expect(object.properties!["customprop"]?.rawValue as? String).to(equal("customval"))

                    expect(object.eventType).to(equal("myevent"))

                    expect(object.timestamp).to(beCloseTo(expectedTimestamp, within: 0.05))

                    waitUntil(action: { (done) in
                        DispatchQueue.global(qos: .background).async {
                            expect(Thread.isMainThread).to(beFalse())
                            expect { try db.delete(object) }.toNot(raiseException())
                            done()
                        }
                    })

                    expect { objects = try db.fetchTrackEvent() }.toNot(raiseException())
                    expect(objects).to(beEmpty())
                })
            })

            describe("when stressed", {
                let customerData: [DataType] = [
                    .customerIds(["registered": .string("myemail")]),
                    .projectToken("mytoken"),
                    .properties(["customprop": .string("customval")]),
                    .pushNotificationToken("pushtoken")
                ]

                let eventData: [DataType] = [
                    .projectToken("mytoken"),
                    .properties(["customprop": .string("customval")]),
                    .eventType("myevent"),
                    .pushNotificationToken("tokenthatisgoingtobeignored")
                ]

                let eventData2: [DataType] = [
                    .projectToken("differenttoken"),
                    .properties([
                        "customprop": .string("customval"),
                        "array": .array([.string("test"), .string("ab")])
                    ]),
                    .eventType("myevent")
                ]

                it("should not crash when tracking event", closure: {
                    db = try! DatabaseManager(persistentStoreDescriptions: [inMemoryDescription])
                    expect {
                        for _ in 0..<1000 {
                            try db.trackEvent(with: eventData)
                        }

                        return nil
                    }.toNot(raiseException())

                    var objects: [TrackEventThreadSafe] = []
                    expect { objects = try db.fetchTrackEvent() }.toNot(raiseException())
                    expect(objects.count).to(equal(1000))
                })

                it("should not crash when tracking customer", closure: {
                    db = try! DatabaseManager(persistentStoreDescriptions: [inMemoryDescription])
                    expect {
                        for _ in 0..<1000 {
                            try db.identifyCustomer(with: customerData)
                        }

                        return nil
                        }.toNot(raiseException())

                    var objects: [TrackCustomerThreadSafe] = []
                    expect { objects = try db.fetchTrackCustomer() }.toNot(raiseException())
                    expect(objects.count).to(equal(1000))
                })

                it("should not crash when tracking event from multiple threads") {
                    db = try! DatabaseManager(persistentStoreDescriptions: [inMemoryDescription])
                    var objects: [TrackEventThreadSafe] = []

                    waitUntil(timeout: 6.0, action: { (allDone) in
                        var doneCount = 0
                        func done() {
                            doneCount += 1
                            if doneCount == 100 {
                                allDone()
                            }
                        }

                        for _ in 0..<100 {
                            DispatchQueue.global(qos: .background).async {
                                expect { try db.trackEvent(with: eventData) }.toNot(raiseException())
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

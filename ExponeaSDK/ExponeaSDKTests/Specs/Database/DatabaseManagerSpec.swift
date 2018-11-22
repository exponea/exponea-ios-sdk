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
            db = try! DatabaseManager(persistentStoreDescriptions: [inMemoryDescription])
            
            describe("when properly instantiated", {
                let customerData: [DataType] = [
                    .timestamp(100),
                    .customerIds(["registered" : .string("myemail")]),
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
                    var objects: [TrackCustomer] = []
                    expect { try db.identifyCustomer(with: customerData) }.toNot(raiseException())
                    expect { objects = try db.fetchTrackCustomer() }.toNot(raiseException())
                    expect(objects.count).to(equal(1))
                    
                    let object = objects[0]
                    expect(object.customer?.ids["registered"]).to(equal("myemail".jsonValue))
                    expect(object.projectToken).to(equal("mytoken"))
                    let props = object.properties as? Set<KeyValueItem>
                    expect(props?.count).to(equal(2))
                    
                    let customProp = props?.first(where: { $0.key == "customprop" })
                    expect(customProp?.value as? String).to(equal("customval"))
                    
                    let pushProp = props?.first(where: { $0.key == "apple_push_notification_id" })
                    expect(pushProp?.value as? String).to(equal("pushtoken"))
                    
                    expect(object.timestamp).to(equal(100))
                    
                    expect { try db.delete(object) }.toNot(raiseException())
                    expect { objects = try db.fetchTrackCustomer() }.toNot(raiseException())
                    expect(objects).to(beEmpty())
                })
                
                it("should track, fetch and delete an event", closure: {
                    var objects: [TrackEvent] = []
                    expect { try db.trackEvent(with: eventData) }.toNot(raiseException())
                    expect { objects = try db.fetchTrackEvent() }.toNot(raiseException())
                    expect(objects.count).to(equal(1))
                    
                    let object = objects[0]
                    expect(object.projectToken).to(equal("mytoken"))
                    let prop = object.properties?.anyObject() as? KeyValueItem
                    expect(prop?.key).to(equal("customprop"))
                    expect(prop?.value as? String).to(equal("customval"))
                    expect(object.timestamp).to(equal(100))
                    expect(object.eventType).to(equal("myevent"))
                    
                    expect { try db.delete(object) }.toNot(raiseException())
                    expect { objects = try db.fetchTrackEvent() }.toNot(raiseException())
                    expect(objects).to(beEmpty())
                })
            })
            
            describe("when accessed from a background thread", {
                let customerData: [DataType] = [
                    .customerIds(["registered" : .string("myemail")]),
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
                    expect(db.customer).toNot(beNil())
                })
                
                it("should identify, fetch and delete a track customer event", closure: {
                    var objects: [TrackCustomer] = []
                    var expectedTimestamp: Double = 1

                    DispatchQueue.global(qos: .background).sync {
                        expectedTimestamp = Date().timeIntervalSince1970
                        expect { try db.identifyCustomer(with: customerData) }.toNot(raiseException())
                    }
                    
                    DispatchQueue.global(qos: .default).sync {
                        expect { objects = try db.fetchTrackCustomer() }.toNot(raiseException())
                        expect(objects.count).to(equal(1))
                    }
                    
                    let object = objects[0]
                    expect(object.customer?.ids["registered"]).to(equal("myemail".jsonValue))
                    expect(object.projectToken).to(equal("mytoken"))
                    let props = object.properties as? Set<KeyValueItem>
                    expect(props?.count).to(equal(2))
                    
                    let customProp = props?.first(where: { $0.key == "customprop" })
                    expect(customProp?.value as? String).to(equal("customval"))
                    
                    let pushProp = props?.first(where: { $0.key == "apple_push_notification_id" })
                    expect(pushProp?.value as? String).to(equal("pushtoken"))
                    
                    expect(object.timestamp).to(beCloseTo(expectedTimestamp, within: 0.05))
                    
                    DispatchQueue.global(qos: .background).sync {
                        expect { try db.delete(object) }.toNot(raiseException())
                    }
                    
                    expect { objects = try db.fetchTrackCustomer() }.toNot(raiseException())
                    expect(objects).to(beEmpty())
                })
                
                it("should track, fetch and delete an event", closure: {
                    var objects: [TrackEvent] = []
                    var expectedTimestamp: Double = 1
                    
                    DispatchQueue.global(qos: .background).sync {
                        expectedTimestamp =  Date().timeIntervalSince1970
                        expect { try db.trackEvent(with: eventData) }.toNot(raiseException())
                    }
                    DispatchQueue.global(qos: .default).sync {
                        expect { objects = try db.fetchTrackEvent() }.toNot(raiseException())
                        expect(objects.count).to(equal(1))
                    }

                    let object = objects[0]
                    
                    waitUntil(action: { (done) in
                        DispatchQueue.main.async {
                            expect(object.projectToken).to(equal("mytoken"))
                            done()
                        }
                    })
                    
                    let prop = object.properties?.anyObject() as? KeyValueItem
                    expect(prop?.key).to(equal("customprop"))
                    expect(prop?.value as? String).to(equal("customval"))
                    expect(object.eventType).to(equal("myevent"))
                    
                    expect(object.timestamp).to(beCloseTo(expectedTimestamp, within: 0.05))

                    DispatchQueue.global(qos: .background).sync {
                        expect { try db.delete(object) }.toNot(raiseException())
                    }
                    
                    expect { objects = try db.fetchTrackEvent() }.toNot(raiseException())
                    expect(objects).to(beEmpty())
                })
            })
            
            describe("when stressed", {
                let customerData: [DataType] = [
                    .customerIds(["registered" : .string("myemail")]),
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
                    .properties(["customprop": .string("customval"), "array": .array([.string("test"), .string("ab")])]),
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
                    
                    var objects: [TrackEvent] = []
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
                    
                    var objects: [TrackCustomer] = []
                    expect { objects = try db.fetchTrackCustomer() }.toNot(raiseException())
                    expect(objects.count).to(equal(1000))
                })
                
                it("should not crash when tracking event from multiple threads") {
                    db = try! DatabaseManager(persistentStoreDescriptions: [inMemoryDescription])
                    var objects: [TrackEvent] = []
                    
                    waitUntil(timeout: 6.0, action: { (done) in
                        var isOneDone = false
                        
                        DispatchQueue.global(qos: .background).async {
                            for _ in 0..<500 {
                                expect { try db.trackEvent(with: eventData) }.toNot(raiseException())
                            }
                            if isOneDone {
                                done()
                                return
                            }
                            isOneDone = true
                        }
                        
                        DispatchQueue.global(qos: .default).async {
                            for _ in 0..<500 {
                                expect { try db.trackEvent(with: eventData2) }.toNot(raiseException())
                            }
                            if isOneDone {
                                done()
                                return
                            }
                            isOneDone = true
                        }
                    })
                    
                    expect { objects = try db.fetchTrackEvent() }.toNot(raiseException())
                    expect(objects.count).to(equal(1000))
                }
            })
        }
    }
}

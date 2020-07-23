//
//  EventFilterSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 05/02/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import XCTest
import Quick
import Nimble

@testable import ExponeaSDK

final class EventFilterSpec: QuickSpec {
    override func spec() {
        describe("passing") {
            let filter = EventFilter(
                eventType: "session_start",
                filter: [
                    EventPropertyFilter.timestamp(NumberConstraint.greaterThan(123.0)),
                    EventPropertyFilter.property("property", StringConstraint.startsWith("val")),
                    EventPropertyFilter.property("property", StringConstraint.isIn(["value", "other_value"])),
                    EventPropertyFilter.property("other_property", BooleanConstraint.isSet)
                ]
            )
            it("should pass on correct event") {
                let event = EventFilterEvent(
                    eventType: "session_start",
                    properties: ["property": "value", "other_property": nil],
                    timestamp: 124
                )
                expect(try! filter.passes(event: event)).to(beTrue())
            }
            it("should fail on incorrect event type") {
                let event = EventFilterEvent(
                    eventType: "session_end",
                    properties: ["property": "value", "other_property": nil],
                    timestamp: 124
                )
                expect(try! filter.passes(event: event)).to(beFalse())
            }
            it("should fail on incorrect property value") {
                let event = EventFilterEvent(
                    eventType: "session_start",
                    properties: ["property": "Xvalue", "other_property": nil],
                    timestamp: 124
                )
                expect(try! filter.passes(event: event)).to(beFalse())
            }
            it("should fail when property is not set") {
                let event = EventFilterEvent(
                    eventType: "session_start",
                    properties: ["property": "value"],
                    timestamp: 124
                )
                expect(try! filter.passes(event: event)).to(beFalse())
            }
            it("should fail when property is not set") {
                let event = EventFilterEvent(
                    eventType: "session_start",
                    properties: ["property": "value", "other_property": nil],
                    timestamp: 122
                )
                expect(try! filter.passes(event: event)).to(beFalse())
            }
            it("should throw on incorrect operand count") {
                let invalidFilter = EventFilter(
                    eventType: "session_start",
                    filter: [
                        EventPropertyFilter.property(
                            "property",
                            StringConstraint(filterOperator: StartsWithOperator.self, operands: [])
                        )
                    ]
                )
                let event = EventFilterEvent(eventType: "session_start", properties: [:], timestamp: 122)
                do {
                    _ = try invalidFilter.passes(event: event)
                    XCTFail("Call should throw")
                } catch {
                    expect(error.localizedDescription).to(
                        equal("Incorrect operand count for operator starts with. Required 1, got 0.")
                    )
                }
            }
        }

        describe("serialization") {
            it("should serialize and deserialize example filter") {
                let filter = EventFilter(
                    eventType: "session_start",
                    filter: [
                        EventPropertyFilter.timestamp(NumberConstraint.greaterThan(123.0)),
                        EventPropertyFilter.property("property", StringConstraint.startsWith("val")),
                        EventPropertyFilter.property("other_property", BooleanConstraint.isSet)
                    ]
                )
                let data = try! JSONEncoder().encode(filter)
                expect(try! JSONDecoder().decode(EventFilter.self, from: data)).to(equal(filter))
            }

            it("should decode payload from server") {
                let payload = """
                    {
                        "event_type":"banner",
                        "filter":[
                            {
                                "attribute":{
                                    "type":"property",
                                    "property":"os_version"
                                },
                                "constraint":{
                                    "operator":"equals",
                                    "operands":[
                                        {
                                            "type":"constant",
                                            "value":"10"
                                        }
                                    ],
                                    "type":"string"
                                }
                            },
                            {
                                "attribute":{
                                    "type":"property",
                                    "property":"platform"
                                },
                                "constraint":{
                                    "operator":"is set",
                                    "operands":[

                                    ],
                                    "type":"boolean",
                                    "value":"true"
                                }
                            },
                            {
                                "attribute":{
                                    "type":"property",
                                    "property":"type"
                                },
                                "constraint":{
                                    "operator":"greater than",
                                    "operands":[
                                        {
                                            "type":"constant",
                                            "value":"123.0"
                                        }
                                    ],
                                    "type":"number"
                                }
                            },
                            {
                                "attribute":{
                                    "type":"timestamp"
                                },
                                "constraint":{
                                    "operator":"less than",
                                    "operands":[
                                        {
                                            "type":"constant",
                                            "value":"456.0"
                                        }
                                    ],
                                    "type":"number"
                                }
                            }
                        ]
                    }
                """
                let filter: EventFilter = try! JSONDecoder().decode(EventFilter.self, from: payload.data(using: .utf8)!)
                expect(filter).to(equal(
                    EventFilter(
                        eventType: "banner",
                        filter: [
                            EventPropertyFilter.property("os_version", StringConstraint.equals("10")),
                            EventPropertyFilter.property("platform", BooleanConstraint.isSet),
                            EventPropertyFilter.property("type", NumberConstraint.greaterThan(123)),
                            EventPropertyFilter.timestamp(NumberConstraint.lessThan(456))
                        ]
                    )
                ))
            }

            context("invalid payload") {
                let getPayload: (String, String, String) -> String = { attributeType, constraintType, filterOperator in
                    return """
                    {
                        "event_type":"banner",
                        "filter":[
                            {
                                "attribute":{ "type":"\(attributeType)", "property":"os_version" },
                                "constraint":{
                                    "operator":"\(filterOperator)",
                                    "operands":[{ "type":"constant","value":"10" }],
                                    "type":"\(constraintType)"
                                }
                            }
                        ]
                    }
                    """
                }

                it("should throw on invalid constraint") {
                    let payload = getPayload("unknown", "string", "equals")
                    do {
                        _ =  try JSONDecoder().decode(EventFilter.self, from: payload.data(using: .utf8)!)
                        XCTFail("Call should throw")
                    } catch {
                        expect(error.localizedDescription).to(
                            equal("Error decoding event filter: Unknown attribute type unknown.")
                        )
                    }
                }

                it("should throw on invalid constraint") {
                    let payload = getPayload("property", "unknown", "equals")
                    do {
                        _ =  try JSONDecoder().decode(EventFilter.self, from: payload.data(using: .utf8)!)
                        XCTFail("Call should throw")
                    } catch {
                        expect(error.localizedDescription).to(
                            equal("Error decoding event filter: Unknown constraint type unknown.")
                        )
                    }
                }

                it("should throw on invalid operator") {
                    let payload = getPayload("property", "string", "unknown")
                    do {
                        _ =  try JSONDecoder().decode(EventFilter.self, from: payload.data(using: .utf8)!)
                        XCTFail("Call should throw")
                    } catch {
                        expect(error.localizedDescription).to(equal(
                            "Error decoding event filter: Operator unknown is not supported for string constraint."
                        ))
                    }
                }
            }
        }
    }
}

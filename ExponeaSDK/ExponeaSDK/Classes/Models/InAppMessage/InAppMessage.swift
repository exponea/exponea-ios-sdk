//
//  InAppMessage.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 28/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

struct InAppMessage: Codable, Equatable {
    public let id: String
    public let name: String
    public let rawMessageType: String
    public var messageType: InAppMessageType { return InAppMessageType(rawValue: rawMessageType) ?? .alert }
    public let rawFrequency: String
    public var frequency: InAppMessageFrequency? { return InAppMessageFrequency(rawValue: rawFrequency) }
    public let payload: InAppMessagePayload?
    public let variantId: Int
    public let variantName: String
    public let trigger: EventFilter
    public let dateFilter: DateFilter
    public let priority: Int?
    public let delayMS: Int?
    public var delay: TimeInterval { return Double(delayMS ?? 0) / 1000.0 }
    public let timeoutMS: Int?
    public var timeout: TimeInterval? { return timeoutMS != nil ? Double(timeoutMS ?? 0 ) / 1000 : nil }

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name
        case rawMessageType = "message_type"
        case rawFrequency = "frequency"
        case payload
        case variantId = "variant_id"
        case variantName = "variant_name"
        case trigger
        case dateFilter = "date_filter"
        case priority = "load_priority"
        case delayMS = "load_delay"
        case timeoutMS = "close_timeout"
    }

    func applyDateFilter(date: Date) -> Bool {
        guard dateFilter.enabled else {
            return true
        }
        if let start = dateFilter.startDate, start > date {
            Exponea.logger.log(.verbose, message: "Message '\(self.name)' outside of date range.")
            return false
        }
        if let end = dateFilter.endDate, end < date {
            Exponea.logger.log(.verbose, message: "Message '\(self.name)' outside of date range.")
            return false
        }
        return true
    }

    func applyEventFilter(event: [DataType]) -> Bool {
        let eventTypes = event.eventTypes
        let timestamp = event.latestTimestamp
        let properties = event.properties
        var passed = false
        eventTypes.forEach { eventType in
            let filterEvent = EventFilterEvent(eventType: eventType, properties: properties, timestamp: timestamp)
            do {
                if try trigger.passes(event: filterEvent) {
                    passed = true
                }
            } catch {
                Exponea.logger.log(.error, message: "Error applying in-app message event filter \(error)")
            }
        }
        if !passed {
            let serializedTrigger = (try? JSONEncoder().encode(trigger)) ?? Data()
            let stringTrigger = String(data: serializedTrigger, encoding: .utf8) ?? ""
            Exponea.logger.log(
                .verbose,
                message: "Message '\(self.name)' failed event filter. Event: \(event). Message filter: \(stringTrigger)"
            )
        }
        return passed
    }

    func applyFrequencyFilter(displayState: InAppMessageDisplayStatus, sessionStart: Date) -> Bool {
        switch frequency {
        case .some(.always):
            return true
        case .some(.onlyOnce):
            let shouldDisplay = displayState.displayed == nil
            if !shouldDisplay {
                Exponea.logger.log(.verbose, message: "Message '\(self.name)' already displayed.")
            }
            return shouldDisplay
        case .some(.oncePerVisit):
            let shouldDisplay = displayState.displayed ?? Date(timeIntervalSince1970: 0) < sessionStart
            if !shouldDisplay {
                Exponea.logger.log(.verbose, message: "Message '\(self.name)' already displayed this session.")
            }
            return shouldDisplay
        case .some(.untilVisitorInteracts):
            let shouldDisplay = displayState.interacted == nil
            if !shouldDisplay {
                Exponea.logger.log(.verbose, message: "Message '\(self.name)' already interacted with.")
            }
            return shouldDisplay
        case .none:
            Exponea.logger.log(.warning, message: "Unknown in-app message frequency.")
            return true
        }
    }
}

struct InAppMessageTrigger: Codable, Equatable {
    public let type: String?
    public let eventType: String?

    enum CodingKeys: String, CodingKey {
        case type
        case eventType = "event_type"
    }
}

enum InAppMessageFrequency: String {
    case always = "always"
    case onlyOnce = "only_once"
    case oncePerVisit = "once_per_visit"
    case untilVisitorInteracts = "until_visitor_interacts"
}

enum InAppMessageType: String, CaseIterable {
    case modal
    case alert
    case fullscreen
    case slideIn = "slide_in"
}

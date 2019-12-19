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
    public let messageType: String
    public let rawFrequency: String
    public var frequency: InAppMessageFrequency? { return InAppMessageFrequency(rawValue: rawFrequency) }
    public let payload: InAppMessagePayload
    public let variantId: Int
    public let variantName: String
    public let trigger: InAppMessageTrigger
    public let dateFilter: DateFilter

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name
        case messageType = "message_type"
        case rawFrequency = "frequency"
        case payload
        case variantId = "variant_id"
        case variantName = "variant_name"
        case trigger
        case dateFilter = "date_filter"
    }

    func applyDateFilter(date: Date) -> Bool {
        guard dateFilter.enabled else {
            return true
        }
        if let start = dateFilter.startDate, start > date {
            return false
        }
        if let end = dateFilter.endDate, end < date {
            return false
        }
        return true
    }

    func applyEventFilter(eventType: String) -> Bool {
        guard let triggerType = trigger.type, let triggerEventType = trigger.eventType else {
            return false
        }
        return triggerType == "event" && triggerEventType == eventType
    }

    func applyFrequencyFilter(displayState: InAppMessageDisplayStatus, sessionStart: Date) -> Bool {
        switch frequency {
        case .some(.always):
            return true
        case .some(.onlyOnce):
            return displayState.displayed == nil
        case .some(.oncePerVisit):
            return displayState.displayed ?? Date(timeIntervalSince1970: 0) < sessionStart
        case .some(.untilVisitorInteracts):
            return displayState.interacted == nil
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

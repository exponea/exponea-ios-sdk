//
//  InAppMessage.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 28/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

public struct InAppMessage: Codable, Equatable {
    public static func == (lhs: InAppMessage, rhs: InAppMessage) -> Bool {
        lhs.id == rhs.id
    }

    public let id: String
    public let name: String
    public let rawMessageType: String?
    public var messageType: InAppMessageType {
        if isHtml {
            return .freeform
        }
        if rawMessageType == nil {
            return .alert
        }
        return InAppMessageType(rawValue: rawMessageType!) ?? .alert
    }
    public var rawFrequency: String
    public var frequency: InAppMessageFrequency? { return InAppMessageFrequency(rawValue: rawFrequency) }
    public var payload: RichInAppMessagePayload?
    public var oldPayload: InAppMessagePayload?
    public let payloadHtml: String?
    public let isHtml: Bool
    public let variantId: Int
    private let isRichText: Bool
    public let variantName: String
    public let trigger: EventFilter
    public let dateFilter: DateFilter
    public let priority: Int?
    public let delayMS: Int?
    public var delay: TimeInterval { return Double(delayMS ?? 0) / 1000.0 }
    public let timeoutMS: Int?
    public var timeout: TimeInterval? { return timeoutMS != nil ? Double(timeoutMS ?? 0 ) / 1000 : nil }
    public var rawHasTrackingConsent: Bool?
    public var hasTrackingConsent: Bool {
        return rawHasTrackingConsent ?? true
    }
    public var consentCategoryTracking: String?
    public var downloadedImage: UIImage?

    public init(
        id: String,
        name: String,
        rawMessageType: String?,
        rawFrequency: String,
        payload: RichInAppMessagePayload? = nil,
        oldPayload: InAppMessagePayload? = nil,
        variantId: Int,
        variantName: String,
        trigger: EventFilter,
        dateFilter: DateFilter,
        priority: Int? = nil,
        delayMS: Int? = nil,
        timeoutMS: Int? = nil,
        payloadHtml: String?,
        isHtml: Bool?,
        hasTrackingConsent: Bool?,
        consentCategoryTracking: String?,
        isRichText: Bool
    ) {
        self.id = id
        self.name = name
        self.rawMessageType = rawMessageType
        self.rawFrequency = rawFrequency
        self.variantId = variantId
        self.variantName = variantName
        self.trigger = trigger
        self.dateFilter = dateFilter
        self.priority = priority
        self.delayMS = delayMS
        self.timeoutMS = timeoutMS
        self.payload = payload
        self.oldPayload = oldPayload
        self.payloadHtml = payloadHtml
        self.isHtml = isHtml ?? false
        self.rawHasTrackingConsent = hasTrackingConsent
        self.consentCategoryTracking = consentCategoryTracking
        self.isRichText = isRichText
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.rawMessageType = try container.decodeIfPresent(String.self, forKey: .rawMessageType)
        self.rawFrequency = try container.decode(String.self, forKey: .rawFrequency)
        self.isRichText = try container.decode(Bool.self, forKey: .isRichText)
        if let isRichText = try? container.decodeIfPresent(Bool.self, forKey: .isRichText), isRichText {
            self.payload = try container.decodeIfPresent(RichInAppMessagePayload.self, forKey: .payload)
        } else {
            self.oldPayload = try container.decodeIfPresent(InAppMessagePayload.self, forKey: .payload)
        }
        self.variantId = try container.decode(Int.self, forKey: .variantId)
        self.variantName = try container.decode(String.self, forKey: .variantName)
        self.trigger = try container.decode(EventFilter.self, forKey: .trigger)
        self.dateFilter = try container.decode(DateFilter.self, forKey: .dateFilter)
        self.priority = try container.decodeIfPresent(Int.self, forKey: .priority)
        self.delayMS = try container.decodeIfPresent(Int.self, forKey: .delayMS)
        self.timeoutMS = try container.decodeIfPresent(Int.self, forKey: .timeoutMS)
        self.payloadHtml = try container.decodeIfPresent(String.self, forKey: .payloadHtml)
        self.isHtml = try container.decode(Bool.self, forKey: .isHtml)
        self.rawHasTrackingConsent = try container.decodeIfPresent(Bool.self, forKey: .rawHasTrackingConsent)
        self.consentCategoryTracking = try container.decodeIfPresent(String.self, forKey: .consentCategoryTracking)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.name, forKey: .name)
        try container.encodeIfPresent(self.rawMessageType, forKey: .rawMessageType)
        try container.encode(self.rawFrequency, forKey: .rawFrequency)
        try container.encodeIfPresent(self.payload, forKey: .payload)
        try container.encodeIfPresent(self.oldPayload, forKey: .payload)
        try container.encode(self.isRichText, forKey: .isRichText)
        try container.encode(self.variantId, forKey: .variantId)
        try container.encode(self.variantName, forKey: .variantName)
        try container.encode(self.trigger, forKey: .trigger)
        try container.encode(self.dateFilter, forKey: .dateFilter)
        try container.encodeIfPresent(self.priority, forKey: .priority)
        try container.encodeIfPresent(self.delayMS, forKey: .delayMS)
        try container.encodeIfPresent(self.timeoutMS, forKey: .timeoutMS)
        try container.encodeIfPresent(self.payloadHtml, forKey: .payloadHtml)
        try container.encode(self.isHtml, forKey: .isHtml)
        try container.encodeIfPresent(self.rawHasTrackingConsent, forKey: .rawHasTrackingConsent)
        try container.encodeIfPresent(self.consentCategoryTracking, forKey: .consentCategoryTracking)
    }

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name
        case rawMessageType = "message_type"
        case rawFrequency = "frequency"
        case payload
        case isRichText = "is_rich_text"
        case variantId = "variant_id"
        case variantName = "variant_name"
        case trigger
        case dateFilter = "date_filter"
        case priority = "load_priority"
        case delayMS = "load_delay"
        case timeoutMS = "close_timeout"
        case payloadHtml = "payload_html"
        case isHtml = "is_html"
        case rawHasTrackingConsent = "has_tracking_consent"
        case consentCategoryTracking = "consent_category_tracking"
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

    func hasPayload() -> Bool {
        payload != nil || oldPayload != nil || (isHtml && payloadHtml != nil)
    }
}

public struct InAppMessageTrigger: Codable, Equatable {
    public let type: String?
    public let eventType: String?

    enum CodingKeys: String, CodingKey {
        case type
        case eventType = "event_type"
    }
    
    public init(type: String?, eventType: String?) {
        self.type = type
        self.eventType = eventType
    }
}

public enum InAppMessageFrequency: String {
    case always = "always"
    case onlyOnce = "only_once"
    case oncePerVisit = "once_per_visit"
    case untilVisitorInteracts = "until_visitor_interacts"
}

public enum InAppMessageType: String, CaseIterable {
    case modal
    case alert
    case fullscreen
    case slideIn = "slide_in"
    case freeform
}

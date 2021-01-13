//
//  PushOpenedData.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 07/09/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation

struct PushOpenedData {
    let silent: Bool
    let campaignData: CampaignData
    let actionType: ExponeaNotificationActionType
    let actionValue: String?
    let eventType: EventType
    let eventData: [DataType]
    let extraData: [String: Any]?
}

extension PushOpenedData: Equatable {
    static func == (
        lhs: PushOpenedData,
        rhs: PushOpenedData
    ) -> Bool {
        guard lhs.silent == rhs.silent &&
              lhs.campaignData == rhs.campaignData &&
              lhs.actionType == rhs.actionType &&
              lhs.actionValue == rhs.actionValue &&
              lhs.eventData == rhs.eventData else {
            return false
        }
        if lhs.extraData == nil && rhs.extraData == nil {
            return true
        }
        if let lhsExtraData = lhs.extraData, let rhsExtraData = rhs.extraData {
            return NSDictionary(dictionary: lhsExtraData).isEqual(to: rhsExtraData)
        } else {
            return false
        }
    }
}

extension PushOpenedData: Codable {
    enum CodingKeys: String, CodingKey {
        case silent
        case campaignData
        case actionType
        case actionValue
        case eventType
        case eventData
        case extraData
    }

    public init(from decoder: Decoder) throws {
        let data = try decoder.container(keyedBy: CodingKeys.self)
        silent = try data.decode(Bool.self, forKey: .silent)
        campaignData = try data.decode(CampaignData.self, forKey: .campaignData)
        actionType = try data.decode(ExponeaNotificationActionType.self, forKey: .actionType)
        actionValue = try data.decode(String?.self, forKey: .actionValue)
        eventType = try data.decode(EventType.self, forKey: .eventType)
        eventData = try data.decode([DataType].self, forKey: .eventData)
        if let extraDataString = try? data.decode(String.self, forKey: .extraData),
           let data = extraDataString.data(using: .utf8) {
            extraData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } else {
            extraData = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(silent, forKey: .silent)
        try container.encode(campaignData, forKey: .campaignData)
        try container.encode(actionType, forKey: .actionType)
        try container.encode(actionValue, forKey: .actionValue)
        try container.encode(eventType, forKey: .eventType)
        try container.encode(eventData, forKey: .eventData)
        if let extraData = extraData {
            let serializedExtraData = try JSONSerialization.data(withJSONObject: extraData, options: [])
            try container.encode(String(data: serializedExtraData, encoding: .utf8), forKey: .extraData)
        }
    }

    public static func deserialize(from data: Data) -> PushOpenedData? {
        do {
            return try JSONDecoder.snakeCase.decode(PushOpenedData.self, from: data)
        } catch {
            Exponea.logger.log(.error, message: "Decoding push opened data failed: \(error.localizedDescription)")
        }
        return nil
    }

    public func serialize() -> Data? {
        return try? JSONEncoder.snakeCase.encode(self)
    }
}

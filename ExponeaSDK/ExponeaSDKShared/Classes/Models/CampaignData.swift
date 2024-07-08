//
//  CampaignData.swift
//  ExponeaSDKShared
//
//  Created by Panaxeo on 08/06/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

public struct CampaignData {
    public let source: String?
    public let campaign: String?
    public let content: String?
    public let medium: String?
    public let term: String?
    public let payload: String?
    public let timestamp: TimeInterval
    public let url: String?

    public init(
        source: String? = nil,
        campaign: String? = nil,
        content: String? = nil,
        medium: String? = nil,
        term: String? = nil,
        payload: String? = nil
    ) {
        self.url = nil
        self.timestamp = Date().timeIntervalSince1970
        self.source = source
        self.campaign = campaign
        self.content = content
        self.medium = medium
        self.term = term
        self.payload = payload
    }

    public init(url: URL) {
        let params = NSURLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems
        if params == nil {
            Exponea.logger.log(.warning, message: "Unable to parse universal link parameters.")
            // continue with creation of empty dict
        }
        let paramsMap = params?.reduce(into: [String: Any?]()) { partialResult, item in
            // keep first occurence
            partialResult[item.name] = partialResult[item.name] ?? item.value
        } ?? [:]
        self.init(source: paramsMap, url: url.absoluteString)
    }

    public init(source: [String: Any?], url: String? = nil) {
        self.url = url
        self.source = source["utm_source"] as? String
        campaign = source["utm_campaign"] as? String
        content = source["utm_content"] as? String
        medium = source["utm_medium"] as? String
        term = source["utm_term"] as? String
        payload = source["xnpe_cmp"] as? String
        timestamp = Date().timeIntervalSince1970
    }

    public var trackingData: [String: JSONValue] {
        var data: [String: JSONValue] = [:]
        if let url = url { data["url"] = .string(url) }
        if let source = source { data["utm_source"] = .string(source) }
        if let campaign = campaign { data["utm_campaign"] = .string(campaign) }
        if let content = content { data["utm_content"] = .string(content) }
        if let medium = medium { data["utm_medium"] = .string(medium) }
        if let term = term { data["utm_term"] = .string(term) }
        if let payload = payload { data["xnpe_cmp"] = .string(payload) }
        return data
    }
    
    public var isValid: Bool {
        // xnpe_cmp is required
        return payload?.count ?? 0 > 0
    }
}

extension CampaignData: Codable {
    // since we use snake case conversion, these need to be camelCase
    enum CodingKeys: String, CodingKey {
        case url = "url"
        case source = "utmSource"
        case campaign = "utmCampaign"
        case content = "utmContent"
        case medium = "utmMedium"
        case term = "utmTerm"
        case payload = "xnpeCmp"
    }

    public init(from decoder: Decoder) throws {
        let data = try decoder.container(keyedBy: CodingKeys.self)
        url = try? data.decode(String.self, forKey: .url)
        source = try? data.decode(String.self, forKey: .source)
        campaign = try? data.decode(String.self, forKey: .campaign)
        content = try? data.decode(String.self, forKey: .content)
        medium = try? data.decode(String.self, forKey: .medium)
        term = try? data.decode(String.self, forKey: .term)
        payload = try? data.decode(String.self, forKey: .payload)
        timestamp = Date().timeIntervalSince1970
    }
}

extension CampaignData: Equatable {
    // compare everything except timestamp
    public static func == (lhs: CampaignData, rhs: CampaignData) -> Bool {
        return lhs.url == rhs.url
            && lhs.source == rhs.source
            && lhs.campaign == rhs.campaign
            && lhs.content == rhs.content
            && lhs.medium == rhs.medium
            && lhs.term == rhs.term
            && lhs.payload == rhs.payload
    }
}

extension CampaignData: CustomStringConvertible {
    public var description: String {
        return """
        Campaign data
        url: \(url ?? "")
        utm_source: \(source ?? "")
        utm_campaign: \(campaign ?? "")
        utm_content: \(content ?? "")
        utm_medium: \(medium ?? "")
        utm_term: \(term ?? "")
        xnpe_cmp: \(payload ?? "")
        """
    }
}

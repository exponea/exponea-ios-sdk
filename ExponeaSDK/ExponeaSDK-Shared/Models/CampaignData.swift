//
//  CampaignData.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 08/06/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

public struct CampaignData: Codable {
    let source: String?
    let campaign: String?
    let content: String?
    let medium: String?
    let term: String?
    let payload: String?
    let timestamp: TimeInterval
    let url: String?

    init(url: URL) {
        self.url = url.absoluteString
        self.timestamp = Date().timeIntervalSince1970
        guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
              let params = components.queryItems else {
            Exponea.logger.log(.warning, message: "Unable to parse universal link parameters.")
            self.source = nil
            self.campaign = nil
            self.content = nil
            self.medium = nil
            self.term = nil
            self.payload = nil
            return
        }
        self.source = params.first {$0.name == "utm_source"}?.value
        self.campaign = params.first {$0.name == "utm_campaign"}?.value
        self.content = params.first {$0.name == "utm_content"}?.value
        self.medium = params.first {$0.name == "utm_medium"}?.value
        self.term = params.first {$0.name == "utm_term"}?.value
        self.payload = params.first {$0.name == "xnpe_cmp"}?.value
    }

    var trackingData: [String: JSONValue] {
        var data: [String: JSONValue] = [:]
        data["platform"] = .string("iOS")
        if let url = url { data["url"] = .string(url) }
        if let source = source { data["utm_source"] = .string(source) }
        if let campaign = campaign { data["utm_campaign"] = .string(campaign) }
        if let content = content { data["utm_content"] = .string(content) }
        if let medium = medium { data["utm_medium"] = .string(medium) }
        if let term = term { data["utm_term"] = .string(term) }
        if let payload = payload { data["xnpe_cmp"] = .string(payload) }
        return data
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

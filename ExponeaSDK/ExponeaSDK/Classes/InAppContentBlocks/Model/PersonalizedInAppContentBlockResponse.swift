//
//  InAppContentBlockResponse.swift
//  ExponeaSDK
//
//  Created by Ankmara on 29.05.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//
import Foundation

public enum InAppContentBlocksStatus: String, Codable {
    case ok = "OK"
    case filterNotMatched = "filter_not_matched"
    case doesNotExist = "does_not_exist"
}

public struct Content: Codable {
    public var html: String
}

public struct PersonalizedInAppContentBlockResponseData: Codable {
    let data: [PersonalizedInAppContentBlockResponse]
}

public struct PersonalizedInAppContentBlockResponse: Codable {
    public let id: String
    public let status: InAppContentBlocksStatus
    public let ttlSeconds: Int
    public var variantId: Int?
    public var hasTrackingConsent: Bool?
    public var variantName: String?
    public var contentType: InAppContentBlockContentType?
    public var content: Content?
    @CodableIgnored
    var htmlPayload: NormalizedResult?
    @CodableIgnored
    public var ttlSeen: Date?
    @CodableIgnored
    public var tag: Int?
    public var isCorruptedImage = false

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case status = "status"
        case ttlSeconds = "ttl_seconds"
        case variantId = "variant_id"
        case hasTrackingConsent = "has_tracking_consent"
        case variantName = "variant_name"
        case contentType = "content_type"
        case content = "content"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.status = try container.decode(InAppContentBlocksStatus.self, forKey: .status)
        self.ttlSeconds = try container.decode(Int.self, forKey: .ttlSeconds)
        self.variantId = try container.decodeIfPresent(Int.self, forKey: .variantId)
        self.hasTrackingConsent = try container.decodeIfPresent(Bool.self, forKey: .hasTrackingConsent)
        self.variantName = try container.decodeIfPresent(String.self, forKey: .variantName)
        contentType = nil
        if let contentType = try? container.decodeIfPresent(String.self, forKey: .contentType) {
            self.contentType = .init(status: contentType)
        }
        self.content = try container.decodeIfPresent(Content.self, forKey: .content)
    }

    init(
        id: String,
        status: InAppContentBlocksStatus,
        ttlSeconds: Int,
        variantId: Int?,
        hasTrackingConsent: Bool?,
        variantName: String?,
        contentType: InAppContentBlockContentType?,
        content: Content?,
        htmlPayload: NormalizedResult?,
        ttlSeen: Date?
    ) {
        self.id = id
        self.status = status
        self.ttlSeconds = ttlSeconds
        self.variantId = variantId
        self.hasTrackingConsent = hasTrackingConsent
        self.variantId = variantId
        self.variantName = variantName
        self.content = content
        self.contentType = contentType
        self.htmlPayload = htmlPayload
        self.ttlSeen = ttlSeen
    }
}

extension PersonalizedInAppContentBlockResponse {
    func describeDetailed() -> String {
        return """
        {
            id: \(id),
            status: \(status),
            ttlSeconds: \(ttlSeconds),
            variantId: \(String(describing: variantId)),
            hasTrackingConsent: \(String(describing: hasTrackingConsent)),
            variantName: \(String(describing: variantName)),
            contentType: \(String(describing: contentType)),
            ttlSeen: \(String(describing: ttlSeen)),
            tag: \(String(describing: tag)),
            isCorruptedImage: \(isCorruptedImage)
        }
        """
    }
}

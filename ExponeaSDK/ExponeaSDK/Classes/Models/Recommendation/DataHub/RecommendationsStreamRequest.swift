import Foundation

public struct RecommendationsStreamRequest: RequestParametersType {
    let customerIds: [String: Any?]
    let engineId: String
    let fillWithRandom: Bool
    let size: Int
    let items: [String: String]?
    let noTrack: Bool?
    let catalogAttributesWhitelist: [String]?

    public init(
        customerIds: [String: Any?],
        engineId: String,
        fillWithRandom: Bool,
        size: Int = 10,
        items: [String: String]? = nil,
        noTrack: Bool? = nil,
        catalogAttributesWhitelist: [String]? = nil
    ) {
        self.customerIds = customerIds
        self.engineId = engineId
        self.fillWithRandom = fillWithRandom
        self.size = size
        self.items = items
        self.noTrack = noTrack
        self.catalogAttributesWhitelist = catalogAttributesWhitelist
    }

    public var parameters: [String: JSONValue] {
        var data: [String: JSONValue] = [
            "engine_id": .string(engineId),
            "fill_with_random": .bool(fillWithRandom),
            "size": .int(size)
        ]
        
        let customerIdValues: [String: Any] = customerIds.compactMapValues { value in
            guard let value = value else { return nil }
            return value
        }
        if !customerIdValues.isEmpty {
            data["customer_ids"] = .dictionary(JSONValue.convert(customerIdValues))
        }
        
        if let items = items {
            data["items"] = .dictionary(items.mapValues { .string($0) })
        }
        
        if let noTrack = noTrack {
            data["no_track"] = .bool(noTrack)
        }
        
        if let catalogAttributesWhitelist = catalogAttributesWhitelist {
            data["catalog_attributes_whitelist"] = .array(catalogAttributesWhitelist.map { .string($0) })
        }
        
        return data
    }
}

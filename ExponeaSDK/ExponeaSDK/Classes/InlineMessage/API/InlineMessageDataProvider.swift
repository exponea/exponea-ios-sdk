//
//  InlineMessageDataProvider.swift
//  ExponeaSDK
//
//  Created by Ankmara on 21.05.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation

public protocol InlineMessageDataProviderType {
    func loadPersonalizedInlineMessages<Data: Codable>(
        data: Data.Type,
        customerIds: [String: String],
        inlineMessageIds: [String],
        completion: @escaping TypeBlock<ResponseData<Data>>
    )
    func getInlineMessages<Data: Codable>(
        data: Data.Type,
        completion: @escaping TypeBlock<ResponseData<Data>>
    )
}

public final class InlineMessageDataProvider {

    // MARK: - Properties
    private lazy var serverRepository = Exponea.shared.repository
    public init() {}
}

public struct ResponseData<Data: Codable> {
    var data: Data?
    var error: Error?
}

// MARK: - InlineMessageDataProviderType
extension InlineMessageDataProvider: InlineMessageDataProviderType {
    public func getInlineMessages<Data: Codable>(
        data: Data.Type = Data.self,
        completion: @escaping TypeBlock<ResponseData<Data>>
    ) {
        guard let serverRepository = serverRepository else { return }
        serverRepository.getInlineMessages { response in
            guard response.error == nil, let data = response.value as? Data else {
                completion(.init(error: response.error))
                return
            }
            completion(.init(data: data, error: nil))
        }
    }

    public func loadPersonalizedInlineMessages<D: Codable>(
        data: D.Type = D.self,
        customerIds: [String: String],
        inlineMessageIds: [String],
        completion: @escaping TypeBlock<ResponseData<D>>
    ) {
        guard let serverRepository = serverRepository else { return }
        serverRepository.personalizedInlineMessages(
            customerIds: customerIds,
            inlineMessageIds: inlineMessageIds
        ) { response in
            guard response.error == nil, let data = response.value as? D else {
                completion(.init(error: response.error))
                return
            }
            completion(.init(data: data, error: nil))
        }
    }
}

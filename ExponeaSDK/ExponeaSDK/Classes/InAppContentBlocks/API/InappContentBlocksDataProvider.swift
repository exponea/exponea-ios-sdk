//
//  InAppContentBlocksDataProvider.swift
//  ExponeaSDK
//
//  Created by Ankmara on 21.05.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation

public protocol InAppContentBlocksDataProviderType {
    func loadPersonalizedInAppContentBlocks<Data: Codable>(
        data: Data.Type,
        customerIds: [String: String],
        inAppContentBlocksIds: [String],
        completion: @escaping TypeBlock<ResponseData<Data>>
    )
    func getInAppContentBlocks<Data: Codable>(
        data: Data.Type,
        completion: @escaping TypeBlock<ResponseData<Data>>
    )
}

/// Internal overload for conditional revalidation; not part of the public API.
protocol InAppContentBlocksETagDataProviding {
    func loadPersonalizedInAppContentBlocks<Data: Codable>(
        data: Data.Type,
        customerIds: [String: String],
        inAppContentBlocksIds: [String],
        etag: String?,
        onNotModified: (() -> Void)?,
        onEtagHeader: ((String) -> Void)?,
        completion: @escaping TypeBlock<ResponseData<Data>>
    )
}

/// Default implementation delegates to the standard fetch without conditional headers.
extension InAppContentBlocksETagDataProviding where Self: InAppContentBlocksDataProviderType {
    func loadPersonalizedInAppContentBlocks<Data: Codable>(
        data: Data.Type,
        customerIds: [String: String],
        inAppContentBlocksIds: [String],
        etag: String?,
        onNotModified: (() -> Void)?,
        onEtagHeader: ((String) -> Void)?,
        completion: @escaping TypeBlock<ResponseData<Data>>
    ) {
        loadPersonalizedInAppContentBlocks(
            data: data,
            customerIds: customerIds,
            inAppContentBlocksIds: inAppContentBlocksIds,
            completion: completion
        )
    }
}

public struct ResponseData<Data: Codable> {
    var data: Data?
    var error: Error?
}

public final class InAppContentBlocksDataProvider {

    // MARK: - Properties
    private lazy var serverRepository = Exponea.shared.repository
    public init() {}
}

// MARK: - InAppContentBlocksDataProviderType
extension InAppContentBlocksDataProvider: InAppContentBlocksDataProviderType {
    public func getInAppContentBlocks<Data: Codable>(
        data: Data.Type = Data.self,
        completion: @escaping TypeBlock<ResponseData<Data>>
    ) {
        guard let serverRepository = serverRepository else {
            completion(
                .init(
                    error: NSError(
                        domain: "com.exponea.in-app-content-blocks",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "In-app content-block repository is unavailable"]
                    )
                )
            )
            return
        }
        serverRepository.getInAppContentBlocks { response in
            guard response.error == nil, let data = response.value as? Data else {
                completion(.init(error: response.error))
                return
            }
            completion(.init(data: data, error: nil))
        }
    }

    public func loadPersonalizedInAppContentBlocks<D: Codable>(
        data: D.Type = D.self,
        customerIds: [String: String],
        inAppContentBlocksIds: [String],
        completion: @escaping TypeBlock<ResponseData<D>>
    ) {
        loadPersonalizedInAppContentBlocks(
            data: data,
            customerIds: customerIds,
            inAppContentBlocksIds: inAppContentBlocksIds,
            etag: nil,
            onNotModified: nil,
            onEtagHeader: nil,
            completion: completion
        )
    }
}

// MARK: - InAppContentBlocksETagDataProviding
extension InAppContentBlocksDataProvider: InAppContentBlocksETagDataProviding {
    func loadPersonalizedInAppContentBlocks<D: Codable>(
        data: D.Type = D.self,
        customerIds: [String: String],
        inAppContentBlocksIds: [String],
        etag: String?,
        onNotModified: (() -> Void)?,
        onEtagHeader: ((String) -> Void)?,
        completion: @escaping TypeBlock<ResponseData<D>>
    ) {
        guard !IntegrationManager.shared.isStopped else {
            Exponea.logger.log(.verbose, message: "In-app content blocks fetch failed: SDK is stopping")
            completion(.init(error: NSError(
                domain: "com.exponea.in-app-content-blocks",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "In-app content blocks fetch failed: SDK is stopping"]
            )))
            return
        }
        guard let serverRepository = serverRepository else {
            completion(.init(error: NSError(
                domain: "com.exponea.in-app-content-blocks",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "In-app content-block repository is unavailable"]
            )))
            return
        }
        serverRepository.personalizedInAppContentBlocks(
            customerIds: customerIds,
            inAppContentBlocksIds: inAppContentBlocksIds,
            etag: etag,
            onNotModified: onNotModified,
            onEtagHeader: onEtagHeader
        ) { response in
            guard !IntegrationManager.shared.isStopped else {
                Exponea.logger.log(.verbose, message: "In-app content blocks fetch failed: SDK is stopping")
                completion(.init(error: NSError(
                    domain: "com.exponea.in-app-content-blocks",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "In-app content blocks fetch failed: SDK is stopping"]
                )))
                return
            }
            guard response.error == nil, let data = response.value as? D else {
                completion(.init(error: response.error))
                return
            }
            completion(.init(data: data, error: nil))
        }
    }
}

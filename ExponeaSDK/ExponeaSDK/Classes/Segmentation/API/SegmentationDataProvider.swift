//
//  SegmentationDataProvider.swift
//  ExponeaSDK
//
//  Created by Ankmara on 18.04.2024.
//  Copyright © 2024 Exponea. All rights reserved.
//

import Foundation

public protocol SegmentationDataProviderType {
    func getSegmentations<D: Codable>(
       data: D.Type,
       cookie: String,
       completion: @escaping TypeBlock<ResponseData<D>>
    )
    func linkIds<D: Codable>(
       data: D.Type,
       cookie: String,
       externalIds: [String: String],
       completion: @escaping TypeBlock<ResponseData<D>>
    )
}

public final class SegmentationDataProvider {

    // MARK: - Properties
    private lazy var serverRepository = Exponea.shared.repository
    public init() {}
}

// MARK: - InAppContentBlocksDataProviderType
extension SegmentationDataProvider: SegmentationDataProviderType {
    public func getSegmentations<D: Codable>(
        data: D.Type,
        cookie: String,
        completion: @escaping TypeBlock<ResponseData<D>>
    ) {
        guard let serverRepository = serverRepository else { return }
        serverRepository.getSegmentations(cookie: cookie) { response in
            guard response.error == nil, let data = response.value as? D else {
                completion(.init(error: response.error))
                return
            }
            completion(.init(data: data, error: nil))
        }
    }

    public func linkIds<D>(
        data: D.Type,
        cookie: String,
        externalIds: [String: String],
        completion: @escaping TypeBlock<ResponseData<D>>) {
            guard let serverRepository = serverRepository else { return }
            serverRepository.getLinkIds(cookie: cookie, externalIds: externalIds) { response in
                guard response.error == nil, let data = response.value as? D else {
                    completion(.init(error: response.error))
                    return
                }
                completion(.init(data: data, error: nil))
            }
    }
}

//
//  TrackingRepository.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 05/03/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation

protocol TrackingRepository {
    func trackObject(
        _ object: TrackingObject,
        for customerIds: [String: JSONValue],
        completion: @escaping ((EmptyResult<RepositoryError>) -> Void)
    )
}

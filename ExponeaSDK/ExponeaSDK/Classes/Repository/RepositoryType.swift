//
//  Repository.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 04/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

protocol RepositoryType: class, TrackingRepository, FetchRepository, SelfCheckRepository {
    var configuration: Configuration { get set }

    /// Cancels all requests that are currently underway.
    func cancelRequests()
}

extension ServerRepository: RepositoryType {}

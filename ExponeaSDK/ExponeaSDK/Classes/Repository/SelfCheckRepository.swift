//
//  SelfCheckRepository.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 26/05/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation

protocol SelfCheckRepository {
    func requestSelfCheckPush(
        for customerIds: [String: String],
        pushToken: String,
        completion: @escaping (EmptyResult<RepositoryError>) -> Void
    )
}

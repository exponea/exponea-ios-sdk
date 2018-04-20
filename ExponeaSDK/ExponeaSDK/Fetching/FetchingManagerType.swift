//
//  FetchingManagerType.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 19/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

protocol FetchingManagerType {
    func fetchRequest<T: Codable>(with type: EventType, data: [DataType], completion: @escaping (APIResult<T>) -> Void)
}

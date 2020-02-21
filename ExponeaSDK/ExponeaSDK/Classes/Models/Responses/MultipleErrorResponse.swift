//
//  ErrorResponse.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 31/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

struct ErrorResponse: Codable {
    let error: String
    let success: Bool
}

struct MultipleErrorResponse: Codable {
    let errors: [ErrorContent]
    let success: Bool
}

struct ErrorContent: Codable {
    let code: Int
    let description: String
    let message: String
}

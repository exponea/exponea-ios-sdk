//
//  ErrorResponse.swift
//  ExponeaSDKShared
//
//  Created by Dominik Hadl on 31/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

public struct ErrorResponse: Codable {
    public let error: String
    public let success: Bool
}

public struct MultipleErrorResponse: Codable {
    public let errors: [ErrorContent]
    public let success: Bool
}

public struct ErrorContent: Codable {
    public let code: Int
    public let description: String
    public let message: String
}

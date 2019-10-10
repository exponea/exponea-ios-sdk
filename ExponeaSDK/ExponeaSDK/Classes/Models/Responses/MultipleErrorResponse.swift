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

/// A structure contain
struct MultipleErrorResponse: Codable {

    /// <#Description#>
    let errors: [ErrorContent]

    /// <#Description#>
    let success: Bool
}

/// <#Description#>
struct ErrorContent: Codable {

    /// <#Description#>
    let code: Int

    /// <#Description#>
    let description: String

    /// <#Description#>
    let message: String
}

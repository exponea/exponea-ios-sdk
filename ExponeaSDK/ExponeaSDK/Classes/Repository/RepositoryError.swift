//
//  RepositoryError.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 10/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

enum RepositoryError: Error {
    case missingData(String)
    case invalidResponse(URLResponse?)
    
    var localizedDescription: String {
        switch self {
        case .missingData(let details):
            return "Request is missing required data: \(details)."
        case .invalidResponse(let response):
            return "An invalid response was received from the API: \(response != nil ? "\(response!)" : "No response.")"
        }
    }
}

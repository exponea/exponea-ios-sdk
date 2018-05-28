//
//  ValueResponse.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 20/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// Data type used to return the fetch any string response in a API call.
/// It returns the status and the object in case of success, otherwise
/// return the error from the Exponea API.
/// This struct is conform to the Codable protocol who are responsible
/// to serialize and deserialize the data.
public struct StringResponse: Codable {
    
    /// Status of the http response.
    public let success: Bool?
    
    /// Holds the string data from the Exponea API.
    public let value: String?
}

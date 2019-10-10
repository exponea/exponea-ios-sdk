//
//  EntityValueResponse.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 02/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// Data type used to return the fetch entity response in a API call.
/// It returns the status and the object in case of success, otherwise
/// return the error from the Exponea API.
/// This struct is conform to the Codable protocol who are responsible
/// to serialize and deserialize the data.
struct EntityValueResponse: Codable {

    /// Status of the http response.
    public let success: Bool

    /// Value of the entity requested.
    public let value: Double

    /// Name of the entity requested.
    public let entityName: String
}

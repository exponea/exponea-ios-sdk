//
//  Constants.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 06/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// enum with constants used through the SDK
enum Constants {
    /// Network
    enum Repository {
        static let baseURL = "https://api.exponea.com/"
        static let contentType = "application/json"
        static let headerContentType = "Content-Type"
        static let headerAccept = "Accept"
        static let headerContentLenght = "Content-length"
    }
    /// Plist keys
    enum Keys {
        static let token = "exponeaProjectIdKey"
    }
}

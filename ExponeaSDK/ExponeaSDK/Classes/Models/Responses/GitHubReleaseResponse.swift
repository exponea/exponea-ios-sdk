//
//  VersionResponse.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 25/04/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//


import Foundation

/// The response returned when fetching last published SDK version from GitHub
public struct GitHubReleaseResponse: Codable {
    let version: String
}

private extension GitHubReleaseResponse {
    enum CodingKeys: String, CodingKey {
        case version = "tag_name"
    }
}

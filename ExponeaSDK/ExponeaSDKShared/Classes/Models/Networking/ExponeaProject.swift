//
//  ExponeaProject.swift
//  ExponeaSDKShared
//
//  Created by Panaxeo on 03/04/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

public struct ExponeaProject: Equatable, Codable {
    public let baseUrl: String
    public let projectToken: String
    public let authorization: Authorization

    public init(baseUrl: String = Constants.Repository.baseUrl, projectToken: String, authorization: Authorization) {
        self.baseUrl = baseUrl
        self.projectToken = projectToken
        self.authorization = authorization
    }

    public init(from decoder: Decoder) throws {
        let data = try decoder.container(keyedBy: CodingKeys.self)
        baseUrl = (try? data.decode(String.self, forKey: .baseUrl)) ?? Constants.Repository.baseUrl
        projectToken = try data.decode(String.self, forKey: .projectToken)
        authorization = try data.decode(Authorization.self, forKey: .authorization)
    }
}

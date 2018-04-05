//
//  Router.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 05/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

protocol RouterRequest {
    var method: HTTPMethod { get }
    var path: String { get }
    var params: [String: Any]? { get }
}

struct Router {

    /// Set the route and parameters for Track Customer request
    struct TrackCustomer: RouterRequest {
        let projectId: String
        let param: [String: Any]?

        var method: HTTPMethod { return .post }
        var path: String { return "/track/v2/\(projectId)/customers" }
        var params: [String: Any]? { return param }
    }

    /// Set the route and parameters for Track Events request
    struct TrackEvents: RouterRequest {
        let projectId: String
        let param: [String: Any]?

        var method: HTTPMethod { return .post }
        var path: String { return "/track/v2/\(projectId)/events" }
        var params: [String: Any]? { return param }
    }

}

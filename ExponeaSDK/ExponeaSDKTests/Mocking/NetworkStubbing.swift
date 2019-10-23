//
//  NetworkStubbing.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 30/09/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation
import Mockingjay

struct NetworkStubbing {
    static func stubNetwork(
        forProjectToken projectToken: String,
        withStatusCode statusCode: Int,
        withDelay delay: TimeInterval = TimeInterval(0),
        withResponseData responseData: Data? = nil,
        withRequestHook requestHook: ((URLRequest) -> Void)? = nil
    ) {
        let stubResponse = HTTPURLResponse(
            url: URL(string: "mock-url")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        let stubData = responseData ?? "mock-response".data(using: String.Encoding.utf8, allowLossyConversion: true)!
        MockingjayProtocol.addStub(
            matcher: { urlRequest in
                guard
                    let url = urlRequest.url,
                    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                else {
                    return false
                }
                return components.path.contains("/projects/\(projectToken)/")
            },
            delay: delay,
            builder: { request in
                requestHook?(request)
                return Response.success(stubResponse, .content(stubData))
            }
        )
    }

    static func unstubNetwork() {
        MockingjayProtocol.removeAllStubs()
    }
}

//
//  URLRequest+Debug.swift
//  ExponeaSDKShared
//
//  Created by Dominik Hadl on 12/07/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

public extension URLRequest {
    var describe: String {
        var requestLog = "[Request]\n"

        guard let urlString = url?.absoluteString else {
            requestLog += """
            ERROR - Can't get detailed information about response.
            Request: \(self)
            """
            return requestLog
        }

        requestLog += "\(httpMethod ?? "NO METHOD") \(urlString)\n"

        for (key, value) in allHTTPHeaderFields ?? [:] {
            // Make sure we don't print out tokens
            if key == "Authorization" {
                requestLog += "Authorization: REDACTED\n"
                continue
            }

            requestLog += "\(key): \(value)\n"
        }

        // Add request body
        if let body = httpBody {
            requestLog += "HTTP Body:\n"
            if let object = try? JSONSerialization.jsonObject(with: body, options: []),
                let pretty = try? JSONSerialization.data(withJSONObject: object, options: .prettyPrinted),
                let prettyString = String(data: pretty, encoding: .utf8) {
                requestLog += prettyString
            } else {
                requestLog += String(data: body, encoding: .utf8) ?? "N/A"
            }
        }

        requestLog += "\n"
        return requestLog
    }
}

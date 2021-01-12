//
//  URLResponse+Debug.swift
//  ExponeaSDKShared
//
//  Created by Dominik Hadl on 12/07/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

public extension URLResponse {
    func description(with data: Data?, error: Error?) -> String {
        var responseLog = "[Response]\n"

        guard let urlString = url?.absoluteString else {
                responseLog += """
                ERROR - Can't get detailed information about response.
                Response: \(self)
                Error: \(error?.localizedDescription ?? String(describing: error))
                Data: \(String(describing: data))
                """
                return responseLog
        }

        if let httpResponse = self as? HTTPURLResponse {
            responseLog += "HTTP \(httpResponse.statusCode) \(urlString)\n"

            for (key, value) in httpResponse.allHeaderFields {
                responseLog += "\(key): \(value)\n"
            }
        }

        if let body = data {
            responseLog += "Response Body:\n\(String(data: body, encoding: .utf8) ?? "N/A")\n"
        }

        if let error = error {
            responseLog += "\nError: \(error.localizedDescription)\n"
        }

        responseLog += "\n"
        return responseLog
    }
}

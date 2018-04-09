//
//  APISource.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 05/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// APISource class is responsible to prepare the data used in the http request.
/// It receives all inputs for the call and return a NSMutableURLRequest.
public class APISource {

    func prepareRequest(router: APIRouter, trackingParam: TrackingParams?, customersParam: CustomersParams?) -> NSMutableURLRequest {
        let request = NSMutableURLRequest()
        var body: Data?

        request.url = URL(string: router.path)
        request.httpMethod = router.method.rawValue
        request.addValue(Constants.Repository.contentType, forHTTPHeaderField: Constants.Repository.headerContentType)
        request.addValue(Constants.Repository.contentType, forHTTPHeaderField: Constants.Repository.headerAccept)

        var params: [String: Any]?

        switch router.route {
        case .trackCustomers, .trackEvents:
            params = trackingParam?.params
        case .tokenRotate, .tokenRevoke:
            params = nil
        default:
            params = customersParam?.params
        }

        if let params = params {
            body = try? JSONSerialization.data(withJSONObject: params, options: [])
        }

        request.httpBody = body

        return request
    }

}

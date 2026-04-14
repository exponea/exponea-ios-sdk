//
//  ServerRepository+TrackingRepository.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 05/03/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation

extension ServerRepository: TrackingRepository {
    public func trackObject(
        _ trackingObject: TrackingObject,
        completion: @escaping ((EmptyResult<RepositoryError>) -> Void)
    ) {
        var properties: [String: JSONValue] = [:]

        for item in trackingObject.dataTypes {
            switch item {
            case .properties(let props): properties.merge(props, uniquingKeysWith: { first, _ in return first })
            default: continue
            }
        }

        if let customer = trackingObject as? CustomerTrackingObject {
            uploadTrackingData(
                into: trackingObject.exponeaProject,
                trackingParameters: TrackingParameters(
                    customerIds: customer.customerIds,
                    properties: properties,
                    timestamp: customer.timestamp
                ),
                route: .identifyCustomer,
                completion: completion
            )
        } else if let event = trackingObject as? EventTrackingObject {
            uploadTrackingData(
                into: trackingObject.exponeaProject,
                trackingParameters: TrackingParameters(
                    customerIds: event.customerIds,
                    properties: properties,
                    timestamp: event.timestamp,
                    eventType: event.eventType
                ),
                route: event.eventType == Constants.EventTypes.campaignClick ? .campaignClick : .customEvent,
                completion: completion
            )
        } else {
            fatalError("Unknown tracking object type")
        }
    }

    func uploadTrackingData(
        into exponeaProject: any ExponeaIntegrationType,
        trackingParameters: TrackingParameters,
        route: Routes,
        completion: @escaping ((EmptyResult<RepositoryError>) -> Void)
    ) {
        let router = makeRouter(for: route, project: exponeaProject)
        var executeRequest: ((@escaping (Bool) -> Void) -> Void)?
        let (handler, startRequest) = router.handler(withRetry: { setRequestHadJwt in executeRequest?(setRequestHadJwt) }, completion: completion)
        executeRequest = { setRequestHadJwt in
            do {
                let request = try router.prepareRequest(parameters: trackingParameters)
                setRequestHadJwt(request.value(forHTTPHeaderField: Constants.Repository.headerAuthorization) != nil)
                self.session.dataTask(with: request, completionHandler: handler).resume()
            } catch {
                completion(.failure(RepositoryError.unknown(error)))
            }
        }
        startRequest()
    }
}

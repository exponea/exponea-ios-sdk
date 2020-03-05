//
//  ServerRepository+TrackingRepository.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 05/03/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation

extension ServerRepository: TrackingRepository {
    func trackObject(
        _ trackingObject: TrackingObject,
        for customerIds: [String: JSONValue],
        completion: @escaping ((EmptyResult<RepositoryError>) -> Void)
    ) {
        var properties: [String: JSONValue] = [:]

        for item in trackingObject.dataTypes {
            switch item {
            case .properties(let props): properties.merge(props, uniquingKeysWith: { first, _ in return first })
            default: continue
            }
        }

        guard let projectToken = trackingObject.projectToken else {
            completion(.failure(RepositoryError.missingData("Project token not provided.")))
            return
        }

        if let customer = trackingObject as? CustomerTrackingObject {
            uploadTrackingData(
                projectToken: projectToken,
                trackingParameters: TrackingParameters(
                    customerIds: customerIds,
                    properties: properties,
                    timestamp: customer.timestamp
                ),
                route: .identifyCustomer,
                completion: completion
            )
        } else if let event = trackingObject as? EventTrackingObject {
            uploadTrackingData(
                projectToken: projectToken,
                trackingParameters: TrackingParameters(
                    customerIds: customerIds,
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
        projectToken: String,
        trackingParameters: TrackingParameters,
        route: Routes,
        completion: @escaping ((EmptyResult<RepositoryError>) -> Void)
    ) {
        let router = RequestFactory(
            baseUrl: configuration.baseUrl,
            projectToken: projectToken,
            route: route
        )
        let request = router.prepareRequest(
            authorization: configuration.authorization,
            parameters: trackingParameters
        )

        session
            .dataTask(with: request, completionHandler: router.handler(with: completion))
            .resume()
    }
}

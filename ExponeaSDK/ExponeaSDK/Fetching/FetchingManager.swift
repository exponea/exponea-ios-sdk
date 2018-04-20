//
//  FetchingManager.swift
//  ExponeaSDK
//
//  Created by Ricardo Tokashiki on 19/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

class FetchingManager {
    let repository: ConnectionManagerType
    let device: DeviceProperties
    var configuration: Configuration

    init(repository: ConnectionManagerType, configuration: Configuration) {
        self.repository = repository
        self.configuration = configuration
        self.device = DeviceProperties()
    }
}

extension FetchingManager: FetchingManagerType {
    func fetchRequest<T: Codable>(with type: EventType,
                                  data: [DataType],
                                  completion: @escaping (APIResult<T>) -> Void) {

        guard let projectToken = Exponea.shared.projectToken else {
            Exponea.logger.log(.error, message: Constants.ErrorMessages.tokenNotConfigured)
            return
        }

        switch type {
        case .fetchEvents:
            repository.fetchEvents(projectToken: projectToken,
                                   customerId: getCustomerId(data: data)!,
                                   events: getEvents(data: data)!) { (result: APIResult<EventsResult>) in
                //completion(result)
            }
        default:
            break
        }
    }
}

extension FetchingManager {
    func getCustomerId(data: [DataType]) -> KeyValueModel? {
        for customer in data {
            switch customer {
            case .customerId(let value):
                return value
            default:
                return nil
            }
        }
        return nil
    }
    func getEvents(data: [DataType]) -> CustomerEvents? {
        for customer in data {
            switch customer {
            case .events(let value):
                return value
            default:
                return nil
            }
        }
        return nil
    }
}

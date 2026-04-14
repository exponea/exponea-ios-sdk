//
//  FlushableObject.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 24/02/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import CoreData

protocol DatabaseObject {
    var objectID: NSManagedObjectID { get }
    var retries: NSNumber { get set }
}

final class DatabaseObjectProxy {
    let objectID: NSManagedObjectID
    let retries: Int

    public init(_ databaseObject: DatabaseObject) {
        objectID = databaseObject.objectID
        retries = databaseObject.retries.intValue
    }
}

protocol FlushableObject {
    var databaseObjectProxy: DatabaseObjectProxy { get }

    func getTrackingObject(
        defaultBaseUrl: String,
        defaultIntegrationId: String,
        defaultAuthorization: Authorization
    ) -> TrackingObject
}

extension FlushableObject {
    func getExponeaIntegrationType(
        integrationType: String?,
        baseUrl: String,
        integrationId: String,
        auth: Authorization
    ) -> any ExponeaIntegrationType {
        guard let type = integrationType, type == IntegrationSourceType.stream(streamId: "").rawValue else {
            return ExponeaProject(
                baseUrl: baseUrl,
                projectToken: integrationId,
                authorization: auth
            )
        }
        return ExponeaIntegration(
            baseUrl: baseUrl,
            streamId: integrationId
        )
    }
}

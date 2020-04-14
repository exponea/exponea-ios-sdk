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
        defaultProjectToken: String,
        defaultAuthorization: Authorization
    ) -> TrackingObject
}

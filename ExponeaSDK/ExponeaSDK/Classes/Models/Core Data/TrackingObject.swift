//
//  TrackingObject.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 24/02/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import CoreData

protocol TrackingObjectProxy {
    var managedObjectID: NSManagedObjectID { get }
    var retries: Int { get }
}

protocol TrackingObject {
    var retries: NSNumber { get set }
}

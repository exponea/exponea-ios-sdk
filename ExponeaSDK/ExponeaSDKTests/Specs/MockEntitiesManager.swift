//
//  EntitiesManager.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 11/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import CoreData

@testable import ExponeaSDK

class MockEntitiesManager: DatabaseManager {

    lazy var managedObjectModel: NSManagedObjectModel = {
        let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle(for: type(of: self))] )!
        return managedObjectModel
    }()

    lazy var mockPersistantContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "DatabaseModel", managedObjectModel: self.managedObjectModel)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false // Make it simpler in test env
        print(container.description)
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { (description, error) in
            // Check if the data store is in memory
            precondition( description.type == NSInMemoryStoreType )
            // Check if creating container wrong
            if let error = error {
                fatalError("Create an in-mem coordinator failed \(error)")
            }
        }
        return container
    }()

    override var managedObjectContext: NSManagedObjectContext {
        return mockPersistantContainer.viewContext
    }
}

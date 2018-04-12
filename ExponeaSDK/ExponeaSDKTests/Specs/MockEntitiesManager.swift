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

/// Mock version of EntitiesManager for testing purposes.
///
/// This intent of this class it to inherit all functionality from DatabaseManager
/// and just override the `managedObjectContext()` function to redirect the
/// the `NSPersistentStoreCoordinator` to memory instead of the actual SQLite
/// model.
///
/// This will allows us to test the functionality of the DatabaseManager
/// independently without populating in real the database and without depending
/// on the SQLite container.
///
/// - Author: Rafael Papallas

class MockEntitiesManager: DatabaseManager {
//
//    /// Returns a `NSManagedObjectContext` linking to memory instead of SQLite
//    override func managedObjectContext() -> NSManagedObjectContext {
//        return managedObjectContextLazy
//    }

    /// This will return the `NSManagedObjectContext` which in this time will
    /// be redirected to memory instead of the original DatabaseManager linking
    /// to the SQLite file.
    ///
    /// Is important to highlight that Swift doesn't like creation of more than
    /// one `NSManagedObjectContext` and therefore we had to lazly do that.
    /// The `override func managedObjectContext()` itself can't be lazy due
    /// to it's superclass constraints and therefore this helper computed property
    /// had to be implemented to bridge the incompatibility.
//    lazy var managedObjectContextLazy: NSManagedObjectContext = {
//        let coordinator = self.persistentStoreCoordinator
//
//        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
//        managedObjectContext.persistentStoreCoordinator = coordinator
//        return managedObjectContext
//    }()

    /// Gets the `NSManagedObjectModel` from the superclass
    lazy var managedObjectModel: NSManagedObjectModel = {
        let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle.main])!
        return managedObjectModel
    }()

    /// Redirects the `NSPersistentStoreCoordinator` to memory.
    ///
    /// Here is all the magic happening. The `NSPersistentStoreCoordinator` is
    /// redirected to memory instead of SQLite.
//    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
//        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
//
//        do {
//            try coordinator!.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil,
//                                                at: nil, options: nil)
//        } catch {
//            coordinator = nil
//            print("Error")
//        }
//
//        return coordinator
//    }()
    
    override lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "EntitiesModel", managedObjectModel: managedObjectModel)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false // Make it simpler in test env
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores(completionHandler: { (_, error) in //(storeDescription, error) in
            if let error = error as NSError? {
                // TODO: Logging
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
}

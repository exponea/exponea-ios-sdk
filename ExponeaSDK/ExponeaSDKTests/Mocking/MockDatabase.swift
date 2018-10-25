//
//  MockDatabase.swift
//  ExponeaSDKTests
//
//  Created by Ricardo Tokashiki on 11/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import CoreData

@testable import ExponeaSDK

//class MockDatabase: DatabaseManager {
//
//    override init() {
//        super.init()
//
//        self.persistentContainer = {
//            var url: URL?
//            for bundle in Bundle.allFrameworks {
//                url = bundle.url(forResource: "DatabaseModel", withExtension: "momd")
//                if url != nil {
//                    break
//                }
//            }
//
//            let container = NSPersistentContainer(name: "DatabaseModel",
//                                                  managedObjectModel: NSManagedObjectModel(contentsOf: url!)!)
//
//            let description = NSPersistentStoreDescription()
//            description.type = NSInMemoryStoreType
//            description.shouldAddStoreAsynchronously = false
//
//            container.persistentStoreDescriptions = [description]
//            container.loadPersistentStores { (description, error) in
//                // Check if the data store is in memory
//                precondition( description.type == NSInMemoryStoreType )
//                // Check if creating container wrong
//                if let error = error {
//                    fatalError("Create an in-mem coordinator failed \(error)")
//                }
//            }
//            return container
//        }()
//    }
//}

//
//  DatabaseManager+Clear.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 15/04/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//
import CoreData

@testable import ExponeaSDK

extension DatabaseManager {
    public func clear() throws {
        // Delete all persistent stores
        let coordinator = persistentContainer.persistentStoreCoordinator
        for store in coordinator.persistentStores {
            // Make sure we have URL and it is a NSSQLiteStoreType
            guard let url = store.url, store.type == NSSQLiteStoreType else { continue }
            try coordinator.destroyPersistentStore(at: url, ofType: NSSQLiteStoreType, options: nil)
        }

        // Load new persistent store
        var loadError: Error?
        persistentContainer.loadPersistentStores(completionHandler: { loadError = $1 })

        // Throw an error if we failed at loading a persistent store
        if let loadError = loadError {
            let error = DatabaseManagerError.unableToLoadPeristentStore(loadError.localizedDescription)
            Exponea.logger.log(.error, message: error.localizedDescription)
           throw error
        }
    }
}

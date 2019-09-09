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

class MockDatabase: DatabaseManager {
    init() throws {
        let inMemoryDescription = NSPersistentStoreDescription()
        inMemoryDescription.type = NSInMemoryStoreType
        try super.init(persistentStoreDescriptions: [inMemoryDescription])
    }
}

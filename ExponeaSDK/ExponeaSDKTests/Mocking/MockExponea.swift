//
//  MockExponea.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 17/07/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

@testable import ExponeaSDK

import CoreData

final class MockExponea: Exponea {
    private var database: DatabaseManager!

    override init() {
        super.init()
        self.userDefaults = MockUserDefaults()
    }

    // override Exponea sharedInitializer to add mock database manager insead of coreData
    public override func sharedInitializer(configuration: Configuration) {
        Exponea.logger.log(.verbose, message: "Configuring MockExponea with provided configuration:\n\(configuration)")

        do {
            // Create database
            database = try MockDatabaseManager()

            // Recreate repository
            let repository = ServerRepository(configuration: configuration)
            self.repository = repository

            self.flushingManager = try! FlushingManager(database: database, repository: repository)

            // Finally, configuring tracking manager
            self.trackingManager = try! TrackingManager(
                repository: repository,
                database: database,
                flushingManager: flushingManager!,
                userDefaults: userDefaults
            )
            processSavedCampaignData()
        } catch {
            // Failing gracefully, if setup failed
            Exponea.logger.log(.error, message: """
                Error while creating a database, MockExponea cannot be configured.\n\(error.localizedDescription)
                """)
        }
    }

    public func fetchTrackEvents() throws -> [TrackEventThreadSafe] {
        return try database.fetchTrackEvent()
    }
}

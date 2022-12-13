//
//  MockExponea.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 17/07/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

@testable import ExponeaSDK

import CoreData

// This protocol is used queried using reflection by native iOS SDK to see if SDK is called from SDK tests
@objc(IsExponeaSDKTest)
protocol IsExponeaSDKTest {
}

final class MockExponeaImplementation: ExponeaInternal {
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

            self.flushingManager = try! FlushingManager(
                database: database,
                repository: repository,
                customerIdentifiedHandler: {}
            )

            // Finally, configuring tracking manager
            self.trackingManager = try! TrackingManager(
                repository: repository,
                database: database,
                flushingManager: flushingManager!,
                userDefaults: userDefaults,
                onEventCallback: { type, event in
                    self.inAppMessagesManager?.onEventOccurred(of: type, for: event)
                }
            )

            self.trackingConsentManager = try! TrackingConsentManager(
                trackingManager: self.trackingManager!
            )
            
            self.inAppMessagesManager = InAppMessagesManager(
               repository: repository,
               displayStatusStore: InAppMessageDisplayStatusStore(userDefaults: userDefaults),
               delegate: DefaultInAppDelegate(),
               trackingConsentManager: self.trackingConsentManager!
            )
            
            self.appInboxManager = AppInboxManager(
                repository: repository,
                trackingManager: self.trackingManager!
            )
            
            processSavedCampaignData()
        } catch {
            // Failing gracefully, if setup failed
            Exponea.logger.log(.error, message: """
                Error while creating a database, MockExponea cannot be configured.\n\(error.localizedDescription)
                """)
        }
    }

    public func fetchTrackEvents() throws -> [TrackEventProxy] {
        return try database.fetchTrackEvent()
    }
}

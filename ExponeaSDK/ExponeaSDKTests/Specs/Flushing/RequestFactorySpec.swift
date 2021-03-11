//
//  RequestFactorySpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 11/03/2021.
//  Copyright © 2021 Exponea. All rights reserved.
//

import Foundation
import Nimble
import Mockingjay
import Quick

@testable import ExponeaSDK
@testable import ExponeaSDKShared

final class RequestFactorySpec: QuickSpec {
    override func spec() {
        describe("RequestFactory") {
            var database: MockDatabaseManager!
            var configuration: ExponeaSDK.Configuration!
            var flushingManager: FlushingManager!
            var repository: RepositoryType!

            var eventData: [DataType]!

            beforeEach {
                configuration = try! Configuration(
                    projectToken: UUID().uuidString,
                    authorization: .token("mock-token"),
                    baseUrl: "https://google.com/" // has to be real url because of reachability
                )
                configuration.automaticSessionTracking = false
                configuration.flushEventMaxRetries = 5
                database = try! MockDatabaseManager()
                repository = ServerRepository(configuration: configuration)
                flushingManager = try! FlushingManager(
                    database: database,
                    repository: repository,
                    customerIdentifiedHandler: {}
                )
                eventData = [.properties(MockData().properties)]
            }

            afterEach {
                NetworkStubbing.unstubNetwork()
            }

            it("should eliminate slash duplicity in URL") {
                try! database.trackEvent(with: eventData, into: configuration.mainProject)
                NetworkStubbing.stubNetwork(
                    forProjectToken: configuration.projectToken,
                    withStatusCode: 200,
                    withDelay: 0,
                    withResponseData: nil,
                    withRequestHook: { request in
                        expect { request.url?.absoluteString }.to(match("https://google.com/track"))
                    }
                )
                waitUntil { done in
                    flushingManager.flushData(completion: { _ in done() })
                }
            }
        }
    }
}

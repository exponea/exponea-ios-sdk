//
//  ServerRepository.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 30/09/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Quick
import Nimble
import Mockingjay

@testable import ExponeaSDK

final class ServerRepositorySpec: QuickSpec {

    override func spec() {
        afterEach {
            NetworkStubbing.unstubNetwork()
        }
        describe("ServerRepository") {
            let configurations = TestConfigParams.configurations
            
            for configuration in configurations {
                context(configuration.integrationConfig.type.rawValue) {
                    context("when anonymizing") {
                        it("should cancel pending requests") {
                            // stub network with a long running request that won't call callback unless cancelled
                            NetworkStubbing.stubNetwork(
                                forIntegrationType: configuration.integrationConfig.type,
                                withStatusCode: 200,
                                withDelay: 1000
                            )
                            
                            let repo = ServerRepository(configuration: configuration)
                            var callbackCalled = false
                            repo.fetchConsents { _ in callbackCalled = true }
                            repo.cancelRequests()
                            expect(callbackCalled).toEventually(beTrue())
                        }
                        
                        it("should not cancel requests on shared URLSession") {
                            NetworkStubbing.stubNetwork(
                                forIntegrationType: configuration.integrationConfig.type,
                                withStatusCode: 200,
                                withDelay: 1000
                            )
                            let repo = ServerRepository(configuration: configuration)
                            
                            // trailing slash is required for the stub to match, so the request stays pending
                            var url: URL {
                                switch configuration.integrationConfig.type {
                                case .project(let projectToken):
                                    return URL(safeString: configuration.integrationConfig.baseUrl + "/projects/\(projectToken)/")!
                                case .stream(let streamId):
                                    return URL(safeString: configuration.integrationConfig.baseUrl + "/streams/\(streamId)/")!
                                }
                            }
                            let networkTask = URLSession.shared.dataTask(with: url)
                            networkTask.resume()
                            waitUntil(timeout: .seconds(5)) { done in
                                repo.fetchConsents { _ in done() }
                                repo.cancelRequests()
                            }
                            expect(networkTask.state.rawValue).to(equal(URLSessionTask.State.running.rawValue))
                            networkTask.cancel()
                            // let the request finish before afterEach removes the stubs it is matched against
                            expect(networkTask.state.rawValue).toEventually(equal(URLSessionTask.State.completed.rawValue))
                        }
                    }

                    context("when linking customer IDs") {
                        func linkIds() -> EmptyResult<RepositoryError>? {
                            var linkResult: EmptyResult<RepositoryError>?
                            waitUntil(timeout: .seconds(5)) { done in
                                ServerRepository(configuration: configuration).getLinkIds(
                                    cookie: "cookie",
                                    externalIds: ["registered": "user@example.com"]
                                ) { result in
                                    linkResult = result
                                    done()
                                }
                            }
                            return linkResult
                        }

                        it("should succeed on an empty 2xx body") {
                            // The backend answers link-ids with HTTP 200 and no body.
                            NetworkStubbing.stubNetwork(
                                forIntegrationType: configuration.integrationConfig.type,
                                withStatusCode: 200,
                                withResponseData: Data()
                            )
                            guard case .success = linkIds() else {
                                return fail("Expected success")
                            }
                        }

                        it("should fail on a server error") {
                            NetworkStubbing.stubNetwork(
                                forIntegrationType: configuration.integrationConfig.type,
                                withStatusCode: 500,
                                withResponseData: Data()
                            )
                            guard case .failure = linkIds() else {
                                return fail("Expected failure")
                            }
                        }
                    }
                }
            }
        }
    }
}

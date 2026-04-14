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
                            
                            var url: URL {
                                switch configuration.integrationConfig.type {
                                case .project(let projectToken):
                                    return URL(safeString: configuration.integrationConfig.baseUrl + "/projects/\(projectToken)")!
                                case .stream(let streamId):
                                    return URL(safeString: configuration.integrationConfig.baseUrl + "/streams/\(streamId)")!
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
                        }
                    }
                }
            }
        }
    }
}

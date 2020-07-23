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
            let configuration = try! Configuration(
                projectToken: UUID().uuidString,
                authorization: .token("mock-token"),
                baseUrl: "https://mock-base-url.com"
            )
            context("when anonymizing") {
                it("should cancel pending requests") {
                    // stub network with a long running request that won't call callback unless cancelled
                    NetworkStubbing.stubNetwork(
                        forProjectToken: configuration.projectToken,
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
                        forProjectToken: configuration.projectToken,
                        withStatusCode: 200,
                        withDelay: 1000
                    )
                    let repo = ServerRepository(configuration: configuration)
                    let networkTask = URLSession.shared.dataTask(
                        with: URL(string: configuration.baseUrl + "/projects/\(configuration.projectToken)")!
                    )
                    networkTask.resume()
                    waitUntil { done in
                        repo.fetchConsents { _ in done() }
                        repo.cancelRequests()
                    }
                    expect(networkTask.state).to(equal(URLSessionTask.State.running))
                    networkTask.cancel()
                }
            }
        }
    }
}

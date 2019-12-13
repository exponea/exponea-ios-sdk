//
//  InAppMessagesManagerSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 05/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//
import Foundation
import Quick
import Nimble

@testable import ExponeaSDK

class InAppMessagesManagerSpec: QuickSpec {
    let configuration = try! Configuration(
        projectToken: "token",
        authorization: Authorization.none,
        baseUrl: "baseUrl"
    )

    override func spec() {
        var cache: MockInAppMessagesCache!
        var repository: MockRepository!
        var manager: InAppMessagesManager!

        beforeEach {
            cache = MockInAppMessagesCache()
            repository = MockRepository(configuration: self.configuration)
            repository.fetchInAppMessagesResult = Result.success(
                InAppMessagesResponse(success: true, data: [SampleInAppMessage.getSampleInAppMessage()])
            )
            manager = InAppMessagesManager(
                repository: repository,
                trackingManager: MockTrackingManager(),
                cache: cache,
                presenter: MockInAppMessageDialogPresenter()
            )
        }

        it("should preload messages") {
            repository.fetchInAppMessagesResult = Result.success(
                InAppMessagesResponse(success: true, data: [SampleInAppMessage.getSampleInAppMessage()])
            )
            waitUntil { done in manager.preload { done() } }
            expect(cache.getInAppMessages()).to(equal([SampleInAppMessage.getSampleInAppMessage()]))
        }

        it("should not overwrite preloaded messages on failure") {
            repository.fetchInAppMessagesResult = Result.success(
                InAppMessagesResponse(success: true, data: [SampleInAppMessage.getSampleInAppMessage()])
            )
            waitUntil { done in manager.preload { done() } }
            repository.fetchInAppMessagesResult = Result.failure(ExponeaError.unknownError(""))
            waitUntil { done in manager.preload { done() } }
            expect(cache.getInAppMessages()).to(equal([SampleInAppMessage.getSampleInAppMessage()]))
        }

        it("should overwrite preloaded messages on success") {
            repository.fetchInAppMessagesResult = Result.success(
                InAppMessagesResponse(success: true, data: [SampleInAppMessage.getSampleInAppMessage()])
            )
            waitUntil { done in manager.preload { done() } }
            repository.fetchInAppMessagesResult = Result.success(
                InAppMessagesResponse(success: true, data: [SampleInAppMessage.getSampleInAppMessage(id: "new-id")])
            )
            waitUntil { done in manager.preload { done() } }
            expect(cache.getInAppMessages()).to(equal([SampleInAppMessage.getSampleInAppMessage(id: "new-id")]))
        }

        it("should get nil in-app message on cold start") {
            expect(manager.getInAppMessage()).to(beNil())
        }

        it("should get in-app messages from cache") {
            cache.saveInAppMessages(inAppMessages: [SampleInAppMessage.getSampleInAppMessage()])
            expect(manager.getInAppMessage()).to(equal(SampleInAppMessage.getSampleInAppMessage()))
        }

        it("should show dialog") {
            cache.saveInAppMessages(inAppMessages: [SampleInAppMessage.getSampleInAppMessage()])
            waitUntil { done in
                manager.showInAppMessage { shown in
                    expect(shown).to(beTrue())
                    done()
                }
            }
        }

        it("should not show dialog without messages") {
            waitUntil { done in
                manager.showInAppMessage { shown in
                    expect(shown).to(beFalse())
                    done()
                }
            }
        }
    }
}

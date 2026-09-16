//
//  InAppContentBlocksETagSpec.swift
//  ExponeaSDKTests
//
//  Copyright © 2026 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Mockingjay
@testable import ExponeaSDK

final class InAppContentBlocksETagSpec: QuickSpec {

    let configuration = try! Configuration(
        projectToken: "test-token",
        authorization: Authorization.none,
        baseUrl: "https://api.exponea.com"
    )

    private var testDefaults: UserDefaults!
    private var testEtagStore: UserDefaultsETagStore!

    private var etagPrefixedKeys: [String] {
        testDefaults.dictionaryRepresentation().keys.filter { $0.hasPrefix("exponea_icb_etag_") }
    }

    private func removeAllEtagKeys() {
        etagPrefixedKeys.forEach { testDefaults.removeObject(forKey: $0) }
    }

    override func spec() {
        var manager: InAppContentBlocksManagerType!

        beforeEach {
            let suiteName = "test.etag.\(UUID().uuidString)"
            self.testDefaults = UserDefaults(suiteName: suiteName)!
            self.testEtagStore = UserDefaultsETagStore(defaults: self.testDefaults)

            Exponea.shared = ExponeaInternal()
            IntegrationManager.shared.isStopped = false
            Exponea.shared.configure(with: self.configuration)

            let testManager = InAppContentBlocksManager(
                provider: InAppContentBlocksDataProvider(),
                etagStore: self.testEtagStore
            )
            (Exponea.shared as! ExponeaInternal).inAppContentBlocksManager = testManager
            manager = testManager
            manager.anonymize()
            testManager.test_setCatalogReady()
        }

        afterEach {
            MockingjayProtocol.removeAllStubs()
            self.removeAllEtagKeys()
        }

        describe("ETag stored from 200 response") {
            it("persists the ETag header from a 200 OK personalized fetch") {
                let placeholderMsg = SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                    id: "etag-msg-1",
                    placeholders: ["etag-ph-1"]
                )
                manager.addMessage(placeholderMsg)

                let etagValue = "\"etag-v1-abc123\""
                let jsonBody = try! JSONEncoder().encode(PersonalizedInAppContentBlockResponseData(data: []))
                MockingjayProtocol.addStub(
                    matcher: { $0.url?.path.contains("inappcontentblocks") == true },
                    builder: { _ in
                        let response = HTTPURLResponse(
                            url: URL(string: "https://api.exponea.com/personalize")!,
                            statusCode: 200,
                            httpVersion: nil,
                            headerFields: ["ETag": etagValue]
                        )!
                        return .success(response, .content(jsonBody))
                    }
                )

                waitUntil(timeout: .seconds(5)) { done in
                    let queueData = StaticQueueData(
                        tag: 1,
                        placeholderId: "etag-ph-1",
                        makeResourcesOffline: false,
                        completion: { _ in done() }
                    )
                    manager.refreshStaticViewContent(staticQueueData: queueData)
                }

                expect(self.etagPrefixedKeys).toNot(beEmpty())
                let storedEtag = self.etagPrefixedKeys
                    .compactMap { self.testDefaults.string(forKey: $0) }
                    .first
                expect(storedEtag).to(equal(etagValue))
            }

            it("replaces the stored ETag when the server returns a new ETag on 200") {
                let placeholderMsg = SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                    id: "etag-msg-2",
                    placeholders: ["etag-ph-2"]
                )
                manager.addMessage(placeholderMsg)

                let jsonBody = try! JSONEncoder().encode(PersonalizedInAppContentBlockResponseData(data: []))

                let oldEtag = "\"etag-old\""
                MockingjayProtocol.addStub(
                    matcher: { $0.url?.path.contains("inappcontentblocks") == true },
                    builder: { _ in
                        let response = HTTPURLResponse(
                            url: URL(string: "https://api.exponea.com/personalize")!,
                            statusCode: 200,
                            httpVersion: nil,
                            headerFields: ["ETag": oldEtag]
                        )!
                        return .success(response, .content(jsonBody))
                    }
                )

                waitUntil(timeout: .seconds(5)) { done in
                    let queueData = StaticQueueData(
                        tag: 2,
                        placeholderId: "etag-ph-2",
                        makeResourcesOffline: false,
                        completion: { _ in done() }
                    )
                    manager.refreshStaticViewContent(staticQueueData: queueData)
                }

                expect(self.etagPrefixedKeys).toNot(beEmpty())

                MockingjayProtocol.removeAllStubs()
                let newEtag = "\"etag-new\""
                MockingjayProtocol.addStub(
                    matcher: { $0.url?.path.contains("inappcontentblocks") == true },
                    builder: { _ in
                        let response = HTTPURLResponse(
                            url: URL(string: "https://api.exponea.com/personalize")!,
                            statusCode: 200,
                            httpVersion: nil,
                            headerFields: ["ETag": newEtag]
                        )!
                        return .success(response, .content(jsonBody))
                    }
                )

                waitUntil(timeout: .seconds(5)) { done in
                    let queueData = StaticQueueData(
                        tag: 3,
                        placeholderId: "etag-ph-2",
                        makeResourcesOffline: false,
                        completion: { _ in done() }
                    )
                    manager.refreshStaticViewContent(staticQueueData: queueData)
                }

                let storedEtag = self.etagPrefixedKeys
                    .compactMap { self.testDefaults.string(forKey: $0) }
                    .first
                expect(storedEtag).to(equal(newEtag))
            }
        }

        describe("304 Not Modified when server content is unchanged") {
            it("returns without downloading a response body when server sends 304") {
                let placeholderMsg = SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                    id: "etag-msg-3",
                    placeholders: ["etag-ph-3"]
                )
                manager.addMessage(placeholderMsg)

                let seededPersonalized = PersonalizedInAppContentBlockResponseData(
                    data: [
                        PersonalizedInAppContentBlockResponse(
                            id: "etag-msg-3",
                            status: .ok,
                            ttlSeconds: 3600,
                            variantId: nil,
                            hasTrackingConsent: true,
                            variantName: nil,
                            contentType: nil,
                            content: .init(html: "<html><body>etag-static</body></html>"),
                            htmlPayload: nil,
                            ttlSeen: nil
                        )
                    ]
                )
                let seededBody = (try? JSONEncoder().encode(seededPersonalized)) ?? Data()

                var fetchCount = 0
                MockingjayProtocol.addStub(
                    matcher: { $0.url?.path.contains("inappcontentblocks") == true },
                    builder: { request in
                        fetchCount += 1
                        let statusCode = request.value(forHTTPHeaderField: "If-None-Match") != nil ? 304 : 200
                        let response = HTTPURLResponse(
                            url: URL(string: "https://api.exponea.com/personalize")!,
                            statusCode: statusCode,
                            httpVersion: nil,
                            headerFields: statusCode == 200 ? ["ETag": "\"etag-v1\""] : nil
                        )!
                        return .success(response, .content(statusCode == 200 ? seededBody : Data()))
                    }
                )

                waitUntil(timeout: .seconds(5)) { done in
                    let queueData = StaticQueueData(
                        tag: 4,
                        placeholderId: "etag-ph-3",
                        makeResourcesOffline: false,
                        completion: { _ in done() }
                    )
                    manager.refreshStaticViewContent(staticQueueData: queueData)
                }

                expect(self.etagPrefixedKeys).toNot(beEmpty())

                var secondCompletionCalled = false
                waitUntil(timeout: .seconds(5)) { done in
                    let queueData = StaticQueueData(
                        tag: 5,
                        placeholderId: "etag-ph-3",
                        makeResourcesOffline: false,
                        completion: { _ in
                            secondCompletionCalled = true
                            done()
                        }
                    )
                    manager.refreshStaticViewContent(staticQueueData: queueData)
                }

                expect(secondCompletionCalled).to(beTrue())
                expect(fetchCount).to(equal(2))
            }

            it("evicts the stored ETag and performs a full 200 re-fetch when 304 arrives with non-renderable personalized cache") {
                let placeholderMsg = SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                    id: "etag-msg-3-invalid",
                    placeholders: ["etag-ph-3-invalid"],
                    personalized: PersonalizedInAppContentBlockResponse.getSample(
                        status: .filterNotMatched,
                        ttlSeen: Date().addingTimeInterval(-120)
                    )
                )
                manager.addMessage(placeholderMsg)

                let customerIds = (try? DatabaseManager().currentCustomer.ids) ?? [:]
                let projectToken = Exponea.shared.configuration?.mainProject.integrationId ?? ""
                let cacheKey = UserDefaultsETagStore.cacheKey(
                    projectToken: projectToken,
                    customerIds: customerIds,
                    blockIds: ["etag-msg-3-invalid"]
                )
                self.testEtagStore.store(etag: "\"stale-static-etag\"", forKey: cacheKey)

                let freshBody = (try? JSONEncoder().encode(
                    PersonalizedInAppContentBlockResponseData(
                        data: [
                            PersonalizedInAppContentBlockResponse(
                                id: "etag-msg-3-invalid",
                                status: .ok,
                                ttlSeconds: 3600,
                                variantId: nil,
                                hasTrackingConsent: true,
                                variantName: nil,
                                contentType: nil,
                                content: .init(html: "<html><body>fresh-static</body></html>"),
                                htmlPayload: nil,
                                ttlSeen: nil
                            )
                        ]
                    )
                )) ?? Data()

                var fetchCount = 0
                MockingjayProtocol.addStub(
                    matcher: { $0.url?.path.contains("inappcontentblocks") == true },
                    builder: { request in
                        fetchCount += 1
                        if request.value(forHTTPHeaderField: "If-None-Match") != nil {
                            let response = HTTPURLResponse(
                                url: URL(string: "https://api.exponea.com/personalize")!,
                                statusCode: 304,
                                httpVersion: nil,
                                headerFields: nil
                            )!
                            return .success(response, .content(Data()))
                        }
                        let response = HTTPURLResponse(
                            url: URL(string: "https://api.exponea.com/personalize")!,
                            statusCode: 200,
                            httpVersion: nil,
                            headerFields: ["ETag": "\"fresh-static-etag\""]
                        )!
                        return .success(response, .content(freshBody))
                    }
                )

                var completionCalled = false
                waitUntil(timeout: .seconds(10)) { done in
                    let queueData = StaticQueueData(
                        tag: 11,
                        placeholderId: "etag-ph-3-invalid",
                        makeResourcesOffline: false,
                        completion: { _ in
                            completionCalled = true
                            done()
                        }
                    )
                    manager.refreshStaticViewContent(staticQueueData: queueData)
                }

                expect(fetchCount).to(equal(2))
                expect(completionCalled).to(beTrue())
                expect(self.testEtagStore.retrieve(forKey: cacheKey)).to(equal("\"fresh-static-etag\""))
            }
        }

        describe("304 fallback when in-memory cache is absent") {
            it("evicts the stored ETag and performs a full 200 re-fetch when 304 arrives with no cached payload") {
                let placeholderMsg = SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                    id: "etag-msg-fallback",
                    placeholders: ["etag-ph-fallback"]
                )
                manager.addMessage(placeholderMsg)

                let projectToken = Exponea.shared.configuration?.mainProject.integrationId ?? ""
                let customerIds = (try? DatabaseManager().currentCustomer.ids) ?? [:]
                let cacheKey = UserDefaultsETagStore.cacheKey(
                    projectToken: projectToken,
                    customerIds: customerIds,
                    blockIds: ["etag-msg-fallback"]
                )
                self.testEtagStore.store(etag: "\"stale-etag\"", forKey: cacheKey)
                expect(self.testEtagStore.retrieve(forKey: cacheKey)).to(equal("\"stale-etag\""))

                let freshPersonalized = PersonalizedInAppContentBlockResponseData(
                    data: [
                        PersonalizedInAppContentBlockResponse(
                            id: "etag-msg-fallback",
                            status: .ok,
                            ttlSeconds: 3600,
                            variantId: nil,
                            hasTrackingConsent: true,
                            variantName: nil,
                            contentType: nil,
                            content: nil,
                            htmlPayload: nil,
                            ttlSeen: nil
                        )
                    ]
                )
                let freshBody = (try? JSONEncoder().encode(freshPersonalized)) ?? Data()

                var fetchCount = 0
                MockingjayProtocol.addStub(
                    matcher: { $0.url?.path.contains("inappcontentblocks") == true },
                    builder: { request in
                        fetchCount += 1
                        if request.value(forHTTPHeaderField: "If-None-Match") != nil {
                            let response = HTTPURLResponse(
                                url: URL(string: "https://api.exponea.com/personalize")!,
                                statusCode: 304,
                                httpVersion: nil,
                                headerFields: nil
                            )!
                            return .success(response, .content(Data()))
                        } else {
                            let response = HTTPURLResponse(
                                url: URL(string: "https://api.exponea.com/personalize")!,
                                statusCode: 200,
                                httpVersion: nil,
                                headerFields: ["ETag": "\"fresh-etag\""]
                            )!
                            return .success(response, .content(freshBody))
                        }
                    }
                )

                var completionCalled = false
                waitUntil(timeout: .seconds(10)) { done in
                    let queueData = StaticQueueData(
                        tag: 10,
                        placeholderId: "etag-ph-fallback",
                        makeResourcesOffline: false,
                        completion: { _ in
                            completionCalled = true
                            done()
                        }
                    )
                    manager.refreshStaticViewContent(staticQueueData: queueData)
                }

                expect(fetchCount).to(equal(2))
                expect(self.testEtagStore.retrieve(forKey: cacheKey)).toNot(equal("\"stale-etag\""))
                expect(completionCalled).to(beTrue())
            }
        }

        describe("forced reload does not send If-None-Match") {
            it("omits If-None-Match when skipEtag is true even if an ETag is stored") {
                let placeholderMsg = SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                    id: "etag-msg-4",
                    placeholders: ["etag-ph-4"]
                )
                manager.addMessage(placeholderMsg)

                let jsonBody = try! JSONEncoder().encode(PersonalizedInAppContentBlockResponseData(data: []))
                var capturedIfNoneMatch: String? = nil

                MockingjayProtocol.addStub(
                    matcher: { $0.url?.path.contains("inappcontentblocks") == true },
                    builder: { request in
                        capturedIfNoneMatch = request.value(forHTTPHeaderField: "If-None-Match")
                        let response = HTTPURLResponse(
                            url: URL(string: "https://api.exponea.com/personalize")!,
                            statusCode: 200,
                            httpVersion: nil,
                            headerFields: ["ETag": "\"some-etag\""]
                        )!
                        return .success(response, .content(jsonBody))
                    }
                )

                waitUntil(timeout: .seconds(5)) { done in
                    let initialData = StaticQueueData(
                        tag: 6,
                        placeholderId: "etag-ph-4",
                        makeResourcesOffline: false,
                        skipEtag: false,
                        completion: { _ in done() }
                    )
                    manager.refreshStaticViewContent(staticQueueData: initialData)
                }
                expect(self.etagPrefixedKeys).toNot(beEmpty())

                capturedIfNoneMatch = nil

                waitUntil(timeout: .seconds(5)) { done in
                    let forceData = StaticQueueData(
                        tag: 7,
                        placeholderId: "etag-ph-4",
                        makeResourcesOffline: false,
                        skipEtag: true,
                        completion: { _ in done() }
                    )
                    manager.refreshStaticViewContent(staticQueueData: forceData)
                }

                expect(capturedIfNoneMatch).to(beNil())
            }
        }

        describe("anonymize() clears stored ETags") {
            it("removes all exponea_icb_etag_ keys when anonymize is called") {
                self.testDefaults.set("\"some-etag\"", forKey: "exponea_icb_etag_test_key")
                expect(self.etagPrefixedKeys).toNot(beEmpty())

                manager.anonymize()

                expect(self.etagPrefixedKeys).to(beEmpty())
            }
        }

        describe("stopIntegration() clears stored ETags") {
            it("removes all exponea_icb_etag_ keys when integration is stopped") {
                self.testDefaults.set("\"some-etag\"", forKey: "exponea_icb_etag_test_key")
                expect(self.etagPrefixedKeys).toNot(beEmpty())

                waitUntil(timeout: .seconds(5)) { done in
                    Exponea.shared.stopIntegration {
                        IntegrationManager.shared.isStopped = false
                        done()
                    }
                }

                expect(self.etagPrefixedKeys).to(beEmpty())
            }
        }

        describe("identifyCustomer() clears stored ETags") {
            it("removes all exponea_icb_etag_ keys when onCustomerIdentified is called") {
                self.testDefaults.set("\"some-etag\"", forKey: "exponea_icb_etag_test_key")
                expect(self.etagPrefixedKeys).toNot(beEmpty())

                guard let concreteManager = manager as? InAppContentBlocksManager else {
                    fail("Expected concrete InAppContentBlocksManager")
                    return
                }
                concreteManager.onCustomerIdentified()

                expect(self.etagPrefixedKeys).to(beEmpty())
            }
        }

        describe("deterministic content_block_ids ordering") {
            it("sends content_block_ids sorted ascending regardless of message insertion order") {
                let placeholder = "order-ph-1"
                manager.addMessage(
                    SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                        id: "block-z",
                        placeholders: [placeholder]
                    )
                )
                manager.addMessage(
                    SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                        id: "block-a",
                        placeholders: [placeholder]
                    )
                )
                manager.addMessage(
                    SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                        id: "block-m",
                        placeholders: [placeholder]
                    )
                )

                var capturedIds: [String]?
                let jsonBody = try! JSONEncoder().encode(PersonalizedInAppContentBlockResponseData(data: []))
                MockingjayProtocol.addStub(
                    matcher: { $0.url?.path.contains("inappcontentblocks") == true },
                    builder: { request in
                        let bodyData = request.httpBody ?? request.httpBodyStream?.readFully() ?? Data()
                        if let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
                           let ids = json["content_block_ids"] as? [String] {
                            capturedIds = ids
                        }
                        let response = HTTPURLResponse(
                            url: URL(string: "https://api.exponea.com/personalize")!,
                            statusCode: 200,
                            httpVersion: nil,
                            headerFields: nil
                        )!
                        return .success(response, .content(jsonBody))
                    }
                )

                waitUntil(timeout: .seconds(5)) { done in
                    let queueData = StaticQueueData(
                        tag: 99,
                        placeholderId: placeholder,
                        makeResourcesOffline: false,
                        completion: { _ in done() }
                    )
                    manager.refreshStaticViewContent(staticQueueData: queueData)
                }

                expect(capturedIds).to(equal(["block-a", "block-m", "block-z"]))
            }
        }

        describe("no ETag in response leaves store empty") {
            it("does not write any ETag key when the server returns no ETag header") {
                let placeholderMsg = SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                    id: "etag-msg-5",
                    placeholders: ["etag-ph-5"]
                )
                manager.addMessage(placeholderMsg)

                let jsonBody = try! JSONEncoder().encode(PersonalizedInAppContentBlockResponseData(data: []))
                MockingjayProtocol.addStub(
                    matcher: { $0.url?.path.contains("inappcontentblocks") == true },
                    builder: { _ in
                        let response = HTTPURLResponse(
                            url: URL(string: "https://api.exponea.com/personalize")!,
                            statusCode: 200,
                            httpVersion: nil,
                            headerFields: nil
                        )!
                        return .success(response, .content(jsonBody))
                    }
                )

                waitUntil(timeout: .seconds(5)) { done in
                    let queueData = StaticQueueData(
                        tag: 8,
                        placeholderId: "etag-ph-5",
                        makeResourcesOffline: false,
                        completion: { _ in done() }
                    )
                    manager.refreshStaticViewContent(staticQueueData: queueData)
                }

                expect(self.etagPrefixedKeys).to(beEmpty())
            }
        }

        describe("loadContent ETag path") {
            let listPlaceholder = "list-ph-1"
            let listMsgId = "list-msg-1"
            let listIndexPath = IndexPath(row: 0, section: 1)

            func listPersonalizedBody(messageId: String = "list-msg-1") -> Data {
                let response = PersonalizedInAppContentBlockResponseData(
                    data: [
                        PersonalizedInAppContentBlockResponse(
                            id: messageId,
                            status: .ok,
                            ttlSeconds: 60,
                            variantId: nil,
                            hasTrackingConsent: true,
                            variantName: nil,
                            contentType: nil,
                            content: .init(html: "<html><body>loadContent</body></html>"),
                            htmlPayload: nil,
                            ttlSeen: nil
                        )
                    ]
                )
                return (try? JSONEncoder().encode(response)) ?? Data()
            }

            it("persists the ETag header from a 200 OK loadContent fetch") {
                manager.addMessage(
                    SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                        id: listMsgId,
                        placeholders: [listPlaceholder]
                    )
                )

                let etagValue = "\"load-content-etag-v1\""
                MockingjayProtocol.addStub(
                    matcher: { $0.url?.path.contains("inappcontentblocks") == true },
                    builder: { _ in
                        let response = HTTPURLResponse(
                            url: URL(string: "https://api.exponea.com/personalize")!,
                            statusCode: 200,
                            httpVersion: nil,
                            headerFields: ["ETag": etagValue]
                        )!
                        return .success(response, .content(listPersonalizedBody()))
                    }
                )

                waitUntil(timeout: .seconds(10)) { done in
                    manager.refreshCallback = { _ in done() }
                    _ = manager.prepareInAppContentBlockView(placeholderId: listPlaceholder, indexPath: listIndexPath)
                }

                let storedEtag = self.etagPrefixedKeys
                    .compactMap { self.testDefaults.string(forKey: $0) }
                    .first
                expect(storedEtag).to(equal(etagValue))
            }

            it("returns without downloading a response body when loadContent receives 304 with cached content") {
                manager.addMessage(
                    SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                        id: listMsgId,
                        placeholders: [listPlaceholder]
                    )
                )

                var fetchCount = 0
                MockingjayProtocol.addStub(
                    matcher: { $0.url?.path.contains("inappcontentblocks") == true },
                    builder: { request in
                        fetchCount += 1
                        let statusCode = request.value(forHTTPHeaderField: "If-None-Match") != nil ? 304 : 200
                        let response = HTTPURLResponse(
                            url: URL(string: "https://api.exponea.com/personalize")!,
                            statusCode: statusCode,
                            httpVersion: nil,
                            headerFields: statusCode == 200 ? ["ETag": "\"load-content-etag-v1\""] : nil
                        )!
                        return .success(response, .content(statusCode == 200 ? listPersonalizedBody() : Data()))
                    }
                )

                waitUntil(timeout: .seconds(10)) { done in
                    manager.refreshCallback = { _ in done() }
                    _ = manager.prepareInAppContentBlockView(placeholderId: listPlaceholder, indexPath: listIndexPath)
                }

                let concreteManager = manager as! InAppContentBlocksManager
                concreteManager.inAppContentBlockMessages = concreteManager.inAppContentBlockMessages.map { message in
                    var copy = message
                    copy.personalizedMessage?.ttlSeen = Date().addingTimeInterval(-120)
                    return copy
                }

                waitUntil(timeout: .seconds(10)) { done in
                    manager.refreshCallback = { _ in done() }
                    _ = manager.prepareInAppContentBlockView(placeholderId: listPlaceholder, indexPath: listIndexPath)
                }

                expect(fetchCount).to(equal(2))
            }

            it("evicts the stored ETag and performs a full 200 re-fetch when loadContent receives 304 with no cached payload") {
                let expiredPersonalized = PersonalizedInAppContentBlockResponse.getSample(
                    status: .ok,
                    ttlSeen: Date().addingTimeInterval(-120)
                )
                manager.addMessage(
                    SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                        id: listMsgId,
                        placeholders: [listPlaceholder],
                        personalized: expiredPersonalized
                    )
                )

                let customerIds = (try? DatabaseManager().currentCustomer.ids) ?? [:]
                let projectToken = Exponea.shared.configuration?.mainProject.integrationId ?? ""
                let cacheKey = UserDefaultsETagStore.cacheKey(
                    projectToken: projectToken,
                    customerIds: customerIds,
                    blockIds: [listMsgId]
                )
                self.testEtagStore.store(etag: "\"stale-load-content-etag\"", forKey: cacheKey)

                var fetchCount = 0
                MockingjayProtocol.addStub(
                    matcher: { $0.url?.path.contains("inappcontentblocks") == true },
                    builder: { request in
                        fetchCount += 1
                        if request.value(forHTTPHeaderField: "If-None-Match") != nil {
                            let concreteManager = manager as! InAppContentBlocksManager
                            concreteManager.inAppContentBlockMessages = concreteManager.inAppContentBlockMessages.map { message in
                                var copy = message
                                copy.personalizedMessage = nil
                                return copy
                            }
                            let response = HTTPURLResponse(
                                url: URL(string: "https://api.exponea.com/personalize")!,
                                statusCode: 304,
                                httpVersion: nil,
                                headerFields: nil
                            )!
                            return .success(response, .content(Data()))
                        }
                        let response = HTTPURLResponse(
                            url: URL(string: "https://api.exponea.com/personalize")!,
                            statusCode: 200,
                            httpVersion: nil,
                            headerFields: ["ETag": "\"fresh-load-content-etag\""]
                        )!
                        return .success(response, .content(listPersonalizedBody()))
                    }
                )

                waitUntil(timeout: .seconds(10)) { done in
                    manager.refreshCallback = { _ in done() }
                    _ = manager.prepareInAppContentBlockView(placeholderId: listPlaceholder, indexPath: listIndexPath)
                }

                expect(fetchCount).to(equal(2))
                expect(self.testEtagStore.retrieve(forKey: cacheKey)).to(equal("\"fresh-load-content-etag\""))
            }

            it("evicts the stored ETag and performs a full 200 re-fetch when loadContent receives 304 with non-renderable personalized cache") {
                let expiredPersonalized = PersonalizedInAppContentBlockResponse(
                    id: listMsgId,
                    status: .filterNotMatched,
                    ttlSeconds: 60,
                    variantId: nil,
                    hasTrackingConsent: true,
                    variantName: nil,
                    contentType: nil,
                    content: .init(html: "<html><body>stale</body></html>"),
                    htmlPayload: nil,
                    ttlSeen: Date().addingTimeInterval(-120)
                )
                manager.addMessage(
                    SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                        id: listMsgId,
                        placeholders: [listPlaceholder],
                        personalized: expiredPersonalized
                    )
                )

                let customerIds = (try? DatabaseManager().currentCustomer.ids) ?? [:]
                let projectToken = Exponea.shared.configuration?.mainProject.integrationId ?? ""
                let cacheKey = UserDefaultsETagStore.cacheKey(
                    projectToken: projectToken,
                    customerIds: customerIds,
                    blockIds: [listMsgId]
                )
                self.testEtagStore.store(etag: "\"stale-load-content-etag\"", forKey: cacheKey)

                var fetchCount = 0
                MockingjayProtocol.addStub(
                    matcher: { $0.url?.path.contains("inappcontentblocks") == true },
                    builder: { request in
                        fetchCount += 1
                        if request.value(forHTTPHeaderField: "If-None-Match") != nil {
                            let response = HTTPURLResponse(
                                url: URL(string: "https://api.exponea.com/personalize")!,
                                statusCode: 304,
                                httpVersion: nil,
                                headerFields: nil
                            )!
                            return .success(response, .content(Data()))
                        }
                        let response = HTTPURLResponse(
                            url: URL(string: "https://api.exponea.com/personalize")!,
                            statusCode: 200,
                            httpVersion: nil,
                            headerFields: ["ETag": "\"fresh-load-content-etag\""]
                        )!
                        return .success(response, .content(listPersonalizedBody()))
                    }
                )

                waitUntil(timeout: .seconds(10)) { done in
                    manager.refreshCallback = { _ in done() }
                    _ = manager.prepareInAppContentBlockView(placeholderId: listPlaceholder, indexPath: listIndexPath)
                }

                expect(fetchCount).to(equal(2))
                expect(self.testEtagStore.retrieve(forKey: cacheKey)).to(equal("\"fresh-load-content-etag\""))
            }
        }

        describe("cold-start ETag reuse") {
            it("sends a pre-seeded ETag as If-None-Match on the first refresh after restart") {
                let placeholderMsg = SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                    id: "etag-msg-6",
                    placeholders: ["etag-ph-6"]
                )
                manager.addMessage(placeholderMsg)

                let jsonBody = try! JSONEncoder().encode(PersonalizedInAppContentBlockResponseData(data: []))
                var capturedIfNoneMatch: String? = nil
                let priorEtag = "\"prior-session-etag\""

                MockingjayProtocol.addStub(
                    matcher: { $0.url?.path.contains("inappcontentblocks") == true },
                    builder: { request in
                        capturedIfNoneMatch = request.value(forHTTPHeaderField: "If-None-Match")
                        let response = HTTPURLResponse(
                            url: URL(string: "https://api.exponea.com/personalize")!,
                            statusCode: 200,
                            httpVersion: nil,
                            headerFields: nil
                        )!
                        return .success(response, .content(jsonBody))
                    }
                )

                let customerIds = (try? DatabaseManager().currentCustomer.ids) ?? [:]
                let projectToken = Exponea.shared.configuration?.mainProject.integrationId ?? ""
                let cacheKey = UserDefaultsETagStore.cacheKey(
                    projectToken: projectToken,
                    customerIds: customerIds,
                    blockIds: ["etag-msg-6"]
                )
                self.testEtagStore.store(etag: priorEtag, forKey: cacheKey)

                waitUntil(timeout: .seconds(5)) { done in
                    let queueData = StaticQueueData(
                        tag: 9,
                        placeholderId: "etag-ph-6",
                        makeResourcesOffline: false,
                        completion: { _ in done() }
                    )
                    manager.refreshStaticViewContent(staticQueueData: queueData)
                }

                expect(capturedIfNoneMatch).to(equal(priorEtag))
            }
        }
    }
}

//
//  InAppContentBlocksManagerSpec.swift.swift
//  ExponeaSDKTests
//
//  Created by Ankmara on 22.06.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Combine
import UIKit
import WebKit
import Mockingjay
@testable import ExponeaSDK

/// Test double that records every `loadHTMLString` call routed through it.
///
/// Used by the WebContent-process-termination recovery specs so we can assert
/// that the cell / calculator re-issued the cached HTML *into the supplied
/// `WKWebView` parameter* (i.e. self-at-runtime in production), without
/// spinning up the real WebKit IPC. Recording is synchronous; the super call
/// is forwarded so the spy stays a fully-functional `WKWebView` and any
/// `WKNavigationDelegate` wiring on the system under test continues to work.
fileprivate final class LoadHTMLStringSpyWebView: WKWebView {
    private(set) var loadedHtmlStrings: [String] = []
    override func loadHTMLString(_ string: String, baseURL: URL?) -> WKNavigation? {
        loadedHtmlStrings.append(string)
        return super.loadHTMLString(string, baseURL: baseURL)
    }
}

private final class DeferredInAppContentBlocksDataProvider:
    InAppContentBlocksDataProviderType,
    InAppContentBlocksETagDataProviding {

    private(set) var catalogLoadCallCount = 0
    private(set) var catalogCompletion:
        ((ResponseData<InAppContentBlocksDataResponse>) -> Void)?
    private(set) var personalizedBlockIds: [[String]] = []
    private(set) var personalizedCompletion:
        ((ResponseData<PersonalizedInAppContentBlockResponseData>) -> Void)?

    func loadPersonalizedInAppContentBlocks<Data: Codable>(
        data: Data.Type,
        customerIds: [String: String],
        inAppContentBlocksIds: [String],
        completion: @escaping TypeBlock<ResponseData<Data>>
    ) {
        personalizedBlockIds.append(inAppContentBlocksIds)
        personalizedCompletion = { response in
            completion(ResponseData(data: response.data as? Data, error: response.error))
        }
    }

    func getInAppContentBlocks<Data: Codable>(
        data: Data.Type,
        completion: @escaping TypeBlock<ResponseData<Data>>
    ) {
        catalogLoadCallCount += 1
        catalogCompletion = { response in
            completion(ResponseData(data: response.data as? Data, error: response.error))
        }
    }

    func loadPersonalizedInAppContentBlocks<Data: Codable>(
        data: Data.Type,
        customerIds: [String: String],
        inAppContentBlocksIds: [String],
        etag: String?,
        onNotModified: (() -> Void)?,
        onEtagHeader: ((String) -> Void)?,
        completion: @escaping TypeBlock<ResponseData<Data>>
    ) {
        loadPersonalizedInAppContentBlocks(
            data: data,
            customerIds: customerIds,
            inAppContentBlocksIds: inAppContentBlocksIds,
            completion: completion
        )
    }
}

fileprivate class CustomCarouselCallback: DefaultContentBlockCarouselCallback {

    var notFoundCallback: EmptyBlock?
    var onMessageChangedCallback: EmptyBlock?

    var overrideDefaultBehavior: Bool = false
    var trackActions: Bool = true

    init() {}

    func onMessageShown(placeholderId: String, contentBlock: ExponeaSDK.InAppContentBlockResponse, index: Int, count: Int) {
        // space for custom implementation
    }
    
    func onMessagesChanged(count: Int, messages: [ExponeaSDK.InAppContentBlockResponse]) {
        // space for custom implementation
        onMessageChangedCallback?()
    }

    func onNoMessageFound(placeholderId: String) {
        // space for custom implementation
        notFoundCallback?()
    }

    func onError(placeholderId: String, contentBlock: ExponeaSDK.InAppContentBlockResponse?, errorMessage: String) {
        // space for custom implementation
    }

    func onCloseClicked(placeholderId: String, contentBlock: ExponeaSDK.InAppContentBlockResponse) {
        // space for custom implementation
    }

    func onActionClickedSafari(placeholderId: String, contentBlock: ExponeaSDK.InAppContentBlockResponse, action: ExponeaSDK.InAppContentBlockAction) {
        // space for custom implementation
    }

    func onHeightUpdate(placeholderId: String, height: CGFloat) {
        Exponea.logger.log(.verbose, message: "Placeholder \(placeholderId) got new height: \(height)")
    }
}

class InAppContentBlocksManagerSpec: QuickSpec {

    let configuration = try! Configuration(
        projectToken: "token",
        authorization: Authorization.none,
        baseUrl: "baseUrl"
    )

    override func spec() {
        var manager: InAppContentBlocksManagerType!
        var callback: CustomCarouselCallback!

        beforeEach {
            Exponea.shared = ExponeaInternal()
            IntegrationManager.shared.isStopped = false
            Exponea.shared.configure(with: self.configuration)
            manager = Exponea.shared.inAppContentBlocksManager!
            callback = CustomCarouselCallback()
            manager.anonymize()
            (manager as? InAppContentBlocksManager)?.test_setCatalogReady()
        }

        it("date filter") {
            let date = Date()
            let bigDate = Date().addingTimeInterval(5)
            let firstInAppContentBlocks = SampleInAppContentBlocks.getSampleIninAppContentBlocks(dateFilter: .init(enabled: true, fromDate: date, toDate: bigDate))
            var isIn = manager.applyDateFilter(message: firstInAppContentBlocks)
            expect(isIn).to(beTrue())
            waitUntil(timeout: .seconds(7)) { done in
                DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                    isIn = manager.applyDateFilter(message: firstInAppContentBlocks)
                    done()
                }
            }
            expect(isIn).to(beFalse())
        }
        
        it("Corrupted images") {
            // Stub network responses deterministically — previously this test made real HTTPS
            // calls to upload.wikimedia.org and flaked under slow/offline network.
            // Mockingjay auto-swizzles `URLSessionConfiguration.ephemeral` at `+load` time, which
            // is exactly what `hasHtmlImages` uses, so no production injection seam is needed.
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
            let validImageData = renderer.image { context in
                UIColor.red.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
            }.pngData()!
            MockingjayProtocol.addStub(
                matcher: { request in
                    request.url?.absoluteString.contains("/Gull_portrait_ca_usa.jpg") == true
                },
                builder: { _ in
                    let response = HTTPURLResponse(
                        url: URL(string: "https://upload.wikimedia.org/wikipedia/commons/9/9a/Gull_portrait_ca_usa.jpg")!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: ["Content-Type": "image/png"]
                    )!
                    return .success(response, .content(validImageData))
                }
            )
            MockingjayProtocol.addStub(
                matcher: { request in
                    request.url?.absoluteString.contains("/Gull_portrait_ca_usssssa.jpg") == true
                },
                builder: { _ in
                    let response = HTTPURLResponse(
                        url: URL(string: "https://upload.wikimedia.org/wikipedia/commons/9/9a/Gull_portrait_ca_usssssa.jpg")!,
                        statusCode: 404,
                        httpVersion: nil,
                        headerFields: nil
                    )!
                    return .success(response, .content(Data()))
                }
            )
            defer { MockingjayProtocol.removeAllStubs() }

            let rawHtml = "<html>" +
            "<body>" +
            "<img src='https://upload.wikimedia.org/wikipedia/commons/9/9a/Gull_portrait_ca_usa.jpg'>" +
            "<img src='https://upload.wikimedia.org/wikipedia/commons/9/9a/Gull_portrait_ca_usa.jpg'>" +
            "<div data-actiontype='close' onclick='alert('hello')'>Close</div>" +
            "<div data-link='https://example.com/1'>Action 1</div>" +
            "<div data-link='https://example.com/2'>Action 2</div>" +
            "</body></html>"
            let rawHtmlEmptyImages = "<html>" +
            "<body>" +
            "<div data-actiontype='close' onclick='alert('hello')'>Close</div>" +
            "<div data-link='https://example.com/1'>Action 1</div>" +
            "<div data-link='https://example.com/2'>Action 2</div>" +
            "</body></html>"
            let rawHtmlCorruptedImage = "<html>" +
            "<body>" +
            "<img src='https://upload.wikimedia.org/wikipedia/commons/9/9a/Gull_portrait_ca_usssssa.jpg'>" +
            "<div data-actiontype='close' onclick='alert('hello')'>Close</div>" +
            "<div data-link='https://example.com/1'>Action 1</div>" +
            "<div data-link='https://example.com/2'>Action 2</div>" +
            "</body></html>"
            // `hasHtmlImages` enforces `dispatchPrecondition(.notOnQueue(.main))` on its
            // implementation, so we must invoke it off-main. Quick test bodies run on main,
            // so we hop to a background queue and rendezvous via `waitUntil`.
            var result: Bool?
            var result2: Bool?
            var result3: Bool?
            waitUntil(timeout: .seconds(10)) { done in
                DispatchQueue.global(qos: .utility).async {
                    result = manager.hasHtmlImages(html: rawHtml)
                    result2 = manager.hasHtmlImages(html: rawHtmlEmptyImages)
                    result3 = manager.hasHtmlImages(html: rawHtmlCorruptedImage)
                    done()
                }
            }
            expect(result).to(equal(true))   // stubbed 200 with valid PNG
            expect(result2).to(equal(true))  // no images at all
            expect(result3).to(equal(false)) // stubbed 404 / empty body
        }

        it("hasHtmlImages consults InAppMessagesCache and skips the network on hit") {
            // Regression for the carousel cold-paint short-circuit: after HtmlNormalizer.asBase64Image
            // has baked images for offline rendering, every image URL is already on disk in
            // InAppMessagesCache. `hasHtmlImages` must consult that cache first and short-circuit
            // to `true` on any decodable hit, without issuing a network request.
            let uniqueSuffix = UUID().uuidString
            let cachedImageUrl = "https://example.test/\(uniqueSuffix).png"

            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
            let validImageData = renderer.image { ctx in
                UIColor.blue.setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
            }.pngData()!

            // Pre-populate the exact cache entry the production code will read.
            let cache = InAppMessagesCache()
            cache.saveImageData(at: cachedImageUrl, data: validImageData)

            // Counter shared between test and Mockingjay matcher/builder. The matcher runs
            // on every URL loaded through any `URLSessionConfiguration.ephemeral`-based session,
            // so it is the authoritative witness of whether the production code went to the
            // network at all for this URL.
            let networkInvocationCount = Atomic(wrappedValue: 0)
            MockingjayProtocol.addStub(
                matcher: { request in
                    request.url?.absoluteString == cachedImageUrl
                },
                builder: { _ in
                    networkInvocationCount.changeValue { $0 += 1 }
                    // Intentionally fail the network path: if the production code skips the
                    // cache and hits the network, the returned empty body will not decode
                    // as a UIImage and `hasHtmlImages` will return `false`, which the
                    // assertion below will catch.
                    let response = HTTPURLResponse(
                        url: URL(string: cachedImageUrl)!,
                        statusCode: 500,
                        httpVersion: nil,
                        headerFields: nil
                    )!
                    return .success(response, .content(Data()))
                }
            )
            defer { MockingjayProtocol.removeAllStubs() }

            let rawHtml = "<html><body>" +
            "<img src='\(cachedImageUrl)'>" +
            "</body></html>"

            var result: Bool?
            waitUntil(timeout: .seconds(5)) { done in
                DispatchQueue.global(qos: .utility).async {
                    result = manager.hasHtmlImages(html: rawHtml)
                    done()
                }
            }
            expect(result).to(equal(true))
            expect(networkInvocationCount.wrappedValue).to(equal(0))
        }

        it("check filtered") {
            let firstInAppContentBlocks = SampleInAppContentBlocks.getSampleIninAppContentBlocks()
            var isDone = false
            manager.addMessage(firstInAppContentBlocks)
            manager.filterCarouselData(placeholder: "asdas") { response in
                isDone = true
            } expiredCompletion: {
                
            }
            waitUntil(timeout: .seconds(3)) { done in
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    done()
                }
            }
            expect(isDone).to(beTrue())
        }

        it("check inAppContentBlocks priority") {
            let firstInAppContentBlocks = SampleInAppContentBlocks.getSampleIninAppContentBlocks(loadPriority: 1)
            let secondInAppContentBlocks = SampleInAppContentBlocks.getSampleIninAppContentBlocks(loadPriority: 2)
            let thirdInAppContentBlocks = SampleInAppContentBlocks.getSampleIninAppContentBlocks(loadPriority: 2)
            let fourthInAppContentBlocks = SampleInAppContentBlocks.getSampleIninAppContentBlocks(loadPriority: 2)
            let input = [
                firstInAppContentBlocks,
                secondInAppContentBlocks,
                thirdInAppContentBlocks,
                fourthInAppContentBlocks,
            ]
            let prioritized = manager.filterPriority(input: input)
            expect(prioritized[1]?.count).to(equal(1))
            expect(prioritized[2]?.count).toNot(equal(10))
            expect(prioritized[2]?.count).to(equal(3))
        }
        
        it("check TTL") {
            let ttlSeen = Date()
            let inAppContentBlocks = [SampleInAppContentBlocks.getSampleIninAppContentBlocks(personalized: .getSample(status: .ok, ttlSeen: ttlSeen))]
            let savedTags = inAppContentBlocks[0].tags ?? []
            let messagesNeeedToRefresh = inAppContentBlocks.first(where: { inAppContentBlocks in
                if let tags = inAppContentBlocks.tags, tags == savedTags,
                   let ttlSeen = inAppContentBlocks.personalizedMessage?.ttlSeen,
                   let ttl = inAppContentBlocks.personalizedMessage?.ttlSeconds,
                   inAppContentBlocks.content == nil {
                    return Date() > ttlSeen.addingTimeInterval(TimeInterval(ttl))
                }
                return false
            })
            expect(messagesNeeedToRefresh).toEventually(beNil(), timeout: .seconds(2))
            var messagesNeeedToRefreshTrue: InAppContentBlockResponse?
            waitUntil(timeout: .seconds(6)) { done in
                DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                    messagesNeeedToRefreshTrue = inAppContentBlocks.first(where: { inAppContentBlocks in
                        if let tag = inAppContentBlocks.tags, tag == savedTags,
                           let ttlSeen = inAppContentBlocks.personalizedMessage?.ttlSeen,
                           let ttl = inAppContentBlocks.personalizedMessage?.ttlSeconds,
                           inAppContentBlocks.content == nil {
                            return Date() > ttlSeen.addingTimeInterval(TimeInterval(ttl))
                        }
                        return false
                    })
                    done()
                }
            }
            expect(messagesNeeedToRefreshTrue).toEventuallyNot(beNil(), timeout: .seconds(1))
        }
        
        it("filter - always") {
            var inAppContentBlocks = SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                id: "filter - always - msg123 - \(UUID().uuidString)",
                personalized: .getSample(
                    status: .ok,
                    ttlSeen: Date()
                )
            )
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                manager.updateDisplayedState(for: inAppContentBlocks.id)
                manager.updateInteractedState(for: inAppContentBlocks.id)
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
                manager.updateDisplayedState(for: inAppContentBlocks.id)
                manager.updateInteractedState(for: inAppContentBlocks.id)
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                manager.updateDisplayedState(for: inAppContentBlocks.id)
                manager.updateInteractedState(for: inAppContentBlocks.id)
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 2.5) {
                manager.updateDisplayedState(for: inAppContentBlocks.id)
                manager.updateInteractedState(for: inAppContentBlocks.id)
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
                manager.updateDisplayedState(for: inAppContentBlocks.id)
                manager.updateInteractedState(for: inAppContentBlocks.id)
            }
            expect(manager.getFilteredMessage(message: inAppContentBlocks)).toEventually(beTrue(), timeout: .seconds(4))
        }
        
        it("filter - interaction") {
            var inAppContentBlocks = SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                id: "filter - interaction - msg123 - \(UUID().uuidString)",
                frequency: .untilVisitorInteracts,
                personalized: .getSample(
                    status: .ok,
                    ttlSeen: Date()
                )
            )
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                manager.updateDisplayedState(for: inAppContentBlocks.id)
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
                manager.updateDisplayedState(for: inAppContentBlocks.id)
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                manager.updateDisplayedState(for: inAppContentBlocks.id)
            }
            expect(manager.getFilteredMessage(message: inAppContentBlocks)).toEventually(beTrue(), timeout: .seconds(3))
            DispatchQueue.global().asyncAfter(deadline: .now() + 3.1) {
                manager.updateDisplayedState(for: inAppContentBlocks.id)
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 3.5) {
                manager.updateDisplayedState(for: inAppContentBlocks.id)
                manager.updateInteractedState(for: inAppContentBlocks.id)
            }
            expect(manager.getFilteredMessage(message: inAppContentBlocks)).toEventually(beFalse(), timeout: .seconds(4))
        }
        
        it("filter - seen") {
            var inAppContentBlocks = SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                id: "filter - seen - msg123 - \(UUID().uuidString)",
                frequency: .onlyOnce,
                personalized: .getSample(
                    status: .ok,
                    ttlSeen: Date()
                )
            )
            expect(manager.getFilteredMessage(message: inAppContentBlocks)).toEventually(beTrue(), timeout: .seconds(3))
            DispatchQueue.global().asyncAfter(deadline: .now() + 3.5) {
                manager.updateDisplayedState(for: inAppContentBlocks.id)
                manager.updateInteractedState(for: inAppContentBlocks.id)
            }
            expect(manager.getFilteredMessage(message: inAppContentBlocks)).toEventually(beFalse(), timeout: .seconds(4))
        }
        
        it("prefetch") {
            let inAppContentBlocks = [
                SampleInAppContentBlocks.getSampleIninAppContentBlocks(placeholders: ["ph1"], personalized: .getSample(status: .ok, ttlSeen: Date())),
                SampleInAppContentBlocks.getSampleIninAppContentBlocks(placeholders: ["ph1"], personalized: .getSample(status: .ok, ttlSeen: Date())),
                SampleInAppContentBlocks.getSampleIninAppContentBlocks(placeholders: ["ph1"], personalized: .getSample(status: .ok, ttlSeen: Date())),
                SampleInAppContentBlocks.getSampleIninAppContentBlocks(placeholders: ["ph2"], personalized: .getSample(status: .ok, ttlSeen: Date())),
            ]
            expect(manager.prefetchPlaceholdersWithIds(input: inAppContentBlocks, ids: ["ph1"]).count).to(be(3))
            expect(manager.prefetchPlaceholdersWithIds(input: inAppContentBlocks, ids: ["ph2"]).count).to(be(1))
            expect(manager.prefetchPlaceholdersWithIds(input: inAppContentBlocks, ids: ["ph1", "ph2"]).count).to(be(4))
            expect(manager.prefetchPlaceholdersWithIds(input: inAppContentBlocks, ids: [""]).count).to(be(0))
        }
        
        it("queue") {
            var inAppContentBlocks = SampleInAppContentBlocks.getSampleIninAppContentBlocks(frequency: .onlyOnce, personalized: .getSample(status: .ok, ttlSeen: Date()))
            var completionValue: Int = 0
            waitUntil(timeout: .seconds(25)) { done in
                for i in 0..<11 {
                    manager.refreshStaticViewContent(staticQueueData: .init(tag: inAppContentBlocks.tags?.first ?? 0, placeholderId: inAppContentBlocks.name, completion: { _ in
                        completionValue = i
                        if i == 10 {
                            DispatchQueue.main.async { done() }
                        }
                    }))
                }
            }
            expect(completionValue).to(be(10))
        }
        
        it("message changed") {
            var wasMessageChanged = false
            let callback = CustomCarouselCallback()
            let view = CarouselInAppContentBlockView(placeholder: "placeholder", behaviourCallback: callback)
                
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                view.state = .refresh
            }
            waitUntil(timeout: .seconds(2)) { done in
                callback.onMessageChangedCallback = {
                    wasMessageChanged = true
                    DispatchQueue.main.async { done() }
                }
            }
            expect(wasMessageChanged).to(beTrue())
        }
        
        it("overlimit") {
            let array: [Int] = [1, 2, 3, 4, 5]
            let maxOverLimit = 10
            let result = array.prefix(maxOverLimit)
            expect(result.count).to(be(5))
        }

        it("multipler") {
            let view = CarouselInAppContentBlockView(placeholder: "")
            let a = view.makeDuplicate(input: [.init(html: "a", tag: 1)])
            expect(a.count).to(be(1))
            let b = view.makeDuplicate(input: [.init(html: "a", tag: 1), .init(html: "a", tag: 2), .init(html: "b", tag: 3)])
            expect(b.count).to(be(150))
            expect(b.filter({ $0.html == "b" }).count).to(be(50))
            let c = view.makeDuplicate(input: [
                .init(html: "a", tag: 1),
                .init(html: "a", tag: 2),
                .init(html: "b", tag: 3),
                .init(html: "b", tag: 4),
                .init(html: "c", tag: 5),
                .init(html: "c", tag: 6)
            ])
            expect(c.count).to(be(150))
            expect(c.filter({ $0.tag == 6 }).count).to(be(25))
            let d = view.makeDuplicate(input: [
                .init(html: "a", tag: 1),
                .init(html: "a", tag: 2),
                .init(html: "b", tag: 3),
                .init(html: "b", tag: 4),
                .init(html: "c", tag: 5),
                .init(html: "c", tag: 6),
                .init(html: "d", tag: 7),
                .init(html: "d", tag: 8),
                .init(html: "e", tag: 9),
                .init(html: "e", tag: 10),
                .init(html: "f", tag: 11)
            ])
            expect(d.count).to(be(110))
            expect(d.filter({ $0.tag == 6 }).count).to(be(10))
            expect(d.filter({ $0.html == "c" }).count).to(be(20))
        }

        it("is valid check") {
            let messageExpired: StaticReturnData = .init(
                html: "",
                tag: 0,
                message: .init(
                    id: UUID().uuidString,
                    name: "",
                    dateFilter: .init(
                        enabled: false,
                        fromDate: nil,
                        toDate: nil
                    ),
                    frequency: .untilVisitorInteracts,
                    placeholders: [""],
                    tags: [],
                    loadPriority: 100,
                    content: nil,
                    personalized: .getSample(status: .ok, ttlSeen: Date().addingTimeInterval(-10000))
                )
            )
            
             var userDefaults: UserDefaults = {
                if UserDefaults(suiteName: Constants.General.userDefaultsSuite) == nil {
                    UserDefaults.standard.addSuite(named: Constants.General.userDefaultsSuite)
                }
                return UserDefaults(suiteName: Constants.General.userDefaultsSuite)!
            }()
            
            let store = InAppContentBlockDisplayStatusStore(userDefaults: userDefaults)

            var messageInvalidInteracted: StaticReturnData = .init(
                html: "",
                tag: 0,
                message: .init(
                    id: UUID().uuidString,
                    name: "",
                    dateFilter: .init(
                        enabled: false,
                        fromDate: nil,
                        toDate: nil
                    ),
                    frequency: .untilVisitorInteracts,
                    placeholders: [""],
                    tags: [],
                    loadPriority: 100,
                    content: nil,
                    personalized: .getSample(status: .ok, ttlSeen: Date())
                )
            )
            store.didInteract(with: messageInvalidInteracted.message?.id ?? "", at: Date().addingTimeInterval(4000))

            var messageInvalidShowed: StaticReturnData = .init(
                html: "",
                tag: 0,
                message: .init(
                    id: UUID().uuidString,
                    name: "",
                    dateFilter: .init(
                        enabled: false,
                        fromDate: nil,
                        toDate: nil
                    ),
                    frequency: .oncePerVisit,
                    placeholders: [""],
                    tags: [],
                    loadPriority: 100,
                    content: nil,
                    personalized: .getSample(status: .ok, ttlSeen: Date())
                )
            )
            store.didDisplay(of: messageInvalidShowed.message?.id ?? "", at: Date().addingTimeInterval(4000))

            var messageValid: StaticReturnData = .init(
                html: "",
                tag: 0,
                message: .init(
                    id: UUID().uuidString,
                    name: "",
                    dateFilter: .init(
                        enabled: false,
                        fromDate: nil,
                        toDate: nil
                    ),
                    frequency: .always,
                    placeholders: [""],
                    tags: [],
                    loadPriority: 100,
                    content: nil,
                    personalized: .getSample(status: .ok, ttlSeen: Date().addingTimeInterval(4000))
                )
            )

            var isMessageExpiredAndValid = false
            waitUntil(timeout: .seconds(2)) { done in
                manager.isMessageValid(message: messageExpired.message!) { _ in
                } refreshCallback: {
                    isMessageExpiredAndValid = true
                    DispatchQueue.main.async { done() }
                }
            }
            expect(isMessageExpiredAndValid).to(beTrue())

            var isMessageInvalid = false
            waitUntil(timeout: .seconds(2)) { done in
                manager.isMessageValid(message: messageInvalidInteracted.message!) { isValid in
                    isMessageInvalid = !isValid
                    DispatchQueue.main.async { done() }
                } refreshCallback: {
                }
            }
            expect(isMessageInvalid).to(beTrue())

            var isMessageInvalidShowed = false
            waitUntil(timeout: .seconds(2)) { done in
                manager.isMessageValid(message: messageInvalidShowed.message!) { isValid in
                    isMessageInvalidShowed = !isValid
                    DispatchQueue.main.async { done() }
                } refreshCallback: {
                }
            }
            expect(isMessageInvalidShowed).to(beTrue())

            var isMessageValid = false
            waitUntil(timeout: .seconds(2)) { done in
                manager.isMessageValid(message: messageValid.message!) { isValid in
                    isMessageValid = isValid
                    DispatchQueue.main.async { done() }
                } refreshCallback: {
                }
            }
            expect(isMessageValid).to(beTrue())
        }
        
        it("batch static requests with empty placeholderId receive empty result") {
            var completionCalled = false
            waitUntil(timeout: .seconds(5)) { done in
                manager.refreshStaticViewContent(staticQueueData: .init(
                    tag: 0,
                    placeholderId: "",
                    completion: { result in
                        completionCalled = true
                        expect(result.html).to(beEmpty())
                        expect(result.message).to(beNil())
                        DispatchQueue.main.async { done() }
                    }
                ))
            }
            expect(completionCalled).to(beTrue())
        }

        // Regression guard for C3: `CarouselInAppContentBlockView.reload` is `open` on a
        // `public` class — subclasses / host apps may call from any thread. A trap-on-background
        // contract was a release-build regression introduced during the batching refactor.
        it("CarouselInAppContentBlockView.reload is safe to call from a background queue") {
            let view = CarouselInAppContentBlockView(placeholder: "carousel_bg_test")
            waitUntil(timeout: .seconds(3)) { done in
                DispatchQueue.global(qos: .userInitiated).async {
                    view.reload(isTriggered: false)
                    DispatchQueue.main.async { done() }
                }
            }
            expect(true).to(beTrue())
        }

        // Regression guard for C3: `refreshStaticViewContent` is public-surface via
        // `InAppContentBlocksManagerType` and must not trap when invoked off the main queue.
        it("refreshStaticViewContent is safe to call from a background queue") {
            var completionCalled = false
            waitUntil(timeout: .seconds(5)) { done in
                DispatchQueue.global(qos: .userInitiated).async {
                    manager.refreshStaticViewContent(staticQueueData: .init(
                        tag: 7,
                        placeholderId: "",
                        completion: { _ in
                            completionCalled = true
                            DispatchQueue.main.async { done() }
                        }
                    ))
                }
            }
            expect(completionCalled).to(beTrue())
        }

        it("multiple batched requests all receive completions") {
            let requestCount = 5
            var completionCount = 0
            waitUntil(timeout: .seconds(10)) { done in
                for i in 0..<requestCount {
                    manager.refreshStaticViewContent(staticQueueData: .init(
                        tag: i,
                        placeholderId: "placeholder_\(i)",
                        completion: { _ in
                            completionCount += 1
                            if completionCount == requestCount {
                                DispatchQueue.main.async { done() }
                            }
                        }
                    ))
                }
            }
            expect(completionCount).to(equal(requestCount))
        }

        it("ttlSeen is preserved after message update") {
            let msgId = "ttl-test-\(UUID().uuidString)"
            let ttlDate = Date().addingTimeInterval(-100)
            let message = SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                id: msgId,
                personalized: .getSample(status: .ok, ttlSeen: ttlDate)
            )
            manager.addMessage(message)
            let concreteManager = manager as! InAppContentBlocksManager
            let stored = concreteManager.inAppContentBlockMessages.first(where: { $0.id == msgId })
            expect(stored).toNot(beNil())
            expect(stored?.personalizedMessage?.ttlSeen).to(equal(ttlDate))
        }

        it("addMessage is safe under concurrent access") {
            let concreteManager = manager as! InAppContentBlocksManager
            let group = DispatchGroup()
            let iterations = 50
            for i in 0..<iterations {
                group.enter()
                DispatchQueue.global().async {
                    manager.addMessage(SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                        id: "concurrent-\(i)"
                    ))
                    group.leave()
                }
            }
            waitUntil(timeout: .seconds(5)) { done in
                group.notify(queue: .main) { done() }
            }
            let concurrentMessages = concreteManager.inAppContentBlockMessages.filter {
                $0.id.hasPrefix("concurrent-")
            }
            expect(concurrentMessages.count).to(equal(iterations))
        }

        // Regression guard for the "only one carousel renders" bug caused by a single shared
        // validation token being overwritten when multiple `CarouselInAppContentBlockView`s for
        // different placeholders started loading in parallel. Each placeholder must own its own
        // token; loading placeholder B must not invalidate placeholder A's in-flight validation.
        it("loadMessagesForCarousel keeps per-placeholder validation tokens independent") {
            let concreteManager = manager as! InAppContentBlocksManager
            manager.addMessage(SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                id: "carousel-indep-a-\(UUID().uuidString)",
                placeholders: ["carousel_a"]
            ))
            manager.addMessage(SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                id: "carousel-indep-b-\(UUID().uuidString)",
                placeholders: ["carousel_b"]
            ))

            // Token writes happen synchronously inside `loadMessagesForCarousel` before the
            // async network call, so we can assert on them without waiting for completion.
            // Called through the concrete type because `loadMessagesForCarousel` is no longer
            // part of the public `InAppContentBlocksManagerType` surface.
            concreteManager.loadMessagesForCarousel(
                placeholder: "carousel_a",
                initialCompletion: nil,
                completion: nil
            )
            let tokenA = concreteManager.carouselValidationTokens["carousel_a"]
            expect(tokenA).toNot(beNil())

            concreteManager.loadMessagesForCarousel(
                placeholder: "carousel_b",
                initialCompletion: nil,
                completion: nil
            )
            let tokenB = concreteManager.carouselValidationTokens["carousel_b"]
            expect(tokenB).toNot(beNil())
            // Crucially, A's token must still be intact — the B reload must not have clobbered it.
            expect(concreteManager.carouselValidationTokens["carousel_a"]).to(equal(tokenA))
            expect(tokenB).toNot(equal(tokenA))
        }

        // Two back-to-back reload() calls for the same placeholder must share one provider
        // fetch. Token rotations in carouselValidationTokens are a synchronous proxy for
        // provider invocations: the second caller should attach to the in-flight fetch
        // without rotating the token again.
        it("two loadMessagesForCarousel calls for the same placeholder share one in-flight fetch") {
            let concreteManager = manager as! InAppContentBlocksManager
            let placeholder = "carousel_dedup_\(UUID().uuidString)"
            // Prime the static cache so `idsForDownload` is non-empty, matching the
            // production scenario where the placeholder has known message IDs before
            // the personalization fetch fires.
            manager.addMessage(SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                id: "dedup-msg-\(UUID().uuidString)",
                placeholders: [placeholder]
            ))

            concreteManager.loadMessagesForCarousel(
                placeholder: placeholder,
                initialCompletion: nil,
                completion: nil
            )
            let firstToken = concreteManager.carouselValidationTokens[placeholder]
            expect(firstToken).toNot(beNil())

            concreteManager.loadMessagesForCarousel(
                placeholder: placeholder,
                initialCompletion: nil,
                completion: nil
            )
            let secondToken = concreteManager.carouselValidationTokens[placeholder]

            // Under dedup: the second call attaches as a waiter on the first in-flight
            // fetch and does NOT rotate the token → secondToken == firstToken.
            // Pre-dedup (the failing-first baseline this test is designed to catch):
            // each call rotates unconditionally → secondToken != firstToken.
            expect(secondToken).to(equal(firstToken))
        }

        // Stale-result-drop regression: a late-arriving personalization callback from
        // a superseded fetch must NOT consume the current in-flight record (which
        // belongs to a newer fetch). Without the guard, a naïve
        // `map.removeValue(forKey: placeholder)` in the callback would orphan the newer
        // run's waiters. Under the `claimInFlightCarouselFetch` guard, the mismatched
        // `validationToken` makes the claim a no-op, leaving the newer record intact.
        it("stale personalized-fetch callback does not consume a newer in-flight record") {
            let concreteManager = manager as! InAppContentBlocksManager
            let placeholder = "carousel_stale_\(UUID().uuidString)"

            // Simulate a newer fetch that has taken over the placeholder's in-flight slot
            // after some older fetch was kicked off. The newer fetch owns `newerToken`
            // and has two waiters queued (the initiator + a subsequent caller that
            // attached via dedup).
            let olderToken = UUID()
            let newerToken = UUID()
            var initialFires = 0
            var completionFires = 0
            let newerRecord = CarouselInFlightFetch(
                validationToken: newerToken,
                waiters: [
                    (
                        initial: { initialFires += 1 },
                        completion: { completionFires += 1 }
                    ),
                    (
                        initial: { initialFires += 1 },
                        completion: { completionFires += 1 }
                    )
                ]
            )
            concreteManager.$carouselInFlightFetches.changeValue { $0[placeholder] = newerRecord }

            // The older fetch's callback finally arrives and attempts to claim — with
            // ITS own (now-stale) token. The guard must refuse, return nil, and leave
            // the newer record + its waiters untouched.
            let claimedByStale = concreteManager.claimInFlightCarouselFetch(
                placeholder: placeholder,
                validationToken: olderToken
            )
            expect(claimedByStale).to(beNil())
            expect(concreteManager.carouselInFlightFetches[placeholder]?.validationToken).to(equal(newerToken))
            expect(concreteManager.carouselInFlightFetches[placeholder]?.waiters.count).to(equal(2))
            expect(initialFires).to(equal(0))
            expect(completionFires).to(equal(0))

            // The newer fetch's own callback then arrives with the matching token and
            // correctly claims the record. Waiters are returned to the caller (who will
            // fan them out via `broadcastInitial` / `broadcastCompletion`) and the map
            // slot is cleared.
            let claimedByCurrent = concreteManager.claimInFlightCarouselFetch(
                placeholder: placeholder,
                validationToken: newerToken
            )
            expect(claimedByCurrent?.count).to(equal(2))
            expect(concreteManager.carouselInFlightFetches[placeholder]).to(beNil())
            // Manually fan out to verify the waiters are the ones we registered (not
            // stubs created by the claim path) — this also catches any accidental
            // truncation of the waiters array during the claim.
            claimedByCurrent?.forEach { waiter in
                waiter.initial?()
                waiter.completion?()
            }
            expect(initialFires).to(equal(2))
            expect(completionFires).to(equal(2))
        }

        // After the token rotates, a stale worker must not overwrite the fresh run's
        // image validation state.
        it("stale worker's final state write is a no-op when token has rotated") {
            let concreteManager = manager as! InAppContentBlocksManager
            let messageId = "stale-race-\(UUID().uuidString)"
            let placeholder = "carousel_race_\(UUID().uuidString)"

            // Run 1 starts — token T1 registered, `.pending` written.
            let tokenRun1 = UUID()
            concreteManager.$carouselValidationTokens.changeValue { $0[placeholder] = tokenRun1 }
            concreteManager.$imageValidationStates.changeValue { $0[messageId] = .pending }

            // Run 2 supersedes Run 1 — token T2 registered, fresh `.pending` written.
            let tokenRun2 = UUID()
            concreteManager.$carouselValidationTokens.changeValue { $0[placeholder] = tokenRun2 }
            concreteManager.$imageValidationStates.changeValue { $0[messageId] = .pending }

            // Run 1's stale worker attempts to finalize; this is a no-op because
            // the active token is T2, not T1.
            concreteManager.updateImageValidationState(
                messageId: messageId,
                placeholder: placeholder,
                validationToken: tokenRun1,
                isCorrupted: false
            )

            expect(concreteManager.imageValidationStates[messageId]).to(equal(.pending))

            // Meanwhile, Run 2's worker finalizing with the current token T2 DOES write through.
            concreteManager.updateImageValidationState(
                messageId: messageId,
                placeholder: placeholder,
                validationToken: tokenRun2,
                isCorrupted: true
            )
            expect(concreteManager.imageValidationStates[messageId]).to(equal(.corrupted))
        }

        describe("InAppContentBlockResponse") {
            let json: [String: Any] = [
                "id": "test-id",
                "name": "Test Name",
                "date_filter": [
                    "enabled": true,
                    "from_date": "2024-01-01T00:00:00Z",
                    "to_date": "2024-12-31T23:59:59Z"
                ],
                "placeholders": ["a", "b"],
                "frequency": "only_once",
                "load_priority": 5,
                "content_type": "html",
                "consent_category_tracking": "analytics"
            ]
            it("should decode and allow mutation of extra properties") {
                let json: [String: Any] = [
                    "id": "test-id",
                    "name": "Test Name",
                    "date_filter": [
                        "enabled": true,
                        "from_date": "2025-01-01T00:00:00Z",
                        "to_date": "2025-12-31T23:59:59Z"
                    ],
                    "frequency": "only_once",
                    "load_priority": 5,
                    "content_type": "html",
                    "consent_category_tracking": "analytics",
                    "placeholders": ["a", "b"]
                ]

                let data = try! JSONSerialization.data(withJSONObject: json)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601

                var block = try! decoder.decode(InAppContentBlockResponse.self, from: data)

                expect(block.id) == "test-id"
                expect(block.name) == "Test Name"
                expect(block.dateFilter.enabled) == true
                expect(block.dateFilter.fromDate).toNot(beNil())
                expect(block.placeholders).to(equal(["a", "b"]))
                expect(block.frequency) == .onlyOnce
                expect(block.loadPriority) == 5
                expect(block.contentType) == .html
                expect(block.trackingConsentCategory) == "analytics"

                expect(block.tags).to(equal([]))
                expect(block.sessionStart).toNot(beNil())
                expect(block.indexPath).to(beNil())
                expect(block.isCorruptedImage) == false
                expect(block.status).to(beNil())

                let now = Date()
                block.tags = [1, 2, 3]
                block.sessionStart = now
                block.indexPath = IndexPath(row: 4, section: 2)
                block.isCorruptedImage = true
                block.status = InAppContentBlocksDisplayStatus(displayed: now, interacted: now.addingTimeInterval(5))

                expect(block.tags).to(equal([1, 2, 3]))
                expect(block.sessionStart).to(equal(now))
                expect(block.indexPath).to(equal(IndexPath(row: 4, section: 2)))
                expect(block.isCorruptedImage).to(beTrue())
                expect(block.status?.displayed).to(equal(now))
                expect(block.status?.interacted).to(equal(now.addingTimeInterval(5)))
            }
            it("decodes and encodes properly including optional and extra attributes") {
                let data = try! JSONSerialization.data(withJSONObject: json)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let block = try! decoder.decode(InAppContentBlockResponse.self, from: data)
                
                expect(block.id) == "test-id"
                expect(block.name) == "Test Name"
                expect(block.dateFilter.enabled) == true
                expect(block.dateFilter.fromDate).toNot(beNil())
                expect(block.placeholders).to(equal(["a", "b"]))
                expect(block.frequency) == .onlyOnce
                expect(block.loadPriority) == 5
                expect(block.contentType) == .html
                expect(block.trackingConsentCategory) == "analytics"
                
                expect(block.tags).to(equal([]))
                expect(block.sessionStart).toNot(beNil())
                expect(block.indexPath).to(beNil())
                expect(block.isCorruptedImage) == false
                expect(block.status).to(beNil())
                
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                encoder.dateEncodingStrategy = .iso8601
                let encoded = try! encoder.encode(block)
                let roundTrip = try! decoder.decode(InAppContentBlockResponse.self, from: encoded)
                expect(roundTrip.id) == "test-id"
                expect(roundTrip.placeholders) == ["a", "b"]
            }
        }

        // Regression guard: CarouselInAppContentBlockView must not be retained by its
        // own Combine cancellables. Strong-self captures in the notification sinks
        // created a cycle that prevented dealloc after identifyCustomer(...) and could
        // surface previous-customer content.
        it("CarouselInAppContentBlockView is deallocated when the host releases its strong reference") {
            weak var weakView: CarouselInAppContentBlockView?
            autoreleasepool {
                let view = CarouselInAppContentBlockView(placeholder: "ph_carousel_dealloc")
                weakView = view
                // The host releases its only strong reference here.
                view.release()
            }
            // Combine subscriptions are cancelled and the array is drained on `release()`,
            // so the view should be deallocated immediately after the autoreleasepool drains.
            expect(weakView).toEventually(beNil(), timeout: .seconds(2))
        }

        // release() must cancel all Combine subscriptions and drain the cancellables array.
        it("CarouselInAppContentBlockView.release() cancels all Combine subscriptions") {
            let view = CarouselInAppContentBlockView(placeholder: "ph_carousel_cancel")
            expect(view.cancellables).toNot(beEmpty())
            view.release()
            expect(view.cancellables).to(beEmpty())
        }

        // Regression guard (cell-callback case): the cell wiring in `cellForItemAt`
        // previously assigned `cell.touchCallback = saveCurrentTimer` and
        // `cell.releaseCallback = startTimer` — unbound instance method refs that Swift
        // desugars into strong-self closures. That formed a fourth retain cycle
        // (self -> collectionView -> cell -> closure -> self) which is invisible to the
        // other two regression tests because they never trigger `cellForItemAt`.
        //
        // Test seam usage: `_testOnly_vendCellAtFirstIndex` vends through the view's own
        // (private, lazy) `collectionView`. This matters — vending through a scratch
        // collection view local to the test would NOT pin the cycle, because a local
        // collection view goes out of scope at the end of the autoreleasepool, releases
        // the cell, the cell releases its closures, and the view dealloca regardless of
        // the bug. Using `self.collectionView` mirrors the production retention graph
        // (the carousel keeps its own collection view alive via a stored property).
        it("CarouselInAppContentBlockView is deallocated even after a cell has been vended") {
            weak var weakView: CarouselInAppContentBlockView?
            autoreleasepool {
                let view = CarouselInAppContentBlockView(placeholder: "ph_carousel_cell_dealloc")
                weakView = view
                view._testOnly_seedData([StaticReturnData(html: "<html></html>", tag: 0)])
                view._testOnly_vendCellAtFirstIndex()
                view.release()
            }
            expect(weakView).toEventually(beNil(), timeout: .seconds(2))
        }

        // MARK: - WebContent process termination recovery (CarouselContentBlockViewCell)
        //
        // When iOS jetsams a cell's WebContent process (notably while the app
        // is backgrounded with the device locked), the cell must transparently
        // reissue the HTML it last rendered so the user does not return to a
        // blank carousel. The cache is `lastLoadedHtml`; it MUST be set on
        // every successful `loadHtml` and MUST be cleared on `prepareForReuse`
        // so a recycled cell never recovers with stale content from a previous
        // index.

        it("CarouselContentBlockViewCell.webViewWebContentProcessDidTerminate reissues the last loaded html") {
            let cell = CarouselContentBlockViewCell(frame: .zero)
            let html = "<html><body>recover-me</body></html>"
            cell.loadHtml(html: html, assignedMessage: nil, placeholder: "ph_recover")

            let spy = LoadHTMLStringSpyWebView()
            cell.webViewWebContentProcessDidTerminate(spy)

            expect(spy.loadedHtmlStrings).to(equal([html]))
        }

        it("CarouselContentBlockViewCell.webViewWebContentProcessDidTerminate is a no-op when no html has been loaded") {
            // Termination can fire on a freshly-vended cell that has not been
            // told to render anything yet (e.g. the WebContent process died
            // mid-`cellForItemAt`). Reissuing an empty/nil cache would either
            // crash or paint a blank page and clobber whatever recovery the
            // real `loadHtml` is about to do.
            let cell = CarouselContentBlockViewCell(frame: .zero)

            let spy = LoadHTMLStringSpyWebView()
            cell.webViewWebContentProcessDidTerminate(spy)

            expect(spy.loadedHtmlStrings).to(beEmpty())
        }

        it("CarouselContentBlockViewCell.webViewWebContentProcessDidTerminate is a no-op after prepareForReuse clears the cache") {
            // This is the key correctness property of clearing `lastLoadedHtml`
            // in `prepareForReuse`: a recycled cell must NOT auto-recover into
            // the previous index's HTML when the WebContent process is killed
            // before the new `loadHtml` lands. Otherwise the user would briefly
            // see the previous message under their finger after a swipe.
            let cell = CarouselContentBlockViewCell(frame: .zero)
            cell.loadHtml(html: "<html>previous</html>", assignedMessage: nil, placeholder: "ph_recover")
            cell.prepareForReuse()

            let spy = LoadHTMLStringSpyWebView()
            cell.webViewWebContentProcessDidTerminate(spy)

            expect(spy.loadedHtmlStrings).to(beEmpty())
        }

        it("CarouselContentBlockViewCell.webViewWebContentProcessDidTerminate is a no-op when the cached html is empty") {
            // Empty HTML is a sentinel for "no message" (see `onNoMessageFound`).
            // Reissuing it on recovery would surface a blank webview to the user
            // and pollute the spy/IPC channel with no benefit.
            let cell = CarouselContentBlockViewCell(frame: .zero)
            cell.loadHtml(html: "", assignedMessage: nil, placeholder: "ph_recover")

            let spy = LoadHTMLStringSpyWebView()
            cell.webViewWebContentProcessDidTerminate(spy)

            expect(spy.loadedHtmlStrings).to(beEmpty())
        }

        // MARK: - WebContent process termination recovery (WKWebViewHeightCalculator)
        //
        // The calculator is *off-screen* (never enters the view hierarchy), so
        // unlike a cell's webview, iOS does NOT auto-restart its WebContent
        // process after termination. Without an explicit reissue, no
        // `didFinish` ever reaches `heightUpdate` and the carousel stays pinned
        // at its initial 1pt placeholder height — the user returns to an
        // invisible carousel. These specs pin that the cached `lastLoadedHtml`
        // is the recovery payload, exactly as for the cell.

        it("WKWebViewHeightCalculator.webViewWebContentProcessDidTerminate reissues the last loaded html") {
            let calculator = WKWebViewHeightCalculator()
            let html = "<html><body style='height:200px'></body></html>"
            calculator.loadHtml(placedholderId: "ph_calc_recover", html: html)

            let spy = LoadHTMLStringSpyWebView()
            calculator.webViewWebContentProcessDidTerminate(spy)

            expect(spy.loadedHtmlStrings).to(equal([html]))
        }

        it("WKWebViewHeightCalculator.webViewWebContentProcessDidTerminate is a no-op when no html has been loaded") {
            let calculator = WKWebViewHeightCalculator()

            let spy = LoadHTMLStringSpyWebView()
            calculator.webViewWebContentProcessDidTerminate(spy)

            expect(spy.loadedHtmlStrings).to(beEmpty())
        }

        it("WKWebViewHeightCalculator.webViewWebContentProcessDidTerminate is a no-op when the cached html is empty") {
            // `loadHtml(placedholderId:html:)` short-circuits on empty input
            // (it fires `heightUpdate(0)` and intentionally does NOT populate
            // `lastLoadedHtml`), so the recovery path must do the same — no
            // spurious empty navigation on termination.
            let calculator = WKWebViewHeightCalculator()
            calculator.loadHtml(placedholderId: "ph_calc_recover", html: "")

            let spy = LoadHTMLStringSpyWebView()
            calculator.webViewWebContentProcessDidTerminate(spy)

            expect(spy.loadedHtmlStrings).to(beEmpty())
        }

        // MARK: - filterCarouselData expiration scoping
        //
        // The TTL-expiration check must be scoped to messages of the *queried*
        // placeholder. Including unrelated placeholders' expired messages
        // causes a permanent refresh loop because `loadMessagesForCarousel`
        // only re-fetches the queried placeholder, so unrelated expirations
        // are never resolved → `expiredCompletion` fires forever → the
        // carousel never paints.

        it("filterCarouselData ignores expired messages in unrelated placeholders so it cannot deadlock on TTL refresh") {
            // Reproduces the production scenario: app returns from a long
            // background; messages on `ph_other` are past their TTL but
            // `ph_under_test` has fresh content. The carousel for
            // `ph_under_test` MUST be allowed to paint.
            let validForUnderTest = SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                id: "valid-under-test-\(UUID().uuidString)",
                placeholders: ["ph_under_test"],
                personalized: .getSample(status: .ok, ttlSeen: Date())
            )
            let expiredOnUnrelated = SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                id: "expired-other-\(UUID().uuidString)",
                placeholders: ["ph_other"],
                personalized: .getSample(status: .ok, ttlSeen: Date(timeIntervalSinceNow: -3600))
            )
            manager.addMessage(validForUnderTest)
            manager.addMessage(expiredOnUnrelated)

            var continued: [InAppContentBlockResponse]?
            var expiredCompletionFired = false
            manager.filterCarouselData(
                placeholder: "ph_under_test",
                continueCallback: { continued = $0 },
                expiredCompletion: { expiredCompletionFired = true }
            )

            expect(expiredCompletionFired).to(beFalse())
            expect(continued).toNot(beNil())
            expect(continued?.contains(where: { $0.id == validForUnderTest.id })).to(beTrue())
            // Sanity: an unrelated placeholder's message must never appear in
            // the result for `ph_under_test`.
            expect(continued?.contains(where: { $0.id == expiredOnUnrelated.id })).to(beFalse())
        }

        it("filterCarouselData triggers expiredCompletion when the queried placeholder itself has expired messages") {
            // Inverse of the deadlock guard: when the QUERIED placeholder
            // genuinely has expired content, the SDK must request a refresh —
            // otherwise the carousel would paint stale messages.
            let expiredForUnderTest = SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                id: "expired-under-test-\(UUID().uuidString)",
                placeholders: ["ph_under_test"],
                personalized: .getSample(status: .ok, ttlSeen: Date(timeIntervalSinceNow: -3600))
            )
            manager.addMessage(expiredForUnderTest)

            var continued: [InAppContentBlockResponse]?
            var expiredCompletionFired = false
            manager.filterCarouselData(
                placeholder: "ph_under_test",
                continueCallback: { continued = $0 },
                expiredCompletion: { expiredCompletionFired = true }
            )

            expect(expiredCompletionFired).to(beTrue())
            expect(continued).to(beNil())
        }

        it("filterCarouselData returns only the queried placeholder's valid messages even when unrelated placeholders carry both valid and expired ones") {
            // Stronger version of the deadlock guard: the result set must be
            // strictly scoped to the queried placeholder regardless of what
            // mixture of states sits in unrelated placeholders.
            let validForUnderTest = SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                id: "valid-under-test-\(UUID().uuidString)",
                placeholders: ["ph_under_test"],
                personalized: .getSample(status: .ok, ttlSeen: Date())
            )
            let validForOther = SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                id: "valid-other-\(UUID().uuidString)",
                placeholders: ["ph_other"],
                personalized: .getSample(status: .ok, ttlSeen: Date())
            )
            let expiredForOther = SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                id: "expired-other-\(UUID().uuidString)",
                placeholders: ["ph_other"],
                personalized: .getSample(status: .ok, ttlSeen: Date(timeIntervalSinceNow: -3600))
            )
            manager.addMessage(validForUnderTest)
            manager.addMessage(validForOther)
            manager.addMessage(expiredForOther)

            var continued: [InAppContentBlockResponse]?
            manager.filterCarouselData(
                placeholder: "ph_under_test",
                continueCallback: { continued = $0 },
                expiredCompletion: { }
            )

            expect(continued?.count).to(equal(1))
            expect(continued?.first?.id).to(equal(validForUnderTest.id))
        }

        // MARK: - WebView pooling lifecycle

        it("WebView pooling returns the same instance after recycle") {
            guard let concreteManager = manager as? InAppContentBlocksManager else {
                fail("Expected concrete InAppContentBlocksManager")
                return
            }
            waitUntil(timeout: .seconds(5)) { done in
                onMain {
                    let holder = UIView()

                    // Exhaust the prepared pool so the next dequeue must come from issued-recycle path.
                    concreteManager.prewarmReusableContentBlockResourcesForStartup()
                    while concreteManager.preparedContentBlockWebViewCount > 0 {
                        let drain = concreteManager.dequeueContentBlockWebViewForTest(tag: 999)
                        holder.addSubview(drain)
                    }

                    let webView1 = concreteManager.dequeueContentBlockWebViewForTest(tag: 100)
                    let identity1 = ObjectIdentifier(webView1)
                    holder.addSubview(webView1)

                    expect(webView1.tag).to(equal(100))

                    // Detach — this is the "recycle" step.
                    webView1.removeFromSuperview()

                    let webView2 = concreteManager.dequeueContentBlockWebViewForTest(tag: 200)
                    let identity2 = ObjectIdentifier(webView2)

                    expect(identity2).to(equal(identity1))
                    expect(webView2.tag).to(equal(200))
                    done()
                }
            }
        }

        it("WebView pooling creates new instance when pool is exhausted") {
            guard let concreteManager = manager as? InAppContentBlocksManager else {
                fail("Expected concrete InAppContentBlocksManager")
                return
            }
            waitUntil(timeout: .seconds(5)) { done in
                onMain {
                    let holder = UIView()
                    var issuedViews: [WKWebView] = []
                    for i in 0..<5 {
                        let wv = concreteManager.dequeueContentBlockWebViewForTest(tag: i)
                        holder.addSubview(wv)
                        issuedViews.append(wv)
                    }

                    let identities = Set(issuedViews.map { ObjectIdentifier($0) })
                    expect(identities.count).to(equal(5))

                    issuedViews.forEach { $0.removeFromSuperview() }
                    done()
                }
            }
        }

        // MARK: - Queue deduplication

        it("queue deduplication prevents identical entries") {
            guard let concreteManager = manager as? InAppContentBlocksManager else {
                fail("Expected concrete InAppContentBlocksManager")
                return
            }
            concreteManager.clearQueueForTest()
            let message = SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                id: "dedup-test-\(UUID().uuidString)",
                placeholders: ["dedup_placeholder"]
            )
            let newValue = UsedInAppContentBlocks(
                tag: 1,
                indexPath: IndexPath(row: 0, section: 0),
                messageId: message.id,
                placeholder: "dedup_placeholder",
                height: 0
            )

            concreteManager.enqueueForTest(message: message, newValue: newValue)
            concreteManager.enqueueForTest(message: message, newValue: newValue)
            concreteManager.enqueueForTest(message: message, newValue: newValue)

            expect(concreteManager.queueCount).to(equal(1))
        }

        it("queue deduplication allows different messages for same cell") {
            guard let concreteManager = manager as? InAppContentBlocksManager else {
                fail("Expected concrete InAppContentBlocksManager")
                return
            }
            concreteManager.clearQueueForTest()
            let message1 = SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                id: "dedup-msg1-\(UUID().uuidString)",
                placeholders: ["dedup_placeholder"]
            )
            let message2 = SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                id: "dedup-msg2-\(UUID().uuidString)",
                placeholders: ["dedup_placeholder"]
            )
            let indexPath = IndexPath(row: 0, section: 0)
            let newValue1 = UsedInAppContentBlocks(
                tag: 1,
                indexPath: indexPath,
                messageId: message1.id,
                placeholder: "dedup_placeholder",
                height: 0
            )
            let newValue2 = UsedInAppContentBlocks(
                tag: 1,
                indexPath: indexPath,
                messageId: message2.id,
                placeholder: "dedup_placeholder",
                height: 0
            )

            concreteManager.enqueueForTest(message: message1, newValue: newValue1)
            concreteManager.enqueueForTest(message: message2, newValue: newValue2)

            // Same cell dedup replaces the pending entry rather than appending
            expect(concreteManager.queueCount).to(equal(1))
        }

        it("queue deduplication allows entries for different cells") {
            guard let concreteManager = manager as? InAppContentBlocksManager else {
                fail("Expected concrete InAppContentBlocksManager")
                return
            }
            concreteManager.clearQueueForTest()
            let message = SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                id: "dedup-multi-\(UUID().uuidString)",
                placeholders: ["dedup_placeholder"]
            )
            let newValue1 = UsedInAppContentBlocks(
                tag: 1,
                indexPath: IndexPath(row: 0, section: 0),
                messageId: message.id,
                placeholder: "dedup_placeholder",
                height: 0
            )
            let newValue2 = UsedInAppContentBlocks(
                tag: 2,
                indexPath: IndexPath(row: 1, section: 0),
                messageId: message.id,
                placeholder: "dedup_placeholder",
                height: 0
            )

            concreteManager.enqueueForTest(message: message, newValue: newValue1)
            concreteManager.enqueueForTest(message: message, newValue: newValue2)

            expect(concreteManager.queueCount).to(equal(2))
        }

        // MARK: - Refresh callback coalescing

        it("refresh callback coalescing suppresses duplicate notifications for the same cell") {
            guard let concreteManager = manager as? InAppContentBlocksManager else {
                fail("Expected concrete InAppContentBlocksManager")
                return
            }
            concreteManager.clearRefreshCoalescingState()
            var callbackCount = 0
            concreteManager.refreshCallback = { _ in
                callbackCount += 1
            }

            let indexPath = IndexPath(row: 0, section: 0)

            concreteManager.notifyRefreshCallbackForTest(
                indexPath: indexPath,
                source: "loadContentForPlaceholder.test",
                placeholder: "coalesce_ph"
            )
            concreteManager.notifyRefreshCallbackForTest(
                indexPath: indexPath,
                source: "loadContentForPlaceholder.test",
                placeholder: "coalesce_ph"
            )
            concreteManager.notifyRefreshCallbackForTest(
                indexPath: indexPath,
                source: "loadContentForPlaceholder.test",
                placeholder: "coalesce_ph"
            )

            expect(callbackCount).to(equal(1))
        }

        it("refresh callback coalescing allows different cells to fire independently") {
            guard let concreteManager = manager as? InAppContentBlocksManager else {
                fail("Expected concrete InAppContentBlocksManager")
                return
            }
            concreteManager.clearRefreshCoalescingState()
            var callbackCount = 0
            concreteManager.refreshCallback = { _ in
                callbackCount += 1
            }

            concreteManager.notifyRefreshCallbackForTest(
                indexPath: IndexPath(row: 0, section: 0),
                source: "loadContentForPlaceholder.a",
                placeholder: "ph_a"
            )
            concreteManager.notifyRefreshCallbackForTest(
                indexPath: IndexPath(row: 1, section: 0),
                source: "loadContentForPlaceholder.b",
                placeholder: "ph_b"
            )

            expect(callbackCount).to(equal(2))
        }

        it("refresh callback does not coalesce non-coalescable sources") {
            guard let concreteManager = manager as? InAppContentBlocksManager else {
                fail("Expected concrete InAppContentBlocksManager")
                return
            }
            concreteManager.clearRefreshCoalescingState()
            var callbackCount = 0
            concreteManager.refreshCallback = { _ in
                callbackCount += 1
            }

            let indexPath = IndexPath(row: 0, section: 0)

            concreteManager.notifyRefreshCallbackForTest(
                indexPath: indexPath,
                source: "someOtherSource",
                placeholder: "ph"
            )
            concreteManager.notifyRefreshCallbackForTest(
                indexPath: indexPath,
                source: "someOtherSource",
                placeholder: "ph"
            )

            expect(callbackCount).to(equal(2))
        }

        it("refresh callback coalescing works for calculateStaticData source") {
            guard let concreteManager = manager as? InAppContentBlocksManager else {
                fail("Expected concrete InAppContentBlocksManager")
                return
            }
            concreteManager.clearRefreshCoalescingState()
            var callbackCount = 0
            concreteManager.refreshCallback = { _ in
                callbackCount += 1
            }

            let indexPath = IndexPath(row: 0, section: 0)

            concreteManager.notifyRefreshCallbackForTest(
                indexPath: indexPath,
                source: "calculateStaticData.test",
                placeholder: "static_ph"
            )
            concreteManager.notifyRefreshCallbackForTest(
                indexPath: indexPath,
                source: "calculateStaticData.test",
                placeholder: "static_ph"
            )

            expect(callbackCount).to(equal(1))
        }

        it("loadContent fetches once and reaches height calculation through the completion-only personalized helper") {
            defer { MockingjayProtocol.removeAllStubs() }

            let placeholder = "height-calc-ph"
            let messageId = "height-calc-msg-\(UUID().uuidString)"
            manager.addMessage(
                SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                    id: messageId,
                    placeholders: [placeholder]
                )
            )

            let personalizedBody: Data = {
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
                            content: .init(html: "<html><body>height</body></html>"),
                            htmlPayload: nil,
                            ttlSeen: nil
                        )
                    ]
                )
                return (try? JSONEncoder().encode(response)) ?? Data()
            }()

            var fetchCount = 0
            MockingjayProtocol.addStub(
                matcher: { $0.url?.path.contains("inappcontentblocks") == true },
                builder: { _ in
                    fetchCount += 1
                    let response = HTTPURLResponse(
                        url: URL(string: "https://api.exponea.com/personalize")!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                    )!
                    return .success(response, .content(personalizedBody))
                }
            )

            let indexPath = IndexPath(row: 0, section: 0)
            var refreshCalled = false
            waitUntil(timeout: .seconds(15)) { done in
                manager.refreshCallback = { _ in
                    refreshCalled = true
                    done()
                }
                _ = manager.prepareInAppContentBlockView(
                    placeholderId: placeholder,
                    indexPath: indexPath
                )
            }

            expect(refreshCalled).to(beTrue())
            expect(fetchCount).to(equal(1))

            // Second prepare simulates a host table reload after refreshCallback.
            _ = manager.prepareInAppContentBlockView(
                placeholderId: placeholder,
                indexPath: indexPath
            )

            let concreteManager = manager as! InAppContentBlocksManager
            let stored = concreteManager.getUsedInAppContentBlocks(
                placeholder: placeholder,
                indexPath: indexPath
            )
            expect(stored?.height).to(beGreaterThan(0))
        }

        describe("prefetchPlaceholdersWithIds characterisation") {
            var testDefaults: UserDefaults!
            var testEtagStore: UserDefaultsETagStore!
            var provider: DeferredInAppContentBlocksDataProvider!
            var isolatedManager: InAppContentBlocksManager!

            func seedCatalogMessage(id: String, placeholders: [String]) {
                isolatedManager.addMessage(
                    SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                        id: id,
                        placeholders: placeholders
                    )
                )
            }

            func personalizedResponse(
                messageId: String,
                html: String = "<html><body>prefetched</body></html>"
            ) -> ResponseData<PersonalizedInAppContentBlockResponseData> {
                ResponseData(
                    data: PersonalizedInAppContentBlockResponseData(
                        data: [
                            PersonalizedInAppContentBlockResponse(
                                id: messageId,
                                status: .ok,
                                ttlSeconds: 60,
                                variantId: nil,
                                hasTrackingConsent: true,
                                variantName: nil,
                                contentType: .html,
                                content: .init(html: html),
                                htmlPayload: nil,
                                ttlSeen: nil
                            )
                        ]
                    ),
                    error: nil
                )
            }

            beforeEach {
                let suiteName = "test.prefetch.characterisation.\(UUID().uuidString)"
                testDefaults = UserDefaults(suiteName: suiteName)!
                testEtagStore = UserDefaultsETagStore(defaults: testDefaults)
                provider = DeferredInAppContentBlocksDataProvider()
                isolatedManager = InAppContentBlocksManager(
                    provider: provider,
                    etagStore: testEtagStore
                )
                isolatedManager.test_setCatalogReady()
            }

            it("invokes personalized fetch for matching catalog IDs and writes payload into cache") {
                seedCatalogMessage(id: "char-msg-a", placeholders: ["char-ph-a"])
                var completed = false

                isolatedManager.prefetchPlaceholdersWithIds(ids: ["char-ph-a"]) {
                    completed = true
                }

                expect(provider.personalizedBlockIds).to(equal([["char-msg-a"]]))
                provider.personalizedCompletion?(personalizedResponse(messageId: "char-msg-a"))

                expect(completed).toEventually(beTrue())
                expect(
                    isolatedManager.inAppContentBlockMessages.first { $0.id == "char-msg-a" }?
                        .personalizedMessage?.status
                ).to(equal(.ok))
            }

            it("completes immediately for empty placeholder IDs without a network call") {
                var completed = false

                isolatedManager.prefetchPlaceholdersWithIds(ids: []) {
                    completed = true
                }

                expect(completed).to(beTrue())
                expect(provider.personalizedBlockIds).to(beEmpty())
                expect(provider.catalogLoadCallCount).to(equal(0))
            }

            it("completes without a personalized request when the catalog has no matching placeholders") {
                seedCatalogMessage(id: "char-msg-known", placeholders: ["char-ph-known"])
                var completed = false

                isolatedManager.prefetchPlaceholdersWithIds(ids: ["char-ph-unknown"]) {
                    completed = true
                }

                expect(completed).toEventually(beTrue())
                expect(provider.personalizedBlockIds).to(beEmpty())
            }

            it("requests only message IDs tied to the requested placeholders") {
                seedCatalogMessage(id: "char-msg-1", placeholders: ["char-ph-1"])
                seedCatalogMessage(id: "char-msg-2", placeholders: ["char-ph-2"])
                seedCatalogMessage(id: "char-msg-3", placeholders: ["char-ph-1"])

                isolatedManager.prefetchPlaceholdersWithIds(ids: ["char-ph-1"], completion: nil)

                expect(provider.personalizedBlockIds.count).to(equal(1))
                expect(Set(provider.personalizedBlockIds[0])).to(equal(Set(["char-msg-1", "char-msg-3"])))
            }

            it("supports prefetch without a completion handler") {
                seedCatalogMessage(id: "char-msg-noop", placeholders: ["char-ph-noop"])

                isolatedManager.prefetchPlaceholdersWithIds(ids: ["char-ph-noop"])

                expect(provider.personalizedBlockIds).toEventually(equal([["char-msg-noop"]]))
            }
        }

        describe("invalidatePlaceholders") {
            var testDefaults: UserDefaults!
            var testEtagStore: UserDefaultsETagStore!
            var concreteManager: InAppContentBlocksManager!

            func etagCacheKey(blockIds: [String]) -> String {
                let customerIds = (try? DatabaseManager().currentCustomer.ids) ?? [:]
                let projectToken = Exponea.shared.configuration?.mainProject.integrationId ?? ""
                return UserDefaultsETagStore.cacheKey(
                    projectToken: projectToken,
                    customerIds: customerIds,
                    blockIds: blockIds
                )
            }

            func seedMessage(
                id: String,
                placeholders: [String],
                personalized: PersonalizedInAppContentBlockResponse? = nil
            ) {
                let message = SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                    id: id,
                    placeholders: placeholders,
                    personalized: personalized ?? .getSample(status: .ok, ttlSeen: Date())
                )
                concreteManager.addMessage(message)
            }

            beforeEach {
                let suiteName = "test.invalidate.\(UUID().uuidString)"
                testDefaults = UserDefaults(suiteName: suiteName)!
                testEtagStore = UserDefaultsETagStore(defaults: testDefaults)
                concreteManager = InAppContentBlocksManager(
                    provider: InAppContentBlocksDataProvider(),
                    etagStore: testEtagStore
                )
                (Exponea.shared as! ExponeaInternal).inAppContentBlocksManager = concreteManager
                manager = concreteManager
            }

            it("clears payload, height cache, selection pin, and ETag for a single placeholder") {
                let placeholderId = "inv-ph-1"
                let messageId = "inv-msg-1"
                seedMessage(id: messageId, placeholders: [placeholderId])
                concreteManager.test_seedPlaceholderCacheStores(
                    placeholderId: placeholderId,
                    messageId: messageId
                )
                let cacheKey = etagCacheKey(blockIds: [messageId])
                testEtagStore.store(etag: "\"inv-etag-1\"", forKey: cacheKey)

                expect(concreteManager.inAppContentBlockMessages.first { $0.id == messageId }?.personalizedMessage)
                    .toNot(beNil())
                expect(concreteManager.getUsedInAppContentBlocks(
                    placeholder: placeholderId,
                    indexPath: IndexPath(row: 0, section: 0)
                )).toNot(beNil())
                expect(concreteManager.test_heightSelectionMessageId(for: placeholderId)).to(equal(messageId))
                expect(testEtagStore.retrieve(forKey: cacheKey)).toNot(beNil())

                concreteManager.invalidatePlaceholders([placeholderId])

                expect(concreteManager.inAppContentBlockMessages.first { $0.id == messageId }?.personalizedMessage)
                    .to(beNil())
                expect(concreteManager.inAppContentBlockMessages.first { $0.id == messageId }?.normalizedResult)
                    .to(beNil())
                expect(concreteManager.getUsedInAppContentBlocks(
                    placeholder: placeholderId,
                    indexPath: IndexPath(row: 0, section: 0)
                )).to(beNil())
                expect(concreteManager.test_heightSelectionMessageId(for: placeholderId)).to(beNil())
                expect(testEtagStore.retrieve(forKey: cacheKey)).to(beNil())
            }

            it("clears only the specified placeholders when multiple IDs are invalidated") {
                seedMessage(id: "inv-msg-a", placeholders: ["inv-ph-a"])
                seedMessage(id: "inv-msg-b", placeholders: ["inv-ph-b"])
                concreteManager.test_seedPlaceholderCacheStores(placeholderId: "inv-ph-a", messageId: "inv-msg-a")
                concreteManager.test_seedPlaceholderCacheStores(placeholderId: "inv-ph-b", messageId: "inv-msg-b")

                let cacheKeyA = etagCacheKey(blockIds: ["inv-msg-a"])
                let cacheKeyB = etagCacheKey(blockIds: ["inv-msg-b"])
                let mergedCacheKey = etagCacheKey(blockIds: ["inv-msg-a", "inv-msg-b"])
                testEtagStore.store(etag: "\"etag-a\"", forKey: cacheKeyA)
                testEtagStore.store(etag: "\"etag-b\"", forKey: cacheKeyB)
                testEtagStore.store(etag: "\"etag-merged\"", forKey: mergedCacheKey)

                concreteManager.invalidatePlaceholders(["inv-ph-a", "inv-ph-b"])

                expect(concreteManager.inAppContentBlockMessages.first { $0.id == "inv-msg-a" }?.personalizedMessage)
                    .to(beNil())
                expect(concreteManager.inAppContentBlockMessages.first { $0.id == "inv-msg-b" }?.personalizedMessage)
                    .to(beNil())
                expect(concreteManager.getUsedInAppContentBlocks(
                    placeholder: "inv-ph-a",
                    indexPath: IndexPath(row: 0, section: 0)
                )).to(beNil())
                expect(concreteManager.getUsedInAppContentBlocks(
                    placeholder: "inv-ph-b",
                    indexPath: IndexPath(row: 0, section: 0)
                )).to(beNil())
                expect(testEtagStore.retrieve(forKey: cacheKeyA)).to(beNil())
                expect(testEtagStore.retrieve(forKey: cacheKeyB)).to(beNil())
                expect(testEtagStore.retrieve(forKey: mergedCacheKey)).to(beNil())
            }

            it("leaves unrelated placeholders untouched") {
                seedMessage(id: "inv-msg-target", placeholders: ["inv-ph-target"])
                seedMessage(id: "inv-msg-other", placeholders: ["inv-ph-other"])
                concreteManager.test_seedPlaceholderCacheStores(
                    placeholderId: "inv-ph-target",
                    messageId: "inv-msg-target"
                )
                concreteManager.test_seedPlaceholderCacheStores(
                    placeholderId: "inv-ph-other",
                    messageId: "inv-msg-other"
                )

                let targetCacheKey = etagCacheKey(blockIds: ["inv-msg-target"])
                let otherCacheKey = etagCacheKey(blockIds: ["inv-msg-other"])
                testEtagStore.store(etag: "\"etag-target\"", forKey: targetCacheKey)
                testEtagStore.store(etag: "\"etag-other\"", forKey: otherCacheKey)

                concreteManager.invalidatePlaceholders(["inv-ph-target"])

                expect(concreteManager.inAppContentBlockMessages.first { $0.id == "inv-msg-target" }?.personalizedMessage)
                    .to(beNil())
                expect(concreteManager.inAppContentBlockMessages.first { $0.id == "inv-msg-other" }?.personalizedMessage)
                    .toNot(beNil())
                expect(concreteManager.getUsedInAppContentBlocks(
                    placeholder: "inv-ph-target",
                    indexPath: IndexPath(row: 0, section: 0)
                )).to(beNil())
                expect(concreteManager.getUsedInAppContentBlocks(
                    placeholder: "inv-ph-other",
                    indexPath: IndexPath(row: 0, section: 0)
                )).toNot(beNil())
                expect(concreteManager.test_heightSelectionMessageId(for: "inv-ph-target")).to(beNil())
                expect(concreteManager.test_heightSelectionMessageId(for: "inv-ph-other")).to(equal("inv-msg-other"))
                expect(testEtagStore.retrieve(forKey: targetCacheKey)).to(beNil())
                expect(testEtagStore.retrieve(forKey: otherCacheKey)).to(equal("\"etag-other\""))
            }

            it("is a no-op for an empty placeholder ID list") {
                seedMessage(id: "inv-msg-noop", placeholders: ["inv-ph-noop"])
                concreteManager.test_seedPlaceholderCacheStores(
                    placeholderId: "inv-ph-noop",
                    messageId: "inv-msg-noop"
                )
                let cacheKey = etagCacheKey(blockIds: ["inv-msg-noop"])
                testEtagStore.store(etag: "\"etag-noop\"", forKey: cacheKey)

                concreteManager.invalidatePlaceholders([])

                expect(concreteManager.inAppContentBlockMessages.first { $0.id == "inv-msg-noop" }?.personalizedMessage)
                    .toNot(beNil())
                expect(concreteManager.getUsedInAppContentBlocks(
                    placeholder: "inv-ph-noop",
                    indexPath: IndexPath(row: 0, section: 0)
                )).toNot(beNil())
                expect(concreteManager.test_heightSelectionMessageId(for: "inv-ph-noop")).to(equal("inv-msg-noop"))
                expect(testEtagStore.retrieve(forKey: cacheKey)).to(equal("\"etag-noop\""))
            }

            it("bumps cacheGeneration to fence in-flight personalization writes") {
                let generationBefore = concreteManager.test_cacheGeneration
                concreteManager.invalidatePlaceholders(["inv-ph-fence"])
                expect(concreteManager.test_cacheGeneration).to(equal(generationBefore &+ 1))
            }

            it("does not bump cacheGeneration for an empty placeholder list") {
                let generationBefore = concreteManager.test_cacheGeneration
                concreteManager.invalidatePlaceholders([])
                expect(concreteManager.test_cacheGeneration).to(equal(generationBefore))
            }

            it("clears the height selection pin when anonymized") {
                let placeholderId = "anonymous-ph"
                let messageId = "anonymous-msg"
                seedMessage(id: messageId, placeholders: [placeholderId])
                concreteManager.test_seedPlaceholderCacheStores(
                    placeholderId: placeholderId,
                    messageId: messageId
                )

                expect(concreteManager.test_heightSelectionMessageId(for: placeholderId))
                    .to(equal(messageId))

                concreteManager.anonymize()

                expect(concreteManager.test_heightSelectionMessageId(for: placeholderId))
                    .to(beNil())
            }

            it("discards personalized responses started before anonymize") {
                let provider = DeferredInAppContentBlocksDataProvider()
                let isolatedManager = InAppContentBlocksManager(
                    provider: provider,
                    etagStore: testEtagStore
                )
                let placeholderId = "generation-ph"
                let messageId = "generation-msg"
                isolatedManager.addMessage(
                    SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                        id: messageId,
                        placeholders: [placeholderId]
                    )
                )
                // Catalog is dirty by default (correct production default). Prime it to ready so
                // this test can exercise the generation guard on in-flight personalization.
                isolatedManager.test_setCatalogReady()

                var completed = false
                isolatedManager.prefetchPlaceholdersWithIds(
                    ids: [placeholderId],
                    completion: { completed = true }
                )
                expect(provider.personalizedCompletion).toNot(beNil())

                isolatedManager.anonymize()
                isolatedManager.addMessage(
                    SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                        id: messageId,
                        placeholders: [placeholderId]
                    )
                )

                provider.personalizedCompletion?(
                    ResponseData(
                        data: PersonalizedInAppContentBlockResponseData(
                            data: [
                                PersonalizedInAppContentBlockResponse(
                                    id: messageId,
                                    status: .ok,
                                    ttlSeconds: 60,
                                    variantId: nil,
                                    hasTrackingConsent: true,
                                    variantName: nil,
                                    contentType: .html,
                                    content: .init(html: "<html><body>old customer</body></html>"),
                                    htmlPayload: nil,
                                    ttlSeen: nil
                                )
                            ]
                        ),
                        error: nil
                    )
                )

                expect(completed).toEventually(beTrue())
                expect(
                    isolatedManager.inAppContentBlockMessages.first { $0.id == messageId }?
                        .personalizedMessage
                ).to(beNil())
            }

            it("waits for the current customer catalog before personalized prefetch") {
                let provider = DeferredInAppContentBlocksDataProvider()
                let isolatedManager = InAppContentBlocksManager(
                    provider: provider,
                    etagStore: testEtagStore
                )
                isolatedManager.anonymize()

                var completed = false
                isolatedManager.prefetchPlaceholdersWithIds(
                    ids: ["generation-ph"],
                    completion: { completed = true }
                )

                expect(provider.catalogLoadCallCount).to(equal(1))
                expect(provider.personalizedBlockIds).to(beEmpty())
                expect(completed).to(beFalse())

                provider.catalogCompletion?(
                    ResponseData(
                        data: InAppContentBlocksDataResponse(
                            data: [
                                SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                                    id: "generation-msg",
                                    placeholders: ["generation-ph"]
                                )
                            ],
                            success: true
                        ),
                        error: nil
                    )
                )

                expect(provider.personalizedBlockIds).toEventually(equal([["generation-msg"]]))
            }

            it("coalesces concurrent first-use catalog loads") {
                let provider = DeferredInAppContentBlocksDataProvider()
                let isolatedManager = InAppContentBlocksManager(
                    provider: provider,
                    etagStore: testEtagStore
                )
                isolatedManager.anonymize()

                isolatedManager.prefetchPlaceholdersWithIds(ids: ["first"], completion: {})
                isolatedManager.prefetchPlaceholdersWithIds(ids: ["second"], completion: {})

                expect(provider.catalogLoadCallCount).to(equal(1))
            }

            it("retries the catalog after a failed first-use load") {
                let provider = DeferredInAppContentBlocksDataProvider()
                let isolatedManager = InAppContentBlocksManager(
                    provider: provider,
                    etagStore: testEtagStore
                )
                isolatedManager.anonymize()

                isolatedManager.prefetchPlaceholdersWithIds(ids: ["generation-ph"], completion: {})
                provider.catalogCompletion?(
                    ResponseData(
                        data: nil,
                        error: NSError(domain: "RuntimeICB", code: 1)
                    )
                )
                isolatedManager.prefetchPlaceholdersWithIds(ids: ["generation-ph"], completion: {})

                expect(provider.catalogLoadCallCount).to(equal(2))
                expect(provider.personalizedBlockIds).to(beEmpty())
            }

            it("does not personalize when a valid catalog has no requested ids") {
                let provider = DeferredInAppContentBlocksDataProvider()
                let isolatedManager = InAppContentBlocksManager(
                    provider: provider,
                    etagStore: testEtagStore
                )
                isolatedManager.anonymize()
                var completed = false

                isolatedManager.prefetchPlaceholdersWithIds(
                    ids: ["unknown-ph"],
                    completion: { completed = true }
                )
                provider.catalogCompletion?(
                    ResponseData(
                        data: InAppContentBlocksDataResponse(data: [], success: true),
                        error: nil
                    )
                )

                expect(completed).toEventually(beTrue())
                expect(provider.personalizedBlockIds).to(beEmpty())
            }

            it("reloads a mounted placeholder after its first-use catalog load") {
                let provider = DeferredInAppContentBlocksDataProvider()
                let isolatedManager = InAppContentBlocksManager(
                    provider: provider,
                    etagStore: testEtagStore
                )
                isolatedManager.anonymize()
                var refreshedIndexPath: IndexPath?
                isolatedManager.refreshCallback = { refreshedIndexPath = $0 }
                let indexPath = IndexPath(row: 2, section: 1)

                _ = isolatedManager.prepareInAppContentBlockView(
                    placeholderId: "generation-ph",
                    indexPath: indexPath
                )

                expect(provider.catalogLoadCallCount).to(equal(1))
                expect(refreshedIndexPath).to(beNil())

                provider.catalogCompletion?(
                    ResponseData(
                        data: InAppContentBlocksDataResponse(
                            data: [
                                SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                                    id: "generation-msg",
                                    placeholders: ["generation-ph"]
                                )
                            ],
                            success: true
                        ),
                        error: nil
                    )
                )

                expect(refreshedIndexPath).toEventually(equal(indexPath))
            }

            it("does not personalize an empty catalog for a first-use static view") {
                let provider = DeferredInAppContentBlocksDataProvider()
                let isolatedManager = InAppContentBlocksManager(
                    provider: provider,
                    etagStore: testEtagStore
                )
                isolatedManager.anonymize()
                var completed = false

                isolatedManager.refreshStaticViewContent(
                    staticQueueData: StaticQueueData(
                        tag: 1,
                        placeholderId: "unknown-static",
                        makeResourcesOffline: false,
                        completion: { _ in completed = true }
                    )
                )
                provider.catalogCompletion?(
                    ResponseData(
                        data: InAppContentBlocksDataResponse(data: [], success: true),
                        error: nil
                    )
                )

                expect(completed).toEventually(beTrue())
                expect(provider.personalizedBlockIds).to(beEmpty())
            }

            it("does not personalize an empty catalog for a first-use carousel") {
                let provider = DeferredInAppContentBlocksDataProvider()
                let isolatedManager = InAppContentBlocksManager(
                    provider: provider,
                    etagStore: testEtagStore
                )
                isolatedManager.anonymize()
                var initialCompleted = false
                var completed = false

                isolatedManager.loadMessagesForCarousel(
                    placeholder: "unknown-carousel",
                    initialCompletion: { initialCompleted = true },
                    completion: { completed = true }
                )
                provider.catalogCompletion?(
                    ResponseData(
                        data: InAppContentBlocksDataResponse(data: [], success: true),
                        error: nil
                    )
                )

                expect(initialCompleted).toEventually(beTrue())
                expect(completed).toEventually(beTrue())
                expect(provider.personalizedBlockIds).to(beEmpty())
            }

            it("reaches ready state after a stale-generation completion flips catalogState to dirty") {
                let provider = DeferredInAppContentBlocksDataProvider()
                let isolatedManager = InAppContentBlocksManager(
                    provider: provider,
                    etagStore: testEtagStore
                )
                isolatedManager.anonymize()

                var firstCompleted = false
                isolatedManager.prefetchPlaceholdersWithIds(
                    ids: ["race-ph"],
                    completion: { firstCompleted = true }
                )

                // Simulate identifyCustomer bumping the generation before the first load returns.
                isolatedManager.anonymize()

                // Stale catalog completion arrives — this flips catalogState back to dirty.
                provider.catalogCompletion?(
                    ResponseData(
                        data: InAppContentBlocksDataResponse(data: [], success: true),
                        error: nil
                    )
                )

                // A fresh load triggered by the second prefetch should still succeed.
                var secondCompleted = false
                isolatedManager.prefetchPlaceholdersWithIds(
                    ids: ["race-ph"],
                    completion: { secondCompleted = true }
                )
                provider.catalogCompletion?(
                    ResponseData(
                        data: InAppContentBlocksDataResponse(data: [], success: true),
                        error: nil
                    )
                )

                expect(secondCompleted).toEventually(beTrue())
                expect(provider.catalogLoadCallCount).to(equal(2))
            }
        }
    }
}

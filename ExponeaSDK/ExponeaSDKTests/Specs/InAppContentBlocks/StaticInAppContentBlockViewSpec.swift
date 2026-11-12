//
//  StaticInAppContentBlockViewSpec.swift
//  ExponeaSDKTests
//
//  Created by Adam Mihalik on 02/02/2024.
//  Copyright © 2024 Exponea. All rights reserved.
//

import Foundation
import XCTest
import Quick
import Nimble
import WebKit

@testable import ExponeaSDK

class StaticInAppContentBlockViewSpec: QuickSpec {
    let configuration = try! Configuration(
        projectToken: "token",
        authorization: Authorization.none,
        baseUrl: "baseUrl"
    )
    override func spec() {
        it("should NOT invoke error event for about:blank action URL") {
            let view = StaticInAppContentBlockView(placeholder: "ph_1", deferredLoad: true)
            var errorCalled = false
            view.behaviourCallback = SimpleBehaviourCallback(
                onErrorAction: { _, _, _ in
                    errorCalled = true
                }
            )
            let action = SimpleNavigationAction(url: URL(string: "about:blank")!)
            var actionHasBeenHandled: Bool?
            view.webView(WKWebView(), decidePolicyFor: action) { decision in
                // canceled action means that action has been handled internaly, WebView is not allowed to continue
                actionHasBeenHandled = decision == .cancel
            }
            expect(actionHasBeenHandled).toNot(beNil())
            guard let actionHasBeenHandled = actionHasBeenHandled else {
                return
            }
            expect(actionHasBeenHandled).to(beFalse())
            expect(errorCalled).to(beFalse())
        }
    }
}

final class StaticInAppContentBlockViewTests: XCTestCase {
    private let configuration = try! Configuration(
        projectToken: "token",
        authorization: Authorization.none,
        baseUrl: "baseUrl"
    )

    override func setUp() {
        super.setUp()
        Exponea.shared = ExponeaInternal()
        IntegrationManager.shared.isStopped = false
        Exponea.shared.configure(with: configuration)
        // Let the startup prewarm finish so web view creation counts below are stable.
        settleContentBlockWebViewWork()
    }

    override func tearDown() {
        InAppContentBlocksManager.manager.inAppContentBlockMessages = []
        super.tearDown()
    }

    func testSubtractsCalculatorPaddingFromRenderedHeight() {
        let expectation = expectation(description: "height completion")
        var reportedHeight: Int?
        let animationsEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)
        defer {
            UIView.setAnimationsEnabled(animationsEnabled)
        }

        let view = StaticInAppContentBlockView(
            placeholder: "ph_1",
            deferredLoad: true,
            heightCompletion: { height in
                reportedHeight = height
                if height == 100 {
                    expectation.fulfill()
                }
            }
        )

        view.calculator.heightUpdate?(.init(height: 120, placeholderId: "ph_1"))
        wait(for: [expectation], timeout: 2)

        // 120 from the calculator includes its 20pt defaultPadding.
        XCTAssertEqual(reportedHeight, 100)
        let displayWebView = view.subviews.first as? WKWebView
        XCTAssertEqual(displayWebView?.scrollView.contentInsetAdjustmentBehavior, .never)
        XCTAssertEqual(displayWebView?.scrollView.contentInset, .zero)
    }

    func testDoesNotCreateWebViewsInInit() {
        let createdBefore = ContentBlockWebViewFactory.createdCount
        let deferred = StaticInAppContentBlockView(placeholder: "ph_1", deferredLoad: true)
        XCTAssertFalse(deferred.hasCreatedWebViews)
        XCTAssertFalse(deferred.subviews.contains { $0 is WKWebView })
        XCTAssertEqual(ContentBlockWebViewFactory.createdCount, createdBefore)
    }

    func testDoesNotCreateWebViewsWhenThereIsNoContent() {
        let expectation = expectation(description: "no message found")
        let animationsEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)
        defer {
            UIView.setAnimationsEnabled(animationsEnabled)
        }

        let createdBefore = ContentBlockWebViewFactory.createdCount
        let view = StaticInAppContentBlockView(placeholder: "", deferredLoad: true)
        view.behaviourCallback = SimpleBehaviourCallback(
            onNoMessageFoundAction: { _ in
                expectation.fulfill()
            }
        )
        view.load()
        wait(for: [expectation], timeout: 2)

        XCTAssertFalse(view.hasCreatedWebViews)
        XCTAssertFalse(view.subviews.contains { $0 is WKWebView })
        XCTAssertEqual(ContentBlockWebViewFactory.createdCount, createdBefore)
    }

    // Known remaining cost: when content is already cached at init, the view measures it right
    // away, so the height calculator is created during init (and the first WKWebView cost with it).
    func testCreatesCalculatorDuringInitWhenContentIsAlreadyCached() {
        InAppContentBlocksManager.manager.clearPreparedContentBlockWebViewsForTest()
        var personalized = PersonalizedInAppContentBlockResponse.getSample(status: .ok, ttlSeen: Date())
        var payload = NormalizedResult()
        payload.html = "<html><body>cached</body></html>"
        personalized.htmlPayload = payload
        InAppContentBlocksManager.manager.inAppContentBlockMessages = [
            SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                dateFilter: .init(enabled: false, fromDate: nil, toDate: nil),
                placeholders: ["ph_cached"],
                personalized: personalized
            )
        ]

        let createdBefore = ContentBlockWebViewFactory.createdCount
        let view = StaticInAppContentBlockView(placeholder: "ph_cached")

        XCTAssertTrue(view.hasCreatedWebViews)
        XCTAssertEqual(ContentBlockWebViewFactory.createdCount - createdBefore, 1)
    }

    func testLoadFromBackgroundThreadCreatesNoWebViewOffMain() {
        var personalized = PersonalizedInAppContentBlockResponse.getSample(status: .ok, ttlSeen: Date())
        var payload = NormalizedResult()
        payload.html = "<html><body>cached</body></html>"
        personalized.htmlPayload = payload
        InAppContentBlocksManager.manager.inAppContentBlockMessages = [
            SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                dateFilter: .init(enabled: false, fromDate: nil, toDate: nil),
                placeholders: ["ph_background"],
                personalized: personalized
            )
        ]
        let view = StaticInAppContentBlockView(placeholder: "ph_background", deferredLoad: true)
        let offMainBefore = ContentBlockWebViewFactory.createdOffMainThreadCount

        let loaded = expectation(description: "load called off main")
        DispatchQueue.global().async {
            view.load()
            loaded.fulfill()
        }
        wait(for: [loaded], timeout: 2)
        settleContentBlockWebViewWork()

        XCTAssertTrue(view.hasCreatedWebViews)
        XCTAssertEqual(ContentBlockWebViewFactory.createdOffMainThreadCount, offMainBefore)
    }

    func testPoolRefillIsDeferredPastTheRender() {
        InAppContentBlocksManager.manager.clearPreparedContentBlockWebViewsForTest()
        let createdBefore = ContentBlockWebViewFactory.createdCount

        _ = InAppContentBlocksManager.manager.preparedStaticHeightCalculator()
        // Only the calculator the caller asked for is created in the same call.
        XCTAssertEqual(ContentBlockWebViewFactory.createdCount - createdBefore, 1)

        settleContentBlockWebViewWork()
        // The spare one for the pool follows on a later main-queue pass.
        XCTAssertEqual(ContentBlockWebViewFactory.createdCount - createdBefore, 2)
    }

    func testPoolIsNotRefilledWhenPrewarmIsDisabled() {
        let manager = InAppContentBlocksManager.manager
        let wasEnabled = manager.isPrewarmEnabled
        manager.isPrewarmEnabled = false
        defer { manager.isPrewarmEnabled = wasEnabled }
        settleContentBlockWebViewWork()
        manager.clearPreparedContentBlockWebViewsForTest()
        let createdBefore = ContentBlockWebViewFactory.createdCount

        _ = manager.preparedStaticHeightCalculator()
        settleContentBlockWebViewWork()

        XCTAssertEqual(ContentBlockWebViewFactory.createdCount - createdBefore, 1)
        XCTAssertFalse(manager.hasPreparedOrWarmingStaticHeightCalculator)
    }

    func testTableRenderKeepsNoSpareWebViewsWhenPrewarmIsDisabled() {
        let manager = InAppContentBlocksManager.manager
        let wasEnabled = manager.isPrewarmEnabled
        manager.isPrewarmEnabled = false
        defer { manager.isPrewarmEnabled = wasEnabled }
        settleContentBlockWebViewWork()
        manager.clearPreparedContentBlockWebViewsForTest()
        settleContentBlockWebViewWork()
        let createdBefore = ContentBlockWebViewFactory.createdCount

        _ = manager.dequeueContentBlockWebViewForTest(tag: 1)
        settleContentBlockWebViewWork()

        XCTAssertEqual(ContentBlockWebViewFactory.createdCount - createdBefore, 1)
        XCTAssertEqual(manager.preparedContentBlockWebViewCount, 0)
    }

    func testTableContentLoadPreparesNoSpareWebViewsWhenPrewarmIsDisabled() {
        let manager = InAppContentBlocksManager.manager
        let wasEnabled = manager.isPrewarmEnabled
        manager.isPrewarmEnabled = false
        defer { manager.isPrewarmEnabled = wasEnabled }
        settleContentBlockWebViewWork()
        manager.clearPreparedContentBlockWebViewsForTest()
        settleContentBlockWebViewWork()
        let createdBefore = ContentBlockWebViewFactory.createdCount

        manager.prewarmContentBlockWebViewsForTest()
        settleContentBlockWebViewWork()

        XCTAssertEqual(ContentBlockWebViewFactory.createdCount, createdBefore)
        XCTAssertEqual(manager.preparedContentBlockWebViewCount, 0)
    }

    func testTableRenderKeepsSpareWebViewsWhenPrewarmIsEnabled() {
        let manager = InAppContentBlocksManager.manager
        manager.isPrewarmEnabled = true
        settleContentBlockWebViewWork()
        manager.clearPreparedContentBlockWebViewsForTest()
        settleContentBlockWebViewWork()

        _ = manager.dequeueContentBlockWebViewForTest(tag: 1)
        settleContentBlockWebViewWork()

        XCTAssertEqual(manager.preparedContentBlockWebViewCount, 2)
    }

    func testCreatesDisplayWebViewOnceContentArrives() {
        let view = StaticInAppContentBlockView(placeholder: "ph_1", deferredLoad: true)
        XCTAssertFalse(view.hasCreatedWebViews)

        // First access creates the calculator lazily, with the height callback wired.
        XCTAssertNotNil(view.calculator.heightUpdate)
        XCTAssertTrue(view.hasCreatedWebViews)
    }

    func testSettingPublicHeightUpdateCreatesNoWebViews() {
        InAppContentBlockRenderHistory.shared.clear()
        defer { InAppContentBlockRenderHistory.shared.resetToSteadyStateForTest() }
        InAppContentBlocksManager.manager.clearPreparedContentBlockWebViewsForTest()
        InAppContentBlocksManager.manager.clearPreparedStaticHeightCalculatorsForTest()
        let createdBefore = ContentBlockWebViewFactory.createdCount

        let view = StaticInAppContentBlockView(placeholder: "ph_1", deferredLoad: true)
        view.publicHeightUpdate = { _ in }
        settleContentBlockWebViewWork()

        XCTAssertFalse(view.hasCreatedWebViews)
        XCTAssertEqual(ContentBlockWebViewFactory.createdCount, createdBefore)
    }

    func testPublicHeightUpdateSetBeforeCalculatorExistsIsCalled() {
        let view = StaticInAppContentBlockView(placeholder: "ph_1", deferredLoad: true)
        let called = expectation(description: "public height update")
        var reported: CalculatorData?
        view.publicHeightUpdate = { data in
            reported = data
            called.fulfill()
        }
        XCTAssertFalse(view.hasCreatedWebViews)

        view.calculator.heightUpdate?(.init(height: 120, placeholderId: "ph_1"))
        wait(for: [called], timeout: 2)

        XCTAssertEqual(reported?.height, 100)
        XCTAssertEqual(reported?.placeholderId, "ph_1")
    }

    func testPublicHeightUpdateSetAfterCalculatorExistsIsCalled() {
        let view = StaticInAppContentBlockView(placeholder: "ph_1", deferredLoad: true)
        let calculator = view.calculator
        let called = expectation(description: "public height update")
        view.publicHeightUpdate = { _ in called.fulfill() }

        calculator.heightUpdate?(.init(height: 120, placeholderId: "ph_1"))
        wait(for: [called], timeout: 2)
    }

    func testHeightUpdateOffMainCreatesNoWebViewOffMainAndReportsOnMain() {
        let view = StaticInAppContentBlockView(placeholder: "ph_1", deferredLoad: true)
        let called = expectation(description: "public height update")
        var calledOnMain: Bool?
        view.publicHeightUpdate = { _ in
            calledOnMain = Thread.isMainThread
            called.fulfill()
        }
        let calculator = view.calculator
        let offMainBefore = ContentBlockWebViewFactory.createdOffMainThreadCount

        DispatchQueue.global().async {
            calculator.heightUpdate?(.init(height: 120, placeholderId: "ph_1"))
        }
        wait(for: [called], timeout: 2)

        XCTAssertEqual(calledOnMain, true)
        XCTAssertEqual(ContentBlockWebViewFactory.createdOffMainThreadCount, offMainBefore)
    }

    func testPublicHeightUpdateReportsZeroWhenShownContentBecomesEmpty() {
        let animationsEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(animationsEnabled) }
        let view = StaticInAppContentBlockView(placeholder: "ph_1", deferredLoad: true)
        var reported: [CGFloat] = []
        let shown = expectation(description: "content height")
        let collapsed = expectation(description: "collapsed height")
        view.publicHeightUpdate = { data in
            reported.append(data.height)
            if data.height > 0 {
                shown.fulfill()
            } else {
                collapsed.fulfill()
            }
        }
        view.calculator.heightUpdate?(.init(height: 120, placeholderId: "ph_1"))
        wait(for: [shown], timeout: 2)

        view.loadContentForTest(html: "")
        wait(for: [collapsed], timeout: 2)

        XCTAssertEqual(reported, [100, 0])
    }

    func testPublicHeightUpdateReportsZeroWhenShownContentMeasuresZero() {
        let animationsEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(animationsEnabled) }
        let view = StaticInAppContentBlockView(placeholder: "ph_1", deferredLoad: true)
        var reported: [CGFloat] = []
        let shown = expectation(description: "content height")
        let collapsed = expectation(description: "collapsed height")
        view.publicHeightUpdate = { data in
            reported.append(data.height)
            if data.height > 0 {
                shown.fulfill()
            } else {
                collapsed.fulfill()
            }
        }
        view.calculator.heightUpdate?(.init(height: 120, placeholderId: "ph_1"))
        wait(for: [shown], timeout: 2)

        view.calculator.heightUpdate?(.init(height: 0, placeholderId: "ph_1"))
        wait(for: [collapsed], timeout: 2)

        XCTAssertEqual(reported, [100, 0])
    }

    func testPublicHeightUpdateReportsZeroWhenIntegrationStops() {
        let animationsEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(animationsEnabled) }
        let view = StaticInAppContentBlockView(placeholder: "ph_1", deferredLoad: true)
        let stopCallback = IntegrationManager.shared.onIntegrationStoppedCallbacks.last
        var reported: [CGFloat] = []
        let shown = expectation(description: "content height")
        let collapsed = expectation(description: "collapsed height")
        view.publicHeightUpdate = { data in
            reported.append(data.height)
            if data.height > 0 {
                shown.fulfill()
            } else {
                collapsed.fulfill()
            }
        }
        view.calculator.heightUpdate?(.init(height: 120, placeholderId: "ph_1"))
        wait(for: [shown], timeout: 2)

        stopCallback?()
        wait(for: [collapsed], timeout: 2)

        XCTAssertEqual(reported, [100, 0])
    }

    func testPublicHeightUpdateIsNotCalledWhenContentMeasuresZero() {
        let animationsEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(animationsEnabled) }
        let laidOut = expectation(description: "height completion")
        let view = StaticInAppContentBlockView(
            placeholder: "ph_1",
            deferredLoad: true,
            heightCompletion: { _ in laidOut.fulfill() }
        )
        var called = false
        view.publicHeightUpdate = { _ in called = true }

        // Empty content: the calculator reports only its padding.
        view.calculator.heightUpdate?(.init(height: view.calculator.defaultPadding, placeholderId: "ph_1"))
        wait(for: [laidOut], timeout: 2)

        XCTAssertFalse(called)
    }

    func testHeightChangeAfterShownReportsContentHeight() {
        let animationsEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(animationsEnabled) }
        var completed: [Int] = []
        var reported: [CGFloat] = []
        let shown = expectation(description: "first height")
        let changed = expectation(description: "changed height")
        let view = StaticInAppContentBlockView(
            placeholder: "ph_1",
            deferredLoad: true,
            heightCompletion: { height in
                completed.append(height)
                if height == 100 {
                    shown.fulfill()
                } else {
                    changed.fulfill()
                }
            }
        )
        view.publicHeightUpdate = { reported.append($0.height) }

        view.calculator.heightUpdate?(.init(height: 120, placeholderId: "ph_1"))
        wait(for: [shown], timeout: 2)
        // The block is on screen now, so this goes through the update path.
        view.calculator.heightUpdate?(.init(height: 150, placeholderId: "ph_1"))
        wait(for: [changed], timeout: 2)

        XCTAssertEqual(completed, [100, 130])
        XCTAssertEqual(reported, [100, 130])
    }

    // Real calculator and view together: the padding the calculator adds is the padding the view removes.
    func testRenderedHeightMatchesMeasuredHtmlHeight() {
        let animationsEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(animationsEnabled) }
        let laidOut = expectation(description: "height completion")
        var reportedHeight: Int?
        let view = StaticInAppContentBlockView(
            placeholder: "ph_1",
            deferredLoad: true,
            heightCompletion: { height in
                reportedHeight = height
                laidOut.fulfill()
            }
        )

        view.loadContentForTest(html: "<html><body style=\"margin:0\"><div style=\"height:100px\"></div></body></html>")
        wait(for: [laidOut], timeout: 10)

        XCTAssertEqual(reportedHeight, 100)
    }

    func testPublicHeightUpdateIsNotCalledWhenPlaceholderStaysEmpty() {
        let animationsEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(animationsEnabled) }
        let view = StaticInAppContentBlockView(placeholder: "ph_1", deferredLoad: true)
        var called = false
        view.publicHeightUpdate = { _ in called = true }

        view.loadContentForTest(html: "")
        settleContentBlockWebViewWork()

        XCTAssertFalse(called)
    }

    // Height is reported only once there is content with a height.
    func testPublicHeightUpdateIsNotCalledWithoutContentHeight() {
        let view = StaticInAppContentBlockView(placeholder: "ph_1", deferredLoad: true)
        var called = false
        view.publicHeightUpdate = { _ in called = true }

        view.calculator.loadHtml(placedholderId: "ph_1", html: "")
        settleContentBlockWebViewWork()

        XCTAssertFalse(called)
    }

    func testPublicHeightUpdateLeavesCalculatorPublicHeightUpdateUntouched() {
        let view = StaticInAppContentBlockView(placeholder: "ph_1", deferredLoad: true)
        let calculatorCallback = expectation(description: "calculator public height update")
        view.calculator.publicHeightUpdate = { _ in calculatorCallback.fulfill() }
        view.publicHeightUpdate = { _ in }

        view.calculator.loadHtml(placedholderId: "ph_1", html: "")
        wait(for: [calculatorCallback], timeout: 2)
    }

    func testCarouselDoesNotCreateCalculatorInInit() {
        let createdBefore = ContentBlockWebViewFactory.createdCount
        let carousel = CarouselInAppContentBlockView(placeholder: "ph_carousel")
        XCTAssertFalse(carousel.isCalculatorCreated)
        XCTAssertEqual(ContentBlockWebViewFactory.createdCount, createdBefore)

        // First access creates the calculator lazily, with the height callback wired.
        XCTAssertNotNil(carousel.calculator.heightUpdate)
        XCTAssertTrue(carousel.isCalculatorCreated)
    }

    // The filter callback runs on a background queue when the catalog has to be reloaded first.
    // The carousel must still create its height calculator (a WKWebView) on the main thread.
    func testCarouselCreatesCalculatorOnMainWhenFilterCallsBackOffMain() {
        var personalized = PersonalizedInAppContentBlockResponse.getSample(status: .ok, ttlSeen: Date())
        var payload = NormalizedResult()
        payload.html = "<html><body>carousel</body></html>"
        personalized.htmlPayload = payload
        let response = SampleInAppContentBlocks.getSampleIninAppContentBlocks(
            dateFilter: .init(enabled: false, fromDate: nil, toDate: nil),
            placeholders: ["ph_carousel_bg"],
            personalized: personalized
        )
        InAppContentBlocksManager.manager.inAppContentBlockMessages = [response]

        let offMainBefore = ContentBlockWebViewFactory.createdOffMainThreadCount
        let carousel = BackgroundFilterCarouselView(placeholder: "ph_carousel_bg")
        carousel.responses = [response]
        carousel._testOnly_applyCarouselData()

        let created = expectation(description: "calculator created")
        func poll() {
            if carousel.isCalculatorCreated {
                created.fulfill()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: poll)
            }
        }
        poll()
        wait(for: [created], timeout: 3)

        XCTAssertEqual(ContentBlockWebViewFactory.createdOffMainThreadCount, offMainBefore)
    }
}

/// Delivers the filter result on a background queue, like `filterCarouselData` does when it has
/// to reload the content block catalog before filtering.
private final class BackgroundFilterCarouselView: CarouselInAppContentBlockView {
    var responses: [InAppContentBlockResponse] = []

    override func filterContentBlocks(
        placeholder: String,
        continueCallback: TypeBlock<[InAppContentBlockResponse]>?,
        expiredCompletion: EmptyBlock?
    ) {
        let responses = self.responses
        DispatchQueue.global(qos: .userInitiated).async {
            continueCallback?(responses)
        }
    }
}

final class ContentBlockStartupPrewarmTests: XCTestCase {
    private var historyDefaults: UserDefaults!
    private var historySuiteName: String!

    override func setUp() {
        super.setUp()
        IntegrationManager.shared.isStopped = false
        settleContentBlockWebViewWork()
        historySuiteName = "test.prewarm.render-history.\(UUID().uuidString)"
        historyDefaults = UserDefaults(suiteName: historySuiteName)
        InAppContentBlockRenderHistory.shared.clear()
    }

    override func tearDown() {
        IntegrationManager.shared.isStopped = false
        InAppContentBlockRenderHistory.shared.resetToSteadyStateForTest()
        InAppContentBlocksManager.manager.inAppContentBlockMessages = []
        historyDefaults.removePersistentDomain(forName: historySuiteName)
        super.tearDown()
    }

    private func makeRenderHistory(
        renderedAt date: Date? = nil,
        firstStartupRecorded: Bool = true
    ) -> InAppContentBlockRenderHistory {
        let history = InAppContentBlockRenderHistory(userDefaults: historyDefaults)
        if firstStartupRecorded {
            history.recordFirstStartup()
        }
        if let date {
            history.recordRender(at: date)
        }
        return history
    }

    // MARK: - Render history

    func testRenderHistoryIsEmptyWithoutRenderedContent() {
        XCTAssertFalse(makeRenderHistory().hasRendered(since: Date(timeIntervalSinceNow: -3600)))
    }

    func testRenderHistoryReportsContentRenderedAfterTheCutOff() {
        let history = makeRenderHistory(renderedAt: Date(timeIntervalSinceNow: -60))
        XCTAssertTrue(history.hasRendered(since: Date(timeIntervalSinceNow: -3600)))
    }

    func testRenderHistoryIgnoresContentRenderedBeforeTheCutOff() {
        let history = makeRenderHistory(renderedAt: Date(timeIntervalSinceNow: -7200))
        XCTAssertFalse(history.hasRendered(since: Date(timeIntervalSinceNow: -3600)))
    }

    func testRenderHistoryKeepsTheLatestRender() {
        let history = makeRenderHistory(renderedAt: Date(timeIntervalSinceNow: -7200))
        history.recordRender(at: Date(timeIntervalSinceNow: -60))
        XCTAssertTrue(history.hasRendered(since: Date(timeIntervalSinceNow: -3600)))
    }

    func testRenderHistoryClearForgetsRenders() {
        let history = makeRenderHistory(renderedAt: Date())
        history.clear()
        XCTAssertFalse(history.hasRendered(since: .distantPast))
    }

    func testRenderHistoryKeepsSpareWebViewRendersSeparately() {
        let history = makeRenderHistory()
        history.recordRender(at: Date(timeIntervalSinceNow: -60))
        XCTAssertFalse(history.hasRenderedWithSpareWebView(since: Date(timeIntervalSinceNow: -3600)))

        history.recordRender(at: Date(timeIntervalSinceNow: -60), usedSpareWebView: true)

        XCTAssertTrue(history.hasRenderedWithSpareWebView(since: Date(timeIntervalSinceNow: -3600)))
        XCTAssertTrue(history.hasRendered(since: Date(timeIntervalSinceNow: -3600)))
    }

    func testRenderHistoryRecordsNoRenderWhileIntegrationIsStopped() {
        let history = makeRenderHistory()
        IntegrationManager.shared.isStopped = true

        history.recordRender(at: Date(), usedSpareWebView: true)

        XCTAssertFalse(history.hasRendered(since: .distantPast))
        XCTAssertFalse(history.hasRenderedWithSpareWebView(since: .distantPast))
    }

    func testRenderHistoryRemembersTheFirstStartup() {
        let history = makeRenderHistory(firstStartupRecorded: false)
        XCTAssertFalse(history.hasRecordedFirstStartup)

        history.recordFirstStartup()

        XCTAssertTrue(InAppContentBlockRenderHistory(userDefaults: historyDefaults).hasRecordedFirstStartup)
    }

    func testRenderHistoryClearForgetsTheFirstStartup() {
        let history = makeRenderHistory()
        history.clear()
        XCTAssertFalse(history.hasRecordedFirstStartup)
    }

    // MARK: - Startup decision

    func testFirstStartupPrewarmsCalculatorAndSpareWebViews() {
        let manager = InAppContentBlocksManager()
        let history = makeRenderHistory(firstStartupRecorded: false)

        manager.prewarmForStartupIfContentRecentlyRendered(renderHistory: history)
        settleContentBlockWebViewWork()

        XCTAssertTrue(manager.hasPreparedOrWarmingStaticHeightCalculator)
        XCTAssertEqual(manager.preparedContentBlockWebViewCount, 2)
        XCTAssertTrue(history.hasRecordedFirstStartup)
    }

    func testOnlyTheFirstStartupPrewarmsWithoutRenderedContent() {
        let history = makeRenderHistory(firstStartupRecorded: false)
        InAppContentBlocksManager().prewarmForStartupIfContentRecentlyRendered(renderHistory: history)
        settleContentBlockWebViewWork()
        let nextLaunch = InAppContentBlocksManager()

        nextLaunch.prewarmForStartupIfContentRecentlyRendered(renderHistory: history)
        settleContentBlockWebViewWork()

        XCTAssertFalse(nextLaunch.hasPreparedOrWarmingStaticHeightCalculator)
        XCTAssertEqual(nextLaunch.preparedContentBlockWebViewCount, 0)
    }

    func testFirstStartupWithPrewarmDisabledCreatesNoWebViewAndKeepsTheFirstStartup() {
        let manager = InAppContentBlocksManager()
        manager.isPrewarmEnabled = false
        let history = makeRenderHistory(firstStartupRecorded: false)

        manager.prewarmForStartupIfContentRecentlyRendered(renderHistory: history)
        settleContentBlockWebViewWork()

        XCTAssertFalse(manager.hasPreparedOrWarmingStaticHeightCalculator)
        XCTAssertEqual(manager.preparedContentBlockWebViewCount, 0)
        XCTAssertFalse(history.hasRecordedFirstStartup)
    }

    func testFirstStartupWhileIntegrationIsStoppedCreatesNoWebViewAndKeepsTheFirstStartup() {
        let manager = InAppContentBlocksManager()
        IntegrationManager.shared.isStopped = true
        let history = makeRenderHistory(firstStartupRecorded: false)

        manager.prewarmForStartupIfContentRecentlyRendered(renderHistory: history)
        settleContentBlockWebViewWork()

        XCTAssertFalse(manager.hasPreparedOrWarmingStaticHeightCalculator)
        XCTAssertEqual(manager.preparedContentBlockWebViewCount, 0)
        XCTAssertFalse(history.hasRecordedFirstStartup)
    }

    func testStartupCreatesNoWebViewWithoutRecentlyRenderedContent() {
        let manager = InAppContentBlocksManager()

        manager.prewarmForStartupIfContentRecentlyRendered(renderHistory: makeRenderHistory())
        settleContentBlockWebViewWork()

        XCTAssertFalse(manager.hasPreparedOrWarmingStaticHeightCalculator)
        XCTAssertEqual(manager.preparedContentBlockWebViewCount, 0)
    }

    func testStartupPrewarmsOnlyTheHeightCalculatorWhenContentWasRecentlyRendered() {
        let manager = InAppContentBlocksManager()

        manager.prewarmForStartupIfContentRecentlyRendered(
            renderHistory: makeRenderHistory(renderedAt: Date(timeIntervalSinceNow: -60))
        )
        settleContentBlockWebViewWork()

        XCTAssertTrue(manager.hasPreparedOrWarmingStaticHeightCalculator)
        // Spare display web views serve only the table and collection API; they are created on first use.
        XCTAssertEqual(manager.preparedContentBlockWebViewCount, 0)
    }

    func testStartupCreatesNoWebViewWhenPrewarmIsDisabled() {
        let manager = InAppContentBlocksManager()
        manager.isPrewarmEnabled = false

        manager.prewarmForStartupIfContentRecentlyRendered(
            renderHistory: makeRenderHistory(renderedAt: Date(timeIntervalSinceNow: -60))
        )
        settleContentBlockWebViewWork()

        XCTAssertFalse(manager.hasPreparedOrWarmingStaticHeightCalculator)
        XCTAssertEqual(manager.preparedContentBlockWebViewCount, 0)
    }

    func testStartupPrewarmsSpareWebViewsWhenTheTableApiRenderedRecently() {
        let manager = InAppContentBlocksManager()
        let history = makeRenderHistory()
        history.recordRender(at: Date(timeIntervalSinceNow: -60), usedSpareWebView: true)

        manager.prewarmForStartupIfContentRecentlyRendered(renderHistory: history)
        settleContentBlockWebViewWork()

        XCTAssertTrue(manager.hasPreparedOrWarmingStaticHeightCalculator)
        XCTAssertEqual(manager.preparedContentBlockWebViewCount, 2)
    }

    func testStartupIgnoresSpareWebViewRendersOlderThanTheLookback() {
        let manager = InAppContentBlocksManager()
        let now = Date()
        let history = makeRenderHistory(renderedAt: now.addingTimeInterval(-60))
        history.recordRender(
            at: now.addingTimeInterval(-InAppContentBlocksManager.startupPrewarmLookback - 60),
            usedSpareWebView: true
        )

        manager.prewarmForStartupIfContentRecentlyRendered(renderHistory: history, now: now)
        settleContentBlockWebViewWork()

        XCTAssertTrue(manager.hasPreparedOrWarmingStaticHeightCalculator)
        XCTAssertEqual(manager.preparedContentBlockWebViewCount, 0)
    }

    func testStartupIgnoresRenderHistoryOlderThanTheLookback() {
        let manager = InAppContentBlocksManager()
        let now = Date()
        let tooOld = now.addingTimeInterval(-InAppContentBlocksManager.startupPrewarmLookback - 60)

        manager.prewarmForStartupIfContentRecentlyRendered(
            renderHistory: makeRenderHistory(renderedAt: tooOld),
            now: now
        )
        settleContentBlockWebViewWork()

        XCTAssertFalse(manager.hasPreparedOrWarmingStaticHeightCalculator)
    }

    func testStartupCreatesNoWebViewWhileIntegrationIsStopped() {
        let manager = InAppContentBlocksManager()
        let history = makeRenderHistory(renderedAt: Date(timeIntervalSinceNow: -60))
        IntegrationManager.shared.isStopped = true

        manager.prewarmForStartupIfContentRecentlyRendered(renderHistory: history)
        settleContentBlockWebViewWork()

        XCTAssertFalse(manager.hasPreparedOrWarmingStaticHeightCalculator)
    }

    // MARK: - Recording renders

    private func cacheContent(placeholder: String) {
        var personalized = PersonalizedInAppContentBlockResponse.getSample(status: .ok, ttlSeen: Date())
        var payload = NormalizedResult()
        payload.html = "<html><body>cached</body></html>"
        personalized.htmlPayload = payload
        InAppContentBlocksManager.manager.inAppContentBlockMessages = [
            SampleInAppContentBlocks.getSampleIninAppContentBlocks(
                dateFilter: .init(enabled: false, fromDate: nil, toDate: nil),
                placeholders: [placeholder],
                personalized: personalized
            )
        ]
    }

    func testStaticViewRecordsARenderWhenItRendersContent() {
        cacheContent(placeholder: "ph_render")

        _ = StaticInAppContentBlockView(placeholder: "ph_render")

        XCTAssertTrue(InAppContentBlockRenderHistory.shared.hasRendered(since: Date(timeIntervalSinceNow: -60)))
    }

    func testStaticViewRendersContentWhenPrewarmIsDisabled() {
        let manager = InAppContentBlocksManager.manager
        let wasEnabled = manager.isPrewarmEnabled
        manager.isPrewarmEnabled = false
        defer { manager.isPrewarmEnabled = wasEnabled }
        cacheContent(placeholder: "ph_prewarm_off")

        let view = StaticInAppContentBlockView(placeholder: "ph_prewarm_off")

        XCTAssertTrue(view.hasCreatedWebViews)
        XCTAssertTrue(InAppContentBlockRenderHistory.shared.hasRendered(since: Date(timeIntervalSinceNow: -60)))
    }

    func testStaticViewRecordsNoSpareWebViewRender() {
        cacheContent(placeholder: "ph_static_only")

        _ = StaticInAppContentBlockView(placeholder: "ph_static_only")

        XCTAssertTrue(InAppContentBlockRenderHistory.shared.hasRendered(since: .distantPast))
        XCTAssertFalse(InAppContentBlockRenderHistory.shared.hasRenderedWithSpareWebView(since: .distantPast))
    }

    func testStaticViewWithNativeRenderingRecordsNoRender() {
        cacheContent(placeholder: "ph_native")

        let view = StaticInAppContentBlockView(placeholder: "ph_native", deferredLoad: true)
        view.skipNativeRendering = true
        view.load()
        settleContentBlockWebViewWork()

        XCTAssertFalse(InAppContentBlockRenderHistory.shared.hasRendered(since: .distantPast))
        XCTAssertFalse(view.hasCreatedWebViews)
    }

    // MARK: - Configure

    private func configureSDK(prewarmInAppContentBlocks: Bool? = nil) {
        Exponea.shared = ExponeaInternal()
        let configuration = try! Configuration(
            projectToken: "token",
            authorization: Authorization.none,
            baseUrl: "baseUrl",
            prewarmInAppContentBlocks: prewarmInAppContentBlocks
        )
        Exponea.shared.configure(with: configuration)
        settleContentBlockWebViewWork()
    }

    private func resetSharedManagerPools() {
        InAppContentBlocksManager.manager.clearPreparedContentBlockWebViewsForTest()
        InAppContentBlocksManager.manager.clearPreparedStaticHeightCalculatorsForTest()
    }

    // MARK: - Clearing local data

    /// Leaves a configured, running SDK for later specs, like the other specs in this file expect.
    private func restoreConfiguredSDK() {
        IntegrationManager.shared.isStopped = false
        configureSDK()
        InAppContentBlockRenderHistory.shared.resetToSteadyStateForTest()
    }

    private func recordRenderHistory() {
        let history = InAppContentBlockRenderHistory.shared
        history.recordFirstStartup()
        history.recordRender(at: Date(), usedSpareWebView: true)
        XCTAssertTrue(history.hasRenderedWithSpareWebView(since: .distantPast))
    }

    private func assertRenderHistoryCleared(file: StaticString = #filePath, line: UInt = #line) {
        let history = InAppContentBlockRenderHistory.shared
        XCTAssertFalse(history.hasRendered(since: .distantPast), file: file, line: line)
        XCTAssertFalse(history.hasRenderedWithSpareWebView(since: .distantPast), file: file, line: line)
        XCTAssertFalse(history.hasRecordedFirstStartup, file: file, line: line)
    }

    func testStopIntegrationClearsRenderHistoryWithAppGroup() {
        let appGroup = "group.test.exponea.render-history.stop"
        defer {
            restoreConfiguredSDK()
            // Teardown persists isStopped into the app group suite; leave nothing behind.
            UserDefaults(suiteName: appGroup)?.removePersistentDomain(forName: appGroup)
        }
        Exponea.shared = ExponeaInternal()
        Exponea.shared.configure(
            Exponea.ProjectSettings(projectToken: "token", authorization: .token("test")),
            pushNotificationTracking: .enabled(appGroup: appGroup),
            flushingSetup: Exponea.FlushingSetup(mode: .manual)
        )
        settleContentBlockWebViewWork()
        recordRenderHistory()

        let stopped = expectation(description: "integration stopped")
        Exponea.shared.stopIntegration { stopped.fulfill() }
        wait(for: [stopped], timeout: 5)

        assertRenderHistoryCleared()
    }

    func testClearLocalCustomerDataClearsRenderHistoryWithAppGroup() {
        let appGroup = "group.test.exponea.render-history.clear"
        defer {
            restoreConfiguredSDK()
            UserDefaults(suiteName: appGroup)?.removePersistentDomain(forName: appGroup)
        }
        Exponea.shared = ExponeaInternal()
        let configuration = try! Configuration(
            projectToken: "token",
            authorization: .none,
            baseUrl: Constants.Repository.baseUrl,
            appGroup: appGroup
        )
        configuration.saveToUserDefaults()
        recordRenderHistory()

        Exponea.shared.clearLocalCustomerData(appGroup: appGroup)

        assertRenderHistoryCleared()
    }

    func testConfigurePrewarmsCalculatorAndSpareWebViewsOnFirstStartup() {
        resetSharedManagerPools()

        configureSDK()

        XCTAssertTrue(InAppContentBlocksManager.manager.hasPreparedOrWarmingStaticHeightCalculator)
        XCTAssertEqual(InAppContentBlocksManager.manager.preparedContentBlockWebViewCount, 2)
    }

    func testConfigureCreatesNoWebViewWhenNoContentWasRendered() {
        resetSharedManagerPools()
        InAppContentBlockRenderHistory.shared.recordFirstStartup()

        configureSDK()

        XCTAssertFalse(InAppContentBlocksManager.manager.hasPreparedOrWarmingStaticHeightCalculator)
        XCTAssertEqual(InAppContentBlocksManager.manager.preparedContentBlockWebViewCount, 0)
    }

    func testConfigureCreatesNoWebViewWhenPrewarmIsDisabled() {
        resetSharedManagerPools()
        InAppContentBlockRenderHistory.shared.recordRender(at: Date())

        configureSDK(prewarmInAppContentBlocks: false)
        defer { InAppContentBlocksManager.manager.isPrewarmEnabled = true }

        XCTAssertFalse(InAppContentBlocksManager.manager.isPrewarmEnabled)
        XCTAssertFalse(InAppContentBlocksManager.manager.hasPreparedOrWarmingStaticHeightCalculator)
        XCTAssertEqual(InAppContentBlocksManager.manager.preparedContentBlockWebViewCount, 0)
    }

    func testConfigurePrewarmsWhenContentWasRecentlyRendered() {
        resetSharedManagerPools()
        InAppContentBlockRenderHistory.shared.recordFirstStartup()
        InAppContentBlockRenderHistory.shared.recordRender(at: Date())

        configureSDK()

        XCTAssertTrue(InAppContentBlocksManager.manager.hasPreparedOrWarmingStaticHeightCalculator)
        XCTAssertEqual(InAppContentBlocksManager.manager.preparedContentBlockWebViewCount, 0)
    }
}

extension InAppContentBlockRenderHistory {
    /// Leaves the shared history as after any earlier configure: first startup handled, no renders.
    /// Specs that clear it call this afterwards, so later specs don't run the first-startup prewarm.
    func resetToSteadyStateForTest() {
        clear()
        recordFirstStartup()
    }
}

extension XCTestCase {
    /// Waits until content block web view work that is already queued has run: the startup
    /// prewarm (after the content rule list compiles) and any deferred pool refills.
    func settleContentBlockWebViewWork() {
        let compiled = expectation(description: "content rule list compiled")
        InAppContentBlocksManager.manager.initBlocker { compiled.fulfill() }
        wait(for: [compiled], timeout: 10)
        for _ in 0..<3 {
            let drained = expectation(description: "main queue drained")
            DispatchQueue.main.async { drained.fulfill() }
            wait(for: [drained], timeout: 2)
        }
    }
}

class SimpleBehaviourCallback: InAppContentBlockCallbackType {

    func onActionClickedSafari(placeholderId: String, contentBlock: ExponeaSDK.InAppContentBlockResponse, action: ExponeaSDK.InAppContentBlockAction) {
        
    }

    private var onMessageShownAction: ((String, ExponeaSDK.InAppContentBlockResponse) -> Void)?
    private var onNoMessageFoundAction: ((String) -> Void)?
    private var onErrorAction: ((String, ExponeaSDK.InAppContentBlockResponse?, String) -> Void)?
    private var onCloseClickedAction: ((String, ExponeaSDK.InAppContentBlockResponse) -> Void)?
    private var onActionClickedAction: ((String, ExponeaSDK.InAppContentBlockResponse, ExponeaSDK.InAppContentBlockAction) -> Void)?
    init(
        onMessageShownAction: ((String, ExponeaSDK.InAppContentBlockResponse) -> Void)? = nil,
        onNoMessageFoundAction: ((String) -> Void)? = nil,
        onErrorAction: ((String, ExponeaSDK.InAppContentBlockResponse?, String) -> Void)? = nil,
        onCloseClickedAction: ((String, ExponeaSDK.InAppContentBlockResponse) -> Void)? = nil,
        onActionClickedAction: ((String, ExponeaSDK.InAppContentBlockResponse, ExponeaSDK.InAppContentBlockAction) -> Void)? = nil
    ) {
        self.onMessageShownAction = onMessageShownAction
        self.onNoMessageFoundAction = onNoMessageFoundAction
        self.onErrorAction = onErrorAction
        self.onCloseClickedAction = onCloseClickedAction
        self.onActionClickedAction = onActionClickedAction
    }
    func onMessageShown(placeholderId: String, contentBlock: ExponeaSDK.InAppContentBlockResponse) {
        onMessageShownAction?(placeholderId, contentBlock)
    }
    func onNoMessageFound(placeholderId: String) {
        onNoMessageFoundAction?(placeholderId)
    }
    func onError(placeholderId: String, contentBlock: ExponeaSDK.InAppContentBlockResponse?, errorMessage: String) {
        onErrorAction?(placeholderId, contentBlock, errorMessage)
    }
    func onCloseClicked(placeholderId: String, contentBlock: ExponeaSDK.InAppContentBlockResponse) {
        onCloseClickedAction?(placeholderId, contentBlock)
    }
    
    func onActionClicked(placeholderId: String, contentBlock: ExponeaSDK.InAppContentBlockResponse, action: ExponeaSDK.InAppContentBlockAction) {
        onActionClickedAction?(placeholderId, contentBlock, action)
    }
}

final class SimpleNavigationAction: WKNavigationAction {
    let urlRequest: URLRequest
    var receivedPolicy: WKNavigationActionPolicy?
    override var request: URLRequest { urlRequest }
    init(
        urlRequest: URLRequest
    ) {
        self.urlRequest = urlRequest
        super.init()
    }
    convenience init(url: URL) {
        self.init(urlRequest: URLRequest(url: url))
    }
    func decisionHandler(_ policy: WKNavigationActionPolicy) { self.receivedPolicy = policy }
}

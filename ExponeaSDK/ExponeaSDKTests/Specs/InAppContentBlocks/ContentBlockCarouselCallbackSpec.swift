//
//  ContentBlockCarouselCallbackSpec.swift
//  ExponeaSDKTests
//
//  Copyright © 2026 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble
@testable import ExponeaSDK

private final class MutableCarouselCallbackSpy: DefaultContentBlockCarouselCallback {
    var overrideDefaultBehavior = false
    var trackActions = false
    private(set) var onActionClickedSafariCallCount = 0

    func onMessageShown(placeholderId: String, contentBlock: InAppContentBlockResponse, index: Int, count: Int) {}

    func onMessagesChanged(count: Int, messages: [InAppContentBlockResponse]) {}

    func onNoMessageFound(placeholderId: String) {}

    func onError(placeholderId: String, contentBlock: InAppContentBlockResponse?, errorMessage: String) {}

    func onCloseClicked(placeholderId: String, contentBlock: InAppContentBlockResponse) {}

    func onActionClickedSafari(
        placeholderId: String,
        contentBlock: InAppContentBlockResponse,
        action: InAppContentBlockAction
    ) {
        onActionClickedSafariCallCount += 1
    }

    func onHeightUpdate(placeholderId: String, height: CGFloat) {}
}

class ContentBlockCarouselCallbackSpec: QuickSpec {
    override func spec() {
        var logger: MockLogger!

        beforeEach {
            logger = MockLogger()
            logger.logLevel = .verbose
            Exponea.logger = logger
        }

        describe("overrideDefaultBehavior") {
            it("reads the live behaviour callback value after carousel init") {
                let spy = MutableCarouselCallbackSpy()
                spy.overrideDefaultBehavior = false
                let wrapper = ContentBlockCarouselCallback(behaviourCallback: spy)
                spy.overrideDefaultBehavior = true

                let action = InAppContentBlockAction(
                    name: "track",
                    url: "exponea://track",
                    type: .deeplink
                )
                let contentBlock = SampleInAppContentBlocks.getSampleIninAppContentBlocks()

                wrapper.onActionClickedSafari(
                    placeholderId: "example_carousel",
                    contentBlock: contentBlock,
                    action: action
                )

                expect(spy.onActionClickedSafariCallCount).to(equal(1))
                expect(logger.messages.contains { $0.contains("Invoking Carousel Content Block") }).to(beFalse())
            }

            it("opens default deeplink handling when override remains false") {
                let spy = MutableCarouselCallbackSpy()
                spy.overrideDefaultBehavior = false
                let wrapper = ContentBlockCarouselCallback(behaviourCallback: spy)

                let action = InAppContentBlockAction(
                    name: "track",
                    url: "exponea://track",
                    type: .deeplink
                )
                let contentBlock = SampleInAppContentBlocks.getSampleIninAppContentBlocks()

                wrapper.onActionClickedSafari(
                    placeholderId: "example_carousel",
                    contentBlock: contentBlock,
                    action: action
                )

                expect(spy.onActionClickedSafariCallCount).to(equal(1))
                expect(logger.messages.contains { $0.contains("Invoking Carousel Content Block") }).to(beTrue())
            }
        }
    }
}

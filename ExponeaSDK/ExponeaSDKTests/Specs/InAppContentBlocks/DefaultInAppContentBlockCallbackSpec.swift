//
//  DefaultInAppContentBlockCallbackSpec.swift
//  ExponeaSDKTests
//
//  Copyright © 2026 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble
@testable import ExponeaSDK

final class DefaultInAppContentBlockCallbackSpec: QuickSpec {
    override func spec() {
        var previousShared: ExponeaInternal!

        beforeEach {
            // The callback tracks the click; point it at a throwaway, unconfigured SDK instance so the
            // tracking call is only queued and nothing is written into, or flushed from, the instance
            // other specs use. No configure, so the throwaway starts no background work either
            previousShared = Exponea.shared
            Exponea.shared = ExponeaInternal()
        }

        afterEach {
            // Later specs read the shared instance (e.g. its user defaults), so hand it back unchanged
            Exponea.shared = previousShared
        }

        describe("browser action") {
            it("presents Safari on main thread when called from background") {
                var presentedOnMainThread: Bool?
                var presentedUrl: URL?
                waitUntil(timeout: .seconds(5)) { done in
                    let callback = DefaultInAppContentBlockCallback(safariPresenter: { url in
                        presentedOnMainThread = Thread.isMainThread
                        presentedUrl = url
                        done()
                    })
                    DispatchQueue.global(qos: .userInitiated).async {
                        callback.onActionClickedSafari(
                            placeholderId: "placeholder",
                            contentBlock: SampleInAppContentBlocks.getSampleIninAppContentBlocks(),
                            action: InAppContentBlockAction(name: "open", url: "https://example.com/page", type: .browser)
                        )
                    }
                }

                expect(presentedOnMainThread).to(beTrue())
                expect(presentedUrl?.absoluteString).to(equal("https://example.com/page"))
            }

            it("presents Safari synchronously when already on main thread") {
                var presentedUrl: URL?
                let callback = DefaultInAppContentBlockCallback(safariPresenter: { presentedUrl = $0 })

                callback.onActionClickedSafari(
                    placeholderId: "placeholder",
                    contentBlock: SampleInAppContentBlocks.getSampleIninAppContentBlocks(),
                    action: InAppContentBlockAction(name: "open", url: "https://example.com/page", type: .browser)
                )

                expect(presentedUrl?.absoluteString).to(equal("https://example.com/page"))
            }
        }
    }
}

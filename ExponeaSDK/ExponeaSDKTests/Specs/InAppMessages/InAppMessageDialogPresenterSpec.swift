//
//  InAppMessageDialogPresenterSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 05/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Nimble
import Quick

@testable import ExponeaSDK

final class InAppMessageDialogPresenterSpec: QuickSpec {
    override func spec() {
        let bundle = Bundle(for: InAppMessageDialogPresenterSpec.self)

        // image data is 225x225
        let lenaImageData: Data! = try? Data(
            contentsOf: URL(fileURLWithPath: bundle.path(forResource: "lena", ofType: "jpeg")!)
        )

        // image data is 640x480
        let mountainImageData: Data! = try? Data(
            contentsOf: URL(fileURLWithPath: bundle.path(forResource: "mountain", ofType: "png")!)
        )

        describe("creating images from data") {
            func verifyImageDimensions(image: UIImage?, width: CGFloat, height: CGFloat) {
                expect(image).notTo(beNil())
                expect(image?.size.width).to(equal(width))
                expect(image?.size.height).to(equal(height))
            }

            it("should return nil with corrupted data") {
                let image = InAppMessageDialogPresenter().createImage(
                    imageData: "something".data(using: .utf8)!,
                    maxDimensionInPixels: 1000
                )
                expect(image).to(beNil())
            }

            it("should create image") {
                let lenaImage = InAppMessageDialogPresenter().createImage(
                    imageData: lenaImageData,
                    maxDimensionInPixels: 1000
                )
                verifyImageDimensions(image: lenaImage, width: 225, height: 225)

                let mountianImage = InAppMessageDialogPresenter().createImage(
                    imageData: mountainImageData,
                    maxDimensionInPixels: 1000
                )
                verifyImageDimensions(image: mountianImage, width: 640, height: 480)
            }

            it("should downsample image") {
                let lenaImage = InAppMessageDialogPresenter().createImage(
                    imageData: lenaImageData,
                    maxDimensionInPixels: 100
                )
                verifyImageDimensions(image: lenaImage, width: 100, height: 100)

                let mountianImage = InAppMessageDialogPresenter().createImage(
                    imageData: mountainImageData,
                    maxDimensionInPixels: 100
                )
                verifyImageDimensions(image: mountianImage, width: 100, height: 75)
            }
        }

        describe("getting top view controller") {
            it("should return nil without window") {
                expect(InAppMessageDialogPresenter().getTopViewController()).to(beNil())
            }

            it("should return root view controller") {
                let window = UIWindow()
                window.rootViewController = UIViewController()
                expect(InAppMessageDialogPresenter(window: window).getTopViewController())
                    .to(equal(window.rootViewController))
            }
        }

        describe("presenting in-app message dialog") {
            let payload = SampleInAppMessage.getSampleInAppMessage().payload

            it("should present dialog with existing UI") {
                let window = UIWindow()
                window.rootViewController = UIViewController()
                waitUntil { done in
                    InAppMessageDialogPresenter(window: window).presentInAppMessage(
                        payload: payload,
                        imageData: lenaImageData,
                        actionCallback: {},
                        dismissCallback: {},
                        presentedCallback: { presented in
                            expect(presented).notTo(beNil())
                            done()
                    })
                }
            }

            it("should not present dialog without existing UI") {
                waitUntil { done in
                    InAppMessageDialogPresenter().presentInAppMessage(
                        payload: payload,
                        imageData: lenaImageData,
                        actionCallback: {},
                        dismissCallback: {},
                        presentedCallback: { presented in
                            expect(presented).to(beNil())
                            done()
                    })
                }
            }

            it("should not present dialog without valid image data") {
                let window = UIWindow()
                window.rootViewController = UIViewController()
                waitUntil { done in
                    InAppMessageDialogPresenter().presentInAppMessage(
                        payload: payload,
                        imageData: "something".data(using: .utf8)!,
                        actionCallback: {},
                        dismissCallback: {},
                        presentedCallback: { presented in
                            expect(presented).to(beNil())
                            done()
                    })
                }
            }

            it("should not present dialog while presenting another") {
                let window = UIWindow()
                window.rootViewController = UIViewController()
                let presenter = InAppMessageDialogPresenter(window: window)
                let present = { callback in
                    presenter.presentInAppMessage(
                        payload: payload,
                        imageData: lenaImageData,
                        actionCallback: {},
                        dismissCallback: {},
                        presentedCallback: callback)
                }
                var presentedDialog: InAppMessageDialogViewController?
                waitUntil { done in
                    present({ presented in
                        expect(presented).notTo(beNil())
                        presentedDialog = presented
                        done()
                    })
                }
                waitUntil { done in
                    present({ presented in
                        expect(presented).to(beNil())
                        done()
                    })
                }
                presentedDialog?.dismissCallback?()
                waitUntil { done in
                    present({ presented in
                        expect(presented).notTo(beNil())
                        presentedDialog = presented
                        done()
                    })
                }
                waitUntil { done in
                    present({ presented in
                        expect(presented).to(beNil())
                        done()
                    })
                }
                presentedDialog?.actionCallback?()
                waitUntil { done in
                    present({ presented in
                        expect(presented).notTo(beNil())
                        done()
                    })
                }
            }

        }
    }
}

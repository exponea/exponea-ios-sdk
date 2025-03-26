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

final class InAppMessagePresenterSpec: QuickSpec {
    override func spec() {
        let bundle = Bundle(for: InAppMessagePresenterSpec.self)

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
                let image = InAppMessagePresenter().createImage(
                    imageData: "something".data(using: .utf8)!,
                    maxDimensionInPixels: 1000
                )
                expect(image).to(beNil())
            }

            it("should create image") {
                let lenaImage = InAppMessagePresenter().createImage(
                    imageData: lenaImageData,
                    maxDimensionInPixels: 1000
                )
                verifyImageDimensions(image: lenaImage, width: 225, height: 225)

                let mountianImage = InAppMessagePresenter().createImage(
                    imageData: mountainImageData,
                    maxDimensionInPixels: 1000
                )
                verifyImageDimensions(image: mountianImage, width: 640, height: 480)
            }

            it("should downsample image") {
                let lenaImage = InAppMessagePresenter().createImage(
                    imageData: lenaImageData,
                    maxDimensionInPixels: 100
                )
                verifyImageDimensions(image: lenaImage, width: 100, height: 100)

                let mountianImage = InAppMessagePresenter().createImage(
                    imageData: mountainImageData,
                    maxDimensionInPixels: 100
                )
                verifyImageDimensions(image: mountianImage, width: 100, height: 75)
            }
        }

        describe("getting top view controller") {
            it("should return nil without window") {
                expect(InAppMessagePresenter.getTopViewController(window: nil)).to(beNil())
            }

            it("should return root view controller") {
                let window = UIWindow()
                window.rootViewController = UIViewController()
                expect(InAppMessagePresenter.getTopViewController(window: window))
                    .to(equal(window.rootViewController))
            }
        }

        describe("presenting in-app message view") {
            let message = SampleInAppMessage.getSampleInAppMessage()
            // TODO: here
            InAppMessageType.allCases.forEach { messageType in
                it("should present dialog with existing UI") {
                    let window = UIWindow()
                    window.rootViewController = UIViewController()
                    waitUntil(timeout: .seconds(5)) { done in
                        let presenter = InAppMessagePresenter(window: window)
                        let view = try? presenter.createInAppMessageView(
                            messageType: .modal,
                            payload: nil,
                            oldPayload: .init(imageUrl: "", title: "", titleTextColor: "", titleTextSize: "", bodyText: "", bodyTextColor: "", bodyTextSize: "", buttons: [], backgroundColor: "", closeButtonColor: "", messagePosition: "", textPosition: "", textOverImage: false),
                            payloadHtml: nil,
                            image: UIImage(),
                            timeout: nil
                        ) { _ in }
                        dismissCallback: { isUserInteraction, _ in
                            expect(isUserInteraction).to(beTrue())
                        }
                        if let inAppMessageDialogView = view as? InAppMessageDialogView {
                            inAppMessageDialogView.closeButtonAction(InAppMessageActionButton())
                        }
                        presenter.presentInAppMessage(
                            messageType: messageType,
                            payload: nil,
                            oldPayload: message.oldPayload,
                            payloadHtml: message.payloadHtml,
                            delay: 0,
                            timeout: nil,
                            imageData: lenaImageData,
                            actionCallback: { _ in },
                            dismissCallback: { _, _ in },
                            presentedCallback: { presented, error in
                                expect(presented).notTo(beNil())
                                done()
                        })
                    }
                }

                it("should not present dialog without existing UI") {
                    waitUntil(timeout: .seconds(5)) { done in
                        let presenter = InAppMessagePresenter()
                        presenter.presentInAppMessage(
                            messageType: messageType,
                            payload: nil,
                            oldPayload: message.oldPayload,
                            payloadHtml: message.payloadHtml,
                            delay: 0,
                            timeout: nil,
                            imageData: lenaImageData,
                            actionCallback: { _ in },
                            dismissCallback: { _, _ in },
                            presentedCallback: { presented, error in
                                expect(presented).to(beNil())
                                done()
                        })
                    }
                }

                it("should not present dialog without valid image data") {
                    let window = UIWindow()
                    window.rootViewController = UIViewController()
                    waitUntil(timeout: .seconds(5)) { done in
                        InAppMessagePresenter().presentInAppMessage(
                            messageType: messageType,
                            payload: nil,
                            oldPayload: message.oldPayload,
                            payloadHtml: message.payloadHtml,
                            delay: 0,
                            timeout: nil,
                            imageData: "something".data(using: .utf8)!,
                            actionCallback: { _ in },
                            dismissCallback: { _, _ in },
                            presentedCallback: { presented, error in
                                expect(presented).to(beNil())
                                done()
                        })
                    }
                }

                it("should not present dialog while presenting another") {
                    let window = UIWindow()
                    window.rootViewController = UIViewController()
                    let presenter = InAppMessagePresenter(window: window)
                    let present = { callback in
                        presenter.presentInAppMessage(
                            messageType: messageType,
                            payload: nil,
                            oldPayload: message.oldPayload,
                            payloadHtml: message.payloadHtml,
                            delay: 0,
                            timeout: nil,
                            imageData: lenaImageData,
                            actionCallback: { _ in },
                            dismissCallback: { _, _ in },
                            presentedCallback: callback)
                    }
                    var presentedDialog: InAppMessageView?
                    waitUntil(timeout: .seconds(5)) { done in
                        present({ presented, error in
                            expect(presented).notTo(beNil())
                            presentedDialog = presented
                            done()
                        })
                    }
                    waitUntil(timeout: .seconds(5)) { done in
                        present({ presented, error in
                            expect(presented).to(beNil())
                            done()
                        })
                    }
                    presentedDialog?.dismissCallback((false, nil))
                    waitUntil(timeout: .seconds(5)) { done in
                        present({ presented, error in
                            expect(presented).notTo(beNil())
                            presentedDialog = presented
                            done()
                        })
                    }
                    waitUntil(timeout: .seconds(5)) { done in
                        present({ presented, error in
                            expect(presented).to(beNil())
                            done()
                        })
                    }
                    presentedDialog?.actionCallback(message.oldPayload!.buttons![0])
                    waitUntil(timeout: .seconds(5)) { done in
                        present({ presented, error in
                            expect(presented).notTo(beNil())
                            done()
                        })
                    }
                }

                it("should dismiss dialog after timeout - \(messageType.rawValue)") {
                    let message: InAppMessage
                    switch messageType {
                    case .modal, .alert, .fullscreen, .slideIn:
                        message = SampleInAppMessage.getSampleInAppMessage(
                            messageType: messageType.rawValue,
                            isHtml: false,
                            htmlPayload: nil
                        )
                    case .freeform:
                        message = SampleInAppMessage.getSampleInAppMessage(
                            payload: nil,
                            variantName: "Variant A",
                            variantId: 0,
                            isHtml: true,
                            htmlPayload: "<html></html>"
                        )
                    }
                    let window = UIWindow(frame: UIScreen.main.bounds)
                    window.makeKeyAndVisible()
                    let rootView = UIViewController()
                    window.rootViewController = rootView
                    _ = rootView.view
                    let presenter = InAppMessagePresenter(window: window)
                    var presentedView: InAppMessageView?
                    var presentationError: String?
                    waitUntil(timeout: .seconds(4)) { done in
                        presenter.presentInAppMessage(
                            messageType: messageType,
                            payload: nil,
                            oldPayload: message.oldPayload,
                            payloadHtml: message.payloadHtml,
                            delay: 0,
                            timeout: 3.0,
                            imageData: lenaImageData,
                            actionCallback: { _ in },
                            dismissCallback: { isUserInteraction, button in
                                expect(isUserInteraction).to(equal(false))
                                expect(button).to(beNil())
                                done()
                            },
                            presentedCallback: { presented, error in
                                presentedView = presented
                                presentationError = error
                            }
                        )
                    }
                    expect(presentedView).notTo(beNil())
                    expect(presentationError).to(beNil())
                }
            }
        }
    }
}

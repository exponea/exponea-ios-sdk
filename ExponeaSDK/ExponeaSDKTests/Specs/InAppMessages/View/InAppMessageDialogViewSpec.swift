//
//  InAppMessageDialogViewSpec.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 05/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Nimble
import Quick

@testable import ExponeaSDK
@testable import ExponeaSDKShared

final class InAppMessageDialogViewSpec: QuickSpec {
    override func spec() {
        let payload = SampleInAppMessage.getSampleInAppMessage().oldPayload
        var image: UIImage!

        beforeEach {
            IntegrationManager.shared.isStopped = false
            let bundle = Bundle(for: InAppMessageDialogViewSpec.self)
            image = UIImage(contentsOfFile: bundle.path(forResource: "lena", ofType: "jpeg")!)
        }

        let fullscreenSettings = [true, false]
        for fullscreen in fullscreenSettings {
            it("should setup \(fullscreen ? "fullscreen" : "modal") dialog with payload") {
                let dialog: InAppMessageDialogView = InAppMessageDialogView(
                    payload: payload!,
                    image: image,
                    actionCallback: { _ in },
                    dismissCallback: { _, _ in },
                    fullscreen: fullscreen
                )
                dialog.beginAppearanceTransition(true, animated: false)
                expect(dialog.bodyTextView.text).to(equal(payload?.bodyText))
                expect(dialog.titleTextView.text).to(equal(payload?.title))
            }
        }

        describe("legacy animated GIF image routing") {
            let gifData = GifImageDecodingSpec.makeTwoFrameGifData()
            let jpegData = GifImageDecodingSpec.makeMinimalJpegData()

            it("loads multi-frame GIF data through UIAnimatedImageView") {
                let placeholder = UIImage(data: gifData)!
                let dialog = InAppMessageDialogView(
                    payload: payload!,
                    image: placeholder,
                    actionCallback: { _ in },
                    dismissCallback: { _, _ in },
                    fullscreen: false,
                    imageData: gifData
                )
                dialog.loadViewIfNeeded()
                expect(gifData.isInAppAnimatedImage).to(beTrue())
                expect(dialog.imageView).to(beAKindOf(UIAnimatedImageView.self))
                expect(dialog.imageView.image).toEventuallyNot(beNil(), timeout: .seconds(3))
            }

            it("loads static JPEG data through UIImage assignment") {
                let staticImage = UIImage(data: jpegData)!
                let dialog = InAppMessageDialogView(
                    payload: payload!,
                    image: staticImage,
                    actionCallback: { _ in },
                    dismissCallback: { _, _ in },
                    fullscreen: false,
                    imageData: jpegData
                )
                dialog.loadViewIfNeeded()
                expect(jpegData.isInAppAnimatedImage).to(beFalse())
                expect(dialog.imageView.image).toNot(beNil())
            }

            it("clears animated image state on dismiss") {
                let placeholder = UIImage(data: gifData)!
                let dialog = InAppMessageDialogView(
                    payload: payload!,
                    image: placeholder,
                    actionCallback: { _ in },
                    dismissCallback: { _, _ in },
                    fullscreen: false,
                    imageData: gifData
                )
                dialog.loadViewIfNeeded()
                expect(dialog.imageView.image).toEventuallyNot(beNil(), timeout: .seconds(3))
                dialog.dismissFromSuperView()
                expect(dialog.imageView.image).to(beNil())
            }

            it("uses fallback image height when dimensions cannot be resolved") {
                let dialog = InAppMessageDialogView(
                    payload: payload!,
                    image: UIImage(),
                    actionCallback: { _ in },
                    dismissCallback: { _, _ in },
                    fullscreen: false,
                    imageData: nil
                )
                dialog.loadViewIfNeeded()
                dialog.view.frame = CGRect(x: 0, y: 0, width: 320, height: 480)
                dialog.view.setNeedsLayout()
                dialog.view.layoutIfNeeded()
                expect(dialog.imageViewHeightConstraint?.constant).to(equal(150))
            }
        }

        describe("OldInAppMessageSlideInView animated GIF routing") {
            let gifData = GifImageDecodingSpec.makeTwoFrameGifData()

            it("loads multi-frame GIF data through UIAnimatedImageView") {
                let placeholder = UIImage(data: gifData)!
                let slideIn = OldInAppMessageSlideInView(
                    payload: payload!,
                    image: placeholder,
                    actionCallback: { _ in },
                    dismissCallback: { _, _ in },
                    imageData: gifData
                )
                let animatedImageView = Mirror(reflecting: slideIn).children
                    .first { $0.label == "imageView" }?
                    .value as? UIAnimatedImageView
                expect(animatedImageView).toNot(beNil())
                expect(animatedImageView?.image).toEventuallyNot(beNil(), timeout: .seconds(3))
            }
        }
    }
}

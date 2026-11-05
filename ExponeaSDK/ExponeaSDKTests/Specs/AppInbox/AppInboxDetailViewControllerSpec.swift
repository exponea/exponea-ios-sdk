//
//  AppInboxDetailViewControllerSpec.swift
//  ExponeaSDKTests
//
//  Copyright © 2026 Exponea. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Mockingjay
import UIKit

@testable import ExponeaSDK

class AppInboxDetailViewControllerSpec: QuickSpec {

    /// - Parameter gate: when set, the download doesn't finish until the gate is signaled
    static func stubImage(_ imageUrl: String, data: Data?, gate: DispatchSemaphore? = nil) {
        MockingjayProtocol.addStub(
            matcher: { $0.url?.absoluteString == imageUrl },
            builder: { _ in
                _ = gate?.wait(timeout: .now() + 5)
                guard let data else {
                    return .failure(NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet))
                }
                let response = HTTPURLResponse(
                    url: URL(string: imageUrl)!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return .success(response, .content(data))
            }
        )
    }

    static func makePushMessage(imageUrl: String) -> MessageItem {
        AppInboxCacheSpec.getSampleMessage(id: "id1", type: "push", data: ["image": .string(imageUrl)])
    }

    static func makePngData(width: Int, height: Int) -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
        return renderer.pngData { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }

    override func spec() {
        var window: UIWindow!
        var viewController: AppInboxDetailViewController!
        var downloadGate: DispatchSemaphore?

        func host(width: CGFloat) {
            window.frame = CGRect(x: 0, y: 0, width: width, height: 844)
            window.layoutIfNeeded()
            viewController.view.layoutIfNeeded()
        }

        func showImage(_ imageData: Data) {
            viewController.animatedMessageImage.loadImage(imageData: imageData)
            viewController.view.layoutIfNeeded()
        }

        func makeDownloadGate() -> DispatchSemaphore {
            let gate = DispatchSemaphore(value: 0)
            downloadGate = gate
            return gate
        }

        func waitUntilOffScreen(_ target: @escaping () -> UIViewController?) {
            expect { target()?.viewIfLoaded?.window == nil }.toEventually(beTrue())
        }

        func waitUntilOnScreen(_ target: @escaping () -> UIViewController?) {
            expect { target()?.viewIfLoaded?.window != nil }.toEventually(beTrue())
        }

        func waitUntilImageLoadHandled() {
            expect(viewController.isLoadingMessageImage).toEventually(beFalse(), timeout: .seconds(5))
        }

        func embedInNavigation() -> UINavigationController {
            window.rootViewController = nil
            let navigationController = UINavigationController(rootViewController: viewController)
            window.rootViewController = navigationController
            window.layoutIfNeeded()
            return navigationController
        }

        func makeCustomImage() -> UIImage? {
            UIImage(data: AppInboxDetailViewControllerSpec.makePngData(width: 1200, height: 300))
        }

        beforeEach {
            IntegrationManager.shared.isStopped = false
            window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
            viewController = AppInboxDetailViewController()
            window.rootViewController = viewController
            window.isHidden = false
            viewController.withData(AppInboxCacheSpec.getSampleMessage(id: "id1", type: "push"))
            host(width: 390)
        }

        afterEach {
            downloadGate?.signal()
            downloadGate = nil
            MockingjayProtocol.removeAllStubs()
            viewController.animatedMessageImage.clear()
            window.isHidden = true
            window = nil
        }

        context("image view size") {
            let sizes: [(width: Int, height: Int)] = [(1200, 900), (1200, 300), (300, 1200), (100, 100)]
            sizes.forEach { size in
                it("matches the drawn image for \(size.width)x\(size.height)") {
                    showImage(AppInboxDetailViewControllerSpec.makePngData(width: size.width, height: size.height))
                    let expectedHeight = 390 * CGFloat(size.height) / CGFloat(size.width)
                    expect(viewController.messageImage.frame.width).to(beCloseTo(390, within: 0.5))
                    expect(viewController.messageImage.frame.height).to(beCloseTo(expectedHeight, within: 0.5))
                    expect(viewController.receivedTime.frame.minY)
                        .to(beCloseTo(viewController.messageImage.frame.maxY + 16, within: 0.5))
                }
            }

            it("keeps the aspect ratio for an animated GIF") {
                showImage(GifImageDecodingSpec.makeTwoFrameGifData())
                expect(viewController.messageImage.frame.width).to(beCloseTo(390, within: 0.5))
                expect(viewController.messageImage.frame.height).to(beCloseTo(390, within: 0.5))
            }

            it("follows the container width when it changes") {
                showImage(AppInboxDetailViewControllerSpec.makePngData(width: 1200, height: 900))
                host(width: 600)
                expect(viewController.messageImage.frame.width).to(beCloseTo(600, within: 0.5))
                expect(viewController.messageImage.frame.height).to(beCloseTo(450, within: 0.5))
            }
        }

        context("without image") {
            it("collapses the image view and places the date right below it") {
                expect(viewController.messageImage.image).to(beNil())
                expect(viewController.messageImage.isHidden).to(beFalse())
                expect(viewController.messageImage.frame.height).to(equal(0))
                expect(viewController.receivedTime.frame.minY)
                    .to(beCloseTo(viewController.messageImage.frame.maxY + 16, within: 0.5))
            }

            it("collapses the image view after the image is cleared") {
                showImage(AppInboxDetailViewControllerSpec.makePngData(width: 1200, height: 900))
                viewController.animatedMessageImage.clear()
                viewController.view.layoutIfNeeded()
                expect(viewController.messageImage.frame.height).to(equal(0))
            }
        }

        context("changes made through the public image view") {
            it("sizes an image set directly on messageImage") {
                viewController.messageImage.image = makeCustomImage()
                viewController.view.layoutIfNeeded()
                expect(viewController.messageImage.frame.height).to(beCloseTo(97.5, within: 0.5))
            }

            it("stops the animation when an image is set on messageImage") {
                showImage(GifImageDecodingSpec.makeTwoFrameGifData())
                expect(viewController.animatedMessageImage.isAnimatingFrames).to(beTrue())
                let customImage = makeCustomImage()
                viewController.messageImage.image = customImage
                expect(viewController.animatedMessageImage.isAnimatingFrames).to(beFalse())
                expect(viewController.messageImage.image).to(beIdenticalTo(customImage))
            }

            it("keeps an image set on messageImage after leaving and returning to the screen") {
                let navigationController = embedInNavigation()
                let customImage = makeCustomImage()
                viewController.messageImage.image = customImage
                navigationController.pushViewController(UIViewController(), animated: false)
                waitUntilOffScreen { viewController }
                navigationController.popViewController(animated: false)
                waitUntilOnScreen { viewController }
                viewController.view.layoutIfNeeded()
                expect(viewController.messageImage.image).to(beIdenticalTo(customImage))
                expect(viewController.messageImage.isHidden).to(beFalse())
                expect(viewController.messageImage.frame.height).to(beCloseTo(97.5, within: 0.5))
            }

            it("collapses and restores the image view when isHidden changes") {
                showImage(AppInboxDetailViewControllerSpec.makePngData(width: 1200, height: 900))
                viewController.messageImage.isHidden = true
                viewController.view.layoutIfNeeded()
                expect(viewController.messageImage.frame.height).to(equal(0))
                expect(viewController.receivedTime.frame.minY)
                    .to(beCloseTo(viewController.messageImage.frame.maxY + 16, within: 0.5))

                viewController.messageImage.isHidden = false
                viewController.view.layoutIfNeeded()
                expect(viewController.messageImage.frame.height).to(beCloseTo(292.5, within: 0.5))
            }

            it("keeps the same height constraint while an animated image plays") {
                showImage(GifImageDecodingSpec.makeTwoFrameGifData())
                let firstFrame = viewController.messageImage.image
                let constraint = viewController.messageImageHeightConstraint
                expect(viewController.messageImage.image).toEventuallyNot(beIdenticalTo(firstFrame))
                expect(viewController.messageImageHeightConstraint).to(beIdenticalTo(constraint))
            }
        }

        context("image loading") {
            var imageUrl: String!

            beforeEach {
                // unique URL so the image is never served from a previous test's cache
                imageUrl = "https://cdn.example.com/app-inbox-\(UUID().uuidString).png"
            }

            it("sizes the downloaded image to its aspect ratio") {
                AppInboxDetailViewControllerSpec.stubImage(
                    imageUrl,
                    data: AppInboxDetailViewControllerSpec.makePngData(width: 1200, height: 900)
                )
                viewController.withData(AppInboxDetailViewControllerSpec.makePushMessage(imageUrl: imageUrl))
                expect(viewController.messageImage.image).toEventuallyNot(beNil(), timeout: .seconds(5))
                viewController.view.layoutIfNeeded()
                expect(viewController.messageImage.isHidden).to(beFalse())
                expect(viewController.messageImage.frame.height).to(beCloseTo(292.5, within: 0.5))
            }

            it("collapses the image view when the download fails") {
                AppInboxDetailViewControllerSpec.stubImage(imageUrl, data: nil)
                showImage(AppInboxDetailViewControllerSpec.makePngData(width: 1200, height: 900))
                viewController.withData(AppInboxDetailViewControllerSpec.makePushMessage(imageUrl: imageUrl))
                expect(viewController.messageImage.image).toEventually(beNil(), timeout: .seconds(5))
                viewController.view.layoutIfNeeded()
                expect(viewController.messageImage.isHidden).to(beFalse())
                expect(viewController.messageImage.frame.height).to(equal(0))
            }

            it("releases the image while the screen is hidden and keeps its height until it's loaded again") {
                AppInboxDetailViewControllerSpec.stubImage(
                    imageUrl,
                    data: AppInboxDetailViewControllerSpec.makePngData(width: 1200, height: 900)
                )
                let navigationController = embedInNavigation()
                viewController.withData(AppInboxDetailViewControllerSpec.makePushMessage(imageUrl: imageUrl))
                expect(viewController.messageImage.image).toEventuallyNot(beNil(), timeout: .seconds(5))

                navigationController.pushViewController(UIViewController(), animated: false)
                waitUntilOffScreen { viewController }
                expect(viewController.messageImage.image).toEventually(beNil())
                viewController.view.layoutIfNeeded()
                expect(viewController.messageImage.frame.height).to(beCloseTo(292.5, within: 0.5))

                navigationController.popViewController(animated: false)
                viewController.view.layoutIfNeeded()
                expect(viewController.messageImage.frame.height).to(beCloseTo(292.5, within: 0.5))
                expect(viewController.messageImage.image).toEventuallyNot(beNil(), timeout: .seconds(5))
                viewController.view.layoutIfNeeded()
                expect(viewController.messageImage.frame.height).to(beCloseTo(292.5, within: 0.5))
            }

            it("collapses the image view when the image can't be loaded again after returning") {
                AppInboxDetailViewControllerSpec.stubImage(
                    imageUrl,
                    data: AppInboxDetailViewControllerSpec.makePngData(width: 1200, height: 900)
                )
                let navigationController = embedInNavigation()
                viewController.withData(AppInboxDetailViewControllerSpec.makePushMessage(imageUrl: imageUrl))
                expect(viewController.messageImage.image).toEventuallyNot(beNil(), timeout: .seconds(5))

                navigationController.pushViewController(UIViewController(), animated: false)
                waitUntilOffScreen { viewController }
                MockingjayProtocol.removeAllStubs()
                AppInboxCache.shared.clear()
                AppInboxDetailViewControllerSpec.stubImage(imageUrl, data: nil)

                navigationController.popViewController(animated: false)
                expect(viewController.messageImage.frame.height).toEventually(equal(0), timeout: .seconds(5))
            }

            it("drops an image that finishes loading while the screen is hidden and loads it on return") {
                let gate = makeDownloadGate()
                AppInboxDetailViewControllerSpec.stubImage(
                    imageUrl,
                    data: AppInboxDetailViewControllerSpec.makePngData(width: 1200, height: 900),
                    gate: gate
                )
                let navigationController = embedInNavigation()
                viewController.withData(AppInboxDetailViewControllerSpec.makePushMessage(imageUrl: imageUrl))
                navigationController.pushViewController(UIViewController(), animated: false)
                waitUntilOffScreen { viewController }
                expect(viewController.isLoadingMessageImage).to(beTrue())
                gate.signal()
                waitUntilImageLoadHandled()
                expect(viewController.messageImage.image).to(beNil())

                navigationController.popViewController(animated: false)
                expect(viewController.messageImage.image).toEventuallyNot(beNil(), timeout: .seconds(5))
            }

            it("keeps the image hidden by a style applied before the image loads") {
                AppInboxDetailViewControllerSpec.stubImage(
                    imageUrl,
                    data: AppInboxDetailViewControllerSpec.makePngData(width: 1200, height: 900)
                )
                DetailViewStyle(image: ImageViewStyle(visible: false)).applyTo(viewController)
                viewController.withData(AppInboxDetailViewControllerSpec.makePushMessage(imageUrl: imageUrl))
                expect(viewController.messageImage.image).toEventuallyNot(beNil(), timeout: .seconds(5))
                viewController.view.layoutIfNeeded()
                expect(viewController.messageImage.isHidden).to(beTrue())
                expect(viewController.messageImage.frame.height).to(equal(0))
            }

            it("doesn't replace an image set on messageImage while its own image is loading") {
                let gate = makeDownloadGate()
                AppInboxDetailViewControllerSpec.stubImage(
                    imageUrl,
                    data: AppInboxDetailViewControllerSpec.makePngData(width: 1200, height: 900),
                    gate: gate
                )
                viewController.withData(AppInboxDetailViewControllerSpec.makePushMessage(imageUrl: imageUrl))
                let customImage = makeCustomImage()
                viewController.messageImage.image = customImage
                expect(viewController.isLoadingMessageImage).to(beTrue())
                gate.signal()
                waitUntilImageLoadHandled()
                expect(viewController.messageImage.image).to(beIdenticalTo(customImage))
            }

            it("keeps an image set on messageImage before the message data arrives") {
                // the provider returns the screen before the message is fetched, integrators can customize it first
                let detail = AppInboxDetailViewController()
                detail.loadViewIfNeeded()
                let customImage = makeCustomImage()
                detail.messageImage.image = customImage
                detail.withData(AppInboxDetailViewControllerSpec.makePushMessage(imageUrl: imageUrl))
                expect(detail.animatedMessageImage.hasCustomImage).to(beTrue())
                expect(detail.messageImage.image).to(beIdenticalTo(customImage))
            }

            it("loads its own image again after messageImage is set to nil") {
                AppInboxDetailViewControllerSpec.stubImage(
                    imageUrl,
                    data: AppInboxDetailViewControllerSpec.makePngData(width: 1200, height: 900)
                )
                viewController.messageImage.image = makeCustomImage()
                viewController.messageImage.image = nil
                viewController.withData(AppInboxDetailViewControllerSpec.makePushMessage(imageUrl: imageUrl))
                expect(viewController.messageImage.image?.size).toEventually(
                    equal(CGSize(width: 1200, height: 900)),
                    timeout: .seconds(5)
                )
            }

            it("replaces an image set on messageImage when data for another message arrives") {
                AppInboxDetailViewControllerSpec.stubImage(
                    imageUrl,
                    data: AppInboxDetailViewControllerSpec.makePngData(width: 1200, height: 900)
                )
                viewController.messageImage.image = makeCustomImage()
                let otherMessage = AppInboxCacheSpec.getSampleMessage(
                    id: "id2",
                    type: "push",
                    data: ["image": .string(imageUrl)]
                )
                viewController.withData(otherMessage)
                expect(viewController.messageImage.image?.size).toEventually(
                    equal(CGSize(width: 1200, height: 900)),
                    timeout: .seconds(5)
                )
            }

            it("releases the image view when the screen is closed before an animated image loads") {
                let gate = makeDownloadGate()
                let gifUrl = "https://cdn.example.com/app-inbox-\(UUID().uuidString).gif"
                AppInboxDetailViewControllerSpec.stubImage(
                    gifUrl,
                    data: GifImageDecodingSpec.makeTwoFrameGifData(),
                    gate: gate
                )
                weak var weakImageView: UIAnimatedImageView?
                weak var weakDetail: AppInboxDetailViewController?
                autoreleasepool {
                    let navigationController = UINavigationController(rootViewController: UIViewController())
                    window.rootViewController = navigationController
                    let detail = AppInboxDetailViewController()
                    weakDetail = detail
                    weakImageView = detail.animatedMessageImage
                    navigationController.pushViewController(detail, animated: false)
                    window.layoutIfNeeded()
                    detail.withData(AppInboxDetailViewControllerSpec.makePushMessage(imageUrl: gifUrl))
                    navigationController.popViewController(animated: false)
                }
                waitUntilOffScreen { weakDetail }
                // the image arrives only after the screen is closed
                gate.signal()
                // compare inside the closure so that polling doesn't keep the objects alive
                expect { weakDetail == nil }.toEventually(beTrue(), timeout: .seconds(5))
                expect { weakImageView == nil }.toEventually(beTrue())
            }
        }

        context("animated image view") {
            it("pauses the animation while the view is hidden or off screen") {
                showImage(GifImageDecodingSpec.makeTwoFrameGifData())
                let imageView = viewController.animatedMessageImage
                expect(imageView.isAnimatingFrames).to(beTrue())

                imageView.isHidden = true
                expect(imageView.isAnimatingFrames).to(beFalse())
                imageView.isHidden = false
                expect(imageView.isAnimatingFrames).to(beTrue())

                let superview = imageView.superview
                imageView.removeFromSuperview()
                expect(imageView.isAnimatingFrames).to(beFalse())
                superview?.addSubview(imageView)
                expect(imageView.isAnimatingFrames).to(beTrue())
            }

            it("is released while an animated image is playing") {
                weak var weakImageView: UIAnimatedImageView?
                autoreleasepool {
                    let imageView = UIAnimatedImageView()
                    weakImageView = imageView
                    window.addSubview(imageView)
                    imageView.loadImage(imageData: GifImageDecodingSpec.makeTwoFrameGifData())
                    expect(imageView.isAnimatingFrames).to(beTrue())
                    imageView.removeFromSuperview()
                }
                // compare inside the closure so that polling doesn't keep the view alive
                expect { weakImageView == nil }.toEventually(beTrue())
            }
        }

        it("makes the whole content scrollable down to the action buttons") {
            showImage(AppInboxDetailViewControllerSpec.makePngData(width: 1200, height: 900))
            expect(viewController.pushContainer.contentSize.height)
                .to(beCloseTo(viewController.actionsContainer.frame.maxY + 16, within: 0.5))
        }
    }
}

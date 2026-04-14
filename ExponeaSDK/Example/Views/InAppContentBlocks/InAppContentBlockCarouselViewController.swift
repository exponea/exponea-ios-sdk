//
//  InAppContentBlockCarouselViewController.swift
//  Example
//
//  Created by Ankmara on 19.06.2024.
//  Copyright © 2024 Exponea. All rights reserved.
//

import Foundation
import UIKit
import WebKit
import ExponeaSDK

class CustomCarouselView: CarouselInAppContentBlockView {
    override func filterContentBlocks(placeholder: String, continueCallback: TypeBlock<[InAppContentBlockResponse]>?, expiredCompletion: EmptyBlock?) {
        super.filterContentBlocks(placeholder: placeholder) { data in
            // custom filter
            let customFilter = data.filter { !$0.name.contains("discarded") }
            continueCallback?(customFilter)
        } expiredCompletion: {
            expiredCompletion?()
        }
    }

    override func sortContentBlocks(data: [StaticReturnData]) -> [StaticReturnData] {
        let origin = super.sortContentBlocks(data: data) // our filter
        return origin.reversed()
    }
}

class CustomCarouselCallback: DefaultContentBlockCarouselCallback {

    public var overrideDefaultBehavior: Bool = false
    public var trackActions: Bool = true

    public init() {}

    public func onMessageShown(placeholderId: String, contentBlock: ExponeaSDK.InAppContentBlockResponse, index: Int, count: Int) {
        // space for custom implementation
    }

    public func onMessagesChanged(count: Int, messages: [ExponeaSDK.InAppContentBlockResponse]) {
        // space for custom implementation
    }

    public func onNoMessageFound(placeholderId: String) {
        // space for custom implementation
    }

    public func onError(placeholderId: String, contentBlock: ExponeaSDK.InAppContentBlockResponse?, errorMessage: String) {
        // space for custom implementation
    }

    public func onCloseClicked(placeholderId: String, contentBlock: ExponeaSDK.InAppContentBlockResponse) {
        // space for custom implementation
    }

    public func onActionClickedSafari(placeholderId: String, contentBlock: ExponeaSDK.InAppContentBlockResponse, action: ExponeaSDK.InAppContentBlockAction) {
        // space for custom implementation
    }

    public func onHeightUpdate(placeholderId: String, height: CGFloat) {
        Exponea.logger.log(.verbose, message: "Placeholder \(placeholderId) got new height: \(height)")
    }
}

class InAppContentBlockCarouselViewController: UIViewController {

    let carousel = CarouselInAppContentBlockView(placeholder: "example_carousel")
    let carousel2 = CustomCarouselView(
        placeholder: "example_carousel",
        maxMessagesCount: 5,
        scrollDelay: 10,
        behaviourCallback: CustomCarouselCallback()
    )
    let carousel3 = CustomCarouselView(placeholder: "example_carousel_ios", scrollDelay: 1000)

    @objc func endEditing() {
        view.endEditing(true)
    }

    deinit {
        carousel.release()
        carousel2.release()
        carousel3.release()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        addCarousel(carousel, topAnchor: view.safeAreaLayoutGuide.topAnchor)
        addCarousel(carousel2, topAnchor: carousel.bottomAnchor)
        addCarousel(carousel3, topAnchor: carousel2.bottomAnchor)

        navigationItem.rightBarButtonItem = .init(barButtonSystemItem: .refresh, target: self, action: #selector(reloadCarousels))

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.navigationItem.title = "\(self.carousel.getShownCount()) / \(self.carousel2.getShownCount()) / \(self.carousel3.getShownCount())"
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.view.layoutIfNeeded()
            self.carousel.reload()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.carousel2.reload()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.carousel3.reload()
                }
            }
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        carousel.continueWithTimer()
        carousel2.continueWithTimer()
        carousel3.continueWithTimer()
    }

    @objc func reloadCarousels() {
        carousel.reload()
        carousel2.reload()
        carousel3.reload()
    }

    private func addCarousel(_ carousel: CarouselInAppContentBlockView, topAnchor: NSLayoutYAxisAnchor) {
        view.addSubview(carousel)
        carousel.translatesAutoresizingMaskIntoConstraints = false
        carousel.topAnchor.constraint(equalTo: topAnchor, constant: 20).isActive = true
        carousel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        carousel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
    }
}

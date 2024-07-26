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

class InAppContentBlockCarouselViewController: UIViewController {

    let carousel = CarouselInAppContentBlockView(placeholder: "example_carousel", behaviourCallback: CustomCarouselCallback())
    let carousel2 = CustomCarouselView(placeholder: "example_carousel", maxMessagesCount: 5, scrollDelay: 10)
    let carousel3 = CustomCarouselView(placeholder: "example_carousel_ios")

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

        carousel.onMessageShown = { message in
            print("ON MESSAGE SHOW")
            print(message.index)
            print(message.placeholderId)
        }

        carousel.onMessageChanged = { chagned in
            print("ON MESSAGE CHANGED")
            print(chagned)
        }

        carousel.reload()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.carousel2.reload()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.carousel3.reload()
        }

        view.backgroundColor = .white

        view.addSubview(carousel)
        carousel.translatesAutoresizingMaskIntoConstraints = false
        carousel.topAnchor.constraint(equalTo: view.topAnchor, constant: 80).isActive = true
        carousel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        carousel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true

        view.addSubview(carousel2)
        carousel2.translatesAutoresizingMaskIntoConstraints = false
        carousel2.topAnchor.constraint(equalTo: carousel.bottomAnchor, constant: 20).isActive = true
        carousel2.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        carousel2.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true

        view.addSubview(carousel3)
        carousel3.translatesAutoresizingMaskIntoConstraints = false
        carousel3.topAnchor.constraint(equalTo: carousel2.bottomAnchor, constant: 20).isActive = true
        carousel3.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        carousel3.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true

        navigationItem.rightBarButtonItem = .init(barButtonSystemItem: .refresh, target: self, action: #selector(reloadCarousels))
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
}

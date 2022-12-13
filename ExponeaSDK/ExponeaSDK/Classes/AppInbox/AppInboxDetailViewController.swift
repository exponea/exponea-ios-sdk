//
//  AppInboxDetailViewController.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 10/10/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//

import Foundation
import UIKit

open class AppInboxDetailViewController: UIViewController {

    @IBOutlet public var messageImage: UIImageView!
    @IBOutlet public var receivedTime: UILabel!
    @IBOutlet public var messageTitle: UILabel!
    @IBOutlet public var message: UILabel!
    @IBOutlet public var actionsContainer: UIStackView!
    @IBOutlet public var actionMain: UIButton!
    @IBOutlet public var action1: UIButton!
    @IBOutlet public var action2: UIButton!
    @IBOutlet public var action3: UIButton!
    @IBOutlet public var action4: UIButton!

    private let SUPPORTED_MESSAGE_ACTION_TYPES: [MessageItemActionType] = [
        .deeplink, .browser
    ]

    private let urlOpener: UrlOpenerType = UrlOpener()
    private var data: MessageItem?
    private var mainAction: MessageItemAction?
    private var shownActions: [MessageItemAction]?

    open func withData(_ source: MessageItem) {
        self.data = source
        self.mainAction = readMainAction(source)
        let actions = source.content?.actions ?? []
        self.shownActions = actions.filter { action in
            return SUPPORTED_MESSAGE_ACTION_TYPES.contains(action.type)
        }
        loadViewIfNeeded()
        applyDataToView()
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = false
        navigationController?.isNavigationBarHidden = false
        applyDataToView()
    }
    
    private func readMainAction(_ source: MessageItem) -> MessageItemAction? {
        guard let mainActionTypeRaw = source.content?.action,
              let mainActionType = MessageItemActionType(rawValue: mainActionTypeRaw),
              let mainActionUrl = source.content?.actionUrl else {
            return nil
        }
        if SUPPORTED_MESSAGE_ACTION_TYPES.contains(mainActionType) {
            return MessageItemAction(
                action: mainActionTypeRaw,
                title: NSLocalizedString(
                    "exponea.inbox.mainActionTitle",
                    value: "See more",
                    comment: ""
                ),
                url: mainActionUrl
            )
        }
        return nil
    }
    
    private func applyDataToView() {
        title = data?.content?.title ?? NSLocalizedString(
            "exponea.inbox.defaultTitle",
            value: "Message",
            comment: ""
        )
        receivedTime.text = translateReceivedTime(data?.content?.createdAtDate ?? Date())
        messageTitle.text = data?.content?.title ?? ""
        message.text = data?.content?.message ?? ""
        setupActionButtons(data)
        if let imageUrl = data?.content?.imageUrl {
            DispatchQueue.global(qos: .background).async {
                guard let imageSource = self.tryDownloadImage(imageUrl),
                      let image = self.createImage(imageData: imageSource, maxDimensionInPixels: Int(UIScreen.main.bounds.width)) else {
                    Exponea.logger.log(.error, message: "Image cannot be shown")
                    return
                }
                DispatchQueue.main.async {
                    self.messageImage.image = image
                }
            }
        }
    }
    @IBAction func onMainActionClicked(_ sender: Any) {
        invokeMainAction()
    }
    @IBAction func onAction1Clicked(_ sender: Any) {
        invokeActionForIndex(0)
    }
    @IBAction func onAction2Clicked(_ sender: Any) {
        invokeActionForIndex(1)
    }
    @IBAction func onAction3Clicked(_ sender: Any) {
        invokeActionForIndex(2)
    }
    @IBAction func onAction4Clicked(_ sender: Any) {
        invokeActionForIndex(3)
    }

    func invokeMainAction() {
        guard let action = mainAction,
            let message = data else {
                Exponea.logger.log(.error, message: "AppInbox main action called but no action or message is provided")
                return
        }
        invokeActionInternally(action, message)
    }

    func invokeActionForIndex(_ index: Int) {
        let action = getActionByIndex(index)
        guard let action = action,
            let message = data else {
                Exponea.logger.log(.error, message: "AppInbox action \(index) called but no action or message is provided")
                return
        }
        invokeActionInternally(action, message)
    }

    private func invokeActionInternally(_ action: MessageItemAction, _ message: MessageItem) {
        Exponea.shared.trackAppInboxClick(action: action, message: message)
        switch action.type {
        case .browser:
            openBrowserAction(action)
        case .deeplink:
            openDeeplinkAction(action)
        default:
            Exponea.logger.log(.warning, message: "No AppInbox action for type \(action.type.rawValue)")
        }
    }

    func openBrowserAction(_ action: MessageItemAction) {
        guard let buttonLink = action.url else {
            Exponea.logger.log(.error, message: "AppInbox action \"\(action.title ?? "<nil>")\" contains invalid browser link \(action.url ?? "<nil>")")
            return
        }
        urlOpener.openBrowserLink(buttonLink)
    }

    func openDeeplinkAction(_ action: MessageItemAction) {
        guard let buttonLink = action.url else {
            Exponea.logger.log(.error, message: "AppInbox action \"\(action.title ?? "<nil>")\" contains invalid universal link \(action.url ?? "<nil>")")
            return
        }
        urlOpener.openDeeplink(buttonLink)
    }

    func setupActionButtons(_ source: MessageItem?) {
        setupMainActionButton(actionMain)
        setupActionButton(action1, 0)
        setupActionButton(action2, 1)
        setupActionButton(action3, 2)
        setupActionButton(action4, 3)
    }
    
    func setupMainActionButton(_ target: UIButton) {
        setupActionButton(target, self.mainAction)
    }

    func setupActionButton(_ target: UIButton, _ index: Int) {
        let action = getActionByIndex(index)
        setupActionButton(target, action)
    }
    
    func setupActionButton(_ target: UIButton, _ action: MessageItemAction?) {
        guard let action = action else {
            // no action for index -> no button
            target.isHidden = true
            return
        }
        target.isHidden = false
        target.setTitle(action.title, for: .normal)
    }

    func getActionByIndex(_ index: Int) -> MessageItemAction? {
        return shownActions?.indices.contains(index) == true ? shownActions![index] : nil
    }

    open func translateReceivedTime(_ source: Date) -> String {
        if #available(iOS 13.0, *) {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            return formatter.localizedString(for: source, relativeTo: Date())
        } else {
            let formatter = DateFormatter()
            formatter.timeStyle = .long
            formatter.dateStyle = .long
            formatter.doesRelativeDateFormatting = true
            return formatter.string(from: source)
        }
    }

    private func tryDownloadImage(_ imageSource: String?) -> Data? {
        guard imageSource != nil,
              let imageUrl = URL(string: imageSource!)
                else {
            Exponea.logger.log(.error, message: "Image cannot be downloaded \(imageSource ?? "<is nil>")")
            return nil
        }
        let semaphore = DispatchSemaphore(value: 0)
        var imageData: Data?
        let dataTask = URLSession.shared.dataTask(with: imageUrl) { data, response, error in {
            imageData = data
            semaphore.signal()
        }() }
        dataTask.resume()
        let awaitResult = semaphore.wait(timeout: .now() + 10.0)
        switch (awaitResult) {
        case .success:
            // Nothing to do, let check imageData
            break
        case .timedOut:
            Exponea.logger.log(.warning, message: "Image \(imageSource!) may be too large or slow connection - aborting")
            dataTask.cancel()
        }
        return imageData
    }

    func createImage(imageData: Data, maxDimensionInPixels: Int) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, imageSourceOptions) else {
            Exponea.logger.log(.error, message: "Unable create image for in-app message - image source failed")
            return nil
        }
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ] as CFDictionary
        guard let downsampledCGImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            Exponea.logger.log(.error, message: "Unable create image for in-app message - downsampling failed")
            return nil
        }
        return UIImage(cgImage: downsampledCGImage)
    }
}

//
//  AppInboxDetailViewController.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 10/10/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//

import Foundation
import UIKit
import WebKit

open class AppInboxDetailViewController: UIViewController, WKUIDelegate {

    @IBOutlet public var pushContainer: UIScrollView!
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
    @IBOutlet public var htmlContainer: WKWebView!

    private let SUPPORTED_MESSAGE_ACTION_TYPES: [MessageItemActionType] = [
        .deeplink, .browser
    ]

    private let SUPPORTED_MESSAGE_TYPES: [String] = [
        "push", "html"
    ]

    private let urlOpener: UrlOpenerType = UrlOpener()
    private var data: MessageItem?
    private var mainAction: MessageItemAction?
    private var shownActions: [MessageItemAction]?
    private var normalizedPayload: NormalizedResult?
    private var actionManager: WebActionManager?

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
        actionManager = WebActionManager(
            onActionCallback: { [weak self] action in
                guard let self = self,
                      let message = self.data else {
                    Exponea.logger.log(.error, message: "AppInbox action \(action.actionUrl) called but no action or message is provided")
                    return
                }
                self.invokeActionInternally(
                    MessageItemAction(
                        action: self.determineActionType(action).rawValue,
                        title: action.buttonText,
                        url: action.actionUrl
                    ),
                    message
                )
            }
        )
        navigationController?.navigationBar.isHidden = false
        navigationController?.isNavigationBarHidden = false
        applyDataToView()
    }

    private func determineActionType(_ action: ActionInfo) -> MessageItemActionType {
        if action.actionUrl.hasPrefix("http://") || action.actionUrl.hasPrefix("https://") {
            return .browser
        } else {
            return .deeplink
        }
    }

    private func readMainAction(_ source: MessageItem) -> MessageItemAction? {
        guard let mainActionTypeRaw = source.content?.action?.action,
              let mainActionType = MessageItemActionType(rawValue: mainActionTypeRaw),
              let mainActionUrl = source.content?.action?.url else {
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
        guard
            let dataType = data?.type,
            SUPPORTED_MESSAGE_TYPES.contains(dataType) else {
            Exponea.logger.log(.warning, message: "Unsupported AppInbox type \(data?.type ?? "nil") to be shown")
            return
        }
        hideContainers()
        switch dataType {
        case "html":
            showHtmlMessage()
        case "push":
            showPushMessage()
        default:
            Exponea.logger.log(.error, message: "Unsupported AppInbox type \(dataType) to be shown")
            return
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

    private func hideContainers() {
        pushContainer.isHidden = true
        htmlContainer.isHidden = true
    }

    private func showPushMessage() {
        pushContainer.isHidden = false
        title = data?.content?.title ?? NSLocalizedString(
            "exponea.inbox.defaultTitle",
            value: "Message",
            comment: ""
        )
        receivedTime.text = translateReceivedTime(data?.receivedTime ?? Date())
        messageTitle.text = data?.content?.title ?? ""
        message.text = data?.content?.message ?? ""
        setupActionButtons(data)
        if let imageUrl = data?.content?.imageUrl {
            DispatchQueue.global(qos: .background).async {
                guard let imageSource = ImageUtils.tryDownloadImage(imageUrl),
                      let image = ImageUtils.createImage(imageData: imageSource, maxDimensionInPixels: Int(UIScreen.main.bounds.width)) else {
                    Exponea.logger.log(.error, message: "Image cannot be shown")
                    return
                }
                DispatchQueue.main.async {
                    self.messageImage.image = image
                }
            }
        }
    }

    private func showHtmlMessage() {
        htmlContainer.isHidden = false
        htmlContainer.navigationDelegate = self.actionManager
        htmlContainer.uiDelegate = self
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let selfWhileAsync = self else {
                Exponea.logger.log(.error, message: "Showing a HTML AppInbox stops")
                return
            }
            let normalizeConf = HtmlNormalizerConfig(
                makeImagesOffline: true,
                ensureCloseButton: false,
                allowAnchorButton: true
            )
            let normalizedPayload = HtmlNormalizer(selfWhileAsync.data?.content?.html ?? "").normalize(normalizeConf)
            guard
                normalizedPayload.valid
            else {
                Exponea.logger.log(.error, message: "AppInbox message contains invalid HTML")
                return
            }
            selfWhileAsync.normalizedPayload = normalizedPayload
            selfWhileAsync.actionManager?.htmlPayload = normalizedPayload
            DispatchQueue.main.async { [weak selfWhileAsync] in
                guard
                    let selfWhileMain = selfWhileAsync,
                    let normalizedHtml = selfWhileMain.normalizedPayload?.html
                else {
                    Exponea.logger.log(.error, message: "Showing a HTML AppInbox stops")
                    return
                }
                selfWhileMain.htmlContainer.loadHTMLString(normalizedHtml, baseURL: nil)
            }
        }
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
}

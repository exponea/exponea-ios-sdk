//
//  InAppMessagePresenter.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 03/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import UIKit

final class InAppMessagePresenter: InAppMessagePresenterType {

    enum InAppMessagePresenterError: Error {
        case unableToCreateView
        case unableToPresentView
    }

    private let window: UIWindow?
    internal var presenting = false

    init(window: UIWindow? = nil) {
        self.window = window
    }

    func presentInAppMessage(
        messageType: InAppMessageType,
        payload: RichInAppMessagePayload?,
        oldPayload: InAppMessagePayload?,
        payloadHtml: String?,
        delay: TimeInterval,
        timeout: TimeInterval?,
        imageData: Data?,
        actionCallback: @escaping (InAppMessagePayloadButton) -> Void,
        dismissCallback: @escaping (Bool, InAppMessagePayloadButton?) -> Void,
        presentedCallback: ((InAppMessageView?, String?) -> Void)? = nil
    ) {
        Exponea.logger.log(
            .verbose,
            message: "Will attempt to present in-app message on main thread with delay \(delay)."
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            Exponea.shared.executeSafely {
                onMain {
                    guard !self.presenting else {
                        Exponea.logger.log(.verbose, message: "Already presenting in-app message.")
                        presentedCallback?(nil, nil)
                        return
                    }
                    var image: UIImage?
                    if let imageData = imageData {
                        if let gifImage = UIImage.gifImageWithData(imageData) {
                            image = gifImage
                        } else if let createdImage = self.createImage(
                            imageData: imageData,
                            maxDimensionInPixels: self.getMaxScreenDimension()
                        ) {
                            image = createdImage
                        } else {
                            Exponea.logger.log(.error, message: "Unable to create in-app message image")
                            presentedCallback?(nil, "Unable to create in-app message image")
                            return
                        }
                    }

                    guard let viewController = InAppMessagePresenter.getTopViewController(window: self.window) else {
                        Exponea.logger.log(.error, message: "Unable to present in-app message - no view controller")
                        presentedCallback?(nil, "Unable to present in-app message - no view controller")
                        return
                    }

                    do {
                        var inAppMessageView = try self.createInAppMessageView(
                            messageType: messageType,
                            payload: payload,
                            oldPayload: oldPayload,
                            payloadHtml: payloadHtml,
                            image: image,
                            timeout: timeout,
                            actionCallback: { button in
                                self.presenting = false
                                actionCallback(button)
                            },
                            dismissCallback: { isUserInteraction, cancelButtonPayload in
                                self.presenting = false
                                dismissCallback(isUserInteraction, cancelButtonPayload)
                            }
                        )
                        try inAppMessageView.present(
                            in: viewController,
                            window: self.window ?? UIApplication.shared.keyWindow
                        )
                        self.presenting = true
                        Exponea.logger.log(.verbose, message: "In-app message presented.")
                        if oldPayload != nil { // old inapp
                            self.setMessageTimeout(inAppMessageView: inAppMessageView, timeout: timeout)
                        }
                        presentedCallback?(inAppMessageView, nil)
                    } catch {
                        Exponea.logger.log(.error, message: "Unable to present in-app message \(error)")
                        presentedCallback?(nil, error.localizedDescription)
                    }
                }
            }
        }
    }

    func setMessageTimeout(inAppMessageView: InAppMessageView, timeout: TimeInterval?) {
        var messageTimeout = timeout
        if inAppMessageView is InAppMessageSlideInView {
            messageTimeout = messageTimeout ?? 4
        }
        if inAppMessageView is OldInAppMessageSlideInView {
            messageTimeout = messageTimeout ?? 4
        }
        if let messageTimeout = messageTimeout {
            DispatchQueue.main.asyncAfter(deadline: .now() + messageTimeout) {
                if !inAppMessageView.isPresented {
                    Exponea.logger.log(
                        .verbose,
                        message: "In-app delayed close is skipped because view is not presented"
                    )
                    return
                }
                inAppMessageView.dismiss(isUserInteraction: false, cancelButton: nil)
            }
        }
    }

    func createInAppMessageView(
        messageType: InAppMessageType,
        payload: RichInAppMessagePayload?,
        oldPayload: InAppMessagePayload?,
        payloadHtml: String?,
        image: UIImage?,
        timeout: TimeInterval?,
        actionCallback: @escaping (InAppMessagePayloadButton) -> Void,
        dismissCallback: @escaping (Bool, InAppMessagePayloadButton?) -> Void
    ) throws -> InAppMessageView {
        switch messageType {
        case .alert:
            if let oldPayload {
                return try InAppMessageAlertView(
                    payload: oldPayload,
                    actionCallback: actionCallback,
                    dismissCallback: dismissCallback
                )
            }
        case .modal, .fullscreen:
            guard let image = image else {
                Exponea.logger.log(.error, message: "In-app message type \(messageType) requires image!")
                throw InAppMessagePresenterError.unableToCreateView
            }
            var fullscreen = false
            if case .fullscreen = messageType {
                fullscreen = true
            }
            if var payload {
                let updatedConfigs = payload.buttons.map { payload in
                    var updatedPayload = payload
                    updatedPayload.buttonConfig?.actionCallback = { type in
                        if let type {
                            actionCallback(type)
                        }
                    }
                    return updatedPayload
                }
                payload.buttons = updatedConfigs
                var updatedPayload = payload
                updatedPayload.closeConfig.dismissCallback = {
                    dismissCallback(true, .init(closeConfig: updatedPayload.closeConfig))
                }
                let view = InAppDialogContainerView(
                    payLoad: updatedPayload,
                    isFullscreen: fullscreen,
                    dismissCallback: dismissCallback,
                    actionCallback: actionCallback
                )
                view.setCloseTimeCallback = { [weak self] in
                    self?.setMessageTimeout(inAppMessageView: view, timeout: timeout)
                }
                return view
            } else if let oldPayload {
                return InAppMessageDialogView(
                    payload: oldPayload,
                    image: image,
                    actionCallback: actionCallback,
                    dismissCallback: dismissCallback,
                    fullscreen: fullscreen
                )
            } else {
                return InAppMessageWebView(
                    payload: payloadHtml ?? "",
                    actionCallback: actionCallback,
                    dismissCallback: dismissCallback
                )
            }
        case .slideIn:
            guard let image = image else {
                Exponea.logger.log(.error, message: "In-app message type \(messageType) requires image!")
                throw InAppMessagePresenterError.unableToCreateView
            }
            if var payload {
                let updatedConfigs = payload.buttons.map { payload in
                    var updatedPayload = payload
                    updatedPayload.buttonConfig?.actionCallback = { type in
                        if let type {
                            actionCallback(type)
                        }
                    }
                    return updatedPayload
                }
                payload.buttons = updatedConfigs
                var updatedPayload = payload
                updatedPayload.closeConfig.dismissCallback = {
                    dismissCallback(true, .init(closeConfig: updatedPayload.closeConfig))
                }
                let slideInView = InAppMessageSlideInView(
                    payload: updatedPayload,
                    image: image,
                    actionCallback: actionCallback,
                    dismissCallback: dismissCallback
                )
                slideInView.setCloseTimeCallback = { [weak self] in
                    self?.setMessageTimeout(inAppMessageView: slideInView, timeout: timeout)
                }
                return slideInView
            } else if let oldPayload {
                return OldInAppMessageSlideInView(
                    payload: oldPayload,
                    image: image,
                    actionCallback: actionCallback,
                    dismissCallback: dismissCallback
                )
            }
        case .freeform:
            return InAppMessageWebView(
                    payload: payloadHtml!,
                    actionCallback: actionCallback,
                    dismissCallback: dismissCallback
            )
        }
        return InAppMessageWebView(
                payload: payloadHtml!,
                actionCallback: actionCallback,
                dismissCallback: dismissCallback
        )
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

    func getMaxScreenDimension() -> Int {
        return Int(max(
            UIScreen.main.bounds.size.width * UIScreen.main.scale,
            UIScreen.main.bounds.size.height * UIScreen.main.scale
        ))
    }

    static func getTopViewController(window: UIWindow? = nil) -> UIViewController? {
        let window = window ?? UIApplication.shared.keyWindow
        if var topController = window?.rootViewController {
            while let presentedViewController = topController.presentedViewController,
                  !presentedViewController.isBeingDismissed {
                topController = presentedViewController
            }
            return topController
        }
        return nil
    }
}

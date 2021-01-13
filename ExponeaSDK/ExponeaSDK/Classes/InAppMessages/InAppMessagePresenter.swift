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

    private var presenting = false

    init(window: UIWindow? = nil) {
        self.window = window
    }

    func presentInAppMessage(
        messageType: InAppMessageType,
        payload: InAppMessagePayload,
        delay: TimeInterval,
        timeout: TimeInterval?,
        imageData: Data?,
        actionCallback: @escaping (InAppMessagePayloadButton) -> Void,
        dismissCallback: @escaping () -> Void,
        presentedCallback: ((InAppMessageView?) -> Void)? = nil
    ) {
        Exponea.logger.log(
            .verbose,
            message: "Will attempt to present in-app message on main thread with delay \(delay)."
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            Exponea.shared.executeSafely {
                guard !self.presenting else {
                    Exponea.logger.log(.verbose, message: "Already presenting in-app message.")
                    presentedCallback?(nil)
                    return
                }
                var image: UIImage?
                if let imageData = imageData {
                    if let createdImage = self.createImage(
                        imageData: imageData,
                        maxDimensionInPixels: self.getMaxScreenDimension()
                    ) {
                        image = createdImage
                    } else {
                        Exponea.logger.log(.error, message: "Unable to create in-app message image")
                        presentedCallback?(nil)
                        return
                    }
                }

                guard let viewController = InAppMessagePresenter.getTopViewController(window: self.window) else {
                    Exponea.logger.log(.error, message: "Unable to present in-app message - no view controller")
                    presentedCallback?(nil)
                    return
                }

                do {
                    let inAppMessageView = try self.createInAppMessageView(
                        messageType: messageType,
                        payload: payload,
                        image: image,
                        actionCallback: { button in
                            self.presenting = false
                            actionCallback(button)
                        },
                        dismissCallback: {
                            self.presenting = false
                            dismissCallback()
                        }
                    )
                    try inAppMessageView.present(
                        in: viewController,
                        window: self.window ?? UIApplication.shared.keyWindow
                    )
                    self.presenting = true
                    Exponea.logger.log(.error, message: "In-app message presented.")
                    self.setMessageTimeout(inAppMessageView: inAppMessageView, timeout: timeout)
                    presentedCallback?(inAppMessageView)
                } catch {
                    Exponea.logger.log(.error, message: "Unable to present in-app message \(error)")
                    presentedCallback?(nil)
                }
            }
        }
    }

    func setMessageTimeout(inAppMessageView: InAppMessageView, timeout: TimeInterval?) {
        var messageTimeout = timeout
        if inAppMessageView is InAppMessageSlideInView {
            // slide-in has default 4 second timeout
            messageTimeout = messageTimeout ?? 4
        }
        if let messageTimeout = messageTimeout {
            DispatchQueue.main.asyncAfter(deadline: .now() + messageTimeout) {
                inAppMessageView.dismiss()
            }
        }
    }

    func createInAppMessageView(
        messageType: InAppMessageType,
        payload: InAppMessagePayload,
        image: UIImage?,
        actionCallback: @escaping (InAppMessagePayloadButton) -> Void,
        dismissCallback: @escaping () -> Void
    ) throws -> InAppMessageView {
        switch messageType {
        case .alert:
            return try InAppMessageAlertView(
                payload: payload,
                actionCallback: actionCallback,
                dismissCallback: dismissCallback
            )
        case .modal, .fullscreen:
            guard let image = image else {
                Exponea.logger.log(.error, message: "In-app message type \(messageType) requires image!")
                throw InAppMessagePresenterError.unableToCreateView
            }
            var fullscreen = false
            if case .fullscreen = messageType {
                fullscreen = true
            }
            return InAppMessageDialogView(
                payload: payload,
                image: image,
                actionCallback: actionCallback,
                dismissCallback: dismissCallback,
                fullscreen: fullscreen
            )
        case .slideIn:
            guard let image = image else {
                Exponea.logger.log(.error, message: "In-app message type \(messageType) requires image!")
                throw InAppMessagePresenterError.unableToCreateView
            }
            return InAppMessageSlideInView(
                payload: payload,
                image: image,
                actionCallback: actionCallback,
                dismissCallback: dismissCallback
            )
        }
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

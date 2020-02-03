//
//  InAppMessagePresenter.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 03/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

final class InAppMessagePresenter: InAppMessagePresenterType {
    enum InAppMessagePresenterError: Error {
        case unableToCreateViewController
    }

    private let window: UIWindow?

    private var presenting = false

    init(window: UIWindow? = nil) {
        self.window = window
    }

    func presentInAppMessage(
        messageType: InAppMessageType,
        payload: InAppMessagePayload,
        imageData: Data?,
        actionCallback: @escaping () -> Void,
        dismissCallback: @escaping () -> Void,
        presentedCallback: ((InAppMessageView?) -> Void)? = nil
    ) {
        guard !presenting else {
            presentedCallback?(nil)
            return
        }
        DispatchQueue.main.async {
            Exponea.shared.executeSafely {
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

                guard let viewController = self.getTopViewController() else {
                    Exponea.logger.log(.error, message: "Unable to present in-app message dialog - no view controller")
                    presentedCallback?(nil)
                    return
                }

                do {
                    let inAppMessageView = try self.createInAppMessageView(
                        messageType: messageType,
                        payload: payload,
                        image: image,
                        actionCallback: {
                            self.presenting = false
                            actionCallback()
                        },
                        dismissCallback: {
                            self.presenting = false
                            dismissCallback()
                        }
                    )
                    viewController.present(inAppMessageView.viewController, animated: true)
                    self.presenting = true
                    presentedCallback?(inAppMessageView)
                } catch {
                    presentedCallback?(nil)
                }
            }
        }
    }

    func createInAppMessageView(
        messageType: InAppMessageType,
        payload: InAppMessagePayload,
        image: UIImage?,
        actionCallback: @escaping () -> Void,
        dismissCallback: @escaping () -> Void
    ) throws -> InAppMessageView {
        switch messageType {
        case .alert:
            return InAppMessageAlertView(
                payload: payload,
                actionCallback: actionCallback,
                dismissCallback: dismissCallback
            )
        case .modal:
            guard let image = image else {
                Exponea.logger.log(.error, message: "In-app message type \(messageType) requires image!")
                throw InAppMessagePresenterError.unableToCreateViewController
            }
            return InAppMessageDialogView(
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
            return nil
        }
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ] as CFDictionary
        guard let downsampledCGImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
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

    func getTopViewController() -> UIViewController? {
        let window = self.window ?? UIApplication.shared.keyWindow
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

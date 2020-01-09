//
//  InAppMessageDialogPresenter.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 03/12/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

class InAppMessageDialogPresenter: InAppMessageDialogPresenterType {
    private let window: UIWindow?

    private var presenting = false

    init(window: UIWindow? = nil) {
        self.window = window
    }

    func presentInAppMessage(
        payload: InAppMessagePayload,
        imageData: Data,
        actionCallback: @escaping () -> Void,
        dismissCallback: @escaping () -> Void,
        presentedCallback: ((InAppMessageDialogViewController?) -> Void)? = nil
    ) {
        guard !presenting else {
            presentedCallback?(nil)
            return
        }
        DispatchQueue.main.async {
            let storyboard = UIStoryboard(
                name: "InAppMessageDialog",
                bundle: Bundle(for: ExponeaSDK.Exponea.self)
            )
            guard let dialogVC = storyboard.instantiateViewController(withIdentifier: "InAppMessageDialog")
                    as? InAppMessageDialogViewController else {
                Exponea.logger.log(.error, message: "Unable to instantiate in-app message view controller")
                presentedCallback?(nil)
                return
            }
            guard let image = self.createImage(
                imageData: imageData,
                maxDimensionInPixels: self.getMaxScreenDimension()
            ) else {
                Exponea.logger.log(.error, message: "Unable to create in-app message image")
                presentedCallback?(nil)
                return
            }
            dialogVC.payload = payload
            dialogVC.image = image
            dialogVC.actionCallback = {
                self.presenting = false
                actionCallback()
            }
            dialogVC.dismissCallback = {
                self.presenting = false
                dismissCallback()
            }

            guard let viewController = self.getTopViewController() else {
                Exponea.logger.log(.error, message: "Unable to present in-app message dialog - no view controller")
                presentedCallback?(nil)
                return
            }
            viewController.present(dialogVC, animated: true)
            self.presenting = true
            presentedCallback?(dialogVC)
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

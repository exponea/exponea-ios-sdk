//
//  ImageDownloader.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 02/01/2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation
import UIKit

struct ImageUtils {

    /// Downloads image from given URL.
    /// Method has to be called within background thread due to sync implementation.
    public static func tryDownloadImage(_ imageSource: String?) -> Data? {
        return FileUtils.tryDownloadFile(imageSource)
    }

    /// Transforms full content of image Data to UIImage that is downsampled by 'maxDimensionInPixels' param
    public static func createImage(imageData: Data, maxDimensionInPixels: Int) -> UIImage? {
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

//
//  GifHelper.swift
//  ExponeaSDK
//
//  Created by Ankmara on 16.08.2024.
//  Copyright © 2024 Exponea. All rights reserved.
//
//  Portions derived from SwiftGif
//  (https://github.com/swiftgif/SwiftGif/blob/master/SwiftGifCommon/UIImage%2BGif.swift)
//
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Arne Bahlo
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import UIKit
import ImageIO

/// Shared per-frame delay extraction for GIF and WebP via ImageIO metadata.
public enum ImageIOFrameDelay {
    public static let defaultDelay: Double = 0.1

    public static func delaySeconds(from properties: [CFString: Any]) -> Double? {
        if let gifDict = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] {
            if let unclamped = gifDict[kCGImagePropertyGIFUnclampedDelayTime] as? Double, unclamped > 0 {
                return unclamped
            }
            if let clamped = gifDict[kCGImagePropertyGIFDelayTime] as? Double, clamped > 0 {
                return clamped
            }
        }
        if let webpDict = properties[kCGImagePropertyWebPDictionary] as? [CFString: Any] {
            if let unclamped = webpDict[kCGImagePropertyWebPUnclampedDelayTime] as? Double, unclamped > 0 {
                return unclamped
            }
            if let clamped = webpDict[kCGImagePropertyWebPDelayTime] as? Double, clamped > 0 {
                return clamped
            }
        }
        return nil
    }

    public static func delaySeconds(at index: Int, source: CGImageSource) -> Double {
        guard let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil),
              let properties = cfProperties as? [CFString: Any],
              let delay = delaySeconds(from: properties) else {
            return defaultDelay
        }
        return delay
    }
}

extension UIImage {
    public class func gifImageWithData(_ data: Data, maxPixelSize: Int? = nil) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetCount(source) > 1 else {
            Exponea.logger.log(.verbose, message: "Invalid image data")
            return nil
        }
        return UIImage.animatedImageWithSourceCustom(source, maxPixelSize: maxPixelSize)
    }

    /// Backward-compatible alias for push-notification content decoding and tests.
    public class func gif(data: Data, maxPixelSize: Int? = nil) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        return UIImage.animatedImageWithSourceCustom(source, maxPixelSize: maxPixelSize)
    }

    public class func hasMultipleFrames(data: Data) -> Bool {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return false
        }
        return CGImageSourceGetCount(source) > 1
    }

    public class func isGif(data: Data) -> Bool {
        hasMultipleFrames(data: data)
    }

    class func delayForImageAtIndexCustom(_ index: Int, source: CGImageSource) -> Double {
        ImageIOFrameDelay.delaySeconds(at: index, source: source)
    }

    class func gcdForPairCustom(_ a: Int?, _ b: Int?) -> Int {
        var a = a
        var b = b
        if b == nil || a == nil {
            if b != nil {
                return b!
            } else if a != nil {
                return a!
            } else {
                return 0
            }
        }
        if a! < b! {
            let c = a
            a = b
            b = c
        }
        var rest: Int
        while true {
            rest = a! % b!
            if rest == 0 {
                return b!
            } else {
                a = b
                b = rest
            }
        }
    }

    class func gcdForArrayCustom(_ array: [Int]) -> Int {
        if array.isEmpty {
            return 1
        }
        var gcd = array[0]
        for val in array {
            gcd = UIImage.gcdForPairCustom(val, gcd)
        }
        return gcd
    }

    class func animatedImageWithSourceCustom(_ source: CGImageSource, maxPixelSize: Int? = nil) -> UIImage? {
        let count = CGImageSourceGetCount(source)
        var images = [CGImage]()
        var delays = [Int]()

        let thumbnailOptions: CFDictionary? = maxPixelSize.map { size in
            [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: size,
                kCGImageSourceCreateThumbnailWithTransform: true
            ] as CFDictionary
        }

        for i in 0..<count {
            let image: CGImage?
            if let options = thumbnailOptions {
                image = CGImageSourceCreateThumbnailAtIndex(source, i, options)
            } else {
                image = CGImageSourceCreateImageAtIndex(source, i, nil)
            }
            guard let image else {
                continue
            }
            images.append(image)
            let delaySeconds = delayForImageAtIndexCustom(Int(i), source: source)
            delays.append(Int(delaySeconds * 1000.0))
        }
        guard !images.isEmpty else {
            return nil
        }
        let duration: Int = {
            var sum = 0
            for val: Int in delays {
                sum += val
            }
            return sum
        }()
        let gcd = gcdForArrayCustom(delays)
        var frames = [UIImage]()
        for i in 0..<images.count {
            let frame = UIImage(cgImage: images[i])
            let frameCount = Int(delays[i] / gcd)
            for _ in 0..<frameCount {
                frames.append(frame)
            }
        }
        let animation = UIImage.animatedImage(with: frames,
            duration: Double(duration) / 1000.0)
        return animation
    }
}

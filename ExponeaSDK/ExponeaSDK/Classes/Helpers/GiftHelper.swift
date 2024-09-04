//
//  GiftHelper.swift
//  ExponeaSDK
//
//  Created by Ankmara on 16.08.2024.
//  Copyright © 2024 Exponea. All rights reserved.
//

import UIKit
import ImageIO

private func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

extension UIImage {
    public class func gifImageWithData(_ data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil), isGif(data: data) else {
            Exponea.logger.log(.error, message: "Invalid image data")
            return nil
        }
        return UIImage.animatedImageWithSourceCustom(source)
    }
    
    public class func gifImageWithURL(_ gifUrl: String) -> UIImage? {
        guard let url: URL = URL(string: gifUrl) else {
            Exponea.logger.log(.error, message: "[GiftHelper] Invalid image url \(gifUrl)")
            return nil
        }
        guard isGif(imageUrl: url), let imageData = try? Data(contentsOf: url) else {
            Exponea.logger.log(.verbose, message: "[GiftHelper] Image \(gifUrl) is not a gif")
            return nil
        }
        return gifImageWithData(imageData)
    }
    
    private class func isGif(imageUrl: URL) -> Bool {
        if let data = try? Data(contentsOf: imageUrl) {
            return isGif(data: data)
        }
        return false
    }
    
    public class func isGif(data: Data) -> Bool {
        if let source = CGImageSourceCreateWithData(data as CFData, nil) {
            let count = CGImageSourceGetCount(source)
            return count > 1
        }
        return false
    }

    class func delayForImageAtIndexCustom(_ index: Int, source: CGImageSource!) -> Double {
        var delay = 0.1
        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        let gifProperties: CFDictionary = unsafeBitCast(
            CFDictionaryGetValue(cfProperties,
                Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque()),
            to: CFDictionary.self)
        var delayObject: AnyObject = unsafeBitCast(
            CFDictionaryGetValue(gifProperties,
                Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()),
            to: AnyObject.self)
        if delayObject.doubleValue == 0 {
            delayObject = unsafeBitCast(CFDictionaryGetValue(gifProperties,
                Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()), to: AnyObject.self)
        }
        delay = delayObject as! Double
        if delay < 0.1 {
            delay = 0.1
        }
        return delay
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
        if a < b {
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

    class func animatedImageWithSourceCustom(_ source: CGImageSource) -> UIImage? {
        let count = CGImageSourceGetCount(source)
        var images = [CGImage]()
        var delays = [Int]()
        for i in 0..<count {
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(image)
            }
            let delaySeconds = delayForImageAtIndexCustom(Int(i),
                source: source)
            delays.append(Int(delaySeconds * 1000.0)) // Seconds to ms
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
        var frame: UIImage
        var frameCount: Int
        for i in 0..<count {
            frame = UIImage(cgImage: images[Int(i)])
            frameCount = Int(delays[Int(i)] / gcd)
            for _ in 0..<frameCount {
                frames.append(frame)
            }
        }
        let animation = UIImage.animatedImage(with: frames,
            duration: Double(duration) / 1000.0)
        return animation
    }
}

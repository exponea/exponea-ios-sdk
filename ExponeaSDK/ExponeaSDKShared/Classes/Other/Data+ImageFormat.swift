//
//  Data+ImageFormat.swift
//  ExponeaSDKShared
//
//  Copyright © 2026 Exponea. All rights reserved.
//

import Foundation
import ImageIO
import UIKit

private final class InAppImageSizeCacheKey: NSObject {
    private let dataHash: Int
    private let count: Int

    init(data: Data) {
        var hasher = Hasher()
        hasher.combine(data)
        self.dataHash = hasher.finalize()
        self.count = data.count
    }

    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(dataHash)
        hasher.combine(count)
        return hasher.finalize()
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? InAppImageSizeCacheKey else {
            return false
        }
        return dataHash == other.dataHash && count == other.count
    }
}

private enum InAppImageSizeCache {
    private static let firstFrameSizeCache = NSCache<InAppImageSizeCacheKey, NSValue>()

    static func firstFrameSize(for data: Data, compute: () -> CGSize?) -> CGSize? {
        let key = InAppImageSizeCacheKey(data: data)
        if let cached = firstFrameSizeCache.object(forKey: key) {
            return cached.cgSizeValue
        }
        guard let size = compute(), size.width > 0, size.height > 0 else {
            return nil
        }
        firstFrameSizeCache.setObject(NSValue(cgSize: size), forKey: key)
        return size
    }
}

private func pixelDimensions(from properties: [CFString: Any]) -> (width: Int, height: Int)? {
    let widthValue = properties[kCGImagePropertyPixelWidth]
    let heightValue = properties[kCGImagePropertyPixelHeight]
    let width: Int?
    let height: Int?

    switch widthValue {
    case let value as Int:
        width = value
    case let value as CGFloat:
        width = Int(value)
    case let value as Double:
        width = Int(value)
    case let value as NSNumber:
        width = value.intValue
    default:
        width = nil
    }

    switch heightValue {
    case let value as Int:
        height = value
    case let value as CGFloat:
        height = Int(value)
    case let value as Double:
        height = Int(value)
    case let value as NSNumber:
        height = value.intValue
    default:
        height = nil
    }

    guard let width, let height, width > 0, height > 0 else {
        return nil
    }
    return (width, height)
}

extension Data {
    /// GIF87a and GIF89a both start with "GIF8".
    public var isGif: Bool {
        starts(with: [0x47, 0x49, 0x46, 0x38])
    }

    /// Any WebP variant: RIFF container (bytes 0-3) + WEBP signature (bytes 8-11).
    /// Covers VP8 (lossy), VP8L (lossless), and VP8X (extended/animated).
    var isWebP: Bool {
        count >= 12
            && self[startIndex]      == 0x52
            && self[startIndex + 1]  == 0x49
            && self[startIndex + 2]  == 0x46
            && self[startIndex + 3]  == 0x46
            && self[startIndex + 8]  == 0x57
            && self[startIndex + 9]  == 0x45
            && self[startIndex + 10] == 0x42
            && self[startIndex + 11] == 0x50
    }

    /// Extended WebP (VP8X chunk at bytes 12-15). VP8X covers animation,
    /// alpha, ICC, and EXIF. False-positive on non-animated VP8X is harmless:
    /// CGImageSource produces a single-frame source and the animated decoder
    /// handles it correctly. On iOS 14+ CGImageSource supports WebP natively.
    public var isExtendedWebP: Bool {
        isWebP
            && count >= 16
            && self[startIndex + 12] == 0x56
            && self[startIndex + 13] == 0x50
            && self[startIndex + 14] == 0x38
            && self[startIndex + 15] == 0x58
    }

    /// Multi-frame GIF or animated WebP data should be rendered via `UIAnimatedImageView`
    /// instead of static `UIImage(data:)` or `UIImage.animatedImage(with:duration:)`.
    public var isInAppAnimatedImage: Bool {
        (isGif || isExtendedWebP) && UIImage.hasMultipleFrames(data: self)
    }

    /// Reads pixel dimensions from the first frame's ImageIO metadata and converts to points using
    /// the main screen scale, matching `UIImage(cgImage:scale:orientation:)` as used by `UIAnimatedImageView`.
    public var inAppImageFirstFrameSize: CGSize? {
        InAppImageSizeCache.firstFrameSize(for: self) {
            guard let source = CGImageSourceCreateWithData(self as CFData, nil),
                  let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
                  let dimensions = pixelDimensions(from: properties) else {
                return nil
            }
            let scale = UIScreen.main.scale
            return CGSize(
                width: CGFloat(dimensions.width) / scale,
                height: CGFloat(dimensions.height) / scale
            )
        }
    }
}

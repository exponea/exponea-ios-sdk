//
//  GifImageDecodingSpec.swift
//  ExponeaSDKTests
//
//  Copyright © 2026 Exponea. All rights reserved.
//

import Nimble
import Quick
import UIKit
import ImageIO

@testable import ExponeaSDK
@testable import ExponeaSDKShared

final class GifImageDecodingSpec: QuickSpec {

    // Proper multi-frame GIF89a: 1x1 pixel, 2 frames (red + blue), built from raw bytes
    // Internal (not private) so other specs, e.g. InAppMessageImageViewSpec, can reuse these fixtures.
    static func makeTwoFrameGifData(frameDelayHundredths: UInt8 = 0x0A) -> Data {
        // GIF89a header + logical screen descriptor + GCE + frame1 + GCE + frame2 + trailer
        let bytes: [UInt8] = [
            // Header: GIF89a
            0x47, 0x49, 0x46, 0x38, 0x39, 0x61,
            // Logical Screen Descriptor: 1x1, 256 colors, no GCT
            0x01, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00,
            // Application Extension (NETSCAPE2.0 for looping)
            0x21, 0xFF, 0x0B,
            0x4E, 0x45, 0x54, 0x53, 0x43, 0x41, 0x50, 0x45, 0x32, 0x2E, 0x30,
            0x03, 0x01, 0x00, 0x00, 0x00,
            // Frame 1: GCE
            0x21, 0xF9, 0x04, 0x00, frameDelayHundredths, 0x00, 0x00, 0x00,
            // Image Descriptor: 1x1, local color table (2 colors)
            0x2C, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x81,
            // Local Color Table (4 entries for 2-bit)
            0xFF, 0x00, 0x00,  // red
            0x00, 0x00, 0x00,
            0x00, 0x00, 0x00,
            0x00, 0x00, 0x00,
            // Image Data
            0x02, 0x02, 0x44, 0x01, 0x00,
            // Frame 2: GCE
            0x21, 0xF9, 0x04, 0x00, frameDelayHundredths, 0x00, 0x00, 0x00,
            // Image Descriptor: 1x1, local color table (2 colors)
            0x2C, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x81,
            // Local Color Table (4 entries for 2-bit)
            0x00, 0x00, 0xFF,  // blue
            0x00, 0x00, 0x00,
            0x00, 0x00, 0x00,
            0x00, 0x00, 0x00,
            // Image Data
            0x02, 0x02, 0x44, 0x01, 0x00,
            // Trailer
            0x3B
        ]
        return Data(bytes)
    }

    /// Builds a multi-frame GIF by repeating the 1x1 frame block from `makeTwoFrameGifData`.
    static func makeMultiFrameGifData(frameCount: Int) -> Data {
        precondition(frameCount >= 2)
        let singleFrameBlock: [UInt8] = [
            0x21, 0xF9, 0x04, 0x00, 0x0A, 0x00, 0x00, 0x00,
            0x2C, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x81,
            0xFF, 0x00, 0x00,
            0x00, 0x00, 0x00,
            0x00, 0x00, 0x00,
            0x00, 0x00, 0x00,
            0x02, 0x02, 0x44, 0x01, 0x00
        ]
        var bytes: [UInt8] = [
            0x47, 0x49, 0x46, 0x38, 0x39, 0x61,
            0x01, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00,
            0x21, 0xFF, 0x0B,
            0x4E, 0x45, 0x54, 0x53, 0x43, 0x41, 0x50, 0x45, 0x32, 0x2E, 0x30,
            0x03, 0x01, 0x00, 0x00, 0x00
        ]
        for _ in 0..<frameCount {
            bytes.append(contentsOf: singleFrameBlock)
        }
        bytes.append(0x3B)
        return Data(bytes)
    }

    static func makeMinimalPngData() -> Data {
        UIGraphicsBeginImageContext(CGSize(width: 2, height: 2))
        UIColor.red.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: 2, height: 2))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image.pngData()!
    }

    static func makeMinimalJpegData() -> Data {
        UIGraphicsBeginImageContext(CGSize(width: 2, height: 2))
        UIColor.blue.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: 2, height: 2))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image.jpegData(compressionQuality: 0.9)!
    }

    // Minimal animated WebP header for magic-bytes detection.
    // Real WebP files contain additional VP8X flag bytes, ANIM chunk, and ANMF frames,
    // but only the first 16 bytes are needed to verify the detection logic.
    static func makeAnimatedWebPHeader() -> Data {
        let bytes: [UInt8] = [
            // RIFF container
            0x52, 0x49, 0x46, 0x46,
            // Little-endian file size minus 8 (placeholder)
            0x00, 0x00, 0x00, 0x00,
            // WEBP signature
            0x57, 0x45, 0x42, 0x50,
            // VP8X extended chunk (animation / alpha / ICC)
            0x56, 0x50, 0x38, 0x58
        ]
        return Data(bytes)
    }

    // Static WebP using the basic VP8 chunk (lossy single frame). Should NOT be detected as animated.
    static func makeStaticWebPHeader() -> Data {
        let bytes: [UInt8] = [
            0x52, 0x49, 0x46, 0x46,
            0x00, 0x00, 0x00, 0x00,
            0x57, 0x45, 0x42, 0x50,
            0x56, 0x50, 0x38, 0x20  // "VP8 " (static lossy)
        ]
        return Data(bytes)
    }

    private static func suggestedFilename(for data: Data) -> String {
        // Animated formats (GIF and extended WebP) use .gif so that
        // UNNotificationAttachment preserves animation data. WebP cannot
        // use .webp (error 101), but .gif is accepted and keeps the raw bytes.
        if data.isGif || data.isExtendedWebP { return "image.gif" }
        return "image.png"
    }

    override func spec() {
        let gifData = GifImageDecodingSpec.makeTwoFrameGifData()
        let pngData = GifImageDecodingSpec.makeMinimalPngData()
        let jpegData = GifImageDecodingSpec.makeMinimalJpegData()
        let animatedWebPData = GifImageDecodingSpec.makeAnimatedWebPHeader()
        let staticWebPData = GifImageDecodingSpec.makeStaticWebPHeader()

        describe("Data.isGif detection") {
            it("detects GIF data correctly") {
                expect(gifData.isGif).to(beTrue())
            }

            it("rejects PNG data") {
                expect(pngData.isGif).to(beFalse())
            }

            it("rejects JPEG data") {
                expect(jpegData.isGif).to(beFalse())
            }

            it("rejects empty data") {
                expect(Data().isGif).to(beFalse())
            }
        }

        describe("UIImage.gif(data:) from ExponeaSDKShared") {
            it("produces an animated image for multi-frame GIF data") {
                let image = UIImage.gif(data: gifData)
                expect(image).toNot(beNil())
                expect(image?.images).toNot(beNil())
                expect(image?.images?.count).to(beGreaterThan(1))
            }

            it("does not return nil for PNG data") {
                // UIImage.gif(data:) does NOT validate GIF format --
                // it succeeds for any valid image, producing a single-frame
                // "animated" image. This confirms magic-bytes detection is required.
                let image = UIImage.gif(data: pngData)
                expect(image).toNot(beNil())
            }

            it("does not return nil for JPEG data") {
                let image = UIImage.gif(data: jpegData)
                expect(image).toNot(beNil())
            }
        }

        describe("UIImage(data:) static image fallback") {
            it("produces a non-animated image for PNG data") {
                let image = UIImage(data: pngData)
                expect(image).toNot(beNil())
                expect(image?.images).to(beNil())
            }

            it("produces a non-animated image for JPEG data") {
                let image = UIImage(data: jpegData)
                expect(image).toNot(beNil())
                expect(image?.images).to(beNil())
            }

            it("produces a static first frame for GIF data") {
                let image = UIImage(data: gifData)
                expect(image).toNot(beNil())
                expect(image?.images).to(beNil())
            }
        }

        describe("animated UIImage properties for aspect ratio calculation") {
            it("has a valid non-zero size") {
                let image = UIImage.gif(data: gifData)
                expect(image).toNot(beNil())
                expect(image!.size.width).to(beGreaterThan(0))
                expect(image!.size.height).to(beGreaterThan(0))
            }

            it("size matches the first frame dimensions") {
                let animatedImage = UIImage.gif(data: gifData)
                let staticImage = UIImage(data: gifData)
                expect(animatedImage).toNot(beNil())
                expect(staticImage).toNot(beNil())
                expect(animatedImage!.size).to(equal(staticImage!.size))
            }
        }

        describe("downsampled GIF decoding via maxPixelSize") {
            it("produces an animated image when maxPixelSize is specified") {
                let image = UIImage.gif(data: gifData, maxPixelSize: 1)
                expect(image).toNot(beNil())
                expect(image?.images).toNot(beNil())
                expect(image?.images?.count).to(beGreaterThan(1))
            }

            it("produces an animated image at full resolution when maxPixelSize is nil") {
                let image = UIImage.gif(data: gifData, maxPixelSize: nil)
                expect(image).toNot(beNil())
                expect(image?.images).toNot(beNil())
            }

            it("downsamples large frames to fit maxPixelSize") {
                let largeSize = CGSize(width: 200, height: 100)
                UIGraphicsBeginImageContext(largeSize)
                UIColor.green.setFill()
                UIRectFill(CGRect(origin: .zero, size: largeSize))
                let largeImage = UIGraphicsGetImageFromCurrentImageContext()!
                UIGraphicsEndImageContext()
                let largePngData = largeImage.pngData()!

                let fullImage = UIImage.gif(data: largePngData, maxPixelSize: nil)
                let downsampledImage = UIImage.gif(data: largePngData, maxPixelSize: 50)

                expect(fullImage).toNot(beNil())
                expect(downsampledImage).toNot(beNil())
                expect(fullImage!.size.width).to(equal(200))
                expect(downsampledImage!.size.width).to(beLessThanOrEqualTo(50))
                expect(downsampledImage!.size.height).to(beLessThanOrEqualTo(50))
            }

            it("preserves aspect ratio when downsampling") {
                let wideSize = CGSize(width: 200, height: 100)
                UIGraphicsBeginImageContext(wideSize)
                UIColor.red.setFill()
                UIRectFill(CGRect(origin: .zero, size: wideSize))
                let wideImage = UIGraphicsGetImageFromCurrentImageContext()!
                UIGraphicsEndImageContext()
                let widePngData = wideImage.pngData()!

                let downsampled = UIImage.gif(data: widePngData, maxPixelSize: 100)
                expect(downsampled).toNot(beNil())

                let aspect = downsampled!.size.height / downsampled!.size.width
                let originalAspect = CGFloat(100) / CGFloat(200)
                expect(aspect).to(beCloseTo(originalAspect, within: 0.01))
            }

            it("preserves sub-0.1s frame delays for smooth push notification animation") {
                // 4 hundredths of a second per frame (common for ~25 fps GIFs).
                // Clamping to 0.1s (old GiftHelper behavior) would yield 0.2s total for 2 frames.
                let fastGifData = GifImageDecodingSpec.makeTwoFrameGifData(frameDelayHundredths: 0x04)
                let image = UIImage.gif(data: fastGifData)
                expect(image).toNot(beNil())
                expect(image!.duration).to(beCloseTo(0.08, within: 0.02))
            }
        }

        describe("ImageIOFrameDelay") {
            it("reads GIF per-frame delay from ImageIO properties") {
                let properties: [CFString: Any] = [
                    kCGImagePropertyGIFDictionary: [
                        kCGImagePropertyGIFDelayTime: 0.25
                    ]
                ]
                expect(ImageIOFrameDelay.delaySeconds(from: properties)).to(equal(0.25))
            }

            it("reads WebP per-frame delay from ImageIO properties") {
                let properties: [CFString: Any] = [
                    kCGImagePropertyWebPDictionary: [
                        kCGImagePropertyWebPDelayTime: 0.5
                    ]
                ]
                expect(ImageIOFrameDelay.delaySeconds(from: properties)).to(equal(0.5))
            }

            it("prefers WebP unclamped delay over clamped delay") {
                let properties: [CFString: Any] = [
                    kCGImagePropertyWebPDictionary: [
                        kCGImagePropertyWebPUnclampedDelayTime: 0.33,
                        kCGImagePropertyWebPDelayTime: 0.1
                    ]
                ]
                expect(ImageIOFrameDelay.delaySeconds(from: properties)).to(equal(0.33))
            }
        }

        describe("combined decode path (matching createImageView logic)") {
            it("produces animated image for GIF data") {
                let isAnimated = gifData.isGif || gifData.isExtendedWebP
                let image = (isAnimated ? UIImage.gif(data: gifData) : nil) ?? UIImage(data: gifData)
                expect(image).toNot(beNil())
                expect(image?.images).toNot(beNil())
                expect(image?.images?.count).to(beGreaterThan(1))
            }

            it("produces static image for PNG data") {
                let isAnimated = pngData.isGif || pngData.isExtendedWebP
                let image = (isAnimated ? UIImage.gif(data: pngData) : nil) ?? UIImage(data: pngData)
                expect(image).toNot(beNil())
                expect(image?.images).to(beNil())
            }

            it("produces static image for JPEG data") {
                let isAnimated = jpegData.isGif || jpegData.isExtendedWebP
                let image = (isAnimated ? UIImage.gif(data: jpegData) : nil) ?? UIImage(data: jpegData)
                expect(image).toNot(beNil())
                expect(image?.images).to(beNil())
            }
        }

        describe("Data.isExtendedWebP detection") {
            it("detects extended WebP (VP8X chunk) correctly") {
                expect(animatedWebPData.isExtendedWebP).to(beTrue())
            }

            it("rejects static WebP (VP8 chunk)") {
                expect(staticWebPData.isExtendedWebP).to(beFalse())
            }

            it("rejects GIF data") {
                expect(gifData.isExtendedWebP).to(beFalse())
            }

            it("rejects PNG data") {
                expect(pngData.isExtendedWebP).to(beFalse())
            }

            it("rejects JPEG data") {
                expect(jpegData.isExtendedWebP).to(beFalse())
            }

            it("rejects empty data") {
                expect(Data().isExtendedWebP).to(beFalse())
            }

            it("rejects data shorter than 16 bytes") {
                let shortData = Data([0x52, 0x49, 0x46, 0x46, 0x00, 0x00, 0x00, 0x00, 0x57, 0x45, 0x42, 0x50])
                expect(shortData.isExtendedWebP).to(beFalse())
            }
        }

        describe("Data.isWebP detection") {
            it("detects extended WebP (VP8X)") {
                expect(animatedWebPData.isWebP).to(beTrue())
            }

            it("detects static WebP (VP8)") {
                expect(staticWebPData.isWebP).to(beTrue())
            }

            it("rejects GIF data") {
                expect(gifData.isWebP).to(beFalse())
            }

            it("rejects PNG data") {
                expect(pngData.isWebP).to(beFalse())
            }

            it("rejects empty data") {
                expect(Data().isWebP).to(beFalse())
            }
        }

        describe("attachment filename selection (matching createContent logic)") {
            it("selects image.gif for GIF data") {
                expect(GifImageDecodingSpec.suggestedFilename(for: gifData)).to(equal("image.gif"))
            }

            it("selects image.gif for animated WebP data (preserves animation via .gif UTI)") {
                expect(GifImageDecodingSpec.suggestedFilename(for: animatedWebPData)).to(equal("image.gif"))
            }

            it("selects image.png for static WebP data (WebP unsupported by UNNotificationAttachment)") {
                expect(GifImageDecodingSpec.suggestedFilename(for: staticWebPData)).to(equal("image.png"))
            }

            it("selects image.png for PNG data") {
                expect(GifImageDecodingSpec.suggestedFilename(for: pngData)).to(equal("image.png"))
            }

            it("selects image.png for JPEG data") {
                expect(GifImageDecodingSpec.suggestedFilename(for: jpegData)).to(equal("image.png"))
            }

            it("selects image.png for empty data") {
                expect(GifImageDecodingSpec.suggestedFilename(for: Data())).to(equal("image.png"))
            }
        }

        describe("animated image source routing (matching combined createImageView logic)") {
            it("routes GIF data through the animated decoder") {
                let isAnimated = gifData.isGif || gifData.isExtendedWebP
                expect(isAnimated).to(beTrue())
            }

            it("routes extended WebP data through the animated decoder") {
                let isAnimated = animatedWebPData.isGif || animatedWebPData.isExtendedWebP
                expect(isAnimated).to(beTrue())
            }

            it("does not route static WebP data through the animated decoder") {
                let isAnimated = staticWebPData.isGif || staticWebPData.isExtendedWebP
                expect(isAnimated).to(beFalse())
            }

            it("does not route PNG data through the animated decoder") {
                let isAnimated = pngData.isGif || pngData.isExtendedWebP
                expect(isAnimated).to(beFalse())
            }
        }

        describe("file-system round-trip preserves magic bytes for both formats") {
            it("preserves GIF magic bytes when written as .gif and read back") {
                let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent(UUID().uuidString, isDirectory: true)
                try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
                defer { try? FileManager.default.removeItem(at: tempDir) }

                let fileURL = tempDir.appendingPathComponent("image.gif")
                try? gifData.write(to: fileURL)

                guard let reloaded = try? Data(contentsOf: fileURL) else {
                    fail("Failed to read back written GIF data")
                    return
                }
                expect(reloaded.starts(with: [0x47, 0x49, 0x46, 0x38])).to(beTrue())

                let image = UIImage.gif(data: reloaded)
                expect(image).toNot(beNil())
                expect(image?.images?.count).to(beGreaterThan(1))
            }

            it("preserves WebP magic bytes when written as .gif and read back") {
                // UNNotificationAttachment does not support .webp, so extended
                // WebP data is saved as .gif in production. Verify that the raw
                // bytes survive the round-trip regardless of the extension.
                let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent(UUID().uuidString, isDirectory: true)
                try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
                defer { try? FileManager.default.removeItem(at: tempDir) }

                let fileURL = tempDir.appendingPathComponent("image.gif")
                try? animatedWebPData.write(to: fileURL)

                guard let reloaded = try? Data(contentsOf: fileURL) else {
                    fail("Failed to read back written WebP data")
                    return
                }
                expect(reloaded.isExtendedWebP).to(beTrue())
            }
        }

        describe("Data.inAppImageFirstFrameSize") {
            it("returns point dimensions consistent with UIAnimatedImageView frame decode") {
                guard let source = CGImageSourceCreateWithData(pngData as CFData, nil),
                      let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                    fail("Failed to decode PNG fixture")
                    return
                }
                let expectedSize = UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up).size
                let metadataSize = pngData.inAppImageFirstFrameSize
                expect(metadataSize).toNot(beNil())
                expect(metadataSize?.width).to(equal(expectedSize.width))
                expect(metadataSize?.height).to(equal(expectedSize.height))
            }

            it("returns point dimensions for multi-frame GIF metadata") {
                guard let source = CGImageSourceCreateWithData(gifData as CFData, nil),
                      let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                    fail("Failed to decode GIF fixture")
                    return
                }
                let expectedSize = UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up).size
                let metadataSize = gifData.inAppImageFirstFrameSize
                expect(metadataSize).toNot(beNil())
                expect(metadataSize?.width).to(equal(expectedSize.width))
                expect(metadataSize?.height).to(equal(expectedSize.height))
            }

            it("returns the same cached first-frame size on repeated access") {
                let first = gifData.inAppImageFirstFrameSize
                let second = gifData.inAppImageFirstFrameSize
                expect(first).to(equal(second))
            }
        }

        describe("ARC regression — repeated GIF decode") {
            it("decodes a multi-frame GIF many times without crashing") {
                for _ in 0..<100 {
                    let image = UIImage.gifImageWithData(gifData)
                    expect(image).toNot(beNil())
                    expect(image?.images?.count).to(beGreaterThan(1))
                }
            }

            it("decodes via gifImageWithData with downsampling in a loop") {
                for _ in 0..<50 {
                    let image = UIImage.gifImageWithData(gifData, maxPixelSize: 10)
                    expect(image).toNot(beNil())
                    expect(image?.images?.count).to(beGreaterThan(1))
                }
            }
        }
    }
}

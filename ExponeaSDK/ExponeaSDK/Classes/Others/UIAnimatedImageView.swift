//
//  UIAnimatedImageView.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 26/09/2025.
//  Copyright © 2025 Exponea. All rights reserved.
//

import UIKit
import ImageIO
import MobileCoreServices
#if canImport(ExponeaSDKShared)
import ExponeaSDKShared
#endif

class UIAnimatedImageView: UIImageView {

    private var imageSource: CGImageSource?
    private var frameCount: Int = 0
    private var frameDurations: [Double] = []
    private var displayLink: CADisplayLink?
    private var currentFrameIndex: Int = 0
    private var accumulator: Double = 0
    private var lastTimestamp: CFTimeInterval = 0

    func loadImage(imageData: Data) {
        clear()
        imageSource = CGImageSourceCreateWithData(imageData as CFData, nil)
        guard let src = imageSource else { return }
        frameCount = CGImageSourceGetCount(src)
        showFrame(at: 0)
        guard frameCount > 1 else {
            return
        }
        frameDurations = (0..<frameCount).map { i in
            guard let props = CGImageSourceCopyPropertiesAtIndex(src, i, nil) as? [CFString: Any] else {
                return ImageIOFrameDelay.defaultDelay
            }
            return ImageIOFrameDelay.delaySeconds(from: props) ?? ImageIOFrameDelay.defaultDelay
        }
        displayLink = CADisplayLink(target: self, selector: #selector(updateFrame))
        displayLink?.add(to: .main, forMode: .common)
    }

    deinit {
        displayLink?.invalidate()
    }

    func clear() {
        displayLink?.invalidate()
        displayLink = nil
        imageSource = nil
        frameDurations.removeAll()
        frameCount = 0
        currentFrameIndex = 0
        accumulator = 0
        image = nil
    }

    private func showFrame(at index: Int) {
        guard let src = imageSource,
              let cgImg = CGImageSourceCreateImageAtIndex(src, index, nil) else { return }
        self.image = UIImage(cgImage: cgImg)
    }

    @objc private func updateFrame(link: CADisplayLink) {
        if lastTimestamp == 0 { lastTimestamp = link.timestamp }
        let delta = link.timestamp - lastTimestamp
        lastTimestamp = link.timestamp
        accumulator += delta

        let frameDuration = frameDurations[currentFrameIndex]
        if accumulator >= frameDuration {
            accumulator -= frameDuration
            currentFrameIndex = (currentFrameIndex + 1) % frameCount
            showFrame(at: currentFrameIndex)
        }
    }
}

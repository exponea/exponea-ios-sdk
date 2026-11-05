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
    /// True while the view itself sets `image` (a decoded frame or `nil` from `clear()`),
    /// so subclasses can tell these changes apart from images set from outside.
    private(set) var isSettingOwnImage = false
    /// True while an animated image is playing, that is, while its display link runs and isn't paused.
    var isAnimatingFrames: Bool {
        guard let displayLink else { return false }
        return !displayLink.isPaused
    }

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
        // the display link retains its target, a weak proxy lets this view be released while animating
        let link = CADisplayLink(target: DisplayLinkProxy(self), selector: #selector(DisplayLinkProxy.tick))
        link.isPaused = !isVisibleForAnimation
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    deinit {
        displayLink?.invalidate()
    }

    override var isHidden: Bool {
        didSet {
            updateAnimationPause()
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updateAnimationPause()
    }

    // no need to decode frames while the view is hidden or not on screen
    private var isVisibleForAnimation: Bool {
        window != nil && !isHidden
    }

    private func updateAnimationPause() {
        guard let displayLink else { return }
        if !isVisibleForAnimation {
            displayLink.isPaused = true
        } else if displayLink.isPaused {
            lastTimestamp = 0
            displayLink.isPaused = false
        }
    }

    func clear() {
        stopFrameAnimation()
        setOwnImage(nil)
    }

    /// Stops the animation and keeps the currently shown frame.
    func stopFrameAnimation() {
        displayLink?.invalidate()
        displayLink = nil
        imageSource = nil
        frameDurations.removeAll()
        frameCount = 0
        currentFrameIndex = 0
        accumulator = 0
        lastTimestamp = 0
    }

    private func setOwnImage(_ newImage: UIImage?) {
        isSettingOwnImage = true
        defer { isSettingOwnImage = false }
        image = newImage
    }

    private func showFrame(at index: Int) {
        guard let src = imageSource,
              let cgImg = CGImageSourceCreateImageAtIndex(src, index, nil) else { return }
        setOwnImage(UIImage(cgImage: cgImg))
    }

    fileprivate func updateFrame(link: CADisplayLink) {
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

private final class DisplayLinkProxy: NSObject {

    private weak var target: UIAnimatedImageView?

    init(_ target: UIAnimatedImageView) {
        self.target = target
    }

    @objc func tick(_ link: CADisplayLink) {
        guard let target else {
            link.invalidate()
            return
        }
        target.updateFrame(link: link)
    }
}

//
//  MessageItemCell.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 07/10/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//

import UIKit

open class MessageItemCell: UITableViewCell {

    @IBOutlet weak var readFlag: UIView!
    @IBOutlet weak var receivedTime: UILabel!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var messageImage: UIImageView!
    @IBOutlet weak var message: UILabel!

    open override func awakeFromNib() {
        super.awakeFromNib()
    }

    open override func setSelected(_ selected: Bool, animated: Bool) {
        // do nothing
    }
    
    open func showData(_ source: MessageItem) {
        readFlag.isHidden = source.read
        receivedTime.text = translateReceivedTime(source.content?.createdAtDate ?? Date())
        title.text = source.content?.title ?? ""
        message.text = source.content?.message ?? ""
        if let imageUrl = source.content?.imageUrl {
            messageImage.isHidden = false
            DispatchQueue.global(qos: .background).async {
                guard let imageData = self.tryDownloadImage(imageUrl),
                      let image = self.createImage(imageData: imageData, maxDimensionInPixels: 80) else {
                    Exponea.logger.log(.error, message: "Image cannot be shown correctly")
                    self.messageImage.isHidden = true
                    return
                }
                DispatchQueue.main.async {
                    self.messageImage.image = image
                }
            }
        } else {
            messageImage.isHidden = true
        }
    }
    
    open func translateReceivedTime(_ source: Date) -> String {
        if #available(iOS 13.0, *) {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            return formatter.localizedString(for: source, relativeTo: Date())
        } else {
            let formatter = DateFormatter()
            formatter.timeStyle = .long
            formatter.dateStyle = .long
            formatter.doesRelativeDateFormatting = true
            return formatter.string(from: source)
        }
    }
    
    private func tryDownloadImage(_ imageSource: String?) -> Data? {
        guard imageSource != nil,
              let imageUrl = URL(string: imageSource!)
                else {
            Exponea.logger.log(.error, message: "Image cannot be downloaded \(imageSource ?? "<is nil>")")
            return nil
        }
        let semaphore = DispatchSemaphore(value: 0)
        var imageData: Data?
        let dataTask = URLSession.shared.dataTask(with: imageUrl) { data, response, error in {
            imageData = data
            semaphore.signal()
        }() }
        dataTask.resume()
        let awaitResult = semaphore.wait(timeout: .now() + 10.0)
        switch (awaitResult) {
        case .success:
            // Nothing to do, let check imageData
            break
        case .timedOut:
            Exponea.logger.log(.warning, message: "Image \(imageSource!) may be too large or slow connection - aborting")
            dataTask.cancel()
        }
        return imageData
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

}

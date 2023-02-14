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

    open func showData(_ source: MessageItem) {
        readFlag.isHidden = source.read
        receivedTime.text = translateReceivedTime(source.receivedTime)
        title.text = source.content?.title ?? ""
        message.text = source.content?.message ?? ""
        if let imageUrl = source.content?.imageUrl {
            messageImage.isHidden = false
            DispatchQueue.global(qos: .background).async {
                guard let imageData = ImageUtils.tryDownloadImage(imageUrl),
                      let image = ImageUtils.createImage(imageData: imageData, maxDimensionInPixels: 80) else {
                    Exponea.logger.log(.error, message: "Image cannot be shown correctly")
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else {
                            return
                        }
                        self.messageImage.isHidden = true
                    }
                    return
                }
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else {
                        return
                    }
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

}

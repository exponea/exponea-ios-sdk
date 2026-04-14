//
//  ExponeaNotificationContentService.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 06/12/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import UserNotifications
import UserNotificationsUI
#if canImport(ExponeaSDKShared)
import ExponeaSDKShared
#endif

public class ExponeaNotificationContentService {

    private let decoder: JSONDecoder = JSONDecoder.snakeCase

    private var attachmentUrl: URL?
    weak private var context: NSExtensionContext?

    public init() { }

    deinit {
        attachmentUrl?.stopAccessingSecurityScopedResource()
    }

    public func didReceive(_ notification: UNNotification,
                           context: NSExtensionContext?,
                           viewController: UIViewController) {
        guard Exponea.isExponeaNotification(userInfo: notification.request.content.userInfo) else {
            Exponea.logger.log(.verbose, message: "Skipping non-Exponea notification")
            return
        }
        createActions(notification: notification, context: context)
        if let first = notification.request.content.attachments.first,
           first.url.startAccessingSecurityScopedResource() {
            attachmentUrl = first.url
            self.context = context
            createImageView(on: viewController.view, with: first.url.path)
            viewController.preferredContentSize = CGSize(width: 0, height: 300)
        }
    }

    private func createActions(notification: UNNotification, context: NSExtensionContext?) {
        guard #available(iOS 12.0, *),
              let context = context,
              let actionsObject = notification.request.content.userInfo["actions"],
              let data = try? JSONSerialization.data(withJSONObject: actionsObject, options: []),
              let actions = try? decoder.decode([ExponeaNotificationAction].self, from: data) else {
            return
        }
        context.notificationActions = []
        for (index, action) in actions.enumerated() {
            context.notificationActions.append(
                ExponeaNotificationAction.createNotificationAction(
                    type: action.action,
                    title: action.title,
                    index: index
                )
            )
        }
    }

    private func createImageView(on view: UIView, with imagePath: String) {
        let url = URL(fileURLWithPath: imagePath)
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            Exponea.logger.log(.warning, message: "Unable to load image contents \(imagePath)")
            return
        }
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.addGestureRecognizer(UITapGestureRecognizer(
            target: self,
            action: #selector(self.imageTapped(gesture:))
        ))
        imageView.isUserInteractionEnabled = true
        view.addSubview(imageView)

        let aspect = image.size.height / max(image.size.width, 1)

        imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: aspect).isActive = true
        imageView.heightAnchor.constraint(lessThanOrEqualToConstant: 300).isActive = true
    }

    @objc
    public func imageTapped(gesture: UITapGestureRecognizer) {
        context?.performNotificationDefaultAction()
    }
}

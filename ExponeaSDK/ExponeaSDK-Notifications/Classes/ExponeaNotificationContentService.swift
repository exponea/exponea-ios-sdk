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

public class ExponeaNotificationContentService {

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    private var attachmentUrl: URL?

    public init() { }

    deinit {
        attachmentUrl?.stopAccessingSecurityScopedResource()
    }

    public func didReceive(_ notification: UNNotification,
                           context: NSExtensionContext?,
                           viewController: UIViewController) {
        createActions(notification: notification, context: context)
        // Add image if any
        if let first = notification.request.content.attachments.first,
            first.url.startAccessingSecurityScopedResource() {
            attachmentUrl = first.url
            createImageView(on: viewController.view, with: first.url.path)
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
        let image = UIImage(contentsOfFile: imagePath)
        let imageView = UIImageView(image: image)

        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)

        // Constraints
        imageView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        imageView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        imageView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        imageView.heightAnchor.constraint(lessThanOrEqualToConstant: 300).isActive = true
    }
}

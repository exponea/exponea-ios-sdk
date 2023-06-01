//
//  AppInboxStyle.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 19/05/2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation

public class AppInboxStyle {
    var appInboxButton: ButtonStyle?
    var detailView: DetailViewStyle?
    var listView: ListScreenStyle?

    public init(appInboxButton: ButtonStyle? = nil, detailView: DetailViewStyle? = nil, listView: ListScreenStyle? = nil) {
        self.appInboxButton = appInboxButton
        self.detailView = detailView
        self.listView = listView
    }
}

//
//  CustomCarouselCallback.swift
//  ExponeaSDK
//
//  Created by Ankmara on 25.07.2024.
//  Copyright © 2024 Exponea. All rights reserved.
//

public class CustomCarouselCallback: DefaultContentBlockCarouselCallback {

    public var overrideDefaultBehavior: Bool = false
    public var trackActions: Bool = true

    public init() {}

    public func onMessageShown(placeholderId: String, contentBlock: ExponeaSDK.InAppContentBlockResponse) {
        // space for custom implementation
    }

    public func onNoMessageFound(placeholderId: String) {
        // space for custom implementation
    }

    public func onError(placeholderId: String, contentBlock: ExponeaSDK.InAppContentBlockResponse?, errorMessage: String) {
        // space for custom implementation
    }

    public func onCloseClicked(placeholderId: String, contentBlock: ExponeaSDK.InAppContentBlockResponse) {
        // space for custom implementation
    }

    public func onActionClickedSafari(placeholderId: String, contentBlock: ExponeaSDK.InAppContentBlockResponse, action: ExponeaSDK.InAppContentBlockAction) {
        // space for custom implementation
    }
}

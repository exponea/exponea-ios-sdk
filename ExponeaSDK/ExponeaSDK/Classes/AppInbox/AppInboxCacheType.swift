//
//  AppInboxCacheType.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 27/10/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//

import Foundation

protocol AppInboxCacheType {
    func setMessages(messages: [MessageItem])
    func addMessages(messages: [MessageItem])
    func getMessages() -> [MessageItem]
    func setSyncToken(token: String?)
    func getSyncToken() -> String?

    func deleteImages(except: [String])
    func hasImageData(at imageUrl: String) -> Bool
    func saveImageData(at imageUrl: String, data: Data)
    func getImageData(at imageUrl: String) -> Data?

    func clear()
}

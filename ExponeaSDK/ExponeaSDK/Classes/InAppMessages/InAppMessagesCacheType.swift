//
//  InAppMessagesCacheType.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 29/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

protocol InAppMessagesCacheType {
    func saveInAppMessages(inAppMessages: [InAppMessage])
    func getInAppMessages() -> [InAppMessage]

    func deleteImages(except: [String])
    func hasImageData(at imageUrl: String) -> Bool
    func saveImageData(at imageUrl: String, data: Data)
    func getImageData(at imageUrl: String) -> Data?

    func clear()
}

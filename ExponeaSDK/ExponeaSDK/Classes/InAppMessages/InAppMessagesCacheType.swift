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
}

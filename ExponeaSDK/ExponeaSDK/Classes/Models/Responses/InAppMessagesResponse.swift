//
//  InAppMessagesResponse.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 28/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

struct InAppMessagesResponse: Codable {
    public let success: Bool
    public let data: [InAppMessage]
}

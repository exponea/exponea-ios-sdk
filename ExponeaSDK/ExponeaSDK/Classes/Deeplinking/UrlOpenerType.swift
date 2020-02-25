//
//  UrlOpenerType.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 10/01/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

protocol UrlOpenerType {
    func openBrowserLink(_ urlString: String)
    func openDeeplink(_ urlString: String)
}

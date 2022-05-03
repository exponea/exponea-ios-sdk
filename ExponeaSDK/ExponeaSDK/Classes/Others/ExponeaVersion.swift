//
//  ExponeaVersion.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 27/04/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//


import Foundation

@objc(ExponeaVersion)
open class ExponeaVersion: NSObject {
    class func getVersion() -> String {
        return Exponea.version
    }
}

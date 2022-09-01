//
//  ExponeaVersion.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 27/04/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//


import Foundation

final class ExponeaVersion: ExponeaVersionProvider {
    func getVersion() -> String {
        Exponea.version as String
    }
}

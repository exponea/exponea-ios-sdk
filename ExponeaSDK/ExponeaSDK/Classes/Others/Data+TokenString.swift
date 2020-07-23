//
//  Data+TokenString.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 24/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

extension Data {
    var tokenString: String {
        return reduce("", { $0 + String(format: "%02X", $1) })
    }
}

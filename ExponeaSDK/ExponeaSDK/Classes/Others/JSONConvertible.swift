//
//  JSONConvertible.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 23/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

public protocol JSONConvertible {}

extension String: JSONConvertible {}
extension Bool: JSONConvertible {}
extension Int: JSONConvertible {}
extension Double: JSONConvertible {}
extension Float: JSONConvertible {}
extension Dictionary: JSONConvertible {}
extension Array: JSONConvertible where Element: JSONConvertible {}
extension NSObject: JSONConvertible {}

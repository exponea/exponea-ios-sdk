//
//  Swizzle.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 28/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

internal class Swizzle: CustomStringConvertible {
    internal let aClass: AnyClass
    internal let selector: Selector
    internal let originalMethod: IMP
    internal let name: String
    internal var blocks = [String: Swizzler.SwizzleBlock]()

    internal init(block: @escaping Swizzler.SwizzleBlock,
                  name: String,
                  aClass: AnyClass,
                  selector: Selector,
                  originalMethod: IMP) {
        self.aClass = aClass
        self.selector = selector
        self.originalMethod = originalMethod
        self.name = name
        self.blocks[name] = block
    }

    internal var description: String {
        var retValue = "Swizzle on \(NSStringFromClass(aClass))::\(NSStringFromSelector(selector)) ["
        for (key, _) in blocks {
            retValue += "\(key),"
        }
        return retValue + "]"
    }
}

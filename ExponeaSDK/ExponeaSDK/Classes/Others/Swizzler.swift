//
//  Swizzler.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 24/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import ObjectiveC
import Foundation

internal class Swizzler {
    internal typealias SwizzleBlock = (
        _ parameter1: AnyObject?,
        _ parameter2: AnyObject?,
        _ parameter3: AnyObject?) -> Void

    internal static var swizzles: [Method: Swizzle] = [:]

    class func printSwizzles() {
        swizzles.forEach({ _, swizzle in
            Exponea.logger.log(.verbose, message: "\(swizzle)")
        })
    }

    class func getSwizzle(for method: Method) -> Swizzle? {
        return swizzles[method]
    }

    class func removeSwizzle(for method: Method) {
        swizzles.removeValue(forKey: method)
    }

    class func setSwizzle(_ swizzle: Swizzle, for method: Method) {
        swizzles[method] = swizzle
    }

    class func swizzleSelector(_ originalSelector: Selector, with newSelector: Selector, for aClass: AnyClass,
                               name: String, block: @escaping SwizzleBlock, addingMethodIfNecessary: Bool = false) {

        guard let swizzledMethod = class_getInstanceMethod(aClass, newSelector) else {
                Exponea.logger.log(.error, message: """
                    Swizzling error: Cannot find method for \
                    \(NSStringFromSelector(newSelector)) on \(NSStringFromClass(aClass))
                    """)
                return
        }

        var method: Method? = class_getInstanceMethod(aClass, originalSelector)

        // If we can't get original method, try to add an empty method with same signature
        if method == nil && addingMethodIfNecessary {
            let block: (@convention(block) () -> Void) = {}
            let impl = imp_implementationWithBlock(block)
            method = addMethod(to: aClass, with: originalSelector, implementation: impl)
        }

        // Make sure we have a method that we want to swizzle
        guard let originalMethod = method else {
            Exponea.logger.log(.error, message: """
                Swizzling error: Cannot find method for \
                \(NSStringFromSelector(originalSelector)) on \(NSStringFromClass(aClass))
                """)
            return
        }

        let swizzledMethodImplementation = method_getImplementation(swizzledMethod)
        let originalMethodImplementation = method_getImplementation(originalMethod)

        var swizzle = getSwizzle(for: originalMethod)

        if swizzle == nil {
            swizzle = Swizzle(block: block, name: name, aClass: aClass, selector: originalSelector,
                              originalMethod: originalMethodImplementation)
            setSwizzle(swizzle!, for: originalMethod)
        } else {
            swizzle?.blocks[name] = block
        }

        let didAddMethod = class_addMethod(aClass, originalSelector, swizzledMethodImplementation,
                                           method_getTypeEncoding(swizzledMethod))
        if didAddMethod {
            setSwizzle(swizzle!, for: class_getInstanceMethod(aClass, originalSelector)!)
        } else {
            method_setImplementation(originalMethod, swizzledMethodImplementation)
        }

        Exponea.logger.log(.verbose, message: "Adding a swizzle: \(swizzle!.description)")
    }

    class func addMethod(to aClass: AnyClass, with selector: Selector, implementation: IMP) -> Method? {
        if let method = class_getInstanceMethod(aClass, selector) {
            return method
        }

        let didAddMethod = class_addMethod(aClass, selector, implementation, "")
        guard didAddMethod else {
            Exponea.logger.log(.error, message: """
                Swizzling error: Cannot find method for \
                \(NSStringFromSelector(selector)) on \(NSStringFromClass(aClass))
                """)
            return nil
        }

        return class_getInstanceMethod(aClass, selector)!
    }

    class func unswizzleSelector(_ selector: Selector, aClass: AnyClass, name: String? = nil) {
        if let method = class_getInstanceMethod(aClass, selector),
            let swizzle = getSwizzle(for: method) {
            if let name = name {
                swizzle.blocks.removeValue(forKey: name)
            }

            if name == nil || swizzle.blocks.count < 1 {
                method_setImplementation(method, swizzle.originalMethod)
                removeSwizzle(for: method)
            }
        }
    }

    class func unswizzle(_ swizzle: Swizzle) {
        unswizzleSelector(swizzle.selector, aClass: swizzle.aClass)
        removeSwizzle(for: swizzle.originalMethod)
    }
}

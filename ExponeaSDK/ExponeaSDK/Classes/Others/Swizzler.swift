//
//  Swizzler.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 24/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import ObjectiveC

internal class Swizzler {
    internal typealias SwizzleBlock = (
        _ view: AnyObject?,
        _ command: Selector,
        _ param1: AnyObject?,
        _ param2: AnyObject?) -> Void
    
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
    
    class func swizzleSelector(_ originalSelector: Selector,
                               with newSelector: Selector,
                               for aClass: AnyClass,
                               name: String,
                               block: @escaping SwizzleBlock,
                               addingMethodIfNecessary: Bool = false) {
        
        guard let swizzledMethod = class_getInstanceMethod(aClass, newSelector) else {
                Exponea.logger.log(.error, message: """
                    Swizzling error: Cannot find method for \
                    \(NSStringFromSelector(originalSelector)) on \(NSStringFromClass(aClass))
                    """)
                return
        }
        
        let originalMethod: Method
        
        if addingMethodIfNecessary {
            if let method = class_getInstanceMethod(aClass, originalSelector) {
                originalMethod = method
            } else {
                let block: () -> Void = { print("empty implementation") }
                let emptyImp = imp_implementationWithBlock(unsafeBitCast(block, to: AnyObject.self))
                let didAddMethod = class_addMethod(aClass, originalSelector, emptyImp, "")
                guard didAddMethod else {
                    Exponea.logger.log(.error, message: """
                        Swizzling error: Cannot find method for \
                        \(NSStringFromSelector(originalSelector)) on \(NSStringFromClass(aClass))
                        """)
                    return
                }
                originalMethod = class_getInstanceMethod(aClass, originalSelector)!
            }
        } else {
            guard let method = class_getInstanceMethod(aClass, originalSelector) else {
                Exponea.logger.log(.error, message: """
                    Swizzling error: Cannot find method for \
                    \(NSStringFromSelector(originalSelector)) on \(NSStringFromClass(aClass))
                    """)
                return
            }
            originalMethod = method
        }
        
        let swizzledMethodImplementation = method_getImplementation(swizzledMethod)
        let originalMethodImplementation = method_getImplementation(originalMethod)
        
        var swizzle = getSwizzle(for: originalMethod)
        
        if swizzle == nil {
            swizzle = Swizzle(block: block,
                              name: name,
                              aClass: aClass,
                              selector: originalSelector,
                              originalMethod: originalMethodImplementation)
            setSwizzle(swizzle!, for: originalMethod)
        } else {
            swizzle?.blocks[name] = block
        }
        
        let didAddMethod = class_addMethod(aClass,
                                           originalSelector,
                                           swizzledMethodImplementation,
                                           method_getTypeEncoding(swizzledMethod))
        if didAddMethod {
            setSwizzle(swizzle!, for: class_getInstanceMethod(aClass, originalSelector)!)
        } else {
            method_setImplementation(originalMethod, swizzledMethodImplementation)
        }
        
        Exponea.logger.log(.verbose, message: "Adding a swizzle: \(swizzle!.description)")
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
extension Swizzler {
    class Swizzle: CustomStringConvertible {
        let aClass: AnyClass
        let selector: Selector
        let originalMethod: IMP
        var blocks = [String: SwizzleBlock]()
        
        init(block: @escaping SwizzleBlock,
             name: String,
             aClass: AnyClass,
             selector: Selector,
             originalMethod: IMP) {
            self.aClass = aClass
            self.selector = selector
            self.originalMethod = originalMethod
            self.blocks[name] = block
        }
        
        var description: String {
            var retValue = "Swizzle on \(NSStringFromClass(type(of: self)))::\(NSStringFromSelector(selector)) ["
            for (key, value) in blocks {
                retValue += "\t\(key) : \(value)\n"
            }
            return retValue + "]"
        }
    }
}

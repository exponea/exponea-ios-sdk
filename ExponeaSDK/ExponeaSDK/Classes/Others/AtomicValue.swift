//
//  AtomicProperty.swift
//  ExponeaSDK
//
//  Created by Gustavo Pizano on 06/03/2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation

@available(swift 5.1)
@propertyWrapper
/// Property wrapper for atomicity that uses DispatchQueue Approach
final class Atomic<Value> {
    private let queue = DispatchQueue(label: "com.exponea.ExponeaSDK.atomic")
    private var value: Value
    
    var wrappedValue: Value {
        get { queue.sync { value } }
        set { queue.sync { value = newValue } }
    }
    
    /// To access this property, we do so by usign the $ symbol for instance foo.$.bar.mutate { /* do something here */ }
    var projectedValue: Atomic<Value> {
        return self
    }
    
    init(wrappedValue value: Value) {
        self.value = value
    }
    
    
    func changeValue(with mutation: (inout Value) -> Void) {
        return queue.sync {
            mutation(&value)
        }
    }
}

@available(swift 5.1)
@propertyWrapper
/// Proprety wrapper for atomicity that uses NSLock Approach
struct AtomicLock<Value> {
    private var value: Value
    private let lock = NSLock()
    
    init(wrappedValue value: Value) {
        self.value = value
    }
    
    var wrappedValue: Value {
        get { load() }
        set { store(newValue: newValue) }
    }
    
    private func load() -> Value {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
    
    private mutating func store(newValue: Value) {
        lock.lock()
        defer { lock.unlock() }
        value = newValue
    }
}
@available(swift 4.2.0)
class AtomicProperty<T> {
    
    private var _property: T?
    
    var property: T? {
        get {
            var retVal: T?
            lock.sync {
                retVal = _property
            }
            return retVal
        }
        set {
            lock.async(flags: .barrier) {
                self._property = newValue
            }
        }
    }
    private let lock: DispatchQueue = {
        var name = "AtomicProperty" + String(Int.random(in: 0...100000))
        let clzzName = String(describing: T.self)
        name += clzzName
        return DispatchQueue(label: name, attributes: .concurrent)
    }()
    
    init(property: T) {
        self.property = property
    }
    
    init() {}
    
    // perform an atomic operation on the atomic property
    // the operation will not run if the property is nil.
    public func performAtomic(atomicOperation: ((_ prop:inout T) -> Void)) {
        lock.sync(flags: .barrier) {
            if var prop = _property {
                atomicOperation(&prop)
                _property = prop
            }
        }
    }
}

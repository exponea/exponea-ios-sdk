//
//  OnMain.swift
//  ExponeaSDK
//
//  Created by Ankmara on 24.02.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation

public func onMain(_ closure: @escaping () -> Void) {
    if Thread.current.isMainThread {
        closure()
    } else {
        DispatchQueue.main.async {
            closure()
        }
    }
}

public func onMain(_ closure: @autoclosure @escaping () -> Void) {
    onMain(closure)
}

public func ensureBackground(_ closure: @escaping () -> Void) {
    if !Thread.current.isMainThread {
        closure()
    } else {
        DispatchQueue.global(qos: .background).async {
            closure()
        }
    }
}

public func onGlobal(_ closure: @autoclosure @escaping () -> Void) {
    ensureBackground(closure)
}

//
//  NSManagedObjectContext+Perform.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 22/08/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
    func performAndWaitSafely<T>(_ block: () throws -> T) rethrows -> T {
        return try performAndWait(block)
    }
}

//
//  NSPersistentContainer+Bundle.swift
//  ExponeaSDK
//
//  Created by Dominik Hadl on 11/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation
import CoreData

extension NSPersistentContainer {

    /// <#Description#>
    ///
    /// - Parameters:
    ///   - name: <#name description#>
    ///   - bundle: <#bundle description#>
    public convenience init?(name: String, bundle: Bundle) {
        guard let modelURL = bundle.url(forResource: name, withExtension: "momd"),
            let objectModel = NSManagedObjectModel(contentsOf: modelURL) else {
                return nil
        }

        self.init(name: name, managedObjectModel: objectModel)
    }
}

//
//  SafeIndex.swift
//  ExponeaSDK
//
//  Created by Ankmara on 24.02.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation

public extension Array {
    subscript(safeIndex index: Int) -> Element? {
        if index < count && index >= 0 {
            return self[index]
        }
        return nil
    }
}

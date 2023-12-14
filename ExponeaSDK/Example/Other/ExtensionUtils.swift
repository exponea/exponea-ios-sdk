//
//  ExtensionUtils.swift
//  Example
//
//  Created by Adam Mihalik on 13/12/2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation

extension URL {
    init?(safeString: String) {
#if compiler(>=5.9) // XCODE 15+
        if #available(iOS 17.0, *) {
            self.init(
                string: safeString,
                encodingInvalidCharacters: false
            )
        } else {
            self.init(string: safeString)
        }
#else
        self.init(string: safeString)
#endif
    }
}

extension Array {
    subscript(safeIndex index: Int) -> Element? {
        if index < count && index >= 0 {
            return self[index]
        }
        return nil
    }
}

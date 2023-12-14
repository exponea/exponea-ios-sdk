//
//  Extension+CleanURL.swift
//  ExponeaSDKShared
//
//  Created by Ankmara on 20.07.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation

public extension String {
    func cleanedURL() -> URL? {
        if let url = URL(sharedSafeString: self) {
            return url
        } else if let urlEscapedString = addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let escapedURL = URL(sharedSafeString: urlEscapedString) {
            return escapedURL
        }
        return nil
    }
}

extension URL {
    init?(sharedSafeString: String) {
#if compiler(>=5.9) // XCODE 15+
        if #available(iOS 17.0, *) {
            self.init(
                string: sharedSafeString,
                encodingInvalidCharacters: false
            )
        } else {
            self.init(string: sharedSafeString)
        }
#else
        self.init(string: sharedSafeString)
#endif
    }
}

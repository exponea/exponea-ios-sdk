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
        if let url = URL(string: self) {
            return url
        } else if let urlEscapedString = addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let escapedURL = URL(string: urlEscapedString) {
            return escapedURL
        }
        return nil
    }
}

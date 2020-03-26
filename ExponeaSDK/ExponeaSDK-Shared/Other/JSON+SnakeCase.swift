//
//  JSON+SnakeCase.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 12/03/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation

extension JSONDecoder {
    static var snakeCase: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}

extension JSONEncoder {
    static var snakeCase: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
}

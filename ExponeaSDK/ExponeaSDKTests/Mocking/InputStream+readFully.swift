//
//  InputStream+readFully.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 09/12/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation

extension InputStream {
    func readFully() -> Data {
        var result = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        open()
        var amount = 0
        repeat {
            amount = read(&buffer, maxLength: buffer.count)
            if amount > 0 {
                result.append(buffer, count: amount)
            }
        } while amount > 0
        close()
        return result
    }

    func readFully() -> String? {
        return String(data: readFully(), encoding: .utf8)
    }
}

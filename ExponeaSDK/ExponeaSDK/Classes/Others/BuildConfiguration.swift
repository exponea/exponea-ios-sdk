//
//  BuildConfiguration.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 24/02/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation

// based on https://forums.swift.org/t/support-debug-only-code/11037

func inDebugBuild(_ code: () -> Void) {
    assert({
        code()
        return true
        }()
    )
}

func inReleaseBuild(_ code: () -> Void) {
    var skip: Bool = false
    inDebugBuild { skip = true }

    if !skip {
        code()
    }
}

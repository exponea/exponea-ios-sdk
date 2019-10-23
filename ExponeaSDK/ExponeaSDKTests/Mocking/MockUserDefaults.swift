//
//  MockUserDefaults.swift
//  ExponeaSDKTests
//
//  Created by Panaxeo on 06/09/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

import Foundation

class MockUserDefaults: UserDefaults {

    convenience init() {
        self.init(suiteName: "Mock User Defaults")!
    }

    override init?(suiteName suitename: String?) {
        UserDefaults().removePersistentDomain(forName: suitename!)
        super.init(suiteName: suitename)
    }
}

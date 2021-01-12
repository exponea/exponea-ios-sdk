//
//  Configuration+Anonymize.swift
//  ExponeaSDKShared
//
//  Created by Panaxeo on 12/01/2021.
//  Copyright © 2021 Exponea. All rights reserved.
//

import Foundation

public extension Configuration {
    mutating func switchProjects(
        mainProject: ExponeaProject,
        projectMapping: [EventType: [ExponeaProject]]?
    ) {
        baseUrl = mainProject.baseUrl
        projectToken = mainProject.projectToken
        authorization = mainProject.authorization
        self.projectMapping = projectMapping
    }
}

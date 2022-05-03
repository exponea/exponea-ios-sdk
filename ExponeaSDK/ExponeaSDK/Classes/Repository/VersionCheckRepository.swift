//
//  VersionCheckRepository.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 25/04/2022.
//  Copyright © 2022 Exponea. All rights reserved.
//


import Foundation

protocol VersionCheckRepository {
    func requestLastSDKVersion(
        completion: @escaping (Result<String>) -> Void
    )
}

//
//  TelemetryUpload.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 15/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

protocol TelemetryUpload: class {
    func upload(crashLog: CrashLog, completionHandler: @escaping (Bool) -> Void)
    func upload(eventWithName: String, properties: [String: String], completionHandler: @escaping (Bool) -> Void)
}

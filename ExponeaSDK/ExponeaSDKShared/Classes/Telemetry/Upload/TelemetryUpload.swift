//
//  TelemetryUpload.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 15/11/2019.
//  Copyright © 2019 Exponea. All rights reserved.
//

public protocol TelemetryUpload: AnyObject {
    func uploadSessionStart(runId: String, completionHandler: @escaping (Bool) -> Void)
    func upload(crashLog: CrashLog, completionHandler: @escaping (Bool) -> Void)
    func upload(eventLog: EventLog, completionHandler: @escaping (Bool) -> Void)
}

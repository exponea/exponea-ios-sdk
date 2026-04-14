//
//  ExponeaSentryEnvelope.swift
//  ExponeaSDK
//
//  Created by Adam Mihalik on 27/06/2025.
//  Copyright © 2025 Exponea. All rights reserved.
//

import Foundation

internal struct ExponeaSentryEnvelope<T: ExponeaSentryEnvelopeItemBody>: Encodable {
    let header: ExponeaSentryEnvelopeHeader
    let item: ExponeaSentryEnvelopeItem<T>
}

internal struct ExponeaSentryEnvelopeHeader: Encodable {
    let eventId: String?
    let dsn: String
    let sentAt: String

    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case dsn = "dsn"
        case sentAt = "sent_at"
    }
}

internal struct ExponeaSentryEnvelopeItem<T: ExponeaSentryEnvelopeItemBody>: Encodable {
    let header: ExponeaSentryEnvelopeItemHeader
    let body: T
}

internal struct ExponeaSentryEnvelopeItemHeader: Encodable {
    let type: String
    let length: Int
    let contentType: String = "application/json"

    enum CodingKeys: String, CodingKey {
        case type = "type"
        case length = "length"
        case contentType = "content_type"
    }

    func withLength(newLength: Int) -> ExponeaSentryEnvelopeItemHeader {
        return ExponeaSentryEnvelopeItemHeader(type: self.type, length: newLength)
    }
}

internal protocol ExponeaSentryEnvelopeItemBody: Encodable {
    func prepareHeader() -> ExponeaSentryEnvelopeItemHeader
}

internal struct ExponeaSentryMessage: ExponeaSentryEnvelopeItemBody {
    let timestamp: String
    let message: ExponeaSentryMessageLog
    let logger: String = "messageLogger"
    let level: String = "info"
    let fingerprint: [String] = ["metrics"]
    let eventId: String
    let contexts: ExponeaSentryContext
    let tags: [String: String]
    let release: String
    let environment: String
    let platform: String = "swift"
    let extra: [String: String]

    enum CodingKeys: String, CodingKey {
        case timestamp = "timestamp"
        case message = "message"
        case logger = "logger"
        case level = "level"
        case fingerprint = "fingerprint"
        case eventId = "event_id"
        case contexts = "contexts"
        case tags = "tags"
        case release = "release"
        case environment = "environment"
        case platform = "platform"
        case extra = "extra"
    }

    func prepareHeader() -> ExponeaSentryEnvelopeItemHeader {
        return ExponeaSentryEnvelopeItemHeader(
            type: "event",
            length: 0
        )
    }
}

internal struct ExponeaSentryMessageLog: Encodable {
    let formatted: String
}
internal struct ExponeaSentryContext: Encodable {
    let app: ExponeaSentryAppContextInfo
    let device: ExponeaSentryDeviceContextInfo
    let os: ExponeaSentryOsContextInfo
}

internal struct ExponeaSentryAppContextInfo: Encodable {
    let type: String = "app"
    let appIdentifier: String
    let appName: String
    let appBuild: String
    enum CodingKeys: String, CodingKey {
        case type = "type"
        case appIdentifier = "app_identifier"
        case appName = "app_name"
        case appBuild = "app_build"
    }
}

internal struct ExponeaSentryDeviceContextInfo: Encodable {
    let type: String = "device"
    let model: String
    let manufacturer: String
    let brand: String
}

internal struct ExponeaSentryOsContextInfo: Encodable {
    let type: String = "os"
    let name: String = "iOS"
    let version: String
}

internal struct ExponeaSentryException: ExponeaSentryEnvelopeItemBody {
    let timestamp: String
    let logger: String = "errorLogger"
    let threads: ExponeaSentryValuesWrapper<ExponeaSentryThread>
    let exception: ExponeaSentryValuesWrapper<ExponeaSentryExceptionPart>
    let level: String
    let fingerprint: [String] = ["error"]
    let eventId: String
    let contexts: ExponeaSentryContext
    let tags: [String: String]
    let release: String
    let environment: String
    let platform: String = "swift"
    let extra: [String: String]

    enum CodingKeys: String, CodingKey {
        case timestamp = "timestamp"
        case logger = "logger"
        case threads = "threads"
        case exception = "exception"
        case level = "level"
        case fingerprint = "fingerprint"
        case eventId = "event_id"
        case contexts = "contexts"
        case tags = "tags"
        case release = "release"
        case environment = "environment"
        case platform = "platform"
        case extra = "extra"
    }

    func prepareHeader() -> ExponeaSentryEnvelopeItemHeader {
        return ExponeaSentryEnvelopeItemHeader(
            type: "event",
            length: 0
        )
    }
}

internal struct ExponeaSentryExceptionPart: Encodable {
    let type: String
    let value: String
    let stacktrace: ExponeaSentryStackTrace
    let mechanism: ExponeaSentryExceptionMechanism
    let threadId: UInt32

    enum CodingKeys: String, CodingKey {
        case type = "type"
        case value = "value"
        case stacktrace = "stacktrace"
        case mechanism = "mechanism"
        case threadId = "thread_id"
    }
}

internal struct ExponeaSentryExceptionMechanism: Encodable {
    let type: String
    let description: String
    let handled: Bool
}

internal struct ExponeaSentryThread: Encodable {
    let id: UInt32
    let name: String
    let state: String
    let crashed: Bool
    let current: Bool
    let daemon: Bool
    let main: Bool
    let stacktrace: ExponeaSentryStackTrace
}

internal struct ExponeaSentryStackTrace: Encodable {
    let frames: [ExponeaSentryStackFrame]
}

internal struct ExponeaSentryStackFrame: Encodable {
    let symbolAddress: String?
    let function: String?
    let module: String?
    let lineno: Int?
    
    enum CodingKeys: String, CodingKey {
        case symbolAddress = "symbol_addr"
        case function = "function"
        case module = "module"
        case lineno = "lineno"
    }
}

internal struct ExponeaSentryValuesWrapper<T: Encodable>: Encodable {
    let values: [T]
}

internal struct ExponeaSentrySession: ExponeaSentryEnvelopeItemBody {
    let started: String
    let timestamp: String
    let distinctId: String
    let sessionId: String
    let isInit: Bool
    let status: String
    let sequence: Int64
    let attributes: ExponeaSentryAttributes
    let extra: [String: String]

    enum CodingKeys: String, CodingKey {
        case started = "started"
        case timestamp = "timestamp"
        case distinctId = "did"
        case sessionId = "sid"
        case isInit = "init"
        case sequence = "seq"
        case attributes = "attrs"
        case extra = "extra"
    }

    func prepareHeader() -> ExponeaSentryEnvelopeItemHeader {
        return ExponeaSentryEnvelopeItemHeader(
            type: "session",
            length: 0
        )
    }
}

internal struct ExponeaSentryAttributes: Encodable {
    let release: String
    let environment: String
}

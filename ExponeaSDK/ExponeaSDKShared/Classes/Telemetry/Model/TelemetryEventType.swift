//
//  TelemetryEventType.swift
//  ExponeaSDK
//
//  Created by Panaxeo on 13/03/2020.
//  Copyright © 2020 Exponea. All rights reserved.
//

import Foundation

public enum TelemetryEventType: String {
    case sdkConfigure
    case identifyCustomer
    case anonymize
    case inappMessageFetch
    case inappMessageShown
    case appInboxInitFetch
    case appInboxSyncFetch
    case appInboxMessageShown
    case pushNotificationDelivered
    case pushNotificationShown
    case contentBlockInitFetch
    case contentBlockPersonalisedFetch = "inappContentBlockPersonalisedFetch"
    case contentBlockShown = "inappContentBlockShown"
    case rtsCallbackRegistered = "callbackRegistered"
    case rtsGetSegments = "getSegments"
    case integrationStopped
    case localCustomerDataCleared
    case recommendationsFetched
    case consentsFetched = "concentsGot"
    case selfCheck = "pushNotificationsSelfCheck"
    case eventCount = "notFlushedEventsCount"
}

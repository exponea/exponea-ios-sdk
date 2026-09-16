//
//  InAppContentBlockAvailability.swift
//  ExponeaSDK
//
//  Copyright © 2026 Exponea. All rights reserved.
//

import Foundation

/// Cache and fetch state for a single in-app content block placeholder.
public enum InAppContentBlockAvailability: Equatable {
    case ready
    case loading
    case empty
}

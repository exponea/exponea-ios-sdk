//
//  InAppContentBlockAvailabilityDecision.swift
//  ExponeaSDK
//
//  Copyright © 2026 Exponea. All rights reserved.
//

import Foundation

/// Terminal outcome of a bounded-time availability check.
public enum InAppContentBlockAvailabilityDecision: Equatable {
    /// Availability resolved within the deadline. The associated value is `.ready` or `.empty` only.
    case resolved(InAppContentBlockAvailability)
    /// The deadline elapsed while the placeholder was still loading.
    case timedOut
}

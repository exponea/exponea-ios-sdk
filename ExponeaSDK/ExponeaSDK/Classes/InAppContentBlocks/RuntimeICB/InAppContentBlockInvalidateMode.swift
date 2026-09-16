//
//  InAppContentBlockInvalidateMode.swift
//  ExponeaSDK
//
//  Copyright © 2026 Exponea. All rights reserved.
//

import Foundation

/// Controls whether cache invalidation triggers an immediate background refetch.
public enum InAppContentBlockInvalidateMode {
    /// Drop cached state and refetch in the background.
    case eager
    /// Drop cached state only; the next access loads content.
    /// For placeholder IDs that have never been prefetched, `.lazy` behaves identically to `.eager`:
    /// the controller immediately starts a background fetch because there is no cached state to defer.
    case lazy
}

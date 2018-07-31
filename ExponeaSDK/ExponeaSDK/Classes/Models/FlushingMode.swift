//
//  FlushingMode.swift
//  ExponeaSDK
//
//  Created by Dominik Hádl on 12/04/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import Foundation

/// Flushing mode that is used to specify how often or if data is automatically flushed.
public enum FlushingMode {
    /// Manual flushing mode disables any automatic upload and it's your responsibility to flush data.
    case manual
    /// Automatic data flushing will flush data when the application will resign active state.
    case automatic
    /// Periodic data flushing will be flushing data in your specified interval (in seconds)
    /// and when you background or quit the application.
    case periodic(Int)
    /// Flushes all data immediately as it is received.
    case immediate
}

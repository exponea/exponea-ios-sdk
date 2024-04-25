//
//  Debouncer.swift
//  ExponeaSDK
//
//  Created by Ankmara on 19.04.2024.
//  Copyright © 2024 Exponea. All rights reserved.
//

import Foundation

final class Debouncer {
    private let delay: TimeInterval
    private var workItem: DispatchWorkItem?
    private let queue: DispatchQueue

    init(delay: TimeInterval, queue: DispatchQueue = .main) {
        self.delay = delay
        self.queue = queue
    }

    func stop() {
        workItem?.cancel()
        workItem = nil
    }

    func debounce(action: @escaping EmptyBlock) {
        workItem?.cancel()
        workItem = DispatchWorkItem { [weak self] in
            action()
            self?.workItem = nil
        }
        if let workItem = workItem {
            queue.asyncAfter(deadline: .now() + delay, execute: workItem)
        }
    }
}

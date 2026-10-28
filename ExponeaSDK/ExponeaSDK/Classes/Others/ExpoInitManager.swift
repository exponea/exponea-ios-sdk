//
//  ExpoInitManager.swift
//  ExponeaSDK
//
//  Created by Ankmara on 31.01.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation

public typealias EmptyBlock = () -> Swift.Void
public typealias EmptyThrowsBlock =  () throws -> Swift.Void

protocol ExpoInitManagerType {
    var actionBlocks: [EmptyThrowsBlock] { get }
    var isConfigured: Bool { get }

    func doActionAfterExponeaInit(_ action: @escaping EmptyThrowsBlock) rethrows
    func setStatus(status: ExpoInitManager.ExponeaInitType)
    func clean()
}

final class ExpoInitManager: ExpoInitManagerType {

    // Enum definition
    enum ExponeaInitType {
        case notInitialized
        case configured
    }

    // Init status and the queue of deferred actions are kept in a single atomic value,
    // so that switching to `.configured` and taking the queued actions is one step.
    // Every action therefore runs exactly once: it is either queued before the switch and replayed,
    // or it runs directly after it. Order is not guaranteed: an action submitted while the replay
    // is running runs immediately and can run before older queued actions.
    private enum State {
        case pending([EmptyThrowsBlock])
        case configured
    }

    // MARK: - Properties
    @Atomic private var state: State = .pending([])
    private let isConfiguredProvider: () -> Bool
    internal var isConfigured: Bool { isConfiguredProvider() }
    internal var actionBlocks: [EmptyThrowsBlock] {
        if case .pending(let blocks) = state { return blocks }
        return []
    }

    // MARK: - Init
    convenience init(sdk: ExponeaType) {
        self.init(isConfigured: { sdk.isConfigured })
    }

    init(isConfigured: @escaping () -> Bool) {
        isConfiguredProvider = isConfigured
    }
}

// MARK: - Methods
extension ExpoInitManager {
    func setStatus(status: ExponeaInitType) {
        switch status {
        case .notInitialized:
            _state.changeValue(with: { $0 = .pending([]) })
        case .configured:
            guard !IntegrationManager.shared.isStopped else {
                Exponea.logger.log(.error, message: "Method has not been invoked, SDK is stopping")
                return
            }
            guard isConfigured else { return }
            var pending: [EmptyThrowsBlock] = []
            _state.changeValue(with: {
                if case .pending(let blocks) = $0 {
                    pending = blocks
                }
                $0 = .configured
            })
            // Replay runs outside of the atomic section, so actions may safely call back into this manager
            for action in pending {
                Exponea.shared.logOnException(action, errorHandler: nil)
            }
        }
    }

    // This will be visible only - rest private
    func doActionAfterExponeaInit(_ action: @escaping EmptyThrowsBlock) rethrows {
        guard !IntegrationManager.shared.isStopped else {
            Exponea.logger.log(.error, message: "Method has not been invoked, SDK is stopping")
            return
        }
        var runNow = false
        _state.changeValue(with: {
            switch $0 {
            case .pending(let blocks):
                $0 = .pending(blocks + [action])
            case .configured:
                runNow = true
            }
        })
        if runNow {
            try action()
        }
    }

    func clean() {
        var deletedCount: Int?
        _state.changeValue(with: {
            if case .pending(let blocks) = $0 {
                deletedCount = blocks.count
                $0 = .pending([])
            }
        })
        // Logged outside of the atomic section, a log hook may call back into this manager
        if let deletedCount {
            Exponea.logger.log(.verbose, message: "Action blocks (\(deletedCount)) have been deleted")
        }
    }
}

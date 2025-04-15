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
    var actionBlocks: [EmptyThrowsBlock] { get set }
    var isConfigured: Bool { get }

    func notifyListenerIfNeeded()
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

    // MARK: - Properties
    internal var status: ExponeaInitType = .notInitialized
    internal var isConfigured: Bool { sdkInstance.isConfigured }
    @Atomic internal var actionBlocks: [EmptyThrowsBlock] = []
    internal var sdkInstance: ExponeaType

    // MARK: - Init
    init(sdk: ExponeaType) {
        sdkInstance = sdk
    }
}

// MARK: - Methods
extension ExpoInitManager {
    func setStatus(status: ExponeaInitType) {
        self.status = status
        switch status {
        case .notInitialized: break
        case .configured:
            notifyListenerIfNeeded()
        }
    }

    internal func notifyListenerIfNeeded() {
        guard !IntegrationManager.shared.isStopped else {
            Exponea.logger.log(.error, message: "Method has not been invoked, SDK is stopping")
            return
        }
        guard isConfigured, status == .configured, !actionBlocks.isEmpty else { return }
        for action in actionBlocks {
            Exponea.shared.logOnException(action, errorHandler: nil)
        }
        clean()
    }

    // This will be visible only - rest private
    func doActionAfterExponeaInit(_ action: @escaping EmptyThrowsBlock) rethrows {
        guard !IntegrationManager.shared.isStopped else {
            Exponea.logger.log(.error, message: "Method has not been invoked, SDK is stopping")
            return
        }
        if isConfigured && status == .configured {
            try action()
        } else {
            _actionBlocks.changeValue(with: { $0.append(action) })
        }
    }

    func clean() {
        Exponea.logger.log(.verbose, message: "Action blocks (\(actionBlocks.count)) have been deleted")
        _actionBlocks.changeValue(with: { $0.removeAll() })
    }
}

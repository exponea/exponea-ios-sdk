//
//  ExpoInitManager.swift
//  ExponeaSDK
//
//  Created by Ankmara on 31.01.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import Foundation

typealias EmptyBlock = () -> Swift.Void
typealias EmptyThrowsBlock =  () throws -> Swift.Void

protocol ExpoInitManagerType {
    var actionBlocks: [EmptyThrowsBlock] { get set }
    var isConfigured: Bool { get }

    func notifyListenerIfNeeded()
    func doActionAfterExponeaInit(_ action: @escaping EmptyThrowsBlock) rethrows
    func setStatus(status: ExpoInitManager.ExponeaInitType)
}

final class ExpoInitManager: ExpoInitManagerType {

    // Enum definition
    enum ExponeaInitType {
        case notInitialized
        case configured
    }

    // MARK: - Properties
    static let manager = ExpoInitManager()
    internal var status: ExponeaInitType = .notInitialized
    internal var isConfigured: Bool { Exponea.shared.isConfigured }
    internal var actionBlocks: [EmptyThrowsBlock] = []

    // MARK: - Init
    private init() {}
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
        guard isConfigured, status == .configured, !actionBlocks.isEmpty else { return }
        try? actionBlocks.forEach {
            try $0()
        }
        clean()
    }

    // This will be visible only - rest private
    func doActionAfterExponeaInit(_ action: @escaping EmptyThrowsBlock) rethrows {
        if isConfigured && status == .configured {
            try action()
        } else {
            actionBlocks.append(action)
        }
    }

    func clean() {
        Exponea.logger.log(.verbose, message: "Action blocks (\(actionBlocks.count)) have been deleted")
        actionBlocks.removeAll()
    }
}

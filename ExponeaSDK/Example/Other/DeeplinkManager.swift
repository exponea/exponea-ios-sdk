//
//  DeeplinkManager.swift
//  Example
//
//  Created by Ankmara on 07.08.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

public enum DeeplinkType {
    case fetch
    case track
    case manual
    case anonymize
    case inappcb

    init?(input: String) {
        switch true {
        case input.contains("fetch"):
            self = .fetch
        case input.contains("track"):
            self = .track
        case input.contains("manual"):
            self = .manual
        case input.contains("anonymize"):
            self = .anonymize
        case input.contains("inappcb"):
            self = .inappcb
        default:
            return nil
        }
    }
}

public protocol DeeplinkManagerType {
    var listener: ((DeeplinkType) -> Void)? { get set }
    func setDeeplinkType(type: DeeplinkType)
}

public final class DeeplinkManager: DeeplinkManagerType {

    public static let manager = DeeplinkManager()
    private init() {}

    private var currentDeeplinkType: DeeplinkType? {
        didSet {
            notifyListenerIfNeeded()
        }
    }

    public var listener: ((DeeplinkType) -> Void)? {
        didSet {
            notifyListenerIfNeeded()
        }
    }

    private func notifyListenerIfNeeded() {
        guard let type = currentDeeplinkType, listener != nil else { return }
        listener?(type)
        currentDeeplinkType = nil
    }

    public func setDeeplinkType(type: DeeplinkType) {
        currentDeeplinkType = type
    }
}

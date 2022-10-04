//
// Created by Adam Mihalik on 15/09/2022.
//

import Foundation

public struct GdprTracking {
    public static func isTrackForced(_ url: String?) -> Bool {
        guard let url = url else {
            return false
        }
        guard let uri = URLComponents(string: url) else {
            return false
        }
        guard let rawForceTrack = uri.queryItems?.first(where: { $0.name == "xnpe_force_track" }) else {
            return false
        }
        guard let rawForceTrackValue = rawForceTrack.value else {
            // URI RFC doesn't mandate that query param needs to be name-value pair
            // this IF is handling of case '?key=value&xnpe_force_track'
            return true
        }
        switch (rawForceTrackValue.lowercased()) {
        case "true" : return true
        case "1" : return true
        case "false" : return false
        case "0" : return false
        default :
            Exponea.logger.log(.error, message: "Action url contains force-track with incompatible value \(rawForceTrackValue)")
            return false
        }
    }
    
    public static func readTrackingConsentFlag(_ source: Any?) -> Bool {
        if (source == nil) {
            // default
            return true
        }
        if let sourceFlag = source as? Bool {
            return sourceFlag
        }
        if let sourceFlag = source as? Int {
            return sourceFlag == 1
        }
        if let sourceFlag = source as? String {
            switch (sourceFlag.lowercased()) {
            case "true" : return true
            case "1" : return true
            case "false" : return false
            case "0" : return false
            default :
                Exponea.logger.log(.error, message: "HasConsentFlag with incompatible value \(sourceFlag)")
                return false
            }
        }
        Exponea.logger.log(.error, message: "HasConsentFlag with incompatible value \(String(describing: source))")
        return false
    }
}

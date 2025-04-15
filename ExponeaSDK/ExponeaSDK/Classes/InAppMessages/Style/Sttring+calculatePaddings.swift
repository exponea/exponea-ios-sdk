//
//  Sttring+calculatePaddings.swift
//  ExponeaSDK
//
//  Created by Ankmara on 18.03.2025.
//  Copyright © 2025 Exponea. All rights reserved.
//

import Foundation

extension String {
    func calculatePaddings() -> [InAppButtonEdge] {
        var padding: [InAppButtonEdge] = []
        let data = components(separatedBy: " ")
        switch data.count {
        case 1:
            padding.append(.init(edge: .top, value: data.first?.convertPxToFloatWithDefaultValue() ?? 0))
            padding.append(.init(edge: .bottom, value: data.first?.convertPxToFloatWithDefaultValue() ?? 0))
            padding.append(.init(edge: .leading, value: data.first?.convertPxToFloatWithDefaultValue() ?? 0))
            padding.append(.init(edge: .trailing, value: data.first?.convertPxToFloatWithDefaultValue() ?? 0))
        case 2:
            padding.append(.init(edge: .top, value: data[0].convertPxToFloatWithDefaultValue()))
            padding.append(.init(edge: .bottom, value: data[0].convertPxToFloatWithDefaultValue()))
            padding.append(.init(edge: .leading, value: data[1].convertPxToFloatWithDefaultValue()))
            padding.append(.init(edge: .trailing, value: data[1].convertPxToFloatWithDefaultValue()))
        case 3:
            padding.append(.init(edge: .top, value: data[0].convertPxToFloatWithDefaultValue()))
            padding.append(.init(edge: .bottom, value: data[2].convertPxToFloatWithDefaultValue()))
            padding.append(.init(edge: .leading, value: data[1].convertPxToFloatWithDefaultValue()))
            padding.append(.init(edge: .trailing, value: data[1].convertPxToFloatWithDefaultValue()))
        case 4:
            padding.append(.init(edge: .top, value: data[0].convertPxToFloatWithDefaultValue()))
            padding.append(.init(edge: .bottom, value: data[2].convertPxToFloatWithDefaultValue()))
            padding.append(.init(edge: .leading, value: data[3].convertPxToFloatWithDefaultValue()))
            padding.append(.init(edge: .trailing, value: data[1].convertPxToFloatWithDefaultValue()))
        default: break
        }
        return padding
    }

    func removePx() -> String {
        lowercased().replacingOccurrences(of: "px", with: "")
    }

    func convertPxToFloatWithDefaultValue() -> CGFloat {
        CGFloat(Int(removePx()) ?? 0)
    }
}

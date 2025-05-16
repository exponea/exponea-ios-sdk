//
//  InAppButtonContainerSwiftUIViewModel.swift
//  ExponeaSDK
//
//  Created by Ankmara on 01.11.2024.
//  Copyright © 2024 Exponea. All rights reserved.
//

import Combine
import UIKit

public enum StackType {
    case horizontal
    case vertical
}

public struct InAppButtonData {
    let id = UUID()
    let stackType: StackType
    let buttons: [InAppButtonConfig]
}

final class InAppButtonContainerSwiftUIViewModel: ObservableObject {
    var input: [InAppButtonConfig] = []

    init(input: [InAppButtonConfig]) {
        self.input = input
        prepareData()
    }

    @Published var data: [InAppButtonData] = []

    private func textWidth(title: String) -> CGSize {
        title.size(withAttributes: [.font: UIFont.systemFont(ofSize: 18)])
    }

    private func isFitToScreenWidth(buttons: [InAppButtonConfig]) -> Bool {
        let margins = buttons
            .filter { $0.layout == .hug }
            .map { $0.margin
                    .filter { $0.edge == .leading || $0.edge == .trailing }
                .map { $0.value }
                .reduce(0, { $0 + $1 })
            }
            .reduce(0, { $0 + $1 })
        let paddings = buttons
            .filter { $0.layout == .hug }
            .map { $0.padding
                    .filter { $0.edge == .leading || $0.edge == .trailing }
                .map { $0.value }
                .reduce(0, { $0 + $1 })
            }
            .reduce(0, { $0 + $1 })
        let widths = buttons
            .filter { $0.layout == .hug }
            .map { textWidthSingle(title: $0.title, config: $0) }
            .map { $0.width }
            .reduce(0, { $0 + $1 })
        let totalWidth = margins + widths + paddings
        let screenWidth = UIScreen.main.bounds.width
        return totalWidth <= screenWidth
    }

    private func textWidthSingle(title: String, config: InAppButtonConfig) -> CGSize {
        if let fontData = config.fontData?.loadedFont {
            return title.size(withAttributes: [.font: fontData])
        } else {
            return title.size(withAttributes: [.font: UIFont.systemFont(ofSize: CGFloat(config.size))])
        }
    }

    func prepareData() {
        let hugButtons = input.filter({ $0.layout == .hug })
        if input.count == hugButtons.count {
            if isFitToScreenWidth(buttons: hugButtons) {
                data.append(.init(stackType: .horizontal, buttons: hugButtons))
            } else {
                for (index, button) in input.enumerated() {
                    var buttonsToCheck: [InAppButtonConfig] = [button]
                    if let nextHugButton = input[safeIndex: index + 1] {
                        buttonsToCheck.append(nextHugButton)
                    }
                    if let previousHugButton = input[safeIndex: index - 1] {
                        buttonsToCheck.append(previousHugButton)
                    }
                    if isFitToScreenWidth(buttons: buttonsToCheck) {
                        data.append(.init(stackType: .horizontal, buttons: Array(input[index...index + 1])))
                    } else {
                        var copy = button
                        copy.isWiderThanScreen = true
                        data.append(.init(stackType: .vertical, buttons: [copy]))
                    }
                }
            }
        } else {
            for (index, button) in input.enumerated() {
                if data.map({ $0.buttons }).flatMap({ $0 }).map({ $0.id }).contains(button.id) { continue }
                if button.layout == .fill {
                    data.append(.init(stackType: .vertical, buttons: [button]))
                } else if button.layout == .hug && (input[safeIndex: index + 1]?.layout == .hug || input[safeIndex: index - 1]?.layout == .hug) {
                    var buttonsToCheck: [InAppButtonConfig] = [button]
                    if let nextHugButton = input[safeIndex: index + 1], nextHugButton.layout == .hug {
                        buttonsToCheck.append(nextHugButton)
                    }
                    if let previousHugButton = input[safeIndex: index - 1], previousHugButton.layout == .hug {
                        buttonsToCheck.append(previousHugButton)
                    }
                    if isFitToScreenWidth(buttons: buttonsToCheck) {
                        data.append(.init(stackType: .horizontal, buttons: Array(input[index...index + 1])))
                    } else {
                        var copy = button
                        copy.isWiderThanScreen = true
                        data.append(.init(stackType: .vertical, buttons: [copy]))
                    }
                } else {
                    data.append(.init(stackType: .vertical, buttons: [button]))
                }
            }
        }
    }
}

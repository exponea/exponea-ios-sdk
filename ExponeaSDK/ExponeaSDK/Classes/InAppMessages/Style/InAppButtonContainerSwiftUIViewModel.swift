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
        data.removeAll()
        let hugButtons = input.filter { $0.layout == .hug }
        if input.count == hugButtons.count {
            if isFitToScreenWidth(buttons: hugButtons) {
                data.append(.init(stackType: .horizontal, buttons: hugButtons))
                return
            }

            var i = 0
            while i < input.count {
                let current = input[i]
                if let next = input[safeIndex: i + 1],
                   isFitToScreenWidth(buttons: [current, next]) {
                    data.append(.init(stackType: .horizontal, buttons: [current, next]))
                    i += 2
                } else {
                    var copy = current
                    copy.isWiderThanScreen = true
                    data.append(.init(stackType: .vertical, buttons: [copy]))
                    i += 1
                }
            }
            return
        }

        var i = 0
        while i < input.count {
            let button = input[i]

            if button.layout == .fill {
                data.append(.init(stackType: .vertical, buttons: [button]))
                i += 1
                continue
            }

            if button.layout == .hug,
               let next = input[safeIndex: i + 1],
               next.layout == .hug,
               isFitToScreenWidth(buttons: [button, next]) {
                data.append(.init(stackType: .horizontal, buttons: [button, next]))
                i += 2
                continue
            }

            var copy = button
            if !isFitToScreenWidth(buttons: [button]) {
                copy.isWiderThanScreen = true
            }
            data.append(.init(stackType: .vertical, buttons: [copy]))
            i += 1
        }
    }
}

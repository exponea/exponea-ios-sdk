//
//  InAppViewConfig.swift
//  ExponeaSDK
//
//  Created by Ankmara on 18.03.2025.
//  Copyright © 2025 Exponea. All rights reserved.
//

import Foundation
import Combine

final class InAppViewConfig: ObservableObject {
    var height: CGFloat = 0 {
        didSet {
            debouncer.debounce { [weak self] in
                guard let self, self.height > 0 else { return }
                self.textCompletionHeight?(self.height)
            }
        }
    }
    public var textCompletionHeight: TypeBlock<CGFloat>?
    @Published var shouldBeScrollable = false
    var debouncer = Debouncer(delay: 1.5)
}

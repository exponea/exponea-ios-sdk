//
//  InAppLabel.swift
//  ExponeaSDK
//
//  Created by Ankmara on 2024/10/23.
//  Copyright © 2024 Exponea. All rights reserved.
//

import UIKit
import Foundation
import SwiftUI
import Combine

public enum TextAlignment {
    case left
    case center
    case right
    case unknown

    public init(input: String?) {
        switch input?.lowercased() {
        case "left":
            self = .left
        case "center":
            self = .center
        case "right":
            self = .right
        default:
            self = .unknown
        }
    }

    var alignment: NSTextAlignment {
        switch self {
        case .center:
            return .center
        case .left:
            return .left
        case .right:
            return .right
        case .unknown:
            return .natural
        }
    }
}

public protocol InAppTextConfigurable {
    var text: String? { get set }
    var size: CGFloat { get set }
    var style: String? { get set }
    var alignment: String? { get set }
    var color: String? { get set }
    var lineHeight: CGFloat? { get set }
    var customFont: String? { get set }
    var isVisible: Bool { get set }
    var padding: [InAppButtonEdge] { get set }
    var fontData: InAppButtonFontData? { get set }
}

extension UIFont {
    static func boldItalic(ofSize: CGFloat) -> UIFont {
        let font = UIFont.systemFont(ofSize: ofSize, weight: .bold)
        return UIFont(descriptor: font.fontDescriptor.withSymbolicTraits(.traitItalic)!, size: ofSize)
    }
}

extension View {
    /// A backwards compatible wrapper for iOS 14 `onChange`
    @ViewBuilder func valueChanged<T: Equatable>(value: T, onChange: @escaping (T) -> Void) -> some View {
        if #available(iOS 14.0, *) {
            self.onChange(of: value, perform: onChange)
        } else {
            self.onReceive(Just(value)) { (value) in
                onChange(value)
            }
        }
    }
}

final class InAppLabel: UILabel {

    private var topInset: CGFloat = 5
    private var bottomInset: CGFloat = 5.0
    private var leftInset: CGFloat = 16.0
    private var rightInset: CGFloat = 16.0
    private let config: InAppLabelConfig

    init(config: InAppLabelConfig) {
        self.config = config
        super.init(frame: .zero)

        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
        applyStyle()
    }

    private func applyStyle() {
        numberOfLines = 0

        var attributes: [NSAttributedString.Key: Any] = [:]
        attributes[.font] = UIFont.fromStyle(style: config.style, size: Int(config.size))
        if let customFont = config.fontData?.loadedFont {
            attributes[.font] = customFont
        }
        attributes[.foregroundColor] = UIColor.parse(config.color) ?? .black

        let attrString = NSMutableAttributedString(string: config.text ?? "", attributes: attributes)

        let style = NSMutableParagraphStyle()
        style.alignment = TextAlignment(input: config.alignment).alignment

        if let lineHeight = config.lineHeight {
            style.minimumLineHeight = lineHeight
        }

        attrString.addAttribute(
            .paragraphStyle,
            value: style,
            range: NSRange(location: 0, length: config.text?.count ?? 0)
        )
        attributedText = attrString
    }

    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets.init(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + leftInset + rightInset,
            height: size.height + topInset + bottomInset
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

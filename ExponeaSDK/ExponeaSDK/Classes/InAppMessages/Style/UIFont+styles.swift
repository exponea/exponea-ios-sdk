//
//  UIFont+styles.swift
//  ExponeaSDK
//
//  Created by Ankmara on 18.03.2025.
//  Copyright © 2025 Exponea. All rights reserved.
//

import UIKit

extension UIFont {
    static func fromStyle(style: String?, size: Int) -> UIFont {
        guard let style else { return .systemFont(ofSize: CGFloat(size)) }
        let font: UIFont
        switch style.lowercased() {
        case "bold":
            font = .boldSystemFont(ofSize: CGFloat(size))
        case "italic":
            font = .italicSystemFont(ofSize: CGFloat(size))
        case "bold+italic":
            font = .boldItalic(ofSize: CGFloat(size))
        case "italic+bold":
            font = .italicSystemBoldFont(ofSize: CGFloat(size))
        default:
            font = .systemFont(ofSize: CGFloat(size))
        }
        return font
    }
}

extension UIFont {
    class func italicSystemBoldFont(ofSize size: CGFloat, weight: UIFont.Weight = .bold) -> UIFont {
        let font = UIFont.systemFont(ofSize: size, weight: weight)
        switch weight {
        case .ultraLight, .light, .thin, .regular:
            return font.withTraits(.traitItalic, ofSize: size)
        case .medium, .semibold, .bold, .heavy, .black:
            return font.withTraits(.traitBold, .traitItalic, ofSize: size)
        default:
            return UIFont.italicSystemFont(ofSize: size)
        }
     }

     func withTraits(_ traits: UIFontDescriptor.SymbolicTraits..., ofSize size: CGFloat) -> UIFont {
        let descriptor = self.fontDescriptor
            .withSymbolicTraits(UIFontDescriptor.SymbolicTraits(traits))
        return UIFont(descriptor: descriptor!, size: size)
     }
}
